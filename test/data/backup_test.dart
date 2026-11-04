import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/recurring_repository.dart';
import 'package:vigon/src/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 3, 10, 30);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> sampleData() async {
    final card = await AccountRepository(db)
        .add(name: 'Thẻ', initialBalance: 1000);
    await db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: 155000,
            categoryId: const Value(1),
            accountId: 1,
            date: '2026-11-03',
            note: const Value('phở, "bò"'),
          ),
        );
    await db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.transfer,
            amount: 500,
            accountId: card,
            toAccountId: const Value(1),
            date: '2026-11-02',
          ),
        );
    await RecurringRepository(db).addWithRepeat(
      EntriesCompanion.insert(
        type: EntryType.expense,
        amount: 3000000,
        categoryId: const Value(3),
        accountId: 1,
        date: '2026-11-01',
      ),
      RecurrenceFrequency.monthly,
    );
    final settings = SettingsRepository(db);
    await settings.ensureCurrency('vi_VN');
    await settings.setBudget(9000000);
  }

  Future<Map<String, List<Object?>>> snapshot(AppDatabase d) async => {
    'accounts': await d.select(d.accounts).get(),
    'categories': await d.select(d.categories).get(),
    'rules': await d.select(d.recurringRules).get(),
    'entries': await d.select(d.entries).get(),
    'settings': await d.select(d.settings).get(),
  };

  /// Sửa phần dữ liệu rồi tính lại mã băm, như một file "hợp lệ về hình thức".
  String tamper(String json, void Function(Map<String, dynamic> tables) edit) {
    final root = jsonDecode(json) as Map<String, dynamic>;
    final tables = root['tables'] as Map<String, dynamic>;
    edit(tables);
    root['checksum'] = sha256
        .convert(utf8.encode(jsonEncode(tables)))
        .toString();
    return jsonEncode(root);
  }

  group('sao lưu và khôi phục (AC-28, AC-29)', () {
    test(
      'validateBackup báo file hỏng mà không đụng dữ liệu (AC-29)',
      () async {
        await sampleData();
        final before = await snapshot(db);
        final json = await exportBackup(db, now: now);
        validateBackup(json); // file đúng thì không ném lỗi
        expect(
          () => validateBackup(json.replaceFirst('155000', '999')),
          throwsA(isA<BackupFormatException>()),
        );
        expect(
          () => validateBackup('không phải json'),
          throwsA(isA<BackupFormatException>()),
        );
        expect(await snapshot(db), before);
      },
    );

    test('xuất rồi khôi phục vào máy khác ra đúng dữ liệu', () async {
      await sampleData();
      final json = await exportBackup(db, now: now);
      final root = jsonDecode(json) as Map<String, dynamic>;
      expect((root['format'], root['version']), ('vigon-backup', 1));

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      expect(await snapshot(other), await snapshot(db));
    });

    test(
      'file bị sửa (mã băm sai) thì báo lỗi, dữ liệu hiện có giữ nguyên',
      () async {
        await sampleData();
        final before = await snapshot(db);
        final json = await exportBackup(db, now: now);
        final edited = json.replaceFirst('155000', '999');
        await expectLater(
          importBackup(db, edited),
          throwsA(isA<BackupFormatException>()),
        );
        expect(await snapshot(db), before);
      },
    );

    test(
      'không phải JSON, sai định dạng, phiên bản mới hơn: báo lỗi',
      () async {
        final json = await exportBackup(db, now: now);
        final root = jsonDecode(json) as Map<String, dynamic>;
        for (final bad in [
          'abc',
          jsonEncode({...root, 'format': 'other'}),
          jsonEncode({...root, 'version': 99}),
        ]) {
          await expectLater(
            importBackup(db, bad),
            throwsA(isA<BackupFormatException>()),
          );
        }
      },
    );

    test(
      'dữ liệu sai bên trong (khóa ngoại hỏng) thì quay lui, giữ dữ liệu cũ',
      () async {
        await sampleData();
        final before = await snapshot(db);
        final json = await exportBackup(db, now: now);
        final broken = tamper(
          json,
          (t) => (t['entries'] as List).first['accountId'] = 999,
        );
        await expectLater(
          importBackup(db, broken),
          throwsA(isA<BackupFormatException>()),
        );
        expect(await snapshot(db), before);
      },
    );

    test('số tiền âm trong file bị từ chối', () async {
      await sampleData();
      final json = await exportBackup(db, now: now);
      final broken = tamper(
        json,
        (t) => (t['entries'] as List).first['amount'] = -5,
      );
      await expectLater(
        importBackup(db, broken),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('xuất CSV (AC-30)', () {
    test(
      'UTF-8 có BOM, đủ cột, chữ Việt, dấu ngoặc kép, chặn công thức',
      () async {
        final entries = [
          Entry(
            id: 2,
            type: EntryType.expense,
            amount: 155000,
            categoryId: 1,
            accountId: 1,
            toAccountId: null,
            date: '2026-11-03',
            note: 'phở, "bò"',
            recurringRuleId: null,
            createdAt: now,
          ),
          Entry(
            id: 1,
            type: EntryType.income,
            amount: 5,
            categoryId: 11,
            accountId: 1,
            toAccountId: null,
            date: '2026-11-01',
            note: '=1+1',
            recurringRuleId: null,
            createdAt: now,
          ),
        ];
        final csv = exportCsv(
          entries: entries,
          currency: 'VND',
          decimalDigits: 0,
          categoryName: (id) => id == 1 ? 'Ăn uống' : 'Lương',
          accountName: (id) => 'Tiền mặt',
        );
        expect(csv.startsWith('﻿'), isTrue);
        final lines = csv.substring(1).trim().split('\r\n');
        expect(
          lines[0],
          'date,type,amount,currency,category,account,to_account,note',
        );
        expect(lines[1], "2026-11-01,income,5,VND,Lương,Tiền mặt,,'=1+1");
        expect(
          lines[2],
          '2026-11-03,expense,155000,VND,Ăn uống,Tiền mặt,,"phở, ""bò"""',
        );
      },
    );

    test('tiền có phần lẻ ghi dấu chấm', () {
      final csv = exportCsv(
        entries: [
          Entry(
            id: 1,
            type: EntryType.expense,
            amount: 1250,
            categoryId: 1,
            accountId: 1,
            toAccountId: null,
            date: '2026-11-03',
            note: null,
            recurringRuleId: null,
            createdAt: now,
          ),
        ],
        currency: 'USD',
        decimalDigits: 2,
        categoryName: (_) => 'Food',
        accountName: (_) => 'Cash',
      );
      expect(csv, contains(',12.50,USD,'));
    });
  });

  test('xóa toàn bộ dữ liệu thì như mới cài (AC-42)', () async {
    await sampleData();
    await deleteAllData(db);
    expect(await db.select(db.entries).get(), isEmpty);
    expect(await db.select(db.recurringRules).get(), isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);
    final accounts = await db.select(db.accounts).get();
    expect(accounts.single.nameKey, 'cash');
    expect(accounts.single.id, 1);
    expect(await db.select(db.categories).get(), hasLength(13));
  });
}
