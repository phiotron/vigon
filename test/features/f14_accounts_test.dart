import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';

Future<void> openAccounts(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.tap(find.text('Tài khoản'));
  await settle(tester);
}

Future<int> addCard(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 50000),
    ))!;

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(VigonApp)));

void main() {
  testWidgets('ẩn tài khoản rồi hiện lại từ mục đã ẩn (AC-44, AC-47)', (
    tester,
  ) async {
    final db = memoryDatabase();
    await addCard(tester, db);
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 20000,
      categoryId: 1,
      accountId: 2,
    );
    await openAccounts(tester);
    // Chưa ẩn gì thì chưa có mục "Tài khoản đã ẩn".
    expect(find.textContaining('Tài khoản đã ẩn'), findsNothing);
    await tester.tap(find.text('Thẻ'));
    await settle(tester);
    await tester.tap(find.text('Ẩn tài khoản'));
    await settle(tester);
    // Không còn trong danh sách; mục đã ẩn có đếm, thu gọn mặc định (A10).
    expect(find.text('Tài khoản đã ẩn (1)'), findsOneWidget);
    expect(find.text('Thẻ'), findsNothing);
    expect(find.text('Hiện lại'), findsNothing);
    await tester.tap(find.text('Tài khoản đã ẩn (1)'));
    await settle(tester);
    expect(find.text('Thẻ'), findsOneWidget);
    // Số dư tài khoản ẩn vẫn đúng: 50.000 - 20.000.
    expect(findPlainText('30.000 ₫'), findsOneWidget);
    // Chạm hàng ẩn mở bảng Sửa: "Hiện lại" thay "Ẩn tài khoản" (SCR-18).
    await tester.tap(find.text('Thẻ'));
    await settle(tester);
    expect(find.text('Sửa tài khoản'), findsOneWidget);
    expect(find.text('Ẩn tài khoản'), findsNothing);
    expect(find.text('Hiện lại'), findsNWidgets(2));
    await tester.tapAt(const Offset(10, 10)); // đóng bảng
    await settle(tester);
    // Nút "Hiện lại" trên hàng.
    await tester.tap(find.text('Hiện lại'));
    await settle(tester);
    expect(find.textContaining('Tài khoản đã ẩn'), findsNothing);
    expect(find.text('Thẻ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('tài khoản ẩn biến khỏi menu lọc, bảng chọn, Chuyển tiền; '
      'khoản của nó vẫn tính (AC-44)', (tester) async {
    final db = memoryDatabase();
    final card = await addCard(tester, db);
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 20000,
      categoryId: 1,
      accountId: card,
    );
    // Đang lọc đúng tài khoản sắp ẩn.
    containerOf(tester).read(accountFilterProvider.notifier).select(card);
    await settle(tester);
    expect(
      findSemanticsLabel('Số dư: -20.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    await tester.runAsync(() => AccountRepository(db).archive(card));
    await settle(tester);
    // Bộ lọc tự bỏ, khoản của tài khoản ẩn vẫn nằm trong tổng.
    expect(containerOf(tester).read(accountFilterProvider), isNull);
    expect(
      findSemanticsLabel('Số dư: -20.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    // Chỉ còn một tài khoản hiện: không có menu lọc.
    expect(find.byTooltip('Tài khoản'), findsNothing);
    // Danh sách khoản vẫn có khoản cũ, ghi đúng tên tài khoản ẩn.
    await tester.tap(find.byTooltip('Các khoản'));
    await settle(tester);
    expect(find.textContaining('20.000'), findsWidgets);
    await disposeApp(tester, db);
  });

  testWidgets('ghi khoản và Chuyển tiền chỉ liệt kê tài khoản hiện (AC-44)', (
    tester,
  ) async {
    final db = memoryDatabase();
    final card = await addCard(tester, db);
    final bank = (await tester.runAsync(
      () => AccountRepository(db).add(name: 'Ngân hàng'),
    ))!;
    await pumpApp(tester, db: db);
    await tester.runAsync(() => AccountRepository(db).archive(card));
    await settle(tester);
    // Bảng chọn tài khoản khi ghi khoản.
    await tester.tap(find.byTooltip('Ăn uống'));
    await settle(tester);
    await tester.tap(find.text('Tiền mặt'));
    await settle(tester);
    expect(find.text('Ngân hàng'), findsOneWidget);
    expect(find.text('Thẻ'), findsNothing);
    await tester.tapAt(const Offset(10, 10)); // đóng bảng
    await settle(tester);
    await disposeApp(tester, db);
    expect(bank, isNot(card));
  });

  testWidgets('Chuyển tiền cần 2 tài khoản hiện, ô Từ/Đến bỏ tài khoản ẩn '
      '(AC-44)', (tester) async {
    final db = memoryDatabase();
    final card = await addCard(tester, db);
    await pumpApp(tester, db: db);
    await openAccounts(tester);
    expect(find.byTooltip('Chuyển tiền'), findsOneWidget);
    await tester.runAsync(() => AccountRepository(db).archive(card));
    await settle(tester);
    // Còn 1 tài khoản hiện nên không còn nút Chuyển tiền.
    expect(find.byTooltip('Chuyển tiền'), findsNothing);
    await tester.runAsync(() => AccountRepository(db).unarchive(card));
    await tester.runAsync(() => AccountRepository(db).add(name: 'Ngân hàng'));
    await settle(tester);
    await tester.runAsync(() => AccountRepository(db).archive(card));
    await settle(tester);
    await tester.tap(find.byTooltip('Chuyển tiền'));
    await settle(tester);
    await tester.tap(find.text('Tiền mặt').first);
    await settle(tester);
    expect(find.text('Ngân hàng'), findsWidgets);
    expect(find.text('Thẻ'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    await disposeApp(tester, db);
  });

  testWidgets('chỉ xóa được tài khoản chưa có khoản, có hộp thoại xác nhận '
      '(AC-45)', (tester) async {
    final db = memoryDatabase();
    final card = await addCard(tester, db);
    final bank = (await tester.runAsync(
      () => AccountRepository(db).add(name: 'Ngân hàng'),
    ))!;
    await pumpApp(tester, db: db);
    // Thẻ chỉ là nơi nhận của một khoản chuyển tiền: vẫn tính là đã có khoản.
    await insertEntry(
      tester,
      db,
      type: EntryType.transfer,
      amount: 1000,
      accountId: 1,
      toAccountId: card,
    );
    await openAccounts(tester);
    await tester.tap(find.text('Thẻ'));
    await settle(tester);
    expect(find.text('Tài khoản đã có khoản, chỉ ẩn được'), findsOneWidget);
    expect(find.text('Xóa tài khoản'), findsNothing);
    expect(find.text('Ẩn tài khoản'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // đóng bảng
    await settle(tester);
    // Ngân hàng chưa có khoản: xóa được, phải xác nhận.
    await tester.tap(find.text('Ngân hàng'));
    await settle(tester);
    expect(find.text('Tài khoản đã có khoản, chỉ ẩn được'), findsNothing);
    await tester.tap(find.text('Xóa tài khoản'));
    await settle(tester);
    expect(find.text('Xóa tài khoản "Ngân hàng"?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    var rows = await tester.runAsync(() => db.select(db.accounts).get());
    expect(rows!.any((a) => a.id == bank), isTrue);
    await tester.tap(find.text('Xóa tài khoản'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await settle(tester);
    rows = await tester.runAsync(() => db.select(db.accounts).get());
    expect(rows!.any((a) => a.id == bank), isFalse);
    expect(find.text('Ngân hàng'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('tài khoản hiện cuối cùng không ẩn, không xóa được (AC-46)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Tiền mặt'));
    await settle(tester);
    expect(find.text('Phải còn ít nhất một tài khoản'), findsOneWidget);
    expect(find.text('Ẩn tài khoản'), findsNothing);
    expect(find.text('Xóa tài khoản'), findsNothing);
    await disposeApp(tester, db);
  });
}
