import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/providers.dart';

/// Cơ sở dữ liệu trong bộ nhớ cho widget test. Phải tạo bên trong thân
/// `testWidgets`; tạo ở `setUp` thì thao tác đầu tiên bị treo.
AppDatabase _memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Chờ thao tác cơ sở dữ liệu thật xong rồi vẽ lại.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<AppDatabase> _pumpApp(WidgetTester tester, {String? localeCode}) async {
  final db = _memoryDatabase();
  await tester.runAsync(() => SettingsRepository(db).setLocaleCode(localeCode));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: VigonApp(router: createRouter()),
    ),
  );
  await _settle(tester);
  return db;
}

/// Gỡ cây widget và đóng cơ sở dữ liệu để không còn stream treo khi test kết thúc.
Future<void> _dispose(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(db.close);
}

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

void main() {
  testWidgets('chữ giao diện theo ngôn ngữ đã chọn (AC-36)', (tester) async {
    final db = await _pumpApp(tester, localeCode: 'vi');
    expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsOneWidget);

    await tester.runAsync(() => SettingsRepository(db).setLocaleCode('en'));
    await _settle(tester);
    expect(find.text('Tap − to record your first expense'), findsOneWidget);
    await _dispose(tester, db);
  });

  testWidgets('đổi giao diện tối trong Cài đặt (AC-35)', (tester) async {
    final db = await _pumpApp(tester, localeCode: 'vi');
    expect(_themeMode(tester), ThemeMode.system);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tối'));
    await _settle(tester);
    expect(_themeMode(tester), ThemeMode.dark);
    await _dispose(tester, db);
  });
}
