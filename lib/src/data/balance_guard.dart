import 'package:drift/drift.dart';

import 'database.dart';
import 'money_sum.dart';
import 'rate_repository.dart';

/// Một thay đổi số dư của một tài khoản: [minor] (có dấu, + là tiền vào)
/// theo [currency] gốc của khoản.
typedef BalanceEffect = ({int accountId, String currency, int minor});

/// Các thay đổi số dư mà khoản [e] gây ra (như `balanceBags`).
List<BalanceEffect> entryEffects(Entry e) {
  final original = entryOriginal(e);
  return switch (e.type) {
    EntryType.income => [
      (accountId: e.accountId, currency: e.currency, minor: original),
    ],
    EntryType.expense => [
      (accountId: e.accountId, currency: e.currency, minor: -original),
    ],
    EntryType.transfer => [
      (accountId: e.accountId, currency: e.currency, minor: -original),
      if (e.toAccountId case final to?)
        (
          accountId: to,
          currency: entryReceivedCurrency(e),
          minor: entryReceivedOriginal(e),
        ),
    ],
    EntryType.debt => [
      (
        accountId: e.accountId,
        currency: e.currency,
        minor: isDebtInflow(e) ? original : -original,
      ),
    ],
  };
}

/// Các thay đổi số dư của một khoản CHƯA lưu ([companion] như khi `insert`).
List<BalanceEffect> companionEffects(EntriesCompanion companion) {
  final c = companion;
  return entryEffects(
    Entry(
      id: -1,
      type: c.type.value,
      amount: c.amount.value,
      accountId: c.accountId.value,
      toAccountId: c.toAccountId.present ? c.toAccountId.value : null,
      date: c.date.value,
      createdAt: DateTime(0),
      source: EntrySource.manual,
      currency: c.currency.present ? c.currency.value : 'USD',
      originalAmount: c.originalAmount.present ? c.originalAmount.value : null,
      toOriginalAmount: c.toOriginalAmount.present
          ? c.toOriginalAmount.value
          : null,
      toCurrency: c.toCurrency.present ? c.toCurrency.value : null,
      toAmount: c.toAmount.present ? c.toAmount.value : null,
      debtKind: c.debtKind.present ? c.debtKind.value : null,
    ),
  );
}

/// Thao tác bị chặn vì tài khoản thiếu tiền (D-046); nơi gọi hiện lỗi theo
/// [shortfall].
class InsufficientFundsException implements Exception {
  const InsufficientFundsException(this.shortfall);

  final Shortfall shortfall;

  @override
  String toString() => 'InsufficientFundsException($shortfall)';
}

/// Tài khoản bị chặn vì thiếu tiền (D-046, AC-160): số dư hiện tại theo
/// tiền tệ tài khoản trước và sau thay đổi.
class Shortfall {
  const Shortfall(this.account, this.before, this.after);

  final Account account;

  /// Số dư hiện tại (theo tiền tệ tài khoản) trước thay đổi — "Trip chỉ còn
  /// 500.000 ₫".
  final int before;

  /// Số dư sau thay đổi (âm) — "Trip sẽ âm 200.000 ₫".
  final int after;

  /// Số còn thiếu để thay đổi không làm âm (Bù tiền, AC-165).
  int get missing => -after;

  @override
  String toString() =>
      'Shortfall(${account.id}, before: $before, after: $after)';
}

/// Có thu mới có chi (D-046): kiểm số dư **hiện tại** (mọi thời gian, không
/// xét ngày của khoản) của mỗi tài khoản sau một thay đổi, cộng chính xác
/// theo tiền tệ gốc rồi quy về tiền tệ tài khoản một lần (AC-148).
///
/// Bị chặn khi tài khoản tắt "Cho phép số dư âm", số dư sau < 0 và thay đổi
/// làm số dư GIẢM — nên tiền vào luôn được, bên nhận chuyển tiền không bao giờ
/// bị chặn, và khoản cũ đã làm âm trước luật này vẫn sửa được miễn không làm
/// âm thêm (AC-161). Thiếu tỷ giá để tính số dư thì không chặn.
class BalanceGuard {
  BalanceGuard(this._db, this._service);

  final AppDatabase _db;
  final CurrencyService _service;

