import 'dates.dart';
import 'database.dart';
import 'money_sum.dart';
import 'period.dart';
import 'rate_repository.dart';
import 'summary.dart';

/// Quy một túi tiền (gom theo tiền tệ gốc) ra MỘT số theo Tiền tệ chính, làm
/// tròn một lần (D-042, AC-148). Phần thiếu tỷ giá không vào tổng (AC-134).
typedef MoneyConvert = int Function(MoneyBag bag);

/// Quy đổi theo Tiền tệ chính của [service].
MoneyConvert convertWith(CurrencyService service) =>
    (bag) => bag.convertTo(service, service.primary) ?? 0;

/// Chỉ dùng khi mọi số cùng một tiền tệ (test): cộng thẳng các phần.
int sumParts(MoneyBag bag) => bag.parts.values.fold(0, (a, b) => a + b);

/// Thu và chi của một ngày theo từng tiền tệ gốc (F-35, F-36, F-38). Chuyển
/// tiền không tính là thu hay chi (AC-19) và mục hàng đợi chưa là khoản
/// (AC-95), nên không có ở đây.
class DailyFlow {
  DailyFlow(this.date, [MoneyBag? income, MoneyBag? expense])
    : income = income ?? MoneyBag(),
      expense = expense ?? MoneyBag();

  /// Ngày `YYYY-MM-DD` (D-005).
  final String date;
  final MoneyBag income;
  final MoneyBag expense;

  bool get isEmpty => income.isZero && expense.isZero;

  @override
  String toString() => 'DailyFlow($date, +$income, -$expense)';
}

/// Gom các khoản thành thu chi từng ngày theo số gốc; bỏ chuyển tiền. Dùng cho
/// test và nơi đã có sẵn danh sách khoản; truy vấn thật gom bằng SQL.
List<DailyFlow> dailyFlowOf(Iterable<EntryView> rows) {
  final byDate = <String, DailyFlow>{};
  for (final r in rows) {
    final e = r.entry;
    switch (e.type) {
      case EntryType.income:
        (byDate[e.date] ??= DailyFlow(
          e.date,
        )).income.add(e.currency, entryOriginal(e));
      case EntryType.expense:
        (byDate[e.date] ??= DailyFlow(
          e.date,
        )).expense.add(e.currency, entryOriginal(e));
      case EntryType.transfer:
      case EntryType.debt:
        break;
    }
  }
  final dates = byDate.keys.toList()..sort();
  return [for (final d in dates) byDate[d]!];
}

/// Đơn vị của một cột ở biểu đồ Thống kê (AC-109).
enum BucketUnit { day, month, year }

/// Một cột: thu và chi (theo Tiền tệ chính) từ [start] tới [end] (tính cả hai
/// đầu). Cột đầu và cuối bị cắt theo kỳ, nên các cột phủ đúng kỳ.
class FlowBucket {
  const FlowBucket({
    required this.unit,
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
  });

  final BucketUnit unit;
  final DateTime start;
  final DateTime end;
  final int income;
  final int expense;
}

/// Đơn vị cột theo loại kỳ (AC-109): Ngày → một cặp cột; Tuần → 7 ngày; Tháng →
/// từng ngày; Năm → 12 tháng; Tất cả → từng năm; khoảng tùy chọn ≤ 31 ngày →
/// từng ngày, ≤ 366 ngày → từng tháng, dài hơn → từng năm.
BucketUnit bucketUnitFor(Period period) {
  switch (period.type) {
    case PeriodType.day:
    case PeriodType.week:
    case PeriodType.month:
      return BucketUnit.day;
    case PeriodType.year:
      return BucketUnit.month;
    case PeriodType.all:
      return BucketUnit.year;
    case PeriodType.custom:
      final days = period.end.difference(period.start).inDays + 1;
      if (days <= 31) return BucketUnit.day;
      if (days <= 366) return BucketUnit.month;
      return BucketUnit.year;
  }
}

String _bucketKey(String date, BucketUnit unit) => switch (unit) {
  BucketUnit.day => date,
  BucketUnit.month => date.substring(0, 7),
  BucketUnit.year => date.substring(0, 4),
};

