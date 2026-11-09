import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';

import '../helpers.dart';

/// Ghi thẳng khoản nợ/lần trả (không qua `DebtRepository.addPayment`: nó mở
/// giao dịch, mà giao dịch mở trong `tester.runAsync` khi cây widget đang theo
/// dõi stream sẽ treo; trong app thì chạy trong vùng của widget, không sao).
Future<int> _debt(
  WidgetTester tester,
  AppDatabase db, {
  String person = 'Lan',
  DebtDirection direction = DebtDirection.lent,
  int amount = 500000,
  String date = '2026-11-01',
  String? due,
  String? note,
  List<(int amount, String date)> payments = const [],
}) async {
  final id = await tester.runAsync(() async {
    final id = await db
        .into(db.debts)
        .insert(
          DebtsCompanion.insert(
            person: person,
            direction: direction,
            amount: amount,
            date: date,
            dueDate: Value(due),
            note: Value(note),
            currency: const Value('VND'),
            originalAmount: Value(amount),
          ),
        );
    for (final (a, d) in payments) {
      await db
          .into(db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              debtId: id,
              amount: a,
              date: d,
              currency: const Value('VND'),
              originalAmount: Value(a),
            ),
          );
    }
    return id;
  });
  await settle(tester);
  return id!;
}

Future<List<DebtView>> _all(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => DebtRepository(db).all()))!;

