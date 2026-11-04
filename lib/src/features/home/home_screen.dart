import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../settings/budget_dialog.dart';
import 'period_picker.dart';

/// Màn chính: biểu đồ chi theo danh mục, tổng thu chi, số dư (F-02).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final accountFilter = ref.watch(accountFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          if (accounts.length > 1)
            PopupMenuButton<int>(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: accountFilter == null
                  ? l.account
                  : '${l.account}: ${accountLabel(l, accounts.firstWhere((a) => a.id == accountFilter, orElse: () => accounts.first))}',
              initialValue: accountFilter ?? -1,
              onSelected: (id) => ref
                  .read(accountFilterProvider.notifier)
                  .select(id == -1 ? null : id),
              itemBuilder: (context) => [
                PopupMenuItem(value: -1, child: Text(l.allAccounts)),
                for (final a in accounts)
                  PopupMenuItem(value: a.id, child: Text(accountLabel(l, a))),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l.entries,
            onPressed: () => context.push('/entries'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _PeriodHeader(),
            const BudgetBar(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  ref.read(periodProvider.notifier).shift(v < 0 ? 1 : -1);
                },
                child: const _ChartWithCategories(),
              ),
            ),
            const _BalanceBar(),
            const _AddButtons(),
          ],
        ),
      ),
    );
  }
}

/// Tên kỳ đang xem, nút kỳ trước, kỳ sau; chạm tên để chọn loại kỳ (AC-10, AC-11).
class _PeriodHeader extends ConsumerWidget {
  const _PeriodHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(periodProvider);
    final notifier = ref.read(periodProvider.notifier);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: l.previousPeriod,
          onPressed: () => notifier.shift(-1),
        ),
        Expanded(
          child: Semantics(
            button: true,
            hint: l.choosePeriod,
            child: InkWell(
              onTap: () => showPeriodPicker(context, ref),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  child: Text(
                    periodTitle(context, period),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: l.nextPeriod,
          onPressed: () => notifier.shift(1),
        ),
      ],
    );
  }
}

/// Biểu đồ tròn ở giữa, icon danh mục chi xếp quanh (AC-06, AC-09).
class _ChartWithCategories extends ConsumerWidget {
  const _ChartWithCategories();

  static const _iconSize = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final categories =
        ref.watch(categoriesProvider(CategoryType.expense)).value ??
        const <Category>[];
    final totals = {
      for (final t in summary.expenseByCategory) t.category.id: t,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final ring = side / 2 - _iconSize / 2 - 4;
        final chartRadius = max(ring - _iconSize / 2 - 8, 40.0);
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        final fit = max(1, (2 * pi * ring / (_iconSize + 8)).floor());
        final shown = categories.take(fit).toList();

        String label(Category c) {
          final name = categoryLabel(l, c);
          final t = totals[c.id];
          return t == null
              ? l.categoryNoEntries(name)
              : l.categoryAmount(
                  name,
                  money(context, currency, t.total),
                  percent(context, t.percent),
                );
        }

        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.fromCircle(center: center, radius: chartRadius),
              child: summary.isEmpty
                  ? Center(
                      child: Text(
                        l.emptyPeriod,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : Semantics(
                      label: l.chartSummary(
                        summary.expenseByCategory
                            .map((t) => label(t.category))
                            .join('; '),
                      ),
                      excludeSemantics: true,
                      child: _Donut(
                        summary: summary,
                        radius: chartRadius,
                        currency: currency,
                      ),
                    ),
            ),
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left:
                    center.dx +
                    ring * cos(-pi / 2 + 2 * pi * i / shown.length) -
                    _iconSize / 2,
                top:
                    center.dy +
                    ring * sin(-pi / 2 + 2 * pi * i / shown.length) -
                    _iconSize / 2,
                child: Tooltip(
                  message: categoryLabel(l, shown[i]),
                  child: CategoryAvatar(
                    category: shown[i],
                    semanticLabel: '${l.addExpense}: ${label(shown[i])}',
                    onTap: () => context.push(
                      '/entry/new?type=expense&category=${shown[i].id}',
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({
    required this.summary,
    required this.radius,
    required this.currency,
  });

  final PeriodSummary summary;
  final double radius;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final thickness = radius * 0.3;
    final sections = summary.expense > 0
        ? [
            for (final t in summary.expenseByCategory)
              PieChartSectionData(
                value: t.total.toDouble(),
                color: Color(t.category.color),
                radius: thickness,
                showTitle: false,
              ),
          ]
        : [
            PieChartSectionData(
              value: 1,
              color: incomeColor(context),
              radius: thickness,
              showTitle: false,
            ),
          ];
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: radius - thickness,
            sectionsSpace: sections.length > 1 ? 1 : 0,
            startDegreeOffset: -90,
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(thickness + 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    money(context, currency, summary.income),
                    style: textTheme.titleMedium?.copyWith(
                      color: incomeColor(context),
                    ),
                  ),
                  Text(
                    money(context, currency, summary.expense),
                    style: textTheme.titleMedium?.copyWith(
                      color: expenseColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Số dư của kỳ; chạm để xem danh sách khoản (AC-07, AC-08).
class _BalanceBar extends ConsumerWidget {
  const _BalanceBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => context.push('/entries'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l.balanceLabel(money(context, currency, summary.balance)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút "−" ghi khoản chi và "+" ghi khoản thu, nằm vùng ngón cái (AC-01, AC-37).
class _AddButtons extends StatelessWidget {
  const _AddButtons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget button(String tooltip, IconData icon, Color color, String type) =>
        Expanded(
          child: Tooltip(
            message: tooltip,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => context.push('/entry/new?type=$type'),
              child: Icon(icon, size: 36, semanticLabel: tooltip),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          button(
            l.addExpense,
            Icons.remove,
            const Color(0xFFC62828),
            'expense',
          ),
          const SizedBox(width: 16),
          button(l.addIncome, Icons.add, const Color(0xFF2E7D32), 'income'),
        ],
      ),
    );
  }
}

/// Thanh ngân sách tháng: đã chi / hạn mức; vượt thì đổi màu và ghi rõ chữ
/// "Vượt", không chỉ dựa vào màu (AC-27). Chạm để đặt lại hạn mức.
class BudgetBar extends ConsumerWidget {
  const BudgetBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(budgetProvider).value;
    if (limit == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final spent = ref.watch(budgetSpentProvider).value ?? 0;
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final over = spent > limit;
    final scheme = Theme.of(context).colorScheme;
    final text = over
        ? '${l.budget}: ${l.budgetOver(money(context, currency, spent - limit))}'
        : '${l.budget}: ${l.budgetProgress(money(context, currency, spent), money(context, currency, limit))}';
    return InkWell(
      onTap: () => showBudgetDialog(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Semantics(
          label: text,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: over ? scheme.error : null,
                  fontWeight: over ? FontWeight.bold : null,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (spent / limit).clamp(0, 1).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: over ? scheme.error : scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
