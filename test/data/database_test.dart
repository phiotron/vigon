import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/seed.dart';
import 'package:vigon/src/data/settings_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('dữ liệu mặc định khi mở lần đầu', () {
    test('có tài khoản Tiền mặt (AC-18)', () async {
      final accounts = await db.select(db.accounts).get();
      expect(accounts, hasLength(1));
      expect(accounts.single.nameKey, 'cash');
      expect(accounts.single.initialBalance, 0);
    });

    test('có đủ danh mục chi và thu theo thứ tự (AC-15)', () async {
      final categories = await (db.select(
        db.categories,
      )..orderBy([(c) => OrderingTerm(expression: c.sortOrder)])).get();
      final expense = categories
          .where((c) => c.type == CategoryType.expense)
          .map((c) => c.nameKey)
          .toList();
      final income = categories
          .where((c) => c.type == CategoryType.income)
          .map((c) => c.nameKey)
          .toList();
      expect(expense, defaultExpenseCategories.map((c) => c.$1).toList());
      expect(income, defaultIncomeCategories.map((c) => c.$1).toList());
    });
  });

  group('ràng buộc khoản ghi', () {
    Future<int> insertEntry(int amount, {int accountId = 1}) => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: amount,
            categoryId: const Value(1),
            accountId: accountId,
            date: '2026-11-03',
          ),
        );

    test('lưu số tiền dương dạng số nguyên', () async {
      final id = await insertEntry(155000);
      final entry = await (db.select(
        db.entries,
      )..where((e) => e.id.equals(id))).getSingle();
      expect(entry.amount, 155000);
      expect(entry.date, '2026-11-03');
    });

    test('từ chối số tiền 0 hoặc âm (AC-05)', () async {
      await expectLater(insertEntry(0), throwsA(isA<SqliteException>()));
      await expectLater(insertEntry(-1), throwsA(isA<SqliteException>()));
    });

    test('từ chối tài khoản không tồn tại (khóa ngoại bật)', () async {
      await expectLater(
        insertEntry(1000, accountId: 999),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('cài đặt', () {
    test('giao diện mặc định theo hệ thống, đổi được (AC-35)', () async {
      final repo = SettingsRepository(db);
      expect(await repo.watchThemeMode().first, ThemeMode.system);
      await repo.setThemeMode(ThemeMode.dark);
      expect(await repo.watchThemeMode().first, ThemeMode.dark);
    });

    test('ngôn ngữ mặc định theo máy, chọn và bỏ chọn được (AC-36)', () async {
      final repo = SettingsRepository(db);
      expect(await repo.watchLocaleCode().first, isNull);
      await repo.setLocaleCode('en');
      expect(await repo.watchLocaleCode().first, 'en');
      await repo.setLocaleCode(null);
      expect(await repo.watchLocaleCode().first, isNull);
    });
  });
}
