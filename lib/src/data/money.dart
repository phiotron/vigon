import 'dart:math';

import 'package:intl/intl.dart';

import 'currency_table.dart';

/// Số chữ số thập phân của tiền tệ theo ISO 4217 (VND 0, USD 2, KWD 3).
/// Ưu tiên bảng của app (`currency_table.dart`); mã lạ thì hỏi intl, rồi mặc định 2.
int currencyDecimalDigits(String currencyCode) =>
    currencyInfo(currencyCode)?.digits ??
    NumberFormat.currency(locale: 'en', name: currencyCode).decimalDigits ??
    2;

/// Đổi số đơn vị nhỏ nhất từ [fromDigits] sang [toDigits] chữ số lẻ mà GIỮ
/// NGUYÊN con số người dùng đã gõ: 10 (VND, 0 lẻ) → 1000 (USD, 2 lẻ) tức vẫn
/// là "10". Dùng khi đổi tiền tệ của ô đang nhập; không phải quy đổi tỷ giá.
/// Bớt chữ số lẻ thì làm tròn half-up ra xa 0 (12,345 → 12,35 → 12).
int rescaleMinorUnits(int minor, int fromDigits, int toDigits) {
  if (toDigits >= fromDigits) {
    return minor * pow(10, toDigits - fromDigits).toInt();
  }
  final f = pow(10, fromDigits - toDigits).toInt();
  final rounded = (minor.abs() * 2 + f) ~/ (2 * f);
  return minor < 0 ? -rounded : rounded;
}

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

/// Dấu thập phân và dấu ngăn nghìn của [locale] (vi: "," và "."; en: "." và ",").
({String decimal, String group}) _separators(String locale) {
  final s = NumberFormat.decimalPattern(locale).symbols;
  return (decimal: s.DECIMAL_SEP, group: s.GROUP_SEP);
}

/// Chữ trong ô nhập số tiền khi mở sửa, theo định dạng của ngôn ngữ (D5, SCR-16/18/21,
/// 5.3): VND 3000000 → "3.000.000" (vi) / "3,000,000" (en); USD 1250 cent → "12,50" /
/// "12.50" (có phần lẻ thì đủ [decimalDigits] chữ số), 1200 cent → "12". [minorUnits] ≥ 0;
/// số âm do màn tự thêm "-". Tính bằng số nguyên, không qua số thực.
String formatAmountInput(
  int minorUnits, {
  required int decimalDigits,
  required String locale,
}) {
  final sep = _separators(locale);
  final unit = BigInt.from(10).pow(decimalDigits).toInt();
  final whole = minorUnits ~/ unit;
  final fraction = minorUnits % unit;
  final digits = '$whole';
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(sep.group);
    grouped.write(digits[i]);
  }
  if (decimalDigits == 0 || fraction == 0) return grouped.toString();
  return '$grouped${sep.decimal}${'$fraction'.padLeft(decimalDigits, '0')}';
}

/// Đọc chữ trong ô nhập số tiền ra đơn vị nhỏ nhất; null nếu sai, rỗng hoặc vượt
/// `maxMinorUnits` (qua `evaluateToMinorUnits`). Hiểu dấu ngăn nghìn và dấu thập
/// phân theo [locale] ("3.000.000" vi, "3,000,000" en, "12,5" vi = 12.5). Người gõ
/// nhầm kiểu ngôn ngữ kia vẫn được hiểu khi không mơ hồ: dấu ngăn nghìn luôn đứng
/// trước đúng 3 chữ số, nên dấu cuối cùng đứng trước 1–2 hay ≥ 4 chữ số là dấu thập
/// phân ("12.5" ở vi = 12.5); dấu lặp lại là dấu ngăn nghìn ("3,000,000" ở vi). Chỉ
/// nhận chữ số và hai dấu này, không nhận phép tính.
String? normalizeAmountInput(String text, {required String locale}) {
  final sep = _separators(locale);
  final t = text.replaceAll(RegExp(r'[\s  ]'), '');
  if (t.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(t)) return null;
  final parts = t.split(RegExp(r'[.,]'));
  final marks = RegExp(r'[.,]').allMatches(t).map((m) => m[0]!).toList();
  final whole = StringBuffer(parts.first);
  String? fraction;
  for (var i = 0; i < marks.length; i++) {
    final chunk = parts[i + 1];
    final last = i == marks.length - 1;
    // Dấu xuất hiện ≥ 2 lần chắc chắn là dấu ngăn nghìn ("3,000,000" gõ ở vi).
    final repeated = marks.where((m) => m == marks[i]).length > 1;
    final isGroup =
        (marks[i] != sep.decimal || repeated) &&
        chunk.length == 3 &&
        fraction == null;
    if (isGroup) {
      if (whole.isEmpty) return null;
      whole.write(chunk);
    } else if (last && fraction == null) {
      fraction = chunk;
    } else {
      return null;
    }
  }
  final w = whole.isEmpty ? '0' : whole.toString();
  return fraction == null ? w : '$w.$fraction';
}

/// Biểu thức bàn phím (`120+3500.5`, luôn dấu "." thập phân, không ngăn nghìn) viết
/// lại để HIỂN THỊ theo [locale]: mỗi số có dấu ngăn nghìn, dấu thập phân của ngôn
/// ngữ ("120+3.500,5" ở vi). Chỉ để hiện; phép tính vẫn đọc biểu thức gốc.
String formatExpressionForDisplay(String expression, {required String locale}) {
  final sep = _separators(locale);
  return expression.replaceAllMapped(RegExp(r'[0-9]+(\.[0-9]*)?|\.[0-9]*'), (
    m,
  ) {
    final s = m[0]!;
    final dot = s.indexOf('.');
    final whole = dot < 0 ? s : s.substring(0, dot);
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(sep.group);
      grouped.write(whole[i]);
    }
    return dot < 0
        ? '$grouped'
        : '$grouped${sep.decimal}${s.substring(dot + 1)}';
  });
}
