import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/import_repositories.dart';
import 'package:vigon/src/data/import_text.dart';
import 'package:vigon/src/data/savings_repository.dart';
import 'package:vigon/src/data/settings_repository.dart';

/// Schema 3 đúng như bản 1.2 tạo ra (D-029): có cột `*Micro`, CHECK amount >= 0.
const _schema3 = [
  '''CREATE TABLE accounts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     name_key TEXT NULL, name TEXT NULL,
     initial_balance INTEGER NOT NULL DEFAULT 0,
     sort_order INTEGER NOT NULL DEFAULT 0,
     archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
     initial_balance_micro INTEGER NULL)''',
  '''CREATE TABLE categories (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, name_key TEXT NULL, name TEXT NULL,
     icon TEXT NOT NULL, color INTEGER NOT NULL,
     sort_order INTEGER NOT NULL DEFAULT 0,
     budget INTEGER NULL CHECK (budget > 0), budget_micro INTEGER NULL)''',
  '''CREATE TABLE recurring_rules (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, amount INTEGER NOT NULL CHECK (amount >= 0),
     amount_micro INTEGER NULL,
     category_id INTEGER NULL REFERENCES categories (id),
     account_id INTEGER NOT NULL REFERENCES accounts (id),
     to_account_id INTEGER NULL REFERENCES accounts (id),
     note TEXT NULL, frequency INTEGER NOT NULL, start_date TEXT NOT NULL,
     last_generated_date TEXT NULL,
     active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)))''',
  '''CREATE TABLE entries (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, amount INTEGER NOT NULL CHECK (amount >= 0),
     amount_micro INTEGER NULL,
     category_id INTEGER NULL REFERENCES categories (id),
     account_id INTEGER NOT NULL REFERENCES accounts (id),
     to_account_id INTEGER NULL REFERENCES accounts (id),
     date TEXT NOT NULL, note TEXT NULL,
     recurring_rule_id INTEGER NULL REFERENCES recurring_rules (id),
     created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''',
  '''CREATE TABLE settings ("key" TEXT NOT NULL, value TEXT NOT NULL,
     PRIMARY KEY ("key"))''',
  '''INSERT INTO accounts (id, name_key, name, initial_balance,
     initial_balance_micro, archived)
     VALUES (1, 'cash', NULL, 5000000, NULL, 0),
            (2, NULL, 'Thẻ', -2600000, NULL, 0),
            (3, NULL, 'Cũ', 0, NULL, 1)''',
  '''INSERT INTO categories (id, type, name_key, icon, color, sort_order,
     budget, budget_micro)
     VALUES (1, 0, 'food', 'restaurant', 4291175465, 0, 2000000, 2000000400000),
            (2, 1, 'salary', 'work', 4284233728, 1, NULL, NULL)''',
  '''INSERT INTO recurring_rules (id, type, amount, amount_micro, category_id,
     account_id, frequency, start_date, last_generated_date)
     VALUES (1, 0, 3000000, NULL, 1, 1, 2, '2026-10-01', '2026-11-01')''',
  '''INSERT INTO entries (id, type, amount, amount_micro, category_id,
     account_id, to_account_id, date, note, recurring_rule_id)
     VALUES (1, 0, 155000, 155000200000, 1, 1, NULL, '2026-11-03', 'phở', NULL),
            (2, 0, 3000000, NULL, 1, 1, NULL, '2026-11-01', NULL, 1),
            (3, 2, 1000000, NULL, NULL, 1, 2, '2026-11-02', NULL, NULL),
            (4, 1, 0, 300, 2, 3, NULL, '2026-10-30', 'nhỏ', NULL)''',
  "INSERT INTO settings VALUES ('monthlyBudget', '9000000')",
  "INSERT INTO settings VALUES ('currency', 'VND')",
  'PRAGMA user_version = 3',
];

ExchangeRate _rate(String r) => ExchangeRate.tryParse(r)!;

Future<List<String>> _columns(AppDatabase db, String table) async => [
  for (final r
      in await db
          .customSelect(
            "SELECT name FROM pragma_table_info('$table') ORDER BY name",
          )
          .get())
    r.read<String>('name'),
];

Future<List<String>> _schemaObjects(AppDatabase db) async => [
  for (final r
      in await db
          .customSelect(
            "SELECT type || ':' || name AS n FROM sqlite_master "
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY n",
          )
          .get())
    r.read<String>('n'),
];

