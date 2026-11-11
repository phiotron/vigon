import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/compact_amount.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/dates.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/import_repositories.dart';
import 'package:vigon/src/data/money_sum.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/rate_repository.dart';
import 'package:vigon/src/data/stats.dart';
import 'package:vigon/src/data/stats_repository.dart';
import 'package:vigon/src/data/summary.dart';

Category _cat(int id, CategoryType type) => Category(
  id: id,
  type: type,
  nameKey: 'c$id',
  name: null,
  icon: 'more_horiz',
  color: 0xFF000000,
  sortOrder: id,
);

EntryView _row(
  int id,
  EntryType type,
  int amount,
  String date, {
  Category? category,
  int account = 1,
  String currency = 'VND',
}) => EntryView(
  Entry(
    id: id,
    type: type,
    amount: amount,
    categoryId: category?.id,
    accountId: account,
    toAccountId: type == EntryType.transfer ? 2 : null,
    date: date,
    note: null,
    recurringRuleId: null,
    source: EntrySource.manual,
    createdAt: DateTime(2026),
    currency: currency,
    originalAmount: amount,
  ),
  category,
);

/// Thu chi một ngày, một tiền tệ (mặc định VND).
DailyFlow _f(String date, int income, int expense, [String currency = 'VND']) =>
    DailyFlow(
      date,
      MoneyBag({currency: income}),
      MoneyBag({currency: expense}),
    );

/// Một ngày thành chữ để so (bỏ phần 0).
String _s(DailyFlow f) => '${f.date} +${f.income.parts} -${f.expense.parts}';

/// Túi một tiền tệ.
MoneyBag _vnd(int v) => MoneyBag({'VND': v});

