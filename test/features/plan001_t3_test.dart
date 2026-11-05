import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/home/range_calendar.dart';
import 'package:vigon/src/providers.dart';
import 'package:vigon/src/ui/choice_sheet.dart';

import '../helpers.dart';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

/// Mở bảng Xem theo rồi chọn "Khoảng tùy chọn" để hiện lịch (2.4 → 2.5).
Future<void> _openCalendar(WidgetTester tester) async {
  await tester.tap(find.text('Tháng 11 năm 2026').first);
  await settle(tester);
  await tester.tap(find.text('Khoảng tùy chọn'));
  await settle(tester);
  expect(find.byType(RangeCalendarSheet), findsOneWidget);
}

Future<void> _tapDay(WidgetTester tester, String day) async {
  await tester.tap(
    find.descendant(
      of: find.byType(RangeCalendarSheet),
      matching: find.text(day),
    ),
  );
  await tester.pump();
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(TextButton, d));
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  group('lịch Khoảng tùy chọn (2.5)', () {
    testWidgets('chọn 5 rồi 9 thì kỳ là 5–9 thg 11', (tester) async {
      final db = await pumpApp(tester);
      await _openCalendar(tester);
      await _tapDay(tester, '5');
      // Mới có ngày đầu: dòng khoảng nhắc chọn ngày cuối.
      expect(find.text('Chọn ngày đầu rồi ngày cuối'), findsOneWidget);
      await _tapDay(tester, '9');
      expect(findPlainText('5 thg 11 – 9 thg 11, 2026'), findsOneWidget);
      await tester.tap(find.text('Áp dụng'));
      await settle(tester);
      final period = _container(tester).read(periodProvider);
      expect(
        period,
        Period.custom(DateTime(2026, 11, 5), DateTime(2026, 11, 9)),
      );
      expect(findPlainText('5 thg 11 – 9 thg 11, 2026'), findsNWidgets(2));
      await disposeApp(tester, db);
    });

    testWidgets('chọn ngược 9 rồi 5 thì tự đổi chỗ', (tester) async {
      final db = await pumpApp(tester);
      await _openCalendar(tester);
      await _tapDay(tester, '9');
      await _tapDay(tester, '5');
      await tester.tap(find.text('Áp dụng'));
      await settle(tester);
      final period = _container(tester).read(periodProvider);
      expect(period.type, PeriodType.custom);
      expect(
        (period.start, period.end),
        (DateTime(2026, 11, 5), DateTime(2026, 11, 9)),
      );
      await disposeApp(tester, db);
    });

    testWidgets('Hủy thì giữ kỳ cũ', (tester) async {
      final db = await pumpApp(tester);
      final before = _container(tester).read(periodProvider);
      await _openCalendar(tester);
      await _tapDay(tester, '5');
      await _tapDay(tester, '9');
      await tester.tap(find.text('Hủy'));
      await settle(tester);
      expect(find.byType(RangeCalendarSheet), findsNothing);
      expect(_container(tester).read(periodProvider), before);
      // Đầu kỳ + dòng tên kỳ dưới "Số dư" (v2).
      expect(find.text('Tháng 11 năm 2026'), findsNWidgets(2));
      await disposeApp(tester, db);
    });

    testWidgets('ô ngày đọc ngày đầy đủ và trạng thái chọn; đổi tháng', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = await pumpApp(tester);
      await _openCalendar(tester);
      await _tapDay(tester, '5');
      final label = DateFormat.yMMMMEEEEd('vi').format(DateTime(2026, 11, 5));
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(
          label: label,
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      await tester.tap(find.byTooltip('Tháng sau'));
      await tester.pump();
      expect(find.text('Tháng 12 năm 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.tap(find.byTooltip('Tháng trước'));
      await tester.pump();
      expect(find.text('Tháng 10 năm 2026'), findsOneWidget);
      handle.dispose();
      await disposeApp(tester, db);
    });

    testWidgets('hàng thứ bắt đầu theo ngày đầu tuần trong cài đặt', (
      tester,
    ) async {
      final db = memoryDatabase();
      await tester.runAsync(
        () => SettingsRepository(db).setWeekStart(DateTime.sunday),
      );
      await pumpApp(tester, db: db);
      await _openCalendar(tester);
      final sheet = find.byType(RangeCalendarSheet);
      final cn = tester.getTopLeft(
        find.descendant(of: sheet, matching: find.text('CN')),
      );
      final t2 = tester.getTopLeft(
        find.descendant(of: sheet, matching: find.text('T2')),
      );
      expect(cn.dx, lessThan(t2.dx));
      await disposeApp(tester, db);
    });
  });

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('lịch và bảng Xem theo ở cỡ chữ 200% không tràn, đủ nhãn '
        'và tương phản · ${theme.name}', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final handle = tester.ensureSemantics();
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setThemeMode(theme));
      await pumpApp(tester, db: db);
      await tester.tap(find.text('Tháng 11 năm 2026').first);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Khoảng tùy chọn'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
      await disposeApp(tester, db);
    });
  }

  testWidgets('kỳ "Tất cả" không có nút kỳ trước/sau', (tester) async {
    final db = await pumpApp(tester);
    expect(find.byTooltip('Kỳ trước'), findsOneWidget);
    expect(find.byTooltip('Kỳ sau'), findsOneWidget);
    await tester.tap(find.text('Tháng 11 năm 2026').first);
    await settle(tester);
    await tester.tap(find.text('Tất cả'));
    await settle(tester);
    expect(_container(tester).read(periodProvider).type, PeriodType.all);
    expect(find.byTooltip('Kỳ trước'), findsNothing);
    expect(find.byTooltip('Kỳ sau'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('menu lọc tài khoản đánh dấu dòng đang chọn (2.6)', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 0),
    );
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Tài khoản'));
    await settle(tester);
    final all = find.ancestor(
      of: find.text('Tất cả tài khoản'),
      matching: find.byType(PopupMenuItem<int>),
    );
    expect(
      find.descendant(of: all, matching: find.byIcon(Symbols.check_rounded)),
      findsOneWidget,
    );
    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);
    expect(tester.getSize(all).height, greaterThanOrEqualTo(48));
    await disposeApp(tester, db);
  });

  testWidgets('bảng Xem theo đánh dấu dòng đang chọn (2.4)', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Tháng 11 năm 2026').first);
    await settle(tester);
    expect(find.text('Xem theo'), findsOneWidget);
    final rows = tester.widgetList<ChoiceRow>(find.byType(ChoiceRow)).toList();
    expect(rows.map((r) => r.label), [
      'Ngày',
      'Tuần',
      'Tháng',
      'Năm',
      'Tất cả',
      'Khoảng tùy chọn',
    ]);
    expect(rows.where((r) => r.selected).map((r) => r.label), ['Tháng']);
    expect(
      rows.every((r) => r.icon != null),
      isTrue,
      reason: 'mỗi dòng có icon đầu',
    );
    await disposeApp(tester, db);
  });

  group('màn khóa (S01)', () {
    testWidgets('sai mã hiện "Sai mã PIN" và rung nhẹ', (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.text('Sai mã PIN'), findsNothing);
      await _enterPin(tester, '1111');
      expect(find.text('Sai mã PIN'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await disposeApp(tester, db);
    });

    testWidgets('Quên mã mở hộp thoại có nút "Xóa toàn bộ dữ liệu"; Hủy về '
        'màn khóa', (tester) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      await tester.tap(find.text('Quên mã'));
      await settle(tester);
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(TextButton, 'Xóa toàn bộ dữ liệu'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('không lấy lại được mã PIN'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('bàn phím PIN dồn xuống đáy, "Quên mã" ở dưới cùng', (
      tester,
    ) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      final height =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final zero = tester.getBottomLeft(find.widgetWithText(TextButton, '0'));
      final forgot = tester.getBottomLeft(find.text('Quên mã'));
      final title = tester.getTopLeft(find.text('Nhập mã PIN'));
      expect(forgot.dy, greaterThan(zero.dy));
      // Phím ở nửa dưới màn hình, tiêu đề ở nửa trên.
      expect(zero.dy, greaterThan(height / 2));
      expect(title.dy, lessThan(height / 3));
      await disposeApp(tester, db);
    });
  });

  group('ghi khoản (S04, S05, S07)', () {
    testWidgets('bảng Chọn danh mục lưới 4 cột; Lặp lại là bảng chọn', (
      tester,
    ) async {
      final db = await pumpApp(tester);
      await tester.tap(find.byTooltip('Thêm khoản chi'));
      await settle(tester);
      expect(find.text('0/200'), findsOneWidget);
      for (final k in ['5', '0', '0', '0']) {
        await tester.tap(find.widgetWithText(TextButton, k));
        await tester.pump();
      }
      await tester.tap(find.text('Không lặp'));
      await settle(tester);
      expect(find.text('Lặp lại'), findsOneWidget);
      final rows = tester.widgetList<ChoiceRow>(find.byType(ChoiceRow));
      expect(rows.where((r) => r.selected).map((r) => r.label), ['Không lặp']);
      await tester.tap(find.text('Hằng tháng'));
      await settle(tester);
      expect(find.text('Hằng tháng'), findsOneWidget);
      // Chưa chọn danh mục: nút lớn mở lưới danh mục.
      await tester.tap(find.text('Chọn danh mục'));
      await settle(tester);
      expect(find.text('Chọn danh mục'), findsWidgets);
      final food = tester.getTopLeft(find.text('Ăn uống'));
      final transport = tester.getTopLeft(find.text('Đi lại'));
      final home = tester.getTopLeft(find.text('Nhà cửa'));
      final bills = tester.getTopLeft(find.text('Hóa đơn'));
      final shopping = tester.getTopLeft(find.text('Mua sắm'));
      // Bốn ô đầu cùng một hàng, ô thứ năm sang hàng mới.
      expect({food.dy, transport.dy, home.dy, bills.dy}.length, 1);
      expect(shopping.dy, greaterThan(food.dy));
      expect(
        tester.getCenter(find.text('Mua sắm')).dx,
        closeTo(tester.getCenter(find.text('Ăn uống')).dx, 0.5),
      );
      await tester.tap(find.text('Đi lại'));
      await settle(tester);
      // AC-02 (tối đa 3 lần chạm) thắng ghi chú bản vẽ 3.3 "chưa lưu": chạm
      // danh mục từ nút "Chọn danh mục" là lưu luôn.
      final saved = await tester.runAsync(() => db.select(db.entries).get());
      expect(saved!.single.categoryId, 2);
      await disposeApp(tester, db);
    });

    testWidgets('màn sửa có tiêu đề "Sửa khoản" và nút xóa', (tester) async {
      final db = await pumpApp(tester);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 155000,
        categoryId: 1,
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/entry/1');
      await settle(tester);
      expect(find.text('Sửa khoản'), findsOneWidget);
      expect(find.byTooltip('Xóa'), findsOneWidget);
      // Sửa khoản không có chip chọn lặp lại.
      expect(find.text('Không lặp'), findsNothing);
      await disposeApp(tester, db);
    });
  });
}
