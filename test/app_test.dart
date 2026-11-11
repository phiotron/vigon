import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/settings_repository.dart';

import 'helpers.dart';

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets('chữ giao diện theo ngôn ngữ đã chọn (AC-36)', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Ghi khoản chi đầu tiên'), findsOneWidget);

    await tester.runAsync(() => SettingsRepository(db).setLocaleCode('en'));
    await settle(tester);
    expect(find.text('Log your first expense'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('đổi giao diện tối trong Cài đặt (AC-35)', (tester) async {
    final db = await pumpApp(tester);
    expect(_themeMode(tester), ThemeMode.system);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    // Nhóm Giao diện & ngôn ngữ nằm gần cuối màn (2026-11-10).
    await tester.scrollUntilVisible(find.text('Giao diện'), 300);
    // Cho hàng nằm hẳn trong màn (không sát mép dưới).
    await tester.ensureVisible(find.text('Giao diện'));
    await settle(tester);
    await tester.tap(find.text('Giao diện'));
    await settle(tester);
    await tester.tap(find.text('Tối'));
    await settle(tester);
    expect(_themeMode(tester), ThemeMode.dark);
    await disposeApp(tester, db);
  });
}
