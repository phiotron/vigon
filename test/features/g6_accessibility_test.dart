import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/app_info.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/budget_alert/budget_alert_providers.dart';
import 'package:vigon/src/features/budget_alert/budget_alerts.dart';
import 'package:vigon/src/features/lock/biometric.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';
import 'package:vigon/src/ui/settings_rows.dart';
import 'package:vigon/src/providers.dart';

import '../fake_biometric.dart';
import '../helpers.dart';

/// Các màn chính cần đạt accessibility (AC-37 tới AC-40).
const _routes = [
  '/',
  '/entry/new',
  '/entry/new?type=income',
  '/entries',
  '/settings',
  '/categories',
  '/accounts',
  '/transfer',
  '/recurring',
  // 2.0 (AC-126): hộp thư email (màn giải thích) và thêm hộp thư.
  '/email-import',
  '/email-import/add',
  // 2.0 (AC-126): Tiết kiệm, Khoản nợ, Hàng đợi, Gợi ý đã nhớ.
  '/savings',
  '/debts',
  '/import-queue',
  '/import-queue/suggestions',
  // 2.0 (AC-126): Tổng quan, Thống kê, Lịch (F-35, F-36, F-38).
  '/overview',
  '/stats',
  '/calendar',
];

Future<AppDatabase> _seed(
  WidgetTester tester, {
  required ThemeMode theme,
}) async {
  final db = memoryDatabase();
  await tester.runAsync(() async {
    await AccountRepository(db).add(name: 'Thẻ', initialBalance: 500000);
    await SettingsRepository(db).setThemeMode(theme);
    await SettingsRepository(db).setBudget(1000000);
  });
  return db;
}

Future<List<String>> _audit(
  WidgetTester tester,
  String where, {
  bool labels = true,
}) async {
  final problems = <String>[];
  for (final (name, guideline) in [
    ('vùng chạm', androidTapTargetGuideline),
    if (labels) ('nhãn', labeledTapTargetGuideline),
    ('tương phản', textContrastGuideline),
  ]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) problems.add('$where · $name: ${result.reason}');
  }
  return problems;
}