  /// Kiểm việc bỏ các khoản [remove] (đang có trong cơ sở dữ liệu) và thêm
  /// các thay đổi [add]. Trả về tài khoản đầu tiên (theo thứ tự hiện) bị
  /// chặn, null nếu được.
  Future<Shortfall?> check({
    Iterable<BalanceEffect> add = const [],
    Iterable<Entry> remove = const [],
  }) async {
    final deltas = <int, MoneyBag>{};
    for (final e in [
      ...add,
      for (final r in remove)
        for (final x in entryEffects(r))
          (accountId: x.accountId, currency: x.currency, minor: -x.minor),
    ]) {
      (deltas[e.accountId] ??= MoneyBag()).add(e.currency, e.minor);
    }
    deltas.removeWhere((_, bag) => bag.isZero);
    if (deltas.isEmpty) return null;
    final accounts =
        await (_db.select(_db.accounts)
              ..where((a) => a.id.isIn(deltas.keys))
              ..orderBy([
                (a) => OrderingTerm(expression: a.sortOrder),
                (a) => OrderingTerm(expression: a.id),
              ]))
            .get();
    if (accounts.every((a) => a.allowNegative)) return null;
    final bags = balanceBags(
      accounts,
      await (_db.select(_db.entries)..where(
            (e) =>
                e.accountId.isIn(deltas.keys) | e.toAccountId.isIn(deltas.keys),
          ))
          .get(),
    );
    for (final a in accounts) {
      if (a.allowNegative) continue;
      final bag = bags[a.id] ?? MoneyBag();
      final before = bag.convertTo(_service, a.currency, skipMissing: false);
      final after = (bag.copy()..addBag(deltas[a.id]!)).convertTo(
        _service,
        a.currency,
        skipMissing: false,
      );
      if (before == null || after == null) continue;
      if (after < 0 && after < before) return Shortfall(a, before, after);
    }
    return null;
  }

  /// Kiểm thêm một khoản mới.
  Future<Shortfall?> checkAdd(EntriesCompanion entry) =>
      check(add: companionEffects(entry));

  /// Kiểm sửa khoản [old] thành [updated].
  Future<Shortfall?> checkReplace(Entry old, Entry updated) =>
      check(add: entryEffects(updated), remove: [old]);

  /// Kiểm xoá các khoản [entries].
  Future<Shortfall?> checkDelete(Iterable<Entry> entries) =>
      check(remove: entries);
}

/// Bật "Cho phép số dư âm" cho mọi tài khoản đang âm (AC-163) khi còn cờ
/// [negativeCheckPendingKey] (nâng cấp lên schema 8, hoặc khôi phục file
/// schema ≤ 7). Trả về id các tài khoản vừa bật — rỗng nếu không có cờ. Ghi
/// danh sách vào cài đặt [negativeNoticeKey] để màn chính báo một lần.
Future<List<int>> applyNegativeUpgrade(
  AppDatabase db,
  CurrencyService service,
) => db.transaction(() async {
  final pending = await (db.select(
    db.settings,
  )..where((s) => s.key.equals(negativeCheckPendingKey))).getSingleOrNull();
  if (pending == null) return const <int>[];
  final accounts = await db.select(db.accounts).get();
  final bags = balanceBags(accounts, await db.select(db.entries).get());
  final turned = <int>[];
  for (final a in accounts) {
    if (a.allowNegative) continue;
    final balance = (bags[a.id] ?? MoneyBag()).convertTo(service, a.currency);
    if (balance != null && balance < 0) turned.add(a.id);
  }
  if (turned.isNotEmpty) {
    await (db.update(db.accounts)..where((a) => a.id.isIn(turned))).write(
      const AccountsCompanion(allowNegative: Value(true)),
    );
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: negativeNoticeKey,
            value: turned.join(','),
          ),
        );
  }
  await (db.delete(
    db.settings,
  )..where((s) => s.key.equals(negativeCheckPendingKey))).go();
  return turned;
});

/// Cài đặt giữ id các tài khoản vừa được tự bật "Cho phép số dư âm" (AC-163),
/// cách nhau dấu phẩy; màn chính hiện hộp một lần rồi xoá.
const negativeNoticeKey = 'negativeAllowedNotice';
