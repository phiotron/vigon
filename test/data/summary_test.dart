import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/rate_repository.dart';
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
  Category? category, {
  String currency = 'VND',
}) => EntryView(
  Entry(
    id: id,
    type: type,
    amount: amount,
    categoryId: category?.id,
    accountId: 1,
    toAccountId: type == EntryType.transfer ? 2 : null,
    date: '2026-11-03',
    note: null,
    recurringRuleId: null,
    source: EntrySource.manual,
    createdAt: DateTime(2026),
    currency: currency,
  ),
  category,
);

void main() {
  final food = _cat(1, CategoryType.expense);
  final bus = _cat(2, CategoryType.expense);
  final home = _cat(3, CategoryType.expense);
  final salary = _cat(10, CategoryType.income);

  test('tổng thu, chi, số dư khớp các khoản (AC-07)', () {
    final s = PeriodSummary.of([
      _row(1, EntryType.expense, 155000, food),
      _row(2, EntryType.expense, 45000, food),
      _row(3, EntryType.expense, 30000, bus),
      _row(4, EntryType.income, 1000000, salary),
    ]);
    expect(s.expense, 230000);
    expect(s.income, 1000000);
    expect(s.balance, 770000);
    expect(s.expenseByCategory.first.category, food);
    expect(s.expenseByCategory.first.total, 200000);
  });

  test('phần trăm theo danh mục cộng lại bằng 100 (AC-08)', () {
    final s = PeriodSummary.of([
      _row(1, EntryType.expense, 1, food),
      _row(2, EntryType.expense, 1, bus),
      _row(3, EntryType.expense, 1, home),
    ]);
    final rounded = s.expenseByCategory
        .map((t) => double.parse(t.percent.toStringAsFixed(1)))
        .fold<double>(0, (a, b) => a + b);
    expect(rounded, closeTo(100, 0.1 + 1e-9));
    expect(
      s.expenseByCategory.map((t) => t.percent).reduce((a, b) => a + b),
      closeTo(100, 1e-9),
    );
  });

  test('chuyển tiền không tính là thu hay chi (AC-19)', () {
    final s = PeriodSummary.of([
      _row(1, EntryType.transfer, 500000, null),
      _row(2, EntryType.expense, 10000, food),
    ]);
    expect(s.expense, 10000);
    expect(s.income, 0);
  });

  test('cặp thiếu tỷ giá bị loại khỏi tổng (D-037)', () {
    const service = CurrencyService(
      RateTable(base: 'USD', date: '2026-11-09', rates: {'VND': 25000}),
      'VND',
    );
    final s = PeriodSummary.of([
      _row(1, EntryType.expense, 155000, food),
      _row(2, EntryType.expense, 9999, food, currency: 'EUR'),
    ], service: service);
    expect(s.expense, 155000);
    expect(s.expenseByCategory.single.total, 155000);
  });

  test('kỳ trống', () {
    final s = PeriodSummary.of(const []);
    expect(s.isEmpty, isTrue);
    expect(s.expenseByCategory, isEmpty);
  });

  for (final n in [6, 7, 12, 13]) {
    test(
      'phần trăm hiển thị của $n danh mục bằng nhau cộng đúng 100,0 (AC-08)',
      () {
        final rows = [
          for (var i = 1; i <= n; i++)
            _row(i, EntryType.expense, 1, _cat(i, CategoryType.expense)),
        ];
        final s = PeriodSummary.of(rows);
        // Giá trị người dùng thấy: làm tròn một chữ số thập phân.
        final shown = s.expenseByCategory
            .map((t) => double.parse(t.percent.toStringAsFixed(1)))
            .toList();
        expect(shown.fold<double>(0, (a, b) => a + b), closeTo(100, 1e-6));
        // Mỗi phần chỉ lệch tối đa 0,1 so với phần trăm thật.
        for (final p in shown) {
          expect((p - 100 / n).abs(), lessThanOrEqualTo(0.1 + 1e-9));
        }
      },
    );
  }

  test('phần trăm có khoản rất nhỏ và rất lớn vẫn cộng 100,0 (AC-08)', () {
    final s = PeriodSummary.of([
      _row(1, EntryType.expense, 1, food),
      _row(2, EntryType.expense, 999999, bus),
      _row(3, EntryType.expense, 3, home),
    ]);
    final sum = s.expenseByCategory.fold<double>(
      0,
      (a, t) => a + double.parse(t.percent.toStringAsFixed(1)),
    );
    expect(sum, closeTo(100, 1e-6));
  });
}
