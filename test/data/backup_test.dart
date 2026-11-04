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

  group('CSV theo ngôn ngữ (AC-52)', () {
    const vi = CsvFormat(
      delimiter: ';',
      decimalSeparator: ',',
      header: [
        'Ngày',
        'Loại',
        'Số tiền',
        'Tiền tệ',
        'Danh mục',
        'Tài khoản',
        'Đến tài khoản',
        'Ghi chú',
      ],
      expense: 'Chi',
      income: 'Thu',
      transfer: 'Chuyển tiền',
    );

    Entry entry(
      int id,
      EntryType type,
      int amount, {
      String? note,
      int? to,
      String date = '2026-11-03',
    }) => Entry(
      id: id,
      type: type,
      amount: amount,
      categoryId: type == EntryType.transfer ? null : 1,
      accountId: 1,
      toAccountId: to,
      date: date,
      note: note,
      recurringRuleId: null,
      createdAt: now,
    );

    String build(
      List<Entry> entries,
      CsvFormat format, {
      String currency = 'VND',
      int digits = 0,
    }) => exportCsv(
      entries: entries,
      currency: currency,
      decimalDigits: digits,
      format: format,
      categoryName: (_) => 'Ăn uống',
      accountName: (id) => id == 1 ? 'Tiền mặt' : 'Thẻ',
    ).substring(1).trim().split('\r\n').join('\n');

    test('tiếng Việt: tiêu đề, loại và dấu ngăn cột tiếng Việt', () {
      final csv = exportCsv(
        entries: [
          entry(1, EntryType.expense, 155000),
          entry(2, EntryType.income, 5000000, date: '2026-11-04'),
          entry(3, EntryType.transfer, 20000, to: 2, date: '2026-11-05'),
        ],
        currency: 'VND',
        decimalDigits: 0,
        format: vi,
        categoryName: (_) => 'Ăn uống',
        accountName: (id) => id == 1 ? 'Tiền mặt' : 'Thẻ',
      );
      expect(csv.startsWith('﻿'), isTrue);
      final lines = csv.substring(1).trim().split('\r\n');
      expect(
        lines[0],
        'Ngày;Loại;Số tiền;Tiền tệ;Danh mục;Tài khoản;Đến tài khoản;Ghi chú',
      );
      expect(lines[1], '2026-11-03;Chi;155000;VND;Ăn uống;Tiền mặt;;');
      expect(lines[2], '2026-11-04;Thu;5000000;VND;Ăn uống;Tiền mặt;;');
      expect(lines[3], '2026-11-05;Chuyển tiền;20000;VND;;Tiền mặt;Thẻ;');
    });

    test('tiếng Anh: tiêu đề và loại tiếng Anh, dấu phẩy và dấu chấm', () {
      final out = build(
        [
          entry(1, EntryType.expense, 1250),
          entry(2, EntryType.transfer, 5, to: 2, date: '2026-11-04'),
        ],
        CsvFormat.forLanguage(
          'en',
          header: CsvFormat.english.header,
          expense: 'expense',
          income: 'income',
          transfer: 'transfer',
        ),
        currency: 'USD',
        digits: 2,
      ).split('\n');
      expect(
        out[0],
        'date,type,amount,currency,category,account,to_account,note',
      );
      expect(out[1], '2026-11-03,expense,12.50,USD,Ăn uống,Tiền mặt,,');
      expect(out[2], '2026-11-04,transfer,0.05,USD,,Tiền mặt,Thẻ,');
    });

    test('forLanguage chọn dấu theo ngôn ngữ', () {
      CsvFormat f(String lang) => CsvFormat.forLanguage(
        lang,
        header: CsvFormat.english.header,
        expense: 'e',
        income: 'i',
        transfer: 't',
      );
      expect((f('vi').delimiter, f('vi').decimalSeparator), (';', ','));
      expect((f('en').delimiter, f('en').decimalSeparator), (',', '.'));
    });

    test('tiếng Việt: tiền có phần lẻ dùng dấu phẩy, VND không có phần lẻ', () {
      final usd = build(
        [entry(1, EntryType.expense, 1250)],
        vi,
        currency: 'USD',
        digits: 2,
      );
      expect(usd, contains(';Chi;12,50;USD;'));
      final kwd = build(
        [entry(1, EntryType.expense, 12005)],
        vi,
        currency: 'KWD',
        digits: 3,
      );
      expect(kwd, contains(';12,005;KWD;'));
      final vnd = build([entry(1, EntryType.expense, 1250)], vi);
      expect(vnd, contains(';Chi;1250;VND;'));
      // Phần lẻ nhỏ hơn một đơn vị vẫn đủ số 0 đứng trước.
      expect(
        build([entry(1, EntryType.expense, 5)], vi, currency: 'USD', digits: 2),
        contains(';0,05;USD;'),
      );
    });

    test('ghi chú chứa dấu chấm phẩy và dấu phẩy được đặt trong ngoặc kép', () {
      final viOut = build([
        entry(1, EntryType.expense, 100, note: 'a; b, c'),
      ], vi);
      expect(viOut, endsWith(';"a; b, c"'));
      final enOut = build([
        entry(1, EntryType.expense, 100, note: 'a; b, c'),
      ], CsvFormat.english);
      expect(enOut, endsWith(',"a; b, c"'));
      // Ngoặc kép bên trong được nhân đôi; xuống dòng cũng được bao ngoặc kép.
      final quote = exportCsv(
        entries: [entry(1, EntryType.expense, 100, note: 'dòng 1\n"x"')],
        currency: 'VND',
        decimalDigits: 0,
        format: vi,
        categoryName: (_) => 'c',
        accountName: (_) => 'a',
      );
      expect(quote, contains(';"dòng 1\n""x"""'));
    });

    test('chặn chèn công thức ở cả hai ngôn ngữ', () {
      for (final format in [vi, CsvFormat.english]) {
        for (final bad in ['=1+1', '+1', '-1', '@SUM(A1)']) {
          final out = build([
            entry(1, EntryType.expense, 1, note: bad),
          ], format);
          expect(out, endsWith("'$bad"));
        }
      }
      // Ghi chú có dấu ngăn vừa là công thức: thêm dấu ' rồi bao ngoặc kép.
      expect(
        build([entry(1, EntryType.expense, 1, note: '=a;b')], vi),
        endsWith('"\'=a;b"'),
      );
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
