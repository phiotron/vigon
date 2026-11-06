import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/settings_repository.dart';

/// Schema 2 (trước D-029): chưa có cột `*Micro`, CHECK amount > 0.
const _schema2 = [
  '''CREATE TABLE accounts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     name_key TEXT NULL, name TEXT NULL,
     initial_balance INTEGER NOT NULL DEFAULT 0,
     sort_order INTEGER NOT NULL DEFAULT 0,
     archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)))''',
  '''CREATE TABLE categories (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, name_key TEXT NULL, name TEXT NULL,
     icon TEXT NOT NULL, color INTEGER NOT NULL,
     sort_order INTEGER NOT NULL DEFAULT 0,
     budget INTEGER NULL CHECK (budget > 0))''',
  '''CREATE TABLE recurring_rules (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, amount INTEGER NOT NULL CHECK (amount > 0),
     category_id INTEGER NULL REFERENCES categories (id),
     account_id INTEGER NOT NULL REFERENCES accounts (id),
     to_account_id INTEGER NULL REFERENCES accounts (id),
     note TEXT NULL, frequency INTEGER NOT NULL, start_date TEXT NOT NULL,
     last_generated_date TEXT NULL,
     active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)))''',
  '''CREATE TABLE entries (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, amount INTEGER NOT NULL CHECK (amount > 0),
     category_id INTEGER NULL REFERENCES categories (id),
     account_id INTEGER NOT NULL REFERENCES accounts (id),
     to_account_id INTEGER NULL REFERENCES accounts (id),
     date TEXT NOT NULL, note TEXT NULL,
     recurring_rule_id INTEGER NULL REFERENCES recurring_rules (id),
     created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''',
  '''CREATE TABLE settings ("key" TEXT NOT NULL, value TEXT NOT NULL,
     PRIMARY KEY ("key"))''',
  '''INSERT INTO accounts (id, name_key, name, initial_balance)
     VALUES (1, 'cash', NULL, 5000000), (2, NULL, 'Thẻ', -2600000)''',
  '''INSERT INTO categories (id, type, name_key, icon, color, sort_order, budget)
     VALUES (1, 0, 'food', 'restaurant', 4291175465, 0, 2000000),
            (2, 0, 'home', 'home', 4284233728, 1, NULL)''',
  '''INSERT INTO recurring_rules (id, type, amount, category_id, account_id,
     frequency, start_date, last_generated_date)
     VALUES (1, 0, 3000000, 1, 1, 2, '2026-10-01', '2026-11-01')''',
  '''INSERT INTO entries (id, type, amount, category_id, account_id,
     to_account_id, date, note, recurring_rule_id)
     VALUES (1, 0, 155000, 1, 1, NULL, '2026-11-03', 'phở', NULL),
            (2, 0, 3000000, 1, 1, NULL, '2026-11-01', NULL, 1),
            (3, 2, 1000000, NULL, 1, 2, '2026-11-02', NULL, NULL)''',
  "INSERT INTO settings VALUES ('monthlyBudget', '9000000')",
  "INSERT INTO settings VALUES ('currency', 'VND')",
  'PRAGMA user_version = 2',
];

