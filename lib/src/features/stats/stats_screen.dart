import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/period.dart';
import '../../data/stats.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/main_tab_bar.dart';
import '../../ui/tokens.g.dart';
import '../home/home_extras.dart';
import 'stats_providers.dart';
import 'stats_widgets.dart';

/// Thống kê (F-36): theo kỳ và bộ lọc tài khoản của màn chính — cột thu/chi
/// theo kỳ con, 5 danh mục chi nhiều nhất, ngày chi nhiều nhất, đường lịch sử
/// tổng số dư. Mọi số theo Tiền tệ chính, cộng gốc rồi quy đổi một lần
/// (AC-109, AC-110, D-042).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(statsDataProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: VgSpace.s4,
        title: Text(l.statsTitle),
        actions: [
          const AccountFilterButton(),
          IconButton(
            icon: const Icon(Symbols.calendar_month_rounded),
            tooltip: l.calendarTitle,
            onPressed: () => context.push('/calendar'),
          ),
        ],
      ),
      bottomNavigationBar: const MainTabBar(current: MainTab.stats),
      body: SafeArea(
        child: Column(
          children: [
            const StatsPeriodHeader(),
            if (ref.watch(accountFilterProvider) != null)
              const ActiveAccountChip(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  ref.read(periodProvider.notifier).shift(v < 0 ? 1 : -1);
                },
                child: data.when(
                  data: (d) => d.isEmpty
                      ? ListView(
                          children: [
                            StatsEmpty(
                              title: l.noEntries,
                              hint: l.statsEmptyHint,
                            ),
                          ],
                        )
                      : _Body(data: d),
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

/// Nhãn ngắn dưới cột và tên đầy đủ để đọc của một cột.
({String label, String spoken}) bucketLabels(
  BuildContext context,
  FlowBucket b,
  Period period,
) {
  final locale = Localizations.localeOf(context).languageCode;
  switch (b.unit) {
    case BucketUnit.day:
      return (
        label: period.type == PeriodType.week
            ? DateFormat.E(locale).format(b.start)
            : DateFormat.d(locale).format(b.start),
        spoken: DateFormat.yMMMMEEEEd(locale).format(b.start),
      );
    case BucketUnit.month:
      final whole =
          b.start.day == 1 &&
          b.end == DateTime(b.start.year, b.start.month + 1, 0);
      return (
        label: shortMonthLabel(context, b.start),
        spoken: whole
            ? DateFormat.yMMMM(locale).format(b.start)
            : '${DateFormat.yMMMd(locale).format(b.start)} – '
                  '${DateFormat.yMMMd(locale).format(b.end)}',
      );
    case BucketUnit.year:
      return (label: '${b.start.year}', spoken: '${b.start.year}');
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final StatsData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final locale = Localizations.localeOf(context).languageCode;
    String amount(int v) => money(context, currency, v);
    final labels = [
      for (final b in data.buckets) bucketLabels(context, b, data.period),
    ];
    final biggest = data.biggestDay;

    return ListView(
      padding: const EdgeInsets.only(bottom: VgSpace.s6),
      children: [
        StatsCard(
          title: l.statsFlowTitle,
          child: FlowBarChart(
            title: l.statsFlowTitle,
            currency: currency,
            items: [
              for (final (i, b) in data.buckets.indexed)
                FlowBarItem(
                  label: labels[i].label,
                  spoken: labels[i].spoken,
                  income: b.income,
                  expense: b.expense,
                ),
            ],
          ),
        ),
        if (data.topCategories.isNotEmpty)
          StatsCard(
            title: l.statsTopCategories,
            child: Column(
              children: [
                for (final t in data.topCategories)
                  _CategoryRow(
                    name: categoryLabel(l, t.category),
                    amount: amount(t.total),
                    percent: percent(context, t.percent),
                    share: t.percent / 100,
                    avatar: CategoryAvatar(category: t.category, size: 32),
                  ),
              ],
            ),
          ),
        if (biggest != null)
          StatsCard(
            title: l.statsBiggestDay,
            child: MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMMEEEEd(locale).format(biggest.date),
                      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: VgSpace.s2),
                  Text(
                    amount(biggest.expense),
                    style: VgType.amountMd.copyWith(
                      color: expenseColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (data.balance.isNotEmpty)
          StatsCard(
            title: l.statsBalanceHistory,
            subtitle: l.statsBalanceNote,
            child: BalanceLineChart(
              title: l.statsBalanceHistory,
              currency: currency,
              items: [
                for (final p in data.balance)
                  () {
                    final i = data.buckets.indexOf(p.bucket);
                    return BalanceItem(
                      label: labels[i].label,
                      spoken: labels[i].spoken,
                      value: p.balance,
                    );
                  }(),
              ],
            ),
          ),
      ],
    );
  }
}

/// Một dòng danh mục: avatar, tên, số tiền, % và thanh tỷ lệ; đọc một câu.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.percent,
    required this.share,
    required this.avatar,
  });

  final String name;
  final String amount;
  final String percent;
  final double share;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final large = isLargeText(context);
    final small = VgType.bodySm.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final nameText = Text(
      name,
      maxLines: large ? null : 1,
      overflow: large ? null : TextOverflow.ellipsis,
      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
    );
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: share.clamp(0, 1),
        minHeight: 4,
        color: expenseColor(context),
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
    return Semantics(
      container: true,
      label: l.statsCategoryRow(name, amount, percent),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VgSpace.s1),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: VgSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // Dòng 1: tên · số tiền; dòng 2: thanh tỷ lệ · %. Chữ lớn: xếp
                  // dọc từng phần.
                  children: large
                      ? [
                          nameText,
                          Text(amount, style: small),
                          Text(percent, style: small),
                          const SizedBox(height: VgSpace.s1),
                          bar,
                        ]
                      : [
                          Row(
                            children: [
                              Expanded(child: nameText),
                              const SizedBox(width: VgSpace.s2),
                              Text(amount, style: small),
                            ],
                          ),
                          const SizedBox(height: VgSpace.s1),
                          Row(
                            children: [
                              Expanded(child: bar),
                              const SizedBox(width: VgSpace.s2),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  percent,
                                  textAlign: TextAlign.end,
                                  style: small,
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
