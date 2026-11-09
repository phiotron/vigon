import 'package:drift/drift.dart';

import 'database.dart';
import 'import_text.dart';

/// Lý do không ẩn hoặc xóa được tài khoản (AC-45, AC-46).
enum AccountBlock {
  /// Là tài khoản hiện cuối cùng.
  lastVisible,

  /// Đã có khoản (kể cả chuyển tiền đi hoặc đến) hoặc chuỗi định kỳ trỏ tới.
  inUse,
}

/// Đọc, ghi tài khoản (AC-18 tới AC-20, AC-44 tới AC-47).
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$AccountsTable, Account> _ordered(
    Expression<bool> Function($AccountsTable a)? where,
  ) {
    final q = _db.select(_db.accounts);
    if (where != null) q.where(where);
    return q..orderBy([
      (a) => OrderingTerm(expression: a.sortOrder),
      (a) => OrderingTerm(expression: a.id),
    ]);
  }

  /// Tài khoản đang hiện (chưa ẩn).
  Stream<List<Account>> watch() =>
      _ordered((a) => a.archived.equals(false)).watch();

  /// Mọi tài khoản, kể cả đã ẩn; dùng để gọi tên tài khoản của khoản cũ (AC-44).
  Stream<List<Account>> watchAll() => _ordered(null).watch();

  /// Tài khoản đã ẩn (AC-47).
  Stream<List<Account>> watchArchived() =>
      _ordered((a) => a.archived.equals(true)).watch();

  /// Tài khoản có khoản (đi hoặc đến) hay chuỗi định kỳ trỏ tới không (AC-45).
  Stream<bool> watchInUse(int id) => _db
      .customSelect('SELECT 1', readsFrom: {_db.entries, _db.recurringRules})
      .watch()
      .asyncMap((_) => isInUse(id));

  Future<bool> isInUse(int id) async {
    final inEntries =
        await (_db.select(_db.entries)
              ..where((e) => e.accountId.equals(id) | e.toAccountId.equals(id))
              ..limit(1))
            .get();
    if (inEntries.isNotEmpty) return true;
    final inRules =
        await (_db.select(_db.recurringRules)
              ..where((r) => r.accountId.equals(id) | r.toAccountId.equals(id))
              ..limit(1))
            .get();
    return inRules.isNotEmpty;
  }

  Future<bool> _isLastVisible(int id) async {
    final visible = await (_db.select(
      _db.accounts,
    )..where((a) => a.archived.equals(false))).get();
    return visible.length == 1 && visible.single.id == id;
  }

  /// Ẩn tài khoản (AC-44). Trả về lý do nếu không ẩn được, null nếu đã ẩn (AC-46).
  Future<AccountBlock?> archive(int id) => _db.transaction(() async {
    if (await _isLastVisible(id)) return AccountBlock.lastVisible;
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(archived: Value(true)),
    );
    return null;
  });

  /// Hiện lại tài khoản đã ẩn (AC-47).
  Future<void> unarchive(int id) =>
      (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(archived: Value(false)),
      );

  /// Xóa tài khoản (AC-45, AC-46). Trả về lý do nếu không xóa được, null nếu đã xóa.
  /// Tài khoản đang gắn mục tiêu tiết kiệm cũng tính là đang dùng (AC-103: xoá
  /// mục tiêu trước). Mục hàng đợi của nó mất tài khoản (null, AC-90); gợi ý
  /// "chuyển sang" nó bị xoá theo.
  Future<AccountBlock?> delete(int id) => _db.transaction(() async {
    if (await isInUse(id)) return AccountBlock.inUse;
    final goal = await (_db.select(
      _db.savingsGoals,
    )..where((g) => g.accountId.equals(id))).getSingleOrNull();
    if (goal != null) return AccountBlock.inUse;
    if (await _isLastVisible(id)) return AccountBlock.lastVisible;
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    return null;
  });

  Future<int> add({
    required String name,
    int initialBalance = 0,
    int? initialBalanceOriginal,
    String currency = 'USD',
  }) => _db
      .into(_db.accounts)
      .insert(
        AccountsCompanion.insert(
          name: Value(name),
          initialBalance: Value(initialBalance),
          initialBalanceOriginal: Value(
            initialBalanceOriginal ?? initialBalance,
          ),
          currency: Value(currency),
          initialCurrency: Value(currency),
        ),
      );

  Future<void> edit(
    int id, {
    required String name,
    required int initialBalance,
    int? initialBalanceOriginal,
    String? currency,
  }) => (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
    AccountsCompanion(
      name: Value(name),
      nameKey: const Value(null),
      initialBalance: Value(initialBalance),
      initialBalanceOriginal: Value(initialBalanceOriginal ?? initialBalance),
      currency: currency == null ? const Value.absent() : Value(currency),
      initialCurrency: currency == null
          ? const Value.absent()
          : Value(currency),
    ),
  );

  /// Đổi tiền tệ tài khoản (D-037): không sửa số gốc của khoản đã có; khoản
  /// mới sẽ mặc định dùng tiền tệ mới. Số dư ban đầu giữ nguyên số, đổi tiền
  /// tệ đích.
  Future<void> setCurrency(int id, String currency) =>
      (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          currency: Value(currency),
          initialCurrency: Value(currency),
        ),
      );

  /// Tài khoản liên kết với tài khoản trích nợ ([bank], [last4]) (AC-89, AC-90),
  /// kể cả đã ẩn; null nếu chưa có.
  Future<Account?> findByBankLink(Bank bank, String last4) =>
      (_db.select(
            _db.accounts,
          )..where((a) => a.bank.equalsValue(bank) & a.bankLast4.equals(last4)))
          .getSingleOrNull();

  /// Gắn liên kết ([bank], [last4]) vào tài khoản [id]; tài khoản khác đang giữ
  /// liên kết đó thì mất liên kết (AC-89 "Gắn vào tài khoản có sẵn"). Chỉ nhận
  /// đúng 4 chữ số (AC-88).
  Future<void> setBankLink(int id, Bank bank, String last4) {
    checkLast4(last4);
    return _db.transaction(() async {
      await (_db.update(_db.accounts)..where(
            (a) =>
                a.bank.equalsValue(bank) &
                a.bankLast4.equals(last4) &
                a.id.equals(id).not(),
          ))
          .write(
            const AccountsCompanion(bank: Value(null), bankLast4: Value(null)),
          );
      await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(bank: Value(bank), bankLast4: Value(last4)),
      );
    });
  }

  /// Bỏ liên kết ngân hàng của tài khoản [id].
  Future<void> clearBankLink(int id) =>
      (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(bank: Value(null), bankLast4: Value(null)),
      );

  /// Số dư hiện tại mỗi tài khoản: số dư ban đầu + thu − chi + nhận − chuyển đi (AC-18, AC-19).
  Stream<Map<int, int>> watchBalances() => _db
      .customSelect('SELECT 1', readsFrom: {_db.accounts, _db.entries})
      .watch()
      .asyncMap(
        (_) async => balances(
          await _db.select(_db.accounts).get(),
          await _db.select(_db.entries).get(),
        ),
      );
}

Map<int, int> balances(List<Account> accounts, List<Entry> entries) {
  final result = {for (final a in accounts) a.id: a.initialBalance};
  for (final e in entries) {
    switch (e.type) {
      case EntryType.income:
        result.update(
          e.accountId,
          (v) => v + e.amount,
          ifAbsent: () => e.amount,
        );
      case EntryType.expense:
        result.update(
          e.accountId,
          (v) => v - e.amount,
          ifAbsent: () => -e.amount,
        );
      case EntryType.transfer:
        result.update(
          e.accountId,
          (v) => v - e.amount,
          ifAbsent: () => -e.amount,
        );
        final to = e.toAccountId;
        if (to != null) {
          final received = e.toAmount ?? e.amount;
          result.update(to, (v) => v + received, ifAbsent: () => received);
        }
    }
  }
  return result;
}
