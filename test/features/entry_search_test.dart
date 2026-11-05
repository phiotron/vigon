import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

Future<void> openEntries(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Các khoản'));
  await settle(tester);
  await tester.tap(find.byTooltip('Tìm'));
  await settle(tester);
}

Future<void> typeQuery(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await settle(tester);
}

void main() {
  testWidgets('tìm trong kỳ đang xem, bỏ dấu, theo số tiền (AC-48, AC-49)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 155000,
      categoryId: 1,
      note: 'Cà phê',
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1550000,
      categoryId: 1,
      date: '2026-11-01',
      note: 'Tiệc',
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 20000,
      categoryId: 2,
      note: 'Grab',
    );
    // Ngoài kỳ đang xem (tháng 11/2026).
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 70000,
      categoryId: 1,
      date: '2026-05-10',
      note: 'Cà phê cũ',
    );

    await openEntries(tester);
    expect(find.byType(TextField), findsOneWidget);

    // Ghi chú, không phân biệt hoa thường và dấu.
    await typeQuery(tester, 'CA PHE');
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Grab'), findsNothing);
    expect(find.text('Cà phê cũ'), findsNothing);
    expect(findPlainText('1 khoản · tổng 155.000 ₫'), findsOneWidget);

    // Tên danh mục "Ăn uống" (danh mục mặc định, dịch theo ngôn ngữ).
    await typeQuery(tester, 'an uong');
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Tiệc'), findsOneWidget);
    expect(find.text('Grab'), findsNothing);
    expect(findPlainText('2 khoản · tổng 1.705.000 ₫'), findsOneWidget);

    // Số tiền: "155" khớp 155.000 và 1.550.000.
    await typeQuery(tester, '155');
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Tiệc'), findsOneWidget);
    expect(find.text('Grab'), findsNothing);

    // Không khớp.
    await typeQuery(tester, 'khong co');
    expect(find.text('Không có khoản nào khớp'), findsOneWidget);

    // Tất cả thời gian thêm khoản của tháng 5.
    await typeQuery(tester, 'ca phe');
    expect(find.text('Cà phê cũ'), findsNothing);
    await tester.tap(find.text('Tất cả thời gian'));
    await settle(tester);
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Cà phê cũ'), findsOneWidget);
    expect(findPlainText('2 khoản · tổng 225.000 ₫'), findsOneWidget);
    // Mới nhất trước.
    expect(
      tester.getTopLeft(find.text('Cà phê')).dy,
      lessThan(tester.getTopLeft(find.text('Cà phê cũ')).dy),
    );

    // Chọn chip tên kỳ (cặp chip chọn một, A21) thì quay về kỳ đang xem.
    await tester.tap(find.text('Tháng 11 năm 2026'));
    await settle(tester);
    expect(find.text('Cà phê cũ'), findsNothing);

    // Đóng tìm kiếm trả về danh sách thường.
    await tester.tap(find.byTooltip('Đóng tìm kiếm'));
    await settle(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Số dư'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('kết quả: chạm sửa, vuốt xóa và hoàn tác (AC-49)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 50000,
      categoryId: 1,
      note: 'phở bò',
    );
    await openEntries(tester);
    await typeQuery(tester, 'pho');

    // Vuốt xóa rồi hoàn tác.
    await tester.drag(find.text('phở bò'), const Offset(-600, 0));
    await settle(tester);
    expect(find.text('Đã xóa'), findsOneWidget);
    var rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows, isEmpty);
    expect(find.text('Không có khoản nào khớp'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows!.single.note, 'phở bò');
    expect(find.text('phở bò'), findsOneWidget);

    // Chạm mở màn sửa.
    await tester.tap(find.text('phở bò'));
    await settle(tester);
    expect(find.text('Sửa khoản'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('nút Back đóng ô tìm trước, rồi mới thoát màn (AC-48)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await openEntries(tester);
    expect(find.byType(TextField), findsOneWidget);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Tìm'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
