import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/budget_alert/budget_alert_providers.dart';
import 'package:vigon/src/features/budget_alert/budget_alert_settings.dart';
import 'package:vigon/src/features/budget_alert/budget_alerts.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';
import 'package:vigon/src/features/settings/settings_screen.dart';

import '../helpers.dart';

class _FakeScheduler implements ReminderScheduler {
  bool permission = true;
  int permissionRequests = 0;
  void Function(String?)? onTap;

  @override
  Future<void> initialize(void Function(String? payload) onTap) async =>
      this.onTap = onTap;

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> openSystemSettings() async {}
}

class _FakeNotifier implements BudgetNotifier {
  final shown = <(BudgetAlert, BudgetAlertContent)>[];

  @override
  Future<void> show(BudgetAlert alert, BudgetAlertContent content) async =>
      shown.add((alert, content));
}

/// Hạn mức tháng 5.000.000 ₫ (ví dụ AC-111).
Future<AppDatabase> _withBudget(WidgetTester tester, {int? category}) async {
  final db = memoryDatabase();
  await tester.runAsync(() async {
    await SettingsRepository(db).setBudget(5000000);
    if (category != null) {
      await (db.update(db.categories)..where((c) => c.id.equals(category)))
          .write(const CategoriesCompanion(budget: Value(5000000)));
    }
  });
  return db;
}

Finder _budgetBar(String text) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.label != null &&
      plain(w.properties.label!) == text,
);

void main() {
  testWidgets('ví dụ AC-111 ở thanh ngân sách màn chính: 3.999.999 bình '
      'thường, 4.000.000 và 5.000.000 Sắp vượt, 5.000.001 Vượt 1', (
    tester,
  ) async {
    final db = await _withBudget(tester);
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 3999999,
      categoryId: 1,
    );
    expect(
      _budgetBar('Ngân sách tháng: Đã chi 3.999.999 ₫ / 5.000.000 ₫'),
      findsOneWidget,
    );
    expect(find.byIcon(Symbols.error_rounded), findsNothing);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1,
      categoryId: 1,
    );
    expect(
      _budgetBar(
        'Ngân sách tháng: Đã dùng 80% · Đã chi 4.000.000 ₫ / 5.000.000 ₫',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1000000,
      categoryId: 1,
    );
    expect(
      _budgetBar(
        'Ngân sách tháng: Đã dùng 100% · Đã chi 5.000.000 ₫ / 5.000.000 ₫',
      ),
      findsOneWidget,
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1,
      categoryId: 1,
    );
    expect(_budgetBar('Ngân sách tháng: Vượt 1 ₫'), findsOneWidget);
    expect(find.byIcon(Symbols.error_rounded), findsNothing);
    expect(find.byIcon(Symbols.warning_rounded), findsWidgets);
    await disposeApp(tester, db);
  });

  testWidgets('ngưỡng 90%: 4.000.000 lại là bình thường; hạn mức danh mục ở '
      'Các khoản cũng Sắp vượt (AC-111)', (tester) async {
    final db = await _withBudget(tester, category: 1);
    await tester.runAsync(() => BudgetAlertSettings(db).setThreshold(90));
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 4000000,
      categoryId: 1,
    );
    expect(
      _budgetBar('Ngân sách tháng: Đã chi 4.000.000 ₫ / 5.000.000 ₫'),
      findsOneWidget,
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 600000,
      categoryId: 1,
    );
    expect(
      _budgetBar(
        'Ngân sách tháng: Đã dùng 92% · Đã chi 4.600.000 ₫ / 5.000.000 ₫',
      ),
      findsOneWidget,
    );
    await goTo(tester, '/entries');
    expect(
      _budgetBar('Đã dùng 92% · Đã chi 4.600.000 ₫ / 5.000.000 ₫'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt → Kế hoạch: chọn ngưỡng 50–95%; bật Thông báo ngân '
      'sách giải thích rồi mới xin quyền, từ chối thì vẫn tắt (AC-111, '
      'AC-112)', (tester) async {
    final scheduler = _FakeScheduler()..permission = false;
    final db = await pumpApp(
      tester,
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        budgetNotifierProvider.overrideWithValue(_FakeNotifier()),
      ],
    );
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    final threshold = find.text('Ngưỡng "Sắp vượt"');
    await tester.scrollUntilVisible(
      threshold,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
    expect(find.text('80%'), findsOneWidget);
    await tester.tap(threshold);
    await settle(tester);
    for (final p in [50, 55, 60, 65, 70, 75, 85, 90, 95]) {
      expect(find.text('$p%'), findsWidgets, reason: '$p%');
    }
    expect(find.text('45%'), findsNothing);
    await tester.tap(find.text('90%').last);
    await settle(tester);
    expect(await tester.runAsync(BudgetAlertSettings(db).readThreshold), 90);

    final toggle = find.text('Thông báo ngân sách');
    await tester.ensureVisible(toggle);
    await settle(tester);
    await tester.tap(toggle);
    await settle(tester);
    expect(find.text('Bật thông báo ngân sách?'), findsOneWidget);
    expect(
      scheduler.permissionRequests,
      0,
      reason: 'chưa xin trước lời giải thích',
    );
    await tester.tap(find.text('Tiếp tục'));
    await settle(tester);
    expect(scheduler.permissionRequests, 1);
    expect(await tester.runAsync(BudgetAlertSettings(db).readEnabled), false);

    scheduler.permission = true;
    await tester.tap(toggle);
    await settle(tester);
    await tester.tap(find.text('Tiếp tục'));
    await settle(tester);
    expect(await tester.runAsync(BudgetAlertSettings(db).readEnabled), true);
    await disposeApp(tester, db);
  });

  testWidgets('bật thông báo: khoản tháng này qua mốc thì báo một lần, chỉ %; '
      'khoản lùi tháng cũ không báo; chạm mở app (AC-112, AC-113)', (
    tester,
  ) async {
    final scheduler = _FakeScheduler();
    final notifier = _FakeNotifier();
    final db = await _withBudget(tester);
    await tester.runAsync(() => BudgetAlertSettings(db).setEnabled(true));
    await pumpApp(
      tester,
      db: db,
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        budgetNotifierProvider.overrideWithValue(notifier),
      ],
    );
    expect(notifier.shown, isEmpty);
    // Khoản lùi vào tháng 10: không đổi đã chi tháng 11 nên không báo.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 9000000,
      categoryId: 1,
      date: '2026-10-15',
    );
    expect(notifier.shown, isEmpty);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 4000000,
      categoryId: 1,
    );
    expect(notifier.shown, hasLength(1));
    final content = notifier.shown.single.$2;
    expect(content.body, 'Ngân sách tháng 11: đã dùng 80%');
    expect(content.title, 'Ví Gọn');
    expect(content.channelName, 'Cảnh báo ngân sách');
    // Thêm nữa trong cùng mốc: không báo lại.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 100000,
      categoryId: 1,
    );
    expect(notifier.shown, hasLength(1));
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 900000,
      categoryId: 1,
    );
    expect(notifier.shown.map((s) => s.$2.body), [
      'Ngân sách tháng 11: đã dùng 80%',
      'Ngân sách tháng 11: đã dùng 100%',
    ]);
    // Chạm thông báo khi đang ở tab Cài đặt → mở Tổng quan (AC-113; router có
    // `/overview` từ F-35).
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    scheduler.onTap!(budgetAlertPayload);
    await settle(tester);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.byType(SettingsScreen), findsNothing);
    await disposeApp(tester, db);
  });
}
