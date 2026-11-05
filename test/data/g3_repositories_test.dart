import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/money.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/data/summary.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;
  late AccountRepository accounts;
  late EntryRepository entries;
  late SettingsRepository settings;
  final all = Period.containing(PeriodType.all, DateTime(2026, 11, 3));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categories = CategoryRepository(db);
    accounts = AccountRepository(db);
    entries = EntryRepository(db);
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  Future<int> expense(int amount, {int category = 1, int account = 1}) =>
      entries.add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          categoryId: Value(category),
          accountId: account,
          date: '2026-11-03',
        ),
      );

  group('danh mục', () {
    test('thêm danh mục xếp cuối loại của nó (AC-16)', () async {
      final id = await categories.add(
        type: CategoryType.expense,
        name: 'Cà phê',
        icon: 'local_cafe',
        color: 0xFF5D4037,
      );
      final list = await categories.watch(CategoryType.expense).first;
      expect(list.last.id, id);
      expect(list.last.name, 'Cà phê');
      expect(list.last.nameKey, isNull);
    });

    test(
      'đổi tên bỏ tên mặc định; chỉ đổi icon thì giữ tên mặc định (AC-16)',
      () async {
        await categories.edit(1, icon: 'local_cafe', color: 0xFF000000);
        var food = (await categories.watch(CategoryType.expense).first).first;
        expect((food.nameKey, food.icon), ('food', 'local_cafe'));

        await categories.edit(
          1,
          name: 'Ăn ngoài',
          icon: 'restaurant',
          color: 0xFF000000,
        );
        food = (await categories.watch(CategoryType.expense).first).first;
        expect((food.nameKey, food.name), (null, 'Ăn ngoài'));
      },
    );

    test('sắp xếp lại theo thứ tự mới (AC-16)', () async {
      final before = (await categories.watch(CategoryType.expense).first)
          .map((c) => c.id)
          .toList();
      final reversed = before.reversed.toList();
      await categories.reorder(reversed);
      final after = (await categories.watch(CategoryType.expense).first)
          .map((c) => c.id)
          .toList();
      expect(after, reversed);
    });

    test('xóa danh mục chuyển hết khoản sang danh mục khác, không mất khoản (AC-17)', () async {
      await expense(100, category: 1);
      await expense(200, category: 1);
      await expense(300, category: 2);
      expect(await categories.usageCount(1), 2);
      await categories.delete(1, moveTo: 2);
      final rows = await db.select(db.entries).get();
      expect(rows, hasLength(3));
      expect(rows.every((e) => e.categoryId == 2), isTrue);
      final list = await categories.watch(CategoryType.expense).first;
      expect(list.any((c) => c.id == 1), isFalse);
    });
  });

  group('tài khoản và chuyển tiền', () {
    test('thêm tài khoản có số dư ban đầu (AC-18)', () async {
      final card = await accounts.add(name: 'Thẻ', initialBalance: 2000000);
      final b = await accounts.watchBalances().first;
      expect(b[card], 2000000);
      expect(b[1], 0);
    });

    test('chuyển tiền đổi số dư hai tài khoản đúng bằng số tiền, không tính thu chi (AC-19)', () async {
      final card = await accounts.add(name: 'Thẻ', initialBalance: 1000000);
      await entries.addTransfer(
        fromAccountId: card,
        toAccountId: 1,
        amount: 300000,
        date: '2026-11-03',
      );
      final b = await accounts.watchBalances().first;
      expect(b[card], 700000);
      expect(b[1], 300000);
      final s = PeriodSummary.of(await entries.watchEntries(all).first);
      expect((s.income, s.expense), (0, 0));
    });

    test('không cho chuyển cùng một tài khoản', () async {
      expect(
        () => entries.addTransfer(
          fromAccountId: 1,
          toAccountId: 1,
          amount: 1,
          date: '2026-11-03',
        ),
        throwsArgumentError,
      );
    });

    test('số dư tính cả thu, chi', () async {
      await expense(50000);
      await entries.add(
        EntriesCompanion.insert(
          type: EntryType.income,
          amount: 200000,
          categoryId: const Value(11),
          accountId: 1,
          date: '2026-11-03',
        ),
      );
      expect((await accounts.watchBalances().first)[1], 150000);
    });

    test('lọc màn chính theo một tài khoản (AC-20)', () async {
      final card = await accounts.add(name: 'Thẻ');
      await expense(100, account: 1);
      await expense(200, account: card);
      await entries.addTransfer(
        fromAccountId: 1,
        toAccountId: card,
        amount: 5,
        date: '2026-11-03',
      );
      final onlyCard = await entries.watchEntries(all, accountId: card).first;
      expect(onlyCard.map((r) => r.entry.amount).toSet(), {200, 5});
      final everything = await entries.watchEntries(all).first;
      expect(everything, hasLength(3));
    });
  });

  group('tiền tệ', () {
    test(
      'lần đầu chọn theo vùng của máy và giữ nguyên về sau (AC-21)',
      () async {
        expect(await settings.ensureCurrency('vi_VN'), 'VND');
        expect(await settings.ensureCurrency('en_US'), 'VND');
        expect(currencyForLocale('en_US'), 'USD');
        expect(currencyForLocale('ja_JP'), 'JPY');
        expect(currencyForLocale('vi'), 'VND');
        expect(currencyForLocale('en'), 'USD');
      },
    );

    test(
      'đổi VND sang USD giữ con số hiển thị, không quy đổi (AC-21)',
      () async {
        await settings.ensureCurrency('vi_VN');
        await expense(155);
        await accounts.edit(1, name: 'Ví', initialBalance: -20);
        await settings.setBudget(5000000);
        await changeCurrency(db, 'USD');
        expect(await settings.watchCurrency().first, 'USD');
        expect((await db.select(db.entries).getSingle()).amount, 15500);
        expect(
          (await db.select(db.accounts).getSingle()).initialBalance,
          -2000,
        );
        expect(await settings.readBudget(), 500000000);
      },
    );

    test('đổi USD sang VND làm tròn và vẫn lớn hơn 0', () async {
      await settings.ensureCurrency('en_US');
      await expense(1250); // $12.50
      await expense(1); // $0.01
      await changeCurrency(db, 'VND');
      final amounts = (await db.select(db.entries).get())
          .map((e) => e.amount)
          .toList();
      expect(amounts, [13, 1]);
    });

    test(
      'đổi VND sang KWD (0 sang 3 chữ số) giữ con số hiển thị (AC-53)',
      () async {
        await settings.ensureCurrency('vi_VN');
        await expense(155);
        await accounts.edit(1, name: 'Ví', initialBalance: -20);
        await settings.setBudget(5000000);
        await changeCurrency(db, 'KWD');
        expect(await settings.watchCurrency().first, 'KWD');
        // 155 đồng thành 155,000 dinar: số lưu nhân 1000.
        expect((await db.select(db.entries).getSingle()).amount, 155000);
        expect(
          (await db.select(db.accounts).getSingle()).initialBalance,
          -20000,
        );
        expect(await settings.readBudget(), 5000000000);
        expect(
          formatMoney(155000, currencyCode: 'KWD', locale: 'en'),
          contains('155.000'),
        );
      },
    );

    test(
      'đổi KWD sang USD (3 sang 2) và USD sang KWD (2 sang 3) (AC-53)',
      () async {
        await settings.ensureCurrency('en_US');
        await changeCurrency(db, 'KWD');
        await expense(12345); // 12,345 dinar
        await changeCurrency(db, 'USD');
        // Chia 10 và làm tròn: 1235 cent ($12.35).
        expect((await db.select(db.entries).getSingle()).amount, 1235);
        await changeCurrency(db, 'KWD');
        expect((await db.select(db.entries).getSingle()).amount, 12350);
      },
    );

    test('đổi VND sang KWD sang VND giữ nguyên số lớn (AC-53)', () async {
      await settings.ensureCurrency('vi_VN');
      await expense(1234567);
      await changeCurrency(db, 'KWD');
      await changeCurrency(db, 'VND');
      expect((await db.select(db.entries).getSingle()).amount, 1234567);
    });

    test(
      'đổi giữa hai tiền tệ cùng số chữ số không đổi số lưu (AC-53)',
      () async {
        await settings.ensureCurrency('vi_VN');
        await expense(155);
        await changeCurrency(db, 'JPY'); // 0 -> 0
        expect((await db.select(db.entries).getSingle()).amount, 155);
        await changeCurrency(db, 'USD'); // 0 -> 2
        await changeCurrency(db, 'EUR'); // 2 -> 2
        expect((await db.select(db.entries).getSingle()).amount, 15500);
        await changeCurrency(db, 'JPY'); // 2 -> 0
        expect((await db.select(db.entries).getSingle()).amount, 155);
      },
    );
  });

  test('ngày đầu tuần và ngày đầu tháng lưu được (AC-12)', () async {
    expect(await settings.watchWeekStart().first, DateTime.monday);
    await settings.setWeekStart(DateTime.sunday);
    expect(await settings.watchWeekStart().first, DateTime.sunday);
    await settings.setMonthStartDay(31);
    expect(await settings.watchMonthStartDay().first, 28);
  });
}
