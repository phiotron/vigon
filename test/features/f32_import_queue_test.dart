import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/summary.dart';
import 'package:vigon/src/data/import_repositories.dart';
import 'package:vigon/src/import/mb/mb_import_service.dart';
import 'package:vigon/src/import/mb/mb_receipt_parser.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';
import 'entry_flow_test.dart' show typeKeys;

// Lưu ý chung: mỗi lần ghi vào bảng mà cây widget đang theo dõi (tài khoản, khoản…)
// đi trong một `tester.runAsync` RIÊNG rồi `settle` — hai lần ghi liền nhau trong
// cùng một `runAsync` làm test treo (xem f33_savings_test.dart). Dữ liệu dựng
// TRƯỚC `pumpApp` thì không bị.

const _payee = 'CONG TY ABC';

/// Ghi thẳng một mục hàng đợi.
Future<int> _item(
  WidgetTester tester,
  AppDatabase db, {
  String ref = 'REF0001',
  int? accountId = 1,
  String last4 = '4821',
  String currency = 'VND',
  int amount = 50000,
  int? micro,
  String date = '2026-11-03',
  String time = '12:02',
  String? payee = _payee,
  String? content = 'Tien an',
}) async {
  final id = await tester.runAsync(
    () => db
        .into(db.importQueueItems)
        .insert(
          ImportQueueItemsCompanion.insert(
            bank: Bank.mb,
            referenceNumber: ref,
            debitLast4: last4,
            accountId: Value(accountId),
            currency: currency,
            amount: amount,
            amountMicro: Value(micro),
            date: date,
            time: time,
            payee: Value(payee),
            transferContent: Value(content),
          ),
        ),
  );
  await settle(tester);
  return id!;
}

Future<int> _account(WidgetTester tester, AppDatabase db, String name) async {
  final id = await tester.runAsync(
    () => AccountRepository(db).add(name: name, initialBalance: 0),
  );
  await settle(tester);
  return id!;
}

Future<List<Entry>> _entries(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.entries).get()))!;

