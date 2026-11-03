import 'dates.dart';

/// Loại kỳ xem trên màn chính (AC-10).
enum PeriodType { day, week, month, year, all, custom }

/// Một kỳ xem: từ [start] tới [end], tính cả hai đầu, chỉ phần ngày.
class Period {
  const Period(this.type, this.start, this.end);

  final PeriodType type;
  final DateTime start;
  final DateTime end;

  String get fromKey => type == PeriodType.all ? '0000-01-01' : dateKey(start);
  String get toKey => type == PeriodType.all ? '9999-12-31' : dateKey(end);

  /// Kỳ loại [type] chứa ngày [date].
  /// [weekStart]: DateTime.monday hoặc DateTime.sunday; [monthStartDay]: 1..28 (AC-12).
  static Period containing(
    PeriodType type,
    DateTime date, {
    int weekStart = DateTime.monday,
    int monthStartDay = 1,
  }) {
    final d = dateOnly(date);
    switch (type) {
      case PeriodType.day:
        return Period(type, d, d);
      case PeriodType.week:
        final start = addDays(d, -((d.weekday - weekStart) % 7));
        return Period(type, start, addDays(start, 6));
      case PeriodType.month:
        final start = d.day >= monthStartDay
            ? DateTime(d.year, d.month, monthStartDay)
            : DateTime(d.year, d.month - 1, monthStartDay);
        return Period(type, start, addDays(addMonths(start, 1), -1));
      case PeriodType.year:
        return Period(type, DateTime(d.year), DateTime(d.year, 12, 31));
      case PeriodType.all:
        return Period(type, d, d);
      case PeriodType.custom:
        return Period(type, d, d);
    }
  }

  /// Kỳ khoảng tùy chọn; đổi chỗ nếu người dùng chọn ngược.
  static Period custom(DateTime a, DateTime b) {
    final x = dateOnly(a), y = dateOnly(b);
    return x.isAfter(y)
        ? Period(PeriodType.custom, y, x)
        : Period(PeriodType.custom, x, y);
  }

  /// Kỳ trước ([delta] = -1) hoặc sau ([delta] = 1) cùng loại (AC-11).
  Period shift(int delta) {
    switch (type) {
      case PeriodType.day:
        final d = addDays(start, delta);
        return Period(type, d, d);
      case PeriodType.week:
        final s = addDays(start, 7 * delta);
        return Period(type, s, addDays(s, 6));
      case PeriodType.month:
        final s = addMonths(start, delta);
        return Period(type, s, addDays(addMonths(s, 1), -1));
      case PeriodType.year:
        return Period(
          type,
          DateTime(start.year + delta),
          DateTime(start.year + delta, 12, 31),
        );
      case PeriodType.all:
        return this;
      case PeriodType.custom:
        final days = end.difference(start).inDays + 1;
        return Period(
          type,
          addDays(start, days * delta),
          addDays(end, days * delta),
        );
    }
  }

  bool contains(String dateKeyValue) =>
      dateKeyValue.compareTo(fromKey) >= 0 &&
      dateKeyValue.compareTo(toKey) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Period &&
      other.type == type &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(type, start, end);

  @override
  String toString() => 'Period($type, $fromKey..$toKey)';
}
