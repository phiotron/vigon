import 'package:drift/drift.dart';

import '../../data/account_repository.dart';
import '../../data/database.dart';
import '../../data/entry_repository.dart';
import '../../data/import_repositories.dart';
import '../../data/settings_repository.dart';
import 'mb_receipt_parser.dart';

/// Kết quả nhập một email thành công của MB.
enum MbImportOutcome {
  /// Số tham chiếu đã biết (đã ghép/xác nhận/bỏ qua/đang chờ) — không tạo gì
  /// (AC-86).
  duplicate,

  /// Ghép vào khoản ghi tay có sẵn (AC-91): khoản chỉ được gắn nguồn + số
  /// tham chiếu, không vào hàng đợi.
  matched,

  /// Vào hàng đợi chọn danh mục (AC-95). Nếu tiền tệ của thư khác tiền tệ
  /// app (AC-87) thì mục mang `currency` khác — màn hàng đợi tự cảnh báo.
  queued,
}

/// Tên Account tự tạo, vd "MB Bank …4821" (AC-89). Tên riêng, không dịch.
String mbAutoAccountName(String last4) => 'MB Bank …$last4';

/// Biên ghép: chênh thời điểm tối đa 2 giờ, tính cả hai đầu (AC-92).
const mbMatchWindow = Duration(hours: 2);

/// Giờ coi như của khoản không có giờ khi ghép (AC-75).
const _noTime = '12:00';

/// Luồng nhập một email biên lai thành công (F-29..F-32, D-033). Chỉ đụng cơ
/// sở dữ liệu; thứ tự theo "Lưu ý cho M1" của M0:
///
/// 1. `isKnown` → bỏ.
/// 2. Tìm/tạo Account theo (MB, 4 số cuối) (F-30).
/// 3. Cùng tiền tệ app: thử ghép khoản ghi tay (F-31) → `attachReference` +
///    `markSeen(matched)`.
/// 4. Không ghép được → mục hàng đợi, KHÔNG `markSeen` (hàng đợi không vào sao
///    lưu, nên mục chờ phải còn "chưa thấy" để khôi phục không làm mất nó).
///
/// Mỗi email chạy trong một giao dịch cơ sở dữ liệu. Lặp lại an toàn: bộ đọc
/// có thể được đưa lại cả lô (UID chỉ nhớ khi cả lô xong).
class MbImportService {
  MbImportService(this._db)
    : _accounts = AccountRepository(_db),
      _entries = EntryRepository(_db),
      _queue = ImportQueueRepository(_db),
      _seen = SeenReferenceRepository(_db);

  final AppDatabase _db;
  final AccountRepository _accounts;
  final EntryRepository _entries;
  final ImportQueueRepository _queue;
  final SeenReferenceRepository _seen;

  static const _bank = Bank.mb;

  /// Nhập một email thành công đã đọc ([receipt]).
  Future<MbImportOutcome> importReceipt(MbReceipt receipt) =>
      _db.transaction(() async {
        if (await _seen.isKnown(_bank, receipt.reference)) {
          return MbImportOutcome.duplicate;
        }
        final account = await _ensureAccount(receipt.debitLast4);

        // Ghép chỉ khi cùng tiền tệ app: số tiền khoản ghi tay ở tiền tệ app
        // (AC-87: tiền tệ khác thì không so được, vào hàng đợi).
        if (receipt.currency == await _appCurrency()) {
          final entry = await _findMatchingEntry(
            accountId: account.id,
            amount: receipt.amount,
            date: receipt.dateKey,
            time: receipt.time,
          );
          if (entry != null) {
            await _entries.attachReference(
              entry.id,
              entrySourceForBank(_bank),
              receipt.reference,
            );
            await _seen.markSeen(
              _bank,
              receipt.reference,
              ReferenceOutcome.matched,
            );
            return MbImportOutcome.matched;
          }
        }

        await _queue.add(
          ImportQueueItemsCompanion.insert(
            bank: _bank,
            referenceNumber: receipt.reference,
            debitLast4: receipt.debitLast4,
            accountId: Value(account.id),
            currency: receipt.currency,
            amount: receipt.amount,
            date: receipt.dateKey,
            time: receipt.time,
            payee: Value(receipt.payee),
            transferContent: Value(receipt.transferContent),
          ),
        );
        return MbImportOutcome.queued;
      });

  Future<String> _appCurrency() => SettingsRepository(_db).readCurrency();

