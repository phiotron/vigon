import 'calculator.dart';
import 'database.dart';
import 'money.dart';
import 'rate_repository.dart';

/// Tổng tiền gom theo từng tiền tệ gốc (D-042, AC-148).
///
/// Mỗi phần là số nguyên đơn vị nhỏ nhất của tiền tệ đó, cộng chính xác. Chỉ
/// khi cần một con số theo một tiền tệ khác mới quy đổi — cộng các phân số
/// bằng BigInt rồi làm tròn MỘT lần — nên không bao giờ có sai số dồn và
/// không bao giờ phải quy ngược một số đã làm tròn.
class MoneyBag {
  MoneyBag([Map<String, int>? parts]) : _parts = {...?parts};

  final Map<String, int> _parts;

  /// Các phần khác 0, theo tiền tệ.
  Map<String, int> get parts => {
    for (final e in _parts.entries)
      if (e.value != 0) e.key: e.value,
  };

  bool get isZero => _parts.values.every((v) => v == 0);

  /// Tiền tệ duy nhất khi chỉ có một phần khác 0; null nếu 0 hoặc nhiều tiền tệ.
  String? get singleCurrency {
    final p = parts;
    return p.length == 1 ? p.keys.first : null;
  }

  void add(String currency, int minor) {
    if (minor == 0) return;
    _parts[currency] = (_parts[currency] ?? 0) + minor;
  }

  void addBag(MoneyBag other) {
    for (final e in other._parts.entries) {
      add(e.key, e.value);
    }
  }

  MoneyBag copy() => MoneyBag(_parts);

  /// Các tiền tệ không quy được sang [target] (thiếu tỷ giá).
  Set<String> missing(CurrencyService service, String target) => {
    for (final c in parts.keys)
      if (c != target && service.table.rate(c, target) == null) c,
  };

  /// Tổng theo [target], làm tròn half-up một lần. Phần thiếu tỷ giá: bỏ qua
  /// khi [skipMissing] (AC-134: không vào tổng), không thì trả null.
  int? convertTo(
    CurrencyService service,
    String target, {
    bool skipMissing = true,
  }) {
    final ten = BigInt.from(10);
    final toDigits = currencyDecimalDigits(target);
    var num = BigInt.zero;
    var den = BigInt.one;
    for (final e in parts.entries) {
      BigInt n, d;
      if (e.key == target) {
        n = BigInt.from(e.value);
        d = BigInt.one;
      } else {
        final rate = service.table.rate(e.key, target);
        if (rate == null) {
          if (skipMissing) continue;
          return null;
        }
        n = BigInt.from(e.value) * rate.numerator * ten.pow(toDigits);
        d = rate.denominator * ten.pow(currencyDecimalDigits(e.key));
      }
      num = num * d + n * den;
      den = den * d;
      final g = num.gcd(den);
      if (g > BigInt.one) {
        num ~/= g;
        den ~/= g;
      }
    }
    final abs = num.abs();
    final rounded = (abs * BigInt.two + den) ~/ (den * BigInt.two);
    final value = num.isNegative ? -rounded : rounded;
    if (value.abs() > BigInt.from(maxMinorUnits)) return null;
    return value.toInt();
  }

  @override
  String toString() => 'MoneyBag($parts)';
}

/// Số gốc của khoản (dữ liệu cũ chưa có cột gốc: số dẫn xuất chính là số gốc).
int entryOriginal(Entry e) => e.originalAmount ?? e.amount;

/// Số nhận gốc của chuyển tiền.
int entryReceivedOriginal(Entry e) =>
    e.toOriginalAmount ?? e.originalAmount ?? e.toAmount ?? e.amount;

/// Tiền tệ nhận của chuyển tiền.
String entryReceivedCurrency(Entry e) => e.toCurrency ?? e.currency;

/// Số dư mọi tài khoản, gom theo tiền tệ gốc (AC-148): số dư ban đầu + thu −
/// chi + nhận − chuyển đi.
Map<int, MoneyBag> balanceBags(List<Account> accounts, List<Entry> entries) {
  final result = <int, MoneyBag>{
    for (final a in accounts)
      a.id: MoneyBag()
        ..add(
          a.initialCurrency ?? a.currency,
          a.initialBalanceOriginal ?? a.initialBalance,
        ),
  };
  MoneyBag bag(int id) => result[id] ??= MoneyBag();
  for (final e in entries) {
    final original = entryOriginal(e);
    switch (e.type) {
      case EntryType.income:
        bag(e.accountId).add(e.currency, original);
      case EntryType.expense:
        bag(e.accountId).add(e.currency, -original);
      case EntryType.transfer:
        bag(e.accountId).add(e.currency, -original);
        final to = e.toAccountId;
        if (to != null) {
          bag(to).add(entryReceivedCurrency(e), entryReceivedOriginal(e));
        }
    }
  }
  return result;
}
