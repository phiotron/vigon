import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/app_info.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/providers.dart';

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

Future<List<String>> _audit(WidgetTester tester, String where) async {
  final problems = <String>[];
  for (final (name, guideline) in [
    ('vùng chạm', androidTapTargetGuideline),
    ('nhãn', labeledTapTargetGuideline),
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
          categoryId: 11,
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
      find.text('Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.'),
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
}