Future<List<ImportQueueItem>> _queue(
  WidgetTester tester,
  AppDatabase db,
) async => (await tester.runAsync(() => ImportQueueRepository(db).all()))!;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  testWidgets('hàng đợi trống: hiện hướng dẫn', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/import-queue');
    expect(find.text('Hàng đợi'), findsOneWidget);
    expect(find.textContaining('Không có khoản nào đang chờ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('mục hiện người thụ hưởng, số tiền, ngày giờ, tài khoản trích '
      'nợ (AC-95)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db);
    await goTo(tester, '/import-queue');
    expect(find.text(_payee), findsOneWidget);
    expect(find.text('Tien an'), findsOneWidget);
    expect(findPlainText('50.000 ₫'), findsOneWidget);
    expect(find.textContaining('12:02'), findsOneWidget);
    expect(find.textContaining('Từ Tiền mặt'), findsOneWidget);
    // Lưới danh mục chi: đủ 10 danh mục chi mặc định.
    for (final name in ['Ăn uống', 'Đi lại', 'Nhà cửa', 'Khác']) {
      expect(find.text(name), findsOneWidget);
    }
    await disposeApp(tester, db);
  });

  testWidgets('mục hàng đợi chưa là khoản: không vào Các khoản, tổng thu chi, '
      'số dư, ngân sách (AC-95)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db, amount: 700000);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    // Màn chính và Các khoản không có gì.
    expect(findSemanticsLabel('Số dư: 0 ₫, Tháng 11 năm 2026'), findsOneWidget);
    await goTo(tester, '/entries');
    expect(find.text('Kỳ này chưa có khoản nào'), findsOneWidget);
    // Tổng của kỳ, số chi cho ngân sách, số dư tài khoản đều không đổi.
    final summary = container.read(periodSummaryProvider);
    expect(summary.expense, 0);
    expect(summary.income, 0);
    expect(summary.balance, 0);
    await settle(tester);
    // Không dùng `container.read(provider.future)` trong runAsync (treo); đọc
    // thẳng kho dữ liệu: cùng truy vấn mà các provider ở trên dùng.
    final spent = await tester.runAsync(() async {
      final rows = await EntryRepository(db)
          .watchEntries(Period.containing(PeriodType.month, testToday))
          .first;
      return PeriodSummary.of(rows).expense;
    });
    expect(spent, 0);
    final balances = await tester.runAsync(
      () => AccountRepository(db).watchBalances().first,
    );
    expect(balances![1], 0);
    expect(await _entries(tester, db), isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('chạm một danh mục (chưa có gợi ý) là lưu: khoản chi có ngày '
      'giờ email, tài khoản, ghi chú, nguồn, số tham chiếu; mục rời hàng đợi, '
      'nhớ số tham chiếu và gợi ý (AC-96, AC-86, AC-97)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db, content: 'Tien an');
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Ăn uống'));

    final e = (await _entries(tester, db)).single;
    expect(e.type, EntryType.expense);
    expect(e.amount, 50000);
    expect(e.categoryId, 1);
    expect(e.accountId, 1);
    expect(e.date, '2026-11-03');
    expect(e.time, '12:02');
    expect(e.note, '$_payee · Tien an');
    expect(e.source, EntrySource.emailMb);
    expect(e.referenceNumber, 'REF0001');
    expect(await _queue(tester, db), isEmpty);
    final seen = await tester.runAsync(
      () => db.select(db.seenReferences).get(),
    );
    expect(seen!.single.referenceNumber, 'REF0001');
    expect(seen.single.outcome, ReferenceOutcome.confirmed);
    final sugg = await tester.runAsync(
      () => PayeeSuggestionRepository(db).forPayee('Cong ty abc'),
    );
    expect(sugg!.categoryId, 1);
    expect(find.text('Đã lưu vào Ăn uống'), findsOneWidget);
    // Từ lúc này khoản tính vào mọi tổng.
    await goTo(tester, '/');
    expect(
      findSemanticsLabel('Số dư: -50.000 ₫, Tháng 11 năm 2026'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('có gợi ý: danh mục chọn sẵn kèm nhãn "Gợi ý", nút "Lưu vào …"; '
      'chưa chạm thì chưa lưu; chạm nút là lưu (AC-96, AC-97)', (tester) async {
    final db = await pumpApp(tester);
    await tester.runAsync(
      // Tên khác hoa/thường/dấu vẫn trùng khoá.
      () => PayeeSuggestionRepository(db).rememberCategory('Công ty ABC', 1),
    );
    await _item(tester, db);
    await goTo(tester, '/import-queue');
    expect(find.text('Gợi ý'), findsOneWidget);
    expect(find.text('Lưu vào Ăn uống'), findsOneWidget);
    expect(await _entries(tester, db), isEmpty);
    expect(await _queue(tester, db), hasLength(1));
    await _tap(tester, find.text('Lưu vào Ăn uống'));
    expect((await _entries(tester, db)).single.categoryId, 1);
    expect(await _queue(tester, db), isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('có gợi ý mà chạm danh mục khác thì lưu vào danh mục đó và gợi ý '
      'đổi theo (AC-96, AC-97)', (tester) async {
    final db = await pumpApp(tester);
    await tester.runAsync(
      () => PayeeSuggestionRepository(db).rememberCategory(_payee, 1),
    );
    await _item(tester, db);
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Đi lại'));
    expect((await _entries(tester, db)).single.categoryId, 2);
    final sugg = await tester.runAsync(
      () => PayeeSuggestionRepository(db).forPayee(_payee),
    );
    expect(sugg!.categoryId, 2);
    await disposeApp(tester, db);
  });

  testWidgets('"Chuyển sang tài khoản của tôi": một Transfer, không vào thu '
      'chi; Account đích khác Account trích nợ, gồm Account của mục tiêu '
      'tiết kiệm; nhớ gợi ý (AC-98)', (tester) async {
    final db = await pumpApp(tester);
    final momo = await _account(tester, db, 'MoMo');
    final fund = await _account(tester, db, 'Quỹ xe');
    await tester.runAsync(
      () => db
          .into(db.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              name: 'Quỹ xe',
              targetAmount: 1000000,
              accountId: fund,
            ),
          ),
    );
    await _item(tester, db, amount: 2000000, payee: 'NGUYEN VAN A');
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Chuyển sang tài khoản của tôi'));
    // Account trích nợ (Tiền mặt) không có trong bảng chọn; Account mục tiêu có.
    expect(find.text('MoMo'), findsOneWidget);
    expect(find.text('Quỹ xe'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Tiền mặt'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('MoMo'));
    await settle(tester);

    final e = (await _entries(tester, db)).single;
    expect(e.type, EntryType.transfer);
    expect(e.accountId, 1);
    expect(e.toAccountId, momo);
    expect(e.amount, 2000000);
    expect(e.date, '2026-11-03');
    expect(e.time, '12:02');
    expect(e.source, EntrySource.emailMb);
    expect(e.referenceNumber, 'REF0001');
    expect(e.categoryId, isNull);
    expect(await _queue(tester, db), isEmpty);
    // Không vào thu/chi của kỳ.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    await goTo(tester, '/');
    expect(container.read(periodSummaryProvider).expense, 0);
    expect(container.read(periodSummaryProvider).income, 0);
    final sugg = await tester.runAsync(
      () => PayeeSuggestionRepository(db).forPayee('nguyen van a'),
    );
    expect(sugg!.toAccountId, momo);
    expect(sugg.categoryId, isNull);

    // Email sau của cùng người: gợi ý "Chuyển sang MoMo".
    await _item(tester, db, ref: 'REF0002', payee: 'Nguyen Van A');
    await goTo(tester, '/import-queue');
    expect(find.text('Chuyển sang MoMo'), findsOneWidget);
    expect(find.text('Gợi ý'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('"Bỏ qua" sau hộp xác nhận: mục rời hàng đợi, số tham chiếu được '
      'nhớ nên không nhập lại (AC-99, AC-86)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db);
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Bỏ qua'));
    expect(find.text('Bỏ qua khoản này?'), findsOneWidget);
    // Hủy thì giữ nguyên.
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(await _queue(tester, db), hasLength(1));
    await _tap(tester, find.text('Bỏ qua'));
    await tester.tap(find.widgetWithText(FilledButton, 'Bỏ qua'));
    await settle(tester);
    expect(await _queue(tester, db), isEmpty);
    expect(await _entries(tester, db), isEmpty);
    final seen = await tester.runAsync(
      () => db.select(db.seenReferences).get(),
    );
    expect(seen!.single.outcome, ReferenceOutcome.skipped);
    final known = await tester.runAsync(
      () => SeenReferenceRepository(db).isKnown(Bank.mb, 'REF0001'),
    );
    expect(known, isTrue);
    expect(find.textContaining('Không có khoản nào đang chờ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('"Sửa trước khi lưu": màn Nhập khoản điền sẵn số tiền, ghi chú, '
      'ngày giờ, tài khoản; lưu thì khoản có nguồn + số tham chiếu và giữ '
      'số chính xác nếu không đổi số tiền (AC-96, D-029)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db, micro: 50000000000);
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Sửa trước khi lưu'));
    expect(find.text('Khoản chi mới'), findsOneWidget);
    expect(findPlainText('50.000 ₫'), findsWidgets);
    expect(find.text('12:02'), findsOneWidget);
    expect(find.text('$_payee · Tien an'), findsOneWidget); // ô ghi chú
    // Chưa chọn danh mục: nút lớn là "Chọn danh mục".
    await tester.tap(find.text('Chọn danh mục'));
    await settle(tester);
    await tester.tap(find.text('Nhà cửa').last);
    await settle(tester);

    final e = (await _entries(tester, db)).single;
    expect(e.categoryId, 3);
    expect(e.amount, 50000);
    expect(e.amountMicro, 50000000000);
    expect(e.time, '12:02');
    expect(e.date, '2026-11-03');
    expect(e.source, EntrySource.emailMb);
    expect(e.referenceNumber, 'REF0001');
    expect(await _queue(tester, db), isEmpty);
    final seen = await tester.runAsync(
      () => db.select(db.seenReferences).get(),
    );
    expect(seen!.single.outcome, ReferenceOutcome.confirmed);
    await disposeApp(tester, db);
  });

  testWidgets('sửa số tiền trước khi lưu: lưu số mới, bỏ số chính xác cũ '
      '(D-029)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db, micro: 50000000000);
    await goTo(tester, '/import-queue');
    await _tap(tester, find.text('Sửa trước khi lưu'));
    await tester.tap(find.bySemanticsLabel('Xóa lùi'));
    await tester.pump();
    await typeKeys(tester, '7');
    await tester.tap(find.text('Chọn danh mục'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống').last);
    await settle(tester);
    final e = (await _entries(tester, db)).single;
    expect(e.amount, 50007); // 50000, xoá lùi → 5000, gõ 7
    expect(e.amountMicro, isNull);
    expect(e.referenceNumber, 'REF0001');
    await disposeApp(tester, db);
  });

  testWidgets('email bằng tiền tệ khác app: hiện ghi chú, không có "Chuyển '
      'sang tài khoản của tôi"; chọn danh mục mở Nhập khoản với ô số tiền '
      'trống (AC-87)', (tester) async {
    final db = await pumpApp(tester);
    await tester.runAsync(
      () => db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: 'currency', value: 'USD'),
          ),
    );
    await settle(tester);
    await _item(tester, db, currency: 'VND', amount: 50000);
    await goTo(tester, '/import-queue');
    expect(
      find.textContaining('Email bằng VND, app đang dùng USD'),
      findsOneWidget,
    );
    expect(find.text('Chuyển sang tài khoản của tôi'), findsNothing);
    await _tap(tester, find.text('Ăn uống'));
    // Màn Nhập khoản, danh mục chọn sẵn, số tiền trống.
    expect(find.text('Khoản chi mới'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    expect(await _entries(tester, db), isEmpty);
    await typeKeys(tester, '25');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    final e = (await _entries(tester, db)).single;
    expect(
      e.amount,
      2500,
    ); // 25 USD = 2500 cent: số người dùng nhập, không quy đổi
    expect(e.categoryId, 1);
    expect(e.referenceNumber, 'REF0001');
    expect(await _queue(tester, db), isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('mục chưa có Account (bị xoá/sau khôi phục): lưu thì tạo lại '
      '"MB Bank …4821" liên kết (AC-90)', (tester) async {
    final db = await pumpApp(tester);
    await _item(tester, db, accountId: null);
    await goTo(tester, '/import-queue');
    expect(find.textContaining('Từ MB Bank …4821'), findsOneWidget);
    await _tap(tester, find.text('Ăn uống'));
    final accounts = await tester.runAsync(() => db.select(db.accounts).get());
    final mb = accounts!.singleWhere((a) => a.bankLast4 == '4821');
    expect(mb.name, 'MB Bank …4821');
    expect(mb.bank, Bank.mb);
    expect((await _entries(tester, db)).single.accountId, mb.id);
    await disposeApp(tester, db);
  });

  testWidgets('hai mục cùng lúc: lưu một mục không đụng mục kia', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _item(tester, db, ref: 'REF0001', payee: 'A');
    await _item(tester, db, ref: 'REF0002', payee: 'B', time: '13:10');
    await goTo(tester, '/import-queue');
    // Mới nhất trước: B (13:10) ở trên A.
    expect(
      tester.getTopLeft(find.text('B')).dy,
      lessThan(tester.getTopLeft(find.text('A')).dy),
    );
    await tester.tap(find.text('Ăn uống').first);
    await settle(tester);
    final left = await _queue(tester, db);
    expect(left.single.referenceNumber, 'REF0001');
    expect((await _entries(tester, db)).single.referenceNumber, 'REF0002');
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt có mục Tiết kiệm, Khoản nợ, Hàng đợi (có số mục chờ) '
      'mở đúng màn', (tester) async {
    final db = await pumpApp(tester);
    await goTo(tester, '/settings');
    await tester.scrollUntilVisible(find.text('Hàng đợi'), 200);
    expect(find.text('Tiết kiệm'), findsOneWidget);
    expect(find.text('Khoản nợ'), findsOneWidget);
    expect(find.text('Không có khoản nào đang chờ'), findsOneWidget);
    await _item(tester, db);
    await _item(tester, db, ref: 'REF0002');
    expect(find.text('2 khoản chờ chọn danh mục'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hàng đợi'), 200);
    await tester.tap(find.text('Hàng đợi'));
    await settle(tester);
    expect(find.text(_payee), findsWidgets);
    await goTo(tester, '/settings');
    await tester.scrollUntilVisible(find.text('Tiết kiệm'), 200);
    await tester.ensureVisible(find.text('Tiết kiệm'));
    await settle(tester);
    await tester.tap(find.text('Tiết kiệm'));
    await settle(tester);
    expect(find.text('Thêm mục tiêu'), findsOneWidget);
    await goTo(tester, '/settings');
    await tester.scrollUntilVisible(find.text('Khoản nợ'), 200);
    await tester.ensureVisible(find.text('Khoản nợ'));
    await settle(tester);
    await tester.tap(find.text('Khoản nợ'));
    await settle(tester);
    expect(find.text('Thêm khoản nợ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  group('Gợi ý đã nhớ (AC-97)', () {
    testWidgets('liệt kê và xoá từng gợi ý', (tester) async {
      final db = await pumpApp(tester);
      final momo = await _account(tester, db, 'MoMo');
      final repo = PayeeSuggestionRepository(db);
      await tester.runAsync(() => repo.rememberCategory('Công ty ABC', 1));
      await tester.runAsync(() => repo.rememberTransfer('Nguyen Van A', momo));
      await goTo(tester, '/import-queue/suggestions');
      expect(find.text('Công ty ABC'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('Chuyển sang MoMo'), findsOneWidget);
      await tester.tap(find.byTooltip('Xoá gợi ý').first);
      await settle(tester);
      final left = await tester.runAsync(() => repo.watchAll().first);
      expect(left, hasLength(1));
      expect(find.text('Đã xoá gợi ý'), findsOneWidget);
      await tester.tap(find.byTooltip('Xoá gợi ý'));
      await settle(tester);
      expect(find.textContaining('Chưa có gợi ý nào'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('mở được từ màn Hàng đợi', (tester) async {
      final db = await pumpApp(tester);
      await goTo(tester, '/import-queue');
      await tester.tap(find.byTooltip('Gợi ý đã nhớ'));
      await settle(tester);
      expect(find.textContaining('Chưa có gợi ý nào'), findsOneWidget);
      await disposeApp(tester, db);
    });
  });

  group('nối với bộ nhập email MB của M1', () {
    MbReceipt receipt({String ref = 'RX1'}) => MbReceipt(
      dateKey: '2026-11-03',
      time: '12:02',
      reference: ref,
      debitLast4: '4821',
      currency: 'VND',
      amount: 50000,
      payee: _payee,
      transferContent: 'tien an',
    );

    /// Cơ sở dữ liệu đã nhập một email (tạo Account "MB Bank …4821" + mục),
    /// dựng TRƯỚC khi mở app.
    Future<AppDatabase> importedDb(WidgetTester tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() async {
        await AccountRepository(db).watchAll().first; // seedDefaults
        await MbImportService(db).importReceipt(receipt());
      });
      return db;
    }

    testWidgets('thẻ "Đã tạo tài khoản MB Bank …4821" → "Gắn vào tài khoản có '
        'sẵn" chuyển liên kết và mục sang Account đã chọn (AC-89)', (
      tester,
    ) async {
      final db = await importedDb(tester);
      await pumpApp(tester, db: db);
      await goTo(tester, '/import-queue');
      expect(find.text('Đã tạo tài khoản MB Bank …4821'), findsOneWidget);
      expect(find.textContaining('Từ MB Bank …4821'), findsOneWidget);
      await _tap(tester, find.text('Gắn vào tài khoản có sẵn'));
      await tester.tap(find.text('Tiền mặt'));
      await settle(tester);
      expect(find.text('Đã tạo tài khoản MB Bank …4821'), findsNothing);
      final accounts = await tester.runAsync(
        () => db.select(db.accounts).get(),
      );
      expect(accounts!.any((a) => a.name == 'MB Bank …4821'), isFalse);
      expect(accounts.singleWhere((a) => a.id == 1).bankLast4, '4821');
      final item = (await _queue(tester, db)).single;
      expect(item.accountId, 1);
      expect(find.textContaining('Từ Tiền mặt'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('"Đóng" thẻ thì giữ Account mới', (tester) async {
      final db = await importedDb(tester);
      await pumpApp(tester, db: db);
      await goTo(tester, '/import-queue');
      await _tap(tester, find.text('Đóng'));
      expect(find.text('Đã tạo tài khoản MB Bank …4821'), findsNothing);
      final accounts = await tester.runAsync(
        () => db.select(db.accounts).get(),
      );
      expect(accounts!.any((a) => a.name == 'MB Bank …4821'), isTrue);
      expect(find.text(_payee), findsOneWidget); // mục vẫn còn
      await disposeApp(tester, db);
    });

    testWidgets('lưu khoản ghi tay khớp một mục đang chờ: mục rời hàng đợi, '
        'khoản gắn email, có thanh "Hoàn tác" đưa mục về hàng đợi (AC-94)', (
      tester,
    ) async {
      final db = await importedDb(tester);
      // Gắn Account tự tạo vào Tiền mặt để khoản ghi tay ở "Tiền mặt" khớp.
      await tester.runAsync(
        () =>
            MbImportService(db)
                .attachToExistingAccount(autoAccountId: 2, targetAccountId: 1),
      );
      await pumpApp(tester, db: db, clock: () => DateTime(2026, 11, 3, 12, 0));
      await tester.tap(find.byTooltip('Thêm khoản chi'));
      await settle(tester);
      await typeKeys(tester, '50000');
      await tester.tap(find.text('Chọn danh mục'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống').last);
      await settle(tester);

      expect(find.text('Đã ghép với email MB 12:02'), findsOneWidget);
      expect(await _queue(tester, db), isEmpty);
      var e = (await _entries(tester, db)).single;
      expect(e.source, EntrySource.emailMb);
      expect(e.referenceNumber, 'RX1');
      expect(e.time, '12:00'); // giữ nguyên dữ liệu của khoản ghi tay

      await tester.tap(find.text('Hoàn tác'));
      await settle(tester);
      expect(await _queue(tester, db), hasLength(1));
      e = (await _entries(tester, db)).single;
      expect(e.source, EntrySource.manual);
      expect(e.referenceNumber, isNull);
      await disposeApp(tester, db);
    });
  });
}
