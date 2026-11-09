import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/savings_repository.dart';
import 'package:vigon/src/features/savings/savings_screen.dart';

import '../helpers.dart';
import 'entry_flow_test.dart' show typeKeys;

SavingsGoalRepository _goals(AppDatabase db) => SavingsGoalRepository(db);

/// Ghi thẳng một mục tiêu.
///
/// Mỗi thao tác ghi đi trong một `tester.runAsync` RIÊNG rồi `settle`: ghi
/// vào bảng mà cây widget đang theo dõi làm stream chạy lại truy vấn trong vùng
/// giả của widget; nếu khi đó cùng khối `runAsync` còn đợi một lần ghi nữa thì
/// hai bên giữ khoá của nhau và test treo (kể cả khi gọi `SavingsGoalRepository
/// .add`, vì nó mở giao dịch).
Future<int> _insertGoal(
  WidgetTester tester,
  AppDatabase db, {
  required String name,
  required int target,
  required int accountId,
  String? due,
}) async {
  final id = await tester.runAsync(
    () => db
        .into(db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            name: name,
            targetAmount: target,
            accountId: accountId,
            dueDate: Value(due),
            currency: const Value('VND'),
            originalTargetAmount: Value(target),
          ),
        ),
  );
  await settle(tester);
  return id!;
}

/// Thêm một tài khoản (xem lý do tách `runAsync` ở [_insertGoal]).
Future<int> _insertAccount(
  WidgetTester tester,
  AppDatabase db,
  String name,
  int balance,
) async {
  final id = await tester.runAsync(
    () =>
        AccountRepository(db)
            .add(name: name, initialBalance: balance, currency: 'VND'),
  );
  await settle(tester);
  return id!;
}

/// Tạo tài khoản + mục tiêu gắn nó.
Future<(int goalId, int accountId)> _seedGoal(
  WidgetTester tester,
  AppDatabase db, {
  String name = 'Du lịch',
  int target = 10000000,
  int balance = 3000000,
  String? due,
}) async {
  final account = await _insertAccount(tester, db, name, balance);
  final goal = await _insertGoal(
    tester,
    db,
    name: name,
    target: target,
    accountId: account,
    due: due,
  );
  return (goal, account);
}

