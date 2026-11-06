import '../../data/calculator.dart' show maxMinorUnits;
import '../../data/money.dart' show currencyDecimalDigits;
import '../../data/text_fold.dart';
import '../mail/raw_mail.dart' show htmlToText;

/// Bộ đọc email biên lai chuyển tiền đi của MB Bank (F-29, D-033).
///
/// Dart thuần, không cơ sở dữ liệu, không giao diện. Nhận thân thư dạng chữ
/// (đã bỏ HTML) và trả về [MbReceipt] hoặc [MbRejected]; không giữ, không
/// in, không ném lỗi chứa nội dung thư (AC-81, AC-88). Mẫu thật: bảng hai cột
/// "nhãn | giá trị"; sau khi bỏ HTML mỗi dòng bảng là `nhãn<tab>giá trị`, còn
/// thư text thuần có thể là `Nhãn: giá trị` hoặc nhãn một dòng, giá trị dòng
/// kế — đọc được cả ba. Nhãn so không phân biệt hoa thường, dấu, dấu câu và
/// khoảng trắng (kể cả khoảng trắng không ngắt dòng).
sealed class MbParseResult {
  const MbParseResult();
}

/// Một giao dịch chuyển tiền đi THÀNH CÔNG đọc được đủ trường.
class MbReceipt extends MbParseResult {
  const MbReceipt({
    required this.dateKey,
    required this.time,
    required this.reference,
    required this.debitLast4,
    required this.currency,
    required this.amount,
    this.payee,
    this.transferContent,
    this.transactionType,
  });

  /// Ngày giao dịch `YYYY-MM-DD` (giờ trong thân thư, không phải giờ thư tới).
  final String dateKey;

  /// Giờ giao dịch `HH:mm` (bỏ giây).
  final String time;

  /// Số tham chiếu — khoá chống trùng (AC-86).
  final String reference;

  /// 4 số cuối tài khoản trích nợ; số đầy đủ không bao giờ được giữ (AC-88).
  final String debitLast4;

  /// Mã tiền tệ trong ngoặc ở ô số tiền, viết hoa (vd `VND`).
  final String currency;

  /// Số tiền theo đơn vị nhỏ nhất của [currency] (VND: đồng). Luôn > 0.
  final int amount;

  /// Người thụ hưởng đã cắt phần ` - số TK`; null nếu trống.
  final String? payee;

  /// Nội dung chuyển tiền (một dòng, ≤ 500 ký tự); null nếu trống.
  final String? transferContent;

  /// Loại giao dịch (vd "Chuyển tiền nhanh ngoài MB"); chỉ để tham khảo.
  final String? transactionType;

  @override
  String toString() => 'MbReceipt'; // không in nội dung
}

/// Lý do email bị bỏ (chỉ để test/đếm, không có nội dung thư).
enum MbRejection {
  /// Thiếu một trường bắt buộc, hoặc trường không đúng định dạng đã biết.
  unreadable,

  /// `Tình trạng` có nhưng không phải "Giao dịch thành công" (AC-85).
  notSuccessful,
}

/// Email không tạo khoản (AC-85).
class MbRejected extends MbParseResult {
  const MbRejected(this.reason);

  final MbRejection reason;

  @override
  String toString() => 'MbRejected(${reason.name})';
}

/// Đọc thân thư. [body] là chữ của thư: text/plain hoặc HTML đã qua
/// [htmlToText]. Hàm thuần, không ném lỗi.
MbParseResult parseMbReceipt(String body) {
  try {
    return _parse(body);
  } catch (_) {
    return const MbRejected(MbRejection.unreadable);
  }
}

/// Như [parseMbReceipt] cho thân HTML: bỏ thẻ trước (không tải gì).
MbParseResult parseMbReceiptHtml(String html) =>
    parseMbReceipt(htmlToText(html));

enum _Field {
  tradeTime(['ngay gio giao dich']),
  type(['loai giao dich']),
  reference(['so tham chieu']),
  debit(['tai khoan trich no']),
  payee(['nguoi thu huong']),
  amount(['so tien giao dich']),
  content(['noi dung chuyen tien']),
  method(['cach thuc lenh']),
  orderDate(['ngay nhap lenh']),
  time(['thoi gian']),
  status(['tinh trang']);

  const _Field(this.labels);
  final List<String> labels;
}

