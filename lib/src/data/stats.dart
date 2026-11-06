import 'dates.dart';
import 'database.dart';
import 'period.dart';
import 'summary.dart';

/// Tổng thu và chi của một ngày (F-35, F-36, F-38). Chuyển tiền không tính là
/// thu hay chi (AC-19) và mục hàng đợi chưa là khoản (AC-95), nên không có ở đây.
class DailyFlow {
  const DailyFlow(this.date, this.income, this.expense);

  /// Ngày `YYYY-MM-DD` (D-005).
  final String date;
  final int income;
  final int expense;

  @override
  bool operator ==(Object other) =>
      other is DailyFlow &&
      other.date == date &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(date, income, expense);

  @override
  String toString() => 'DailyFlow($date, +$income, -$expense)';
}

/// Gom các khoản thành tổng thu chi từng ngày; bỏ chuyển tiền. Dùng cho test
/// và cho nơi đã có sẵn danh sách khoản; truy vấn thật dùng SQL gom nhóm.
List<DailyFlow> dailyFlowOf(Iterable<EntryView> rows) {
  final income = <String, int>{}, expense = <String, int>{};
  for (final r in rows) {
    final e = r.entry;
    switch (e.type) {
      case EntryType.income:
        income[e.date] = (income[e.date] ?? 0) + e.amount;
      case EntryType.expense:
        expense[e.date] = (expense[e.date] ?? 0) + e.amount;
      case EntryType.transfer:
        break;
    }
  }
  final dates = {...income.keys, ...expense.keys}.toList()..sort();
  return [for (final d in dates) DailyFlow(d, income[d] ?? 0, expense[d] ?? 0)];
}

/// Đơn vị của một cột ở biểu đồ Thống kê (AC-109).
enum BucketUnit { day, month, year }

/// Một cột: thu và chi từ [start] tới [end] (tính cả hai đầu). Cột đầu và cuối
/// bị cắt theo kỳ, nên tổng các cột bằng tổng kỳ.
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

/// Cột thu/chi của Thống kê (AC-109). [flows] là tổng từng ngày đã lọc theo
/// tài khoản; ngày ngoài kỳ bị bỏ qua. Kỳ không có khoản thu chi nào cho danh
/// sách rỗng (trạng thái trống, AC-110).
List<FlowBucket> flowBuckets(Period period, Iterable<DailyFlow> flows) {
  final inPeriod = flows.where((f) => period.contains(f.date)).toList();
  if (inPeriod.every((f) => f.income == 0 && f.expense == 0)) return const [];
  final ranges = bucketRanges(period, inPeriod);
  if (ranges.isEmpty) return const [];
  final unit = ranges.first.unit;
  final index = <String, int>{
    for (final (i, r) in ranges.indexed) _bucketKey(dateKey(r.start), unit): i,
  };
  final income = List<int>.filled(ranges.length, 0);
  final expense = List<int>.filled(ranges.length, 0);
  for (final f in inPeriod) {
    final i = index[_bucketKey(f.date, unit)];
    if (i == null) continue;
    income[i] += f.income;
    expense[i] += f.expense;
  }
  return [
    for (final (i, r) in ranges.indexed)
      FlowBucket(
        unit: unit,
        start: r.start,
        end: r.end,
        income: income[i],
        expense: expense[i],
      ),
  ];
}

/// Ngày chi nhiều nhất (AC-109): bằng nhau thì lấy ngày sớm hơn.
class BiggestDay {
  const BiggestDay(this.date, this.expense);

  final DateTime date;
  final int expense;
}

/// Ngày chi nhiều nhất trong [flows]; null khi không có khoản chi nào (số chi 0
/// không tính là "nhiều nhất"). Màn ẩn thẻ này ở kỳ Ngày (AC-109).
BiggestDay? biggestSpendingDay(Iterable<DailyFlow> flows) {
  DailyFlow? best;
  for (final f in flows) {
    if (f.expense <= 0) continue;
    if (best == null ||
        f.expense > best.expense ||
        (f.expense == best.expense && f.date.compareTo(best.date) < 0)) {
      best = f;
    }
  }
  return best == null
      ? null
      : BiggestDay(parseDateKey(best.date), best.expense);
}

