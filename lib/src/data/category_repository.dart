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

  Future<int> add({
    required CategoryType type,
    required String name,
    required String icon,
    required int color,
  }) async {
    final max = _db.categories.sortOrder.max();
    final row =
        await (_db.selectOnly(_db.categories)
              ..addColumns([max])
              ..where(_db.categories.type.equalsValue(type)))
            .getSingle();
    return _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            type: type,
            name: Value(name),
            icon: icon,
            color: color,
            sortOrder: Value((row.read(max) ?? -1) + 1),
          ),
        );
  }

  /// Đổi tên, icon, màu (AC-16). Có [name] thì bỏ tên mặc định theo ngôn ngữ;
  /// [name] null thì giữ tên đang có.
  Future<void> edit(
    int id, {
    String? name,
    required String icon,
    required int color,
  }) => (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
    CategoriesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      nameKey: name == null ? const Value.absent() : const Value(null),
      icon: Value(icon),
      color: Value(color),
    ),
  );

  /// Ghi thứ tự mới theo danh sách id (AC-16).
  Future<void> reorder(List<int> ids) => _db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.categories)..where((c) => c.id.equals(ids[i])))
          .write(CategoriesCompanion(sortOrder: Value(i)));
    }
  });

  /// Số khoản đang dùng danh mục.
  Future<int> usageCount(int id) async {
    final count = _db.entries.id.count();
    final row =
        await (_db.selectOnly(_db.entries)
              ..addColumns([count])
              ..where(_db.entries.categoryId.equals(id)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Xóa danh mục; các khoản và chuỗi định kỳ của nó chuyển sang [moveTo]
  /// để không mất khoản nào (AC-17).
  Future<void> delete(int id, {required int moveTo}) {
    assert(id != moveTo);
    return _db.transaction(() async {
      await (_db.update(_db.entries)..where((e) => e.categoryId.equals(id)))
          .write(EntriesCompanion(categoryId: Value(moveTo)));
      await (_db.update(_db.recurringRules)
            ..where((r) => r.categoryId.equals(id)))
          .write(RecurringRulesCompanion(categoryId: Value(moveTo)));
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    });
  }
}