void main() {
  group('dailyFlowOf', () {
    test('gom thu chi từng ngày, bỏ chuyển tiền', () {
      final food = _cat(1, CategoryType.expense);
      final salary = _cat(10, CategoryType.income);
      final flows = dailyFlowOf([
        _row(1, EntryType.expense, 100, '2026-11-02', category: food),
        _row(2, EntryType.expense, 50, '2026-11-02', category: food),
        _row(3, EntryType.income, 900, '2026-11-02', category: salary),
        _row(4, EntryType.transfer, 700, '2026-11-02'),
        _row(5, EntryType.expense, 7, '2026-11-01', category: food),
      ]);
      expect(flows.map(_s), [
        _s(_f('2026-11-01', 0, 7)),
        _s(_f('2026-11-02', 900, 150)),
      ]);
    });
  });

  group('bucketUnitFor (AC-109)', () {
    final d = DateTime(2026, 11, 6);
    test('theo loại kỳ', () {
      Period p(PeriodType t) => Period.containing(t, d);
      expect(bucketUnitFor(p(PeriodType.day)), BucketUnit.day);
      expect(bucketUnitFor(p(PeriodType.week)), BucketUnit.day);
      expect(bucketUnitFor(p(PeriodType.month)), BucketUnit.day);
      expect(bucketUnitFor(p(PeriodType.year)), BucketUnit.month);
      expect(bucketUnitFor(p(PeriodType.all)), BucketUnit.year);
    });

    test('khoảng tùy chọn: ≤ 31 ngày ngày, ≤ 366 tháng, dài hơn năm', () {
      Period c(int days) =>
          Period.custom(DateTime(2026, 1, 1), DateTime(2026, 1, days));
      Period long(int days) => Period.custom(
        DateTime(2025, 1, 1),
        addDays(DateTime(2025, 1, 1), days - 1),
      );
      expect(bucketUnitFor(c(1)), BucketUnit.day);
      expect(bucketUnitFor(c(31)), BucketUnit.day);
      expect(bucketUnitFor(long(32)), BucketUnit.month);
      expect(bucketUnitFor(long(365)), BucketUnit.month);
      expect(bucketUnitFor(long(366)), BucketUnit.month);
      expect(bucketUnitFor(long(367)), BucketUnit.year);
    });
  });

  group('flowBuckets (AC-109)', () {
    int sum(Iterable<FlowBucket> b, int Function(FlowBucket) f) =>
        b.fold(0, (a, x) => a + f(x));

    test('kỳ Ngày: một cặp cột', () {
      final p = Period.containing(PeriodType.day, DateTime(2026, 11, 6));
      final b = flowBuckets(p, [_f('2026-11-06', 10, 20)], sumParts);
      expect(b, hasLength(1));
      expect(b.single.income, 10);
      expect(b.single.expense, 20);
    });

    test('kỳ Tuần: 7 ngày, kể cả ngày không có khoản', () {
      final p = Period.containing(PeriodType.week, DateTime(2026, 11, 6));
      final b = flowBuckets(p, [_f(dateKey(p.start), 5, 0)], sumParts);
      expect(b, hasLength(7));
      expect(b.every((x) => x.unit == BucketUnit.day), isTrue);
      expect(b.first.income, 5);
      expect(sum(b, (x) => x.expense), 0);
    });

    test(
      'kỳ Tháng: từng ngày; tháng bắt đầu ngày 15 thì 30/31 ngày đúng kỳ',
      () {
        final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
        expect(
          flowBuckets(nov, [_f('2026-11-30', 0, 1)], sumParts),
          hasLength(30),
        );
        final mid = Period.containing(
          PeriodType.month,
          DateTime(2026, 11, 20),
          monthStartDay: 15,
        );
        final b = flowBuckets(mid, [_f('2026-12-14', 0, 3)], sumParts);
        expect(b.first.start, DateTime(2026, 11, 15));
        expect(b.last.end, DateTime(2026, 12, 14));
        expect(b, hasLength(30));
        expect(b.last.expense, 3);
      },
    );

    test('kỳ Năm: 12 tháng', () {
      final p = Period.containing(PeriodType.year, DateTime(2026, 6, 1));
      final b = flowBuckets(p, [
        _f('2026-01-31', 1, 2),
        _f('2026-02-01', 3, 4),
        _f('2026-12-31', 5, 6),
      ], sumParts);
      expect(b, hasLength(12));
      expect(b.every((x) => x.unit == BucketUnit.month), isTrue);
      expect([b[0].income, b[0].expense], [1, 2]);
      expect([b[1].income, b[1].expense], [3, 4]);
      expect([b[11].income, b[11].expense], [5, 6]);
      expect(b[1].start, DateTime(2026, 2, 1));
      expect(b[1].end, DateTime(2026, 2, 28));
    });

    test('kỳ Tất cả: từng năm từ khoản đầu tới khoản cuối', () {
      final p = Period.containing(PeriodType.all, DateTime(2026, 11, 6));
      final b = flowBuckets(p, [
        _f('2024-05-05', 0, 10),
        _f('2026-02-02', 7, 0),
      ], sumParts);
      expect(b.map((x) => x.start.year), [2024, 2025, 2026]);
      expect(b.map((x) => x.expense), [10, 0, 0]);
      expect(b.last.income, 7);
      expect(b.every((x) => x.unit == BucketUnit.year), isTrue);
    });

    test(
      'khoảng tùy chọn 40 ngày: từng tháng, cột đầu/cuối cắt theo khoảng',
      () {
        final p = Period.custom(DateTime(2026, 1, 20), DateTime(2026, 2, 28));
        final b = flowBuckets(p, [
          _f('2026-01-20', 0, 1),
          _f('2026-01-31', 0, 2),
          _f('2026-02-28', 0, 4),
        ], sumParts);
        expect(b, hasLength(2));
        expect(b[0].start, DateTime(2026, 1, 20));
        expect(b[0].end, DateTime(2026, 1, 31));
        expect(b[0].expense, 3);
        expect(b[1].end, DateTime(2026, 2, 28));
        expect(b[1].expense, 4);
      },
    );

    test('khoảng tùy chọn dài hơn 366 ngày: từng năm, cắt theo khoảng', () {
      final p = Period.custom(DateTime(2024, 7, 1), DateTime(2026, 3, 31));
      final b = flowBuckets(p, [
        _f('2024-07-01', 1, 0),
        _f('2025-06-06', 2, 0),
        _f('2026-03-31', 4, 0),
        _f('2026-04-01', 99, 99), // ngoài khoảng
      ], sumParts);
      expect(b.map((x) => x.start), [
        DateTime(2024, 7, 1),
        DateTime(2025, 1, 1),
        DateTime(2026, 1, 1),
      ]);
      expect(b.map((x) => x.income), [1, 2, 4]);
      expect(b.last.end, DateTime(2026, 3, 31));
    });

    test('tổng các cột bằng tổng kỳ; ngày ngoài kỳ bị bỏ qua', () {
      final p = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final flows = [
        for (var d = 1; d <= 30; d++)
          _f('2026-11-${'$d'.padLeft(2, '0')}', d * 1000, d * 700 + 1),
        _f('2026-10-31', 5, 5),
        _f('2026-12-01', 5, 5),
      ];
      final b = flowBuckets(p, flows, sumParts);
      expect(sum(b, (x) => x.income), 1000 * (30 * 31 ~/ 2));
      expect(sum(b, (x) => x.expense), 700 * (30 * 31 ~/ 2) + 30);
    });

    test('kỳ không có khoản: danh sách rỗng, không cột rỗng (AC-110)', () {
      final p = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      expect(flowBuckets(p, <DailyFlow>[], sumParts), isEmpty);
      expect(flowBuckets(p, [_f('2026-10-01', 1, 1)], sumParts), isEmpty);
      final all = Period.containing(PeriodType.all, DateTime(2026, 11, 6));
      expect(flowBuckets(all, <DailyFlow>[], sumParts), isEmpty);
    });
  });

  group('biggestSpendingDay (AC-109)', () {
    test('lấy ngày chi nhiều nhất', () {
      final d = biggestSpendingDay([
        _f('2026-11-01', 0, 540000),
        _f('2026-11-14', 0, 310000),
        _f('2026-11-06', 9999999, 250000),
      ], sumParts);
      expect(d!.date, DateTime(2026, 11, 1));
      expect(d.expense, 540000);
    });

    test('bằng nhau thì ngày sớm hơn, dù xuất hiện sau', () {
      final d = biggestSpendingDay([
        _f('2026-11-20', 0, 100),
        _f('2026-11-03', 0, 100),
        _f('2026-11-09', 0, 100),
      ], sumParts);
      expect(d!.date, DateTime(2026, 11, 3));
    });

    test('không có khoản chi thì null', () {
      expect(biggestSpendingDay(<DailyFlow>[], sumParts), isNull);
      expect(biggestSpendingDay([_f('2026-11-01', 5, 0)], sumParts), isNull);
    });
  });

  group('topExpenseCategories (AC-109)', () {
    test('5 danh mục chi nhiều nhất, % trên tổng chi kỳ', () {
      final cats = [for (var i = 1; i <= 7; i++) _cat(i, CategoryType.expense)];
      final salary = _cat(10, CategoryType.income);
      final rows = [
        for (var i = 0; i < 7; i++)
          _row(
            i + 1,
            EntryType.expense,
            (i + 1) * 100,
            '2026-11-02',
            category: cats[i],
          ),
        _row(20, EntryType.income, 99999, '2026-11-02', category: salary),
        _row(21, EntryType.transfer, 99999, '2026-11-02'),
      ];
      final top = topExpenseCategories(PeriodSummary.of(rows));
      expect(top.map((t) => t.category.id), [7, 6, 5, 4, 3]);
      expect(top.map((t) => t.total), [700, 600, 500, 400, 300]);
      // Tổng chi = 2800: 700/2800 = 25,0%.
      expect(top.first.percent, 25.0);
    });

    test('bằng tiền thì id nhỏ trước; ít hơn 5 thì trả hết', () {
      final a = _cat(5, CategoryType.expense),
          b = _cat(2, CategoryType.expense);
      final top = topExpenseCategories(
        PeriodSummary.of([
          _row(1, EntryType.expense, 100, '2026-11-02', category: a),
          _row(2, EntryType.expense, 100, '2026-11-02', category: b),
        ]),
      );
      expect(top.map((t) => t.category.id), [2, 5]);
      expect(topExpenseCategories(PeriodSummary.empty), isEmpty);
    });
  });

  group('BalanceLedger và đường lịch sử số dư (AC-109)', () {
    final ledger = BalanceLedger(
      initial: _vnd(1000),
      netByDate: {
        '2026-11-10': _vnd(-300),
        '2026-11-02': _vnd(500),
        '2026-12-01': _vnd(50),
      },
    );
    int at(String d) => sumParts(ledger.at(d));

    test('số dư cuối ngày', () {
      expect(at('2026-10-31'), 1000);
      expect(at('2026-11-02'), 1500);
      expect(at('2026-11-09'), 1500);
      expect(at('2026-11-10'), 1200);
      expect(at('2027-01-01'), 1250);
      expect(sumParts(ledger.total), 1250);
      expect(
        sumParts(
          BalanceLedger(initial: _vnd(7), netByDate: const {}).at('2026-01-01'),
        ),
        7,
      );
    });

    test('giá trị cuối mỗi cột; bỏ cột sau hôm nay', () {
      final p = Period.containing(PeriodType.year, DateTime(2026, 11, 6));
      final buckets = flowBuckets(p, [_f('2026-11-02', 500, 0)], sumParts);
      final points = balanceHistory(
        buckets,
        ledger,
        sumParts,
        today: DateTime(2026, 11, 15),
      );
      expect(points, hasLength(11)); // tháng 12 bắt đầu sau hôm nay: bỏ
      expect(points[9].bucket.start, DateTime(2026, 10, 1));
      expect(points[9].balance, 1000);
      expect(points[10].bucket.start, DateTime(2026, 11, 1));
      expect(points[10].balance, 1200);
    });
  });

  group('tháng, so với tháng trước (AC-107, AC-108)', () {
    test('6 tháng kết thúc ở tháng đang chọn, cũ nhất trước', () {
      final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final months = monthsEndingAt(nov);
      expect(months, hasLength(6));
      expect(months.first.start, DateTime(2026, 6, 1));
      expect(months.last, nov);
    });

    test('theo ngày bắt đầu tháng', () {
      final m = Period.containing(
        PeriodType.month,
        DateTime(2026, 1, 20),
        monthStartDay: 15,
      );
      final months = monthsEndingAt(m);
      expect(months.first.start, DateTime(2025, 8, 15));
      expect(months.last.end, DateTime(2026, 2, 14));
      for (var i = 1; i < months.length; i++) {
        expect(months[i].start, addDays(months[i - 1].end, 1));
      }
    });

    test('monthlyFlows khớp tổng các khoản', () {
      final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final flows = monthlyFlows(monthsEndingAt(nov), [
        _f('2026-06-01', 10, 20),
        _f('2026-10-31', 0, 4000000),
        _f('2026-11-01', 100, 3000000),
        _f('2026-11-30', 7, 2000000),
        _f('2026-12-01', 1, 1), // ngoài 6 tháng
        _f('2026-05-31', 1, 1), // ngoài 6 tháng
      ], sumParts);
      expect(flows.first.income, 10);
      expect(flows.first.expense, 20);
      expect(flows[4].expense, 4000000);
      expect(flows[5].income, 107);
      expect(flows[5].expense, 5000000);
      expect(flows[5].net, 107 - 5000000);
    });

    test('tháng 10 chi 4.000.000, tháng 11 chi 5.000.000 → tăng 25%', () {
      final c = percentChange(4000000, 5000000)!;
      expect(c.direction, ChangeDirection.up);
      expect(c.percent, 25);
    });

    test('giảm, không đổi, làm tròn, tháng trước bằng 0', () {
      final down = percentChange(5000000, 4000000)!;
      expect(down.direction, ChangeDirection.down);
      expect(down.percent, 20);
      expect(percentChange(100, 100)!.direction, ChangeDirection.same);
      // 1/3 → 33,33% → 33; 2/3 → 66,67% → 67.
      expect(percentChange(300, 400)!.percent, 33);
      expect(percentChange(300, 500)!.percent, 67);
      // 0,5% làm tròn nửa lên thành 1%.
      expect(percentChange(200, 201)!.percent, 1);
      // Nhỏ hơn 0,5% coi là không đổi.
      expect(percentChange(1000, 1003)!.direction, ChangeDirection.same);
      expect(percentChange(0, 5000000), isNull);
      expect(percentChange(0, 0), isNull);
      // Chi về 0 → giảm 100%.
      final gone = percentChange(800, 0)!;
      expect(gone.direction, ChangeDirection.down);
      expect(gone.percent, 100);
    });

    test('OverviewData: net, ngân sách còn lại, vượt, chưa đặt', () {
      final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final months = monthsEndingAt(nov);
      final flows = [
        for (final (i, p) in months.indexed)
          _f(
            dateKey(p.start),
            i == 5 ? 9000000 : 1,
            i == 4 ? 4000000 : (i == 5 ? 5000000 : 0),
          ),
      ];
      OverviewData data(int? budget) => OverviewData.of(
        month: nov,
        months: months,
        flows: flows,
        totalBalance: _vnd(123),
        budget: budget,
        convert: sumParts,
      );
      expect(data(null).totalBalance, 123);
      expect(data(6000000).net, 4000000);
      expect(data(6000000).budgetLeft, 1000000);
      expect(data(4000000).budgetLeft, -1000000);
      expect(data(null).budgetLeft, isNull);
      expect(data(null).expenseChange!.percent, 25);
      expect(data(null).incomeChange, isNotNull);
      expect(data(null).isEmpty, isFalse);
      expect(data(null).hasNoFlow, isFalse);
    });
  });

  group('compactAmount (AC-114)', () {
    String vi(int v, {int digits = 0}) =>
        compactAmount(v, decimalDigits: digits, languageCode: 'vi');
    String en(int v, {int digits = 2}) =>
        compactAmount(v, decimalDigits: digits, languageCode: 'en');

    test('vi: 50k, 1,2tr', () {
      expect(vi(50000), '50k');
      expect(vi(1200000), '1,2tr');
      expect(vi(1234567), '1,2tr');
      expect(vi(12500000), '13tr');
      expect(vi(250), '250');
      expect(vi(0), '0');
      expect(vi(1000), '1k');
      expect(vi(1500), '1,5k');
      expect(vi(3000000000), '3tỷ');
      expect(vi(540000), '540k');
    });

    test('en: 50K, 1.2M (USD, đơn vị nhỏ nhất là cent)', () {
      expect(en(5000000), '50K');
      expect(en(120000000), '1.2M');
      expect(en(25000), '250');
      expect(en(54000), '540');
      expect(en(300000000000), '3B');
    });

    test('lên bậc khi làm tròn chạm 1.000', () {
      expect(vi(999600), '1tr');
      expect(vi(999400), '999k');
      expect(vi(999999999), '1tỷ');
      expect(en(99960000), '1M');
    });

    test('dưới 1 đơn vị chính', () {
      expect(en(30), '<1');
      expect(en(50), '1');
      expect(en(149), '1');
    });
  });

  group('StatsRepository (cơ sở dữ liệu thật trong bộ nhớ)', () {
    late AppDatabase db;
    late StatsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StatsRepository(db);
    });
    tearDown(() => db.close());

    Future<void> add(
      EntryType type,
      int amount,
      String date, {
      int account = 1,
      int? to,
      int? category,
    }) => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: type,
            amount: amount,
            categoryId: Value(category),
            accountId: account,
            toAccountId: Value(to),
            date: date,
          ),
        );

    test('thu chi từng ngày; chuyển tiền và hàng đợi không tính', () async {
      final second = await AccountRepository(db).add(name: 'Ví');
      await add(EntryType.expense, 100, '2026-11-02', category: 1);
      await add(
        EntryType.expense,
        50,
        '2026-11-02',
        category: 1,
        account: second,
      );
      await add(EntryType.income, 900, '2026-11-02', category: 11);
      await add(EntryType.transfer, 700, '2026-11-02', to: second);
      await add(EntryType.expense, 7, '2026-12-01', category: 1);
      // Mục hàng đợi chưa là khoản (AC-95): có trong bảng của nó, không vào số liệu.
      await ImportQueueRepository(db).add(
        ImportQueueItemsCompanion.insert(
          bank: Bank.mb,
          referenceNumber: 'FT1',
          debitLast4: '1234',
          currency: 'VND',
          amount: 5000000,
          date: '2026-11-02',
          time: '10:00',
        ),
      );
      final all = await repo.watchDailyFlow('2026-11-01', '2026-11-30').first;
      expect(all.map(_s), [_s(_f('2026-11-02', 900, 150, 'USD'))]);
      final onlySecond = await repo
          .watchDailyFlow('2026-11-01', '2026-11-30', accountId: second)
          .first;
      expect(onlySecond.map(_s), [_s(_f('2026-11-02', 0, 50, 'USD'))]);
      final allTime = await repo
          .watchPeriodFlow(
            Period.containing(PeriodType.all, DateTime(2026, 11, 6)),
          )
          .first;
      expect(allTime, hasLength(2));
    });

    test(
      'tổng số dư gồm cả tài khoản ẩn, chuyển tiền không đổi tổng',
      () async {
        final accounts = AccountRepository(db);
        final hidden = await accounts.add(name: 'Cũ', initialBalance: 2000);
        await accounts.edit(1, name: 'Chính', initialBalance: 1000);
        await add(EntryType.income, 500, '2026-11-02', category: 11);
        await add(
          EntryType.expense,
          200,
          '2026-11-03',
          category: 1,
          account: hidden,
        );
        await add(EntryType.transfer, 300, '2026-11-04', to: hidden);
        await accounts.archive(hidden);
        final ledger = await repo.balanceLedger();
        expect(sumParts(ledger.initial), 3000);
        expect(sumParts(ledger.at('2026-11-02')), 3500);
        expect(sumParts(ledger.at('2026-11-03')), 3300);
        expect(sumParts(ledger.at('2026-11-04')), 3300);
        // Khớp tổng số dư từng tài khoản của app.
        final perAccount = MoneyBag();
        balanceBags(
          await db.select(db.accounts).get(),
          await db.select(db.entries).get(),
        ).values.forEach(perAccount.addBag);
        expect(ledger.total.parts, perAccount.parts);
      },
    );

    test('10.000 khoản: số liệu khớp tổng (thời gian thật là [M])', () async {
      var income = 0, expense = 0;
      await db.batch((b) {
        for (var i = 0; i < 10000; i++) {
          final isIncome = i % 7 == 0;
          final amount = 1000 + i;
          final day = 1 + i % 28;
          final month = 1 + i % 12;
          final date =
              '2026-${'$month'.padLeft(2, '0')}-${'$day'.padLeft(2, '0')}';
          if (isIncome) {
            income += amount;
          } else {
            expense += amount;
          }
          b.insert(
            db.entries,
            EntriesCompanion.insert(
              type: isIncome ? EntryType.income : EntryType.expense,
              amount: amount,
              categoryId: Value(isIncome ? 11 : 1 + i % 5),
              accountId: 1,
              date: date,
            ),
          );
        }
      });
      final flows = await repo
          .watchPeriodFlow(
            Period.containing(PeriodType.all, DateTime(2026, 11, 6)),
          )
          .first;
      expect(flows.fold<int>(0, (a, f) => a + sumParts(f.income)), income);
      expect(flows.fold<int>(0, (a, f) => a + sumParts(f.expense)), expense);
      final year = Period.containing(PeriodType.year, DateTime(2026, 6, 1));
      final buckets = flowBuckets(year, flows, sumParts);
      expect(buckets, hasLength(12));
      expect(buckets.fold<int>(0, (a, b) => a + b.expense), expense);
      final ledger = await repo.balanceLedger();
      expect(
        sumParts(ledger.total),
        sumParts(ledger.initial) + income - expense,
      );
    });
  });

  group('Tiền tệ chính, cộng chính xác (D-042, AC-148)', () {
    // 1 USD = 25 974 VND (như test/data/exact_sum_test.dart).
    const table = RateTable(
      base: 'USD',
      date: '2026-11-10',
      rates: {'VND': 25974, 'EUR': 0.92},
    );
    final usd = convertWith(const CurrencyService(table, 'USD'));
    final vnd = convertWith(const CurrencyService(table, 'VND'));

    test('cột cộng gốc theo tiền tệ rồi quy đổi một lần', () {
      // 3 ngày × 10 000 ₫: quy từng ngày rồi cộng = 3 × 39 = 117 cent; cộng
      // gốc rồi quy một lần = 30 000 / 25 974 → 116 cent.
      final year = Period.containing(PeriodType.year, DateTime(2026, 11, 6));
      final flows = [
        for (final d in ['2026-11-01', '2026-11-02', '2026-11-03'])
          _f(d, 0, 10000),
      ];
      final b = flowBuckets(year, flows, usd);
      expect(b[10].expense, 116);
      // Theo VND thì từng đồng.
      expect(flowBuckets(year, flows, vnd)[10].expense, 30000);
    });

    test('nhiều tiền tệ trong một ngày: mỗi phần giữ số gốc', () {
      final rows = dailyFlowOf([
        _row(1, EntryType.expense, 10000, '2026-11-02', currency: 'VND'),
        _row(2, EntryType.expense, 150, '2026-11-02', currency: 'USD'),
        _row(3, EntryType.expense, 20000, '2026-11-02', currency: 'VND'),
      ]);
      expect(rows.single.expense.parts, {'VND': 30000, 'USD': 150});
      // 150 cent + 30 000 ₫ (≈ 115,5 cent) = 265,5 → 266 cent, làm tròn một lần.
      expect(usd(rows.single.expense), 266);
      expect(biggestSpendingDay(rows, usd)!.expense, 266);
    });

    test('thiếu tỷ giá: phần đó không vào tổng (AC-134)', () {
      final bag = MoneyBag({'VND': 25974, 'XYZ': 999});
      expect(usd(bag), 100);
    });

    test('Tổng quan: thu − chi tháng cộng gốc rồi quy đổi một lần', () {
      final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final data = OverviewData.of(
        month: nov,
        months: monthsEndingAt(nov),
        flows: [
          _f('2026-11-01', 0, 10000),
          _f('2026-11-02', 0, 10000),
          _f('2026-11-03', 0, 10000),
        ],
        totalBalance: MoneyBag({'VND': 25974, 'USD': 100}),
        budget: 200,
        convert: usd,
      );
      expect(data.current.expense, 116);
      expect(data.net, -116);
      expect(data.totalBalance, 200);
      expect(data.budgetLeft, 84);
    });

    test('AC-108: tháng 10 chi 4.000.000 ₫, tháng 11 chi 5.000.000 ₫ → '
        'tăng 25%', () {
      final nov = Period.containing(PeriodType.month, DateTime(2026, 11, 6));
      final data = OverviewData.of(
        month: nov,
        months: monthsEndingAt(nov),
        flows: [
          _f('2026-10-15', 0, 1500000),
          _f('2026-10-31', 0, 2500000),
          _f('2026-11-03', 0, 5000000),
        ],
        totalBalance: MoneyBag(),
        budget: null,
        convert: vnd,
      );
      expect(data.previous!.expense, 4000000);
      expect(data.current.expense, 5000000);
      expect(data.expenseChange!.direction, ChangeDirection.up);
      expect(data.expenseChange!.percent, 25);
      expect(data.incomeChange, isNull); // tháng trước thu 0 → "—"
    });

    test('sổ số dư: chuyển tiền khác tiền tệ, tài khoản ẩn — khớp số dư '
        'từng tài khoản', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final accounts = AccountRepository(db);
      await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
        const AccountsCompanion(
          currency: Value('VND'),
          initialCurrency: Value('VND'),
          initialBalanceOriginal: Value(1000000),
          initialBalance: Value(1000000),
        ),
      );
      final wallet = await accounts.add(name: 'USD');
      await (db.update(db.accounts)..where((a) => a.id.equals(wallet))).write(
        const AccountsCompanion(
          currency: Value('USD'),
          initialCurrency: Value('USD'),
          initialBalanceOriginal: Value(500),
          initialBalance: Value(500),
        ),
      );
      Future<void> add(
        EntryType type,
        int original,
        String currency,
        String date, {
        int account = 1,
        int? to,
        int? toOriginal,
        String? toCurrency,
      }) => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: type,
              amount: original,
              categoryId: Value(
                type == EntryType.transfer
                    ? null
                    : (type == EntryType.income ? 11 : 1),
              ),
              accountId: account,
              toAccountId: Value(to),
              date: date,
              currency: Value(currency),
              originalAmount: Value(original),
              toOriginalAmount: Value(toOriginal),
              toCurrency: Value(toCurrency),
            ),
          );
      await add(EntryType.expense, 10000, 'VND', '2026-11-01');
      await add(EntryType.expense, 10000, 'VND', '2026-11-01');
      await add(EntryType.income, 250, 'USD', '2026-11-02', account: wallet);
      await add(
        EntryType.transfer,
        259740,
        'VND',
        '2026-11-03',
        to: wallet,
        toOriginal: 1000,
        toCurrency: 'USD',
      );
      await accounts.archive(wallet);
      final repo = StatsRepository(db);
      final ledger = await repo.balanceLedger();
      expect(ledger.initial.parts, {'VND': 1000000, 'USD': 500});
      expect(ledger.at('2026-11-01').parts, {'VND': 980000, 'USD': 500});
      expect(ledger.at('2026-11-03').parts, {'VND': 720260, 'USD': 1750});
      final perAccount = MoneyBag();
      balanceBags(
        await db.select(db.accounts).get(),
        await db.select(db.entries).get(),
      ).values.forEach(perAccount.addBag);
      expect(ledger.total.parts, perAccount.parts);
      // Thu chi gốc theo ngày, theo tiền tệ.
      final flows = await repo.watchDailyFlow('2026-11-01', '2026-11-30').first;
      expect(flows.map(_s), [
        '2026-11-01 +{} -{VND: 20000}',
        '2026-11-02 +{USD: 250} -{}',
      ]);
    });
  });
}
