import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/period.dart';
import '../../data/stats.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../budget_alert/budget_alert_providers.dart';
import '../budget_alert/budget_status.dart';
import '../import_queue/import_queue_providers.dart';
import '../settings/budget_dialog.dart';
import '../stats/stats_widgets.dart';
import 'debt_totals.dart';
import 'overview_providers.dart';

/// Tổng quan (F-35): tổng số dư, thu − chi tháng, ngân sách còn lại, nợ, biểu
/// đồ cột thu–chi 6 tháng, so với tháng trước. Tháng chọn riêng, không theo kỳ
/// ở màn chính; mọi số tính trên mọi tài khoản, theo Tiền tệ chính, cộng gốc
/// rồi quy đổi một lần (AC-107, D-042).
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(overviewDataProvider);
    final offset = ref.watch(overviewMonthProvider);
    final notifier = ref.read(overviewMonthProvider.notifier);
    final month = data.value?.month;

    return Scaffold(
      appBar: AppBar(title: Text(l.overviewTitle)),
      body: SafeArea(
        child: Column(
          children: [
            MonthHeader(
              title: month == null ? '' : periodTitle(context, month),
              onPrevious: () => notifier.shift(-1),
              onNext: offset >= 0 ? null : () => notifier.shift(1),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  notifier.shift(v > 0 ? -1 : 1);
                },
                child: data.when(
                  data: (d) => _Body(data: d),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final OverviewData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final queueCount = ref.watch(importQueueCountProvider).value ?? 0;
    final locale = Localizations.localeOf(context).languageCode;
    final large = isLargeText(context);
    String amount(int v) => money(context, currency, v);

    final net = data.net;
    final netText = net > 0 ? '+${amount(net)}' : amount(net);
    final netColor = net > 0
        ? incomeColor(context)
        : (net < 0 ? expenseColor(context) : scheme.onSurface);
    final left = data.budgetLeft;
    final limit = data.budget ?? 0;
    final near =
        left != null &&
        budgetStateFor(ref, spent: data.current.expense, limit: limit) ==
            BudgetState.almostOver;
    final usedPercent = budgetUsedPercent(
      spent: data.current.expense,
      limit: limit,
    );

    final netTile = _Tile(
      title: l.overviewNet,
      spoken: '${l.overviewNet}, $netText',
      child: _AmountText(netText, color: netColor),
    );
    final budgetTile = left == null
        ? _Tile(
            title: l.overviewBudgetLeft,
            child: FilledButton.tonal(
              onPressed: () => showBudgetDialog(context, ref),
              child: Text(l.overviewSetBudget),
            ),
          )
        : _Tile(
            title: l.overviewBudgetLeft,
            spoken: left < 0
                ? '${l.overviewBudgetLeft}, ${l.budgetOver(amount(-left))}'
                : near
                ? '${l.overviewBudgetLeft}, ${amount(left)}, ${l.almostOver}, ${l.budgetAlertUsed(usedPercent)}'
                : '${l.overviewBudgetLeft}, ${amount(left)}',
            child: left < 0
                // Vượt: số tiền vượt ở dòng riêng, nhãn "Đã vượt" bên dưới — không để
                // số bị ngắt giữa nhóm nghìn trong ô hẹp (2026-11-13). Icon +
                // chữ để không chỉ dựa vào màu (AC-27, AC-40).
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AmountText(amount(-left), color: scheme.error),
                      Row(
                        children: [
                          Icon(
                            Symbols.warning_rounded,
                            fill: 1,
                            size: 16,
                            color: scheme.error,
                          ),
                          const SizedBox(width: VgSpace.s1),
                          Flexible(
                            child: Text(
                              l.overviewBudgetOver,
                              style: VgType.bodySm.copyWith(
                                color: scheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : near
                // Sắp vượt (F-37, AC-111): icon + "Đã dùng 82%", màu cảnh báo
                // (hổ phách), khác đỏ của Vượt.
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AmountText(amount(left), color: scheme.onSurface),
                      Row(
                        children: [
                          Icon(
                            Symbols.info_rounded,
                            fill: 1,
                            size: 16,
                            color: context.vg.warning,
                          ),
                          const SizedBox(width: VgSpace.s1),
                          Flexible(
                            child: Text(
                              l.budgetAlertUsed(usedPercent),
                              style: VgType.bodySm.copyWith(
                                color: context.vg.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : _AmountText(amount(left), color: scheme.onSurface),
          );

    // "tháng 10" / "October" khi tháng bắt đầu ngày 1; không thì khoảng ngày.
    // Giữa câu: vi viết thường ("so với tháng 10", AC-108; intl cho "Tháng
    // 10"), en giữ nguyên ("October").
    String monthName(Period p) => p.start.day == 1
        ? (locale == 'vi'
              ? DateFormat.MMMM(locale).format(p.start).toLowerCase()
              : DateFormat.MMMM(locale).format(p.start))
        : periodTitle(context, p);
    String shortMonth(Period p) => p.start.day == 1
        ? shortMonthLabel(context, p.start)
        : DateFormat.MMMd(locale).format(p.start);

    final prev = data.previous;
    final expenseChange = data.expenseChange;
    final summary = prev == null || expenseChange == null
        ? null
        : switch (expenseChange.direction) {
            ChangeDirection.up => l.overviewSummaryUp(
              expenseChange.percent,
              monthName(prev.period),
            ),
            ChangeDirection.down => l.overviewSummaryDown(
              expenseChange.percent,
              monthName(prev.period),
            ),
            ChangeDirection.same => l.overviewSummarySame(
              monthName(prev.period),
            ),
          };

    return ListView(
      padding: const EdgeInsets.only(bottom: VgSpace.s6),
      children: [
        _HeroBalance(
          title: l.overviewTotalBalance,
          caption: l.overviewAllAccounts,
          amount: amount(data.totalBalance),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s4,
            VgSpace.s3,
            VgSpace.s4,
            0,
          ),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    netTile,
                    const SizedBox(height: VgSpace.s3),
                    budgetTile,
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: netTile),
                      const SizedBox(width: VgSpace.s3),
                      Expanded(child: budgetTile),
                    ],
                  ),
                ),
        ),
        const _DebtCard(),
        if (queueCount > 0)
          _QueueNote(
            text: l.overviewQueueNote(queueCount),
            onTap: () => context.push('/import-queue'),
          ),
        if (data.isEmpty)
          StatsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.overviewMonthEmpty,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                ),
              ],
            ),
          ),
        if (!data.hasNoFlow) ...[
          StatsCard(
            title: l.overviewChartTitle,
            child: FlowBarChart(
              title: l.overviewChartTitle,
              currency: currency,
              initialSelected: data.months.length - 1,
              items: [
                for (final m in data.months)
                  FlowBarItem(
                    label: shortMonth(m.period),
                    spoken: periodTitle(context, m.period),
                    income: m.income,
                    expense: m.expense,
                  ),
              ],
            ),
          ),
          StatsCard(
            title: l.overviewVsLastMonth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChangeRow(
                  label: l.expense,
                  change: data.expenseChange,
                  goodWhenUp: false,
                ),
                _ChangeRow(
                  label: l.income,
                  change: data.incomeChange,
                  goodWhenUp: true,
                ),
                if (summary != null)
                  Padding(
                    padding: const EdgeInsets.only(top: VgSpace.s2),
                    child: Text(
                      summary,
                      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Thẻ Tổng số dư: số lớn trên nền `primary-container`.
class _HeroBalance extends StatelessWidget {
  const _HeroBalance({
    required this.title,
    required this.caption,
    required this.amount,
  });

  final String title;
  final String caption;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
      child: Semantics(
        container: true,
        label: '$title, $amount, $caption',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(VgRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(VgSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VgType.titleSm.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: VgSpace.s1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      amount,
                      style: VgType.amountXl.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: VgSpace.s1),
                  Text(
                    caption,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Số tiền trong ô số liệu: một dòng, tự thu nhỏ khi số quá dài — không để
/// số xuống dòng giữa nhóm nghìn trong ô hẹp (2026-11-13).
class _AmountText extends StatelessWidget {
  const _AmountText(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: VgType.amountMd.copyWith(color: color),
    ),
  );
}

/// Ô số liệu: tiêu đề, giá trị; ô chỉ có số thì đọc một câu [spoken].
class _Tile extends StatelessWidget {
  const _Tile({required this.title, this.spoken, required this.child});

  final String title;

  /// Null: ô có nút, để nút tự đọc.
  final String? spoken;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: VgSpace.s2),
        child,
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VgRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VgSpace.s4),
        child: spoken == null
            ? body
            : Semantics(
                container: true,
                label: spoken,
                child: ExcludeSemantics(child: body),
              ),
      ),
    );
  }
}

/// Thẻ "Nợ": người khác nợ bạn · bạn nợ (số còn lại các khoản nợ chưa xong,
/// theo Tiền tệ chính); chạm mở màn Khoản nợ. Không thuộc Tổng số dư.
class _DebtCard extends ConsumerWidget {
  const _DebtCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final totals = ref.watch(debtTotalsProvider).value;
    if (totals == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    String amount(int v) => money(context, currency, v);
    final lines = totals.openCount == 0
        ? [l.overviewDebtNone]
        : [
            l.overviewDebtOwedToYou(amount(totals.owedToYou)),
            l.overviewDebtYouOwe(amount(totals.youOwe)),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, VgSpace.s3, VgSpace.s4, 0),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VgRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(VgRadius.lg),
          onTap: () => context.push('/debts'),
          child: Semantics(
            button: true,
            label: '${l.overviewDebtTitle}. ${lines.join('. ')}',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapMin),
              child: Padding(
                padding: const EdgeInsets.all(VgSpace.s4),
                // Tiêu đề một hàng riêng để icon và mũi tên không chen giữa
                // dòng "Người khác nợ bạn …" khi chữ xuống dòng (2026-11-13).
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.handshake_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: VgSpace.s3),
                        Expanded(
                          child: Text(
                            l.overviewDebtTitle,
                            style: VgType.titleSm.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Symbols.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: VgSpace.s2),
                    for (final line in lines)
                      Text(
                        line,
                        style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                      ),
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

/// Dòng "đang chờ, chưa được tính" (hàng đợi email chưa là khoản, AC-95).
class _QueueNote extends StatelessWidget {
  const _QueueNote({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, VgSpace.s3, VgSpace.s4, 0),
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(VgRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(VgRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VgSize.tapMin),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VgSpace.s4,
                vertical: VgSpace.s2,
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.inbox_rounded,
                    size: 20,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: VgSpace.s3),
                  Expanded(
                    child: Text(
                      text,
                      style: VgType.bodySm.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Một dòng "So với tháng trước": tên, mũi tên và chữ tăng/giảm/không đổi kèm
/// %, hoặc "—" khi tháng trước bằng 0 (AC-107). Mũi tên luôn đi kèm chữ.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.change,
    required this.goodWhenUp,
  });

  final String label;
  final PercentChange? change;

  /// Thu tăng là tốt; chi tăng là xấu — chỉ để chọn màu.
  final bool goodWhenUp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = change;
    final String words;
    final String spoken;
    final IconData? icon;
    var color = scheme.onSurfaceVariant;
    if (c == null) {
      words = l.overviewChangeNone;
      spoken = l.overviewChangeNoneSpoken;
      icon = null;
    } else {
      switch (c.direction) {
        case ChangeDirection.up:
          words = l.overviewChangeUp(c.percent);
          icon = Symbols.trending_up_rounded;
          color = goodWhenUp ? incomeColor(context) : expenseColor(context);
        case ChangeDirection.down:
          words = l.overviewChangeDown(c.percent);
          icon = Symbols.trending_down_rounded;
          color = goodWhenUp ? expenseColor(context) : incomeColor(context);
        case ChangeDirection.same:
          words = l.overviewChangeSame;
          icon = Symbols.trending_flat_rounded;
      }
      spoken = words;
    }
    final value = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: VgSpace.s1),
        ],
        Flexible(
          child: Text(words, style: VgType.labelLg.copyWith(color: color)),
        ),
      ],
    );
    final name = Text(
      label,
      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
    );
    return Semantics(
      container: true,
      label: '$label, $spoken',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VgSize.tapMin),
          child: isLargeText(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [name, value],
                )
              : Row(
                  children: [
                    Expanded(child: name),
                    value,
                  ],
                ),
        ),
      ),
    );
  }
}
