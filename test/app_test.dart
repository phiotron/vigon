import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/settings_repository.dart';

import 'helpers.dart';

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets('chữ giao diện theo ngôn ngữ đã chọn (AC-36)', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsOneWidget);

    await tester.runAsync(() => SettingsRepository(db).setLocaleCode('en'));
    await settle(tester);
    expect(find.text('Tap − to record your first expense'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('đổi giao diện tối trong Cài đặt (AC-35)', (tester) async {
    final db = await pumpApp(tester);
    expect(_themeMode(tester), ThemeMode.system);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await settle(tester);
    expect(_themeMode(tester), ThemeMode.dark);
    await disposeApp(tester, db);
  });
}
