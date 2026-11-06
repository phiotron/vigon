import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/home/home_screen.dart';
import 'package:vigon/src/providers.dart';

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

  testWidgets(
    'thanh ngân sách tính theo tháng đang xem; xem năm thì ẩn (D-028)',
    (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setBudget(100000));
      await pumpApp(tester, db: db);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 150000,
        categoryId: 1,
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 30000,
        categoryId: 1,
        date: '2026-10-15',
      );
      expect(findPlainText('Ngân sách tháng: Vượt 50.000 ₫'), findsOneWidget);

      // Tháng 10: chỉ tính khoản của tháng 10, không lấy số tháng 11.
      await tester.tap(find.byTooltip('Kỳ trước'));
      await settle(tester);
      expect(
        findPlainText('Ngân sách tháng: Đã chi 30.000 ₫ / 100.000 ₫'),
        findsOneWidget,
      );
      expect(find.textContaining('Vượt'), findsNothing);

      // Tháng 9 chưa có khoản nào.
      await tester.tap(find.byTooltip('Kỳ trước'));
      await settle(tester);
      expect(
        findPlainText('Ngân sách tháng: Đã chi 0 ₫ / 100.000 ₫'),
        findsOneWidget,
      );

      // Xem cả năm: không ứng với một tháng nào, ẩn thanh.
      ProviderScope.containerOf(tester.element(find.byType(BudgetBar)))
          .read(periodProvider.notifier)
          .selectType(PeriodType.year);
      await settle(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await disposeApp(tester, db);
    },
  );

  test('budgetMonthFor: tháng, ngày, tuần vắt hai tháng, năm (D-028)', () {
    Period m(DateTime d, {int start = 1}) =>
        Period.containing(PeriodType.month, d, monthStartDay: start);
    String keys(Period? p) => p == null ? 'null' : '${p.fromKey}..${p.toKey}';

    final oct = m(DateTime(2026, 10, 15));
    expect(
      keys(budgetMonthFor(oct, monthStartDay: 1)),
      '2026-10-01..2026-10-31',
    );
    final day = Period.containing(PeriodType.day, DateTime(2026, 9, 3));
    expect(
      keys(budgetMonthFor(day, monthStartDay: 1)),
      '2026-09-01..2026-09-30',
    );
    // Tuần 26/10–1/11: tính tháng chứa ngày cuối (tháng 11).
    final week = Period.containing(PeriodType.week, DateTime(2026, 10, 28));
    expect(
      keys(budgetMonthFor(week, monthStartDay: 1)),
      '2026-11-01..2026-11-30',
    );
    // Tháng bắt đầu ngày 25: ngày 3/11 thuộc kỳ 25/10–24/11.
    final day25 = Period.containing(PeriodType.day, DateTime(2026, 11, 3));
    expect(
      keys(budgetMonthFor(day25, monthStartDay: 25)),
      '2026-10-25..2026-11-24',
    );
    for (final t in [PeriodType.year, PeriodType.all]) {
      expect(
        budgetMonthFor(
          Period.containing(t, DateTime(2026, 11, 3)),
          monthStartDay: 1,
        ),
        isNull,
      );
    }
    expect(
      budgetMonthFor(
        Period.custom(DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
        monthStartDay: 1,
      ),
      isNull,
    );
  });

  testWidgets('chưa đặt ngân sách thì không hiện thanh', (tester) async {
    final db = await pumpApp(tester);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await disposeApp(tester, db);
  });
}
