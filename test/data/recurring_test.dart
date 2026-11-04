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

    group('sửa tần suất, danh mục, tài khoản (AC-50)', () {
      Future<List<Entry>> all() => (db.select(
        db.entries,
      )..orderBy([(e) => OrderingTerm(expression: e.date)])).get();

      test('chỉ đổi số tiền: giữ nguyên lịch, danh mục, tài khoản', () async {
        final id = await repo.addWithRepeat(
          first('2026-11-03'),
          RecurrenceFrequency.monthly,
        );
        await repo.edit(id, amount: 5, note: null);
        final r = (await repo.find(id))!;
        expect(
          (
            r.amount,
            r.frequency,
            r.startDate,
            r.lastGeneratedDate,
            r.categoryId,
            r.accountId,
          ),
          (5, RecurrenceFrequency.monthly, '2026-11-03', '2026-11-03', 3, 1),
        );
      });

      test(
        'tháng sang tuần: bắt đầu lại từ ngày tới hạn cũ, không trùng',
        () async {
          final id = await repo.addWithRepeat(
            first('2026-10-03'),
            RecurrenceFrequency.monthly,
          );
          // Lịch cũ đã sinh 03/10, ngày tới hạn kế tiếp là 03/11.
          await repo.edit(
            id,
            amount: 100000,
            frequency: RecurrenceFrequency.weekly,
          );
          final r = (await repo.find(id))!;
          expect(
            (r.frequency, r.startDate, r.lastGeneratedDate),
            (RecurrenceFrequency.weekly, '2026-11-03', '2026-11-02'),
          );
          expect(dateKey(RecurringRepository.nextDate(r)), '2026-11-03');
          // Lần sinh đầu theo tuần chính là ngày tới hạn cũ; không sinh bù tháng trước.
          expect(await repo.generateDue(DateTime(2026, 11, 18)), 3);
          expect(await repo.generateDue(DateTime(2026, 11, 18)), 0);
          expect((await all()).map((e) => e.date), [
            '2026-10-03',
            '2026-11-03',
            '2026-11-10',
            '2026-11-17',
          ]);
        },
      );

      test('tuần sang tháng', () async {
        final id = await repo.addWithRepeat(
          first('2026-11-03'),
          RecurrenceFrequency.weekly,
        );
        await repo.generateDue(DateTime(2026, 11, 12)); // sinh thêm 10/11
        await repo.edit(
          id,
          amount: 100000,
          frequency: RecurrenceFrequency.monthly,
        );
        final r = (await repo.find(id))!;
        expect(
          (r.startDate, r.lastGeneratedDate),
          ('2026-11-17', '2026-11-16'),
        );
        expect(await repo.generateDue(DateTime(2027, 1, 20)), 3);
        expect(await repo.generateDue(DateTime(2027, 1, 20)), 0);
        expect((await all()).map((e) => e.date), [
          '2026-11-03',
          '2026-11-10',
          '2026-11-17',
          '2026-12-17',
          '2027-01-17',
        ]);
      });

      test('đổi sang cùng tần suất hiện có thì không dời lịch', () async {
        final id = await repo.addWithRepeat(
          first('2026-11-03'),
          RecurrenceFrequency.weekly,
        );
        await repo.edit(id, amount: 1, frequency: RecurrenceFrequency.weekly);
        final r = (await repo.find(id))!;
        expect(
          (r.startDate, r.lastGeneratedDate),
          ('2026-11-03', '2026-11-03'),
        );
      });

      test(
        'đổi danh mục và tài khoản chỉ ảnh hưởng các lần sinh sau',
        () async {
          final id = await repo.addWithRepeat(
            first('2026-11-01'),
            RecurrenceFrequency.daily,
          );
          final other = await db
              .into(db.accounts)
              .insert(AccountsCompanion.insert(name: const Value('Thẻ')));
          await repo.generateDue(DateTime(2026, 11, 2));
          await repo.edit(id, amount: 100000, categoryId: 4, accountId: other);
          await repo.generateDue(DateTime(2026, 11, 3));
          expect(
            (await all()).map((e) => (e.date, e.categoryId, e.accountId)),
            [
              ('2026-11-01', 3, 1),
              ('2026-11-02', 3, 1),
              ('2026-11-03', 4, other),
            ],
          );
        },
      );

      test('chuỗi đang dừng vẫn sửa được; chạy lại theo cài đặt mới', () async {
        final id = await repo.addWithRepeat(
          first('2026-11-03'),
          RecurrenceFrequency.monthly,
        );
        await repo.stop(id);
        await repo.edit(
          id,
          amount: 7,
          frequency: RecurrenceFrequency.weekly,
          categoryId: 4,
        );
        final r = (await repo.find(id))!;
        expect(
          (r.active, r.amount, r.frequency, r.categoryId, r.startDate),
          (false, 7, RecurrenceFrequency.weekly, 4, '2026-12-03'),
        );
        expect(await repo.generateDue(DateTime(2027, 1, 1)), 0);
        await repo.resume(id, DateTime(2026, 12, 20));
        await repo.generateDue(DateTime(2026, 12, 25));
        // Tuần bắt đầu 03/12: 24/12 là lần đầu từ ngày chạy lại 20/12.
        expect((await all()).map((e) => (e.date, e.amount)), [
          ('2026-11-03', 100000),
          ('2026-12-24', 7),
        ]);
      });
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
