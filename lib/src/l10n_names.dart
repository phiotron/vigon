import '../l10n/app_localizations.dart';
import 'data/database.dart';

/// Tên hiển thị của danh mục và tài khoản mặc định theo `nameKey` (D-005).
/// Trả về null khi khóa không có trong bảng dịch.
String? defaultName(AppLocalizations l, String key) => switch (key) {
  'cash' => l.accountCash,
  'food' => l.categoryFood,
  'transport' => l.categoryTransport,
  'home' => l.categoryHome,
  'bills' => l.categoryBills,
  'shopping' => l.categoryShopping,
  'health' => l.categoryHealth,
  'entertainment' => l.categoryEntertainment,
  'education' => l.categoryEducation,
  'family' => l.categoryFamily,
  'other' => l.categoryOther,
  'salary' => l.categorySalary,
  'bonus' => l.categoryBonus,
  'otherIncome' => l.categoryOtherIncome,
  _ => null,
};

/// Tên người dùng đặt nếu có, không thì tên mặc định theo ngôn ngữ.
String _label(AppLocalizations l, String? name, String? nameKey) =>
    name ?? (nameKey == null ? null : defaultName(l, nameKey)) ?? '';

String categoryLabel(AppLocalizations l, Category c) =>
    _label(l, c.name, c.nameKey);

String accountLabel(AppLocalizations l, Account a) =>
    _label(l, a.name, a.nameKey);
