import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/debts/debts_screen.dart';
import 'package:vigon/src/features/overview/overview_screen.dart';
import 'package:vigon/src/features/stats/stats_screen.dart';

import '../helpers.dart';

/// F-35 Tổng quan, F-36 Thống kê, F-38 Lịch (AC-107..AC-110, AC-114), số theo
/// Tiền tệ chính (D-042). Ngày test: 3/11/2026, tiếng Việt, VND.
/// Vùng cuộn dọc chính của màn [screen].
Finder _scrollableOf(Type screen) => find
    .descendant(
      of: find.byType(screen),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .first;

void main() {
  group('Tổng quan (F-35)', () {
    testWidgets('AC-108: tháng 10 chi 4.000.000, tháng 11 chi 5.000.000 → '
        '"Chi tăng 25% so với tháng 10"', (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setBudget(4500000));
      await pumpApp(tester, db: db);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 1500000,
        categoryId: 1,
        date: '2026-10-05',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 2500000,
        categoryId: 2,
        date: '2026-10-31',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 5000000,
        categoryId: 1,
        date: '2026-11-02',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.income,
        amount: 9000000,
        categoryId: 11,
        date: '2026-11-01',
      );
      await goTo(tester, '/overview');
      // Thu − chi tháng = 9.000.000 − 5.000.000.
      expect(findPlainText('+4.000.000 ₫'), findsOneWidget);
      // Ngân sách còn lại = 4.500.000 − 5.000.000 → "Vượt 500.000 ₫".
      expect(findPlainText('Vượt 500.000 ₫'), findsOneWidget);
      // Tổng số dư = 0 + 9.000.000 − 9.000.000 chi.
      expect(
        findSemanticsLabel(
          'Tổng số dư, 0 ₫, Mọi tài khoản, kể cả tài khoản ẩn. '
          'Không gồm khoản nợ.',
        ),
        findsOneWidget,
      );
      // Biểu đồ cột có bảng thay thế cho trình đọc màn hình.
      expect(find.byType(BarChart), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith(
                'Thu và chi 6 tháng gần nhất. ',
              ) &&
              plain(w.properties.label!)
                  .contains('thu 9.000.000 ₫, chi 5.000.000 ₫'),
        ),
        findsOneWidget,
      );
      // So với tháng trước (cuối màn).
      await tester.scrollUntilVisible(
        find.text('So với tháng trước'),
        200,
        scrollable: _scrollableOf(OverviewScreen),
      );
      expect(findPlainText('Chi tăng 25% so với tháng 10'), findsOneWidget);
      expect(findSemanticsLabel('Chi, tăng 25%'), findsOneWidget);
      expect(
        findSemanticsLabel('Thu, không so được, tháng trước bằng 0'),
        findsOneWidget,
      );
      // "Xem dạng bảng" hiện bảng chữ thật.
      await tester.tap(find.text('Xem dạng bảng'));
      await settle(tester);
      expect(find.byType(BarChart), findsNothing);
      expect(findPlainText('4.000.000 ₫'), findsWidgets);

      // Tháng trước: chi tháng 10, so với tháng 9 = 0 → "—".
      await tester.tap(find.byTooltip('Tháng trước'));
      await settle(tester);
      expect(find.text('—'), findsNWidgets(2));
      await disposeApp(tester, db);
    });

    testWidgets('ô Ngân sách còn lại: Sắp vượt ở ngưỡng 80% (F-37, AC-111)', (
      tester,
    ) async {
      final db = memoryDatabase();
      await tester.runAsync(() => SettingsRepository(db).setBudget(5000000));
      await pumpApp(tester, db: db);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 4000000,
        categoryId: 1,
        date: '2026-11-02',
      );
      await goTo(tester, '/overview');
      expect(findPlainText('1.000.000 ₫'), findsWidgets);
      expect(findPlainText('Đã dùng 80%'), findsOneWidget);
      expect(
        findSemanticsLabel(
          'Ngân sách còn lại, 1.000.000 ₫, Sắp vượt, Đã dùng 80%',
        ),
        findsOneWidget,
      );
      await disposeApp(tester, db);
    });

    testWidgets('tháng không có khoản: trạng thái trống, không vẽ biểu đồ; '
        'chưa đặt ngân sách thì có nút "Đặt ngân sách"', (tester) async {
      final db = await pumpApp(tester);
      await goTo(tester, '/overview');
      expect(find.text('Tháng này chưa có khoản nào'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('Đặt ngân sách'), findsOneWidget);
      // Không đi quá tháng hiện tại.
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Tháng sau'),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull);
      await disposeApp(tester, db);
    });

    testWidgets('thẻ Nợ: số còn lại theo hai chiều, không vào Tổng số dư; '
        'chạm mở Khoản nợ', (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() async {
        final debts = DebtRepository(db);
        await debts.add(
          person: 'An',
          direction: DebtDirection.lent,
          amount: 2000000,
          date: '2026-11-01',
          currency: 'VND',
        );
        final b = await debts.add(
          person: 'Bình',
          direction: DebtDirection.borrowed,
          amount: 700000,
          date: '2026-11-01',
          currency: 'VND',
        );
        await debts.addPayment(b, amount: 200000, date: '2026-11-02');
        // Đã xong: không tính.
        final c = await debts.add(
          person: 'Chi',
          direction: DebtDirection.lent,
          amount: 100000,
          date: '2026-11-01',
          currency: 'VND',
        );
        await debts.addPayment(c, amount: 100000, date: '2026-11-02');
      });
      await pumpApp(tester, db: db);
      await goTo(tester, '/overview');
      expect(findPlainText('Người khác nợ bạn 2.000.000 ₫'), findsOneWidget);
      expect(findPlainText('Bạn nợ 500.000 ₫'), findsOneWidget);
      expect(
        findSemanticsLabel(
          'Tổng số dư, 0 ₫, Mọi tài khoản, kể cả tài khoản ẩn. '
          'Không gồm khoản nợ.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Nợ'));
      await settle(tester);
      expect(find.byType(DebtsScreen), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('màn chính mở Tổng quan, Thống kê, Lịch từ nút trên thanh '
        'trên', (tester) async {
      final db = await pumpApp(tester);
      await tester.tap(find.byTooltip('Tổng quan, thống kê, lịch'));
      await settle(tester);
      expect(find.text('Thống kê'), findsOneWidget);
      expect(find.text('Lịch'), findsOneWidget);
      await tester.tap(find.text('Tổng quan'));
      await settle(tester);
      expect(find.byType(OverviewScreen), findsOneWidget);
      await disposeApp(tester, db);
    });
  });

  group('Thống kê (F-36)', () {
    testWidgets('cột theo ngày, 5 danh mục, ngày chi nhiều nhất, đường số dư', (
      tester,
    ) async {
      final db = await pumpApp(tester);
      for (final (amount, category, date) in [
        (100000, 1, '2026-11-01'),
        (250000, 2, '2026-11-02'),
        (50000, 3, '2026-11-02'),
        (30000, 4, '2026-11-03'),
        (20000, 5, '2026-11-03'),
        (10000, 6, '2026-11-03'),
      ]) {
        await insertEntry(
          tester,
          db,
          type: EntryType.expense,
          amount: amount,
          categoryId: category,
          date: date,
        );
      }
      await goTo(tester, '/stats');
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Danh mục chi nhiều nhất'), findsOneWidget);
      // 5 danh mục, không phải 6.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              RegExp(r', \d+[,.]\d%$').hasMatch(w.properties.label ?? ''),
        ),
        findsNWidgets(5),
      );
      // Ngày 2/11 chi 300.000 ₫.
      await tester.scrollUntilVisible(
        find.text('Ngày chi nhiều nhất'),
        200,
        scrollable: _scrollableOf(StatsScreen),
      );
      expect(find.text('Ngày chi nhiều nhất'), findsOneWidget);
      expect(findPlainText('300.000 ₫'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Lịch sử tổng số dư'),
        200,
        scrollable: _scrollableOf(StatsScreen),
      );
      expect(find.byType(LineChart), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('kỳ không có khoản: trạng thái trống, không biểu đồ (AC-110)', (
      tester,
    ) async {
      final db = await pumpApp(tester);
      await goTo(tester, '/stats');
      expect(find.text('Kỳ này chưa có khoản nào'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(LineChart), findsNothing);
      await disposeApp(tester, db);
    });
  });

  group('Lịch (F-38)', () {
    testWidgets('ô ngày: chi rút gọn, chấm thu, đọc "3 tháng 11, chi …"; '
        'chạm ngày → danh sách, vuốt xoá có Hoàn tác', (tester) async {
      final db = await pumpApp(tester);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 250000,
        categoryId: 1,
        note: 'phở',
        date: '2026-11-03',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 1200000,
        categoryId: 2,
        date: '2026-11-06',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.income,
        amount: 9000000,
        categoryId: 11,
        date: '2026-11-06',
      );
      await goTo(tester, '/calendar');
      expect(find.text('250k'), findsOneWidget);
      expect(find.text('1,2tr'), findsOneWidget);
      expect(findSemanticsLabel('3 tháng 11, chi 250.000 ₫'), findsOneWidget);
      expect(
        findSemanticsLabel('6 tháng 11, chi 1.200.000 ₫, có thu'),
        findsOneWidget,
      );
      // Hôm nay được chọn sẵn: danh sách khoản của ngày 3.
      expect(find.textContaining('phở'), findsOneWidget);
      expect(findPlainText('Chi 250.000 ₫ · Thu 0 ₫'), findsOneWidget);

      // Chạm ngày 6.
      await tester.tap(
        findSemanticsLabel('6 tháng 11, chi 1.200.000 ₫, có thu'),
      );
      await settle(tester);
      expect(
        findPlainText('Chi 1.200.000 ₫ · Thu 9.000.000 ₫'),
        findsOneWidget,
      );

      // Về ngày 3, vuốt xoá rồi Hoàn tác.
      await tester.tap(findSemanticsLabel('3 tháng 11, chi 250.000 ₫'));
      await settle(tester);
      await tester.drag(find.textContaining('phở'), const Offset(-500, 0));
      await settle(tester);
      expect(find.textContaining('phở'), findsNothing);
      expect(find.text('250k'), findsNothing);
      await tester.tap(find.text('Hoàn tác'));
      await settle(tester);
      expect(find.textContaining('phở'), findsOneWidget);
      expect(find.text('250k'), findsOneWidget);

      // Tháng trước: không có khoản.
      await tester.tap(find.byTooltip('Tháng trước'));
      await settle(tester);
      expect(find.text('250k'), findsNothing);
      await disposeApp(tester, db);
    });
  });
}
