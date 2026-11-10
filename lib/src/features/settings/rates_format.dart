import '../../../l10n/app_localizations.dart';
import '../../data/dates.dart';
import '../../data/exchange_rate.dart';

/// Cách đọc bảng tỷ giá dùng chung cho Cài đặt và màn Tỷ giá (D-037).
///
/// Bảng tỷ giá chỉ lưu ngày (không lưu giờ như A001), nên "cập nhật khi nào"
/// tính theo ngày: hôm nay · hôm qua · N ngày trước.

/// Ngày của [table] so với [now], dạng "hôm nay", "hôm qua", "3 ngày trước".
String ratesAgoLabel(AppLocalizations l, RateTable table, DateTime now) {
  final day = DateTime.tryParse(table.date);
  if (day == null) return l.ratesAgoToday;
  final days = dateOnly(now).difference(dateOnly(day)).inDays;
  if (days <= 0) return l.ratesAgoToday;
  if (days == 1) return l.ratesAgoYesterday;
  return l.ratesAgoDays(days);
}

/// Người dùng đã đặt tay tỷ giá của cặp [from]–[to] (đọc được cả hai chiều).
bool rateIsOverridden(RateTable table, String from, String to) =>
    table.overrides.containsKey('$from>$to') ||
    table.overrides.containsKey('$to>$from');

/// Cặp hiển thị dễ đọc như A001: "1 ngoại tệ = X tiền chính"; nếu tỷ giá
/// xuống dưới 1 (ngoại tệ mạnh hơn) thì đảo thành "1 tiền chính = X ngoại tệ".
(String, String) ratePairFor(RateTable table, String from, String to) {
  final direct = table.rate(from, to);
  if (direct != null && direct.toDouble() < 1) {
    final inverse = table.rate(to, from);
    if (inverse != null && inverse.toDouble() >= 1) return (to, from);
  }
  return (from, to);
}

/// Dòng tóm tắt hàng "Tỷ giá" ở Cài đặt: "Tự động · hôm qua" · "Có sẵn" ·
/// "Bạn đặt tay" (khi mọi cặp đang dùng đều đã đặt tay, như A001).
String ratesSummaryLabel(
  AppLocalizations l,
  RateTable table,
  Set<String> used,
  String primary,
  DateTime now,
) {
  final foreign = used.where((c) => c != primary);
  if (foreign.isNotEmpty &&
      foreign.every((c) => rateIsOverridden(table, c, primary))) {
    return l.ratesSummaryManual;
  }
  if (table.isFallback) return l.ratesSummaryBuiltIn;
  return l.ratesSummaryAuto(ratesAgoLabel(l, table, now));
}

/// Phụ đề từng cặp ở màn Tỷ giá: "Bạn đặt tay" · "Tự động · tỷ giá ước tính
/// có sẵn" · "Tự động · cập nhật hôm nay" / "Ngoại tuyến · tỷ giá từ hôm qua".
String ratePairSubtitle(
  AppLocalizations l,
  RateTable table,
  String from,
  String to, {
  required bool offline,
  required DateTime now,
}) {
  if (rateIsOverridden(table, from, to)) return l.ratesManual;
  if (table.isFallback) return l.ratesBuiltIn;
  final ago = ratesAgoLabel(l, table, now);
  return offline ? l.ratesAutoOffline(ago) : l.ratesAuto(ago);
}
