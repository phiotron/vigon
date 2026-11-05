import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../data/summary.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/limit_bar.dart';

/// Tổng chi của THÁNG HIỆN TẠI theo từng danh mục chi (khóa là id danh mục),
/// mọi tài khoản, không phụ thuộc kỳ đang xem (AC-54). Cùng cách tính tháng
/// với [budgetSpentProvider].
final categorySpentProvider = StreamProvider<Map<int, int>>((ref) {
  final month = Period.containing(
    PeriodType.month,
    ref.watch(todayProvider),
    monthStartDay: ref.watch(monthStartDayProvider).value ?? 1,
  );
  return ref.watch(entryRepositoryProvider).watchEntries(month).map((rows) {
    final summary = PeriodSummary.of(rows);
    return {for (final t in summary.expenseByCategory) t.category.id: t.total};
  });
});

/// Thanh tiến độ nhỏ của hạn mức tháng một danh mục chi: "Đã chi X / Y"; vượt
/// thì màu lỗi, đậm và thêm chữ "Vượt Z", không chỉ dựa vào màu (AC-54).
/// Không hiện gì khi danh mục chưa đặt hạn mức.
class CategoryBudgetBar extends ConsumerWidget {
  const CategoryBudgetBar({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = category.budget;
    if (limit == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final spent = ref.watch(categorySpentProvider).value?[category.id] ?? 0;
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final over = spent > limit;
    final progress = l.budgetProgress(
      money(context, currency, spent),
      money(context, currency, limit),
    );
    final text = over
        ? '$progress · ${l.budgetOver(money(context, currency, spent - limit))}'
        : progress;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: LimitBar(text: text, progress: spent / limit, over: over),
    );
  }
}
