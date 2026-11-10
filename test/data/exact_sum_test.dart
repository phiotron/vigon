import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/money_sum.dart';
import 'package:vigon/src/data/rate_repository.dart';
import 'package:vigon/src/data/savings_repository.dart';
import 'package:vigon/src/data/summary.dart';
import 'package:vigon/src/features/reminder/deadline_reminders.dart';

/// D-042 / D-043 / D-044 — SPEC 3g (AC-146..AC-158).
void main() {
  // 1 USD = 25 974 VND, 1 USD = 0.92 EUR.
  const table = RateTable(
    base: 'USD',
    date: '2026-11-10',
    rates: {'VND': 25974, 'EUR': 0.92},
  );
  const usd = CurrencyService(table, 'USD');
  const vnd = CurrencyService(table, 'VND');

  group('MoneyBag (AC-148)', () {
    test('cộng gốc theo tiền tệ rồi quy đổi một lần', () {
      // 3 × 10 000 ₫: quy từng khoản sang cent rồi cộng = 3 × 39 = 117 cent;
      // cộng gốc rồi đổi một lần = 30 000 / 25 974 = 1,155 → 116 cent.
      final bag = MoneyBag();
      for (var i = 0; i < 3; i++) {
        bag.add('VND', 10000);
      }
      expect(bag.parts, {'VND': 30000});
      expect(bag.convertTo(usd, 'USD'), 116);
      expect(3 * usd.toPrimary(10000, 'VND')!, 117);
      // Theo chính tiền tệ gốc thì không có sai số nào.
      expect(bag.convertTo(usd, 'VND'), 30000);
    });

    test('nhiều tiền tệ + thiếu tỷ giá thì bỏ phần đó', () {
      final bag = MoneyBag()
        ..add('USD', 1000)
        ..add('VND', 259740)
        ..add('XAF', 500);
      expect(bag.convertTo(usd, 'USD'), 2000);
      expect(bag.convertTo(usd, 'USD', skipMissing: false), isNull);
      expect(bag.missing(usd, 'USD'), {'XAF'});
    });

    test('số âm làm tròn đối xứng', () {
      final bag = MoneyBag()..add('VND', -10000);
      expect(bag.convertTo(usd, 'USD'), -39); // −0,385 → −0,39 (ra xa 0)
    });
  });

  group('số dư theo tiền gốc không lệch khi đổi Tiền tệ chính (AC-148b)', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('tài khoản ₫ giữ đúng từng đồng dù Tiền tệ chính là USD', () async {
      final cash = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: const Value('Cash VND'),
              currency: const Value('VND'),
              initialCurrency: const Value('VND'),
              initialBalance: const Value(0),
              initialBalanceOriginal: const Value(1000000),
            ),
          );
      for (var i = 0; i < 7; i++) {
        await db
            .into(db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.expense,
                // Số dẫn xuất đã làm tròn theo USD (cent).
                amount: usd.toPrimary(12345, 'VND')!,
                originalAmount: const Value(12345),
                currency: const Value('VND'),
                categoryId: const Value(1),
                accountId: cash,
                date: '2026-11-0${i + 1}',
              ),
            );
      }
      final bags = balanceBags(
        await db.select(db.accounts).get(),
        await db.select(db.entries).get(),
      );
      final bag = bags[cash]!;
      for (final service in [usd, vnd]) {
        expect(bag.convertTo(service, 'VND'), 1000000 - 7 * 12345);
      }
      expect(bag.convertTo(usd, 'USD'), 3517); // 913 585 / 25 974 = 35,17
    });

    test('tổng kỳ cộng số gốc (PeriodSummary)', () {
      final food = Category(
        id: 1,
        type: CategoryType.expense,
        name: 'Food',
        icon: 'restaurant',
        color: 0,
        sortOrder: 0,
      );
      Entry e(int original) => Entry(
        id: original,
        type: EntryType.expense,
        amount: usd.toPrimary(original, 'VND')!,
        categoryId: 1,
        accountId: 1,
        date: '2026-11-01',
        createdAt: DateTime(2026),
        currency: 'VND',
        originalAmount: original,
        source: EntrySource.manual,
      );
      final rows = [for (var i = 0; i < 3; i++) EntryView(e(10000 + i), food)];
      final s = PeriodSummary.of(rows, service: usd);
      expect(s.expense, 116); // 30 003 ₫ → $1.16 (cộng từng dòng: $1.17)
      expect(s.expenseByCategory.single.total, 116);
    });
  });

  group('Khoản nợ tính bằng số gốc (AC-158)', () {
    late AppDatabase db;
    late DebtRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DebtRepository(db);
    });
    tearDown(() => db.close());

    test(
      'nợ 100 USD khi Tiền tệ chính là VND: trả 40 + 60 còn đúng 0',
      () async {
        final id = await repo.add(
          person: 'An',
          direction: DebtDirection.lent,
          amount: vnd.toPrimary(10000, 'USD')!,
          originalAmount: 10000,
          currency: 'USD',
          date: '2026-11-01',
        );
        await repo.addPayment(
          id,
          amount: vnd.toPrimary(4000, 'USD')!,
          originalAmount: 4000,
          currency: 'USD',
          date: '2026-11-02',
        );
        await expectLater(
          repo.addPayment(
            id,
            amount: vnd.toPrimary(6001, 'USD')!,
            originalAmount: 6001,
            currency: 'USD',
            date: '2026-11-03',
          ),
          throwsA(
            isA<DebtOverpaymentException>().having(
              (e) => e.remaining,
              'remaining',
              6000,
            ),
          ),
        );
        await repo.addPayment(
          id,
          amount: vnd.toPrimary(6000, 'USD')!,
          originalAmount: 6000,
          currency: 'USD',
          date: '2026-11-03',
        );
        final view = (await repo.find(id))!;
        expect(
          (view.remaining(), view.paid(), view.isSettled()),
          (0, 10000, true),
        );
      },
    );
  });

  group('Ví tiết kiệm (AC-149, AC-153, AC-154)', () {
    late AppDatabase db;
    late SavingsGoalRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SavingsGoalRepository(db);
    });
    tearDown(() => db.close());

    test('luôn tạo ví mới, số dư ban đầu = Đã có sẵn', () async {
      final (goalId, accountId) = await repo.addWithWallet(
        name: 'Du lịch',
        accountName: 'Quỹ du lịch',
        targetAmount: 5000000,
        originalTargetAmount: 5000000,
        currency: 'VND',
        alreadySaved: 1000000,
      );
      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(accountId))).getSingle();
      expect(
        (account.name, account.currency, account.initialBalanceOriginal),
        ('Quỹ du lịch', 'VND', 1000000),
      );
      final goal = (await repo.find(goalId))!;
      expect((goal.accountId, goal.completedAt), (accountId, null));
      expect(await repo.walletHasEntries(accountId), isFalse);
    });

    test('Đã xong chỉ ghi lần đầu; Mở lại xoá', () async {
      final (goalId, _) = await repo.addWithWallet(
        name: 'Laptop',
        accountName: 'Laptop',
        targetAmount: 100,
        originalTargetAmount: 100,
        currency: 'USD',
      );
      expect(await repo.markCompleted(goalId, '2026-11-10'), isTrue);
      expect(await repo.markCompleted(goalId, '2026-11-11'), isFalse);
      expect((await repo.find(goalId))!.completedAt, '2026-11-10');
      await repo.reopen(goalId);
      expect((await repo.find(goalId))!.completedAt, isNull);
    });

    test('migration schema 6 → 7 thêm completed_at, mục tiêu cũ giữ', () async {
      final dir = Directory.systemTemp.createTempSync('vigon_v7_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/db.sqlite');
      final fresh = AppDatabase(NativeDatabase(file));
      await SavingsGoalRepository(fresh)
          .add(name: 'Old', targetAmount: 500, accountId: 1, currency: 'USD');
      await fresh.customStatement(
        'ALTER TABLE savings_goals DROP COLUMN completed_at',
      );
      await fresh.customStatement('PRAGMA user_version = 6');
      await fresh.close();

      final migrated = AppDatabase(NativeDatabase(file));
      addTearDown(migrated.close);
      final goal = await migrated.select(migrated.savingsGoals).getSingle();
      expect((goal.name, goal.completedAt), ('Old', null));
      final v = await migrated.customSelect('PRAGMA user_version').getSingle();
      expect(v.read<int>('user_version'), currentSchemaVersion);
    });
  });

  group('Nhắc trước hạn (AC-156, AC-157)', () {
    final l = lookupAppLocalizations(const Locale('vi'));
    final due = DateTime(2026, 11, 20);
    final items = [
      DeadlineItem(
        kind: DeadlineKind.debt,
        id: 1,
        name: 'An',
        due: due,
        remaining: 2000000,
        currency: 'VND',
      ),
      DeadlineItem(
        kind: DeadlineKind.goal,
        id: 1,
        name: 'Du lịch',
        due: due,
        remaining: 0, // đã đủ → không nhắc
        currency: 'VND',
      ),
    ];

    test('hai mốc: trước N ngày và đúng ngày hạn, có số tiền', () {
      final plan = planDeadlineNotifications(
        items: items,
        days: 7,
        time: const TimeOfDay(hour: 9, minute: 0),
        now: DateTime(2026, 11, 10, 12),
        l: l,
        locale: 'vi',
      );
      expect(plan.map((n) => n.at), [
        DateTime(2026, 11, 13, 9),
        DateTime(2026, 11, 20, 9),
      ]);
      expect(
        plan.first.body.replaceAll(' ', ' '),
        'Khoản nợ với An: còn 2.000.000 ₫, đến hạn sau 7 ngày',
      );
      expect(
        plan.last.body.replaceAll(' ', ' '),
        'Khoản nợ với An: còn 2.000.000 ₫, đến hạn hôm nay',
      );
      expect(plan.map((n) => n.id).toSet().length, 2);
      expect(plan.every((n) => n.payload == deadlineDebtPayload), isTrue);
    });

    test('mốc đã qua thì bỏ', () {
      final plan = planDeadlineNotifications(
        items: items,
        days: 7,
        time: const TimeOfDay(hour: 9, minute: 0),
        now: DateTime(2026, 11, 15),
        l: l,
        locale: 'vi',
      );
      expect(plan.single.at, DateTime(2026, 11, 20, 9));
    });

    test('tiếng Anh, mục tiêu', () {
      final plan = planDeadlineNotifications(
        items: [
          DeadlineItem(
            kind: DeadlineKind.goal,
            id: 3,
            name: 'Trip',
            due: due,
            remaining: 30000,
            currency: 'EUR',
          ),
        ],
        days: 7,
        time: const TimeOfDay(hour: 9, minute: 0),
        now: DateTime(2026, 11, 10),
        l: lookupAppLocalizations(const Locale('en')),
        locale: 'en',
      );
      expect(plan.first.body, startsWith('Goal Trip: '));
      expect(plan.first.body, endsWith('to go, due in 7 days'));
      expect(plan.first.payload, deadlineSavingsPayload);
    });
  });
}
