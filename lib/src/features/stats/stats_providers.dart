import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/period.dart';
import '../../data/stats.dart';
import '../../data/stats_repository.dart';
import '../../data/summary.dart';
import '../../providers.dart';

/// Truy vấn gom nhóm cho Tổng quan, Thống kê, Lịch.
final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(ref.watch(databaseProvider)),
);

/// Quy túi tiền gốc ra Tiền tệ chính, một lần (D-042); null khi bảng tỷ giá
/// chưa nạp xong.
final moneyConvertProvider = Provider<MoneyConvert?>((ref) {
  final service = ref.watch(currencyServiceProvider).value;
  return service == null ? null : convertWith(service);
});

/// Sổ tổng số dư mọi tài khoản, kể cả đã ẩn (AC-109).
final balanceLedgerProvider = StreamProvider<BalanceLedger>(
  (ref) => ref.watch(statsRepositoryProvider).watchBalanceLedger(),
);

/// Thu chi từng ngày của kỳ đang xem ở Thống kê, theo bộ lọc tài khoản
/// (AC-109). Dùng chung kỳ và bộ lọc với màn chính (F-03, AC-20).
final statsFlowProvider = StreamProvider<List<DailyFlow>>(
  (ref) => ref
      .watch(statsRepositoryProvider)
      .watchPeriodFlow(
        ref.watch(periodProvider),
        accountId: ref.watch(accountFilterProvider),
      ),
);

/// Số liệu một màn Thống kê, mọi số theo Tiền tệ chính.
class StatsData {
  const StatsData({
    required this.period,
    required this.buckets,
    required this.topCategories,
    required this.expenseTotal,
    required this.biggestDay,
    required this.balance,
  });

  final Period period;

  /// Cột thu/chi; rỗng là kỳ không có khoản (AC-110).
  final List<FlowBucket> buckets;
  final List<CategoryTotal> topCategories;
  final int expenseTotal;

  /// Null khi không có khoản chi hoặc đang xem kỳ Ngày (ẩn thẻ).
  final BiggestDay? biggestDay;

  /// Đường lịch sử tổng số dư (mọi tài khoản, không theo bộ lọc).
  final List<BalancePoint> balance;

  bool get isEmpty => buckets.isEmpty;
}

final statsDataProvider = Provider<AsyncValue<StatsData>>((ref) {
  final period = ref.watch(periodProvider);
  final flows = ref.watch(statsFlowProvider);
  final ledger = ref.watch(balanceLedgerProvider);
  final convert = ref.watch(moneyConvertProvider);
  final error = flows.error ?? ledger.error;
  if (error != null) return AsyncError(error, StackTrace.current);
  if (!flows.hasValue || !ledger.hasValue || convert == null) {
    return const AsyncLoading();
  }
  final summary = ref.watch(periodSummaryProvider);
  final buckets = flowBuckets(period, flows.requireValue, convert);
  return AsyncData(
    StatsData(
      period: period,
      buckets: buckets,
      topCategories: topExpenseCategories(summary),
      expenseTotal: summary.expense,
      biggestDay: period.type == PeriodType.day
          ? null
          : biggestSpendingDay(flows.requireValue, convert),
      balance: balanceHistory(
        buckets,
        ledger.requireValue,
        convert,
        today: ref.watch(todayProvider),
      ),
    ),
  );
});
