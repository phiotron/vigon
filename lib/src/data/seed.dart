import 'package:drift/drift.dart';

import 'database.dart';

/// Danh mục chi mặc định (AC-15): khóa dịch, icon, màu trong [categoryColors].
const defaultExpenseCategories = [
  ('food', 'restaurant', 0xFFC62828),
  ('transport', 'directions_bus', 0xFF1565C0),
  ('home', 'home', 0xFF5D4037),
  ('bills', 'receipt_long', 0xFFE65100),
  ('shopping', 'shopping_bag', 0xFF6A1B9A),
  ('health', 'medical_services', 0xFF00695C),
  ('entertainment', 'movie', 0xFFAD1457),
  ('education', 'school', 0xFF283593),
  ('family', 'family_restroom', 0xFF00838F),
  ('other', 'more_horiz', 0xFF455A64),
];

/// Danh mục thu mặc định (AC-15).
const defaultIncomeCategories = [
  ('salary', 'payments', 0xFF2E7D32),
  ('bonus', 'redeem', 0xFF558B2F),
  ('otherIncome', 'more_horiz', 0xFF455A64),
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
