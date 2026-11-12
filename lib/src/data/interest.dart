import 'database.dart';
import 'dates.dart';

/// Lãi suất năm, phần trăm × 100, từ lãi suất [rate] (phần trăm × 100) theo
/// kỳ [period] (AC-171): %/tháng × 12 = %/năm.
int annualRateOf(int rate, InterestPeriod period) =>
    period == InterestPeriod.month ? rate * 12 : rate;

/// Mẫu số của lãi một ngày: lãi suất lưu phần trăm × 100 (÷ 10.000) và năm
/// luôn 365 ngày, kể cả năm nhuận (TT 14/2017/TT-NHNN, AC-172).
final _dayDenominator = BigInt.from(365 * 10000);

/// Số ngày từ [from] tới [to] (âm nếu [to] trước) theo lịch, không lệch giờ
/// mùa hè.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Một mốc lãi suất: áp từ [from] (gồm), lãi suất năm phần trăm × 100.
typedef RateStep = ({DateTime from, int annual});

/// Một lần trả theo tiền tệ khoản nợ: phần gốc và phần lãi.
typedef PaymentStep = ({DateTime date, int principal, int interest});

/// Lãi đơn theo ngày trên dư nợ gốc thực tế (D-049, AC-172):
/// lãi = Σ ngày d từ [start] (gồm) tới ngày tính (không gồm) của
/// gốc còn lại cuối ngày d × lãi suất năm của ngày d ÷ 365.
///
/// "Gốc còn lại cuối ngày d" đã trừ mọi lần trả gốc có ngày ≤ d — nên lần
/// trả ngày 01/12 làm lãi từ chính ngày 01/12 tính trên gốc mới (ví dụ
/// AC-173), còn lãi "tới ngày trả" thì không gồm ngày trả. Tính bằng phân số
/// chính xác, làm tròn MỘT lần (nửa lên) tới đơn vị nhỏ nhất.
class DebtInterest {
  DebtInterest({
    required this.principal,
    required this.start,
    required List<RateStep> rates,
    required List<PaymentStep> payments,
  }) : rates = [...rates]..sort((a, b) => a.from.compareTo(b.from)),
       payments = [...payments]..sort((a, b) => a.date.compareTo(b.date));

  /// Dựng từ khoản nợ, các mốc đổi lãi suất và các lần trả đã lưu.
  factory DebtInterest.of(
    Debt debt,
    List<DebtRateChange> changes,
    List<DebtPayment> payments,
  ) {
    final start = parseDateKey(debt.interestStart ?? debt.date);
    final rate = debt.interestRate;
    final period = debt.interestPeriod;
    return DebtInterest(
      principal: debt.originalAmount ?? debt.amount,
      start: start,
      rates: [
        if (rate != null && period != null)
          (from: start, annual: annualRateOf(rate, period)),
        for (final c in changes)
          (from: parseDateKey(c.date), annual: annualRateOf(c.rate, c.period)),
      ],
      payments: [
        for (final p in payments)
          (
            date: parseDateKey(p.date),
            principal: p.originalAmount ?? p.amount,
            interest: p.interest,
          ),
      ],
    );
  }

  /// Số tiền vay gốc theo tiền tệ khoản nợ.
  final int principal;

  /// Ngày bắt đầu tính lãi.
  final DateTime start;

  /// Các mốc lãi suất, cũ trước. Ngày trước mốc đầu tiên: lãi suất 0.
  final List<RateStep> rates;

  /// Các lần trả, cũ trước.
  final List<PaymentStep> payments;

  /// Có lãi suất nào không (khoản nợ "có lãi").
  bool get hasInterest => rates.isNotEmpty;

  /// Tổng gốc đã trả (mọi lần trả).
  int get principalPaid => payments.fold(0, (a, p) => a + p.principal);

  /// Tổng lãi đã trả (mọi lần trả).
  int get interestPaid => payments.fold(0, (a, p) => a + p.interest);

  /// Gốc còn lại sau mọi lần trả; không âm.
  int get principalLeft {
    final left = principal - principalPaid;
    return left < 0 ? 0 : left;
  }

  /// Lãi tích luỹ từ [start] tới [until] (không gồm), làm tròn một lần nửa
  /// lên. [until] không sau [start] → 0.
  int accrued(DateTime until) {
    final num = _accruedNumerator(until);
    if (num <= BigInt.zero) return 0;
    return ((num * BigInt.two + _dayDenominator) ~/
            (_dayDenominator * BigInt.two))
        .toInt();
  }

  BigInt _accruedNumerator(DateTime until) {
    if (!hasInterest || _daysBetween(start, until) <= 0) return BigInt.zero;
    // Các ngày đổi: mốc lãi suất và ngày trả (gốc đổi từ chính ngày trả).
    final cuts = <DateTime>{
      start,
      for (final r in rates)
        if (r.from.isAfter(start) && r.from.isBefore(until)) r.from,
      for (final p in payments)
        if (p.date.isAfter(start) && p.date.isBefore(until)) p.date,
    }.toList()..sort();
    var total = BigInt.zero;
    for (var i = 0; i < cuts.length; i++) {
      final from = cuts[i];
      final to = i + 1 < cuts.length ? cuts[i + 1] : until;
      final days = _daysBetween(from, to);
      if (days <= 0) continue;
      final rate = _rateOn(from);
      if (rate == 0) continue;
      final left = _principalAfter(from);
      if (left <= 0) continue;
      total += BigInt.from(left) * BigInt.from(rate) * BigInt.from(days);
    }
    return total;
  }

  /// Lãi suất năm (× 100) áp cho ngày [day].
  int _rateOn(DateTime day) {
    var rate = 0;
    for (final r in rates) {
      if (r.from.isAfter(day)) break;
      rate = r.annual;
    }
    return rate;
  }

  /// Gốc còn lại cuối ngày [day]: trừ mọi lần trả gốc có ngày ≤ [day].
  int _principalAfter(DateTime day) {
    var left = principal;
    for (final p in payments) {
      if (p.date.isAfter(day)) break;
      left -= p.principal;
    }
    return left;
  }

  /// Lãi tới [day] (không gồm) còn chưa trả: lãi tích luỹ − lãi đã trả;
  /// không âm.
  int unpaidInterest(DateTime day) {
    final left = accrued(day) - interestPaid;
    return left < 0 ? 0 : left;
  }

  /// "Còn lại" tới [day] (AC-174): gốc còn lại + lãi tới [day] chưa trả.
  int remaining(DateTime day) => principalLeft + unpaidInterest(day);

  /// Tổng phải trả ước tính tới [due] nếu không trả thêm (AC-174, nhắc trước
  /// hạn): gốc còn lại + lãi tới [due] chưa trả.
  int dueEstimate(DateTime due) => remaining(due);

  /// Chia [amount] trả ngày [day] theo lãi trước (Interest-first split,
  /// AC-173): lãi = min(số trả, lãi tới ngày trả chưa trả), gốc = phần dư
  /// (không quá gốc còn lại — phần vượt để nơi gọi báo lỗi).
  ({int interest, int principal}) split(int amount, DateTime day) {
    final due = unpaidInterest(day);
    final interest = amount < due ? amount : due;
    return (interest: interest, principal: amount - interest);
  }
}
