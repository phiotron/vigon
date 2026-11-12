import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/balance_guard.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/recurring_repository.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';
import 'entry_flow_test.dart' show typeKeys;

/// SPEC 3h — màn hình của F-49 (có thu mới có chi), F-50 (tài khoản mặc định
/// theo lọc), F-51 (chip tiền tệ khi góp), F-52 (khoản nợ qua tài khoản).
/// Mỗi thao tác ghi đi trong một `runAsync` riêng (xem `f33_savings_test`).
Future<int> _account(
  WidgetTester tester,
  AppDatabase db,
  String name,
  int balance, {
  String currency = 'VND',
  bool negative = false,
}) async {
  final id = await tester.runAsync(
    () => AccountRepository(db).add(
      name: name,
      initialBalance: balance,
      currency: currency,
      allowNegative: negative,
    ),
  );
  await settle(tester);
  return id!;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<List<Entry>> _entries(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.entries).get()))!;

/// Một mục email MB đang chờ chọn danh mục cho tài khoản [accountId].
Future<int> _queuedEmail(
  WidgetTester tester,
  AppDatabase db,
  int accountId, {
  String referenceNumber = 'REF9',
  int amount = 200000,
}) async => (await tester.runAsync(
  () => db
      .into(db.importQueueItems)
      .insert(
        ImportQueueItemsCompanion.insert(
          bank: Bank.mb,
          referenceNumber: referenceNumber,
          debitLast4: '1234',
          accountId: Value(accountId),
          currency: 'VND',
          amount: amount,
          date: '2026-11-03',
          time: '12:02',
          payee: const Value('Quán A'),
        ),
      ),
))!;

