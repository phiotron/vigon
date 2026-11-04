import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';

void main() {
  late AppDatabase db;
  late AccountRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AccountRepository(db);
  });
  tearDown(() => db.close());

  Future<void> addEntry({
    required int accountId,
    int? toAccountId,
    EntryType type = EntryType.expense,
    int amount = 1000,
  }) => db
      .into(db.entries)
      .insert(
        EntriesCompanion.insert(
          type: type,
          amount: amount,
          categoryId: type == EntryType.transfer
              ? const Value(null)
              : const Value(1),
          accountId: accountId,
          toAccountId: Value(toAccountId),
          date: '2026-11-03',
        ),
      );

  test('ẩn và hiện lại; số dư tài khoản ẩn vẫn đúng (AC-44, AC-47)', () async {
    final card = await repo.add(name: 'Thẻ', initialBalance: 5000);
    await addEntry(accountId: card, amount: 1500);
    expect(await repo.archive(card), isNull);
    expect((await repo.watch().first).map((a) => a.id), [1]);
    expect((await repo.watchAll().first).map((a) => a.id), [1, card]);
    expect((await repo.watchArchived().first).map((a) => a.id), [card]);
    expect((await repo.watchBalances().first)[card], 3500);
    await repo.unarchive(card);
    expect((await repo.watch().first).map((a) => a.id), [1, card]);
    expect(await repo.watchArchived().first, isEmpty);
  });

  test('không ẩn, không xóa tài khoản hiện cuối cùng (AC-46)', () async {
    expect(await repo.archive(1), AccountBlock.lastVisible);
    expect(await repo.delete(1), AccountBlock.lastVisible);
    expect((await repo.watch().first).length, 1);
    // Còn một tài khoản hiện khác nhưng đã ẩn thì tài khoản kia vẫn là cuối cùng.
    final card = await repo.add(name: 'Thẻ');
    expect(await repo.archive(card), isNull);
    expect(await repo.archive(1), AccountBlock.lastVisible);
    expect(await repo.delete(1), AccountBlock.lastVisible);
  });

  test('chỉ xóa khi chưa có khoản đi, đến hay chuỗi định kỳ (AC-45)', () async {
    final a = await repo.add(name: 'Chỉ nhận chuyển');
    final b = await repo.add(name: 'Chỉ có chuỗi định kỳ');
    final c = await repo.add(name: 'Trống');
    await addEntry(accountId: 1, toAccountId: a, type: EntryType.transfer);
    await db
        .into(db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            type: EntryType.expense,
            amount: 100,
            categoryId: const Value(1),
            accountId: b,
            frequency: RecurrenceFrequency.monthly,
            startDate: '2026-11-01',
          ),
        );
    expect(await repo.isInUse(a), isTrue);
    expect(await repo.isInUse(b), isTrue);
    expect(await repo.isInUse(c), isFalse);
    expect(await repo.delete(a), AccountBlock.inUse);
    expect(await repo.delete(b), AccountBlock.inUse);
    expect(await repo.delete(c), isNull);
    expect((await repo.watchAll().first).map((x) => x.id), [1, a, b]);
  });

  test('sao lưu rồi khôi phục giữ trạng thái ẩn (AC-44)', () async {
    final card = await repo.add(name: 'Thẻ', initialBalance: 700);
    await addEntry(accountId: card);
    await repo.archive(card);
    final json = await exportBackup(db, now: DateTime(2026, 11, 4));
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await importBackup(other, json);
    final r = AccountRepository(other);
    expect((await r.watch().first).map((a) => a.id), [1]);
    expect((await r.watchArchived().first).map((a) => a.id), [card]);
  });

  test('theo dõi được việc tài khoản có khoản hay chưa', () async {
    final card = await repo.add(name: 'Thẻ');
    final inUse = repo.watchInUse(card);
    expectLater(inUse, emitsInOrder([false, true]));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await addEntry(accountId: card);
  });
}