/// Mọi nhãn đã chuẩn hoá thành danh sách từ, sắp theo độ dài giảm dần.
final List<(_Field, List<String>)> _labels = [
  for (final f in _Field.values)
    for (final l in f.labels) (f, l.split(' ')),
]..sort((a, b) => b.$2.length.compareTo(a.$2.length));

final _oddSpaces = RegExp(r'[   -​  　﻿]');

/// Một từ → chữ thường không dấu chỉ còn chữ-số (bỏ dấu câu như `,` `:`).
String _word(String w) => foldText(w).replaceAll(RegExp(r'[^a-z0-9]'), '');

List<String> _words(String line) => [
  for (final w in line.split(RegExp(r'\s+')))
    if (w.isNotEmpty) w,
];

/// Nhãn ở đầu dòng: (trường, phần còn lại của dòng) hoặc null.
(_Field, String)? _matchLabel(String line) {
  final words = _words(line);
  for (final (field, label) in _labels) {
    if (words.length < label.length) continue;
    var ok = true;
    for (var i = 0; i < label.length; i++) {
      if (_word(words[i]) != label[i]) {
        ok = false;
        break;
      }
    }
    if (!ok) continue;
    // Nhãn phải đứng riêng: từ cuối của nhãn có thể kèm `:`, nhưng phần giá
    // trị bắt đầu từ từ kế tiếp. Bỏ dấu `:`/`-` đứng một mình ngay sau nhãn.
    var rest = words.sublist(label.length);
    while (rest.isNotEmpty && RegExp(r'^[:\-–]+$').hasMatch(rest.first)) {
      rest = rest.sublist(1);
    }
    return (field, rest.join(' '));
  }
  return null;
}

