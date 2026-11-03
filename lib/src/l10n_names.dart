import '../l10n/app_localizations.dart';

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
