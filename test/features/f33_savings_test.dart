import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/savings_repository.dart';
import 'package:vigon/src/features/savings/savings_screen.dart';

import '../helpers.dart';

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

  Finder inSheet(Finder f) =>
      find.descendant(of: find.byType(BottomSheet), matching: f);

  testWidgets('tạo mục tiêu luôn tạo ví mới; "Đã có sẵn" là số dư ban đầu '
      '(AC-149)', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Thêm mục tiêu'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên mục tiêu'),
      'Mua xe',
    );
    await settle(tester);
    // Ô "Tài khoản" tự theo tên mục tiêu.
    expect(find.widgetWithText(TextField, 'Mua xe'), findsNWidgets(2));
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền mục tiêu'),
      '10000000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Đã có sẵn (tuỳ chọn)'),
      '2000000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);

    final goals = await tester.runAsync(() => _goals(db).all());
    final g = goals!.single;
    expect(
      (g.name, g.originalTargetAmount, g.currency),
      ('Mua xe', 10000000, 'VND'),
    );
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts, hasLength(2));
    final wallet = accounts!.firstWhere((a) => a.id == g.accountId);
    expect(
      (wallet.name, wallet.currency, wallet.initialBalanceOriginal),
      ('Mua xe', 'VND', 2000000),
    );
    expect(findPlainText('Đã có 2.000.000 ₫ / 10.000.000 ₫'), findsOneWidget);
    expect(findPlainText('Còn thiếu 8.000.000 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('đặt tên ví riêng khác tên mục tiêu (AC-149)', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Thêm mục tiêu'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên mục tiêu'),
      'Du lịch',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tài khoản'),
      'Quỹ du lịch',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền mục tiêu'),
      '5000000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final g = (await tester.runAsync(() => _goals(db).all()))!.single;
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(
      accounts!.firstWhere((a) => a.id == g.accountId).name,
      'Quỹ du lịch',
    );
    expect(g.name, 'Du lịch');
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
      final name = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Tên mục tiêu'),
      );
      expect(name.maxLength, 50);
      expect(await tester.runAsync(() => _goals(db).all()), isEmpty);
      await disposeApp(tester, db);
    },
  );

  testWidgets('tiến độ: 3.000.000 / 10.000.000 → 30%, còn thiếu 7.000.000 '
      '(AC-150)', (tester) async {
    final db = await pumpApp(tester);
    await _seedGoal(tester, db);
    await goTo(tester, '/savings');
    expect(findPlainText('Đã có 3.000.000 ₫ / 10.000.000 ₫'), findsOneWidget);
    expect(findPlainText('Còn thiếu 7.000.000 ₫'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('đủ tiền: hộp "Tiết kiệm thành công", chuyển xuống "Đã xong"; '
      'chi bớt sau đó vẫn Đã xong (AC-153)', (tester) async {
    final db = await pumpApp(tester);
    final (goalId, accountId) = await _seedGoal(
      tester,
      db,
      target: 5000000,
      balance: 5000000,
    );
    await goTo(tester, '/savings');
    expect(find.text('Tiết kiệm thành công'), findsOneWidget);
    expect(findPlainText('Bạn đã đủ 5.000.000 ₫ cho Du lịch.'), findsOneWidget);
    await tester.tap(find.text('Tuyệt'));
    await settle(tester);
    final g = await tester.runAsync(() => _goals(db).find(goalId));
    expect(g!.completedAt, '2026-11-03');
    expect(find.text('Đã xong (1)'), findsOneWidget);
    expect(find.text('Đang tiết kiệm'), findsNothing);
    // Chi bớt từ ví: vẫn Đã xong, không chúc mừng lại.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1000000,
      categoryId: 1,
      accountId: accountId,
    );
    expect(find.text('Đã xong (1)'), findsOneWidget);
    expect(find.text('Tiết kiệm thành công'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('hạn: "Còn N ngày", "Quá hạn N ngày" (AC-150)', (tester) async {
    final db = await pumpApp(tester); // hôm nay 2026-11-03
    await _seedGoal(tester, db, name: 'Sắp tới', due: '2026-11-10');
    await _seedGoal(tester, db, name: 'Trễ', due: '2026-11-01');
    await goTo(tester, '/savings');
    expect(find.text('Còn 7 ngày'), findsOneWidget);
    expect(find.text('Quá hạn 2 ngày'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Góp tiền: không vượt số còn thiếu, "Điền đủ" điền đúng, lưu là '
      'chuyển tiền từ Tiền mặt (AC-152)', (tester) async {
    final db = await pumpApp(tester);
    final (_, accountId) = await _seedGoal(tester, db);
    await goTo(tester, '/savings');
    await tester.tap(find.widgetWithText(FilledButton, 'Góp tiền'));
    await settle(tester);
    expect(inSheet(find.text('Tiền mặt')), findsOneWidget);
    await tester.enterText(
      inSheet(find.widgetWithText(TextField, 'Số tiền')),
      '8000000',
    );
    await tester.tap(inSheet(find.widgetWithText(FilledButton, 'Góp tiền')));
    await settle(tester);
    expect(findPlainText('Chỉ cần góp thêm 7.000.000 ₫'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
    await tester.tap(inSheet(find.textContaining('Điền đủ')));
    await settle(tester);
    await tester.tap(inSheet(find.widgetWithText(FilledButton, 'Góp tiền')));
    await settle(tester);

    final rows = await tester.runAsync(() => db.select(db.entries).get());
    final t = rows!.single;
    expect(
      (t.type, t.accountId, t.toAccountId, t.originalAmount),
      (EntryType.transfer, 1, accountId, 7000000),
    );
    // Đủ mục tiêu → chúc mừng.
    expect(find.text('Tiết kiệm thành công'), findsOneWidget);
    await tester.tap(find.text('Tuyệt'));
    await settle(tester);
    // Thu, chi của kỳ không đổi.
    await goTo(tester, '/');
    expect(
      findSemanticsLabel('Số dư: 0 ₫, Tháng 11 năm 2026 · theo VND'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Chi tiết: Rút tiền không vượt số dư; Lịch sử hiện lần rút '
      '(AC-151, AC-152)', (tester) async {
    final db = await pumpApp(tester);
    final (_, accountId) = await _seedGoal(tester, db);
    await goTo(tester, '/savings');
    await tester.tap(find.text('Du lịch').first);
    await settle(tester);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Đã có sẵn'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Rút tiền'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền').last,
      '4000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rút tiền').last);
    await settle(tester);
    expect(findPlainText('Tài khoản chỉ còn 3.000.000 ₫'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số tiền').last,
      '1000000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rút tiền').last);
    await settle(tester);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    final t = rows!.single;
    expect(
      (t.accountId, t.toAccountId, t.originalAmount),
      (accountId, 1, 1000000),
    );
    expect(find.text('Rút về Tiền mặt'), findsOneWidget);
    expect(
      findPlainText('Đã có 2.000.000 ₫ / 10.000.000 ₫ · 20%'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Góp tiền khi không còn tài khoản nào khác: báo trong bảng', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _insertGoal(tester, db, name: 'Quỹ', target: 1000, accountId: 1);
    await goTo(tester, '/savings');
    await tester.tap(find.widgetWithText(FilledButton, 'Góp tiền'));
    await settle(tester);
    expect(
      find.text('Cần có thêm một tài khoản khác để góp tiền'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('sửa mục tiêu: đổi tên mục tiêu và tên ví; giữ số tiền thì giữ '
      'số chính xác (D-029)', (tester) async {
    final db = await pumpApp(tester);
    final (goalId, accountId) = await _seedGoal(tester, db);
    await tester.runAsync(
      () =>
          (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId))).write(
            const SavingsGoalsCompanion(targetAmountMicro: Value(4500000)),
          ),
    );
    await goTo(tester, '/savings');
    await tester.tap(find.text('Du lịch').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sửa mục tiêu'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên mục tiêu'),
      'Du lịch Đà Lạt',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tài khoản'),
      'Quỹ ĐL',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final g = await tester.runAsync(() => _goals(db).find(goalId));
    expect(g!.name, 'Du lịch Đà Lạt');
    expect(g.targetAmountMicro, 4500000);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    expect(accounts!.firstWhere((a) => a.id == accountId).name, 'Quỹ ĐL');
    await disposeApp(tester, db);
  });

  testWidgets(
    'xoá mục tiêu sau hộp xác nhận: ví và khoản giữ nguyên, ở lại màn '
    'Tiết kiệm (AC-154)',
    (tester) async {
      final db = await pumpApp(tester);
      final (_, accountId) = await _seedGoal(tester, db);
      await insertEntry(
        tester,
        db,
        type: EntryType.income,
        amount: 1000,
        categoryId: 12,
        accountId: accountId,
      );
      await goTo(tester, '/savings');
      await tester.tap(find.text('Du lịch').first);
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Sửa mục tiêu'));
      await settle(tester);
      await tester.tap(find.text('Xoá mục tiêu'));
      await settle(tester);
      expect(find.text('Xoá mục tiêu?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await settle(tester);
      expect(await tester.runAsync(() => _goals(db).all()), isEmpty);
      final accounts = await tester.runAsync(
        () => db.select(db.accounts).get(),
      );
      expect(accounts!.any((a) => a.id == accountId), isTrue);
      final entries = await tester.runAsync(() => db.select(db.entries).get());
      expect(entries, hasLength(1));
      expect(find.text('Đã xoá mục tiêu'), findsOneWidget);
      expect(find.textContaining('Chưa có mục tiêu tiết kiệm'), findsOneWidget);
      await disposeApp(tester, db);
    },
  );
}