/// Khoảng ngày của từng cột (đã cắt theo kỳ) của [period]. Kỳ "Tất cả" không
/// có ngày đầu cuối thật nên lấy từ ngày của khoản đầu tới ngày của khoản cuối
/// trong [flows]; chưa có khoản nào thì không có cột.
List<({BucketUnit unit, DateTime start, DateTime end})> bucketRanges(
  Period period,
  Iterable<DailyFlow> flows,
) {
  final unit = bucketUnitFor(period);
  var start = period.start, end = period.end;
  if (period.type == PeriodType.all) {
    String? first, last;
    for (final f in flows) {
      if (first == null || f.date.compareTo(first) < 0) first = f.date;
      if (last == null || f.date.compareTo(last) > 0) last = f.date;
    }
    if (first == null || last == null) return const [];
    start = parseDateKey(first);
    end = parseDateKey(last);
  }
  final out = <({BucketUnit unit, DateTime start, DateTime end})>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    final DateTime natural = switch (unit) {
      BucketUnit.day => cursor,
      BucketUnit.month => DateTime(cursor.year, cursor.month + 1, 0),
      BucketUnit.year => DateTime(cursor.year, 12, 31),
    };
    final bucketEnd = natural.isAfter(end) ? end : natural;
    out.add((unit: unit, start: cursor, end: bucketEnd));
    cursor = addDays(bucketEnd, 1);
  }
  return out;
}

/// Cột thu/chi của Thống kê (AC-109). [flows] là thu chi từng ngày đã lọc theo
/// tài khoản; ngày ngoài kỳ bị bỏ qua. Mỗi cột cộng số gốc theo tiền tệ rồi
/// mới quy đổi một lần bằng [convert] (AC-148). Kỳ không có khoản thu chi nào
/// cho danh sách rỗng (trạng thái trống, AC-110).
List<FlowBucket> flowBuckets(
  Period period,
  Iterable<DailyFlow> flows,
  MoneyConvert convert,
) {
  final inPeriod = flows.where((f) => period.contains(f.date)).toList();
  if (inPeriod.every((f) => f.isEmpty)) return const [];
  final ranges = bucketRanges(period, inPeriod);
  if (ranges.isEmpty) return const [];
  final unit = ranges.first.unit;
  final index = <String, int>{
    for (final (i, r) in ranges.indexed) _bucketKey(dateKey(r.start), unit): i,
  };
  final income = [for (final _ in ranges) MoneyBag()];
  final expense = [for (final _ in ranges) MoneyBag()];
  for (final f in inPeriod) {
    final i = index[_bucketKey(f.date, unit)];
    if (i == null) continue;
    income[i].addBag(f.income);
    expense[i].addBag(f.expense);
  }
  return [
    for (final (i, r) in ranges.indexed)
      FlowBucket(
        unit: unit,
        start: r.start,
        end: r.end,
        income: convert(income[i]),
        expense: convert(expense[i]),
      ),
  ];
}

/// Ngày chi nhiều nhất (AC-109): bằng nhau thì lấy ngày sớm hơn.
class BiggestDay {
  const BiggestDay(this.date, this.expense);

  final DateTime date;

  /// Theo Tiền tệ chính.
  final int expense;
}

/// Ngày chi nhiều nhất trong [flows] (so theo Tiền tệ chính, mỗi ngày quy đổi
/// một lần); null khi không có khoản chi nào. Màn ẩn thẻ này ở kỳ Ngày.
BiggestDay? biggestSpendingDay(
  Iterable<DailyFlow> flows,
  MoneyConvert convert,
) {
  String? bestDate;
  var best = 0;
  for (final f in flows) {
    if (f.expense.isZero) continue;
    final spent = convert(f.expense);
    if (spent <= 0) continue;
    if (bestDate == null ||
        spent > best ||
        (spent == best && f.date.compareTo(bestDate) < 0)) {
      bestDate = f.date;
      best = spent;
    }
  }
  return bestDate == null ? null : BiggestDay(parseDateKey(bestDate), best);
}