Map<_Field, String> _extract(String body) {
  final lines = [
    for (final raw in body.replaceAll(_oddSpaces, ' ').split(RegExp(r'\r?\n')))
      raw.replaceAll('\t', ' ').trim(),
  ].where((l) => l.isNotEmpty).toList();
  final found = <_Field, String>{};
  for (var i = 0; i < lines.length; i++) {
    final m = _matchLabel(lines[i]);
    if (m == null || found.containsKey(m.$1)) continue;
    var value = m.$2;
    // Nhãn một dòng, giá trị ở dòng kế (không phải nhãn khác).
    if (value.isEmpty && i + 1 < lines.length) {
      if (_matchLabel(lines[i + 1]) == null) value = lines[i + 1];
    }
    found[m.$1] = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return found;
}

const _reject = MbRejected(MbRejection.unreadable);

MbParseResult _parse(String body) {
  final f = _extract(body);

  // Tình trạng: chỉ đúng "Giao dịch thành công" (AC-85). Không có nhãn → không
  // đọc được; có mà khác → bỏ vì không thành công.
  final status = f[_Field.status];
  if (status == null || status.isEmpty) return _reject;
  if (!_isSuccess(status)) return const MbRejected(MbRejection.notSuccessful);

  final when = _parseDateTime(f[_Field.tradeTime] ?? f[_Field.time]);
  if (when == null) return _reject;

  final reference = f[_Field.reference];
  if (reference == null ||
      !RegExp(r'^[A-Za-z0-9]{6,64}$').hasMatch(reference)) {
    return _reject;
  }

  final debit = f[_Field.debit];
  final last4 = debit == null ? null : _debitLast4(debit);
  if (last4 == null) return _reject;

  final money = _parseMoney(f[_Field.amount]);
  if (money == null) return _reject;

  return MbReceipt(
    dateKey: when.$1,
    time: when.$2,
    reference: reference,
    debitLast4: last4,
    currency: money.$1,
    amount: money.$2,
    payee: _payee(f[_Field.payee]),
    transferContent: _clip(f[_Field.content], 500),
    transactionType: _clip(f[_Field.type], 100),
  );
}

bool _isSuccess(String status) {
  final n = foldText(status)
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  return n == 'giao dich thanh cong';
}

/// `dd-MM-yyyy HH:mm[:ss]` → (`yyyy-MM-dd`, `HH:mm`); null nếu sai.
(String, String)? _parseDateTime(String? text) {
  if (text == null) return null;
  final m = RegExp(r'^(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?$')
      .firstMatch(text.trim());
  if (m == null) return null;
  final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
  final h = int.parse(m[4]!), mi = int.parse(m[5]!);
  final s = m[6] == null ? 0 : int.parse(m[6]!);
  final check = DateTime.utc(y, mo, d, h, mi, s);
  // Từ chối ngày/giờ ngoài khoảng (DateTime tự cuộn 31/02 sang tháng sau).
  if (check.year != y ||
      check.month != mo ||
      check.day != d ||
      h > 23 ||
      mi > 59 ||
      s > 59 ||
      y < 2000) {
    return null;
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return ('$y-${two(mo)}-${two(d)}', '${two(h)}:${two(mi)}');
}

/// 4 số cuối của `TÊN - SỐ TK (VND)`; không bao giờ trả số đầy đủ (AC-88).
String? _debitLast4(String value) {
  final m = RegExp(r'(\d{4})\s*(?:\(\s*[A-Za-z]{3}\s*\))?\s*$')
      .firstMatch(value.trim());
  return m?[1];
}

/// Cắt phần ` - số TK` ở cuối tên người thụ hưởng (số có thể đã bị ngân hàng
/// che bằng X). Tên còn lại rỗng thì null.
String? _payee(String? value) {
  if (value == null) return null;
  var v = value.trim();
  final m = RegExp(r'^(.*?)\s+-\s+([0-9Xx*·•.\-]{4,})$').firstMatch(v);
  if (m != null && RegExp(r'[0-9]{2}').hasMatch(m[2]!)) v = m[1]!.trim();
  return _clip(v, 200);
}

String? _clip(String? v, int max) {
  if (v == null) return null;
  final t = v.trim();
  if (t.isEmpty) return null;
  return t.length > max ? t.substring(0, max).trimRight() : t;
}

final _moneyRe = RegExp(r'^\(\s*([A-Za-z]{3})\s*\)\s*([0-9][0-9.,]*)$');

/// `(VND) 48,000.00` → (`VND`, 48000). Dạng chuẩn của MB: `,` ngăn nghìn, `.`
/// thập phân (bộ đọc riêng, không phụ thuộc ngôn ngữ app). Cũng nhận "50.000"
/// cho tiền không có phần lẻ (SPEC AC-84) và `48.000,00`. Phần lẻ khác 0 mà
/// tiền tệ không có chỗ cho nó → sai (null).
(String, int)? _parseMoney(String? text) {
  if (text == null) return null;
  final m = _moneyRe.firstMatch(text.trim());
  if (m == null) return null;
  final currency = m[1]!.toUpperCase();
  final digits = currencyDecimalDigits(currency);
  final raw = m[2]!;

  String whole;
  String frac;
  final lastDot = raw.lastIndexOf('.');
  final lastComma = raw.lastIndexOf(',');
  if (lastDot >= 0 && lastComma >= 0) {
    // Cả hai: dấu đứng sau cùng là thập phân, dấu kia là ngăn nghìn.
    final decimalAt = lastDot > lastComma ? lastDot : lastComma;
    whole = raw.substring(0, decimalAt);
    frac = raw.substring(decimalAt + 1);
  } else if (lastDot >= 0 || lastComma >= 0) {
    final sep = lastDot >= 0 ? '.' : ',';
    final at = lastDot >= 0 ? lastDot : lastComma;
    final count = sep.allMatches(raw).length;
    final after = raw.length - at - 1;
    final grouping =
        count > 1 || (digits == 0 && after == 3) || (sep == ',' && after == 3);
    if (grouping) {
      whole = raw;
      frac = '';
    } else {
      whole = raw.substring(0, at);
      frac = raw.substring(at + 1);
    }
  } else {
    whole = raw;
    frac = '';
  }

  // Phần nguyên: chỉ chữ số sau khi bỏ ngăn nghìn đúng chỗ (nhóm 3 chữ số).
  final groups = whole.split(RegExp(r'[.,]'));
  if (groups.length > 1) {
    if (groups.first.isEmpty ||
        groups.first.length > 3 ||
        groups.skip(1).any((g) => g.length != 3)) {
      return null;
    }
  }
  final wholeDigits = groups.join();
  if (!RegExp(r'^\d+$').hasMatch(wholeDigits)) return null;
  if (frac.isNotEmpty && !RegExp(r'^\d+$').hasMatch(frac)) return null;

  // Phần lẻ: tối đa [digits] chữ số có nghĩa; chữ số thừa phải là 0.
  final significant = frac.length > digits ? frac.substring(0, digits) : frac;
  final extra = frac.length > digits ? frac.substring(digits) : '';
  if (extra.replaceAll('0', '').isNotEmpty) return null;
  final padded = significant.padRight(digits, '0');

  final minor = int.tryParse('$wholeDigits$padded');
  if (minor == null || minor <= 0 || minor > maxMinorUnits) return null;
  return (currency, minor);
}
