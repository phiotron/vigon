import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/calculator.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/settings_repository.dart';

/// Quy đổi tiền tệ theo tỉ giá (D-025, AC-21, AC-70..AC-72).
void main() {
  ExchangeRate rate(String r) => ExchangeRate.tryParse(r)!;

  group('ExchangeRate', () {
    test('đọc số thập phân và dạng mũ, từ chối số ≤ 0 hay sai', () {
      expect(rate('25974').toDouble(), 25974);
      expect(rate('0.0000385').toDouble(), closeTo(0.0000385, 1e-15));
      expect(rate('3.85e-5'), rate('0.0000385'));
      expect(rate('1E3'), rate('1000'));
      expect(rate('.5'), rate('0.5'));
      for (final bad in ['', '0', '0.000', '-1', 'abc', '1,5', '1.2.3', 'e5']) {
        expect(ExchangeRate.tryParse(bad), isNull, reason: bad);
      }
    });

    test('fromDouble giữ 12 chữ số, chiều ngược, lưu rồi đọc lại', () {
      final r = ExchangeRate.fromDouble(1 / 25974.0)!;
      expect(r.toDouble(), closeTo(1 / 25974.0, 1e-15));
      expect(r.inverse.toDouble(), closeTo(25974, 1e-6));
      expect(
        ExchangeRate.tryParse(rate('0.0000385').toStorage()),
        rate('0.0000385'),
      );
      expect(rate('0.0000385').toStorage(), '0.0000385');
      expect(rate('26000').toStorage(), '26000');
      expect(ExchangeRate.fromDouble(0), isNull);
      expect(ExchangeRate.fromDouble(double.nan), isNull);
      expect(ExchangeRate.fromDouble(double.infinity), isNull);
    });
  });

  group('convertMinorUnits', () {
    BigInt c(int v, String r, int from, int to) =>
        convertMinorUnits(v, rate(r), fromDigits: from, toDigits: to);

    test('làm tròn half-up đối xứng', () {
      expect(c(25, '0.1', 0, 0), BigInt.from(3)); // 2,5 → 3
      expect(c(24, '0.1', 0, 0), BigInt.from(2)); // 2,4 → 2
      expect(c(-25, '0.1', 0, 0), BigInt.from(-3)); // −2,5 → −3
      expect(c(-24, '0.1', 0, 0), BigInt.from(-2));
      expect(c(0, '123', 0, 2), BigInt.zero);
    });

    test(
      'đổi số chữ số thập phân: VND → USD, USD → VND, USD → JPY, VND → KWD',
      () {
        // 1.000.000 ₫ × 0,0000385 = 38,50 US$.
        expect(c(1000000, '0.0000385', 0, 2), BigInt.from(3850));
        // 12,34 US$ × 25974 = 320.519,16 ₫ → 320.519.
        expect(c(1234, '25974', 2, 0), BigInt.from(320519));
        // 0,99 US$ × 152,5 = 150,975 ¥ → 151.
        expect(c(99, '152.5', 2, 0), BigInt.from(151));
        // 1 ₫ × 0,0000118 = 0,0000118 KWD → 0 fils (chặn tối thiểu ở convertCurrency).
        expect(c(1, '0.0000118', 0, 3), BigInt.zero);
      },
    );

    test('không tràn số với số lớn nhất và tỉ giá lớn', () {
      expect(
        c(maxMinorUnits, '1000000', 0, 3),
        BigInt.from(maxMinorUnits) * BigInt.from(10).pow(9),
      );
    });
  });

  group('RateTable', () {
    const table = RateTable(
      base: 'USD',
      date: '2026-11-05',
      rates: {'USD': 1, 'VND': 25974, 'EUR': 0.89, 'JPY': 152.5},
    );

    test('tỉ giá chéo qua USD, thiếu cặp thì null', () {
      expect(table.rate('USD', 'VND')!.toDouble(), closeTo(25974, 1e-6));
      expect(table.rate('VND', 'USD')!.toDouble(), closeTo(1 / 25974, 1e-15));
      expect(table.rate('EUR', 'JPY')!.toDouble(), closeTo(152.5 / 0.89, 1e-9));
      expect(table.rate('VND', 'XYZ'), isNull);
      expect(table.rate('XYZ', 'VND'), isNull);
    });

    test('lưu JSON rồi đọc lại; chữ hỏng thì null', () {
      final back = RateTable.tryFromJson(table.toJson())!;
      expect(back.date, '2026-11-05');
      expect(back.rates, table.rates);
      expect(RateTable.tryFromJson('{oops'), isNull);
      expect(RateTable.tryFromJson(null), isNull);
    });
  });

  group('convertCurrency (một giao dịch)', () {
    late AppDatabase db;
    late SettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    Future<int> entry(EntryType type, int amount, {int? toAccount}) => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: type,
            amount: amount,
            categoryId: Value(type == EntryType.transfer ? null : 1),
            accountId: 1,
            toAccountId: Value(toAccount),
            date: '2026-11-03',
          ),
        );

    Future<void> seedVnd() async {
      await settings.ensureCurrency('vi_VN');
      final second = await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: const Value('Thẻ')));
      await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: const Value('Trống')));
      await entry(EntryType.expense, 155000);
      await entry(EntryType.income, 26000000);
      await entry(EntryType.transfer, 1000000, toAccount: second);
      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              type: EntryType.expense,
              amount: 3000000,
              categoryId: const Value(1),
              accountId: 1,
              frequency: RecurrenceFrequency.monthly,
              startDate: '2026-11-01',
            ),
          );
      await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
        const AccountsCompanion(initialBalance: Value(5000000)),
      );
      await (db.update(db.accounts)..where((a) => a.id.equals(second))).write(
        const AccountsCompanion(initialBalance: Value(-2600000)),
      );
      await CategoryRepository(db).setBudget(1, 2000000);
      await settings.setBudget(10000000);
    }

    Future<Map<String, Object?>> snapshot() async => {
      'currency': await settings.readCurrency(),
      'entries': [for (final e in await db.select(db.entries).get()) e.amount],
      'rules': [
        for (final r in await db.select(db.recurringRules).get()) r.amount,
      ],
      'accounts': [
        for (final a in await db.select(db.accounts).get()) a.initialBalance,
      ],
      'categories': [
        for (final c in await db.select(db.categories).get()) c.budget,
      ],
      'budget': await settings.readBudget(),
    };

    test('VND → USD quy đổi MỌI cột tiền (khoản, chuyển, định kỳ, số dư, '
        'hạn mức, ngân sách)', () async {
      await seedVnd();
      final before = await snapshot();
      await convertCurrency(db, 'USD', rate('0.0000385'));
      final after = await snapshot();
      expect(after['currency'], 'USD');
      // 155.000 → 5,9675 → 597; 26.000.000 → 1.001,00; 1.000.000 → 38,50.
      expect(after['entries'], [597, 100100, 3850]);
      expect(after['rules'], [11550]); // 3.000.000 → 115,50
      expect(after['accounts'], [19250, -10010, 0]); // tài khoản 0 giữ 0
      final cats = after['categories']! as List;
      expect(cats.first, 7700); // 2.000.000 → 77,00
      expect(
        cats.skip(1).every((b) => b == null),
        isTrue,
        reason: 'hạn mức chưa đặt vẫn null',
      );
      expect(after['budget'], 38500); // 10.000.000 → 385,00
      expect(before['currency'], 'VND');
    });

    test('USD → VND rồi JPY (0 chữ số thập phân)', () async {
      await settings.ensureCurrency('en_US');
      await entry(EntryType.expense, 1234); // 12,34 US$
      await convertCurrency(db, 'VND', rate('25974'));
      expect((await db.select(db.entries).getSingle()).amount, 320519);
      // 320.519 ₫ × 0,00587 = 1.881,446... ¥ → 1.881.
      await convertCurrency(db, 'JPY', rate('0.00587'));
      expect(await settings.readCurrency(), 'JPY');
      expect((await db.select(db.entries).getSingle()).amount, 1881);
      // JPY → USD: 1.881 ¥ × 0,00656 = 12,33936 → 12,34 US$.
      await convertCurrency(db, 'USD', rate('0.00656'));
      expect((await db.select(db.entries).getSingle()).amount, 1234);
    });

    test('số > 0 nhỏ hơn 1 đơn vị sau làm tròn thành 1', () async {
      await settings.ensureCurrency('vi_VN');
      await entry(EntryType.expense, 1); // 1 ₫
      await settings.setBudget(5);
      await convertCurrency(db, 'USD', rate('0.0000385'));
      expect((await db.select(db.entries).getSingle()).amount, 1);
      expect(await settings.readBudget(), 1);
    });

    test('vượt 10^12 thì báo lỗi và KHÔNG đổi gì', () async {
      await seedVnd();
      // Khoản 26 tỉ ₫ × 100 = 2,6 nghìn tỉ, vượt giới hạn.
      await entry(EntryType.income, 26000000000);
      final before = await snapshot();
      await expectLater(
        convertCurrency(db, 'IDR', rate('100')),
        throwsA(isA<CurrencyConversionOverflow>()),
      );
      expect(await snapshot(), before);
    });

    test('số âm vượt giới hạn (số dư ban đầu) cũng bị chặn', () async {
      await settings.ensureCurrency('vi_VN');
      await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
        const AccountsCompanion(initialBalance: Value(-maxMinorUnits)),
      );
      await expectLater(
        convertCurrency(db, 'IDR', rate('2')),
        throwsA(isA<CurrencyConversionOverflow>()),
      );
      expect(await settings.readCurrency(), 'VND');
    });

    test('lỗi giữa chừng thì giao dịch quay lui, dữ liệu như cũ', () async {
      await seedVnd();
      final before = await snapshot();
      // Bảng tài khoản ghi sau bảng khoản: làm hỏng lúc ghi để chắc chắn khoản
      // đã ghi rồi phải được quay lui.
      await db.customStatement(
        'CREATE TRIGGER fail_accounts BEFORE UPDATE ON accounts '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(
        convertCurrency(db, 'USD', rate('0.0000385')),
        throwsA(anything),
      );
      expect(await snapshot(), before);
    });

    test('cùng mã thì không đổi gì', () async {
      await seedVnd();
      final before = await snapshot();
      await convertCurrency(db, 'VND', rate('3'));
      expect(await snapshot(), before);
    });

    test('số ví dụ: khoản mới nhất, không có thì ngân sách', () async {
      await settings.ensureCurrency('vi_VN');
      expect(await conversionExampleAmount(db), isNull);
      await settings.setBudget(700);
      expect(await conversionExampleAmount(db), 700);
      await entry(EntryType.expense, 155000);
      expect(await conversionExampleAmount(db), 155000);
    });
  });

  group('cache tỉ giá trong bảng settings', () {
    late AppDatabase db;
    late SettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    test('bảng tỉ giá và tỉ giá tự nhập (đọc được cả chiều ngược)', () async {
      expect(await settings.readRateTable(), isNull);
      await settings.setRateTable(
        const RateTable(base: 'USD', date: '2026-11-05', rates: {'VND': 25974}),
      );
      expect((await settings.readRateTable())!.rates['VND'], 25974);

      expect(await settings.readManualRate('USD', 'VND'), isNull);
      await settings.setManualRate('USD', 'VND', rate('25000'), '2026-11-06');
      final same = await settings.readManualRate('USD', 'VND');
      expect(same!.rate, rate('25000'));
      expect(same.date, '2026-11-06');
      final back = await settings.readManualRate('VND', 'USD');
      expect(back!.rate, rate('0.00004'));
      expect(await settings.readManualRate('USD', 'EUR'), isNull);
    });
  });
}