void main() {
  testWidgets('AC-160 + AC-166: lọc Trip → Nhập khoản mặc định Trip; chi vượt '
      'báo "Trip chỉ còn 500.000 ₫", chi đúng 500.000 lưu được', (
    tester,
  ) async {
    final db = await pumpApp(tester, allowNegative: false);
    final trip = await _account(tester, db, 'Trip', 500000);
    _container(tester).read(accountFilterProvider.notifier).select(trip);
    await settle(tester);
    await goTo(tester, '/entry/new');
    await typeKeys(tester, '700000');
    await tester.tap(find.text('Chọn danh mục'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    expect(find.textContaining('Trip chỉ còn 500.000'), findsOneWidget);
    expect(await _entries(tester, db), isEmpty);
    // Sửa còn 500.000: lưu được, vào đúng tài khoản Trip (đang lọc).
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byIcon(Symbols.backspace_rounded));
      await tester.pump();
    }
    await typeKeys(tester, '500000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final rows = await _entries(tester, db);
    expect(rows.single.accountId, trip);
    expect(rows.single.originalAmount, 500000);
    await disposeApp(tester, db);
  });

  testWidgets('AC-161: xoá khoản thu làm tài khoản âm → hộp "Không xoá được"', (
    tester,
  ) async {
    final db = await pumpApp(tester, allowNegative: false);
    final trip = await _account(tester, db, 'Trip', 0);
    final id = await tester.runAsync(
      () => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: EntryType.income,
              amount: 500000,
              categoryId: const Value(11),
              accountId: trip,
              date: '2026-11-03',
              currency: const Value('VND'),
              originalAmount: const Value(500000),
            ),
          ),
    );
    await settle(tester);
    // Đã chi 300.000 từ khoản thu đó: xoá khoản thu thì Trip âm 300.000.
    await tester.runAsync(
      () => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: EntryType.expense,
              amount: 300000,
              categoryId: const Value(1),
              accountId: trip,
              date: '2026-11-03',
              currency: const Value('VND'),
              originalAmount: const Value(300000),
            ),
          ),
    );
    await settle(tester);
    await goTo(tester, '/entry/$id');
    await tester.tap(find.byTooltip('Xóa'));
    await settle(tester);
    await settle(tester);
    await settle(tester);
    expect(find.text('Không xoá được'), findsOneWidget);
    expect(find.textContaining('Trip sẽ âm 300.000'), findsOneWidget);
    expect(await _entries(tester, db), hasLength(2));
    await disposeApp(tester, db);
  });

  testWidgets('AC-162: công tắc "Cho phép số dư âm"; số dư ban đầu âm chỉ khi '
      'bật; màn Tài khoản có nhãn "Âm" (icon + chữ)', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    await _account(tester, db, 'Thẻ VIB', -200000, negative: true);
    await goTo(tester, '/accounts');
    expect(find.text('Âm'), findsOneWidget);
    // Thêm tài khoản mới với số dư ban đầu âm khi công tắc tắt → lỗi.
    await tester.tap(find.text('Thêm tài khoản'));
    await settle(tester);
    expect(find.text('Dùng cho thẻ tín dụng, thấu chi'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Tên'), 'Ví B');
    await tester.enterText(
      find.widgetWithText(TextField, 'Số dư ban đầu'),
      '-1000',
    );
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.textContaining('Bật "Cho phép số dư âm"'), findsOneWidget);
    await tester.tap(find.byKey(const Key('allow-negative')));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    final b = accounts!.singleWhere((a) => a.name == 'Ví B');
    expect((b.initialBalance, b.allowNegative), (-1000, true));
    await disposeApp(tester, db);
  });

  testWidgets('AC-163: sau nâng cấp hiện hộp "Đã cho phép số dư âm cho: …" một '
      'lần', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    final vib = await _account(tester, db, 'Thẻ VIB', 0);
    await tester.runAsync(
      () => db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: negativeNoticeKey, value: '$vib'),
          ),
    );
    await settle(tester);
    expect(find.text('Đã cho phép số dư âm'), findsOneWidget);
    expect(find.textContaining('Thẻ VIB'), findsWidgets);
    await tester.tap(find.text('Đã hiểu'));
    await settle(tester);
    final left = await tester.runAsync(
      () => (db.select(
        db.settings,
      )..where((s) => s.key.equals(negativeNoticeKey))).get(),
    );
    expect(left, isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('AC-164: thanh "Bỏ qua 1 khoản định kỳ vì Trip thiếu tiền", đóng '
      'được', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    final trip = await _account(tester, db, 'Trip', 0);
    _container(tester)
        .read(skippedOccurrencesProvider.notifier)
        .add([SkippedOccurrence(1, '2026-11-03', trip)]);
    await settle(tester);
    expect(
      find.text('Bỏ qua 1 khoản định kỳ vì Trip thiếu tiền'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Đóng'));
    await settle(tester);
    expect(find.textContaining('Bỏ qua 1 khoản định kỳ'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('AC-165: mục email thiếu tiền ở lại hàng đợi, mở "Bù tiền"; sửa '
      'số dư ban đầu cho đủ thì mục tự được lưu, có Hoàn tác', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    final mb = await _account(tester, db, 'MB Bank …1234', 0);
    await tester.runAsync(
      () => db
          .into(db.importQueueItems)
          .insert(
            ImportQueueItemsCompanion.insert(
              bank: Bank.mb,
              referenceNumber: 'REF9',
              debitLast4: '1234',
              accountId: Value(mb),
              currency: 'VND',
              amount: 200000,
              date: '2026-11-03',
              time: '12:02',
              payee: const Value('Quán A'),
            ),
          ),
    );
    await settle(tester);
    await goTo(tester, '/import-queue');
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    expect(find.text('Bù tiền'), findsOneWidget);
    expect(find.textContaining('MB Bank …1234 thiếu 200.000'), findsOneWidget);
    expect(
      find.textContaining('Ghi khoản thu vào MB Bank …1234'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Chuyển tiền vào MB Bank …1234'),
      findsOneWidget,
    );
    expect(await _entries(tester, db), isEmpty);
    // Cách 3: sửa số dư ban đầu thành 300.000 → đủ → tự lưu.
    await tester.tap(find.text('Sửa số dư ban đầu'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Số dư ban đầu').last,
      '300000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu').last);
    await settle(tester);
    final rows = await _entries(tester, db);
    expect(rows.single.referenceNumber, 'REF9');
    expect(find.text('Đã bù đủ · đã lưu mục'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    expect(await _entries(tester, db), isEmpty);
    final queue = await tester.runAsync(
      () => db.select(db.importQueueItems).get(),
    );
    expect(queue, hasLength(1));
    await disposeApp(tester, db);
  });

  testWidgets('AC-165: cách 1 · ghi khoản thu vào tài khoản thiếu tiền rồi quay '
      'lại thì mục tự được lưu, có Hoàn tác', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    final mb = await _account(tester, db, 'MB Bank …1234', 0);
    await _queuedEmail(tester, db, mb);
    await settle(tester);
    await goTo(tester, '/import-queue');
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    // Cách 1: mở màn Nhập khoản đã chọn sẵn tài khoản + số tiền bằng số thiếu.
    await tester.tap(find.textContaining('Ghi khoản thu vào MB Bank …1234'));
    await settle(tester);
    expect(find.text('Khoản thu mới'), findsOneWidget);
    expect(findPlainText('200.000 ₫'), findsOneWidget);
    expect(find.text('MB Bank …1234'), findsOneWidget);
    await tester.tap(find.text('Chọn danh mục'));
    await settle(tester);
    await tester.tap(find.text('Lương'));
    await settle(tester);
    // Quay lại hàng đợi: kiểm lại thấy đủ tiền nên tự lưu mục kèm Hoàn tác.
    expect(find.text('Đã bù đủ · đã lưu mục'), findsOneWidget);
    final rows = await _entries(tester, db);
    expect(rows, hasLength(2));
    final income = rows.singleWhere((e) => e.type == EntryType.income);
    expect((income.amount, income.accountId), (200000, mb));
    final expense = rows.singleWhere((e) => e.type == EntryType.expense);
    expect(expense.referenceNumber, 'REF9');
    expect(
      await tester.runAsync(() => db.select(db.importQueueItems).get()),
      isEmpty,
    );
    // Hoàn tác chỉ bỏ khoản chi vừa lưu; khoản thu bù vẫn còn.
    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    expect((await _entries(tester, db)).single.type, EntryType.income);
    expect(
      await tester.runAsync(() => db.select(db.importQueueItems).get()),
      hasLength(1),
    );
    await disposeApp(tester, db);
  });

  testWidgets('AC-165: cách 2 · chuyển tiền vào tài khoản thiếu tiền rồi quay '
      'lại thì mục tự được lưu', (tester) async {
    final db = await pumpApp(tester, allowNegative: false);
    final mb = await _account(tester, db, 'MB Bank …1234', 0);
    await tester.runAsync(
      () => (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
        const AccountsCompanion(initialBalance: Value(500000)),
      ),
    );
    await _queuedEmail(tester, db, mb);
    await settle(tester);
    await goTo(tester, '/import-queue');
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    // Cách 2: màn Chuyển tiền với ô Đến đã chọn sẵn tài khoản thiếu tiền.
    await tester.tap(find.textContaining('Chuyển tiền vào MB Bank …1234'));
    await settle(tester);
    await typeKeys(tester, '200000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Đã bù đủ · đã lưu mục'), findsOneWidget);
    final rows = await _entries(tester, db);
    expect(rows, hasLength(2));
    final transfer = rows.singleWhere((e) => e.type == EntryType.transfer);
    expect((transfer.accountId, transfer.toAccountId), (1, mb));
    final expense = rows.singleWhere((e) => e.type == EntryType.expense);
    expect(expense.referenceNumber, 'REF9');
    expect(
      await tester.runAsync(() => db.select(db.importQueueItems).get()),
      isEmpty,
    );
    await disposeApp(tester, db);
  });

  testWidgets('AC-167: Tiền tệ chính VND, ví USD: góp 500.000 ₫ từ Tiền mặt ₫ '
      'lưu được, hiện hai dòng "Vào ví" · "Trừ từ"', (tester) async {
    final db = await pumpApp(tester);
    final wallet = await _account(
      tester,
      db,
      'Du lịch Đà Lạt',
      0,
      currency: 'USD',
    );
    await tester.runAsync(
      () => db
          .into(db.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              name: 'Du lịch Đà Lạt',
              targetAmount: 100000,
              accountId: wallet,
              currency: const Value('USD'),
              originalTargetAmount: const Value(100000),
            ),
          ),
    );
    await settle(tester);
    await goTo(tester, '/savings');
    await tester.tap(find.widgetWithText(FilledButton, 'Góp tiền'));
    await settle(tester);
    final inSheet = find.byType(BottomSheet);
    await tester.enterText(
      find.descendant(
        of: inSheet,
        matching: find.widgetWithText(TextField, 'Số tiền'),
      ),
      '500000',
    );
    await settle(tester);
    expect(find.textContaining('Vào ví:'), findsOneWidget);
    expect(find.textContaining('Trừ từ Tiền mặt:'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: inSheet,
        matching: find.widgetWithText(FilledButton, 'Góp tiền'),
      ),
    );
    await settle(tester);
    final t = (await _entries(tester, db)).single;
    expect(
      (t.type, t.accountId, t.toAccountId, t.currency, t.originalAmount),
      (EntryType.transfer, 1, wallet, 'VND', 500000),
    );
    expect(t.toCurrency, 'USD');
    expect(t.toOriginalAmount, inInclusiveRange(1000, 3000)); // ≈ 19,23 $
    await disposeApp(tester, db);
  });

  testWidgets('AC-169, AC-170, AC-174: cho vay 5 triệu từ TCB qua tài khoản; '
      'dòng Debt movement trong Các khoản; lần trả tách lãi/gốc', (
    tester,
  ) async {
    final db = await pumpApp(tester, allowNegative: false);
    await _account(tester, db, 'TCB', 6000000);
    _container(tester)
        .read(accountFilterProvider.notifier)
        .select(2); // TCB (id 2)
    await settle(tester);
    await goTo(tester, '/debts');
    await tester.tap(find.text('Thêm khoản nợ'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Người'), 'An');
    await tester.enterText(find.byKey(const Key('debt-amount')), '5000000');
    // Tài khoản mặc định theo bộ lọc (AC-166 áp cho khoản nợ).
    expect(
      find.descendant(
        of: find.byKey(const Key('debt-account')),
        matching: find.text('TCB'),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('debt-rate')), '12');
    await settle(tester);
    expect(find.textContaining('Lãi 30 ngày đầu khoảng'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final rows = await _entries(tester, db);
    final loan = rows.single;
    expect(
      (loan.type, loan.debtKind, loan.accountId),
      (EntryType.debt, DebtMovementKind.lend, 2),
    );
    expect(loan.originalAmount, 5000000);
    // Dòng trong Các khoản: nhãn "Cho vay · An", không tính thu/chi.
    await goTo(tester, '/entries');
    expect(find.text('Cho vay · An'), findsOneWidget);
    // Chi tiết: lãi suất, "Gốc … · Lãi tới hôm nay …".
    await goTo(tester, '/debts');
    await tester.tap(find.text('An'));
    await settle(tester);
    expect(find.byKey(const Key('debt-rate-chip')), findsOneWidget);
    expect(find.byKey(const Key('debt-principal-interest')), findsOneWidget);
    expect(find.byKey(const Key('debt-change-rate')), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('AC-175: xoá khoản nợ giữ khoản; nhãn "Khoản nợ đã xoá"', (
    tester,
  ) async {
    final db = await pumpApp(tester, allowNegative: false);
    await _account(tester, db, 'TCB', 6000000);
    final id = await tester.runAsync(() async {
      final debt = await db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              person: 'An',
              direction: DebtDirection.lent,
              amount: 5000000,
              date: '2026-11-01',
              currency: const Value('VND'),
              originalAmount: const Value(5000000),
              accountId: const Value(2),
            ),
          );
      await db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: EntryType.debt,
              amount: 5000000,
              accountId: 2,
              date: '2026-11-01',
              currency: const Value('VND'),
              originalAmount: const Value(5000000),
              debtKind: const Value(DebtMovementKind.lend),
              debtId: Value(debt),
            ),
          );
      return debt;
    });
    await settle(tester);
    expect(id, isNotNull);
    await goTo(tester, '/debts');
    await tester.tap(find.text('An'));
    await settle(tester);
    await tester.tap(find.text('Xoá khoản nợ'));
    await settle(tester);
    expect(find.text('Xoá khoản nợ với An?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await settle(tester);
    expect(await _entries(tester, db), hasLength(1));
    await goTo(tester, '/entries');
    expect(find.text('Khoản nợ đã xoá'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
