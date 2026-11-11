import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/money_sum.dart';
import '../../data/period.dart';
import '../../data/stats.dart';
import '../../providers.dart';
import '../stats/stats_providers.dart';

/// Số tháng của biểu đồ cột Tổng quan (AC-107).
const overviewMonthCount = 6;

/// Tháng Tổng quan đang chọn: số tháng lệch so với tháng hiện tại (0 là tháng
/// này, −1 là tháng trước). Riêng với kỳ ở màn chính (AC-107).
class OverviewMonthNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Không đi quá tháng hiện tại.
  void shift(int delta) {
    final next = state + delta;
    if (next <= 0) state = next;
  }
}

final overviewMonthProvider = NotifierProvider<OverviewMonthNotifier, int>(
  OverviewMonthNotifier.new,
);

/// Tháng đang chọn (theo Ngày bắt đầu tháng, AC-12), 6 tháng kết thúc ở đó và
/// thu chi gốc từng ngày của 6 tháng, mọi tài khoản.
final overviewFlowProvider =
    StreamProvider<
      ({Period month, List<Period> months, List<DailyFlow> flows})
    >((ref) async* {
      final offset = ref.watch(overviewMonthProvider);
      final today = ref.watch(todayProvider);
      final monthStartDay = await ref.watch(monthStartDayProvider.future);
      final month = Period.containing(
        PeriodType.month,
        today,
        monthStartDay: monthStartDay,
      ).shift(offset);
      final months = monthsEndingAt(month, count: overviewMonthCount);
      yield* ref
          .watch(statsRepositoryProvider)
          .watchDailyFlow(months.first.fromKey, month.toKey)
          .map((flows) => (month: month, months: months, flows: flows));
    });

/// Dữ liệu màn Tổng quan; đang tải khi một nguồn chưa có giá trị đầu.
final overviewDataProvider = Provider<AsyncValue<OverviewData>>((ref) {
  final flow = ref.watch(overviewFlowProvider);
  final bags = ref.watch(accountBalanceBagsProvider);
  final budget = ref.watch(budgetProvider);
  final convert = ref.watch(moneyConvertProvider);
  final error = flow.error ?? bags.error ?? budget.error;
  if (error != null) return AsyncError(error, StackTrace.current);
  if (!flow.hasValue || !bags.hasValue || !budget.hasValue || convert == null) {
    return const AsyncLoading();
  }
  // Tổng số dư = số dư mọi tài khoản (kể cả ẩn) cộng gốc rồi quy một lần.
  final total = MoneyBag();
  for (final b in bags.requireValue.values) {
    total.addBag(b);
  }
  final f = flow.requireValue;
  return AsyncData(
    OverviewData.of(
      month: f.month,
      months: f.months,
      flows: f.flows,
      totalBalance: total,
      budget: budget.requireValue,
      convert: convert,
    ),
  );
});
