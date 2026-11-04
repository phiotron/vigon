import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tokens.g.dart';

// Họ chữ do tool/gen_tokens.py sinh trong tokens.g.dart; xuất lại cho nơi chỉ
// import theme.dart.
export 'tokens.g.dart' show vgFontFamily;

/// Màu không có chỗ trong [ColorScheme]: thu, chi, vuốt xóa, focus, bóng.
class ViGonColors extends ThemeExtension<ViGonColors> {
  const ViGonColors(this.palette);

  final VgPalette palette;

  @override
  ViGonColors copyWith({VgPalette? palette}) =>
      ViGonColors(palette ?? this.palette);

  @override
  ViGonColors lerp(ViGonColors? other, double t) => other == null
      ? this
      : ViGonColors(VgPalette.lerp(palette, other.palette, t));
}

extension ViGonTheme on BuildContext {
  /// Token màu của chủ đề đang dùng: `context.vg.income`.
  VgPalette get vg => Theme.of(this).extension<ViGonColors>()!.palette;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? vgDark : vgLight;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    // Thiết kế không có màu phụ riêng; giữ cùng tông màu gốc.
    secondary: p.primary,
    onSecondary: p.onPrimary,
    secondaryContainer: p.secondaryContainer,
    onSecondaryContainer: p.onSecondaryContainer,
    error: p.error,
    onError: p.onError,
    // Nền vuốt xóa và icon trên nó (4.2).
    errorContainer: p.swipeDelete,
    onErrorContainer: p.error,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surfaceContainer,
    surfaceContainerHigh: p.surfaceContainerHigh,
    surfaceContainerHighest: p.surfaceContainerHigh,
    surfaceTint: Colors.transparent,
    outline: p.outline,
    outlineVariant: p.outlineVariant,
    inverseSurface: p.inverseSurface,
    onInverseSurface: p.inverseInk,
    inversePrimary: p.inversePrimary,
    scrim: p.scrim,
    shadow: Colors.black,
  );

  TextStyle ink(TextStyle s, [Color? c]) => s.copyWith(color: c ?? p.ink);
  final textTheme = TextTheme(
    titleLarge: ink(VgType.titleLg),
    titleMedium: ink(VgType.titleMd),
    titleSmall: ink(VgType.titleSm),
    bodyLarge: ink(VgType.bodyMd),
    bodyMedium: ink(VgType.bodySm),
    bodySmall: ink(VgType.labelSm.copyWith(fontWeight: FontWeight.w400)),
    labelLarge: ink(VgType.labelMd),
    labelMedium: ink(VgType.labelSm),
    labelSmall: ink(VgType.labelSm),
  );
  const sheetTop = BorderRadius.vertical(top: Radius.circular(VgRadius.xl));

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: vgFontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: p.surface,
    extensions: [ViGonColors(p)],
    // Tiêu đề căn trái ở cả iPhone và Android (README thiết kế).
    appBarTheme: AppBarTheme(
      centerTitle: false,
      // Màn có nút quay lại: chữ bắt đầu ngay sau nút (x = 60, bản vẽ 3.1).
      titleSpacing: VgSpace.s1,
      toolbarHeight: VgSize.appbar,
      backgroundColor: p.surface,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    dividerTheme: DividerThemeData(color: p.outlineVariant, space: 1),
    listTileTheme: const ListTileThemeData(minTileHeight: VgSize.tapKey),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VgRadius.xl),
      ),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceContainer,
      modalBackgroundColor: p.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: sheetTop),
      dragHandleColor: p.outline,
      dragHandleSize: const Size(32, 4),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceContainer,
      surfaceTintColor: Colors.transparent,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.surfaceContainer),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.inverseSurface,
      contentTextStyle: ink(VgType.bodySm, p.inverseInk),
      actionTextColor: p.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: p.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
      ),
      labelStyle: textTheme.labelLarge,
      // Chip cao 40, vùng chạm 48 (MaterialTapTargetSize.padded mặc định).
      padding: const EdgeInsets.fromLTRB(VgSpace.s2, 9, VgSpace.s3, 9),
      labelPadding: const EdgeInsets.only(left: VgSpace.s1),
      iconTheme: IconThemeData(color: p.inkMuted, size: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
        borderSide: BorderSide(color: p.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
        borderSide: BorderSide(color: p.outline),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primaryContainer,
      foregroundColor: p.onPrimaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VgRadius.lg),
      ),
    ),
    // Nút hộp thoại (T1_Nut): cao 40, bo tròn, label-md; vùng chạm 48. Nút
    // lớn (Lưu, − / +) tự đặt kiểu riêng.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(VgSize.tapMin, 40),
        textStyle: VgType.labelMd,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(VgSize.tapMin, 40),
        foregroundColor: p.primary,
        textStyle: VgType.labelMd,
        shape: const StadiumBorder(),
      ),
    ),
    // Mũi tên quay lại giống nhau trên iPhone và Android; iPhone không có nút
    // Back cứng nên màn con nào cũng có mũi tên này.
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) =>
          const Icon(Symbols.arrow_back_rounded),
    ),
    // iPhone dùng chuyển trang Cupertino (vuốt mép trái để quay lại) theo
    // mặc định của PageTransitionsTheme; không cần khai riêng.
  );
}

/// Nút xác nhận hành động xóa ở bước cuối (nền `error`, T1_Nut).
ButtonStyle dangerButtonStyle(BuildContext context) => FilledButton.styleFrom(
  backgroundColor: context.vg.error,
  foregroundColor: context.vg.onError,
);

/// Nút lớn (Lưu, − / +): cao [height], bo `radius-lg`, chữ label-lg.
ButtonStyle bigButtonStyle({
  required Color background,
  required Color foreground,
  double height = VgSize.tapKey,
}) => FilledButton.styleFrom(
  backgroundColor: background,
  foregroundColor: foreground,
  minimumSize: Size.fromHeight(height),
  textStyle: VgType.labelLg,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VgRadius.lg),
  ),
);
