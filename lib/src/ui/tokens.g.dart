// SINH TỰ ĐỘNG bởi tool/gen_tokens.py từ design-mobile/screens/tokens.json.
// Không sửa tay: sửa tokens.json rồi chạy `python tool/gen_tokens.py` (D-010).
// ignore_for_file: public_member_api_docs

import 'package:flutter/painting.dart';

/// Màu và bóng của một chủ đề (sáng hoặc tối) theo token thiết kế.
class VgPalette {
  const VgPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.outlineVariant,
    required this.income,
    required this.onIncome,
    required this.expense,
    required this.onExpense,
    required this.error,
    required this.onError,
    required this.swipeDelete,
    required this.inverseSurface,
    required this.inverseInk,
    required this.inversePrimary,
    required this.focus,
    required this.scrim,
    required this.onCat,
    required this.shadowSheet,
    required this.shadowFloat,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color outlineVariant;
  final Color income;
  final Color onIncome;
  final Color expense;
  final Color onExpense;
  final Color error;
  final Color onError;
  final Color swipeDelete;
  final Color inverseSurface;
  final Color inverseInk;
  final Color inversePrimary;
  final Color focus;
  final Color scrim;
  final Color onCat;
  final List<BoxShadow> shadowSheet;
  final List<BoxShadow> shadowFloat;

  /// Chuyển dần giữa hai chủ đề khi đổi sáng/tối.
  static VgPalette lerp(VgPalette a, VgPalette b, double t) => VgPalette(
    primary: Color.lerp(a.primary, b.primary, t)!,
    onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
    primaryContainer: Color.lerp(a.primaryContainer, b.primaryContainer, t)!,
    onPrimaryContainer: Color.lerp(
      a.onPrimaryContainer,
      b.onPrimaryContainer,
      t,
    )!,
    secondaryContainer: Color.lerp(
      a.secondaryContainer,
      b.secondaryContainer,
      t,
    )!,
    onSecondaryContainer: Color.lerp(
      a.onSecondaryContainer,
      b.onSecondaryContainer,
      t,
    )!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    surfaceContainer: Color.lerp(a.surfaceContainer, b.surfaceContainer, t)!,
    surfaceContainerHigh: Color.lerp(
      a.surfaceContainerHigh,
      b.surfaceContainerHigh,
      t,
    )!,
    ink: Color.lerp(a.ink, b.ink, t)!,
    inkMuted: Color.lerp(a.inkMuted, b.inkMuted, t)!,
    outline: Color.lerp(a.outline, b.outline, t)!,
    outlineVariant: Color.lerp(a.outlineVariant, b.outlineVariant, t)!,
    income: Color.lerp(a.income, b.income, t)!,
    onIncome: Color.lerp(a.onIncome, b.onIncome, t)!,
    expense: Color.lerp(a.expense, b.expense, t)!,
    onExpense: Color.lerp(a.onExpense, b.onExpense, t)!,
    error: Color.lerp(a.error, b.error, t)!,
    onError: Color.lerp(a.onError, b.onError, t)!,
    swipeDelete: Color.lerp(a.swipeDelete, b.swipeDelete, t)!,
    inverseSurface: Color.lerp(a.inverseSurface, b.inverseSurface, t)!,
    inverseInk: Color.lerp(a.inverseInk, b.inverseInk, t)!,
    inversePrimary: Color.lerp(a.inversePrimary, b.inversePrimary, t)!,
    focus: Color.lerp(a.focus, b.focus, t)!,
    scrim: Color.lerp(a.scrim, b.scrim, t)!,
    onCat: Color.lerp(a.onCat, b.onCat, t)!,
    shadowSheet: BoxShadow.lerpList(a.shadowSheet, b.shadowSheet, t)!,
    shadowFloat: BoxShadow.lerpList(a.shadowFloat, b.shadowFloat, t)!,
  );
}

const vgLight = VgPalette(
  primary: Color(0xFF2E7D6B),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFB8EDDC),
  onPrimaryContainer: Color(0xFF002019),
  secondaryContainer: Color(0xFFCCE8DF),
  onSecondaryContainer: Color(0xFF062019),
  surface: Color(0xFFF7FAF8),
  surfaceContainer: Color(0xFFECF2EF),
  surfaceContainerHigh: Color(0xFFE3EBE7),
  ink: Color(0xFF171D1B),
  inkMuted: Color(0xFF3F4946),
  outline: Color(0xFF6F7975),
  outlineVariant: Color(0xFFBEC9C4),
  income: Color(0xFF2E7D32),
  onIncome: Color(0xFFFFFFFF),
  expense: Color(0xFFC62828),
  onExpense: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  swipeDelete: Color(0xFFFFDAD6),
  inverseSurface: Color(0xFF2C3230),
  inverseInk: Color(0xFFEDF2EF),
  inversePrimary: Color(0xFF8CD5BF),
  focus: Color(0xFF0E5244),
  scrim: Color(0x66000000),
  onCat: Color(0xFFFFFFFF),
  shadowSheet: [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, -2), blurRadius: 12),
  ],
  shadowFloat: [
    BoxShadow(color: Color(0x2E000000), offset: Offset(0, 3), blurRadius: 8),
  ],
);

