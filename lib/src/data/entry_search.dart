import 'database.dart';
import 'summary.dart';
import 'text_fold.dart';
import 'money_sum.dart';
import 'rate_repository.dart';

/// Chuỗi tìm có phải số tiền không: chỉ gồm chữ số và dấu ngăn cách (AC-48).
final _amountQuery = RegExp(r"^[\d\s.,'’]+$");
final _nonDigit = RegExp(r'\D');

/// Lọc [rows] theo [query] (AC-48): khớp một phần, không phân biệt hoa thường
/// và dấu tiếng Việt, ở ghi chú, tên danh mục, hoặc số tiền.
///
/// - [categoryNameOf]: tên danh mục theo ngôn ngữ đang dùng (rỗng nếu không có).
/// - [amountTextOf]: số tiền như đang hiển thị, ví dụ `1.550.000 ₫`. Chỉ lấy
///   chữ số, nên gõ `155` khớp cả 155.000 và 1.550.000.
///
/// Số tiền chỉ được xét khi chuỗi tìm toàn là chữ số và dấu ngăn cách.
/// Chuỗi tìm rỗng thì giữ nguyên tất cả. Giữ nguyên thứ tự của [rows].
List<EntryView> filterEntries(
  List<EntryView> rows,
  String query, {
  required String Function(EntryView row) categoryNameOf,
  required String Function(EntryView row) amountTextOf,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return rows;
  final text = foldText(trimmed);
  final digits = _amountQuery.hasMatch(trimmed)
      ? trimmed.replaceAll(_nonDigit, '')
      : '';
  return [
    for (final row in rows)
      if (_matches(row, text, digits, categoryNameOf, amountTextOf)) row,
  ];
}

bool _matches(
  EntryView row,
  String text,
  String digits,
  String Function(EntryView) categoryNameOf,
  String Function(EntryView) amountTextOf,
) {
  final note = row.entry.note;
  if (note != null && foldText(note).contains(text)) return true;
  if (foldText(categoryNameOf(row)).contains(text)) return true;
  return digits.isNotEmpty &&
      amountTextOf(row).replaceAll(_nonDigit, '').contains(digits);
}

/// Tổng hiển thị ở đầu kết quả tìm: chỉ khoản chi thì tổng chi, chỉ khoản thu
/// thì tổng thu, lẫn cả hai thì thu trừ chi (có dấu). Chuyển tiền không tính.
int searchTotal(List<EntryView> rows, {CurrencyService? service}) {
  // Cộng gốc theo từng tiền tệ rồi quy đổi một lần (D-042, AC-148).
  final income = MoneyBag(), expense = MoneyBag();
  var hasIncome = false, hasExpense = false;
  for (final r in rows) {
    final e = r.entry;
    final amount = service == null ? e.amount : entryOriginal(e);
    final currency = service == null ? '' : e.currency;
    switch (e.type) {
      case EntryType.income:
        hasIncome = true;
        income.add(currency, amount);
      case EntryType.expense:
        hasExpense = true;
        expense.add(currency, amount);
      case EntryType.transfer:
        break;
    }
  }
  int total(MoneyBag bag) => service == null
      ? bag.parts.values.fold(0, (a, b) => a + b)
      : bag.convertTo(service, service.primary) ?? 0;
  final i = total(income), x = total(expense);
  if (!hasIncome) return x;
  if (!hasExpense) return i;
  return i - x;
}
