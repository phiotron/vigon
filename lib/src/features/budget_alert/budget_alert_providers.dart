import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../reminder/reminder_providers.dart';
import 'budget_alert_settings.dart';
import 'budget_alert_text.dart';
import 'budget_alerts.dart';
import 'budget_notifier.dart';
import 'budget_status.dart';

final budgetAlertSettingsProvider = Provider<BudgetAlertSettings>(
  (ref) => BudgetAlertSettings(ref.watch(databaseProvider)),
);

/// Bản thật của lớp gửi thông báo ngân sách; test ghi đè bằng bản giả.
final budgetNotifierProvider = Provider<BudgetNotifier>(
  (ref) => LocalBudgetNotifier(),
);

/// Ngưỡng "Sắp vượt" (AC-111), phần trăm.
final budgetWarnPercentProvider = StreamProvider<int>(
  (ref) => ref.watch(budgetAlertSettingsProvider).watchThreshold(),
);

/// Công tắc "Thông báo ngân sách" (AC-112).
final budgetAlertEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(budgetAlertSettingsProvider).watchEnabled(),
);

/// Trạng thái hiện của một ngân sách theo ngưỡng đang chọn (thanh màn chính,
/// hạn mức danh mục). Chưa đọc xong ngưỡng thì dùng mặc định 80%.
BudgetState budgetStateFor(
  WidgetRef ref, {
  required int spent,
  required int limit,
}) => budgetStateOf(
  spent: spent,
  limit: limit,
  warnPercent:
      ref.watch(budgetWarnPercentProvider).value ?? defaultBudgetWarnPercent,
);

final budgetAlertMonitorProvider = Provider<BudgetAlertMonitor>(
  (ref) => BudgetAlertMonitor(
    ref.watch(budgetAlertSettingsProvider),
    ref.watch(budgetNotifierProvider),
  ),
);

/// Số đã chi của THÁNG HIỆN TẠI: tổng và theo danh mục, cùng một lần đọc và
/// kèm kỳ của chúng, nên không bao giờ ghép số của tháng này với khoá của
/// tháng khác. Chỉ tháng hiện tại: khoản ghi lùi vào tháng cũ không làm luồng
/// này đổi nên không gây thông báo (AC-112). Mọi đường ghi khoản (ghi tay, sinh
/// định kỳ, xác nhận từ hàng đợi) đều đi qua bảng `entries` nên đều được thấy.
/// Cộng chính xác theo tiền tệ gốc rồi quy đổi một lần (D-042), cùng cách với
/// `budgetSpentProvider` và `categorySpentProvider`.
class BudgetAlertSnapshot {
  const BudgetAlertSnapshot({
    required this.month,
    required this.total,
    required this.byCategory,
  });

  final Period month;
  final int total;
  final Map<int, int> byCategory;

  String get monthKey => month.fromKey;
}

final budgetAlertSnapshotProvider = StreamProvider<BudgetAlertSnapshot>((
  ref,
) async* {
  final today = ref.watch(todayProvider);
  final service = await ref.watch(currencyServiceProvider.future);
  final monthStartDay = await ref.watch(monthStartDayProvider.future);
  final month = Period.containing(
    PeriodType.month,
    today,
    monthStartDay: monthStartDay,
  );
  yield* ref.watch(entryRepositoryProvider).watchEntries(month).map((rows) {
    final summary = PeriodSummary.of(rows, service: service);
    return BudgetAlertSnapshot(
      month: month,
      total: summary.expense,
      byCategory: {
        for (final t in summary.expenseByCategory) t.category.id: t.total,
      },
    );
  });
});

bool _loaded(AsyncValue<Object?> v) => v.hasValue && !v.isLoading;

/// Giữ thông báo ngân sách khớp số liệu: mỗi khi đã chi, hạn mức hay ngưỡng
/// đổi thì tính lại và gửi mốc mới chạm (AC-112). Tắt công tắc thì xoá trạng
/// thái. Chờ plugin thông báo khởi tạo xong để không mất thông báo lúc mở app.
/// `VigonApp` theo dõi provider này.
final budgetAlertSyncProvider = Provider<void>((ref) {
  final ready = ref.watch(reminderReadyProvider);
  final enabled = ref.watch(budgetAlertEnabledProvider);
  if (!ready.hasValue || !enabled.hasValue) return;
  final monitor = ref.read(budgetAlertMonitorProvider);
  if (enabled.value != true) {
    unawaited(monitor.disable());
    return;
  }
  final snapshot = ref.watch(budgetAlertSnapshotProvider);
  final warn = ref.watch(budgetWarnPercentProvider);
  final monthly = ref.watch(budgetProvider);
  final categories = ref.watch(categoriesProvider(CategoryType.expense));
  final localeCode = ref.watch(localeCodeProvider);
  if (![snapshot, warn, monthly, categories, localeCode].every(_loaded)) {
    return;
  }
  final data = snapshot.requireValue;
  final limit = monthly.value;
  final budgets = <BudgetAlertInput>[
    if (limit != null && limit > 0)
      BudgetAlertInput(id: monthlyBudgetId, limit: limit, spent: data.total),
    for (final c in categories.requireValue)
      if (c.budget != null && c.budget! > 0)
        BudgetAlertInput(
          id: categoryBudgetId(c.id),
          limit: c.budget!,
          spent: data.byCategory[c.id] ?? 0,
          categoryId: c.id,
        ),
  ];
  final l = lookupAppLocalizations(Locale(localeCode.value ?? 'en'));
  final names = {
    for (final c in categories.requireValue) c.id: categoryLabel(l, c),
  };
  unawaited(
    monitor.evaluate(
      month: data.monthKey,
      warnPercent: warn.requireValue,
      budgets: budgets,
      contentFor: (alert) => budgetAlertContent(
        l,
        alert,
        monthStart: data.month.start,
        monthEnd: data.month.end,
        categoryName: names[alert.categoryId],
      ),
    ),
  );
});

/// Chạm thông báo ngân sách → mở Tổng quan (AC-113). `VigonApp` gọi trong
/// `build`, cùng chỗ theo dõi [budgetAlertSyncProvider]. Màn khoá phủ lên trên
/// nên nếu bật PIN, người dùng mở khoá xong mới thấy màn này. Router chưa có
/// `/overview` thì mở màn chính.
void listenBudgetAlertTaps(WidgetRef ref, GoRouter router) {
  ref.listen(reminderTapProvider, (_, next) {
    if (next?.payload != budgetAlertPayload) return;
    router.go(budgetAlertRoute(router));
  });
}

/// Route mở khi chạm thông báo ngân sách: Tổng quan nếu router có, không thì
/// màn chính.
String budgetAlertRoute(GoRouter router) {
  try {
    final match = router.configuration.findMatch(Uri.parse(budgetAlertPayload));
    if (!match.isError && match.isNotEmpty) return budgetAlertPayload;
  } catch (_) {}
  return '/';
}