/// Số tiền chính xác: migration schema 3, sao lưu `.vigon` (D-029).
void main() {
  final now = DateTime(2026, 11, 6, 10);
  ExchangeRate rate(String r) => ExchangeRate.tryParse(r)!;

  group('migration schema 2 lên 3 (D-029)', () {
    late AppDatabase old;
    setUp(() {
      old = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final sql in _schema2) {
              raw.execute(sql);
            }
          },
        ),
      );
    });
    tearDown(() => old.close());

    test('dữ liệu cũ còn nguyên, cột micro rỗng, khóa ngoại còn', () async {
      final version = await old.customSelect('PRAGMA user_version').getSingle();
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
              e.toAccountId,
              e.note,
              e.recurringRuleId,
            ),
        ],
        [
          (1, EntryType.expense, 155000, null, null, 'phở', null),
          (2, EntryType.expense, 3000000, null, null, null, 1),
          (3, EntryType.transfer, 1000000, null, 2, null, null),
        ],
      );
      final rule = await old.select(old.recurringRules).getSingle();
      expect(
        (rule.amount, rule.amountMicro, rule.lastGeneratedDate),
        (3000000, null, '2026-11-01'),
      );
      final accounts = await old.select(old.accounts).get();
      expect(
        [for (final a in accounts) (a.initialBalance, a.initialBalanceMicro)],
        [(5000000, null), (-2600000, null)],
      );
      final cats = await old.select(old.categories).get();
      expect(
        [for (final c in cats) (c.budget, c.budgetMicro)],
        [(2000000, null), (null, null)],
      );
      expect(await SettingsRepository(old).readBudget(), 9000000);
      // Không chạy lại onCreate.
      expect(cats, hasLength(2));
      expect(await old.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      final fk = await old.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.read<int>('foreign_keys'), 1);
    });

    test('CHECK mới cho phép 0, vẫn chặn số âm và khóa ngoại sai', () async {
      await old.customStatement('UPDATE entries SET amount = 0 WHERE id = 1');
      await old.customStatement(
        'UPDATE recurring_rules SET amount = 0 WHERE id = 1',
      );
      await expectLater(
        old.customStatement('UPDATE entries SET amount = -1 WHERE id = 1'),
        throwsA(anything),
      );
      await expectLater(
        old.customStatement(
          'UPDATE recurring_rules SET amount = -1 WHERE id = 1',
        ),
        throwsA(anything),
      );
      await expectLater(
        old.customStatement('UPDATE entries SET account_id = 99 WHERE id = 1'),
        throwsA(anything),
      );
      await expectLater(
        old.customStatement(
          'UPDATE entries SET recurring_rule_id = 99 WHERE id = 1',
        ),
        throwsA(anything),
      );
      await expectLater(
        old.customStatement('UPDATE categories SET budget = 0 WHERE id = 1'),
        throwsA(anything),
      );
    });

    test('quy đổi được ngay sau khi nâng cấp, đổi lại ra đúng', () async {
      await convertCurrency(old, 'USD', rate('0.0000385'));
      await convertCurrency(old, 'VND', rate('0.0000385').inverse);
      final entries = await (old.select(
        old.entries,
      )..orderBy([(e) => OrderingTerm(expression: e.id)])).get();
      expect([for (final e in entries) e.amount], [155000, 3000000, 1000000]);
      expect(await SettingsRepository(old).readBudget(), 9000000);
    });

    test('DB mới tạo có schema 3 và đủ cột micro', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, currentSchemaVersion);
      expect(currentSchemaVersion, greaterThanOrEqualTo(3));
      Future<List<String>> cols(String table) async => [
        for (final r
            in await db
                .customSelect("SELECT name FROM pragma_table_info('$table')")
                .get())
          r.read<String>('name'),
      ];
      expect(await cols('entries'), contains('amount_micro'));
      expect(await cols('recurring_rules'), contains('amount_micro'));
      expect(await cols('accounts'), contains('initial_balance_micro'));
      expect(await cols('categories'), contains('budget_micro'));
    });
  });

  group('sao lưu .vigon mang số chính xác (D-029)', () {
    late AppDatabase db;
    late SettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    String rewrite(String json, void Function(Map<String, dynamic> root) edit) {
      final root = jsonDecode(json) as Map<String, dynamic>;
      edit(root);
      root['checksum'] = sha256
          .convert(utf8.encode(jsonEncode(root['tables'])))
          .toString();
      return jsonEncode(root);
    }

    Future<void> seed() async {
      await settings.setCurrency('VND');
      for (final a in [100, 155000]) {
        await db
            .into(db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.expense,
                amount: a,
                categoryId: const Value(1),
                accountId: 1,
                date: '2026-11-06',
              ),
            );
      }
      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              type: EntryType.expense,
              amount: 155000,
              categoryId: const Value(1),
              accountId: 1,
              frequency: RecurrenceFrequency.monthly,
              startDate: '2026-11-01',
            ),
          );
      await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
        const AccountsCompanion(initialBalance: Value(-155000)),
      );
      await CategoryRepository(db).setBudget(1, 155000);
      await settings.setBudget(155000);
      // 155.000 ₫ → 5,9675 US$: hiện 5,97, micro 5.967.500.
      await convertCurrency(db, 'USD', rate('0.0000385'));
    }

    test('xuất rồi khôi phục giữ micro, đổi lại ra đúng số gốc', () async {
      await seed();
      final json = await exportBackup(db, now: now);
      final root = jsonDecode(json) as Map<String, dynamic>;
      expect(root['schemaVersion'], currentSchemaVersion);
      final tables = root['tables'] as Map<String, dynamic>;
      expect((tables['entries'] as List).first['amountMicro'], 3850);
      expect(
        (tables['settings'] as List).any((s) => s['key'] == 'budgetMicro'),
        isTrue,
      );

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      final entries = await other.select(other.entries).get();
      expect(
        [for (final e in entries) (e.amount, e.amountMicro)],
        [(0, 3850), (597, 5967500)],
      );
      expect(
        (await other.select(other.recurringRules).getSingle()).amountMicro,
        5967500,
      );
      final cash = await (other.select(
        other.accounts,
      )..where((a) => a.id.equals(1))).getSingle();
      expect((cash.initialBalance, cash.initialBalanceMicro), (-597, -5967500));
      final food = await (other.select(
        other.categories,
      )..where((c) => c.id.equals(1))).getSingle();
      expect((food.budget, food.budgetMicro), (597, 5967500));
      expect(await SettingsRepository(other).readBudgetMicro(), 5967500);

      await convertCurrency(other, 'VND', rate('0.0000385').inverse);
      final back = await other.select(other.entries).get();
      expect([for (final e in back) e.amount], [100, 155000]);
      expect(
        (await other.select(other.recurringRules).getSingle()).amount,
        155000,
      );
      expect(await SettingsRepository(other).readBudget(), 155000);
    });

    test('file schema 2 cũ (không có micro) vẫn khôi phục được', () async {
      await seed();
      final json = await exportBackup(db, now: now);
      final old = rewrite(json, (root) {
        root['schemaVersion'] = 2;
        final tables = root['tables'] as Map<String, dynamic>;
        for (final (table, column) in [
          ('entries', 'amountMicro'),
          ('recurringRules', 'amountMicro'),
          ('accounts', 'initialBalanceMicro'),
          ('categories', 'budgetMicro'),
        ]) {
          for (final row in tables[table] as List) {
            (row as Map).remove(column);
          }
        }
        (tables['settings'] as List).removeWhere(
          (s) => (s as Map)['key'] == 'budgetMicro',
        );
        // Bản cũ không có khoản 0: đặt lại số dương.
        ((tables['entries'] as List).first as Map)['amount'] = 1;
      });
      expect(old.contains('Micro'), isFalse);

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      validateBackup(old);
      await importBackup(other, old);
      final entries = await other.select(other.entries).get();
      expect(
        [for (final e in entries) (e.amount, e.amountMicro)],
        [(1, null), (597, null)],
      );
      expect(await SettingsRepository(other).readBudgetMicro(), isNull);
      expect(await SettingsRepository(other).readBudget(), 597);
    });

    test('khoản 0 trong file khôi phục được, số âm vẫn bị từ chối', () async {
      await seed();
      final json = await exportBackup(db, now: now);
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json); // có khoản 0 (0,00 US$)
      final bad = rewrite(
        json,
        (r) => ((r['tables'] as Map)['entries'] as List).first['amount'] = -1,
      );
      await expectLater(
        importBackup(other, bad),
        throwsA(isA<BackupFormatException>()),
      );
      expect(await other.select(other.entries).get(), hasLength(2));
    });
  });
}
