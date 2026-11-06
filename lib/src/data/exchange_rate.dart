import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Tỉ giá "1 đơn vị tiền cũ = [numerator]/[denominator] đơn vị tiền mới" (D-025).
///
/// Giữ dạng phân số số nguyên để quy đổi và làm tròn chính xác (không qua số
/// thực khi nhân với số tiền, D-005). Luôn > 0.
class ExchangeRate {
  ExchangeRate._(this.numerator, this.denominator)
    : assert(numerator > BigInt.zero && denominator > BigInt.zero);

  final BigInt numerator;
  final BigInt denominator;

  /// Đọc số thập phân dạng "26000.5", "0.0000385" hay "3.85e-5" (dấu "." là dấu
  /// thập phân, không có dấu ngăn nghìn). Null nếu sai hoặc ≤ 0.
  static ExchangeRate? tryParse(String text) {
    final m = RegExp(r'^\+?([0-9]*)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]{1,3}))?$')
        .firstMatch(text.trim());
    if (m == null) return null;
    final whole = m[1] ?? '';
    final fraction = m[2] ?? '';
    if (whole.isEmpty && fraction.isEmpty) return null;
    final exponent = int.parse(m[3] ?? '0');
    var numerator = BigInt.parse(
      '$whole$fraction'.isEmpty ? '0' : '$whole$fraction',
    );
    var denominator = BigInt.from(10).pow(fraction.length);
    if (exponent > 0) numerator *= BigInt.from(10).pow(exponent);
    if (exponent < 0) denominator *= BigInt.from(10).pow(-exponent);
    if (numerator <= BigInt.zero) return null;
    // Không rút gọn: mẫu số giữ là lũy thừa của 10 để [toStorage] ghi lại đúng.
    return ExchangeRate._(numerator, denominator);
  }

  /// Tỉ giá từ số thực của nguồn tỉ giá, giữ 12 chữ số có nghĩa (dư so với độ
  /// chính xác của nguồn). Null nếu không hữu hạn hoặc ≤ 0.
  static ExchangeRate? fromDouble(double value) {
    if (!value.isFinite || value <= 0) return null;
    return tryParse(value.toStringAsPrecision(12));
  }

  /// Đọc chữ do [toStorage] ghi: số thập phân như [tryParse] hoặc phân số
  /// "tử/mẫu" (tỉ giá chéo, tỉ giá đảo chiều). Null nếu sai hoặc ≤ 0.
  static ExchangeRate? fromStorage(String text) {
    final m = RegExp(r'^([0-9]+)/([0-9]+)$').firstMatch(text.trim());
    if (m == null) return tryParse(text);
    final numerator = BigInt.parse(m[1]!);
    final denominator = BigInt.parse(m[2]!);
    if (numerator <= BigInt.zero || denominator <= BigInt.zero) return null;
    return ExchangeRate._(numerator, denominator);
  }

  /// "1 tiền mới = ? tiền cũ".
  ExchangeRate get inverse => ExchangeRate._(denominator, numerator);

  /// Thương hai tỉ giá, chính xác (phân số, rút gọn): tỉ giá chéo
  /// "1 A = (b / a) B" từ hai tỉ giá cùng gốc (D-029).
  ExchangeRate operator /(ExchangeRate other) {
    final n = numerator * other.denominator;
    final d = denominator * other.numerator;
    final g = n.gcd(d);
    return ExchangeRate._(n ~/ g, d ~/ g);
  }

  /// Chỉ để hiển thị.
  double toDouble() => numerator / denominator;

  /// Dạng gọn để lưu, đọc lại bằng [fromStorage] ra đúng giá trị: thập phân
  /// ("0.0000385") khi mẫu số là lũy thừa của 10 (tỉ giá đọc từ chữ), không
  /// thì phân số "tử/mẫu" (tỉ giá chéo, tỉ giá đảo chiều — D-029).
  String toStorage() {
    var d = denominator;
    var zeros = 0;
    while (d % BigInt.from(10) == BigInt.zero) {
      d ~/= BigInt.from(10);
      zeros++;
    }
    if (d != BigInt.one) return '$numerator/$denominator';
    final digits = numerator.toString();
    if (zeros == 0) return digits;
    final padded = digits.padLeft(zeros + 1, '0');
    final cut = padded.length - zeros;
    return '${padded.substring(0, cut)}.${padded.substring(cut)}';
  }

