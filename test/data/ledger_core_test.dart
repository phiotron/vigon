import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/balance_guard.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/money_sum.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/rate_repository.dart';
import 'package:vigon/src/data/summary.dart';

/// SPEC 3h — lớp dữ liệu của F-49 (có thu mới có chi) và F-52 (khoản nợ qua
/// tài khoản, có lãi). D-046, D-049.
void main() {
  // 1 USD = 26 000 VND.
  const table = RateTable(
    base: 'USD',
    date: '2026-11-10',
    rates: {'VND': 26000},
  );
  const vnd = CurrencyService(table, 'VND');

  late AppDatabase db;
  late AccountRepository accounts;
  late EntryRepository entries;
  late BalanceGuard guard;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountRepository(db);
    entries = EntryRepository(db);
    guard = BalanceGuard(db, vnd);
  });
  tearDown(() => db.close());

  Future<int> vndAccount(String name, int balance, {bool negative = false}) =>
      accounts.add(
        name: name,
        initialBalance: balance,
        currency: 'VND',
        allowNegative: negative,
      );

  EntriesCompanion expense(
    int account,
    int amount, {
    String date = '2026-11-11',
  }) => EntriesCompanion.insert(
    type: EntryType.expense,
    amount: amount,
    categoryId: const Value(1),
    accountId: account,
    date: date,
    currency: const Value('VND'),
    originalAmount: Value(amount),
  );

  Future<int> balanceOf(int id) async {
    final bags = balanceBags(
      await db.select(db.accounts).get(),
      await db.select(db.entries).get(),
    );
    return bags[id]!.convertTo(vnd, 'VND')!;
  }

  group('BalanceGuard (AC-160, AC-161)', () {
    test(
      'Trip 500.000 ₫: chi 700.000 bị chặn, chi 500.000 được (số dư 0)',
      () async {
        final trip = await vndAccount('Trip', 500000);
        final short = await guard.checkAdd(expense(trip, 700000));
        expect(short, isNotNull);
        expect(
          (short!.account.id, short.before, short.after),
          (trip, 500000, -200000),
        );
        expect(await guard.checkAdd(expense(trip, 500000)), isNull);
        await entries.add(expense(trip, 500000));
        expect(await balanceOf(trip), 0);
      },
    );

    test('mọi thời gian: khoản ngày cũ vẫn so với số dư hiện tại', () async {
      final trip = await vndAccount('Trip', 500000);
      await entries.add(expense(trip, 400000));
      expect(
        await guard.checkAdd(expense(trip, 200000, date: '2020-01-01')),
        isNotNull,
      );
    });

    test('tài khoản cho phép âm không bị chặn', () async {
      final card = await vndAccount('Thẻ', 0, negative: true);
      expect(await guard.checkAdd(expense(card, 1000000)), isNull);
    });

    test(
      'bên nhận chuyển tiền không bao giờ bị chặn; bên gửi bị chặn',
      () async {
        final a = await vndAccount('A', 100);
        final b = await vndAccount('B', -500, negative: false);
        final transfer = EntriesCompanion.insert(
          type: EntryType.transfer,
          amount: 100,
          accountId: a,
          toAccountId: Value(b),
          date: '2026-11-11',
          currency: const Value('VND'),
          originalAmount: const Value(100),
        );
        // B đang âm, nhận tiền vẫn được (số dư tăng).
        expect(await guard.checkAdd(transfer), isNull);
        final tooMuch = transfer.copyWith(
          amount: const Value(101),
          originalAmount: const Value(101),
        );
        expect((await guard.checkAdd(tooMuch))!.account.id, a);
      },
    );

    test('sửa: tăng số tiền chi bị chặn; đổi ngày không ảnh hưởng', () async {
      final trip = await vndAccount('Trip', 500000);
      final id = await entries.add(expense(trip, 300000));
      final old = (await entries.find(id))!;
      expect(
        await guard.checkReplace(
          old,
          old.copyWith(amount: 600000, originalAmount: const Value(600000)),
        ),
        isNotNull,
      );
      expect(
        await guard.checkReplace(old, old.copyWith(date: '2019-01-01')),
        isNull,
      );
    });

    test('sửa: đổi sang tài khoản thiếu tiền bị chặn', () async {
      final a = await vndAccount('A', 500000);
      final b = await vndAccount('B', 100);
      final id = await entries.add(expense(a, 300000));
      final old = (await entries.find(id))!;
      final short = await guard.checkReplace(old, old.copyWith(accountId: b));
      expect(short?.account.id, b);
    });

    test('xoá khoản thu làm âm → chặn ("sẽ âm 200.000 ₫")', () async {
      final trip = await vndAccount('Trip', 0);
      final income = await entries.add(
        EntriesCompanion.insert(
          type: EntryType.income,
          amount: 500000,
          categoryId: const Value(12),
          accountId: trip,
          date: '2026-11-01',
          currency: const Value('VND'),
          originalAmount: const Value(500000),
        ),
      );
      await entries.add(expense(trip, 500000));
      // Số dư 0 + 500.000 − 500.000 = 0; xoá thu 500.000 → −500.000.
      final short = await guard.checkDelete([(await entries.find(income))!]);
      expect((short!.before, short.after, short.missing), (0, -500000, 500000));
    });

    test(
      'khoản cũ đã làm âm trước luật: sửa được miễn không âm thêm',
      () async {
        final trip = await vndAccount('Trip', 0);
        // Dữ liệu cũ: chi 300.000 khi số dư 0 (trước luật).
        final id = await entries.add(expense(trip, 300000));
        final old = (await entries.find(id))!;
        expect(
          await guard.checkReplace(old, old.copyWith(note: const Value('x'))),
          isNull,
        );
        expect(
          await guard.checkReplace(
            old,
            old.copyWith(amount: 200000, originalAmount: const Value(200000)),
          ),
          isNull,
        );
        expect(
          await guard.checkReplace(
            old,
            old.copyWith(amount: 400000, originalAmount: const Value(400000)),
          ),
          isNotNull,
        );
        // Thu vào tài khoản đang âm luôn được.
        expect(
          await guard.check(
            add: [(accountId: trip, currency: 'VND', minor: 1000)],
          ),
          isNull,
        );
      },
    );

    test(
      'tắt công tắc khi đang âm: mọi tiền ra bị chặn tới khi ≥ 0 (AC-162)',
      () async {
        final card = await vndAccount('Thẻ', -100000, negative: true);
        await accounts.setAllowNegative(card, false);
        expect(await guard.checkAdd(expense(card, 1)), isNotNull);
      },
    );

    test('khoản khác tiền tệ trừ theo tỷ giá vào tài khoản ₫', () async {
      final trip = await vndAccount('Trip', 500000);
      final usd = EntriesCompanion.insert(
        type: EntryType.expense,
        amount: 520000,
        categoryId: const Value(1),
        accountId: trip,
        date: '2026-11-11',
        currency: const Value('USD'),
        originalAmount: const Value(2000), // 20 $ = 520.000 ₫
      );
      expect(await guard.checkAdd(usd), isNotNull);
      expect(
        await guard.checkAdd(usd.copyWith(originalAmount: const Value(1900))),
        isNull,
      );
    });
  });

  group('Khoản nợ qua tài khoản (AC-169, AC-170, AC-173, AC-175)', () {
    late DebtRepository debts;
    setUp(() => debts = DebtRepository(db, () => DateTime(2026, 12, 1)));

    Future<int> lend(int account, int amount, {int? rate}) => debts.add(
      person: 'An',
      direction: DebtDirection.lent,
      amount: amount,
      originalAmount: amount,
      currency: 'VND',
      date: '2026-11-01',
      accountId: account,
      interestRate: rate,
      interestPeriod: rate == null ? null : InterestPeriod.year,
      service: vnd,
    );

    test('Cho vay = tiền ra, là Debt movement không vào thu/chi', () async {
      final tcb = await vndAccount('TCB', 6000000);
      final id = await lend(tcb, 5000000);
      expect(await balanceOf(tcb), 1000000);
      final rows = await entries.watchEntries(_allTime, accountId: tcb).first;
      expect(rows.single.entry.type, EntryType.debt);
      expect(rows.single.entry.debtKind, DebtMovementKind.lend);
      expect(rows.single.entry.debtId, id);
      final summary = PeriodSummary.of(rows, service: vnd);
      expect((summary.income, summary.expense), (0, 0));
    });

    test('Cho vay chịu có thu mới có chi: thiếu tiền không lưu gì', () async {
      final tcb = await vndAccount('TCB', 1000);
      await expectLater(
        lend(tcb, 5000),
        throwsA(isA<InsufficientFundsException>()),
      );
      expect(await db.select(db.debts).get(), isEmpty);
      expect(await db.select(db.entries).get(), isEmpty);
    });

    test('Đi vay = tiền vào; Trả nợ = tiền ra, chịu AC-160', () async {
      final cash = await vndAccount('Ví', 0);
      final id = await debts.add(
        person: 'Bình',
        direction: DebtDirection.borrowed,
        amount: 1000000,
        originalAmount: 1000000,
        currency: 'VND',
        date: '2026-11-01',
        accountId: cash,
        service: vnd,
      );
      expect(await balanceOf(cash), 1000000);
      await entries.add(expense(cash, 700000));
      await expectLater(
        debts.addPayment(
          id,
          amount: 400000,
          date: '2026-11-20',
          accountId: cash,
          service: vnd,
        ),
        throwsA(isA<InsufficientFundsException>()),
      );
      await debts.addPayment(
        id,
        amount: 300000,
        date: '2026-11-20',
        accountId: cash,
        service: vnd,
      );
      expect(await balanceOf(cash), 0);
    });

    test(
      'AC-173: lần trả chia lãi + gốc; lãi là khoản thu "Tiền lãi"',
      () async {
        final tcb = await vndAccount('TCB', 10000000);
        final id = await lend(tcb, 10000000, rate: 1200);
        var view = (await debts.find(id))!;
        expect(view.unpaidInterest, 98630);
        expect(view.remaining(), 10098630);
        final split = view.interest.split(1000000, DateTime(2026, 12, 1));
        await debts.addPayment(
          id,
          amount: split.principal,
          originalAmount: split.principal,
          interest: split.interest,
          date: '2026-12-01',
          accountId: tcb,
          service: vnd,
        );
        view = (await debts.find(id))!;
        expect(view.principalLeft, 9098630);
        expect(view.unpaidInterest, 0);
        expect(await balanceOf(tcb), 1000000);
        final rows = await entries.watchEntries(_allTime).first;
        final interest = rows.singleWhere(
          (r) => r.entry.type == EntryType.income,
        );
        expect(interest.entry.originalAmount, 98630);
        expect(interest.category!.nameKey, 'interestIncome');
        expect(PeriodSummary.of(rows, service: vnd).income, 98630);
      },
    );

    test('lãi vượt lãi tới ngày trả / gốc vượt gốc còn lại → lỗi', () async {
      final tcb = await vndAccount('TCB', 10000000);
      final id = await lend(tcb, 10000000, rate: 1200);
      await expectLater(
        debts.addPayment(
          id,
          amount: 0,
          interest: 98631,
          date: '2026-12-01',
          accountId: tcb,
          service: vnd,
        ),
        throwsA(isA<DebtInterestOverException>()),
      );
      await expectLater(
        debts.addPayment(
          id,
          amount: 10000001,
          date: '2026-12-01',
          accountId: tcb,
          service: vnd,
        ),
        throwsA(isA<DebtOverpaymentException>()),
      );
    });

    test('đi vay: lãi là khoản chi "Lãi vay", có vào ngân sách', () async {
      final cash = await vndAccount('Ví', 0);
      final id = await debts.add(
        person: 'Bình',
        direction: DebtDirection.borrowed,
        amount: 10000000,
        originalAmount: 10000000,
        currency: 'VND',
        date: '2026-11-01',
        accountId: cash,
        interestRate: 100,
        interestPeriod: InterestPeriod.month,
        service: vnd,
      );
      await debts.addPayment(
        id,
        amount: 0,
        interest: 98630,
        date: '2026-12-01',
        accountId: cash,
        service: vnd,
      );
      final rows = await entries.watchEntries(_allTime).first;
      final summary = PeriodSummary.of(rows, service: vnd);
      expect(summary.expense, 98630);
      expect(summary.expenseByCategory.single.category.nameKey, 'loanInterest');
    });

    test(
      'xoá lần trả xoá các khoản của nó; xoá lần thu làm âm bị chặn',
      () async {
        final tcb = await vndAccount('TCB', 5000000);
        final id = await lend(tcb, 5000000);
        final pay = await debts.addPayment(
          id,
          amount: 2000000,
          date: '2026-11-20',
          accountId: tcb,
          service: vnd,
        );
        await entries.add(expense(tcb, 1500000));
        await expectLater(
          debts.deletePayment(pay, service: vnd),
          throwsA(isA<InsufficientFundsException>()),
        );
        await (db.delete(
          db.entries,
        )..where((e) => e.type.equalsValue(EntryType.expense))).go();
        final deleted = await debts.deletePayment(pay, service: vnd);
        expect(deleted!.entries, hasLength(1));
        expect(await debts.paymentEntries(pay), isEmpty);
        await debts.restorePayment(deleted, service: vnd);
        expect(await debts.paymentEntries(pay), hasLength(1));
      },
    );

    test(
      'AC-175: xoá khoản nợ giữ các khoản (mồ côi), số dư không đổi',
      () async {
        final tcb = await vndAccount('TCB', 6000000);
        final id = await lend(tcb, 5000000, rate: 1200);
        await debts.addPayment(
          id,
          amount: 1000000,
          interest: 49315,
          date: '2026-12-01',
          accountId: tcb,
          service: vnd,
        );
        await debts.addRateChange(
          id,
          date: '2026-12-15',
          rate: 1500,
          period: InterestPeriod.year,
        );
        final before = await balanceOf(tcb);
        await debts.delete(id);
        expect(await balanceOf(tcb), before);
        final left = await db.select(db.entries).get();
        expect(left, hasLength(3));
        expect(
          left.every((e) => e.debtId == null && e.debtPaymentId == null),
          isTrue,
        );
        expect(
          left.where((e) => e.type == EntryType.debt).map((e) => e.debtKind),
          [DebtMovementKind.lend, DebtMovementKind.collect],
        );
        expect(await db.select(db.debtRateChanges).get(), isEmpty);
      },
    );

    test('khoản nợ ghi nhớ (không tài khoản) không sinh khoản nào', () async {
      await debts.add(
        person: 'An',
        direction: DebtDirection.lent,
        amount: 500,
        date: '2026-11-01',
        currency: 'VND',
      );
      expect(await db.select(db.entries).get(), isEmpty);
    });

    test(
      'AC-176: khoá tiền tệ khi đã có Debt movement; sửa số tiền đổi khoản',
      () async {
        final tcb = await vndAccount('TCB', 6000000);
        final id = await lend(tcb, 5000000);
        await debts.edit(
          id,
          person: 'An',
          direction: DebtDirection.lent,
          amount: 4000000,
          originalAmount: 4000000,
          currency: 'USD',
          date: '2026-11-02',
          service: vnd,
        );
        final view = (await debts.find(id))!;
        expect(view.debt.currency, 'VND');
        final loan = (await debts.loanEntry(id))!;
        expect((loan.originalAmount, loan.date), (4000000, '2026-11-02'));
        expect(await balanceOf(tcb), 2000000);
      },
    );

    test(
      'khoản nợ USD qua tài khoản ₫: khoản ghi theo tiền tệ tài khoản',
      () async {
        final tcb = await vndAccount('TCB', 6000000);
        final id = await debts.add(
          person: 'An',
          direction: DebtDirection.lent,
          amount: 2600000,
          originalAmount: 10000,
          currency: 'USD',
          date: '2026-11-01',
          accountId: tcb,
          service: vnd,
        );
        final loan = (await debts.loanEntry(id))!;
        expect((loan.currency, loan.originalAmount), ('VND', 2600000));
        await debts.addPayment(
          id,
          amount: 1040000,
          originalAmount: 4000,
          currency: 'USD',
          date: '2026-11-10',
          accountId: tcb,
          service: vnd,
        );
        expect((await debts.find(id))!.remaining(), 6000);
        expect(await balanceOf(tcb), 6000000 - 2600000 + 1040000);
      },
    );
  });

  group('Schema 8 (AC-163, AC-176, AC-177)', () {
    test('mới cài: có hai danh mục lãi, không cờ nâng cấp', () async {
      final keys = (await db.select(db.categories).get()).map((c) => c.nameKey);
      expect(keys, containsAll(['loanInterest', 'interestIncome']));
      expect(
        await (db.select(
          db.settings,
        )..where((s) => s.key.equals(negativeCheckPendingKey))).get(),
        isEmpty,
      );
    });

    test('migration 7 → 8: giữ dữ liệu, thêm cột/bảng, bật âm cho tài khoản đang âm', () async {
      final dir = Directory.systemTemp.createTempSync('vigon_v8_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      final fresh = AppDatabase(NativeDatabase(file));
      final repo = AccountRepository(fresh);
      final ok = await repo.add(
        name: 'Ok',
        initialBalance: 100,
        currency: 'VND',
      );
      final neg = await repo.add(
        name: 'Thẻ VIB',
        initialBalance: 0,
        currency: 'VND',
      );
      await EntryRepository(fresh).add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 300,
          categoryId: const Value(1),
          accountId: neg,
          date: '2026-11-01',
          currency: const Value('VND'),
          originalAmount: const Value(300),
        ),
      );
      await DebtRepository(fresh).add(
        person: 'An',
        direction: DebtDirection.lent,
        amount: 500,
        date: '2026-11-01',
        currency: 'VND',
      );
      // Về schema 7: bỏ cột/bảng của schema 8 (bảng nợ dựng lại theo v7).
      await fresh.customStatement('PRAGMA foreign_keys = OFF');
      for (final sql in _toSchema7) {
        await fresh.customStatement(sql);
      }
      await fresh.customStatement('PRAGMA user_version = 7');
      await fresh.close();

      final migrated = AppDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      final v = await migrated.customSelect('PRAGMA user_version').getSingle();
      expect(v.read<int>('user_version'), 8);
      final debt = await migrated.select(migrated.debts).getSingle();
      expect(
        (debt.person, debt.accountId, debt.interestRate),
        ('An', null, null),
      );
      expect(await migrated.select(migrated.debtRateChanges).get(), isEmpty);
      final keys = (await migrated.select(migrated.categories).get()).map(
        (c) => c.nameKey,
      );
      expect(keys.where((k) => k == 'loanInterest'), hasLength(1));
      expect(
        await migrated.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      // Lần mở đầu (có tỷ giá): tài khoản đang âm tự bật, báo một lần.
      final turned = await applyNegativeUpgrade(migrated, vnd);
      expect(turned, [neg]);
      final all = {
        for (final a in await migrated.select(migrated.accounts).get())
          a.id: a.allowNegative,
      };
      expect((all[ok], all[neg]), (false, true));
      expect(await applyNegativeUpgrade(migrated, vnd), isEmpty);
    });

    test('sao lưu mang cột/bảng mới; file schema 7 khôi phục được', () async {
      final tcb = await vndAccount('TCB', 6000000, negative: true);
      final debts = DebtRepository(db, () => DateTime(2026, 12, 1));
      final id = await debts.add(
        person: 'An',
        direction: DebtDirection.lent,
        amount: 5000000,
        originalAmount: 5000000,
        currency: 'VND',
        date: '2026-11-01',
        accountId: tcb,
        interestRate: 1200,
        interestPeriod: InterestPeriod.year,
        interestStart: '2026-11-05',
        service: vnd,
      );
      await debts.addPayment(
        id,
        amount: 100000,
        interest: 20000,
        date: '2026-12-01',
        accountId: tcb,
        service: vnd,
      );
      await debts.addRateChange(
        id,
        date: '2026-12-10',
        rate: 100,
        period: InterestPeriod.month,
      );
      final json = await exportBackup(db, now: DateTime(2026, 12, 1));

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      final a = await (other.select(
        other.accounts,
      )..where((a) => a.id.equals(tcb))).getSingle();
      expect(a.allowNegative, isTrue);
      final view = (await DebtRepository(
        other,
        () => DateTime(2026, 12, 1),
      ).find(id))!;
      expect(
        (view.debt.accountId, view.debt.interestStart),
        (tcb, '2026-11-05'),
      );
      expect(view.payments.single.interest, 20000);
      expect(view.rateChanges.single.rate, 100);
      final moved = await other.select(other.entries).get();
      expect(moved.where((e) => e.debtId == id), hasLength(3));

      // File schema 7: không có các trường mới → mặc định + cờ nâng cấp.
      final old = await exportBackup(db, now: DateTime(2026, 12, 1));
      final v7 = _asSchema7(old);
      final third = AppDatabase(NativeDatabase.memory());
      addTearDown(third.close);
      await importBackup(third, v7);
      final restored = await third.select(third.accounts).get();
      expect(restored.every((a) => !a.allowNegative), isTrue);
      final pending = await (third.select(
        third.settings,
      )..where((s) => s.key.equals(negativeCheckPendingKey))).get();
      expect(pending, hasLength(1));
    });
  });
}

