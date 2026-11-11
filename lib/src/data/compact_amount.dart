/// Số tiền rút gọn cho ô ngày của Lịch (AC-114): vi "50k", "1,2tr", "3tỷ";
/// en "50K", "1.2M", "3B". Không kèm ký hiệu tiền (ô quá hẹp).
///
/// Dưới 1.000 đơn vị chính thì viết nguyên số (làm tròn tới đơn vị chính; dưới
/// 1 mà lớn hơn 0 thì "<1"). Từ 1.000 trở lên dùng hậu tố; có một chữ số thập
/// phân khi phần số < 10 ("1,2tr"), từ 10 trở lên làm tròn nguyên ("12tr").
/// Làm tròn nửa lên và lên bậc khi chạm 1.000 của bậc dưới (999.600 → "1tr",
/// không phải "1000k"). Tính bằng số nguyên.
///
/// [minorUnits] theo đơn vị nhỏ nhất (≤ 0 → "0"); [decimalDigits] là số chữ
/// số lẻ của tiền tệ (VND 0, USD 2). [languageCode] `vi` dùng dấu phẩy thập
/// phân và hậu tố k/tr/tỷ; mọi mã khác dùng dấu chấm và K/M/B.
String compactAmount(
  int minorUnits, {
  required int decimalDigits,
  required String languageCode,
}) {
  if (minorUnits <= 0) return '0';
  final vi = languageCode == 'vi';
  var unit = 1;
  for (var i = 0; i < decimalDigits; i++) {
    unit *= 10;
  }
  final whole = (minorUnits * 2 + unit) ~/ (2 * unit);
  if (whole == 0) return '<1';
  if (whole < 1000) return '$whole';

  final suffixes = vi ? const ['k', 'tr', 'tỷ'] : const ['K', 'M', 'B'];
  var level = whole < 1000000 ? 0 : (whole < 1000000000 ? 1 : 2);

  // Số phần mười của bậc [l]: minor / (unit × 1000^(l+1)) × 10, làm tròn nửa lên.
  int tenthsAt(int l) {
    var scale = unit;
    for (var i = 0; i <= l; i++) {
      scale *= 1000;
    }
    return (minorUnits * 20 + scale) ~/ (2 * scale);
  }

  var tenths = tenthsAt(level);
  if (tenths >= 9995 && level < 2) {
    // Làm tròn sẽ ra "1000" của bậc này: lên bậc kế.
    level++;
    tenths = tenthsAt(level);
  }
  final String number;
  if (tenths < 100 && tenths % 10 != 0) {
    number = '${tenths ~/ 10}${vi ? ',' : '.'}${tenths % 10}';
  } else {
    number = '${(tenths + 5) ~/ 10}';
  }
  return '$number${suffixes[level]}';
}