void main() {
  group('GoalProgress (AC-101)', () {
    SavingsGoal goal(int target, {String? due}) => SavingsGoal(
      id: 1,
      name: 'x',
      targetAmount: target,
      accountId: 1,
      dueDate: due,
      createdAt: DateTime(2026, 11, 1),
      currency: 'VND',
    );
    final today = DateTime(2026, 11, 3);

    test(
      '30% và còn thiếu 7.000.000; làm tròn xuống, chưa đạt thì không 100%',
      () {
        final p = GoalProgress.of(goal(10000000), 3000000, today);
        expect(p.percent, 30);
        expect(p.missing, 7000000);
        expect(p.reached, isFalse);
        final almost = GoalProgress.of(goal(10000000), 9999999, today);
        expect(almost.percent, 99);
        expect(almost.reached, isFalse);
      },
    );

    test('đạt khi số dư ≥ mục tiêu; số dư âm không ra phần trăm âm', () {
      expect(GoalProgress.of(goal(100), 100, today).reached, isTrue);
      expect(GoalProgress.of(goal(100), 250, today).percent, 100);
      expect(GoalProgress.of(goal(100), 250, today).missing, 0);
      final neg = GoalProgress.of(goal(100), -50, today);
      expect(neg.percent, 0);
      expect(neg.fraction, 0);
      expect(neg.missing, 150);
    });

    test('số ngày tới hạn và quá hạn', () {
      expect(
        GoalProgress.of(goal(100, due: '2026-11-10'), 0, today).daysToDue,
        7,
      );
      final over = GoalProgress.of(goal(100, due: '2026-11-01'), 0, today);
      expect(over.daysToDue, -2);
      expect(over.overdue, isTrue);
      // Đã đạt thì không bao giờ "quá hạn".
      expect(
        GoalProgress.of(goal(100, due: '2026-11-01'), 100, today).overdue,
        isFalse,
      );
      expect(GoalProgress.of(goal(100), 0, today).daysToDue, isNull);
    });
  });

  testWidgets('chưa có mục tiêu: hiện hướng dẫn', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/savings');
    expect(find.text('Tiết kiệm'), findsOneWidget);
    expect(find.textContaining('Chưa có mục tiêu tiết kiệm'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('tạo mục tiêu với tài khoản mới: tài khoản tên = tên mục tiêu, '
      'số dư 0 (AC-100)', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Thêm mục tiêu'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Tên'), 'Mua xe');
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền mục tiêu'),
      '10000000',
    );
    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    final goals = await tester.runAsync(() => _goals(db).all());
    expect(goals!.single.name, 'Mua xe');
    expect(goals.single.targetAmount, 10000000);
    expect(goals.single.dueDate, isNull);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    final account = accounts!.firstWhere((a) => a.id == goals.single.accountId);
    expect(account.name, 'Mua xe');
    expect(account.initialBalance, 0);
    expect(accounts, hasLength(2));
    // Thẻ mục tiêu: tiến độ 0.
    expect(findPlainText('Đã có 0 ₫ / 10.000.000 ₫'), findsOneWidget);
    expect(findPlainText('Còn thiếu 10.000.000 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('gắn tài khoản có sẵn: tài khoản đã gắn mục tiêu khác không '
      'được đưa ra để chọn (AC-100)', (tester) async {
    final db = await pumpApp(tester);
    await _seedGoal(tester, db, name: 'Quỹ A');
    await _insertAccount(tester, db, 'Thẻ B', 500000);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Thêm mục tiêu'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Tên'), 'Quỹ B');
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền mục tiêu'),
      '2000000',
    );
    await tester.tap(find.text('Tạo tài khoản mới'));
    await settle(tester);
    expect(find.text('Thẻ B'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    // "Quỹ A" đã gắn mục tiêu: chỉ còn ở thẻ mục tiêu phía sau, không trong bảng.
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Quỹ A'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Thẻ B'));
    await settle(tester);
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final goals = await tester.runAsync(() => _goals(db).all());
    expect(goals, hasLength(2));
    final b = goals!.firstWhere((g) => g.name == 'Quỹ B');
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts!.firstWhere((a) => a.id == b.accountId).name, 'Thẻ B');
    expect(accounts, hasLength(3)); // không tạo thêm tài khoản
    await disposeApp(tester, db);
  });

  testWidgets(
    'tên trống và số tiền 0 báo lỗi, không lưu; tên tối đa 50 ký tự',
    (tester) async {
      final db = await pumpApp(tester);
      await goTo(tester, '/savings');
      await tester.tap(find.text('Thêm mục tiêu'));
      await settle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Số tiền mục tiêu'),
        '0',
      );
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      expect(find.text('Nhập tên'), findsOneWidget);
      expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Tên'), 'a' * 60);
      final name = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Tên'),
      );
      expect(name.maxLength, 50);
      final goals = await tester.runAsync(() => _goals(db).all());
      expect(goals, isEmpty);
      await disposeApp(tester, db);
    },
  );

  testWidgets('tiến độ: 3.000.000 / 10.000.000 → 30%, còn thiếu 7.000.000 '
      '(AC-101)', (tester) async {
    final db = await pumpApp(tester);
    await _seedGoal(tester, db);
    await goTo(tester, '/savings');
    expect(findPlainText('Đã có 3.000.000 ₫ / 10.000.000 ₫'), findsOneWidget);
    expect(findPlainText('Còn thiếu 7.000.000 ₫'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('đạt mục tiêu hiện "Đã đạt"; rút tiền thì mất (AC-101)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final (_, accountId) = await _seedGoal(
      tester,
      db,
      target: 5000000,
      balance: 5000000,
    );
    await goTo(tester, '/savings');
    expect(find.text('Đã đạt'), findsOneWidget);
    expect(find.textContaining('Còn thiếu'), findsNothing);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1000000,
      categoryId: 1,
      accountId: accountId,
    );
    expect(find.text('Đã đạt'), findsNothing);
    expect(findPlainText('Còn thiếu 1.000.000 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('hạn: "Còn N ngày", "Quá hạn N ngày"; đã đạt thì không quá hạn '
      '(AC-101)', (tester) async {
    final db = await pumpApp(tester); // hôm nay 2026-11-03
    await _seedGoal(tester, db, name: 'Sắp tới', due: '2026-11-10');
    await _seedGoal(tester, db, name: 'Trễ', due: '2026-11-01');
    await _seedGoal(
      tester,
      db,
      name: 'Xong rồi',
      due: '2026-10-01',
      balance: 10000000,
    );
    await goTo(tester, '/savings');
    expect(find.text('Còn 7 ngày'), findsOneWidget);
    expect(find.text('Quá hạn 2 ngày'), findsOneWidget);
    expect(find.text('Đã đạt'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Góp tiền mở màn Chuyển tiền: Đến = tài khoản mục tiêu, Từ = '
      'tài khoản mặc định; lưu là Transfer, thu chi không đổi (AC-102)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final (_, accountId) = await _seedGoal(tester, db);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Góp tiền'));
    await settle(tester);
    expect(find.text('Chuyển tiền'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('transfer-to')),
        matching: find.text('Du lịch'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('transfer-from')),
        matching: find.text('Tiền mặt'),
      ),
      findsOneWidget,
    );
    await typeKeys(tester, '500000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.entries).get());
    final t = rows!.single;
    expect(t.type, EntryType.transfer);
    expect(t.toAccountId, accountId);
    expect(t.accountId, 1);
    expect(t.amount, 500000);
    // Quay lại màn Tiết kiệm: tiến độ tăng 500.000.
    expect(findPlainText('Đã có 3.500.000 ₫ / 10.000.000 ₫'), findsOneWidget);
    // Tổng thu, tổng chi của kỳ không đổi.
    await goTo(tester, '/');
    expect(findSemanticsLabel('Số dư: 0 ₫, Tháng 11 năm 2026'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Góp tiền khi tài khoản mục tiêu là tài khoản hiện đầu tiên: Từ '
      'là tài khoản khác', (tester) async {
    final db = await pumpApp(tester);
    final other = await _insertAccount(tester, db, 'Thẻ', 0);
    expect(other, 2);
    await _insertGoal(
      tester,
      db,
      name: 'Quỹ chung',
      target: 1000000,
      accountId: 1,
    );
    await goTo(tester, '/savings');
    await tester.tap(find.text('Góp tiền'));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('transfer-from')),
        matching: find.text('Thẻ'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('transfer-to')),
        matching: find.text('Tiền mặt'),
      ),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Góp tiền khi không còn tài khoản nào khác: báo, không mở màn '
      'Chuyển tiền', (tester) async {
    final db = await pumpApp(tester);
    await _insertGoal(tester, db, name: 'Quỹ', target: 1000, accountId: 1);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Góp tiền'));
    await settle(tester);
    expect(
      find.text('Cần có thêm một tài khoản khác để góp tiền'),
      findsOneWidget,
    );
    expect(find.text('Chuyển tiền'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('sửa mục tiêu: tài khoản gắn không đổi được; giữ số tiền thì '
      'giữ số chính xác (D-029)', (tester) async {
    final db = await pumpApp(tester);
    final (goalId, _) = await _seedGoal(tester, db, target: 5);
    await tester.runAsync(
      () =>
          (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId))).write(
            const SavingsGoalsCompanion(targetAmountMicro: Value(4500000)),
          ),
    );
    await goTo(tester, '/savings');
    await tester.tap(find.byTooltip('Sửa mục tiêu'));
    await settle(tester);
    expect(find.textContaining('Tài khoản gắn không đổi được'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên'),
      'Du lịch Đà Lạt',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    var g = await tester.runAsync(() => _goals(db).find(goalId));
    expect(g!.name, 'Du lịch Đà Lạt');
    expect(g.targetAmount, 5);
    expect(
      g.targetAmountMicro,
      4500000,
    ); // số tiền không đổi → giữ số chính xác
    // Đổi số tiền thì bỏ số chính xác cũ.
    await tester.tap(find.byTooltip('Sửa mục tiêu'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền mục tiêu'),
      '20000000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    g = await tester.runAsync(() => _goals(db).find(goalId));
    expect(g!.targetAmount, 20000000);
    expect(g.targetAmountMicro, isNull);
    await disposeApp(tester, db);
  });

  testWidgets('xoá mục tiêu sau hộp xác nhận: tài khoản và khoản giữ nguyên '
      '(AC-103)', (tester) async {
    final db = await pumpApp(tester);
    final (_, accountId) = await _seedGoal(tester, db);
    await insertEntry(
      tester,
      db,
      type: EntryType.income,
      amount: 1000,
      categoryId: 11,
      accountId: accountId,
    );
    await goTo(tester, '/savings');
    await tester.tap(find.byTooltip('Sửa mục tiêu'));
    await settle(tester);
    await tester.tap(find.text('Xoá mục tiêu'));
    await settle(tester);
    expect(find.text('Xoá mục tiêu?'), findsOneWidget);
    // Hủy thì vẫn còn.
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(await tester.runAsync(() => _goals(db).all()), hasLength(1));
    await tester.tap(find.text('Xoá mục tiêu'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await settle(tester);
    expect(await tester.runAsync(() => _goals(db).all()), isEmpty);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts!.any((a) => a.id == accountId), isTrue);
    final entries = await tester.runAsync(() => db.select(db.entries).get());
    expect(entries, hasLength(1));
    expect(find.text('Đã xoá mục tiêu'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
