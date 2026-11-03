import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/dates.dart';
import 'package:vigon/src/data/recurring_repository.dart';

void main() {
  group('lần lặp tính từ ngày bắt đầu (AC-23)', () {
    String at(String start, RecurrenceFrequency f, int n) =>
        dateKey(occurrence(parseDateKey(start), f, n));

    test('hằng tháng từ ngày 31 không trôi sau tháng ngắn', () {
      const f = RecurrenceFrequency.monthly;
      expect(at('2026-01-31', f, 1), '2026-02-28');
      expect(at('2026-01-31', f, 2), '2026-03-31');
      expect(at('2026-01-31', f, 3), '2026-04-30');
      expect(at('2026-01-31', f, 12), '2027-01-31');
    });

    test('hằng năm từ 29/2', () {
      const f = RecurrenceFrequency.yearly;
      expect(at('2028-02-29', f, 1), '2029-02-28');
      expect(at('2028-02-29', f, 4), '2032-02-29');
    });

    test('hằng ngày, hằng tuần', () {
      expect(at('2026-12-30', RecurrenceFrequency.daily, 3), '2027-01-02');
      expect(at('2026-11-03', RecurrenceFrequency.weekly, 2), '2026-11-17');
    });
  });

  group('chuỗi định kỳ trong cơ sở dữ liệu', () {
    late AppDatabase db;
    late RecurringRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = RecurringRepository(db);
    });
    tearDown(() => db.close());

    EntriesCompanion first(String date, {int amount = 100000}) =>
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          categoryId: const Value(3),
          accountId: 1,
          date: date,
          note: const Value('tiền nhà'),
        );

    Future<List<String>> dates() async =>
        (await (db.select(
              db.entries,
            )..orderBy([(e) => OrderingTerm(expression: e.date)])).get())
            .map((e) => e.date)
            .toList();

    test('ghi khoản đầu và tạo chuỗi gắn với khoản đó', () async {
      final ruleId = await repo.addWithRepeat(
        first('2026-11-03'),
        RecurrenceFrequency.monthly,
      );
      final entry = await db.select(db.entries).getSingle();
      expect(entry.recurringRuleId, ruleId);
      final rule = (await repo.find(ruleId))!;
      expect(
        (rule.startDate, rule.lastGeneratedDate, rule.active),
        ('2026-11-03', '2026-11-03', true),
      );
    });

    test('mở app sau khi tới hạn thì tạo đủ khoản còn thiếu, không trùng khi mở lại (AC-24)', () async {
      await repo.addWithRepeat(first('2026-11-01'), RecurrenceFrequency.daily);
      expect(await repo.generateDue(DateTime(2026, 11, 3, 8)), 2);
      expect(await repo.generateDue(DateTime(2026, 11, 3, 20)), 0);
      expect(await dates(), ['2026-11-01', '2026-11-02', '2026-11-03']);
      final all = await db.select(db.entries).get();
      expect(
        all.every((e) => e.amount == 100000 && e.note == 'tiền nhà'),
        isTrue,
      );
    });

    test('ngày bắt đầu ở quá khứ thì tạo bù các tháng đã qua', () async {
      await repo.addWithRepeat(
        first('2026-08-31'),
        RecurrenceFrequency.monthly,
      );
      await repo.generateDue(DateTime(2026, 11, 3));
      expect(await dates(), ['2026-08-31', '2026-09-30', '2026-10-31']);
    });

    test('dừng chuỗi: không tạo thêm, khoản cũ giữ nguyên (AC-25)', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-01'),
        RecurrenceFrequency.daily,
      );
      await repo.generateDue(DateTime(2026, 11, 2));
      await repo.stop(id);
      expect(await repo.generateDue(DateTime(2026, 11, 10)), 0);
      expect(await dates(), ['2026-11-01', '2026-11-02']);
    });

    test('sửa số tiền chỉ áp dụng cho các lần sau (AC-25)', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-01'),
        RecurrenceFrequency.daily,
      );
      await repo.generateDue(DateTime(2026, 11, 2));
      await repo.edit(id, amount: 120000, note: 'tăng giá');
      await repo.generateDue(DateTime(2026, 11, 3));
      final amounts =
          (await (db.select(
                db.entries,
              )..orderBy([(e) => OrderingTerm(expression: e.date)])).get())
              .map((e) => e.amount)
              .toList();
      expect(amounts, [100000, 100000, 120000]);
    });

    test('chạy lại sau khi dừng thì không tạo bù các ngày đã lỡ', () async {
      final id = await repo.addWithRepeat(
        first('2026-11-01'),
        RecurrenceFrequency.daily,
      );
      await repo.stop(id);
      await repo.resume(id, DateTime(2026, 11, 10));
      await repo.generateDue(DateTime(2026, 11, 11));
      expect(await dates(), ['2026-11-01', '2026-11-10', '2026-11-11']);
    });

    test('ngày tới hạn kế tiếp', () async {
      final id = await repo.addWithRepeat(
        first('2026-01-31'),
        RecurrenceFrequency.monthly,
      );
      expect(
        dateKey(RecurringRepository.nextDate((await repo.find(id))!)),
        '2026-02-28',
      );
    });
  });
}
