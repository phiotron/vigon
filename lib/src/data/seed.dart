import 'package:drift/drift.dart';

import 'database.dart';

/// Danh mục chi mặc định (AC-15): khóa dịch, icon, màu.
const defaultExpenseCategories = [
  ('food', 'restaurant', 0xFFE57373),
  ('transport', 'directions_bus', 0xFF64B5F6),
  ('home', 'home', 0xFF8D6E63),
  ('bills', 'receipt_long', 0xFFFFB74D),
  ('shopping', 'shopping_bag', 0xFFBA68C8),
  ('health', 'medical_services', 0xFF4DB6AC),
  ('entertainment', 'movie', 0xFFF06292),
  ('education', 'school', 0xFF7986CB),
  ('family', 'family_restroom', 0xFFA1887F),
  ('other', 'more_horiz', 0xFF90A4AE),
];

/// Danh mục thu mặc định (AC-15).
const defaultIncomeCategories = [
  ('salary', 'payments', 0xFF81C784),
  ('bonus', 'redeem', 0xFFAED581),
  ('otherIncome', 'more_horiz', 0xFF90A4AE),
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