const vgDark = VgPalette(
  primary: Color(0xFF8CD5BF),
  onPrimary: Color(0xFF00382D),
  primaryContainer: Color(0xFF0E5244),
  onPrimaryContainer: Color(0xFFB8EDDC),
  secondaryContainer: Color(0xFF334B44),
  onSecondaryContainer: Color(0xFFCCE8DF),
  surface: Color(0xFF0F1513),
  surfaceContainer: Color(0xFF1B211F),
  surfaceContainerHigh: Color(0xFF252B29),
  ink: Color(0xFFDEE4E1),
  inkMuted: Color(0xFFBEC9C4),
  outline: Color(0xFF89938F),
  outlineVariant: Color(0xFF3F4946),
  income: Color(0xFF81C784),
  onIncome: Color(0xFF0A1F0B),
  expense: Color(0xFFEF9A9A),
  onExpense: Color(0xFF2D0A0A),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  swipeDelete: Color(0xFF5C1714),
  inverseSurface: Color(0xFFDEE4E1),
  inverseInk: Color(0xFF2C3230),
  inversePrimary: Color(0xFF0E5244),
  focus: Color(0xFF8CD5BF),
  scrim: Color(0x99000000),
  onCat: Color(0xFFFFFFFF),
  shadowSheet: [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, -2), blurRadius: 12),
  ],
  shadowFloat: [
    BoxShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 8),
  ],
);

/// 16 màu danh mục cat-01 … cat-16, giống nhau ở hai chủ đề; icon trên đó dùng `onCat`.
const vgCategoryColors = <Color>[
  Color(0xFFC62828), // cat-01
  Color(0xFFAD1457), // cat-02
  Color(0xFF6A1B9A), // cat-03
  Color(0xFF4527A0), // cat-04
  Color(0xFF283593), // cat-05
  Color(0xFF1565C0), // cat-06
  Color(0xFF0277BD), // cat-07
  Color(0xFF00838F), // cat-08
  Color(0xFF00695C), // cat-09
  Color(0xFF2E7D32), // cat-10
  Color(0xFF558B2F), // cat-11
  Color(0xFF827717), // cat-12
  Color(0xFFE65100), // cat-13
  Color(0xFFBF360C), // cat-14
  Color(0xFF6D4C41), // cat-15
  Color(0xFF546E7A), // cat-16
];

/// Khoảng cách (space-*).
abstract final class VgSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;
}

/// Bo góc (radius-*).
abstract final class VgRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
  static const double full = 999;
}

/// Vùng chạm tối thiểu và chiều cao thanh tiêu đề, dp/pt.
abstract final class VgSize {
  static const double tapMin = 48;
  static const double tapKey = 56;
  static const double tapMain = 64;
  static const double appbar = 56;
}

/// Họ chữ của app, khai trong pubspec.yaml (file font ở assets/fonts/).
const vgFontFamily = 'BeVietnamPro';

/// 12 kiểu chữ, đều mang họ chữ riêng để không rơi về font hệ thống khi
/// dùng trực tiếp (nút, chip, hộp thoại). Số tiền dùng số đều độ rộng.
abstract final class VgType {
  static const amountXl = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 40,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const amountMd = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 18,
    height: 1.3333,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const titleLg = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 22,
    height: 1.2727,
    fontWeight: FontWeight.w600,
  );
  static const titleMd = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 18,
    height: 1.3333,
    fontWeight: FontWeight.w600,
  );
  static const titleSm = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const bodyMd = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodySm = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 14,
    height: 1.4286,
    fontWeight: FontWeight.w400,
  );
  static const labelLg = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const labelMd = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 14,
    height: 1.4286,
    fontWeight: FontWeight.w500,
  );
  static const labelSm = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 12,
    height: 1.3333,
    fontWeight: FontWeight.w500,
  );
  static const keyDigit = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 24,
    height: 1.3333,
    fontWeight: FontWeight.w500,
  );
  static const keyGlyph = TextStyle(
    fontFamily: vgFontFamily,
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w500,
  );
}
