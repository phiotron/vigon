import 'package:drift/drift.dart';

import '../../data/account_repository.dart';
import '../../data/database.dart';
import '../../data/import_repositories.dart';
import '../../import/mb/mb_import_service.dart' show mbAutoAccountName;

/// Ghi chú của khoản lấy từ email (AC-88): "người thụ hưởng · nội dung",
/// cắt ở 200 ký tự. Người thụ hưởng và nội dung đã được che dãy ≥ 9 chữ số
/// ngay khi vào hàng đợi (`ImportQueueRepository.add`).
String? queueItemNote(ImportQueueItem item) {
  final payee = item.payee?.trim() ?? '';
  final content = item.transferContent?.trim() ?? '';
  final note = [
    if (payee.isNotEmpty) payee,
    if (content.isNotEmpty) content,
  ].join(' · ');
  if (note.isEmpty) return null;
  return note.length > 200 ? note.substring(0, 200) : note;
}

/// Hành động lưu/chuyển/bỏ một mục hàng đợi (F-32, AC-96..AC-99). Mỗi hành
/// động chạy trong MỘT giao dịch cơ sở dữ liệu và theo đúng luật của M0:
/// tạo khoản có `source` + `referenceNumber` + giờ, xoá mục khỏi hàng đợi, ghi
/// `seen_references` (`confirmed`/`skipped`), nhớ gợi ý. Mục còn trong hàng đợi
/// KHÔNG `markSeen`.
///
/// Mục đã không còn trong hàng đợi (vd bị xoá ở nơi khác) thì hành động không
/// làm gì và trả về null — không tạo khoản trùng.
class ImportQueueActions {
  ImportQueueActions(this._db)
    : _queue = ImportQueueRepository(_db),
      _seen = SeenReferenceRepository(_db),
      _suggestions = PayeeSuggestionRepository(_db),
      _accounts = AccountRepository(_db);

  final AppDatabase _db;
  final ImportQueueRepository _queue;
  final SeenReferenceRepository _seen;
  final PayeeSuggestionRepository _suggestions;
  final AccountRepository _accounts;

  /// Account trích nợ của mục. Mục có `accountId == null` (Account bị xoá, hoặc
  /// sau khôi phục chưa có liên kết) thì tìm lại theo (ngân hàng, 4 số cuối),
  /// không có thì tạo lại "MB Bank …xxxx" số dư 0, rồi gắn lại mọi mục cùng tài
  /// khoản trích nợ (AC-90).
  Future<int> resolveAccount(ImportQueueItem item) async {
    final id = item.accountId;
    if (id != null) return id;
    var account = await _accounts.findByBankLink(item.bank, item.debitLast4);
    if (account == null) {
      final newId = await _accounts.add(
        name: mbAutoAccountName(item.debitLast4),
      );
      await _accounts.setBankLink(newId, item.bank, item.debitLast4);
      account = await _accounts.findByBankLink(item.bank, item.debitLast4);
    }
    await _queue.assignAccount(item.bank, item.debitLast4, account!.id);
    return account.id;
  }

