import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/recurring_repository.dart';
import 'package:vigon/src/data/settings_repository.dart';

/// Chặn các lỗi do kiểm chứng độc lập tìm ra ở bản 1.1 (B1, B4, B8, B9).
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('đổi tiền tệ quy đổi cả hạn mức danh mục (F-20, AC-53, D-025)', () {
    Future<int?> budgetOfFood() async => (await (db.select(
      db.categories,
    )..where((c) => c.id.equals(1))).getSingle()).budget;
    ExchangeRate rate(String r) => ExchangeRate.tryParse(r)!;

    test('VND sang USD rồi về VND theo tỉ giá ngược', () async {
      await SettingsRepository(db).ensureCurrency('vi_VN');
      await CategoryRepository(db).setBudget(1, 500000);
      await convertCurrency(db, 'USD', rate('0.00004'));
      expect(await budgetOfFood(), 2000); // 500.000 ₫ → 20,00 US$
      await convertCurrency(db, 'VND', rate('25000'));
      expect(await budgetOfFood(), 500000);
    });

    test('hạn mức chưa đặt vẫn là null', () async {
      await SettingsRepository(db).ensureCurrency('vi_VN');
      await CategoryRepository(db).setBudget(1, 500000);
      await convertCurrency(db, 'KWD', rate('0.0000118'));
      expect(await budgetOfFood(), 5900);
      final other = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(2))).getSingle();
      expect(other.budget, isNull);
    });

    test('làm tròn nhưng không về 0 (ràng buộc budget > 0)', () async {
      await SettingsRepository(db).ensureCurrency('en_US');
      await CategoryRepository(db).setBudget(1, 1); // 0,01 USD
      await convertCurrency(db, 'JPY', rate('0.1')); // 0,001 ¥ → 0
      expect(await budgetOfFood(), 1);
    });
  });

  group('chạy lại chuỗi định kỳ không sinh trùng (BUG chuỗi hằng ngày)', () {
    test('tắt rồi bật cùng ngày với khoản đã sinh: không thêm khoản', () async {
      final repo = RecurringRepository(db);
      final today = DateTime(2026, 11, 3);
      final ruleId = await repo.addWithRepeat(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 100000,
          categoryId: const Value(1),
          accountId: 1,
          date: '2026-11-03',
        ),
        RecurrenceFrequency.daily,
      );
      await repo.generateDue(today);
      expect((await db.select(db.entries).get()).length, 1);
      await repo.stop(ruleId);
      await repo.resume(ruleId, today);
      await repo.generateDue(today);
      await repo.generateDue(today);
      expect((await db.select(db.entries).get()).length, 1);
      // Hôm sau vẫn sinh đúng một khoản.
      await repo.generateDue(DateTime(2026, 11, 4));
      expect((await db.select(db.entries).get()).length, 2);
    });

    test('chuỗi dừng nhiều ngày rồi bật lại: không sinh bù', () async {
      final repo = RecurringRepository(db);
      final ruleId = await repo.addWithRepeat(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 100000,
          categoryId: const Value(1),
          accountId: 1,
          date: '2026-11-03',
        ),
        RecurrenceFrequency.daily,
      );
      await repo.stop(ruleId);
      await repo.resume(ruleId, DateTime(2026, 11, 10));
      await repo.generateDue(DateTime(2026, 11, 10));
      // Khoản đầu 03/11 và đúng một khoản của 10/11, không lấp 04..09/11.
      expect((await db.select(db.entries).get()).length, 2);
    });
  });

  group('CSV chặn công thức cả khi ô bắt đầu bằng tab hoặc xuống dòng', () {
    String csvWithNote(String note) {
      final e = Entry(
        id: 1,
        type: EntryType.expense,
        amount: 1000,
        categoryId: 1,
        accountId: 1,
        toAccountId: null,
        date: '2026-11-03',
        note: note,
        recurringRuleId: null,
        source: EntrySource.manual,
        createdAt: DateTime(2026),
      );
      return exportCsv(
        entries: [e],
        currency: 'VND',
        decimalDigits: 0,
        categoryName: (_) => 'Ăn uống',
        accountName: (_) => 'Tiền mặt',
      );
    }

    test('= + - @ tab CR đều được thêm dấu nháy', () {
      for (final lead in ['=', '+', '-', '@', '\t', '\r']) {
        final csv = csvWithNote('${lead}1+1');
        expect(
          csv.contains("'${lead}1+1"),
          isTrue,
          reason: 'ký tự đầu ${lead.codeUnitAt(0)}',
        );
      }
    });
  });

  group('file sao lưu phải còn tài khoản hiện', () {
    String tamper(
      String json,
      void Function(Map<String, dynamic> tables) edit,
    ) {
      final root = jsonDecode(json) as Map<String, dynamic>;
      final tables = root['tables'] as Map<String, dynamic>;
      edit(tables);
      root['checksum'] = sha256
          .convert(utf8.encode(jsonEncode(tables)))
          .toString();
      return jsonEncode(root);
    }

    test('mọi tài khoản đã ẩn thì bị từ chối, dữ liệu cũ giữ nguyên', () async {
      await AccountRepository(db).add(name: 'Thẻ');
      final json = await exportBackup(db, now: DateTime(2026, 11, 3));
      final bad = tamper(json, (t) {
        for (final a in t['accounts'] as List) {
          (a as Map<String, dynamic>)['archived'] = true;
        }
      });
      expect(() => validateBackup(bad), throwsA(isA<BackupFormatException>()));
      await expectLater(
        importBackup(db, bad),
        throwsA(isA<BackupFormatException>()),
      );
      expect((await db.select(db.accounts).get()).length, 2);
    });
  });
}
