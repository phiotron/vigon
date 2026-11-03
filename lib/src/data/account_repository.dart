import 'package:drift/drift.dart';

import 'database.dart';

/// Đọc, ghi tài khoản (AC-18 tới AC-20).
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watch() =>
      (_db.select(_db.accounts)
            ..where((a) => a.archived.equals(false))
            ..orderBy([
              (a) => OrderingTerm(expression: a.sortOrder),
              (a) => OrderingTerm(expression: a.id),
            ]))
          .watch();

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
