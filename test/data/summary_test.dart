import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
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

EntryView _row(int id, EntryType type, int amount, Category? category) =>
    EntryView(
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
        createdAt: DateTime(2026),
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

  test('kỳ trống', () {
    final s = PeriodSummary.of(const []);
    expect(s.isEmpty, isTrue);
    expect(s.expenseByCategory, isEmpty);
  });
}