  @override
  bool operator ==(Object other) =>
      other is ExchangeRate &&
      other.numerator * denominator == numerator * other.denominator;

  @override
  int get hashCode => toDouble().hashCode;

  @override
  String toString() => 'ExchangeRate(${toStorage()})';
}

/// Quy đổi [amount] (đơn vị nhỏ nhất của tiền cũ, có [fromDigits] chữ số thập
/// phân) sang đơn vị nhỏ nhất của tiền mới ([toDigits]) theo [rate]. Làm tròn
/// half-up đối xứng (0,5 làm tròn ra xa số 0: 2,5 → 3, −2,5 → −3). Tính bằng
/// BigInt nên không tràn số và không sai số làm tròn.
BigInt convertMinorUnits(
  int amount,
  ExchangeRate rate, {
  required int fromDigits,
  required int toDigits,
}) {
  final ten = BigInt.from(10);
  final num = BigInt.from(amount).abs() * rate.numerator * ten.pow(toDigits);
  final den = rate.denominator * ten.pow(fromDigits);
  final rounded = (num * BigInt.two + den) ~/ (den * BigInt.two);
  return amount < 0 ? -rounded : rounded;
}

/// Bảng tỉ giá: số đơn vị mỗi tiền tệ cho 1 [base] (D-025). Lưu lại trong bảng
/// `settings` để lần sau mất mạng vẫn điền sẵn được tỉ giá gần nhất.
class RateTable {
  const RateTable({
    required this.base,
    required this.date,
    required this.rates,
  });

  final String base;

  /// Ngày nguồn cập nhật bảng, `YYYY-MM-DD` theo giờ UTC.
  final String date;
  final Map<String, double> rates;

  /// Tỉ giá chéo "1 [from] = ? [to]" = b / a tính bằng phân số (không qua số
  /// thực) nên A→B và B→A cùng bảng là nghịch đảo đúng (D-029); null nếu bảng
  /// thiếu một trong hai mã.
  ExchangeRate? rate(String from, String to) {
    final a = from == base ? 1.0 : rates[from];
    final b = to == base ? 1.0 : rates[to];
    if (a == null || b == null) return null;
    final ra = ExchangeRate.fromDouble(a);
    final rb = ExchangeRate.fromDouble(b);
    if (ra == null || rb == null) return null;
    return rb / ra;
  }

  String toJson() => jsonEncode({'base': base, 'date': date, 'rates': rates});

  /// Null nếu chữ hỏng (cache cũ không làm hỏng luồng đổi tiền tệ).
  static RateTable? tryFromJson(String? text) {
    if (text == null) return null;
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      return RateTable(
        base: map['base'] as String,
        date: map['date'] as String,
        rates: {
          for (final e in (map['rates'] as Map<String, dynamic>).entries)
            e.key: (e.value as num).toDouble(),
        },
      );
    } catch (_) {
      return null;
    }
  }
}

/// Loại lỗi khi tải tỉ giá: [offline] không kết nối được (mất mạng, hết giờ
/// chờ), [unavailable] máy chủ trả lỗi hoặc dữ liệu không đọc được.
enum ExchangeRateError { offline, unavailable }

class ExchangeRateException implements Exception {
  const ExchangeRateException(this.kind, [this.detail]);

  final ExchangeRateError kind;
  final Object? detail;

  @override
  String toString() => 'ExchangeRateException($kind, $detail)';
}

/// Nguồn tỉ giá. Lớp trừu tượng để test thay bằng nguồn giả, không gọi mạng.
abstract class ExchangeRateSource {
  /// Tên hiển thị cho dòng ghi công nguồn.
  String get attribution;

  /// Trang của nguồn (link ghi công).
  Uri get homepage;

  /// Tải bảng tỉ giá mới nhất. Ném [ExchangeRateException].
  Future<RateTable> fetch();
}

/// Một lần GET trả về chữ của thân phản hồi. Ném [ExchangeRateException].
typedef HttpGetText = Future<String> Function(Uri uri, Duration timeout);

/// Thân phản hồi tối đa (bảng thật ~4 KB); lớn hơn coi như dữ liệu lỗi.
const _maxResponseBytes = 256 * 1024;

