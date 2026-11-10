import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/dates.dart';
import 'package:vigon/src/data/recurring_repository.dart';
import 'package:vigon/src/data/repeat.dart';

// 2026-11-09 là thứ Hai, 2026-11-10 thứ Ba, 2026-11-11 thứ Tư.
final monTue = weekdayBit(DateTime.monday) | weekdayBit(DateTime.tuesday);

void main() {
  group('Repeat — "Chọn thứ" (F-45)', () {
    test('chọn đủ 7 thứ = Hằng ngày', () {
      final r = Repeat.days(allWeekdaysMask);
      expect(r, const Repeat(RecurrenceFrequency.daily));
      expect(r.isPickDays, isFalse);
    });

    test('thứ chọn được giữ ở hằng tuần', () {
      final r = Repeat.days(monTue);
      expect((r.frequency, r.weekdays), (RecurrenceFrequency.weekly, monTue));
      expect(r.isPickDays, isTrue);
    });

    test('mask rỗng hoặc ngoài hằng tuần thì bỏ qua', () {
      expect(
        Repeat.from(RecurrenceFrequency.weekly, 0),
        const Repeat(RecurrenceFrequency.weekly),
      );
      expect(
        Repeat.from(RecurrenceFrequency.monthly, monTue),
        const Repeat(RecurrenceFrequency.monthly),
      );
    });

    test('ngày tới hạn chỉ là các thứ đã chọn, từ ngày bắt đầu', () {
      final days = Repeat.days(monTue)
          .occurrences(DateTime(2026, 11, 11))
          .take(4)
          .map(dateKey)
          .toList();
      expect(days, ['2026-11-16', '2026-11-17', '2026-11-23', '2026-11-24']);
    });

    test('ngày bắt đầu thuộc thứ đã chọn thì là lần đầu', () {
      expect(
        dateKey(Repeat.days(monTue).firstOn(DateTime(2026, 11, 10))),
        '2026-11-10',
      );
      expect(
        dateKey(Repeat.days(monTue).firstOn(DateTime(2026, 11, 11))),
        '2026-11-16',
      );
    });
  });

  group('chuỗi "Chọn thứ" trong cơ sở dữ liệu', () {
    late AppDatabase db;
    late RecurringRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = RecurringRepository(db);
    });
    tearDown(() => db.close());

    EntriesCompanion first(String date) => EntriesCompanion.insert(
      type: EntryType.expense,
      amount: 30000,
      categoryId: const Value(1),
      accountId: 1,
      date: date,
      note: const Value('cà phê'),
    );

    Future<List<String>> dates() async =>
        (await (db.select(
              db.entries,
            )..orderBy([(e) => OrderingTerm(expression: e.date)])).get())
            .map((e) => e.date)
            .toList();

    test(
      'ngày khoản không thuộc thứ đã chọn: KHÔNG ghi khoản hôm nay (D-040)',
      () async {
        final id = await repo.addWithRepeat(
          first('2026-11-11'), // thứ Tư
          RecurrenceFrequency.weekly,
          weekdays: monTue,
        );
        expect(await dates(), isEmpty);
        final rule = (await repo.find(id))!;
        expect(
          (rule.startDate, rule.lastGeneratedDate, rule.weekdays),
          ('2026-11-11', '2026-11-10', monTue),
        );
        expect(dateKey(RecurringRepository.nextDate(rule)), '2026-11-16');

        expect(await repo.generateDue(DateTime(2026, 11, 11, 20)), 0);
        expect(await repo.generateDue(DateTime(2026, 11, 17, 8)), 2);
        expect(await dates(), ['2026-11-16', '2026-11-17']);
        final all = await db.select(db.entries).get();
        expect(all.every((e) => e.recurringRuleId == id), isTrue);
      },
    );

    test('ngày khoản thuộc thứ đã chọn: ghi khoản đó như cũ', () async {
      await repo.addWithRepeat(
        first('2026-11-09'), // thứ Hai
        RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      expect(await dates(), ['2026-11-09']);
      await repo.generateDue(DateTime(2026, 11, 17));
      expect(await dates(), [
        '2026-11-09',
        '2026-11-10',
        '2026-11-16',
        '2026-11-17',
      ]);
    });

    test('ngày bắt đầu ở quá khứ: sinh bù đúng các thứ đã chọn', () async {
      await repo.addWithRepeat(
        first('2026-11-04'), // thứ Tư tuần trước
        RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      await repo.generateDue(DateTime(2026, 11, 11));
      expect(await dates(), ['2026-11-09', '2026-11-10']);
    });

    test('đủ 7 thứ lưu thành Hằng ngày', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-11'),
        RecurrenceFrequency.weekly,
        weekdays: allWeekdaysMask,
      );
      final rule = (await repo.find(id))!;
      expect(
        (rule.frequency, rule.weekdays),
        (RecurrenceFrequency.daily, null),
      );
      expect(await dates(), ['2026-11-11']);
    });

    test('sửa Hằng tuần sang thứ: bắt đầu lại từ ngày tới hạn cũ, không sinh bù (R4)', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-03'), // thứ Ba
        RecurrenceFrequency.weekly,
      );
      // Ngày tới hạn kế tiếp theo lịch cũ: 10/11.
      final fri = weekdayBit(DateTime.monday) | weekdayBit(DateTime.friday);
      await repo.edit(
        id,
        amount: 30000,
        frequency: RecurrenceFrequency.weekly,
        weekdays: fri,
      );
      final r = (await repo.find(id))!;
      expect(
        (r.startDate, r.lastGeneratedDate, r.weekdays),
        ('2026-11-10', '2026-11-09', fri),
      );
      await repo.generateDue(DateTime(2026, 11, 16));
      expect(await dates(), ['2026-11-03', '2026-11-13', '2026-11-16']);
    });

    test('sửa mà giữ nguyên thứ thì không bắt đầu lại', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-09'),
        RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      await repo.edit(
        id,
        amount: 40000,
        frequency: RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      final r = (await repo.find(id))!;
      expect((r.startDate, r.lastGeneratedDate), ('2026-11-09', '2026-11-09'));
    });

    test('sửa thứ về Hằng tháng thì bỏ thứ', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-09'),
        RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      await repo.edit(
        id,
        amount: 30000,
        frequency: RecurrenceFrequency.monthly,
      );
      final r = (await repo.find(id))!;
      expect((r.frequency, r.weekdays), (RecurrenceFrequency.monthly, null));
    });

    test('sao lưu giữ thứ đã chọn; file cũ không có trường → null', () async {
      await repo.addWithRepeat(
        first('2026-11-09'),
        RecurrenceFrequency.weekly,
        weekdays: monTue,
      );
      final json = await exportBackup(db, now: DateTime(2026, 11, 10));

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      expect(
        (await other.select(other.recurringRules).getSingle()).weekdays,
        monTue,
      );

      // File của bản trước (schema 5) không có `weekdays`.
      final root = jsonDecode(json) as Map<String, dynamic>;
      final tables = root['tables'] as Map<String, dynamic>;
      for (final r in tables['recurringRules'] as List) {
        (r as Map<String, dynamic>).remove('weekdays');
      }
      root['schemaVersion'] = 5;
      root['checksum'] = sha256
          .convert(utf8.encode(jsonEncode(tables)))
          .toString();
      final old = AppDatabase(NativeDatabase.memory());
      addTearDown(old.close);
      await importBackup(old, jsonEncode(root));
      expect(
        (await old.select(old.recurringRules).getSingle()).weekdays,
        isNull,
      );
    });
  });

  test('migration schema 5 → 6: thêm cột thứ, chuỗi cũ giữ nguyên', () async {
    final dir = Directory.systemTemp.createTempSync('vigon_v6_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    // Dựng một DB schema 5: tạo bản hiện tại rồi bỏ cột mới, hạ user_version.
    final fresh = AppDatabase(NativeDatabase(file));
    await RecurringRepository(fresh).addWithRepeat(
      EntriesCompanion.insert(
        type: EntryType.expense,
        amount: 30000,
        categoryId: const Value(1),
        accountId: 1,
        date: '2026-11-03',
      ),
      RecurrenceFrequency.weekly,
    );
    await fresh.customStatement(
      'ALTER TABLE recurring_rules DROP COLUMN weekdays',
    );
    await fresh.customStatement(
      'ALTER TABLE savings_goals DROP COLUMN completed_at',
    );
    await fresh.customStatement('PRAGMA user_version = 5');
    await fresh.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final rule = await db.select(db.recurringRules).getSingle();
    expect(
      (rule.frequency, rule.weekdays, rule.startDate),
      (RecurrenceFrequency.weekly, null, '2026-11-03'),
    );
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), currentSchemaVersion);
    expect(currentSchemaVersion, greaterThanOrEqualTo(6));
  });
}
