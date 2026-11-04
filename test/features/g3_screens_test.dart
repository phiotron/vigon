import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

void main() {
  testWidgets('thêm danh mục từ Cài đặt → Danh mục (AC-16)', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.tap(find.text('Danh mục'));
    await settle(tester);
    await tester.tap(find.byTooltip('Thêm danh mục'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Cà phê');
    await tester.tap(find.byKey(const ValueKey('icon-local_cafe')));
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final added = await tester.runAsync(
      () => (db.select(
        db.categories,
      )..where((c) => c.name.equals('Cà phê'))).getSingle(),
    );
    expect(added!.icon, 'local_cafe');
    await tester.dragUntilVisible(
      find.text('Cà phê'),
      find.byType(ReorderableListView).first,
      const Offset(0, -200),
    );
    expect(find.text('Cà phê'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('chuyển tiền giữa hai tài khoản trên màn Chuyển tiền (AC-19)', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 500000),
    );
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.tap(find.text('Tài khoản'));
    await settle(tester);
    await tester.tap(find.byTooltip('Chuyển tiền'));
    await settle(tester);
    for (final k in '200000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, k));
      await tester.pump();
    }
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows!.single.type, EntryType.transfer);
    expect(
      (rows.single.accountId, rows.single.toAccountId, rows.single.amount),
      (1, 2, 200000),
    );
    expect(findPlainText('-200.000 ₫'), findsOneWidget); // Tiền mặt
    expect(findPlainText('700.000 ₫'), findsOneWidget); // Thẻ
    await disposeApp(tester, db);
  });
}
