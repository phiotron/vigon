import 'dart:math';

import 'package:intl/intl.dart';

import 'currency_table.dart';

/// Số chữ số thập phân của tiền tệ theo ISO 4217 (VND 0, USD 2, KWD 3).
/// Ưu tiên bảng của app (`currency_table.dart`); mã lạ thì hỏi intl, rồi mặc định 2.
int currencyDecimalDigits(String currencyCode) =>
    currencyInfo(currencyCode)?.digits ??
    NumberFormat.currency(locale: 'en', name: currencyCode).decimalDigits ??
    2;

/// Hiển thị số tiền lưu dạng đơn vị nhỏ nhất theo ngôn ngữ (AC-22).
/// Chỉ đổi sang số thực ở bước hiển thị; tính toán luôn dùng số nguyên (D-005).
String formatMoney(
  int minorUnits, {
  required String currencyCode,
  required String locale,
}) {
  final format = NumberFormat.simpleCurrency(
    locale: locale,
    name: currencyCode,
    decimalDigits: currencyDecimalDigits(currencyCode),
  );
  return format.format(minorUnits / pow(10, format.decimalDigits!));
}
