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
    int? budget,
    int? budgetOriginal,
    String? budgetCurrency,
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
            budget: Value(budget),
            budgetOriginal: Value(budgetOriginal),
            budgetCurrency: Value(budgetCurrency),
          ),
        );
  }

  /// Đổi tên, icon, màu (AC-16), và hạn mức tháng nếu truyền [budget] (AC-54). Có [name] thì bỏ tên mặc định theo ngôn ngữ;
  /// [name] null thì giữ tên đang có. `budget` là số dẫn xuất quy về Tiền tệ
  /// chính; `budgetOriginal`/`budgetCurrency` là số gốc người dùng nhập (D-037).
  Future<void> edit(
    int id, {
    String? name,
    required String icon,
    required int color,
    Value<int?> budget = const Value.absent(),
    Value<int?> budgetOriginal = const Value.absent(),
    Value<String?> budgetCurrency = const Value.absent(),
  }) => (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
    CategoriesCompanion(
      name: name == null ? const Value.absent() : Value(name),
      nameKey: name == null ? const Value.absent() : const Value(null),
      icon: Value(icon),
      color: Value(color),
      budget: budget,
      budgetOriginal: budgetOriginal,
      budgetCurrency: budgetCurrency,
    ),
  );

  /// Đặt hạn mức chi tháng của danh mục; null là bỏ hạn mức (AC-54).
  /// Giá trị phải > 0 (ràng buộc CHECK của bảng cũng chặn).
  Future<void> setBudget(int id, int? budget) {
    if (budget != null && budget <= 0) {
      throw ArgumentError.value(budget, 'budget', 'phải lớn hơn 0');
    }
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(budget: Value(budget)),
    );
  }

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
      // Gợi ý theo người thụ hưởng trỏ tới danh mục này cũng chuyển theo (AC-97).
      await (_db.update(_db.payeeSuggestions)
            ..where((s) => s.categoryId.equals(id)))
          .write(PayeeSuggestionsCompanion(categoryId: Value(moveTo)));
      await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    });
  }
}
