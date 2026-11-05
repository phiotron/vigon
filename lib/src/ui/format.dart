import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../data/calculator.dart';
import '../data/money.dart';
import '../data/period.dart';
import 'theme.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// Số tiền hiển thị theo ngôn ngữ đang dùng (AC-22).
String money(BuildContext context, String currency, int minorUnits) =>
    formatMoney(minorUnits, currencyCode: currency, locale: _locale(context));

/// Chữ đặt sẵn trong ô số tiền khi mở sửa, theo ngôn ngữ ("3.000.000" / "3,000,000").
String amountInput(BuildContext context, int minorUnits, int decimalDigits) =>
    formatAmountInput(
      minorUnits,
      decimalDigits: decimalDigits,
      locale: _locale(context),
    );

/// Đọc ô số tiền (có dấu ngăn nghìn theo ngôn ngữ) ra đơn vị nhỏ nhất; null nếu sai.
int? parseAmountField(BuildContext context, String text, int decimalDigits) {
  final normalized = normalizeAmountInput(text, locale: _locale(context));
  return normalized == null
      ? null
      : evaluateToMinorUnits(normalized, decimalDigits: decimalDigits);
}

/// Phần trăm một chữ số thập phân, ví dụ `42,5%` (AC-08).
String percent(BuildContext context, double value) =>
    NumberFormat.decimalPercentPattern(
      locale: _locale(context),
      decimalDigits: 1,
    ).format(value / 100);

String shortDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(_locale(context)).format(d);

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Tiêu đề kỳ đang xem, ví dụ "Tháng 11 năm 2026" (AC-11).
String periodTitle(BuildContext context, Period p) {
  final l = AppLocalizations.of(context);
  final locale = _locale(context);
  String range() =>
      '${DateFormat.MMMd(locale).format(p.start)} – ${DateFormat.yMMMd(locale).format(p.end)}';
  return switch (p.type) {
    PeriodType.day => _capitalize(DateFormat.yMMMEd(locale).format(p.start)),
    PeriodType.week => range(),
    PeriodType.month when p.start.day == 1 => _capitalize(
      DateFormat.yMMMM(locale).format(p.start),
    ),
    PeriodType.month => range(),
    PeriodType.year => '${p.start.year}',
    PeriodType.all => l.periodAll,
    PeriodType.custom => range(),
  };
}

/// Màu cho số tiền thu và chi theo token, đủ tương phản trên nền sáng và
/// tối (AC-40).
Color incomeColor(BuildContext context) => context.vg.income;

Color expenseColor(BuildContext context) => context.vg.expense;

/// Cỡ chữ hệ thống từ 130% trở lên: số tiền đặt dưới tiêu đề thay vì cuối
/// dòng, để không bị cắt ở màn 360 dp (AC-38).
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) >= 13;