/// Viết lại file sao lưu như bản app cũ: bỏ bảng/cột chưa có ở [schema], tính
/// lại mã băm.
String _downgradeBackup(String json, int schema) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final tables = root['tables'] as Map<String, dynamic>;
  for (final t in [
    'savingsGoals',
    'debts',
    'debtPayments',
    'payeeSuggestions',
    'seenReferences',
  ]) {
    tables.remove(t);
  }
  void drop(String table, List<String> cols) {
    for (final r in tables[table] as List) {
      (r as Map<String, dynamic>).removeWhere((k, _) => cols.contains(k));
    }
  }

  drop('entries', ['time', 'source', 'referenceNumber']);
  drop('accounts', ['bank', 'bankLast4']);
  if (schema < 3) {
    drop('entries', ['amountMicro']);
    drop('recurringRules', ['amountMicro']);
    drop('accounts', ['initialBalanceMicro']);
    drop('categories', ['budgetMicro']);
  }
  root['schemaVersion'] = schema;
  root['checksum'] = sha256.convert(utf8.encode(jsonEncode(tables))).toString();
  return jsonEncode(root);
}

void main() {
  final now = DateTime(2026, 11, 6, 10);

  group('migration schema 3 lên 5 (AC-121, D-037)', () {
    late AppDatabase old;
    setUp(() {
      old = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final sql in _schema3) {
              raw.execute(sql);
            }
          },
        ),
      );
    });
    tearDown(() => old.close());

    test(
      'dữ liệu v3 còn nguyên; khoản cũ ghi tay, không giờ (AC-75)',
      () async {
        final version = await old
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), currentSchemaVersion);

        final entries = await (old.select(
          old.entries,
        )..orderBy([(e) => OrderingTerm(expression: e.id)])).get();
        expect(
          [
            for (final e in entries)
              (
                e.id,
                e.type,
                e.amount,
                e.amountMicro,
                e.accountId,
                e.toAccountId,
                e.date,
                e.note,
                e.recurringRuleId,
                e.time,
                e.source,
                e.referenceNumber,
              ),
          ],
          [
            (
              1,
              EntryType.expense,
              155000,
              155000200000,
              1,
              null,
              '2026-11-03',
              'phở',
              null,
              null,
              EntrySource.manual,
              null,
            ),
            (
              2,
              EntryType.expense,
              3000000,
              null,
              1,
              null,
              '2026-11-01',
              null,
              1,
              null,
              EntrySource.manual,
              null,
            ),
            (
              3,
              EntryType.transfer,
              1000000,
              null,
              1,
              2,
              '2026-11-02',
              null,
              null,
              null,
              EntrySource.manual,
              null,
            ),
            (
              4,
              EntryType.income,
              0,
              300,
              3,
              null,
              '2026-10-30',
              'nhỏ',
              null,
              null,
              EntrySource.manual,
              null,
            ),
          ],
        );
        final accounts = await old.select(old.accounts).get();
        expect(
          [
            for (final a in accounts)
              (a.id, a.initialBalance, a.archived, a.bank, a.bankLast4),
          ],
          [
            (1, 5000000, false, null, null),
            (2, -2600000, false, null, null),
            (3, 0, true, null, null),
          ],
        );
        final cats = await old.select(old.categories).get();
        expect(
          [for (final c in cats) (c.budget, c.budgetMicro)],
          // + 2 danh mục lãi thêm ở schema 8 (AC-173).
          [(2000000, 2000000400000), (null, null), (null, null), (null, null)],
        );
        final rule = await old.select(old.recurringRules).getSingle();
        expect((rule.amount, rule.lastGeneratedDate), (3000000, '2026-11-01'));
        expect(await SettingsRepository(old).readBudget(), 9000000);
        // Không chạy lại onCreate (không thêm danh mục/tài khoản mặc định).
        expect(cats, hasLength(4));
        // Bảng mới có và rỗng.
        expect(await old.select(old.savingsGoals).get(), isEmpty);
        expect(await old.select(old.debts).get(), isEmpty);
        expect(await old.select(old.debtPayments).get(), isEmpty);
        expect(await old.select(old.payeeSuggestions).get(), isEmpty);
        expect(await old.select(old.importQueueItems).get(), isEmpty);
        expect(await old.select(old.seenReferences).get(), isEmpty);
        expect(
          await old.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        final fk = await old.customSelect('PRAGMA foreign_keys').getSingle();
        expect(fk.read<int>('foreign_keys'), 1);
      },
    );

    test(
      'migration lên 5: tiền tệ cũ thành tiền tệ gốc, giữ nguyên số',
      () async {
        final settings = SettingsRepository(old);
        expect(await settings.readPrimaryCurrency(), 'VND');
        expect(await settings.readBudgetCurrency(), 'VND');
        final entries = await old.select(old.entries).get();
        expect(entries.map((e) => e.currency), everyElement('VND'));
        expect(entries.map((e) => e.originalAmount), everyElement(isNull));
        final accounts = await old.select(old.accounts).get();
        expect(accounts.map((a) => a.currency), everyElement('VND'));
        expect(accounts.map((a) => a.initialCurrency), everyElement('VND'));
        expect(
          accounts.map((a) => a.initialBalanceOriginal),
          everyElement(isNull),
        );
        final cats = await old.select(old.categories).get();
        expect(cats.map((c) => c.budgetCurrency), ['VND', null, null, null]);
        final rule = await old.select(old.recurringRules).getSingle();
        expect((rule.currency, rule.originalAmount), ('VND', null));
        expect(await old.select(old.savingsGoals).get(), isEmpty);
      },
    );

    test('cấu trúc sau migration giống hệt DB mới tạo', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      expect(await _schemaObjects(old), await _schemaObjects(fresh));
      for (final t in [
        'accounts',
        'categories',
        'recurring_rules',
        'entries',
        'settings',
        'savings_goals',
        'debts',
        'debt_payments',
        'payee_suggestions',
        'import_queue_items',
        'seen_references',
      ]) {
        expect(await _columns(old, t), await _columns(fresh, t), reason: t);
      }
    });

    test('ràng buộc mới: giờ HH:mm, 4 số cuối, số tham chiếu duy nhất', () async {
      await expectLater(
        old.customStatement("UPDATE entries SET time = '9:5' WHERE id = 1"),
        throwsA(anything),
      );
      await old.customStatement(
        "UPDATE entries SET time = '12:02' WHERE id = 1",
      );
      await expectLater(
        old.customStatement(
          "UPDATE accounts SET bank = 'mb', bank_last4 = '12345' WHERE id = 1",
        ),
        throwsA(anything),
      );
      final accounts = AccountRepository(old);
      await accounts.setBankLink(1, Bank.mb, '1234');
      expect(
        () => accounts.setBankLink(2, Bank.mb, '12a4'),
        throwsArgumentError,
      );
      final entries = EntryRepository(old);
      await entries.attachReference(1, EntrySource.emailMb, 'FT001');
      await expectLater(
        entries.attachReference(2, EntrySource.emailMb, 'FT001'),
        throwsA(anything),
      );
      // Khoản ghi tay không số tham chiếu: nhiều NULL không tính trùng.
      expect((await entries.find(2))!.referenceNumber, isNull);
    });

    test(
      'file schema 3 của chính DB này khôi phục được sau khi lên 4',
      () async {
        final v4 = await exportBackup(old, now: now);
        final v3 = _downgradeBackup(v4, 3);
        final other = AppDatabase(NativeDatabase.memory());
        addTearDown(other.close);
        await importBackup(other, v3);
        final entries = await other.select(other.entries).get();
        expect(entries, hasLength(4));
        expect(entries.every((e) => e.source == EntrySource.manual), isTrue);
        expect(entries.every((e) => e.time == null), isTrue);
        expect(entries.firstWhere((e) => e.id == 1).amountMicro, 155000200000);
      },
    );
  });

  group('kho dữ liệu bảng mới', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('liên kết ngân hàng chuyển sang tài khoản có sẵn (AC-89)', () async {
      final accounts = AccountRepository(db);
      final auto = await accounts.add(name: 'MB Bank …1234');
      await accounts.setBankLink(auto, Bank.mb, '1234');
      expect((await accounts.findByBankLink(Bank.mb, '1234'))!.id, auto);
      final queue = ImportQueueRepository(db);
      await queue.add(
        ImportQueueItemsCompanion.insert(
          bank: Bank.mb,
          referenceNumber: 'FT1',
          debitLast4: '1234',
          accountId: Value(auto),
          currency: 'VND',
          amount: 50000,
          date: '2026-11-06',
          time: '12:02',
        ),
      );
      await accounts.setBankLink(1, Bank.mb, '1234');
      await queue.moveAccount(auto, 1);
      expect(await accounts.delete(auto), isNull);
      expect((await accounts.findByBankLink(Bank.mb, '1234'))!.id, 1);
      expect((await queue.all()).single.accountId, 1);
      await accounts.clearBankLink(1);
      expect(await accounts.findByBankLink(Bank.mb, '1234'), isNull);
    });

    test('hàng đợi: che số dài, chặn trùng, xoá + hoàn tác, đếm', () async {
      final queue = ImportQueueRepository(db);
      ImportQueueItemsCompanion item(String ref) =>
          ImportQueueItemsCompanion.insert(
            bank: Bank.mb,
            referenceNumber: ref,
            debitLast4: '1234',
            accountId: const Value(1),
            currency: 'VND',
            amount: 2000000,
            date: '2026-11-06',
            time: '08:30',
            payee: const Value('NGUYEN VAN A 0123456789'),
            transferContent: const Value('chuyen tien TK 9704221234567890'),
          );
      final id = await queue.add(item('FT1'));
      expect(id, isNotNull);
      expect(await queue.add(item('FT1')), isNull);
      final saved = (await queue.find(id!))!;
      expect(saved.payee, 'NGUYEN VAN A …6789');
      expect(saved.transferContent, 'chuyen tien TK …7890');
      expect(await queue.watchCount().first, 1);
      final removed = await queue.remove(id);
      expect(await queue.watchCount().first, 0);
      await queue.restore(removed!);
      expect((await queue.all()).single.id, id);
      expect(
        () => queue.add(item('FT2').copyWith(debitLast4: const Value('123'))),
        throwsArgumentError,
      );
    });

    test(
      'số tham chiếu đã biết: đã gặp, trong hàng đợi, trong khoản (AC-86)',
      () async {
        final seen = SeenReferenceRepository(db);
        expect(await seen.isKnown(Bank.mb, 'FT1'), isFalse);
        await seen.markSeen(Bank.mb, 'FT1', ReferenceOutcome.skipped);
        expect(await seen.isSeen(Bank.mb, 'FT1'), isTrue);
        expect(await seen.isKnown(Bank.mb, 'FT1'), isTrue);
        await seen.markSeen(Bank.mb, 'FT1', ReferenceOutcome.confirmed);
        expect(
          (await db.select(db.seenReferences).getSingle()).outcome,
          ReferenceOutcome.confirmed,
        );
        await seen.forget(Bank.mb, 'FT1');
        expect(await seen.isKnown(Bank.mb, 'FT1'), isFalse);

        final entryId = await EntryRepository(db).add(
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: 50000,
            categoryId: const Value(1),
            accountId: 1,
            date: '2026-11-06',
            time: const Value('12:00'),
          ),
        );
        await EntryRepository(db)
            .attachReference(entryId, EntrySource.emailMb, 'FT2');
        expect(await seen.isKnown(Bank.mb, 'FT2'), isTrue);
        await EntryRepository(db).detachReference(entryId);
        final e = (await EntryRepository(db).find(entryId))!;
        expect(
          (e.source, e.referenceNumber, e.time),
          (EntrySource.manual, null, '12:00'),
        );
      },
    );

    test(
      'gợi ý theo người thụ hưởng: khoá bỏ dấu, ghi đè, xoá danh mục (AC-97)',
      () async {
        expect(payeeKey('  Công   ty ABC '), 'cong ty abc');
        final repo = PayeeSuggestionRepository(db);
        await repo.rememberCategory('CONG TY ABC', 1, at: now);
        expect((await repo.forPayee('Công ty ABC'))!.categoryId, 1);
        await repo.rememberTransfer('Công ty ABC', 1, at: now);
        final s = (await repo.forPayee('cong ty abc'))!;
        expect(
          (s.categoryId, s.toAccountId, s.payee),
          (null, 1, 'Công ty ABC'),
        );
        await repo.rememberCategory('Quán X', 2, at: now);
        await CategoryRepository(db).delete(2, moveTo: 3);
        expect((await repo.forPayee('quan x'))!.categoryId, 3);
        expect(await repo.watchAll().first, hasLength(2));
        await repo.delete('quan x');
        expect(await repo.forPayee('Quán X'), isNull);
        // Một gợi ý phải trỏ đúng một nơi.
        await expectLater(
          db.customStatement(
            "INSERT INTO payee_suggestions (payee_key, payee, category_id, "
            "to_account_id, updated_at) VALUES ('k', 'k', 1, 1, 0)",
          ),
          throwsA(anything),
        );
      },
    );

    test('mục tiêu tiết kiệm: một tài khoản một mục tiêu, tạo tài khoản mới (AC-100, AC-103)', () async {
      final repo = SavingsGoalRepository(db);
      final (goalId, accountId) = await repo.addWithNewAccount(
        name: 'Du lịch',
        targetAmount: 10000000,
        dueDate: '2027-06-01',
      );
      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(accountId))).getSingle();
      expect((account.name, account.initialBalance), ('Du lịch', 0));
      await expectLater(
        repo.add(name: 'Khác', targetAmount: 1, accountId: accountId),
        throwsA(isA<AccountHasGoalException>()),
      );
      expect(
        () => repo.add(name: 'X', targetAmount: 0, accountId: 1),
        throwsArgumentError,
      );
      // Tài khoản đang gắn mục tiêu không xoá được; xoá mục tiêu giữ tài khoản.
      expect(await AccountRepository(db).delete(accountId), AccountBlock.inUse);
      await repo.edit(goalId, name: 'Du lịch Nhật', targetAmount: 12000000);
      expect((await repo.find(goalId))!.targetAmount, 12000000);
      await repo.delete(goalId);
      expect(await repo.all(), isEmpty);
      expect(await AccountRepository(db).delete(accountId), isNull);
    });

    test(
      'khoản nợ: lần trả không vượt số còn lại, xoá theo (AC-104, AC-105)',
      () async {
        await SettingsRepository(db).setCurrency('VND');
        final repo = DebtRepository(db);
        final id = await repo.add(
          person: 'Lan',
          direction: DebtDirection.lent,
          amount: 500000,
          date: '2026-11-01',
        );
        await repo.addPayment(id, amount: 200000, date: '2026-11-03');
        await expectLater(
          repo.addPayment(id, amount: 300001, date: '2026-11-04'),
          throwsA(
            isA<DebtOverpaymentException>().having(
              (e) => e.remaining,
              'remaining',
              300000,
            ),
          ),
        );
        final p2 = await repo.addPayment(
          id,
          amount: 300000,
          date: '2026-11-04',
        );
        var view = (await repo.find(id))!;
        expect(
          (view.remaining(0), view.paid(0), view.isSettled(0)),
          (0, 500000, true),
        );
        await repo.deletePayment(p2);
        view = (await repo.find(id))!;
        expect((view.remaining(0), view.isSettled(0)), (300000, false));
        expect((await repo.watchAll().first).single.payments, hasLength(1));
        await repo.delete(id);
        expect(await db.select(db.debtPayments).get(), isEmpty);
      },
    );
  });

  group('sao lưu .vigon schema 4 (AC-121)', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> seed() async {
      final settings = SettingsRepository(db);
      await settings.setCurrency('VND');
      final accounts = AccountRepository(db);
      final mb = await accounts.add(name: 'MB Bank …1234');
      await accounts.setBankLink(mb, Bank.mb, '1234');
      await EntryRepository(db).add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 50000,
          categoryId: const Value(1),
          accountId: mb,
          date: '2026-11-06',
          time: const Value('12:00'),
          source: const Value(EntrySource.emailMb),
          referenceNumber: const Value('FT-IN-ENTRY'),
        ),
      );
      await SavingsGoalRepository(db).add(
        name: 'Quỹ',
        targetAmount: 10000000,
        accountId: 1,
        dueDate: '2027-01-01',
      );
      await db.customStatement(
        'UPDATE savings_goals SET target_amount_micro = 10000000300000',
      );
      final debts = DebtRepository(db);
      final debt = await debts.add(
        person: 'Minh',
        direction: DebtDirection.borrowed,
        amount: 1000000,
        date: '2026-10-01',
        note: 'mượn',
      );
      await debts.addPayment(debt, amount: 400000, date: '2026-10-15');
      await PayeeSuggestionRepository(db)
          .rememberCategory('Quán A', 1, at: now);
      await PayeeSuggestionRepository(db).rememberTransfer('Tôi', mb, at: now);
      await SeenReferenceRepository(db)
          .markSeen(Bank.mb, 'FT-SKIPPED', ReferenceOutcome.skipped, at: now);
      await ImportQueueRepository(db).add(
        ImportQueueItemsCompanion.insert(
          bank: Bank.mb,
          referenceNumber: 'FT-QUEUED',
          debitLast4: '1234',
          accountId: Value(mb),
          currency: 'VND',
          amount: 70000,
          date: '2026-11-06',
          time: '13:00',
        ),
      );
    }

    test(
      'mang mọi bảng mới trừ hàng đợi; khôi phục giữ đúng dữ liệu',
      () async {
        await seed();
        final json = await exportBackup(db, now: now);
        final root = jsonDecode(json) as Map<String, dynamic>;
        expect(root['schemaVersion'], currentSchemaVersion);
        final tables = root['tables'] as Map<String, dynamic>;
        expect(tables.keys, isNot(contains('importQueueItems')));
        expect(json, isNot(contains('FT-QUEUED')));
        for (final t in [
          'savingsGoals',
          'debts',
          'debtPayments',
          'payeeSuggestions',
          'seenReferences',
        ]) {
          expect(tables[t], isNotEmpty, reason: t);
        }

        final other = AppDatabase(NativeDatabase.memory());
        addTearDown(other.close);
        await importBackup(other, json);
        Future<List<Map<String, dynamic>>> dump(
          AppDatabase d,
          String t,
        ) async => [
          for (final r in await d.customSelect('SELECT * FROM $t').get())
            r.data,
        ];
        for (final t in [
          'accounts',
          'entries',
          'savings_goals',
          'debts',
          'debt_payments',
          'payee_suggestions',
          'seen_references',
        ]) {
          expect(await dump(other, t), await dump(db, t), reason: t);
        }
        // Hàng đợi không đi theo file.
        expect(await other.select(other.importQueueItems).get(), isEmpty);
        final e = (await other.select(other.entries).get()).last;
        expect(
          (e.time, e.source, e.referenceNumber),
          ('12:00', EntrySource.emailMb, 'FT-IN-ENTRY'),
        );
      },
    );

    test('khôi phục giữ hàng đợi hiện có, bỏ mục đã xử lý, gắn lại tài khoản (AC-99)', () async {
      await seed();
      final json = await exportBackup(db, now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      // Máy khác: tài khoản liên kết có id khác, hàng đợi có 3 mục.
      final accounts = AccountRepository(other);
      await accounts.add(name: 'A');
      await accounts.add(name: 'B');
      final localMb = await accounts.add(name: 'MB …1234 (máy này)');
      await accounts.setBankLink(localMb, Bank.mb, '1234');
      final queue = ImportQueueRepository(other);
      for (final ref in ['FT-IN-ENTRY', 'FT-SKIPPED', 'FT-NEW', 'FT-OTHER']) {
        await queue.add(
          ImportQueueItemsCompanion.insert(
            bank: Bank.mb,
            referenceNumber: ref,
            debitLast4: ref == 'FT-OTHER' ? '9999' : '1234',
            accountId: Value(localMb),
            currency: 'VND',
            amount: 1000,
            date: '2026-11-06',
            time: '09:00',
          ),
        );
      }
      await importBackup(other, json);
      final restoredMb = (await AccountRepository(other)
          .findByBankLink(Bank.mb, '1234'))!;
      final left = {
        for (final q in await queue.all()) q.referenceNumber: q.accountId,
      };
      expect(left, {'FT-NEW': restoredMb.id, 'FT-OTHER': null});
      expect(
        await other.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    });

    test(
      'file schema 2 và 3 vẫn khôi phục (bảng mới rỗng, khoản không giờ)',
      () async {
        await seed();
        final json = await exportBackup(db, now: now);
        for (final schema in [2, 3]) {
          final other = AppDatabase(NativeDatabase.memory());
          addTearDown(other.close);
          await importBackup(other, _downgradeBackup(json, schema));
          final e = (await other.select(other.entries).get()).single;
          expect(
            (e.time, e.source, e.referenceNumber),
            (null, EntrySource.manual, null),
            reason: 'schema $schema',
          );
          expect(await other.select(other.savingsGoals).get(), isEmpty);
          expect(await other.select(other.seenReferences).get(), isEmpty);
          final mb = (await other.select(other.accounts).get()).last;
          expect((mb.bank, mb.bankLast4), (null, null));
        }
      },
    );

    test(
      'file schema 4 thiếu bảng mới bị từ chối; schema mới hơn bị từ chối',
      () async {
        await seed();
        final json = await exportBackup(db, now: now);
        final root = jsonDecode(json) as Map<String, dynamic>;
        final tables = root['tables'] as Map<String, dynamic>..remove('debts');
        root['checksum'] = sha256
            .convert(utf8.encode(jsonEncode(tables)))
            .toString();
        expect(
          () => validateBackup(jsonEncode(root)),
          throwsA(isA<BackupFormatException>()),
        );
        final newer = jsonDecode(json) as Map<String, dynamic>
          ..['schemaVersion'] = currentSchemaVersion + 1;
        expect(
          () => validateBackup(jsonEncode(newer)),
          throwsA(isA<BackupFormatException>()),
        );
      },
    );
  });

  group('đổi tiền tệ bảng mới (AC-122)', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> seed() async {
      await SettingsRepository(db).setCurrency('VND');
      await SavingsGoalRepository(db)
          .add(name: 'Quỹ', targetAmount: 10000000, accountId: 1);
      final acc2 = await AccountRepository(db).add(name: 'Nhỏ');
      await SavingsGoalRepository(db)
          .add(name: 'Tí', targetAmount: 1, accountId: acc2);
      final debts = DebtRepository(db);
      final d = await debts.add(
        person: 'Lan',
        direction: DebtDirection.lent,
        amount: 100001,
        date: '2026-11-01',
      );
      for (final p in [33333, 33334, 33334]) {
        await debts.addPayment(d, amount: p, date: '2026-11-02');
      }
      final queue = ImportQueueRepository(db);
      ImportQueueItemsCompanion item(String ref, String currency, int amount) =>
          ImportQueueItemsCompanion.insert(
            bank: Bank.mb,
            referenceNumber: ref,
            debitLast4: '1234',
            currency: currency,
            amount: amount,
            date: '2026-11-06',
            time: '10:00',
          );
      await queue.add(item('FT-VND', 'VND', 155000));
      await queue.add(item('FT-EUR', 'EUR', 1999));
    }

    Future<List<Object?>> snapshot() async => [
      for (final g in await db.select(db.savingsGoals).get()) g.targetAmount,
      for (final d in await db.select(db.debts).get()) d.amount,
      for (final p in await db.select(db.debtPayments).get()) p.amount,
      for (final q in await db.select(db.importQueueItems).get())
        (q.referenceNumber, q.currency, q.amount),
    ];

    test('VND → USD → VND về đúng số cũ; mục tiêu tối thiểu 1; mục tiền khác giữ nguyên', () async {
      await seed();
      final before = await snapshot();
      await convertCurrency(db, 'USD', _rate('0.0000385'));
      final goals = await db.select(db.savingsGoals).get();
      expect([for (final g in goals) g.targetAmount], [38500, 1]);
      final queue = {
        for (final q in await db.select(db.importQueueItems).get())
          q.referenceNumber: (q.currency, q.amount),
      };
      // 155.000 ₫ × 0,0000385 = 5,9675 US$ → 597 cent.
      expect(queue, {'FT-VND': ('USD', 597), 'FT-EUR': ('EUR', 1999)});
      // Khoản nợ đã trả đủ vẫn còn đúng 0 dù từng lần trả làm tròn lệch.
      final view = (await DebtRepository(db).all()).single;
      expect(view.remaining(2), 0);
      expect(view.isSettled(2), isTrue);

      await convertCurrency(db, 'VND', _rate('0.0000385').inverse);
      final after = await snapshot();
      // Mục tiêu 1 ₫ bị nâng lên 1 cent nên không về 1 ₫ (như ngân sách, D-029);
      // mọi số khác về đúng.
      expect(after[1], greaterThan(1));
      expect([after[0], ...after.skip(2)], [before[0], ...before.skip(2)]);
    });

    test('vượt giới hạn ở bảng mới thì không đổi gì', () async {
      await seed();
      await DebtRepository(db).add(
        person: 'To',
        direction: DebtDirection.borrowed,
        amount: 900000000000,
        date: '2026-11-01',
      );
      final before = await snapshot();
      await expectLater(
        convertCurrency(db, 'USD', _rate('1000')),
        throwsA(isA<CurrencyConversionOverflow>()),
      );
      expect(await snapshot(), before);
      expect(await SettingsRepository(db).readCurrency(), 'VND');
    });
  });

  group('xóa toàn bộ dữ liệu (AC-123)', () {
    test(
      'xoá bảng mới, kể cả hàng đợi; chạy hook ngoài cơ sở dữ liệu',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await SavingsGoalRepository(db)
            .add(name: 'Quỹ', targetAmount: 1000, accountId: 1);
        await DebtRepository(db).add(
          person: 'A',
          direction: DebtDirection.lent,
          amount: 10,
          date: '2026-11-01',
        );
        await PayeeSuggestionRepository(db).rememberCategory('A', 1);
        await SeenReferenceRepository(db)
            .markSeen(Bank.mb, 'FT1', ReferenceOutcome.matched);
        await ImportQueueRepository(db).add(
          ImportQueueItemsCompanion.insert(
            bank: Bank.mb,
            referenceNumber: 'FT2',
            debitLast4: '1234',
            currency: 'VND',
            amount: 1,
            date: '2026-11-06',
            time: '10:00',
          ),
        );
        await AccountRepository(db).setBankLink(1, Bank.mb, '1234');
        final calls = <String>[];
        await expectLater(
          deleteAllData(
            db,
            hooks: [
              () async => calls.add('mailboxes'),
              () async => throw StateError('keychain'),
              () async => calls.add('background'),
            ],
          ),
          throwsA(isA<StateError>()),
        );
        // Mọi hook vẫn chạy dù một hook lỗi.
        expect(calls, ['mailboxes', 'background']);
        for (final t in [
          'savings_goals',
          'debts',
          'debt_payments',
          'payee_suggestions',
          'seen_references',
          'import_queue_items',
        ]) {
          final n = await db
              .customSelect('SELECT COUNT(*) AS n FROM $t')
              .getSingle();
          expect(n.read<int>('n'), 0, reason: t);
        }
        final account = await db.select(db.accounts).getSingle();
        expect(
          (account.nameKey, account.bank, account.bankLast4),
          ('cash', null, null),
        );
      },
    );
  });

  group('CSV thêm Giờ và Nguồn ở cuối (AC-124)', () {
    test('khoản có giờ, khoản từ email MB', () {
      final csv = exportCsv(
        entries: [
          Entry(
            id: 1,
            type: EntryType.expense,
            amount: 50000,
            categoryId: 1,
            accountId: 1,
            toAccountId: null,
            date: '2026-11-06',
            note: 'Cà phê',
            recurringRuleId: null,
            createdAt: now,
            time: '12:00',
            source: EntrySource.emailMb,
            referenceNumber: 'FT1',
            currency: 'VND',
          ),
          Entry(
            id: 2,
            type: EntryType.expense,
            amount: 1000,
            categoryId: 1,
            accountId: 1,
            toAccountId: null,
            date: '2026-11-06',
            note: null,
            recurringRuleId: null,
            createdAt: now,
            time: null,
            source: EntrySource.manual,
            currency: 'VND',
          ),
        ],
        currency: 'VND',
        decimalDigits: 0,
        categoryName: (_) => 'Ăn uống',
        accountName: (_) => 'MB',
        format: CsvFormat.forLanguage(
          'vi',
          header: CsvFormat.english.header,
          expense: 'Chi',
          income: 'Thu',
          transfer: 'Chuyển tiền',
          timeHeader: 'Giờ',
          sourceHeader: 'Nguồn',
          manualSource: 'Ghi tay',
          emailMbSource: 'Email MB',
        ),
      );
      final lines = csv.substring(1).trim().split('\r\n');
      expect(lines[0], endsWith(';note;Giờ;Nguồn'));
      expect(
        lines[1],
        '2026-11-06;Chi;50000;VND;Ăn uống;MB;;Cà phê;12:00;Email MB',
      );
      expect(lines[2], '2026-11-06;Chi;1000;VND;Ăn uống;MB;;;;Ghi tay');
      // Số tham chiếu không xuất ra CSV.
      expect(csv, isNot(contains('FT1')));
    });
  });

  test('maskLongDigitRuns chỉ che dãy từ 9 chữ số (AC-88)', () {
    expect(
      maskLongDigitRuns('ma 12345678 va 123456789'),
      'ma 12345678 va …6789',
    );
    checkLast4('0001');
    expect(() => checkLast4('12345'), throwsArgumentError);
    expect(() => checkLast4('12a4'), throwsArgumentError);
  });
}
