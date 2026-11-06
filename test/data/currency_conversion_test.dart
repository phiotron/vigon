import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/calculator.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/recurring_repository.dart';
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

    test('A→B và B→A cùng bảng là nghịch đảo ĐÚNG (phân số, D-029)', () {
      const codes = ['USD', 'VND', 'EUR', 'JPY'];
      for (final a in codes) {
        for (final b in codes) {
          final ab = table.rate(a, b)!;
          final ba = table.rate(b, a)!;
          expect(ab, ba.inverse, reason: '$a→$b');
          expect(ab.numerator * ba.numerator, ab.denominator * ba.denominator);
        }
      }
      // 1 VND = 1/25974 USD đúng tuyệt đối, không phải 0,0000385000385.
      final vndUsd = table.rate('VND', 'USD')!;
      expect(
        (vndUsd.numerator, vndUsd.denominator),
        (BigInt.one, BigInt.from(25974)),
      );
      // Chuỗi tỉ giá chéo cùng bảng nhân lại đúng bằng 1.
      final loop =
          table.rate('VND', 'EUR')! /
          table.rate('VND', 'JPY')! /
          table.rate('JPY', 'EUR')!;
      expect((loop.numerator, loop.denominator), (BigInt.one, BigInt.one));
    });

    test('tỉ giá phân số lưu rồi đọc lại đúng giá trị (cache tỉ giá)', () {
      final cross = table.rate('EUR', 'JPY')!;
      expect(cross.toStorage(), contains('/'));
      expect(ExchangeRate.fromStorage(cross.toStorage()), cross);
      expect(
        ExchangeRate.fromStorage(rate('0.0000385').toStorage()),
        rate('0.0000385'),
      );
      expect(ExchangeRate.fromStorage('3/0'), isNull);
      expect(ExchangeRate.fromStorage('0/3'), isNull);
      expect(ExchangeRate.fromStorage('1/x'), isNull);
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
      await settings.ensureCurrency(defaultCode: 'VND');
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
      await settings.ensureCurrency();
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

    test('khoản nhỏ hơn 1 đơn vị thành 0 (giữ số chính xác); ngân sách và '
        'hạn mức tối thiểu 1 (D-029)', () async {
      await settings.ensureCurrency(defaultCode: 'VND');
      await entry(EntryType.expense, 1); // 1 ₫
      await settings.setBudget(5);
      await CategoryRepository(db).setBudget(1, 5);
      await convertCurrency(db, 'USD', rate('0.0000385'));
      final e = await db.select(db.entries).getSingle();
      // 1 ₫ = 0,0000385 US$ = 38,5 micro → 39 micro, hiện 0,00 US$.
      expect((e.amount, e.amountMicro), (0, 39));
      expect(await settings.readBudget(), 1);
      expect(await settings.readBudgetMicro(), isNull);
      final food = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(1))).getSingle();
      expect((food.budget, food.budgetMicro), (1, null));
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
      await settings.ensureCurrency(defaultCode: 'VND');
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
      await settings.ensureCurrency(defaultCode: 'VND');
      expect(await conversionExampleAmount(db), isNull);
      await settings.setBudget(700);
      expect(await conversionExampleAmount(db), (minor: 700, exact: 700000000));
      await entry(EntryType.expense, 155000);
      expect(await conversionExampleAmount(db), (
        minor: 155000,
        exact: 155000000000,
      ));
      // Khoản đã quy đổi về 0,00 US$: số ví dụ mang số chính xác.
      await db.delete(db.entries).go();
      await entry(EntryType.expense, 100);
      await convertCurrency(db, 'USD', rate('0.0000385'));
      expect(await conversionExampleAmount(db), (minor: 0, exact: 3850));
    });
  });

  group(
    'số tiền chính xác 6 lẻ: đổi đi đổi lại ra đúng số cũ (D-029, AC-73)',
    () {
      late AppDatabase db;
      late SettingsRepository settings;
      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        settings = SettingsRepository(db);
      });
      tearDown(() => db.close());

      const table = RateTable(
        base: 'USD',
        date: '2026-11-06',
        rates: {'USD': 1, 'VND': 25974, 'KWD': 0.3071, 'JPY': 152.5},
      );

      Future<int> entry(int amount) => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: EntryType.expense,
              amount: amount,
              categoryId: const Value(1),
              accountId: 1,
              date: '2026-11-06',
            ),
          );

      Future<List<int>> amounts() async => [
        for (final e in await (db.select(
          db.entries,
        )..orderBy([(e) => OrderingTerm(expression: e.id)])).get())
          e.amount,
      ];

      Future<void> to(String code) async => convertCurrency(
        db,
        code,
        table.rate(await settings.readCurrency(), code)!,
      );

      test('50.000 ₫ → USD → ₫ = 50.000 ₫ (lỗi cũ: 50.130 ₫)', () async {
        await settings.setCurrency('VND');
        await entry(50000);
        await to('USD');
        expect(await amounts(), [193]); // hiện 1,93 US$
        await to('VND');
        expect(await amounts(), [50000]);
      });

      test('100 ₫ → USD = 0 cent, micro 3850; đổi lại = 100 ₫', () async {
        await settings.setCurrency('VND');
        await entry(100);
        await convertCurrency(db, 'USD', rate('0.0000385'));
        final e = await db.select(db.entries).getSingle();
        expect((e.amount, e.amountMicro), (0, 3850)); // hiện 0,00 US$
        await convertCurrency(db, 'VND', rate('0.0000385').inverse);
        final back = await db.select(db.entries).getSingle();
        expect((back.amount, back.amountMicro), (100, null));
      });

      test('chuỗi VND → USD → KWD → JPY → VND ra đúng MỌI số gốc', () async {
        await settings.setCurrency('VND');
        const original = [1, 100, 999, 50000, 155000, 26000000, 123456789];
        for (final a in original) {
          await entry(a);
        }
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
          const AccountsCompanion(initialBalance: Value(-2600001)),
        );
        await CategoryRepository(db).setBudget(1, 2000003);
        await settings.setBudget(10000007);

        for (final code in ['USD', 'KWD', 'JPY', 'VND']) {
          await to(code);
        }
        expect(await settings.readCurrency(), 'VND');
        expect(await amounts(), original);
        expect(
          (await db.select(db.recurringRules).getSingle()).amount,
          3000000,
        );
        final cash = await (db.select(
          db.accounts,
        )..where((a) => a.id.equals(1))).getSingle();
        expect(cash.initialBalance, -2600001);
        final food = await (db.select(
          db.categories,
        )..where((c) => c.id.equals(1))).getSingle();
        expect(food.budget, 2000003);
        expect(await settings.readBudget(), 10000007);
      });

      test('ngẫu nhiên (seed cố định): 1.000 số tiền × tỉ giá, đổi qua lại 10 '
          'lần ra đúng gốc', () async {
        final rnd = Random(20261106);
        // Khoảng tỉ giá thực tế, số đơn vị cho 1 USD; 6 chữ số có nghĩa như nguồn.
        const ranges = {
          'USD': (1.0, 1.0),
          'VND': (20000.0, 30000.0),
          'EUR': (0.8, 1.0),
          'GBP': (0.7, 0.9),
          'JPY': (100.0, 200.0),
          'KWD': (0.29, 0.33),
        };
        RateTable randomTable() => RateTable(
          base: 'USD',
          date: '2026-11-06',
          rates: {
            for (final MapEntry(key: code, value: (lo, hi)) in ranges.entries)
              code: double.parse(
                (lo + rnd.nextDouble() * (hi - lo)).toStringAsPrecision(6),
              ),
          },
        );
        final codes = ranges.keys.toList();
        for (final home in ['VND', 'USD', 'KWD', 'JPY']) {
          await db.delete(db.entries).go();
          await settings.setCurrency(home);
          final original = [
            for (var i = 0; i < 250; i++)
              rnd.nextBool()
                  ? 1 + rnd.nextInt(1000)
                  : 1 + rnd.nextInt(1000000000),
          ];
          await db.batch((b) {
            for (final a in original) {
              b.insert(
                db.entries,
                EntriesCompanion.insert(
                  type: EntryType.expense,
                  amount: a,
                  categoryId: const Value(1),
                  accountId: 1,
                  date: '2026-11-06',
                ),
              );
            }
          });
          for (var trip = 0; trip < 10; trip++) {
            final t = randomTable();
            final others = codes.where((c) => c != home).toList()..shuffle(rnd);
            final other = others.first;
            await convertCurrency(db, other, t.rate(home, other)!);
            await convertCurrency(db, home, t.rate(other, home)!);
            expect(await amounts(), original, reason: '$home↔$other lần $trip');
          }
        }
      });

      test('sửa tay số tiền sau khi đổi thì bỏ số chính xác cũ', () async {
        await settings.setCurrency('VND');
        final id = await entry(100);
        await convertCurrency(db, 'USD', rate('0.0000385'));
        final converted = await (db.select(
          db.entries,
        )..where((e) => e.id.equals(id))).getSingle();
        expect(converted.amountMicro, 3850);
        // Màn sửa khoản ghi đè cả dòng, giữ nguyên cột micro cũ.
        await db.update(db.entries).replace(converted.copyWith(amount: 500));
        await convertCurrency(db, 'VND', rate('0.0000385').inverse);
        // 5,00 US$ (số người dùng gõ) chứ không phải 0,00385 US$ → 129.870 ₫.
        final back = await (db.select(
          db.entries,
        )..where((e) => e.id.equals(id))).getSingle();
        expect(back.amount, 129870);
      });

      test(
        'khoản định kỳ sinh sau khi đổi mang số chính xác của chuỗi',
        () async {
          await settings.setCurrency('VND');
          final repo = RecurringRepository(db);
          await repo.addWithRepeat(
            EntriesCompanion.insert(
              type: EntryType.expense,
              amount: 3000000,
              categoryId: const Value(1),
              accountId: 1,
              date: '2026-10-01',
            ),
            RecurrenceFrequency.monthly,
          );
          await to('USD');
          await repo.generateDue(DateTime(2026, 11, 1));
          expect(await amounts(), [11550, 11550]); // 115,50 US$
          await to('VND');
          expect(await amounts(), [3000000, 3000000]);
        },
      );

      test(
        'vượt giới hạn (tính từ số chính xác) báo lỗi, không đổi gì',
        () async {
          await settings.setCurrency('VND');
          await entry(100);
          await convertCurrency(db, 'USD', rate('0.0000385'));
          await entry(maxMinorUnits);
          final before = await db.select(db.entries).get();
          await expectLater(
            convertCurrency(db, 'VND', rate('25974')),
            throwsA(isA<CurrencyConversionOverflow>()),
          );
          expect(await db.select(db.entries).get(), before);
          expect(await settings.readCurrency(), 'USD');
        },
      );

      test('exactMicro tự kiểm: micro khớp số đang hiện mới được dùng', () {
        expect(exactMicro(0, 3850, 2), 3850);
        expect(exactMicro(193, 1925003, 2), 1925003); // 1,925003 US$
        expect(exactMicro(500, 3850, 2), 5000000); // đã sửa tay
        expect(exactMicro(7, null, 0), 7000000);
        expect(exactMicro(-10010, -100100000, 2), -100100000);
        expect(exactMicro(-15, -15000, 3), -15000); // −0,015 KWD
        expect(roundMicroToMinor(5000, 2), 1); // 0,005 → 0,01 (half-up)
        expect(roundMicroToMinor(-5000, 2), -1);
        expect(roundMicroToMinor(4999, 2), 0);
      });
    },
  );

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
