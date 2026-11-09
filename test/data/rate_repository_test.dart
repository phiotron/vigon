import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/rate_repository.dart';
import 'package:vigon/src/data/settings_repository.dart';

RateTable _table({String date = '2026-11-09', double usdToVnd = 25000}) =>
    RateTable(base: 'USD', date: date, rates: {'VND': usdToVnd, 'EUR': 0.9});

class _FakeSource implements ExchangeRateSource {
  _FakeSource(this.result);

  final Object result;
  int calls = 0;

  @override
  String get attribution => 'Fake';

  @override
  Uri get homepage => Uri.parse('https://example.com');

  @override
  Future<RateTable> fetch() async {
    calls++;
    if (result is ExchangeRateException) throw result;
    return result as RateTable;
  }
}

void main() {
  group('CurrencyService (D-037)', () {
    test('quy đổi đúng số lẻ của hai tiền tệ', () {
      final service = CurrencyService(_table(), 'VND');
      expect(service.toPrimary(1000, 'USD'), 250000); // $10 → 250.000 ₫
      expect(service.fromPrimary(250000, 'USD'), 1000);
      expect(service.toPrimary(1000, 'VND'), 1000);
    });

    test('cặp thiếu tỷ giá trả null, không quy đổi ngầm', () {
      final service = CurrencyService(
        const RateTable(base: 'USD', date: '2026-11-09', rates: {'VND': 25000}),
        'VND',
      );
      expect(service.toPrimary(100, 'EUR'), isNull);
      expect(service.has('VND', 'EUR'), isFalse);
    });

    test('ghi đè thắng bảng tự động và đảo chiều đúng', () {
      final table = _table().withOverrides({
        'USD>VND': ExchangeRate.tryParse('26000')!,
      });
      expect(table.rate('USD', 'VND'), ExchangeRate.tryParse('26000'));
      expect(table.rate('VND', 'USD'), ExchangeRate.tryParse('26000')!.inverse);
    });
  });

  group('RateRepository.refreshIfStale', () {
    late AppDatabase db;
    late SettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    test('bảng còn mới thì không tải', () async {
      await settings.setRateTable(_table(date: '2026-11-09'));
      final source = _FakeSource(_table(date: '2026-11-10'));
      final repo = RateRepository(
        db,
        settings,
        source,
        () => DateTime(2026, 11, 9, 20),
      );
      expect(await repo.refreshIfStale(), RatesRefreshResult.notNeeded);
      expect(source.calls, 0);
    });

    test('bảng cũ ≥ 1 ngày thì tải và lưu', () async {
      await settings.setRateTable(_table(date: '2026-11-08'));
      final source = _FakeSource(_table(date: '2026-11-09'));
      final repo = RateRepository(
        db,
        settings,
        source,
        () => DateTime(2026, 11, 9, 8),
      );
      expect(await repo.refreshIfStale(), RatesRefreshResult.updated);
      expect(source.calls, 1);
      expect((await settings.readRateTable())?.date, '2026-11-09');
    });

    test('tải lỗi thì giữ bảng cũ', () async {
      await settings.setRateTable(_table(date: '2026-11-08'));
      final repo = RateRepository(
        db,
        settings,
        _FakeSource(const ExchangeRateException(ExchangeRateError.offline)),
        () => DateTime(2026, 11, 9, 8),
      );
      expect(await repo.refreshIfStale(), RatesRefreshResult.failed);
      expect((await settings.readRateTable())?.date, '2026-11-08');
    });
  });

  group('recomputeDerivedAmounts (D-037)', () {
    late AppDatabase db;
    late SettingsRepository settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
    });
    tearDown(() => db.close());

    test('đổi tỷ giá chỉ tính lại số dẫn xuất, giữ số gốc', () async {
      await settings.setCurrency('VND');
      final account = await AccountRepository(db)
          .add(name: 'USD', currency: 'USD');
      final id = await EntryRepository(db).add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 1,
          accountId: account,
          date: '2026-11-09',
          currency: const Value('USD'),
          originalAmount: const Value(1000),
        ),
      );
      await recomputeDerivedAmounts(db, CurrencyService(_table(), 'VND'));
      var entry = await EntryRepository(db).find(id);
      expect((entry!.amount, entry.originalAmount), (250000, 1000));

      await recomputeDerivedAmounts(
        db,
        CurrencyService(_table(usdToVnd: 26000), 'VND'),
      );
      entry = await EntryRepository(db).find(id);
      expect((entry!.amount, entry.originalAmount), (260000, 1000));
    });

    test('cặp thiếu tỷ giá thì giữ số dẫn xuất cũ', () async {
      await settings.setCurrency('VND');
      final account = await AccountRepository(db)
          .add(name: 'EUR', currency: 'EUR');
      final id = await EntryRepository(db).add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 123,
          accountId: account,
          date: '2026-11-09',
          currency: const Value('EUR'),
          originalAmount: const Value(1000),
        ),
      );
      await recomputeDerivedAmounts(
        db,
        const CurrencyService(
          RateTable(base: 'USD', date: '2026-11-09', rates: {'VND': 25000}),
          'VND',
        ),
      );
      final entry = await EntryRepository(db).find(id);
      expect(entry!.amount, 123);
    });

    test('promoteLegacyAmounts gán số gốc và tiền tệ cũ', () async {
      await settings.setCurrency('VND');
      final account = await AccountRepository(db).add(name: 'Tiền mặt');
      final id = await EntryRepository(db).add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 155000,
          accountId: account,
          date: '2026-11-09',
        ),
      );
      await promoteLegacyAmounts(db, 'VND');
      final entry = await EntryRepository(db).find(id);
      expect((entry!.originalAmount, entry.currency), (155000, 'VND'));
      final acc = (await db.select(db.accounts).get()).first;
      expect((acc.initialBalanceOriginal, acc.initialCurrency), (0, 'USD'));
    });
  });

  test('chuyển tiền khác tiền tệ lưu cả hai số (D-037)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final accounts = AccountRepository(db);
    final usd = await accounts.add(name: 'USD', currency: 'USD');
    final vnd = await accounts.add(name: 'VND', currency: 'VND');
    final id = await EntryRepository(db).addTransfer(
      fromAccountId: usd,
      toAccountId: vnd,
      amount: 1000,
      originalAmount: 1000,
      currency: 'USD',
      toAmount: 250000,
      toOriginalAmount: 250000,
      toCurrency: 'VND',
      date: '2026-11-09',
    );
    final entry = await EntryRepository(db).find(id);
    expect(
      (
        entry!.amount,
        entry.originalAmount,
        entry.currency,
        entry.toAmount,
        entry.toOriginalAmount,
        entry.toCurrency,
      ),
      (1000, 1000, 'USD', 250000, 250000, 'VND'),
    );
  });
}
