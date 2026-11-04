import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/tokens.g.dart';

/// Màu '#RRGGBB' trong tokens.json.
Color _hex(String v) => Color(int.parse('FF${v.substring(1)}', radix: 16));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final tokens = jsonDecode(
    File('design-mobile/screens/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final colorTokens = {
    for (final t in (tokens['color']['tokens'] as List))
      t['name'] as String: Map<String, String>.from(t['value'] as Map),
  };

  test('tokens.g.dart khớp tokens.json (quên chạy tool/gen_tokens.py thì '
      'hỏng) (UI-01)', () {
    for (final (theme, p) in [('light', vgLight), ('dark', vgDark)]) {
      final generated = {
        'primary': p.primary,
        'on-primary': p.onPrimary,
        'surface': p.surface,
        'surface-container-high': p.surfaceContainerHigh,
        'ink': p.ink,
        'ink-muted': p.inkMuted,
        'income': p.income,
        'expense': p.expense,
        'error': p.error,
        'swipe-delete': p.swipeDelete,
        'inverse-surface': p.inverseSurface,
      };
      generated.forEach((name, color) {
        expect(color, _hex(colorTokens[name]![theme]!), reason: '$theme $name');
      });
    }
    for (var i = 0; i < 16; i++) {
      final name = 'cat-${(i + 1).toString().padLeft(2, '0')}';
      expect(vgCategoryColors[i], _hex(colorTokens[name]!['light']!));
    }
  });

  test('theme dùng màu token, không sinh màu từ seed (UI-01)', () {
    for (final (brightness, p) in [
      (Brightness.light, vgLight),
      (Brightness.dark, vgDark),
    ]) {
      final theme = buildTheme(brightness);
      final s = theme.colorScheme;
      expect(s.brightness, brightness);
      expect(s.primary, p.primary);
      expect(s.primaryContainer, p.primaryContainer);
      expect(s.secondaryContainer, p.secondaryContainer);
      expect(s.surface, p.surface);
      expect(s.surfaceContainer, p.surfaceContainer);
      expect(s.surfaceContainerHigh, p.surfaceContainerHigh);
      expect(s.onSurface, p.ink);
      expect(s.onSurfaceVariant, p.inkMuted);
      expect(s.outline, p.outline);
      expect(s.error, p.error);
      expect(s.inverseSurface, p.inverseSurface);
      expect(theme.scaffoldBackgroundColor, p.surface);
      expect(theme.extension<ViGonColors>()!.palette.income, p.income);
      expect(theme.appBarTheme.centerTitle, isFalse);
      expect(theme.textTheme.titleLarge!.fontSize, VgType.titleLg.fontSize);
      expect(theme.textTheme.bodyLarge!.fontSize, VgType.bodyMd.fontSize);
    }
  });

  test('chữ Be Vietnam Pro được khai và đóng trong app (UI-02)', () {
    expect(
      buildTheme(Brightness.light).textTheme.bodyLarge!.fontFamily,
      vgFontFamily,
    );
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: $vgFontFamily'));
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final path = 'assets/fonts/BeVietnamPro-$w.ttf';
      expect(pubspec, contains(path));
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
    expect(VgType.amountXl.fontFeatures, [const FontFeature.tabularFigures()]);
  });

  test('các cặp màu đang dùng đủ tương phản ở hai chủ đề (UI-05, AC-40)', () {
    for (final (theme, p) in [('sáng', vgLight), ('tối', vgDark)]) {
      // Chữ: 4,5:1.
      final text = <String, (Color, Color)>{
        'ink/surface': (p.ink, p.surface),
        'ink/surface-container-high': (p.ink, p.surfaceContainerHigh),
        'ink-muted/surface': (p.inkMuted, p.surface),
        'ink-muted/surface-container': (p.inkMuted, p.surfaceContainer),
        'ink-muted/surface-container-high': (
          p.inkMuted,
          p.surfaceContainerHigh,
        ),
        'on-primary/primary': (p.onPrimary, p.primary),
        'on-primary-container': (p.onPrimaryContainer, p.primaryContainer),
        'on-secondary-container': (
          p.onSecondaryContainer,
          p.secondaryContainer,
        ),
        'on-income/income': (p.onIncome, p.income),
        'on-expense/expense': (p.onExpense, p.expense),
        'on-error/error': (p.onError, p.error),
        'inverse-ink/inverse-surface': (p.inverseInk, p.inverseSurface),
        'inverse-primary/inverse-surface': (p.inversePrimary, p.inverseSurface),
        'income/surface': (p.income, p.surface),
        'expense/surface': (p.expense, p.surface),
        'expense/surface-container-high': (p.expense, p.surfaceContainerHigh),
        'error/surface': (p.error, p.surface),
        'error/surface-container-high': (p.error, p.surfaceContainerHigh),
        'primary/surface': (p.primary, p.surface),
      };
      text.forEach((name, pair) {
        expect(
          _contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '$theme $name',
        );
      });
      // Viền, icon, vòng focus: 3:1.
      final ui = <String, (Color, Color)>{
        'outline/surface-container-high': (p.outline, p.surfaceContainerHigh),
        'focus/surface': (p.focus, p.surface),
        'error/swipe-delete': (p.error, p.swipeDelete),
      };
      ui.forEach((name, pair) {
        expect(
          _contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(3),
          reason: '$theme $name',
        );
      });
    }
    for (final c in vgCategoryColors) {
      expect(_contrast(vgLight.onCat, c), greaterThanOrEqualTo(3));
    }
  });
}
