import 'package:drift/drift.dart';

import 'database.dart';
import 'import_text.dart';

/// Nguồn của khoản khi số tham chiếu đến từ email của [bank].
EntrySource entrySourceForBank(Bank bank) => switch (bank) {
  Bank.mb => EntrySource.emailMb,
};

/// Hàng đợi nhập (Import queue, AC-95..AC-99): đọc, ghi mục chờ chọn danh
/// mục. Chỉ là kho dữ liệu: luật nhập/ghép (D-033) nằm ở `lib/src/import/`.
class ImportQueueRepository {
  ImportQueueRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$ImportQueueItemsTable, ImportQueueItem> _ordered() =>
      _db.select(_db.importQueueItems)..orderBy([
        (q) => OrderingTerm.desc(q.date),
        (q) => OrderingTerm.desc(q.time),
        (q) => OrderingTerm.desc(q.id),
      ]);

  /// Mọi mục, mới nhất trước (theo ngày giờ email).
  Stream<List<ImportQueueItem>> watchAll() => _ordered().watch();

  Future<List<ImportQueueItem>> all() => _ordered().get();

  /// Số mục đang chờ — "N khoản chờ chọn danh mục" ở màn chính (AC-95).
  Stream<int> watchCount() {
    final count = _db.importQueueItems.id.count();
    return (_db.selectOnly(
      _db.importQueueItems,
    )..addColumns([count])).map((r) => r.read(count) ?? 0).watchSingle();
  }

  Future<ImportQueueItem?> find(int id) => (_db.select(
    _db.importQueueItems,
  )..where((q) => q.id.equals(id))).getSingleOrNull();

  /// Mục của số tham chiếu ([bank], [reference]) nếu đang trong hàng đợi.
  Future<ImportQueueItem?> findByReference(Bank bank, String reference) =>
      (_db.select(_db.importQueueItems)..where(
            (q) =>
                q.bank.equalsValue(bank) & q.referenceNumber.equals(reference),
          ))
          .getSingleOrNull();

  /// Mục đang gắn tài khoản [accountId].
  Future<List<ImportQueueItem>> forAccount(int accountId) =>
      (_ordered()..where((q) => q.accountId.equals(accountId))).get();

  /// Thêm một mục. Người thụ hưởng và nội dung được che dãy ≥ 9 chữ số
  /// (AC-88) ngay tại đây; [ImportQueueItemsCompanion.debitLast4] phải đúng 4
  /// chữ số. Trả về null (không thêm) nếu số tham chiếu đã có trong hàng đợi.
  /// Kiểm "đã gặp"/"đã nằm trong khoản" là việc của bên nhập
  /// ([SeenReferenceRepository.isKnown]).
  Future<int?> add(ImportQueueItemsCompanion item) {
    checkLast4(item.debitLast4.value);
    String? mask(Value<String?> v) =>
        v.present && v.value != null ? maskLongDigitRuns(v.value!) : null;
    return _db.transaction(() async {
      final existing = await findByReference(
        item.bank.value,
        item.referenceNumber.value,
      );
      if (existing != null) return null;
      return _db
          .into(_db.importQueueItems)
          .insert(
            item.copyWith(
              payee: Value(mask(item.payee)),
              transferContent: Value(mask(item.transferContent)),
            ),
          );
    });
  }

  /// Xoá mục và trả về bản đã xoá (để Hoàn tác, AC-94); null nếu không có.
  Future<ImportQueueItem?> remove(int id) => _db.transaction(() async {
    final item = await find(id);
    if (item != null) {
      await (_db.delete(
        _db.importQueueItems,
      )..where((q) => q.id.equals(id))).go();
    }
    return item;
  });

  /// Ghi lại đúng mục đã xoá, giữ nguyên id (Hoàn tác, AC-94).
  Future<void> restore(ImportQueueItem item) =>
      _db.into(_db.importQueueItems).insert(item);

  /// Chuyển mọi mục của tài khoản [from] sang [to] (AC-89 "Gắn vào tài khoản
  /// có sẵn").
  Future<void> moveAccount(int from, int to) =>
      (_db.update(_db.importQueueItems)..where((q) => q.accountId.equals(from)))
          .write(ImportQueueItemsCompanion(accountId: Value(to)));

  /// Gắn [accountId] cho mọi mục của tài khoản trích nợ ([bank], [last4]) —
  /// sau khi tạo lại tài khoản liên kết (AC-90) hoặc sau khôi phục.
  Future<void> assignAccount(Bank bank, String last4, int accountId) =>
      (_db.update(_db.importQueueItems)..where(
            (q) => q.bank.equalsValue(bank) & q.debitLast4.equals(last4),
          ))
          .write(ImportQueueItemsCompanion(accountId: Value(accountId)));
}

