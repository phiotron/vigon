import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/ui/dialog.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/home/range_calendar.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
}

Future<void> typeAmount(WidgetTester tester, String digits) async {
  for (final k in digits.split('')) {
    await tester.tap(find.widgetWithText(TextButton, k));
    await tester.pump();
  }
}

void main() {
  testWidgets('đặt rồi bỏ ngân sách bằng hộp thoại (AC-26)', (tester) async {
    final db = await pumpApp(tester);
    expect(find.textContaining('Ngân sách tháng'), findsNothing);
    await openSettings(tester);
    await tester.tap(find.text('Ngân sách tháng'));
    await settle(tester);
    // Số tiền 0 bị từ chối.
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1000000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    await tester.tap(find.byTooltip('Quay lại'));
    await settle(tester);
    expect(
      findPlainText('Ngân sách tháng: Đã chi 0 ₫ / 1.000.000 ₫'),
      findsOneWidget,
    );
    // Chạm thanh ngân sách mở lại hộp thoại; "Bỏ ngân sách" xóa thanh.
    await tester.tap(find.textContaining('Ngân sách tháng'));
    await settle(tester);
    await tester.tap(find.text('Bỏ ngân sách'));
    await settle(tester);
    expect(find.textContaining('Ngân sách tháng'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('lọc theo tài khoản ở màn chính (AC-20)', (tester) async {
    final db = memoryDatabase();
    final card = await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 0),
    );
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 100000,
      categoryId: 1,
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 30000,
      categoryId: 1,
      accountId: card!,
    );
    expect(
      findSemanticsLabel('Số dư: -130.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Tài khoản'));
    await settle(tester);
    await tester.tap(find.text('Thẻ').last);
    await settle(tester);
    expect(
      findSemanticsLabel('Số dư: -30.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    // Nút lọc đọc tên tài khoản đang lọc.
    await tester.tap(find.byTooltip('Tài khoản: Thẻ'));
    await settle(tester);
    await tester.tap(find.text('Tất cả tài khoản'));
    await settle(tester);
    expect(
      findSemanticsLabel('Số dư: -130.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('đổi tên, màu, icon danh mục có sẵn (AC-16)', (tester) async {
    final db = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Danh mục'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Ăn ngoài');
    await tester.tap(find.byKey(const ValueKey('icon-local_cafe')));
    await tester.tap(find.bySemanticsLabel('Màu 3'));
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final c = await tester.runAsync(
      () =>
          (db.select(db.categories)..where((c) => c.id.equals(1))).getSingle(),
    );
    expect((c!.name, c.icon, c.color), ('Ăn ngoài', 'local_cafe', 0xFF6A1B9A));
    expect(find.text('Ăn ngoài'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('xóa danh mục chuyển khoản sang danh mục khác (AC-17)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 40000,
      categoryId: 1,
    );
    await openSettings(tester);
    await tester.tap(find.text('Danh mục'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    await tester.tap(find.text('Xóa danh mục'));
    await settle(tester);
    expect(find.text('1 khoản sẽ được chuyển sang:'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(VgDialog), matching: find.text('Đi lại')),
    );
    await settle(tester);
    final cats = await tester.runAsync(() => db.select(db.categories).get());
    expect(cats!.any((c) => c.id == 1), isFalse);
    final entry = await tester.runAsync(
      () => db.select(db.entries).getSingle(),
    );
    expect(entry!.categoryId, 2);
    await disposeApp(tester, db);
  });

  testWidgets('ghi chú tối đa 200 ký tự; chọn tài khoản và ngày (AC-04)', (
    tester,
  ) async {
    final db = memoryDatabase();
    final card = await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 0),
    );
    await pumpApp(tester, db: db);
    await tester.tap(find.byTooltip('Ăn uống'));
    await settle(tester);
    await typeAmount(tester, '5000');
    // Ghi chú dài 250 ký tự chỉ nhận 200.
    await tester.enterText(find.byType(TextField), 'a' * 250);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text.length,
      200,
    );
    // Chọn tài khoản thứ hai.
    await tester.tap(find.text('Tiền mặt'));
    await settle(tester);
    await tester.tap(find.text('Thẻ').last);
    await settle(tester);
    // Chọn ngày 1 của tháng hiện tại trong hộp chọn ngày.
    await tester.tap(find.text('Hôm nay'));
    await settle(tester);
    await tester.tap(find.text('1').last);
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final e = await tester.runAsync(() => db.select(db.entries).getSingle());
    expect(e!.accountId, card);
    expect(e.date, '2026-11-01');
    expect(e.note!.length, 200);
    await disposeApp(tester, db);
  });

  testWidgets('chọn kỳ Tuần và Năm từ bảng chọn kỳ (AC-10)', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Tháng 11 năm 2026'), findsNWidgets(2));
    await tester.tap(find.text('Tháng 11 năm 2026').first);
    await settle(tester);
    await tester.tap(find.text('Tuần'));
    await settle(tester);
    // 3/11/2026 là Thứ Ba; tuần bắt đầu Thứ Hai 2/11.
    expect(find.textContaining('2 thg 11'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Kỳ sau'));
    await settle(tester);
    expect(find.textContaining('9 thg 11'), findsNWidgets(2));
    await tester.tap(find.textContaining('9 thg 11').first);
    await settle(tester);
    await tester.tap(find.text('Năm'));
    await settle(tester);
    expect(find.text('2026'), findsNWidgets(2));
    await disposeApp(tester, db);
  });

  testWidgets(
    'app sống qua tháng mới: thanh theo tháng đang xem, số cho widget sang '
    'tháng mới (D-028)',
    (tester) async {
      var now = DateTime(2026, 11, 30, 23, 0);
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setBudget(1000000));
      await pumpApp(tester, db: db, clock: () => now);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 250000,
        categoryId: 1,
        date: '2026-11-30',
      );
      expect(
        findPlainText('Ngân sách tháng: Đã chi 250.000 ₫ / 1.000.000 ₫'),
        findsOneWidget,
      );
      // Qua nửa đêm sang 1/12 rồi app quay lại từ nền.
      now = DateTime(2026, 12, 1, 0, 5);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      final widgetSpent = container.listen(budgetSpentProvider, (_, _) {});
      container.read(todayProvider.notifier).refresh();
      await settle(tester);
      // Kỳ đang xem vẫn là Tháng 11 (không tự nhảy) nên thanh vẫn số tháng 11.
      expect(find.text('Tháng 11 năm 2026'), findsWidgets);
      expect(
        findPlainText('Ngân sách tháng: Đã chi 250.000 ₫ / 1.000.000 ₫'),
        findsOneWidget,
      );
      // Số đẩy ra widget màn hình chờ thì đã sang tháng 12.
      expect(widgetSpent.read().value, 0);
      widgetSpent.close();
      // Sang Tháng 12 trên màn chính: thanh tính tháng 12.
      await tester.tap(find.byTooltip('Kỳ sau'));
      await settle(tester);
      expect(
        findPlainText('Ngân sách tháng: Đã chi 0 ₫ / 1.000.000 ₫'),
        findsOneWidget,
      );
      await disposeApp(tester, db);
    },
  );

  testWidgets('chọn Khoảng tùy chọn bằng lịch trong bảng kéo (AC-10)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Tháng 11 năm 2026').first);
    await settle(tester);
    await tester.tap(find.text('Khoảng tùy chọn'));
    await settle(tester);
    // Lịch riêng của app (2.5): chạm ngày đầu rồi ngày cuối, bấm Áp dụng.
    final calendar = find.byType(RangeCalendarSheet);
    await tester.tap(find.descendant(of: calendar, matching: find.text('5')));
    await tester.pump();
    await tester.tap(find.descendant(of: calendar, matching: find.text('9')));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);
    expect(find.textContaining('5 thg 11'), findsNWidgets(2));
    expect(find.textContaining('9 thg 11'), findsNWidgets(2));
    // Kỳ sau dịch cả khoảng đi đúng số ngày (5 ngày).
    await tester.tap(find.byTooltip('Kỳ sau'));
    await settle(tester);
    expect(find.textContaining('10 thg 11'), findsNWidgets(2));
    expect(find.textContaining('14 thg 11'), findsNWidgets(2));
    await disposeApp(tester, db);
  });
}