/// [n] danh mục chi nhiều nhất của kỳ, kèm số tiền và phần trăm trên tổng chi
/// (AC-109). Bằng tiền thì danh mục có id nhỏ hơn đứng trước, nên thứ tự không
/// đổi giữa các lần tính.
List<CategoryTotal> topExpenseCategories(
  Iterable<EntryView> rows, {
  int n = 5,
}) {
  final all = [...PeriodSummary.of(rows).expenseByCategory]
    ..sort((a, b) {
      final byTotal = b.total.compareTo(a.total);
      return byTotal != 0 ? byTotal : a.category.id.compareTo(b.category.id);
    });
  return all.take(n).toList();
}

/// Tổng số dư của mọi tài khoản (kể cả đã ẩn) theo từng ngày (AC-109, đường
/// lịch sử). Giữ số dư đầu và thay đổi ròng mỗi ngày; chuyển tiền giữa hai
/// tài khoản không làm đổi tổng nên không có trong [netByDate].
class BalanceLedger {
  BalanceLedger({required this.initial, required Map<String, int> netByDate})
    : _dates = netByDate.keys.toList()..sort() {
    var running = initial;
    for (final d in _dates) {
      running += netByDate[d]!;
      _prefix.add(running);
    }
  }

  /// Tổng số dư ban đầu của mọi tài khoản.
  final int initial;
  final List<String> _dates;
  final List<int> _prefix = [];

  /// Tổng số dư cuối ngày [dateKeyValue] (đã tính mọi khoản tới hết ngày đó).
  int at(String dateKeyValue) {
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
  int get total => _prefix.isEmpty ? initial : _prefix.last;
}

/// Một điểm của đường lịch sử số dư: số dư cuối [bucket].
class BalancePoint {
  const BalancePoint(this.bucket, this.balance);

  final FlowBucket bucket;
  final int balance;
}

/// Đường lịch sử tổng số dư: giá trị cuối mỗi cột (AC-109). Cột bắt đầu sau
/// [today] bị bỏ để đường không kéo dài phẳng vào tương lai.
List<BalancePoint> balanceHistory(
  List<FlowBucket> buckets,
  BalanceLedger ledger, {
  required DateTime today,
}) => [
  for (final b in buckets)
    if (!b.start.isAfter(today)) BalancePoint(b, ledger.at(dateKey(b.end))),
];

/// Một tháng của biểu đồ cột Tổng quan (AC-107).
class MonthFlow {
  const MonthFlow(this.period, this.income, this.expense);

  final Period period;
  final int income;
  final int expense;

  int get net => income - expense;
}

/// Các tháng (theo ngày bắt đầu tháng) từ `count - 1` tháng trước [month] tới
/// [month], cũ nhất trước (AC-107: 6 tháng kết thúc ở tháng đang chọn).
List<Period> monthsEndingAt(Period month, {int count = 6}) => [
  for (var i = count - 1; i >= 0; i--) month.shift(-i),
];

/// Thu chi từng tháng trong [months] từ tổng từng ngày [flows].
List<MonthFlow> monthlyFlows(List<Period> months, Iterable<DailyFlow> flows) {
  final income = List<int>.filled(months.length, 0);
  final expense = List<int>.filled(months.length, 0);
  for (final f in flows) {
    for (var i = 0; i < months.length; i++) {
      if (months[i].contains(f.date)) {
        income[i] += f.income;
        expense[i] += f.expense;
        break;
      }
    }
  }
  return [
    for (final (i, m) in months.indexed) MonthFlow(m, income[i], expense[i]),
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

/// Dữ liệu một màn Tổng quan (AC-107).
class OverviewData {
  const OverviewData({
    required this.month,
    required this.months,
    required this.totalBalance,
    required this.budget,
  });

  /// Tháng đang chọn.
  final Period month;

  /// 6 tháng kết thúc ở [month], cũ nhất trước.
  final List<MonthFlow> months;

  /// Tổng số dư mọi tài khoản, kể cả đã ẩn.
  final int totalBalance;

  /// Hạn mức chi tháng; null là chưa đặt.
  final int? budget;

  MonthFlow get current => months.last;
  MonthFlow? get previous =>
      months.length < 2 ? null : months[months.length - 2];

  /// Thu − chi của tháng.
  int get net => current.net;

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
