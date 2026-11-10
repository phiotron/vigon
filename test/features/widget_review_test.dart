import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/widget/widget_sync.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';
import 'f26_widget_test.dart' show FakeBridge;

/// Lỗi rà soát widget F-26: số của kỳ cũ, widget bị cắt, kỳ sai lúc khởi động.
void main() {
  Future<void> addExpense(
    WidgetTester tester,
    AppDatabase db,
    int amount,
    String date,
  ) => insertEntry(
    tester,
    db,
    type: EntryType.expense,
    amount: amount,
    categoryId: 1,
    date: date,
  ).then((_) {});

  group('lỗi 1: số kỳ cũ không được hiện như của kỳ này', () {
    testWidgets('dòng số tiền đi kèm hạn dùng = 0 giờ ngày đầu kỳ sau', (
      tester,
    ) async {
      final bridge = FakeBridge();
      final db = memoryDatabase();
      await pumpApp(
        tester,
        db: db,
        overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
      );
      await addExpense(tester, db, 150000, '2026-11-03');
      final repo = SettingsRepository(db);
      await tester.runAsync(() => repo.setWidgetShowAmounts(true));
      await settle(tester);
      expect(bridge.last, 'show:Tháng này đã chi 150.000 ₫');
      expect(bridge.validUntils.last, DateTime(2026, 12));

      // Tháng bắt đầu ngày 15: hôm nay 3/11 thuộc kỳ 15/10 - 14/11.
      await tester.runAsync(() => repo.setMonthStartDay(15));
      await settle(tester);
      expect(bridge.last, startsWith('show:Tháng này đã chi'));
      expect(bridge.validUntils.last, DateTime(2026, 11, 15));
      await disposeApp(tester, db);
    });

    testWidgets('dòng "Đã khóa bằng PIN" không có hạn (không chứa số)', (
      tester,
    ) async {
      final bridge = FakeBridge();
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = memoryDatabase();
      await tester.runAsync(
        () => SettingsRepository(db).setWidgetShowAmounts(true),
      );
      await pumpApp(
        tester,
        db: db,
        secrets: secrets,
        overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
      );
      expect(bridge.last, 'show:Đã khóa bằng PIN');
      expect(bridge.validUntils.every((v) => v == null), isTrue);
      await disposeApp(tester, db);
    });

    test(
      'phía Android: xóa số quá hạn, hiện "Mở app để cập nhật", không quyền',
      () {
        final kt = File(
          'android/app/src/main/kotlin/com/phiotron/vigon/WidgetProvider.kt',
        ).readAsStringSync();
        expect(kt, contains('KEY_VALID_UNTIL'));
        expect(kt, contains('System.currentTimeMillis() >= validUntil'));
        expect(kt, contains('.remove(KEY_LINE)'));
        expect(kt, contains('R.string.widget_stale'));
        expect(kt, contains('alarms.set(AlarmManager.RTC'));
        // Không báo thức chính xác, không thêm quyền.
        expect(kt, isNot(contains('setExact')));
        expect(kt, isNot(contains('setAlarmClock')));
        expect(kt, isNot(contains('SCHEDULE_EXACT_ALARM')));
        final manifest = File('android/app/src/main/AndroidManifest.xml')
            .readAsStringSync();
        expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
        expect(manifest, isNot(contains('USE_EXACT_ALARM')));
        for (final dir in ['values', 'values-vi']) {
          final xml = File('android/app/src/main/res/$dir/widget_strings.xml')
              .readAsStringSync();
          expect(xml, contains('name="widget_stale"'), reason: dir);
        }
        expect(
          File('android/app/src/main/res/values/widget_strings.xml')
              .readAsStringSync(),
          contains('>Open the app to update<'),
        );
        expect(
          File('android/app/src/main/res/xml/vigon_widget_info.xml')
              .readAsStringSync(),
          contains('android:updatePeriodMillis="1800000"'),
        );
      },
    );
  });

  test('lỗi 2: widget đủ cao cho dòng trạng thái + nút 48dp + đệm', () {
    final info = File('android/app/src/main/res/xml/vigon_widget_info.xml')
        .readAsStringSync();
    double dp(String attr) => double.parse(
      RegExp('android:$attr="([0-9.]+)dp"').firstMatch(info)!.group(1)!,
    );
    // Đệm 8+8, dòng chữ 12sp (~16) + lề 6, nút 48 = 86dp.
    expect(dp('minHeight'), greaterThanOrEqualTo(86));
    expect(dp('minResizeHeight'), greaterThanOrEqualTo(86));
    final layout = File('android/app/src/main/res/layout/vigon_widget.xml')
        .readAsStringSync();
    expect(
      layout,
      contains('android:contentDescription="@string/widget_expense_desc"'),
    );
    expect(
      layout,
      contains('android:contentDescription="@string/widget_income_desc"'),
    );
  });

  testWidgets(
    'lỗi 3: ngân sách chưa biết ngày bắt đầu tháng thì chưa tính số',
    (tester) async {
      final db = memoryDatabase();
      await addExpense(tester, db, 1000, '2026-10-20'); // kỳ 15/10 - 14/11
      await addExpense(tester, db, 200, '2026-11-03');
      await tester.runAsync(() async {
        final settings = SettingsRepository(db);
        await settings.setMonthStartDay(15);
        // Khoản ghi bằng VND; Tiền tệ chính cũng VND (như pumpApp) để tổng
        // không bị quy sang USD (D-042).
        await settings.ensureCurrency(defaultCode: 'VND');
      });
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => testToday),
        ],
      );
      addTearDown(container.dispose);
      final seen = <AsyncValue<int>>[];
      container.listen(
        budgetSpentProvider,
        (_, next) => seen.add(next),
        fireImmediately: true,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      // Chỉ được phát ra số của đúng kỳ (1.200); không từng có số tháng 11 một mình (200).
      final values = seen.where((v) => v.hasValue).map((v) => v.value).toList();
      expect(values, isNotEmpty);
      expect(values, everyElement(1200));
      container.dispose();
      await tester.runAsync(db.close);
    },
  );

  testWidgets('lỗi 3: widget không đẩy số của kỳ sai lúc khởi động', (
    tester,
  ) async {
    final bridge = FakeBridge();
    final db = memoryDatabase();
    await addExpense(tester, db, 1000, '2026-10-20');
    await addExpense(tester, db, 200, '2026-11-03');
    final repo = SettingsRepository(db);
    await tester.runAsync(() async {
      await repo.setMonthStartDay(15);
      await repo.setWidgetShowAmounts(true);
    });
    await pumpApp(
      tester,
      db: db,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    expect(bridge.everShown, isTrue);
    expect(
      // Dòng khóa PIN (lúc đang đọc PIN) không chứa số nên được phép.
      bridge.calls.where((c) => RegExp(r'\d').hasMatch(c)),
      everyElement('show:Tháng này đã chi 1.200 ₫'),
    );
    await disposeApp(tester, db);
  });

  testWidgets('lỗi 4: sang tháng mới khi app chạy thì đẩy lại số tháng mới, '
      'không đẩy số tháng cũ kèm hạn mới', (tester) async {
    final bridge = FakeBridge();
    final db = memoryDatabase();
    var now = DateTime(2026, 11, 30, 23, 59);
    await pumpApp(
      tester,
      db: db,
      clock: () => now,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    await addExpense(tester, db, 150000, '2026-11-30');
    await addExpense(tester, db, 70000, '2026-12-01');
    await tester.runAsync(
      () => SettingsRepository(db).setWidgetShowAmounts(true),
    );
    await settle(tester);
    expect(bridge.last, 'show:Tháng này đã chi 150.000 ₫');
    expect(bridge.validUntils.last, DateTime(2026, 12));

    final before = bridge.calls.length;
    now = DateTime(2026, 12, 1, 0, 1);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(VigonApp)),
    );
    container.read(todayProvider.notifier).refresh();
    await settle(tester);

    expect(bridge.last, 'show:Tháng này đã chi 70.000 ₫');
    expect(bridge.validUntils.last, DateTime(2027));
    final after = bridge.calls.skip(before);
    expect(after, isNotEmpty);
    expect(after.where((c) => c.contains('150.000')), isEmpty);
    await disposeApp(tester, db);
  });
}
