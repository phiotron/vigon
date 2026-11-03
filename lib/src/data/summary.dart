import 'database.dart';

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

  factory PeriodSummary.of(Iterable<EntryView> rows) {
    final expense = <int, (Category, int)>{};
    final income = <int, (Category, int)>{};
    var expenseTotal = 0, incomeTotal = 0;
    for (final row in rows) {
      final category = row.category;
      if (category == null) continue;
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

  static List<CategoryTotal> _sorted(
    Iterable<(Category, int)> values,
    int total,
  ) =>
      values
          .map(
            (v) =>
                CategoryTotal(v.$1, v.$2, total == 0 ? 0 : v.$2 * 100 / total),
          )
          .toList()
        ..sort((a, b) => b.total.compareTo(a.total));
}