void main() {
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('các màn chính đạt accessibility · ${theme.name} · '
          'cỡ chữ ${(scale * 100).round()}%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final db = await _seed(tester, theme: theme);
        await pumpApp(tester, db: db);
        await insertEntry(
          tester,
          db,
          type: EntryType.expense,
          amount: 155000,
          categoryId: 1,
          note: 'phở',
        );
        await insertEntry(
          tester,
          db,
          type: EntryType.income,
          amount: 9000000,
          categoryId: 12,
        );
        final problems = <String>[];
        // Gom lỗi vẽ (tràn chữ, ListTile hết chỗ) của từng màn thay vì dừng ở lỗi đầu.
        final drawErrors = <String>{};
        final previous = FlutterError.onError;
        FlutterError.onError = (d) => drawErrors.add(
          '${d.exceptionAsString().split('\n').first} '
          '@ ${d.informationCollector?.call().map((e) => e.toString()).firstWhere((s) => s.contains('file:///'), orElse: () => '').split('file:///').last ?? ''}',
        );
        try {
          for (final route in _routes) {
            try {
              final context = tester.element(find.byType(Scaffold).first);
              GoRouter.of(context).go(route);
              await settle(tester);
              problems.addAll(await _audit(tester, route));
            } catch (e) {
              problems.add('$route · ngoại lệ: ${'$e'.split('\n').first}');
            }
            for (final e in drawErrors) {
              problems.add('$route · lỗi vẽ: $e');
            }
            drawErrors.clear();
          }
        } finally {
          FlutterError.onError = previous;
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
        handle.dispose();
        await disposeApp(tester, db);
      });
    }
  }

  testWidgets('màn khóa đạt accessibility ở cỡ chữ 200% (AC-37 tới AC-40)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final handle = tester.ensureSemantics();
    final secrets = MemorySecretStore();
    await PinService(secrets).setPin('2580');
    final db = await pumpApp(tester, secrets: secrets);
    expect(find.text('Nhập mã PIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final problems = await _audit(tester, 'màn khóa');
    expect(problems, isEmpty, reason: problems.join('\n'));
    handle.dispose();
    await disposeApp(tester, db);
  });

  // F-37 / F-41: trạng thái "Sắp vượt" (màu cảnh báo), hàng sinh trắc ở Cài
  // đặt, nút sinh trắc ở màn khoá, hộp giải thích Thông báo ngân sách.
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Sắp vượt, sinh trắc, Thông báo ngân sách đạt accessibility '
          '· ${theme.name} · cỡ chữ ${(scale * 100).round()}%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final db = await _seed(tester, theme: theme);
        await tester.runAsync(
          () => (db.update(db.categories)..where((c) => c.id.equals(1))).write(
            const CategoriesCompanion(budget: Value(1000000)),
          ),
        );
        final secrets = MemorySecretStore();
        final pin = PinService(secrets);
        await pin.setPin('2580');
        await BiometricSettings(secrets, pin).setEnabled(true);
        final biometric = FakeBiometricAuth(result: false);
        await pumpApp(
          tester,
          db: db,
          secrets: secrets,
          overrides: [
            biometricAuthProvider.overrideWithValue(biometric),
            reminderSchedulerProvider.overrideWithValue(_NoopScheduler()),
            budgetNotifierProvider.overrideWithValue(_NoopBudgetNotifier()),
          ],
        );
        final problems = <String>[];
        // Màn khoá: sinh trắc bị huỷ, còn PIN + nút thử lại.
        expect(find.text('Mở bằng sinh trắc học'), findsOneWidget);
        problems.addAll(await _audit(tester, 'màn khoá + sinh trắc'));
        for (final d in '2580'.split('')) {
          await tester.tap(find.text(d));
          await tester.pump();
        }
        await settle(tester);
        await insertEntry(
          tester,
          db,
          type: EntryType.expense,
          amount: 900000,
          categoryId: 1,
        );
        expect(find.textContaining('Đã dùng 90%'), findsWidgets);
        problems.addAll(await _audit(tester, '/ Sắp vượt'));
        final context = tester.element(find.byType(Scaffold).first);
        GoRouter.of(context).go('/entries');
        await settle(tester);
        expect(find.textContaining('Đã dùng 90%'), findsWidgets);
        problems.addAll(await _audit(tester, '/entries Sắp vượt'));
        GoRouter.of(context).go('/settings');
        await settle(tester);
        for (final row in [
          'Thông báo ngân sách',
          'Tháng bắt đầu từ ngày',
          'Mở khoá bằng vân tay',
        ]) {
          await tester.scrollUntilVisible(
            find.text(row),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await settle(tester);
          problems.addAll(await _audit(tester, '/settings · $row'));
          final node = tester.getSemantics(find.text(row));
          final data = node.getSemanticsData();
          if (!data.label.contains(row) ||
              !data.hasAction(SemanticsAction.tap)) {
            problems.add('/settings · $row: thiếu nhãn hoặc không chạm được');
          }
        }
        await tester.scrollUntilVisible(
          find.text('Thông báo ngân sách'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.widgetWithText(SettingsSwitchRow, 'Thông báo ngân sách'),
        );
        await settle(tester);
        await tester.tap(find.text('Thông báo ngân sách'));
        await settle(tester);
        expect(find.text('Bật thông báo ngân sách?'), findsOneWidget);
        problems.addAll(await _audit(tester, 'hộp Bật thông báo ngân sách'));
        expect(tester.takeException(), isNull);
        expect(problems, isEmpty, reason: problems.join('\n'));
        handle.dispose();
        await disposeApp(tester, db);
      });
    }
  }

  testWidgets('nhóm Giới thiệu trong Cài đặt có phiên bản, chính sách, điều '
      'khoản, giấy phép, góp ý, báo lỗi (AC-41)', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    final versionRow = find.text('Phiên bản');
    await tester.dragUntilVisible(
      versionRow,
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(versionRow);
    await settle(tester);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Gửi góp ý'), findsOneWidget);
    expect(find.text('Báo lỗi bảo mật'), findsOneWidget);
    expect(find.text('Email liên hệ: ${AppInfo.contactEmail}'), findsOneWidget);
    expect(
      find.text(
        'Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Giấy phép mã nguồn mở'));
    await settle(tester);
    expect(find.byType(LicensePage), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('icon danh mục quanh biểu đồ bấm được bằng TalkBack (AC-39)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await pumpApp(tester);
    final label = RegExp('^Thêm khoản chi: Ăn uống');
    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(isButton: true, hasTapAction: true),
    );
    tester.semantics.tap(find.semantics.byLabel(label));
    await settle(tester);
    expect(find.text('Khoản chi mới'), findsOneWidget);
    handle.dispose();
    await disposeApp(tester, db);
  });

  testWidgets('đổi ngày đầu tuần khi đang xem Tuần thì vẫn ở kỳ Tuần (AC-12)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(periodProvider.notifier).selectType(PeriodType.week);
    await settle(tester);
    expect(container.read(periodProvider).type, PeriodType.week);
    expect(container.read(periodProvider).start.weekday, DateTime.monday);
    await tester.runAsync(
      () => SettingsRepository(db).setWeekStart(DateTime.sunday),
    );
    await settle(tester);
    final after = container.read(periodProvider);
    expect(after.type, PeriodType.week);
    expect(after.start.weekday, DateTime.sunday);
    await disposeApp(tester, db);
  });

  // 2.0 (AC-126): bảng Lọc (F-39) và bảng "Xuất khoảng nào" (F-40).
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('bảng Lọc và bảng Xuất đạt accessibility · ${theme.name} · '
          'cỡ chữ ${(scale * 100).round()}%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final db = await _seed(tester, theme: theme);
        await pumpApp(tester, db: db);
        final problems = <String>[];
        Future<void> openAndAudit(
          String route,
          String tap,
          String where,
        ) async {
          final context = tester.element(find.byType(Scaffold).first);
          GoRouter.of(context).go(route);
          await settle(tester);
          final target = find.byTooltip(tap).evaluate().isNotEmpty
              ? find.byTooltip(tap)
              : find.text(tap);
          if (target.evaluate().isEmpty) {
            await tester.dragUntilVisible(
              target,
              find.byType(ListView).first,
              const Offset(0, -300),
            );
          }
          await tester.ensureVisible(target);
          await settle(tester);
          await tester.tap(target);
          await settle(tester);
          problems.addAll(await _audit(tester, where));
          expect(tester.takeException(), isNull, reason: where);
          await tester.tapAt(const Offset(10, 10));
          await settle(tester);
        }

        await openAndAudit('/entries', 'Lọc', 'bảng Lọc');
        await openAndAudit('/settings', 'Xuất PDF', 'bảng Xuất');
        expect(problems, isEmpty, reason: problems.join('\n'));
        handle.dispose();
        await disposeApp(tester, db);
      });
    }
  }
  _ledgerA11yTests();
}