final _allTime = Period(PeriodType.all, DateTime(2026), DateTime(2026));

/// Câu lệnh đưa cơ sở dữ liệu schema 8 (vừa tạo) về đúng schema 7 cho các
/// bảng đổi ở schema 8.
const _toSchema7 = [
  'ALTER TABLE accounts DROP COLUMN allow_negative',
  'DROP TABLE debt_rate_changes',
  "DELETE FROM categories WHERE name_key IN ('loanInterest', 'interestIncome')",
  'ALTER TABLE entries DROP COLUMN debt_kind',
  // debt_id / debt_payment_id có khoá ngoại nên không DROP COLUMN được:
  // dựng lại bảng khoản nợ / lần trả theo v7; cột khoản để nguyên (bước 7→8
  // chỉ thêm cột còn thiếu).
  'CREATE TABLE debts_v7 ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"person" TEXT NOT NULL, "direction" TEXT NOT NULL, '
      '"amount" INTEGER NOT NULL CHECK ("amount" >= 0), "amount_micro" INTEGER NULL, '
      '"date" TEXT NOT NULL, "due_date" TEXT NULL, "note" TEXT NULL, '
      '"created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
      '"currency" TEXT NOT NULL DEFAULT \'USD\', "original_amount" INTEGER NULL)',
  'INSERT INTO debts_v7 SELECT id, person, direction, amount, amount_micro, '
      'date, due_date, note, created_at, currency, original_amount FROM debts',
  'DROP TABLE debts',
  'ALTER TABLE debts_v7 RENAME TO debts',
  'CREATE TABLE debt_payments_v7 ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"debt_id" INTEGER NOT NULL REFERENCES debts (id) ON DELETE CASCADE, '
      '"amount" INTEGER NOT NULL CHECK ("amount" >= 0), "amount_micro" INTEGER NULL, '
      '"date" TEXT NOT NULL, '
      '"created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
      '"currency" TEXT NOT NULL DEFAULT \'USD\', "original_amount" INTEGER NULL)',
  'INSERT INTO debt_payments_v7 SELECT id, debt_id, amount, amount_micro, '
      'date, created_at, currency, original_amount FROM debt_payments',
  'DROP TABLE debt_payments',
  'ALTER TABLE debt_payments_v7 RENAME TO debt_payments',
];

/// File sao lưu [json] viết lại như file schema 7: bỏ bảng/trường mới.
String _asSchema7(String json) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final tables = root['tables'] as Map<String, dynamic>;
  tables.remove('debtRateChanges');
  for (final a in tables['accounts'] as List) {
    (a as Map).remove('allowNegative');
  }
  for (final p in tables['debtPayments'] as List) {
    (p as Map)
      ..remove('interest')
      ..remove('accountId');
  }
  for (final d in tables['debts'] as List) {
    (d as Map)
      ..remove('accountId')
      ..remove('interestRate')
      ..remove('interestPeriod')
      ..remove('interestStart');
  }
  for (final e in tables['entries'] as List) {
    (e as Map)
      ..remove('debtKind')
      ..remove('debtId')
      ..remove('debtPaymentId');
  }
  // Khoản Debt movement không có ở schema 7.
  (tables['entries'] as List).removeWhere((e) => (e as Map)['type'] == 3);
  root['schemaVersion'] = 7;
  root['checksum'] = sha256.convert(utf8.encode(jsonEncode(tables))).toString();
  return jsonEncode(root);
}
