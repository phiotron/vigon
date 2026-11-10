import 'database.dart';
import 'dates.dart';

/// Every day of the week in a [Repeat.weekdays] mask (Mon = bit 0 … Sun = bit 6).
const allWeekdaysMask = 0x7f;

/// Bit of [weekday] (`DateTime.monday` … `DateTime.sunday`) in a weekday mask.
int weekdayBit(int weekday) => 1 << (weekday - 1);

/// What "Repeat" means for a Recurring series (F-08, F-45): a [frequency] and,
/// for "Pick days", the set of weekdays it falls on.
///
/// [weekdays] is only used with [RecurrenceFrequency.weekly]; null there means
/// "the weekday of the start date" (the plain "Weekly" choice). Picking all 7
/// days is stored as [RecurrenceFrequency.daily] (see [Repeat.days]).
class Repeat {
  const Repeat(this.frequency) : weekdays = null;

  const Repeat._(this.frequency, this.weekdays);

  /// "Pick days" with [mask]; all 7 days → daily (F-45). [mask] must be > 0.
  factory Repeat.days(int mask) {
    final m = mask & allWeekdaysMask;
    assert(m != 0, 'pick at least one day');
    if (m == allWeekdaysMask) return const Repeat(RecurrenceFrequency.daily);
    return Repeat._(RecurrenceFrequency.weekly, m);
  }

  /// The repeat stored on [rule].
  factory Repeat.of(RecurringRule rule) => from(rule.frequency, rule.weekdays);

  /// From stored columns; a mask outside weekly or an empty mask is ignored.
  static Repeat from(RecurrenceFrequency frequency, int? weekdays) {
    final m = (weekdays ?? 0) & allWeekdaysMask;
    if (frequency != RecurrenceFrequency.weekly || m == 0) {
      return Repeat(frequency);
    }
    return Repeat.days(m);
  }

  final RecurrenceFrequency frequency;

  /// Weekday mask for "Pick days"; null otherwise.
  final int? weekdays;

  bool get isPickDays => weekdays != null;

  /// [day] is one of the picked weekdays (always true when not "Pick days").
  bool includes(DateTime day) {
    final m = weekdays;
    return m == null || m & weekdayBit(day.weekday) != 0;
  }

  /// Due dates from [start] on, in order, without end. A month or year that
  /// lacks the start day falls back to its last day but the series keeps the
  /// start day (AC-23). With "Pick days" only the picked weekdays on or after
  /// [start] are due, so [start] itself may not be one (D-040).
  Iterable<DateTime> occurrences(DateTime start) sync* {
    final m = weekdays;
    if (m != null) {
      for (var d = start; ; d = addDays(d, 1)) {
        if (m & weekdayBit(d.weekday) != 0) yield d;
      }
    }
    for (var n = 0; ; n++) {
      yield switch (frequency) {
        RecurrenceFrequency.daily => addDays(start, n),
        RecurrenceFrequency.weekly => addDays(start, 7 * n),
        RecurrenceFrequency.monthly => addMonths(start, n, day: start.day),
        RecurrenceFrequency.yearly => addMonths(start, 12 * n, day: start.day),
      };
    }
  }

  /// First due date on or after [start].
  DateTime firstOn(DateTime start) => occurrences(start).first;

  @override
  bool operator ==(Object other) =>
      other is Repeat &&
      other.frequency == frequency &&
      other.weekdays == weekdays;

  @override
  int get hashCode => Object.hash(frequency, weekdays);

  @override
  String toString() => 'Repeat(${frequency.name}, $weekdays)';
}
