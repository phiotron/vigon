import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/data/database.dart';

import 'helpers.dart';

void main() {
  test('MainActivity tat lien ket sau cua Flutter: app ngoai khong day duong '
      'dan tuy y vao go_router (mac dinh Flutter la bat)', () {
    final xml = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final activity = RegExp(
      r'<activity\b.*?</activity>',
      dotAll: true,
    ).firstMatch(xml)![0]!;
    final meta = RegExp(
      r'<meta-data[^>]*flutter_deeplinking_enabled[^>]*>',
      dotAll: true,
    ).firstMatch(activity);
    expect(meta, isNotNull, reason: 'thieu flutter_deeplinking_enabled');
    expect(meta![0], contains('android:value="false"'));
  });

  for (final path in ['/entry/abc', '/transfer/xyz', '/entry/1.5']) {
    testWidgets('id khong phai so $path: ve man chinh, khong nem loi', (
      tester,
    ) async {
      final db = await pumpApp(tester);
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go(path);
      await settle(tester);
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byType(Scaffold), findsWidgets);
      await disposeApp(tester, db);
    });
  }

  testWidgets('id hop le van mo man sua khoan (khong hong duong cu)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final id = await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 100,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/entry/$id');
    await settle(tester);
    expect(tester.takeException(), isNull);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    expect(router.routeInformationProvider.value.uri.path, '/entry/$id');
    await disposeApp(tester, db);
  });
}
