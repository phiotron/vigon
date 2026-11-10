import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/appearance_sheet.dart';
import 'package:vigon/src/ui/choice_segments.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../helpers.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
}

void main() {
  testWidgets('Giao diện & ngôn ngữ: hai hàng cùng mở một bảng kéo, chọn là '
      'áp dụng ngay (D-038)', (tester) async {
    final db = await pumpApp(tester);
    await _openSettings(tester);
    // Nhóm Giao diện & ngôn ngữ nằm gần cuối màn (2026-11-10).
    await tester.scrollUntilVisible(find.text('Giao diện & ngôn ngữ'), 300);

    expect(
      find.widgetWithText(SettingsGroupTitle, 'Giao diện & ngôn ngữ'),
      findsOneWidget,
    );
    // Không còn hai nhóm rời nhau.
    expect(find.widgetWithText(SettingsGroupTitle, 'Giao diện'), findsNothing);
    expect(find.widgetWithText(SettingsGroupTitle, 'Ngôn ngữ'), findsNothing);

    // Giá trị nằm bên phải trong chính hàng.
    final themeRow = find.widgetWithText(SettingsNavRow, 'Giao diện');
    expect(
      find.descendant(of: themeRow, matching: find.text('Theo hệ thống')),
      findsOneWidget,
    );
    final languageRow = find.widgetWithText(SettingsNavRow, 'Ngôn ngữ');
    expect(
      find.descendant(of: languageRow, matching: find.text('Tiếng Việt')),
      findsOneWidget,
    );

    // Mở từ hàng ngôn ngữ cũng ra cùng bảng kéo.
    await tester.tap(languageRow);
    await settle(tester);
    expect(find.byType(AppearanceSheet), findsOneWidget);
    expect(find.byType(ChoiceSegments<ThemeMode>), findsOneWidget);
    expect(find.byType(ChoiceSegments<String>), findsOneWidget);

    await tester.tap(find.text('Tối'));
    await settle(tester);
    expect(
      await tester.runAsync(
        () => SettingsRepository(db).watchThemeMode().first,
      ),
      ThemeMode.dark,
    );

    // Done chỉ đóng bảng, giá trị mới đã nằm trên hàng.
    await tester.tap(find.text('Xong'));
    await settle(tester);
    expect(find.byType(AppearanceSheet), findsNothing);
    expect(
      find.descendant(of: themeRow, matching: find.text('Tối')),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Đổi ngôn ngữ trong bảng kéo: áp dụng ngay, bảng vẫn mở và đổi '
      'chữ tại chỗ (D-038)', (tester) async {
    final db = await pumpApp(tester, localeCode: 'en');
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);

    await tester.scrollUntilVisible(find.text('Theme'), 300);
    await tester.tap(find.text('Theme'));
    await settle(tester);
    final sheet = find.byType(AppearanceSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Appearance & language')),
      findsOneWidget,
    );

    await tester.tap(find.text('Tiếng Việt'));
    await settle(tester);

    expect(
      await tester.runAsync(
        () => SettingsRepository(db).watchLocaleCode().first,
      ),
      'vi',
    );
    // Bảng không bị đóng và chữ bên trong đã sang tiếng Việt.
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Giao diện & ngôn ngữ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Ngôn ngữ')),
      findsOneWidget,
    );
    expect(find.text('Xong'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
