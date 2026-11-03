/// Ngày lưu dạng chữ `YYYY-MM-DD` theo giờ địa phương (D-005).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Bỏ phần giờ, giữ ngày theo giờ địa phương.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Cộng [days] ngày theo lịch (không lệch khi đổi giờ mùa hè).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Cộng [months] tháng; ngày vượt cuối tháng thì lấy ngày cuối tháng.
DateTime addMonths(DateTime d, int months, {int? day}) {
  final first = DateTime(d.year, d.month + months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  final wanted = day ?? d.day;
  return DateTime(first.year, first.month, wanted > last ? last : wanted);
}
