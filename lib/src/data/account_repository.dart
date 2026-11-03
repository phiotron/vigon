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
}
