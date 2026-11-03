import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/period.dart';

void main() {
  late AppDatabase db;
  late EntryRepository repo;
  final november = Period.containing(PeriodType.month, DateTime(2026, 11, 3));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EntryRepository(db);
  });
  tearDown(() => db.close());

  Future<int> add(int amount, {String date = '2026-11-03', int account = 1}) =>
      repo.add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          categoryId: const Value(1),
          accountId: account,
          date: date,
        ),
      );

  test('chỉ lấy khoản trong kỳ, mới nhất trước, kèm danh mục', () async {
    await add(1, date: '2026-10-31');
    final a = await add(2, date: '2026-11-01');
    final b = await add(3, date: '2026-11-30');
    await add(4, date: '2026-12-01');
    final rows = await repo.watchEntries(november).first;
    expect(rows.map((r) => r.entry.id), [b, a]);
    expect(rows.first.category?.nameKey, 'food');
  });

  test('sửa khoản thì danh sách cập nhật (AC-13)', () async {
    final id = await add(100);
    final entry = (await repo.find(id))!;
    await repo.update(entry.copyWith(amount: 250, note: const Value('trưa')));
    final rows = await repo.watchEntries(november).first;
    expect(rows.single.entry.amount, 250);
    expect(rows.single.entry.note, 'trưa');
  });

  test('xóa rồi hoàn tác trả lại đúng khoản, giữ id (AC-14)', () async {
    final id = await add(100);
    final before = (await repo.find(id))!;
    final deleted = await repo.delete(id);
    expect(await repo.find(id), isNull);
    await repo.restore(deleted!);
    expect(await repo.find(id), before);
  });
}
