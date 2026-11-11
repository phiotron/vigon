import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../data/summary.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/limit_bar.dart';
import '../../ui/tokens.g.dart';
import '../budget_alert/budget_alert_providers.dart';
import '../budget_alert/budget_status.dart';

/// Tổng chi của THÁNG HIỆN TẠI theo từng danh mục chi (khóa là id danh mục),
/// mọi tài khoản, không phụ thuộc kỳ đang xem (AC-54). Cùng cách tính tháng
/// với [budgetSpentProvider].
final categorySpentProvider = StreamProvider<Map<int, int>>((ref) async* {
  final service = await ref.watch(currencyServiceProvider.future);
  final month = Period.containing(
    PeriodType.month,
    ref.watch(todayProvider),
    monthStartDay: ref.watch(monthStartDayProvider).value ?? 1,
  );
  yield* ref.watch(entryRepositoryProvider).watchEntries(month).map((rows) {
    final summary = PeriodSummary.of(rows, service: service);
    return {for (final t in summary.expenseByCategory) t.category.id: t.total};
  });
});

/// Thanh hạn mức tháng của một danh mục chi (`.vg-catbudget`, SCR-10): một
/// dòng chữ + thanh 4 dp, thụt vào cột chữ (72) ngay dưới dòng danh mục.
/// Chưa vượt: "Đã chi X / Y"; vượt: ⚠ + "Vượt Z" màu lỗi 600 + thanh đầy, không
/// chỉ dựa vào màu (AC-54). Thanh luôn tính THÁNG HIỆN TẠI; khi kỳ đang xem
/// không phải tháng này thì thêm tiền tố "Tháng này:" (A05). Không hiện gì khi
/// danh mục chưa đặt hạn mức.
class CategoryBudgetBar extends ConsumerWidget {
  const CategoryBudgetBar({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = category.budget;
    if (limit == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final spent = ref.watch(categorySpentProvider).value?[category.id] ?? 0;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    // Sắp vượt (F-37, AC-111) theo cùng ngưỡng với ngân sách tháng.
    final state = budgetStateFor(ref, spent: spent, limit: limit);
    final over = state == BudgetState.over;
    final near = state == BudgetState.almostOver;
    final progress = l.budgetProgress(
      money(context, currency, spent),
      money(context, currency, limit),
    );
    final status = over
        ? l.budgetOver(money(context, currency, spent - limit))
        : near
        ? '${l.budgetAlertUsed(budgetUsedPercent(spent: spent, limit: limit))} · $progress'
        : progress;
    final viewed = ref.watch(periodProvider);
    final month = Period.containing(
      PeriodType.month,
      ref.watch(todayProvider),
      monthStartDay: ref.watch(monthStartDayProvider).value ?? 1,
    );
    final isThisMonth =
        viewed.type == PeriodType.month &&
        viewed.fromKey == month.fromKey &&
        viewed.toKey == month.toKey;
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, VgSpace.s4, VgSpace.s3),
      child: LimitBar(
        text: isThisMonth ? status : l.categoryLimitThisMonth(status),
        progress: spent / limit,
        over: over,
        near: near,
      ),
    );
  }
}