  /// Lưu mục thành một khoản chi vào [categoryId] (AC-96): ngày giờ của email,
  /// Account trích nợ, đúng số tiền (kể cả số chính xác D-029), ghi chú AC-88,
  /// nguồn + số tham chiếu của email; nhớ gợi ý người thụ hưởng → danh mục.
  /// Trả về id khoản mới, hoặc null nếu mục không còn trong hàng đợi.
  Future<int?> saveToCategory(ImportQueueItem item, int categoryId) =>
      _db.transaction(() async {
        final removed = await _queue.remove(item.id);
        if (removed == null) return null;
        final accountId = await resolveAccount(removed);
        final entryId = await _db
            .into(_db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.expense,
                amount: removed.amount,
                amountMicro: Value(removed.amountMicro),
                categoryId: Value(categoryId),
                accountId: accountId,
                date: removed.date,
                time: Value(removed.time),
                note: Value(queueItemNote(removed)),
                source: Value(entrySourceForBank(removed.bank)),
                referenceNumber: Value(removed.referenceNumber),
              ),
            );
        await _seen.markSeen(
          removed.bank,
          removed.referenceNumber,
          ReferenceOutcome.confirmed,
        );
        await _remember(removed, categoryId: categoryId);
        return entryId;
      });

  /// "Chuyển sang tài khoản của tôi" (AC-98): một Transfer từ Account trích nợ
  /// sang [toAccountId] (khác Account trích nợ; gồm cả Account của mục tiêu
  /// tiết kiệm), cùng ngày giờ, số tiền, ghi chú, số tham chiếu; nhớ gợi ý.
  /// Không vào thu/chi. Ném [ArgumentError] nếu trùng Account trích nợ.
  Future<int?> saveAsTransfer(ImportQueueItem item, int toAccountId) =>
      _db.transaction(() async {
        final removed = await _queue.remove(item.id);
        if (removed == null) return null;
        final fromId = await resolveAccount(removed);
        if (fromId == toAccountId) {
          throw ArgumentError('Hai tài khoản phải khác nhau');
        }
        final entryId = await _db
            .into(_db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.transfer,
                amount: removed.amount,
                amountMicro: Value(removed.amountMicro),
                accountId: fromId,
                toAccountId: Value(toAccountId),
                date: removed.date,
                time: Value(removed.time),
                note: Value(queueItemNote(removed)),
                source: Value(entrySourceForBank(removed.bank)),
                referenceNumber: Value(removed.referenceNumber),
              ),
            );
        await _seen.markSeen(
          removed.bank,
          removed.referenceNumber,
          ReferenceOutcome.confirmed,
        );
        await _remember(removed, toAccountId: toAccountId);
        return entryId;
      });

  /// "Sửa trước khi lưu" (AC-96, AC-87): người dùng đã chỉnh khoản ở màn Nhập
  /// khoản; [entry] là khoản sẽ lưu (chưa có nguồn/số tham chiếu — thêm ở đây).
  /// Làm đúng như [saveToCategory] nhưng với dữ liệu đã sửa. Trả về id khoản
  /// mới, hoặc null nếu mục không còn trong hàng đợi (không tạo gì).
  Future<int?> saveEdited(ImportQueueItem item, EntriesCompanion entry) =>
      _db.transaction(() async {
        final removed = await _queue.remove(item.id);
        if (removed == null) return null;
        final entryId = await _db
            .into(_db.entries)
            .insert(
              entry.copyWith(
                source: Value(entrySourceForBank(removed.bank)),
                referenceNumber: Value(removed.referenceNumber),
              ),
            );
        await _seen.markSeen(
          removed.bank,
          removed.referenceNumber,
          ReferenceOutcome.confirmed,
        );
        final categoryId = entry.categoryId.present
            ? entry.categoryId.value
            : null;
        if (categoryId != null) {
          await _remember(removed, categoryId: categoryId);
        }
        return entryId;
      });

  /// "Bỏ qua" (AC-99): xoá mục khỏi hàng đợi, nhớ số tham chiếu là đã bỏ qua để
  /// không nhập lại (AC-86). Trả về true nếu có xoá.
  Future<bool> skip(ImportQueueItem item) => _db.transaction(() async {
    final removed = await _queue.remove(item.id);
    if (removed == null) return false;
    await _seen.markSeen(
      removed.bank,
      removed.referenceNumber,
      ReferenceOutcome.skipped,
    );
    return true;
  });

  Future<void> _remember(
    ImportQueueItem item, {
    int? categoryId,
    int? toAccountId,
  }) async {
    final payee = item.payee;
    if (payee == null || payee.trim().isEmpty) return;
    if (categoryId != null) {
      await _suggestions.rememberCategory(payee, categoryId);
    } else if (toAccountId != null) {
      await _suggestions.rememberTransfer(payee, toAccountId);
    }
  }
}
