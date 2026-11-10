import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/repeat.dart';

import '../helpers.dart';

/// F-45 "Chọn thứ…" ở màn Nhập khoản (hôm nay trong test: thứ Ba 03/11/2026).
void main() {
  Future<AppDatabase> openRepeat(WidgetTester tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Nhà cửa'));
    await settle(tester);
    for (final k in '50000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, k));
      await tester.pump();
    }
    await tester.tap(find.text('Không lặp'));
    await settle(tester);
    await tester.tap(find.text('Chọn thứ…'));
    await settle(tester);
    return db;
  }

  testWidgets(
    'chọn T2 + T6 khi hôm nay là T3: hiện "Khoản đầu", Lưu không ghi khoản hôm nay (D-040)',
    (tester) async {
      final db = await openRepeat(tester);
      // Mặc định sáng sẵn thứ của ngày khoản (T3).
      expect(
        tester
            .widget<FilterChip>(find.byKey(const ValueKey('weekday-2')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('weekday-2'))); // bỏ T3
      await tester.tap(find.byKey(const ValueKey('weekday-1'))); // T2
      await tester.tap(find.byKey(const ValueKey('weekday-5'))); // T6
      await tester.pump();
      await tester.tap(find.byKey(const Key('weekday-done')));
      await settle(tester);

      expect(find.text('T2, T6'), findsOneWidget);
      expect(find.text('Khoản đầu: T6 6/11'), findsOneWidget);

      await tester.tap(find.text('Lưu'));
      await settle(tester);
      expect(
        find.text('Đã tạo khoản định kỳ · khoản đầu T6 6/11'),
        findsOneWidget,
      );
      final rule = await tester.runAsync(
        () => db.select(db.recurringRules).getSingle(),
      );
      expect(
        (rule!.frequency, rule.weekdays, rule.startDate),
        (
          RecurrenceFrequency.weekly,
          weekdayBit(DateTime.monday) | weekdayBit(DateTime.friday),
          '2026-11-03',
        ),
      );
      final entries = await tester.runAsync(() => db.select(db.entries).get());
      expect(entries, isEmpty);
      await disposeApp(tester, db);
    },
  );

  testWidgets('chọn đủ 7 thứ thì thành Hằng ngày, khoản hôm nay được ghi', (
    tester,
  ) async {
    final db = await openRepeat(tester);
    for (final d in [1, 3, 4, 5, 6, 7]) {
      await tester.tap(find.byKey(ValueKey('weekday-$d')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const Key('weekday-done')));
    await settle(tester);
    expect(find.text('Hằng ngày'), findsOneWidget);
    expect(find.byKey(const Key('repeat-first-on')), findsNothing);

    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final rule = await tester.runAsync(
      () => db.select(db.recurringRules).getSingle(),
    );
    expect((rule!.frequency, rule.weekdays), (RecurrenceFrequency.daily, null));
    final entries = await tester.runAsync(() => db.select(db.entries).get());
    expect(entries!.single.date, '2026-11-03');
    await disposeApp(tester, db);
  });
  testWidgets('sửa chuỗi Hằng tháng sang "Chọn thứ" (R4)', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(
      () => db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              type: EntryType.expense,
              amount: 100000,
              categoryId: const Value(3), // Nhà cửa
              accountId: 1,
              frequency: RecurrenceFrequency.monthly,
              startDate: '2026-11-03',
              lastGeneratedDate: const Value('2026-11-03'),
            ),
          ),
    );
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.tap(find.text('Khoản định kỳ'));
    await settle(tester);
    await tester.tap(find.textContaining('Nhà cửa'));
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('rule-frequency-days')));
    await settle(tester);
    // Mặc định: thứ của ngày tới hạn kế tiếp (03/12/2026 là thứ Năm).
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('weekday-4')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('weekday-6'))); // + T7
    await tester.pump();
    await tester.tap(find.byKey(const Key('weekday-done')));
    await settle(tester);
    expect(find.text('T5, T7'), findsOneWidget);
    expect(
      find.textContaining('Bắt đầu lại từ lần đến hạn kế tiếp'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    final rule = await tester.runAsync(
      () => db.select(db.recurringRules).getSingle(),
    );
    expect(
      (rule!.frequency, rule.weekdays, rule.startDate, rule.lastGeneratedDate),
      (
        RecurrenceFrequency.weekly,
        weekdayBit(DateTime.thursday) | weekdayBit(DateTime.saturday),
        '2026-12-03',
        '2026-12-02',
      ),
    );
    expect(find.textContaining('T5, T7'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
