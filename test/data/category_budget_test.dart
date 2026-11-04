import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/entries/category_budget.dart';
import 'package:vigon/src/providers.dart';

/// Schema 1 (trước F-20): bảng danh mục chưa có cột `budget`.
const _schema1 = [
  '''CREATE TABLE accounts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     name_key TEXT NULL, name TEXT NULL,
     initial_balance INTEGER NOT NULL DEFAULT 0,
     sort_order INTEGER NOT NULL DEFAULT 0,
     archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)))''',
  '''CREATE TABLE categories (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
     type INTEGER NOT NULL, name_key TEXT NULL, name TEXT NULL,
     icon TEXT NOT NULL, color INTEGER NOT NULL,
     sort_order INTEGER NOT NULL DEFAULT 0)''',
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
  "INSERT INTO accounts (id, name_key, initial_balance) VALUES (1, 'cash', 0)",
  '''INSERT INTO categories (id, type, name_key, icon, color, sort_order)
     VALUES (1, 0, 'food', 'restaurant', 4291175465, 0),
            (2, 0, NULL, 'home', 4284233728, 1)''',
  "UPDATE categories SET name = 'Cà phê' WHERE id = 2",
  '''INSERT INTO entries (type, amount, category_id, account_id, date, note)
     VALUES (0, 155000, 1, 1, '2026-11-03', 'phở')''',
  "INSERT INTO settings VALUES ('monthlyBudget', '9000000')",
  'PRAGMA user_version = 1',
];

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 3, 10, 30);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('kho danh mục: hạn mức (AC-54)', () {
    test('mặc định chưa có hạn mức; đặt, đổi, bỏ', () async {
      final repo = CategoryRepository(db);
      Future<int?> budgetOf(int id) async => (await (db.select(
        db.categories,
      )..where((c) => c.id.equals(id))).getSingle()).budget;

      expect(await budgetOf(1), isNull);
      await repo.setBudget(1, 500000);
      expect(await budgetOf(1), 500000);
      await repo.setBudget(1, 700000);
      expect(await budgetOf(1), 700000);
      await repo.setBudget(1, null);
      expect(await budgetOf(1), isNull);
    });

    test('hạn mức phải lớn hơn 0, kho và bảng đều chặn', () async {
      final repo = CategoryRepository(db);
      expect(() => repo.setBudget(1, 0), throwsArgumentError);
      expect(() => repo.setBudget(1, -5), throwsArgumentError);
      await expectLater(
        db.customStatement('UPDATE categories SET budget = 0 WHERE id = 1'),
        throwsA(anything),
      );
    });

    test(
      'add và edit mang hạn mức; edit không truyền thì giữ nguyên',
      () async {
        final repo = CategoryRepository(db);
        final id = await repo.add(
          type: CategoryType.expense,
          name: 'Cà phê',
          icon: 'local_cafe',
          color: 0xFF6A1B9A,
          budget: 300000,
        );
        Future<Category> get() => (db.select(
          db.categories,
        )..where((c) => c.id.equals(id))).getSingle();
        expect((await get()).budget, 300000);

        await repo.edit(id, name: 'Cà phê 2', icon: 'home', color: 0xFF6A1B9A);
        expect((await get()).budget, 300000);

        await repo.edit(
          id,
          icon: 'home',
          color: 0xFF6A1B9A,
          budget: const Value(null),
        );
        expect((await get()).budget, isNull);
      },
    );
  });

  group('migration schema 1 lên 2 (AC-54)', () {
    test('giữ nguyên dữ liệu cũ, thêm cột budget rỗng, dùng được', () async {
      final old = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final sql in _schema1) {
              raw.execute(sql);
            }
          },
        ),
      );
      addTearDown(old.close);

      final cats = await (old.select(
        old.categories,
      )..orderBy([(c) => OrderingTerm(expression: c.id)])).get();
      expect(cats.map((c) => (c.id, c.nameKey, c.name, c.budget)), [
        (1, 'food', null, null),
        (2, null, 'Cà phê', null),
      ]);
      final entry = await old.select(old.entries).getSingle();
      expect((entry.amount, entry.note, entry.categoryId), (155000, 'phở', 1));
      final setting = await old.select(old.settings).getSingle();
      expect((setting.key, setting.value), ('monthlyBudget', '9000000'));
      // Không chạy lại onCreate: không có danh mục mặc định thừa.
      expect(await old.select(old.accounts).get(), hasLength(1));

      final version = await old.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 2);
      await CategoryRepository(old).setBudget(1, 123);
      final c1 = await (old.select(
        old.categories,
      )..where((c) => c.id.equals(1))).getSingle();
      expect(c1.budget, 123);
      // Cột mới vẫn có ràng buộc > 0 sau khi nâng cấp bằng addColumn.
      expect(
        old.customStatement('UPDATE categories SET budget = -1 WHERE id = 1'),
        throwsA(anything),
      );
    });

    test('cơ sở dữ liệu mới tạo đã có schema 2 và cột budget', () async {
      expect(db.schemaVersion, 2);
      final cols = await db
          .customSelect("SELECT name FROM pragma_table_info('categories')")
          .get();
      expect(cols.map((r) => r.read<String>('name')), contains('budget'));
    });
  });

  group('sao lưu mang hạn mức (AC-54)', () {
    String rewrite(String json, void Function(Map<String, dynamic> root) edit) {
      final root = jsonDecode(json) as Map<String, dynamic>;
      edit(root);
      root['checksum'] = sha256
          .convert(utf8.encode(jsonEncode(root['tables'])))
          .toString();
      return jsonEncode(root);
    }

    test('xuất rồi khôi phục giữ đúng hạn mức từng danh mục', () async {
      await CategoryRepository(db).setBudget(1, 800000);
      await CategoryRepository(db).setBudget(3, 250000);
      final json = await exportBackup(db, now: now);
      final root = jsonDecode(json) as Map<String, dynamic>;
      expect(root['schemaVersion'], 2);
      expect((root['version'], root['format']), (1, 'vigon-backup'));

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      final cats = await other.select(other.categories).get();
      expect({for (final c in cats) c.id: c.budget}[1], 800000);
      expect({for (final c in cats) c.id: c.budget}[3], 250000);
      expect({for (final c in cats) c.id: c.budget}[2], isNull);
    });

    test(
      'file sao lưu CŨ (schema 1, không có khóa budget) vẫn khôi phục',
      () async {
        final json = await exportBackup(db, now: now);
        final old = rewrite(json, (root) {
          root['schemaVersion'] = 1;
          for (final c in (root['tables'] as Map)['categories'] as List) {
            (c as Map).remove('budget');
          }
        });
        expect(old.contains('"budget"'), isFalse);

        // Khôi phục lên máy đang có hạn mức: hạn mức cũ bị thay bằng dữ liệu file.
        await CategoryRepository(db).setBudget(1, 999);
        validateBackup(old);
        await importBackup(db, old);
        final cats = await db.select(db.categories).get();
        expect(cats, isNotEmpty);
        expect(cats.every((c) => c.budget == null), isTrue);
      },
    );

    test(
      'schemaVersion cao hơn bản hiện tại bị từ chối, thiếu thì chấp nhận',
      () async {
        final json = await exportBackup(db, now: now);
        final future = rewrite(json, (r) => r['schemaVersion'] = 3);
        await expectLater(
          importBackup(db, future),
          throwsA(isA<BackupFormatException>()),
        );
        final noSchema = rewrite(json, (r) => r.remove('schemaVersion'));
        await importBackup(db, noSchema);
      },
    );

    test('hạn mức ≤ 0 trong file bị từ chối, dữ liệu giữ nguyên', () async {
      await CategoryRepository(db).setBudget(1, 500);
      final json = await exportBackup(db, now: now);
      final bad = rewrite(
        json,
        (r) => ((r['tables'] as Map)['categories'] as List).first['budget'] = 0,
      );
      await expectLater(
        importBackup(db, bad),
        throwsA(isA<BackupFormatException>()),
      );
      final first = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(1))).getSingle();
      expect(first.budget, 500);
    });
  });

  group('chi theo tháng hiện tại của từng danh mục (AC-54)', () {
    Future<void> expense(int category, int amount, String date) => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: amount,
            categoryId: Value(category),
            accountId: 1,
            date: date,
          ),
        );

    test(
      'chỉ tính tháng chứa hôm nay, mọi tài khoản, bỏ thu và chuyển tiền',
      () async {
        await db
            .into(db.accounts)
            .insert(AccountsCompanion.insert(name: const Value('Thẻ')));
        await expense(1, 40000, '2026-11-01');
        await expense(1, 60000, '2026-11-30');
        await expense(2, 5000, '2026-11-15');
        await expense(1, 99999, '2026-10-31'); // tháng trước
        await expense(1, 77777, '2026-12-01'); // tháng sau
        await db
            .into(db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.expense,
                amount: 1000,
                categoryId: const Value(2),
                accountId: 2,
                date: '2026-11-10',
              ),
            );
        await db
            .into(db.entries)
            .insert(
              EntriesCompanion.insert(
                type: EntryType.income,
                amount: 5000000,
                categoryId: const Value(11),
                accountId: 1,
                date: '2026-11-05',
              ),
            );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            clockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 9)),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(categorySpentProvider, (_, _) {});
        addTearDown(sub.close);
        final spent = await container.read(categorySpentProvider.future);
        expect(spent, {1: 100000, 2: 6000});
      },
    );

    test('theo ngày bắt đầu tháng: bắt đầu ngày 15, hôm nay 20/11', () async {
      await db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: 'monthStartDay', value: '15'));
      await expense(1, 10, '2026-11-14'); // kỳ trước
      await expense(1, 20, '2026-11-15');
      await expense(1, 30, '2026-12-14');
      await expense(1, 40, '2026-12-15'); // kỳ sau
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 20)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(categorySpentProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await container.read(categorySpentProvider.future), {1: 50});
    });
  });
}
