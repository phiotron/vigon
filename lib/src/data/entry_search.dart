import 'database.dart';
import 'summary.dart';
import 'text_fold.dart';

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
  required String Function(int amount) amountTextOf,
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
  String Function(int) amountTextOf,
) {
  final note = row.entry.note;
  if (note != null && foldText(note).contains(text)) return true;
  if (foldText(categoryNameOf(row)).contains(text)) return true;
  return digits.isNotEmpty &&
      amountTextOf(row.entry.amount).replaceAll(_nonDigit, '').contains(digits);
}

/// Tổng hiển thị ở đầu kết quả tìm: chỉ khoản chi thì tổng chi, chỉ khoản thu
/// thì tổng thu, lẫn cả hai thì thu trừ chi (có dấu). Chuyển tiền không tính.
int searchTotal(List<EntryView> rows) {
  var income = 0, expense = 0;
  for (final r in rows) {
    switch (r.entry.type) {
      case EntryType.income:
        income += r.entry.amount;
      case EntryType.expense:
        expense += r.entry.amount;
      case EntryType.transfer:
        break;
    }
  }
  if (income == 0) return expense;
  if (expense == 0) return income;
  return income - expense;
}
