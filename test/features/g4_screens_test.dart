import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';

import '../helpers.dart';

void main() {
  testWidgets('ghi khoản có Lặp lại hằng tháng thì tạo chuỗi định kỳ (AC-23)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Nhà cửa'));
    await settle(tester);
    for (final k in '3000000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, k));
      await tester.pump();
    }
    await tester.tap(find.text('Không lặp'));
    await settle(tester);
    await tester.tap(find.text('Hằng tháng'));
    await settle(tester);
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final rule = await tester.runAsync(
      () => db.select(db.recurringRules).getSingle(),
    );
    expect(
      (rule!.frequency, rule.amount, rule.startDate),
      (RecurrenceFrequency.monthly, 3000000, '2026-11-03'),
    );
    final entries = await tester.runAsync(() => db.select(db.entries).get());
    expect(entries!.single.recurringRuleId, rule.id);
    await disposeApp(tester, db);
  });

  testWidgets(
    'thanh ngân sách: đã chi / hạn mức, vượt thì ghi chữ "Vượt" (AC-26, AC-27)',
    (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setBudget(100000));
      await pumpApp(tester, db: db);
      expect(
        findPlainText('Ngân sách tháng: Đã chi 0 ₫ / 100.000 ₫'),
        findsOneWidget,
      );

      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 150000,
        categoryId: 1,
      );
      expect(findPlainText('Ngân sách tháng: Vượt 50.000 ₫'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1);
      await disposeApp(tester, db);
    },
  );

  testWidgets('chưa đặt ngân sách thì không hiện thanh', (tester) async {
    final db = await pumpApp(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await disposeApp(tester, db);
  });
}
