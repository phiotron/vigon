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
];

/// Danh mục thu mặc định (AC-15).
const defaultIncomeCategories = [
  ('salary', 'payments', 0xFF2E7D32), // cat-10
  ('bonus', 'redeem', 0xFF827717), // cat-12
  ('otherIncome', 'more_horiz', 0xFF546E7A), // cat-16
];

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