void main() {
  testWidgets('chưa có khoản nợ: hiện hướng dẫn', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/debts');
    expect(find.text('Khoản nợ'), findsOneWidget);
    expect(find.textContaining('Chưa có khoản nợ nào'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('thêm khoản nợ: người, chiều, số tiền, hạn, ghi chú (AC-104)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Thêm khoản nợ'));
    await settle(tester);
    // Mặc định là "Cho vay".
    await tester.enterText(find.widgetWithText(TextField, 'Người'), 'Bình');
    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '500000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Ghi chú'),
      'ăn trưa',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    final debts = await _all(tester, db);
    final d = debts.single.debt;
    expect(d.person, 'Bình');
    expect(d.direction, DebtDirection.lent);
    expect(d.amount, 500000);
    expect(d.date, '2026-11-03');
    expect(d.dueDate, isNull);
    expect(d.note, 'ăn trưa');
    expect(find.text('Người khác nợ bạn'), findsOneWidget);
    expect(find.text('Bạn nợ người khác'), findsNothing);
    expect(findPlainText('Còn lại 500.000 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('chọn "Đi vay": vào nhóm "Bạn nợ người khác"', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Thêm khoản nợ'));
    await settle(tester);
    await tester.tap(find.text('Đi vay'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Người'), 'Mẹ');
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền'),
      '2000000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(
      (await _all(tester, db)).single.debt.direction,
      DebtDirection.borrowed,
    );
    expect(find.text('Bạn nợ người khác'), findsOneWidget);
    expect(find.text('Người khác nợ bạn'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('hai nhóm, mỗi nhóm có tổng còn lại (AC-104)', (tester) async {
    final db = await pumpApp(tester);
    await _debt(tester, db, person: 'A', amount: 300000);
    await _debt(
      tester,
      db,
      person: 'B',
      amount: 200000,
      payments: [(50000, '2026-11-02')],
    );
    await _debt(
      tester,
      db,
      person: 'C',
      direction: DebtDirection.borrowed,
      amount: 1000000,
    );
    await goTo(tester, '/debts');
    expect(find.text('Người khác nợ bạn'), findsOneWidget);
    expect(find.text('Bạn nợ người khác'), findsOneWidget);
    // 300.000 + (200.000 − 50.000) = 450.000.
    expect(findPlainText('Còn lại 450.000 ₫'), findsOneWidget);
    expect(findPlainText('Còn lại 1.000.000 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('người để trống và số tiền 0 báo lỗi, không lưu; tên ≤ 50, ghi '
      'chú ≤ 200 (AC-104)', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Thêm khoản nợ'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '0');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Nhập tên'), findsOneWidget);
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    expect(await _all(tester, db), isEmpty);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Người'))
          .maxLength,
      50,
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Ghi chú'))
          .maxLength,
      200,
    );
    await disposeApp(tester, db);
  });

  testWidgets('thêm lần trả: còn lại giảm; trả vượt thì báo lỗi, không lưu '
      '(AC-105)', (tester) async {
    final db = await pumpApp(tester);
    final id = await _debt(tester, db);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Lan'));
    await settle(tester);
    await tester.tap(find.text('Thêm lần trả'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền trả'),
      '200000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(findPlainText('Còn lại 300.000 ₫'), findsWidgets);
    // Vượt số còn lại (300.000): báo lỗi.
    await tester.tap(find.text('Thêm lần trả'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền trả'),
      '300001',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.textContaining('Vượt số còn lại'), findsOneWidget);
    var view = (await _all(tester, db)).singleWhere((v) => v.debt.id == id);
    expect(view.payments, hasLength(1));
    expect(view.payments.single.amount, 200000);
    // Trả đúng số còn lại thì được.
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền trả'),
      '300000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    view = (await _all(tester, db)).singleWhere((v) => v.debt.id == id);
    expect(view.payments, hasLength(2));
    expect(view.remaining(0), 0);
    await disposeApp(tester, db);
  });

  testWidgets('trả hết: chuyển xuống mục "Đã xong" thu gọn; xoá lần trả thì '
      'tính lại (AC-105)', (tester) async {
    final db = await pumpApp(tester);
    await _debt(
      tester,
      db,
      payments: [(300000, '2026-11-01'), (200000, '2026-11-02')],
    );
    await goTo(tester, '/debts');
    // Đã xong: không còn trong nhóm, mục "Đã xong (1)" thu gọn.
    expect(find.text('Người khác nợ bạn'), findsNothing);
    expect(find.text('Đã xong (1)'), findsOneWidget);
    expect(find.text('Lan'), findsNothing);
    await tester.tap(find.text('Đã xong (1)'));
    await settle(tester);
    expect(find.text('Lan'), findsOneWidget);
    expect(find.text('Đã xong'), findsOneWidget);
    // Xoá một lần trả → còn lại 200.000, quay về nhóm.
    await tester.tap(find.text('Lan'));
    await settle(tester);
    await tester.tap(find.byTooltip('Xoá lần trả').last);
    await settle(tester);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop(); // đóng bảng
    await settle(tester);
    expect(find.text('Người khác nợ bạn'), findsOneWidget);
    expect(findPlainText('Còn lại 200.000 ₫'), findsWidgets);
    expect(find.textContaining('Đã xong ('), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('quá hạn mà chưa xong hiện chữ "Quá hạn"; xong rồi thì không '
      '(AC-105)', (tester) async {
    final db = await pumpApp(tester); // hôm nay 2026-11-03
    await _debt(tester, db, person: 'Trễ', due: '2026-11-02');
    await _debt(tester, db, person: 'Chưa tới', due: '2026-11-03');
    await _debt(
      tester,
      db,
      person: 'Đã trả',
      due: '2026-10-01',
      payments: [(500000, '2026-10-20')],
    );
    await goTo(tester, '/debts');
    expect(find.textContaining('Quá hạn'), findsOneWidget);
    expect(find.textContaining('Hạn '), findsWidgets);
    await tester.tap(find.text('Đã xong (1)'));
    await settle(tester);
    expect(find.textContaining('Quá hạn'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('sửa khoản nợ; số tiền không được nhỏ hơn số đã trả', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final id = await _debt(tester, db, payments: [(200000, '2026-11-02')]);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Lan'));
    await settle(tester);
    await tester.tap(find.text('Sửa khoản nợ'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '100000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.textContaining('Không được nhỏ hơn số đã trả'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '800000');
    await tester.enterText(find.widgetWithText(TextField, 'Người'), 'Lan Anh');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final d = (await _all(tester, db)).singleWhere((v) => v.debt.id == id).debt;
    expect(d.amount, 800000);
    expect(d.person, 'Lan Anh');
    await disposeApp(tester, db);
  });

  testWidgets('xoá khoản nợ sau hộp xác nhận: xoá cả lần trả (AC-104)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _debt(tester, db, payments: [(100000, '2026-11-02')]);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Lan'));
    await settle(tester);
    await tester.tap(find.text('Xoá khoản nợ'));
    await settle(tester);
    expect(find.text('Xoá khoản nợ?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(await _all(tester, db), hasLength(1));
    await tester.tap(find.text('Xoá khoản nợ'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await settle(tester);
    expect(await _all(tester, db), isEmpty);
    final payments = await tester.runAsync(
      () => db.select(db.debtPayments).get(),
    );
    expect(payments, isEmpty);
    expect(find.text('Đã xoá khoản nợ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('khoản nợ không tạo khoản, không đổi số dư tài khoản, không vào '
      'thu chi (AC-106)', (tester) async {
    final db = await pumpApp(tester);
    await _debt(tester, db, payments: [(100000, '2026-11-02')]);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Thêm khoản nợ'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Người'), 'Hùng');
    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '70000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts!.single.initialBalance, 0);
    await goTo(tester, '/');
    expect(findSemanticsLabel('Số dư: 0 ₫, Tháng 11 năm 2026'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