/// GET bằng `dart:io HttpClient`: chỉ HTTPS, không theo chuyển hướng, không
/// cookie, không gửi gì ngoài yêu cầu GET (không có dữ liệu người dùng).
Future<String> ioHttpGetText(Uri uri, Duration timeout) async {
  if (uri.scheme != 'https') {
    throw ExchangeRateException(ExchangeRateError.unavailable, 'not https');
  }
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..idleTimeout = timeout;
  try {
    Future<String> run() async {
      final request = await client.getUrl(uri);
      request
        ..followRedirects = false
        ..persistentConnection = false
        ..headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw ExchangeRateException(
          ExchangeRateError.unavailable,
          'HTTP ${response.statusCode}',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > _maxResponseBytes) {
          throw const ExchangeRateException(
            ExchangeRateError.unavailable,
            'too large',
          );
        }
      }
      return utf8.decode(bytes);
    }

    return await run().timeout(timeout);
  } on ExchangeRateException {
    rethrow;
  } on TimeoutException catch (e) {
    throw ExchangeRateException(ExchangeRateError.offline, e);
  } on SocketException catch (e) {
    throw ExchangeRateException(ExchangeRateError.offline, e);
  } on HandshakeException catch (e) {
    throw ExchangeRateException(ExchangeRateError.offline, e);
  } on HttpException catch (e) {
    throw ExchangeRateException(ExchangeRateError.offline, e);
  } on FormatException catch (e) {
    throw ExchangeRateException(ExchangeRateError.unavailable, e);
  } finally {
    client.close(force: true);
  }
}

/// ExchangeRate-API, gói "Open Access" (https://www.exchangerate-api.com/docs/free):
/// miễn phí, không cần khóa API, cho dùng cả mục đích thương mại, BẮT BUỘC ghi
/// công nguồn kèm link, giới hạn tần suất theo IP (vượt thì HTTP 429 trong 20
/// phút), cập nhật mỗi ngày, cấm phân phối lại dữ liệu.
///
/// Luôn lấy bảng gốc USD: bảng gốc VND chỉ có 6 chữ số thập phân (1 VND =
/// 0.000039 USD, lệch ~1%), còn bảng gốc USD đủ chính xác để tính tỉ giá chéo.
/// Yêu cầu không chứa tiền tệ của người dùng.
class ErApiRateSource implements ExchangeRateSource {
  const ErApiRateSource({
    this.get = ioHttpGetText,
    this.timeout = const Duration(seconds: 10),
  });

  static final endpoint = Uri.parse('https://open.er-api.com/v6/latest/USD');

  final HttpGetText get;
  final Duration timeout;

  @override
  String get attribution => 'Rates By Exchange Rate API';

  @override
  Uri get homepage => Uri.parse('https://www.exchangerate-api.com');

  @override
  Future<RateTable> fetch() async {
    final String body;
    try {
      // Chặn thêm một lớp: [get] nào cũng không được treo quá [timeout].
      body = await get(endpoint, timeout).timeout(timeout);
    } on TimeoutException catch (e) {
      throw ExchangeRateException(ExchangeRateError.offline, e);
    }
    return parseErApiResponse(body);
  }
}

/// Đọc JSON của open.er-api.com. Ném [ExchangeRateException] khi sai dạng.
RateTable parseErApiResponse(String body) {
  Never bad(String why) =>
      throw ExchangeRateException(ExchangeRateError.unavailable, why);
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    bad('json');
  }
  if (decoded is! Map<String, dynamic>) bad('not object');
  if (decoded['result'] != 'success') bad('result ${decoded['result']}');
  final base = decoded['base_code'];
  final rawRates = decoded['rates'];
  final updated = decoded['time_last_update_unix'];
  if (base is! String || rawRates is! Map<String, dynamic> || updated is! int) {
    bad('fields');
  }
  final rates = <String, double>{};
  for (final e in rawRates.entries) {
    final v = e.value;
    if (v is num &&
        v.isFinite &&
        v > 0 &&
        RegExp(r'^[A-Z]{3}$').hasMatch(e.key)) {
      rates[e.key] = v.toDouble();
    }
  }
  if (rates.isEmpty) bad('no rates');
  final day = DateTime.fromMillisecondsSinceEpoch(updated * 1000, isUtc: true);
  String two(int v) => v.toString().padLeft(2, '0');
  return RateTable(
    base: base,
    date: '${day.year}-${two(day.month)}-${two(day.day)}',
    rates: rates,
  );
}