class _NoopScheduler implements ReminderScheduler {
  @override
  Future<void> initialize(void Function(String? payload) onTap) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async => true;

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

class _NoopBudgetNotifier implements BudgetNotifier {
  @override
  Future<void> show(BudgetAlert alert, BudgetAlertContent content) async {}
}

/// Nhóm kiểm trợ năng của đợt 5 (D-046..D-049), tách hàm cho gọn.
void _ledgerA11yTests() {
  // D-046..D-049: các màn/hộp mới của đợt 5 (nợ qua tài khoản có lãi, Bù
  // tiền, thanh bỏ qua định kỳ, hộp nâng cấp, công tắc cho phép âm).
  for (final scale in [1.0, 2.0]) {
    testWidgets('hộp/màn mới của đợt 5 đạt accessibility · cỡ chữ '
        '${(scale * 100).round()}%', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final handle = tester.ensureSemantics();
      final db = await pumpApp(tester, allowNegative: false);
      final problems = <String>[];
      // Đóng bảng/hộp trên cùng.
      void closeTop() =>
          Navigator.of(tester.element(find.byType(BottomSheet).last)).pop();

      Future<void> check(String where) async {
        await settle(tester);
        problems.addAll(await _audit(tester, where));
        expect(tester.takeException(), isNull, reason: where);
      }

      // Khoản nợ có lãi + một khoản Debt movement.
      await tester.runAsync(() async {
        final debt = await db
            .into(db.debts)
            .insert(
              DebtsCompanion.insert(
                person: 'An',
                direction: DebtDirection.lent,
                amount: 5000000,
                date: '2026-11-01',
                currency: const Value('VND'),
                originalAmount: const Value(5000000),
                accountId: const Value(1),
                interestRate: const Value(1200),
                interestPeriod: const Value(InterestPeriod.year),
              ),
            );
        await db
            .into(db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.debt,
                amount: 5000000,
                accountId: 1,
                date: '2026-11-01',
                currency: const Value('VND'),
                originalAmount: const Value(5000000),
                debtKind: const Value(DebtMovementKind.lend),
                debtId: Value(debt),
              ),
            );
      });
      await settle(tester);
      await goTo(tester, '/entries');
      await check('Các khoản · Debt movement');
      await goTo(tester, '/debts');
      await tester.tap(find.text('Thêm khoản nợ'));
      await check('Thêm khoản nợ');
      closeTop();
      await settle(tester);
      await tester.tap(find.text('An'));
      await check('Chi tiết khoản nợ có lãi');
      await tester.ensureVisible(find.byKey(const Key('debt-change-rate')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('debt-change-rate')));
      await check('Đổi lãi suất');
      await tester.tap(find.text('Hủy'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Thêm lần trả'));
      await check('Lần trả có lãi');
      expect(problems, isEmpty, reason: problems.join('\n'));
      handle.dispose();
      await disposeApp(tester, db);
    });
  }
}
