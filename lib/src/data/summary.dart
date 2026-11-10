import 'database.dart';
import 'money_sum.dart';
import 'rate_repository.dart';

/// Một khoản ghi kèm danh mục của nó (null với chuyển tiền).
class EntryView {
  const EntryView(this.entry, this.category);

  final Entry entry;
  final Category? category;
}

/// Tổng của một danh mục trong kỳ và phần trăm trong loại của nó (AC-08).
class CategoryTotal {
  const CategoryTotal(this.category, this.total, this.percent);

  final Category category;
  final int total;
  final double percent;
}

/// Tổng thu, chi, số dư và chia theo danh mục của một kỳ (AC-07, AC-08).
/// Chuyển tiền không tính là thu hay chi (AC-19).
class PeriodSummary {
  const PeriodSummary({
    required this.income,
    required this.expense,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  static const empty = PeriodSummary(
    income: 0,
    expense: 0,
    expenseByCategory: [],
    incomeByCategory: [],
  );

  final int income;
  final int expense;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;

  int get balance => income - expense;
  bool get isEmpty => income == 0 && expense == 0;

  factory PeriodSummary.of(
    Iterable<EntryView> rows, {
    CurrencyService? service,
  }) {
    // Có service: cộng số gốc theo từng tiền tệ rồi quy đổi một lần (D-042,
    // AC-148). Không có (test cũ, chưa nạp tỷ giá): cộng số dẫn xuất.
    final expense = <int, (Category, MoneyBag)>{};
    final income = <int, (Category, MoneyBag)>{};
    final expenseAll = MoneyBag(), incomeAll = MoneyBag();
    for (final row in rows) {
      final category = row.category;
      if (category == null) continue;
      final e = row.entry;
      // Cặp thiếu tỷ giá thì khoản không vào tổng (D-037); UI vẫn hiện số gốc
      // kèm ghi chú "không có tỷ giá".
      if (service != null &&
          e.type != EntryType.transfer &&
          !service.has(e.currency, service.primary)) {
        continue;
      }
      final amount = service == null ? e.amount : entryOriginal(e);
      final currency = service == null ? '' : e.currency;
      switch (e.type) {
        case EntryType.expense:
          expenseAll.add(currency, amount);
          (expense[category.id] ??= (
            category,
            MoneyBag(),
          )).$2.add(currency, amount);
        case EntryType.income:
          incomeAll.add(currency, amount);
          (income[category.id] ??= (
            category,
            MoneyBag(),
          )).$2.add(currency, amount);
        case EntryType.transfer:
          break;
      }
    }
    int total(MoneyBag bag) => service == null
        ? bag.parts.values.fold(0, (a, b) => a + b)
        : bag.convertTo(service, service.primary) ?? 0;
    final expenseTotal = total(expenseAll);
    final incomeTotal = total(incomeAll);
    return PeriodSummary(
      income: incomeTotal,
      expense: expenseTotal,
      expenseByCategory: _sorted([
        for (final v in expense.values) (v.$1, total(v.$2)),
      ], expenseTotal),
      incomeByCategory: _sorted([
        for (final v in income.values) (v.$1, total(v.$2)),
      ], incomeTotal),
    );
  }

  /// Phần trăm làm tròn tới 0,1 theo phần dư lớn nhất, nên các phần hiển thị
  /// cộng lại đúng 100,0 (AC-08).
  static List<CategoryTotal> _sorted(
    Iterable<(Category, int)> values,
    int total,
  ) {
    final items = values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final tenths = [
      for (final v in items) total == 0 ? 0 : v.$2 * 1000 ~/ total,
    ];
    if (total > 0) {
      final order = List.generate(items.length, (i) => i)
        ..sort((a, b) {
          final ra = items[a].$2 * 1000 % total;
          final rb = items[b].$2 * 1000 % total;
          return rb != ra ? rb.compareTo(ra) : a.compareTo(b);
        });
      var left = 1000 - tenths.fold<int>(0, (a, b) => a + b);
      for (var k = 0; left > 0 && k < order.length; k++, left--) {
        tenths[order[k]]++;
      }
    }
    return [
      for (var i = 0; i < items.length; i++)
        CategoryTotal(items[i].$1, items[i].$2, tenths[i] / 10),
    ];
  }
}
