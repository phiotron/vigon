import 'package:drift/drift.dart';

import 'database.dart';

/// Danh mục chi mặc định (AC-15): khóa dịch, icon, màu cat-xx của bộ thiết
/// kế (`design/current/screens/README.md`, D-010).
const defaultExpenseCategories = [
  ('food', 'restaurant', 0xFFE65100), // cat-13
  ('transport', 'directions_bus', 0xFF1565C0), // cat-06
  ('home', 'home', 0xFF00695C), // cat-09
  ('bills', 'receipt_long', 0xFF283593), // cat-05
  ('shopping', 'shopping_bag', 0xFFAD1457), // cat-02
  ('health', 'health_and_safety', 0xFFC62828), // cat-01
  ('entertainment', 'movie', 0xFF6A1B9A), // cat-03
  ('education', 'school', 0xFF00838F), // cat-08
  ('family', 'family_restroom', 0xFF6D4C41), // cat-15
  ('other', 'more_horiz', 0xFF546E7A), // cat-16
  loanInterestCategory,
];

/// Danh mục thu mặc định (AC-15).
const defaultIncomeCategories = [
  ('salary', 'payments', 0xFF2E7D32), // cat-10
  ('bonus', 'redeem', 0xFF827717), // cat-12
  ('otherIncome', 'more_horiz', 0xFF546E7A), // cat-16
  interestIncomeCategory,
];

/// Danh mục chi "Lãi vay" — phần lãi của lần trả khoản Đi vay (AC-173).
const loanInterestCategory = ('loanInterest', 'payments', 0xFF283593); // cat-05

/// Danh mục thu "Tiền lãi" — phần lãi của lần thu khoản Cho vay (AC-173).
const interestIncomeCategory = (
  'interestIncome',
  'savings',
  0xFF2E7D32,
); // cat-10

/// Thêm hai danh mục lãi (AC-173) vào cơ sở dữ liệu có từ trước schema 8:
/// mỗi danh mục chỉ thêm khi chưa có danh mục cùng `nameKey`, xếp cuối loại
/// của nó. Cũng dùng để tạo lại khi người dùng đã xoá danh mục lãi.
Future<void> addInterestCategories(AppDatabase db) async {
  for (final (type, (key, icon, color)) in [
    (CategoryType.expense, loanInterestCategory),
    (CategoryType.income, interestIncomeCategory),
  ]) {
    await db.customStatement(
      'INSERT INTO categories (type, name_key, icon, color, sort_order) '
      'SELECT ?, ?, ?, ?, COALESCE(MAX(sort_order), -1) + 1 FROM categories '
      'WHERE type = ? AND NOT EXISTS '
      '(SELECT 1 FROM categories WHERE name_key = ?)',
      [type.index, key, icon, color, type.index, key],
    );
  }
}

/// Id danh mục lãi theo chiều khoản nợ: chi "Lãi vay" khi [expense], thu
/// "Tiền lãi" khi không; tạo lại nếu đã bị xoá (AC-173).
Future<int> interestCategoryId(AppDatabase db, {required bool expense}) async {
  final key = expense ? loanInterestCategory.$1 : interestIncomeCategory.$1;
  Future<int?> find() async => (await (db.select(
    db.categories,
  )..where((c) => c.nameKey.equals(key))).get()).firstOrNull?.id;
  final found = await find();
  if (found != null) return found;
  await addInterestCategories(db);
  return (await find())!;
}

/// Ghi danh mục và tài khoản "Tiền mặt" mặc định khi tạo cơ sở dữ liệu lần đầu.
Future<void> seedDefaults(AppDatabase db) async {
  await db.batch((b) {
    b.insert(
      db.accounts,
      AccountsCompanion.insert(nameKey: const Value('cash')),
    );
    var order = 0;
    for (final (key, icon, color) in defaultExpenseCategories) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          type: CategoryType.expense,
          nameKey: Value(key),
          icon: icon,
          color: color,
          sortOrder: Value(order++),
        ),
      );
    }
    order = 0;
    for (final (key, icon, color) in defaultIncomeCategories) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          type: CategoryType.income,
          nameKey: Value(key),
          icon: icon,
          color: color,
          sortOrder: Value(order++),
        ),
      );
    }
  });
}