  /// Account của (MB, [last4]); chưa có thì tạo "MB Bank …xxxx", số dư 0, và
  /// ghi nhớ thẻ "Gắn vào tài khoản có sẵn" (AC-89). Account đã ẩn vẫn nhận
  /// (AC-90).
  Future<Account> _ensureAccount(String last4) async {
    final existing = await _accounts.findByBankLink(_bank, last4);
    if (existing != null) return existing;
    final id = await _accounts.add(name: mbAutoAccountName(last4));
    await _accounts.setBankLink(id, _bank, last4);
    await _addNotice(id);
    return (await _accounts.findByBankLink(_bank, last4))!;
  }

  // ---------------------------------------------------------------- ghép

  /// Khoản ghi tay khớp một email (AC-91..AC-93): cùng Account (khoản chi, hoặc
  /// chuyển tiền đi từ Account đó), cùng số tiền, chênh ≤ 2 giờ, chưa gắn
  /// email nào. Nhiều khoản → gần nhất; bằng nhau → khoản tạo trước.
  Future<Entry?> _findMatchingEntry({
    required int accountId,
    required int amount,
    required String date,
    required String time,
  }) async {
    final day = _parseDate(date);
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    // 2 giờ có thể vượt nửa đêm: xét ngày trước và ngày sau.
    final from = key(day.subtract(const Duration(days: 1)));
    final to = key(day.add(const Duration(days: 1)));
    final rows =
        await (_db.select(_db.entries)..where(
              (e) =>
                  e.accountId.equals(accountId) &
                  e.referenceNumber.isNull() &
                  e.amount.equals(amount) &
                  e.type.isInValues([EntryType.expense, EntryType.transfer]) &
                  e.date.isBetweenValues(from, to),
            ))
            .get();
    final at = _instant(date, time);
    Entry? best;
    Duration? bestGap;
    for (final e in rows) {
      final gap = _instant(e.date, e.time ?? _noTime).difference(at).abs();
      if (gap > mbMatchWindow) continue;
      if (best == null ||
          gap < bestGap! ||
          (gap == bestGap && e.id < best.id)) {
        best = e;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Chiều ngược (AC-94): khoản ghi tay [entry] vừa được lưu (hoặc vừa gắn
  /// Account, AC-89) có mục hàng đợi thoả AC-91 không. Mục cùng Account, cùng
  /// tiền tệ app, cùng số tiền, ≤ 2 giờ; nhiều mục → gần nhất, bằng nhau →
  /// mục có sớm trước. Không đổi gì.
  Future<ImportQueueItem?> findQueueMatchFor(Entry entry) async {
    if (entry.referenceNumber != null ||
        entry.source != EntrySource.manual ||
        entry.type == EntryType.income) {
      return null;
    }
    final currency = await _appCurrency();
    final at = _instant(entry.date, entry.time ?? _noTime);
    ImportQueueItem? best;
    Duration? bestGap;
    for (final item in await _queue.forAccount(entry.accountId)) {
      if (item.currency != currency || item.amount != entry.amount) continue;
      final gap = _instant(item.date, item.time).difference(at).abs();
      if (gap > mbMatchWindow) continue;
      if (best == null ||
          gap < bestGap! ||
          (gap == bestGap && item.id < best.id)) {
        best = item;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Ghép mục hàng đợi [item] vào khoản [entryId] (AC-94): khoản giữ nguyên
  /// dữ liệu, chỉ thêm nguồn + số tham chiếu; mục rời hàng đợi và số tham
  /// chiếu được nhớ là đã ghép. Trả về mục đã xoá (cho [undoAttach]).
  Future<ImportQueueItem?> attachQueueItem(ImportQueueItem item, int entryId) =>
      _db.transaction(() async {
        await _entries.attachReference(
          entryId,
          entrySourceForBank(item.bank),
          item.referenceNumber,
        );
        final removed = await _queue.remove(item.id);
        await _seen.markSeen(
          item.bank,
          item.referenceNumber,
          ReferenceOutcome.matched,
        );
        return removed;
      });

  /// Hoàn tác [attachQueueItem]: mục về hàng đợi, khoản về ghi tay, số tham
  /// chiếu không còn là "đã thấy".
  Future<void> undoAttach(ImportQueueItem item, int entryId) =>
      _db.transaction(() async {
        await _entries.detachReference(entryId);
        await _queue.restore(item);
        await _seen.forget(item.bank, item.referenceNumber);
      });

  /// Thử ghép lại mọi mục hàng đợi của [accountId] với khoản ghi tay (sau khi
  /// gắn Account, AC-89). Trả về số mục đã ghép.
  Future<int> rematchAccount(int accountId) async {
    var matched = 0;
    final currency = await _appCurrency();
    for (final item in await _queue.forAccount(accountId)) {
      if (item.currency != currency) continue;
      final entry = await _findMatchingEntry(
        accountId: accountId,
        amount: item.amount,
        date: item.date,
        time: item.time,
      );
      if (entry == null) continue;
      await attachQueueItem(item, entry.id);
      matched++;
    }
    return matched;
  }

  // -------------------------------------------- tài khoản tự tạo (AC-89)

  /// Id các Account tự tạo còn thẻ "Gắn vào tài khoản có sẵn" (mới tạo trước).
  /// Id không còn tồn tại (Account bị xoá) đã được lọc.
  Stream<List<int>> watchAutoAccountNotices() {
    final query = _db.select(_db.settings)
      ..where((s) => s.key.equals(SettingsRepository.mbAutoAccountNoticesKey));
    return query.watchSingleOrNull().asyncMap((row) async {
      final ids = _parseIds(row?.value);
      if (ids.isEmpty) return const <int>[];
      final alive = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.isIn(ids))).get();
      final aliveIds = {for (final a in alive) a.id};
      return [
        for (final id in ids.reversed)
          if (aliveIds.contains(id)) id,
      ];
    });
  }

  /// Đóng thẻ — giữ Account mới (AC-89).
  Future<void> dismissAutoAccountNotice(int accountId) =>
      _db.transaction(() async {
        final ids = await _readIds();
        if (ids.remove(accountId)) await _writeIds(ids);
      });

  /// "Gắn vào tài khoản có sẵn" (AC-89): liên kết (MB, 4 số cuối) của Account
  /// tự tạo [autoAccountId] chuyển sang [targetAccountId]; các mục hàng đợi
  /// chuyển theo; Account tự tạo bị xoá (nếu chưa có khoản nào — chưa có thì
  /// mới an toàn) và các mục được thử ghép lại (AC-94). Trả về số mục đã ghép;
  /// null nếu [autoAccountId] không còn liên kết (không làm gì).
  Future<int?> attachToExistingAccount({
    required int autoAccountId,
    required int targetAccountId,
  }) => _db.transaction(() async {
    if (autoAccountId == targetAccountId) return null;
    final auto = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(autoAccountId))).getSingleOrNull();
    if (auto == null || auto.bank == null || auto.bankLast4 == null) {
      return null;
    }
    await _accounts.setBankLink(targetAccountId, auto.bank!, auto.bankLast4!);
    await _queue.moveAccount(autoAccountId, targetAccountId);
    // Chưa có khoản nào nên xoá được; nếu bị chặn (đã có khoản) thì giữ lại,
    // chỉ mất liên kết.
    await _accounts.delete(autoAccountId);
    final ids = await _readIds();
    if (ids.remove(autoAccountId)) await _writeIds(ids);
    return rematchAccount(targetAccountId);
  });

  Future<void> _addNotice(int accountId) async {
    final ids = await _readIds();
    if (!ids.contains(accountId)) await _writeIds([...ids, accountId]);
  }

  Future<List<int>> _readIds() async {
    final row =
        await (_db.select(_db.settings)..where(
              (s) => s.key.equals(SettingsRepository.mbAutoAccountNoticesKey),
            ))
            .getSingleOrNull();
    return _parseIds(row?.value);
  }

  Future<void> _writeIds(List<int> ids) async {
    if (ids.isEmpty) {
      await (_db.delete(_db.settings)..where(
            (s) => s.key.equals(SettingsRepository.mbAutoAccountNoticesKey),
          ))
          .go();
      return;
    }
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: SettingsRepository.mbAutoAccountNoticesKey,
            value: ids.join(','),
          ),
        );
  }

  static List<int> _parseIds(String? value) => [
    if (value != null)
      for (final p in value.split(','))
        if (int.tryParse(p) != null) int.parse(p),
  ];
}

DateTime _parseDate(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// Thời điểm `YYYY-MM-DD` + `HH:mm` ở dạng so được. Dùng UTC để giờ mùa hè
/// không làm lệch 2 giờ: các giờ đều là giờ máy, chỉ cần hiệu của hai giờ.
DateTime _instant(String date, String time) {
  final d = _parseDate(date);
  final t = time.split(':').map(int.parse).toList();
  return DateTime.utc(d.year, d.month, d.day, t[0], t[1]);
}
