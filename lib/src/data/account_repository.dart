import 'package:drift/drift.dart';

import 'database.dart';

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
  Future<AccountBlock?> delete(int id) => _db.transaction(() async {
    if (await isInUse(id)) return AccountBlock.inUse;
    if (await _isLastVisible(id)) return AccountBlock.lastVisible;
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    return null;
  });

  Future<int> add({required String name, int initialBalance = 0}) => _db
      .into(_db.accounts)
      .insert(
        AccountsCompanion.insert(
          name: Value(name),
          initialBalance: Value(initialBalance),
        ),
      );

  Future<void> edit(
    int id, {
    required String name,
    required int initialBalance,
  }) => (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
    AccountsCompanion(
      name: Value(name),
      nameKey: const Value(null),
      initialBalance: Value(initialBalance),
    ),
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
          result.update(to, (v) => v + e.amount, ifAbsent: () => e.amount);
        }
    }
  }
  return result;
}