/// [n] danh mục chi nhiều nhất của kỳ từ tổng kỳ đã cộng chính xác (D-042),
/// kèm số tiền và phần trăm trên tổng chi (AC-109). Bằng tiền thì danh mục có
/// id nhỏ hơn đứng trước, nên thứ tự không đổi giữa các lần tính.
List<CategoryTotal> topExpenseCategories(PeriodSummary summary, {int n = 5}) {
  final all = [...summary.expenseByCategory]
    ..sort((a, b) {
      final byTotal = b.total.compareTo(a.total);
      return byTotal != 0 ? byTotal : a.category.id.compareTo(b.category.id);
    });
  return all.take(n).toList();
}

/// Tổng số dư của mọi tài khoản (kể cả đã ẩn) theo từng ngày, gom theo tiền
/// tệ gốc (AC-109, đường lịch sử; AC-148). Giữ số dư đầu và thay đổi ròng mỗi
/// ngày; chuyển tiền cùng tiền tệ tự triệt tiêu, khác tiền tệ thì một phần
/// trừ ở tiền gửi, một phần cộng ở tiền nhận — như số dư từng tài khoản.
class BalanceLedger {
  BalanceLedger({
    required MoneyBag initial,
    required Map<String, MoneyBag> netByDate,
  }) : initial = initial.copy(),
       _dates = netByDate.keys.toList()..sort() {
    final running = initial.copy();
    for (final d in _dates) {
      running.addBag(netByDate[d]!);
      _prefix.add(running.copy());
    }
  }

  /// Tổng số dư ban đầu của mọi tài khoản.
  final MoneyBag initial;
  final List<String> _dates;
  final List<MoneyBag> _prefix = [];

  /// Tổng số dư cuối ngày [dateKeyValue] (đã tính mọi khoản tới hết ngày đó).
  MoneyBag at(String dateKeyValue) {
    var lo = 0, hi = _dates.length; // số ngày có thay đổi ≤ dateKeyValue
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_dates[mid].compareTo(dateKeyValue) <= 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo == 0 ? initial : _prefix[lo - 1];
  }

  /// Tổng số dư hiện tại (sau mọi khoản).
  MoneyBag get total => _prefix.isEmpty ? initial : _prefix.last;
}

/// Một điểm của đường lịch sử số dư: số dư (Tiền tệ chính) cuối [bucket].
class BalancePoint {
  const BalancePoint(this.bucket, this.balance);

  final FlowBucket bucket;
  final int balance;
}

/// Đường lịch sử tổng số dư: giá trị cuối mỗi cột (AC-109), mỗi điểm cộng gốc
/// rồi quy đổi một lần. Cột bắt đầu sau [today] bị bỏ để đường không kéo dài
/// phẳng vào tương lai.
List<BalancePoint> balanceHistory(
  List<FlowBucket> buckets,
  BalanceLedger ledger,
  MoneyConvert convert, {
  required DateTime today,
}) => [
  for (final b in buckets)
    if (!b.start.isAfter(today))
      BalancePoint(b, convert(ledger.at(dateKey(b.end)))),
];

/// Một tháng của biểu đồ cột Tổng quan (AC-107), theo Tiền tệ chính.
class MonthFlow {
  const MonthFlow(this.period, this.income, this.expense);

  final Period period;
  final int income;
  final int expense;

  /// Thu − chi theo Tiền tệ chính. Tổng quan dùng [OverviewData.net] (cộng
  /// gốc rồi mới quy đổi) cho tháng đang chọn.
  int get net => income - expense;
}

/// Các tháng (theo ngày bắt đầu tháng) từ `count - 1` tháng trước [month] tới
/// [month], cũ nhất trước (AC-107: 6 tháng kết thúc ở tháng đang chọn).
List<Period> monthsEndingAt(Period month, {int count = 6}) => [
  for (var i = count - 1; i >= 0; i--) month.shift(-i),
];

/// Thu chi gốc của từng tháng trong [months] (chưa quy đổi).
List<({MoneyBag income, MoneyBag expense})> monthlyBags(
  List<Period> months,
  Iterable<DailyFlow> flows,
) {
  final out = [
    for (final _ in months) (income: MoneyBag(), expense: MoneyBag()),
  ];
  for (final f in flows) {
    for (var i = 0; i < months.length; i++) {
      if (months[i].contains(f.date)) {
        out[i].income.addBag(f.income);
        out[i].expense.addBag(f.expense);
        break;
      }
    }
  }
  return out;
}

