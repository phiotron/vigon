import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Họ chữ khai trong `pubspec.yaml`, file ở `assets/fonts/` (D-010).
const vgFontFamily = 'BeVietnamPro';

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
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
        textStyle: VgType.labelLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VgRadius.lg),
        ),
      ),
    ),
    // iPhone dùng chuyển trang Cupertino (vuốt mép trái để quay lại) theo
    // mặc định của PageTransitionsTheme; không cần khai riêng.
  );
}