/// Số tham chiếu đã gặp (AC-86): đã ghép, đã lưu, đã bỏ qua.
class SeenReferenceRepository {
  SeenReferenceRepository(this._db);

  final AppDatabase _db;

  Future<bool> isSeen(Bank bank, String reference) async =>
      await (_db.select(_db.seenReferences)..where(
            (s) =>
                s.bank.equalsValue(bank) & s.referenceNumber.equals(reference),
          ))
          .getSingleOrNull() !=
      null;

  /// Số tham chiếu đã biết ở bất kỳ đâu: đã gặp, đang trong hàng đợi, hoặc
  /// đang gắn vào một khoản — gặp lại thì không tạo gì (AC-86).
  Future<bool> isKnown(Bank bank, String reference) async {
    if (await isSeen(bank, reference)) return true;
    if (await ImportQueueRepository(_db).findByReference(bank, reference) !=
        null) {
      return true;
    }
    final source = entrySourceForBank(bank);
    final entry =
        await (_db.select(_db.entries)
              ..where(
                (e) =>
                    e.source.equalsValue(source) &
                    e.referenceNumber.equals(reference),
              )
              ..limit(1))
            .getSingleOrNull();
    return entry != null;
  }

  /// Ghi nhớ (hoặc ghi đè kết quả của) số tham chiếu.
  Future<void> markSeen(
    Bank bank,
    String reference,
    ReferenceOutcome outcome, {
    DateTime? at,
  }) => _db
      .into(_db.seenReferences)
      .insertOnConflictUpdate(
        SeenReferencesCompanion.insert(
          bank: bank,
          referenceNumber: reference,
          outcome: outcome,
          seenAt: at == null ? const Value.absent() : Value(at),
        ),
      );

  /// Quên số tham chiếu (Hoàn tác một lần ghép/lưu, AC-94).
  Future<void> forget(Bank bank, String reference) =>
      (_db.delete(_db.seenReferences)..where(
            (s) =>
                s.bank.equalsValue(bank) & s.referenceNumber.equals(reference),
          ))
          .go();
}

/// Gợi ý theo người thụ hưởng (AC-97, AC-98).
class PayeeSuggestionRepository {
  PayeeSuggestionRepository(this._db);

  final AppDatabase _db;

  /// Gợi ý cho [payee] (so theo [payeeKey]); null nếu chưa có.
  Future<PayeeSuggestion?> forPayee(String payee) {
    final key = _key(payee);
    if (key.isEmpty) return Future.value();
    return (_db.select(
      _db.payeeSuggestions,
    )..where((s) => s.payeeKey.equals(key))).getSingleOrNull();
  }

  /// "Gợi ý đã nhớ", theo tên.
  Stream<List<PayeeSuggestion>> watchAll() => (_db.select(
    _db.payeeSuggestions,
  )..orderBy([(s) => OrderingTerm(expression: s.payeeKey)])).watch();

  /// Nhớ lần lưu vào danh mục [categoryId] cho [payee] (ghi đè lựa chọn cũ).
  Future<void> rememberCategory(String payee, int categoryId, {DateTime? at}) =>
      _remember(payee, categoryId: categoryId, at: at);

  /// Nhớ lần "Chuyển sang tài khoản của tôi" [toAccountId] cho [payee] (AC-98).
  Future<void> rememberTransfer(
    String payee,
    int toAccountId, {
    DateTime? at,
  }) => _remember(payee, toAccountId: toAccountId, at: at);

  Future<void> _remember(
    String payee, {
    int? categoryId,
    int? toAccountId,
    DateTime? at,
  }) async {
    final key = _key(payee);
    if (key.isEmpty) return;
    final name = maskLongDigitRuns(payee.trim());
    await _db
        .into(_db.payeeSuggestions)
        .insertOnConflictUpdate(
          PayeeSuggestionsCompanion.insert(
            payeeKey: key,
            payee: name.length > 200 ? name.substring(0, 200) : name,
            categoryId: Value(categoryId),
            toAccountId: Value(toAccountId),
            updatedAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  /// Xoá một gợi ý (theo khoá đã gấp).
  Future<void> delete(String key) => (_db.delete(
    _db.payeeSuggestions,
  )..where((s) => s.payeeKey.equals(key))).go();
}

/// Khoá lưu được (cột tối đa 200 ký tự).
String _key(String payee) {
  final key = payeeKey(payee);
  return key.length > 200 ? key.substring(0, 200) : key;
}