/// Thu chi từng tháng trong [months], mỗi tháng quy đổi một lần.
List<MonthFlow> monthlyFlows(
  List<Period> months,
  Iterable<DailyFlow> flows,
  MoneyConvert convert,
) {
  final bags = monthlyBags(months, flows);
  return [
    for (final (i, m) in months.indexed)
      MonthFlow(m, convert(bags[i].income), convert(bags[i].expense)),
  ];
}

/// Chiều đổi so với tháng trước (AC-107).
enum ChangeDirection { up, down, same }

/// % thay đổi so với tháng trước, làm tròn tới số nguyên (nửa lên).
class PercentChange {
  const PercentChange(this.direction, this.percent);

  final ChangeDirection direction;

  /// Giá trị tuyệt đối, ≥ 0; 0 khi [direction] là [ChangeDirection.same].
  final int percent;
}

/// % thay đổi từ [previous] sang [current]; null khi [previous] bằng 0 (hiện
/// "—", AC-107). Tính bằng số nguyên, không qua số thực. Thay đổi nhỏ tới mức
/// làm tròn về 0% thì coi là không đổi.
PercentChange? percentChange(int previous, int current) {
  if (previous == 0) return null;
  final diff = current - previous;
  if (diff == 0) return const PercentChange(ChangeDirection.same, 0);
  final base = previous.abs();
  final pct = (diff.abs() * 200 + base) ~/ (2 * base);
  if (pct == 0) return const PercentChange(ChangeDirection.same, 0);
  final up = (diff > 0) == (previous > 0);
  return PercentChange(up ? ChangeDirection.up : ChangeDirection.down, pct);
}

/// Dữ liệu một màn Tổng quan (AC-107), mọi số theo Tiền tệ chính.
class OverviewData {
  const OverviewData({
    required this.month,
    required this.months,
    required this.net,
    required this.totalBalance,
    required this.budget,
  });

  /// Gom từ thu chi gốc 6 tháng: mỗi tháng quy đổi một lần; "thu − chi" của
  /// tháng đang chọn cộng gốc (thu trừ chi theo từng tiền tệ) rồi mới quy đổi.
  factory OverviewData.of({
    required Period month,
    required List<Period> months,
    required Iterable<DailyFlow> flows,
    required MoneyBag totalBalance,
    required int? budget,
    required MoneyConvert convert,
  }) {
    final bags = monthlyBags(months, flows);
    final current = bags.last;
    final net = current.income.copy();
    for (final e in current.expense.parts.entries) {
      net.add(e.key, -e.value);
    }
    return OverviewData(
      month: month,
      months: [
        for (final (i, m) in months.indexed)
          MonthFlow(m, convert(bags[i].income), convert(bags[i].expense)),
      ],
      net: convert(net),
      totalBalance: convert(totalBalance),
      budget: budget,
    );
  }

  /// Tháng đang chọn.
  final Period month;

  /// 6 tháng kết thúc ở [month], cũ nhất trước.
  final List<MonthFlow> months;

  /// Thu − chi của tháng đang chọn.
  final int net;

  /// Tổng số dư mọi tài khoản, kể cả đã ẩn; không gồm khoản nợ.
  final int totalBalance;

  /// Hạn mức chi tháng; null là chưa đặt.
  final int? budget;

  MonthFlow get current => months.last;
  MonthFlow? get previous =>
      months.length < 2 ? null : months[months.length - 2];

  /// Ngân sách còn lại = hạn mức − đã chi; âm là vượt. Null khi chưa đặt.
  int? get budgetLeft => budget == null ? null : budget! - current.expense;

  PercentChange? get expenseChange => previous == null
      ? null
      : percentChange(previous!.expense, current.expense);

  PercentChange? get incomeChange =>
      previous == null ? null : percentChange(previous!.income, current.income);

  /// Tháng này không có khoản thu chi nào.
  bool get isEmpty => current.income == 0 && current.expense == 0;

  /// Cả 6 tháng đều không có khoản: không vẽ biểu đồ cột rỗng.
  bool get hasNoFlow => months.every((m) => m.income == 0 && m.expense == 0);
}
