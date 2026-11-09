import 'database.dart';
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
    final expense = <int, (Category, int)>{};
    final income = <int, (Category, int)>{};
    var expenseTotal = 0, incomeTotal = 0;
    for (final row in rows) {
      final category = row.category;
      if (category == null) continue;
      // Cặp thiếu tỷ giá thì khoản không vào tổng (D-037); UI vẫn hiện số gốc
      // kèm ghi chú "không có tỷ giá".
      if (service != null &&
          row.entry.type != EntryType.transfer &&
          !service.has(row.entry.currency, service.primary)) {
        continue;
      }
      final amount = row.entry.amount;
      switch (row.entry.type) {
        case EntryType.expense:
          expenseTotal += amount;
          final old = expense[category.id]?.$2 ?? 0;
          expense[category.id] = (category, old + amount);
        case EntryType.income:
          incomeTotal += amount;
          final old = income[category.id]?.$2 ?? 0;
          income[category.id] = (category, old + amount);
        case EntryType.transfer:
          break;
      }
    }
    return PeriodSummary(
      income: incomeTotal,
      expense: expenseTotal,
      expenseByCategory: _sorted(expense.values, expenseTotal),
      incomeByCategory: _sorted(income.values, incomeTotal),
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
