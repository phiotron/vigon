import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/main_action_button.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
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
              icon: const Icon(Symbols.account_balance_wallet_rounded),
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
            icon: const Icon(Symbols.receipt_long_rounded),
            tooltip: l.entries,
            onPressed: () => context.push('/entries'),
          ),
          IconButton(
            icon: const Icon(Symbols.settings_rounded),
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
          icon: const Icon(Symbols.chevron_left_rounded),
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
          icon: const Icon(Symbols.chevron_right_rounded),
          tooltip: l.nextPeriod,
          onPressed: () => notifier.shift(1),
        ),
      ],
    );
  }
}

/// Biểu đồ tròn ở giữa, icon danh mục chi xếp quanh (AC-06, AC-09). Kích
/// thước theo bản vẽ 2.1 trong khung 328 (lớn nhất): icon 48 trên vòng bán kính 140,
/// vòng chi tiêu từ 77 tới 107; khung nhỏ hơn thì co theo tỉ lệ.
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
        // Icon phải nằm trọn trong khung: bán kính vòng icon tối đa 140, khung
        // nhỏ (cỡ chữ lớn, màn thấp) thì co cả vòng icon lẫn biểu đồ.
        final ring = max(0.0, min(140.0, side / 2 - _iconSize / 2));
        final scale = ring / 140;
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        // Mỗi icon cần 56 trên vòng tròn (48 cộng khoảng hở 8).
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
              rect: Rect.fromCircle(center: center, radius: 107 * scale),
              child: summary.isEmpty
                  ? Center(
                      child: SizedBox(
                        width: 180 * scale,
                        child: Text(
                          l.emptyPeriod,
                          textAlign: TextAlign.center,
                          style: VgType.bodyMd.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : Semantics(
                      label: l.chartSummary(
                        summary.expenseByCategory
                            .map((t) => label(t.category))
                            .join('; '),
                      ),
                      excludeSemantics: true,
                      child: SpendingRing(
                        summary: summary,
                        scale: scale,
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

/// Vòng chi tiêu theo danh mục (2.1): cung màu danh mục từ lớn tới nhỏ, bắt
/// đầu 12 giờ, cách nhau 2; giữa là tổng thu rồi tổng chi. Chỉ có thu thì
/// vòng đầy màu thu.
class SpendingRing extends StatelessWidget {
  const SpendingRing({
    super.key,
    required this.summary,
    required this.currency,
    this.scale = 1,
  });

  final PeriodSummary summary;
  final String currency;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final inner = 77 * scale;
    final thickness = 30 * scale;
    final sorted = [...summary.expenseByCategory]
      ..sort((a, b) => b.total.compareTo(a.total));
    final sections = summary.expense > 0
        ? [
            for (final t in sorted)
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
    return Stack(
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            centerSpaceRadius: inner,
            sectionsSpace: sections.length > 1 ? 2 : 0,
            startDegreeOffset: -90,
          ),
        ),
        Center(
          child: SizedBox.square(
            dimension: inner * 2 - VgSpace.s4,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      money(context, currency, summary.income),
                      style: VgType.amountMd.copyWith(
                        color: incomeColor(context),
                      ),
                    ),
                    Text(
                      money(context, currency, summary.expense),
                      style: VgType.amountMd.copyWith(
                        color: expenseColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thanh Số dư của kỳ (2.1): cao 56, bo `radius-md`; chạm để xem danh sách
/// khoản (AC-07, AC-08).
class _BalanceBar extends ConsumerWidget {
  const _BalanceBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final amount = money(context, currency, summary.balance);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s3),
      child: Semantics(
        button: true,
        label: l.balanceLabel(amount),
        excludeSemantics: true,
        onTap: () => context.push('/entries'),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(VgRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/entries'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapKey),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4,
                  VgSpace.s2,
                  VgSpace.s2,
                  VgSpace.s2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.balance,
                        style: VgType.bodyMd.copyWith(color: muted),
                      ),
                    ),
                    const SizedBox(width: VgSpace.s2),
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(amount, style: VgType.amountMd),
                      ),
                    ),
                    const SizedBox(width: VgSpace.s2),
                    Icon(Symbols.chevron_right_rounded, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hai nút lớn "− Chi" và "+ Thu" ở vùng ngón cái (AC-01, AC-37).
class _AddButtons extends StatelessWidget {
  const _AddButtons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: MainActionButton(
              glyph: '−',
              label: l.expense,
              semanticLabel: l.addExpense,
              background: context.vg.expense,
              foreground: context.vg.onExpense,
              onPressed: () => context.push('/entry/new?type=expense'),
            ),
          ),
          const SizedBox(width: VgSpace.s3),
          Expanded(
            child: MainActionButton(
              glyph: '+',
              label: l.income,
              semanticLabel: l.addIncome,
              background: context.vg.income,
              foreground: context.vg.onIncome,
              onPressed: () => context.push('/entry/new?type=income'),
            ),
          ),
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
    final color = over ? scheme.error : scheme.onSurfaceVariant;
    return InkWell(
      onTap: () => showBudgetDialog(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s4,
          VgSpace.s1,
          VgSpace.s4,
          VgSpace.s3,
        ),
        child: Semantics(
          label: text,
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Vượt ngân sách: thêm icon cảnh báo và chữ đậm, không chỉ
                  // đổi màu (AC-27, AC-40).
                  if (over) ...[
                    Icon(
                      Symbols.warning_rounded,
                      fill: 1,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: VgSpace.s1),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: VgType.bodySm.copyWith(
                        color: color,
                        fontWeight: over ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(VgRadius.full),
                child: LinearProgressIndicator(
                  value: (spent / limit).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHigh,
                  color: over ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
