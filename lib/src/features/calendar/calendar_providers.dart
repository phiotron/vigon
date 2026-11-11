import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dates.dart';
import '../../data/period.dart';
import '../../data/stats.dart';
import '../../data/summary.dart';
import '../../providers.dart';
import '../stats/stats_providers.dart';

/// Tháng Lịch đang xem: số tháng lịch lệch so với tháng hiện tại.
class CalendarMonthNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void shift(int delta) => state += delta;
}

final calendarMonthProvider = NotifierProvider<CalendarMonthNotifier, int>(
  CalendarMonthNotifier.new,
);

/// Ngày đầu tháng lịch đang xem.
final calendarMonthStartProvider = Provider<DateTime>((ref) {
  final today = ref.watch(todayProvider);
  return DateTime(today.year, today.month + ref.watch(calendarMonthProvider));
});

/// Thu chi gốc từng ngày của tháng Lịch, theo bộ lọc tài khoản (AC-114).
final calendarFlowProvider = StreamProvider<List<DailyFlow>>((ref) {
  final first = ref.watch(calendarMonthStartProvider);
  final last = DateTime(first.year, first.month + 1, 0);
  return ref
      .watch(statsRepositoryProvider)
      .watchDailyFlow(
        dateKey(first),
        dateKey(last),
        accountId: ref.watch(accountFilterProvider),
      );
});

/// Ngày đang chọn trên Lịch; null là chưa chọn.
class CalendarDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => ref.read(todayProvider);

  void select(DateTime? day) => state = day;
}

final calendarDayProvider = NotifierProvider<CalendarDayNotifier, DateTime?>(
  CalendarDayNotifier.new,
);

/// Các khoản của ngày đang chọn, theo bộ lọc tài khoản (AC-114).
final calendarDayEntriesProvider = StreamProvider<List<EntryView>>((ref) {
  final day = ref.watch(calendarDayProvider);
  if (day == null) return Stream.value(const <EntryView>[]);
  return ref
      .watch(entryRepositoryProvider)
      .watchEntries(
        Period(PeriodType.day, day, day),
        accountId: ref.watch(accountFilterProvider),
      );
});
