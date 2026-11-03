import 'package:drift/drift.dart';

import 'database.dart';

/// Đọc, ghi danh mục (AC-15 tới AC-17).
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watch(CategoryType type) =>
      (_db.select(_db.categories)
            ..where((c) => c.type.equalsValue(type))
            ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
          .watch();
}
