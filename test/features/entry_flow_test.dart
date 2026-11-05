import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

Future<void> typeKeys(WidgetTester tester, String keys) async {
  for (final k in keys.split('')) {
    await tester.tap(find.widgetWithText(TextButton, k));
    await tester.pump();
  }
}

void main() {
  testWidgets(
    'bấm −, nhập 120+35, chọn danh mục thì lưu 155 và về màn chính (AC-02, AC-03, AC-07)',
    (tester) async {
      final db = await pumpApp(tester);

      await tester.tap(find.byTooltip('Thêm khoản chi')); // chạm 1
      await settle(tester);
      expect(find.text('Khoản chi mới'), findsOneWidget);
      await typeKeys(tester, '120+35');
      expect(findPlainText('155 ₫'), findsOneWidget);

      await tester.tap(find.text('Chọn danh mục')); // chạm 2
      await settle(tester);
      await tester.tap(find.text('Ăn uống')); // chạm 3
      await settle(tester);

      expect(find.text('Khoản chi mới'), findsNothing);
      expect(
        findSemanticsLabel('Số dư: -155 ₫, Tháng 11 năm 2026'),
        findsOneWidget,
      );
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.amount, 155);
      expect(rows.single.type, EntryType.expense);
      expect(rows.single.date, '2026-11-03');
      await disposeApp(tester, db);
    },
  );

  testWidgets(
    'chạm icon danh mục quanh biểu đồ thì danh mục chọn sẵn (AC-06)',
    (tester) async {
      final db = await pumpApp(tester);
      await tester.tap(find.byTooltip('Đi lại'));
      await settle(tester);
      expect(find.text('Đi lại'), findsOneWidget); // chip danh mục
      await typeKeys(tester, '30');
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.categoryId, 2);
      await disposeApp(tester, db);
    },
  );

  testWidgets('số tiền 0 thì không lưu và báo lỗi (AC-05)', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Thêm khoản chi'));
    await settle(tester);
    await typeKeys(tester, '0');
    await tester.tap(find.text('Chọn danh mục'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows, isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('kỳ trống hiện hướng dẫn, không vẽ biểu đồ (AC-09)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsOneWidget);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 50000,
      categoryId: 1,
    );
    expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('sửa khoản thì tổng cập nhật; xóa rồi hoàn tác (AC-13, AC-14)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 50000,
      categoryId: 1,
      note: 'phở',
    );

    await tester.tap(find.byTooltip('Các khoản'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    await tester.tap(find.text('phở'));
    await settle(tester);
    expect(find.text('Sửa khoản'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Xóa lùi'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    var rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows!.single.amount, 5000);

    await tester.tap(find.text('phở'));
    await settle(tester);
    await tester.tap(find.byTooltip('Xóa'));
    await settle(tester);
    expect(find.text('Đã xóa'), findsOneWidget);
    rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows, isEmpty);

    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows!.single.amount, 5000);
    expect(rows.single.note, 'phở');
    await disposeApp(tester, db);
  });
}
