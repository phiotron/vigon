import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import '../home/period_picker.dart';

/// Thẻ nội dung của Tổng quan và Thống kê: nền `surface-container-low`, bo
/// `radius-lg`, lề trong 16.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String? title;
  final String? subtitle;

  /// Nút nhỏ cạnh tiêu đề (vd "Xem dạng bảng").
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heading = title == null
        ? null
        : Semantics(
            header: true,
            child: Text(
              title!,
              style: VgType.titleSm.copyWith(color: scheme.onSurface),
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, VgSpace.s3, VgSpace.s4, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VgRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(VgSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (heading != null)
                trailing == null || isLargeText(context)
                    ? heading
                    : Row(
                        children: [
                          Expanded(child: heading),
                          trailing!,
                        ],
                      ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (trailing != null && isLargeText(context))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing,
                ),
              if (title != null) const SizedBox(height: VgSpace.s3),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Trạng thái trống của một màn số liệu: không vẽ biểu đồ rỗng (AC-110).
class StatsEmpty extends StatelessWidget {
  const StatsEmpty({super.key, required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VgSpace.s8,
        vertical: VgSpace.s8,
      ),
      child: Column(
        children: [
          Icon(
            Symbols.bar_chart_rounded,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: VgSpace.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: VgType.bodyMd.copyWith(color: scheme.onSurface),
          ),
          if (hint != null) ...[
            const SizedBox(height: VgSpace.s2),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Đầu tháng `‹ Tháng 11 năm 2026 ›` của Tổng quan và Lịch: hai nút 48 dp và
/// tên tháng giữa. Nút "sau" tắt khi [onNext] là null.
class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.title,
    required this.onPrevious,
    this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VgSize.appbar),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Symbols.chevron_left_rounded),
              tooltip: l.previousMonth,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Symbols.chevron_right_rounded),
              tooltip: l.nextMonth,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// Đầu kỳ của Thống kê: dùng chung kỳ với màn chính (F-03) — ‹ tên kỳ ▾ ›,
/// chạm tên kỳ mở bảng "Xem theo". Kỳ "Tất cả" ẩn hai nút.
class StatsPeriodHeader extends ConsumerWidget {
  const StatsPeriodHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(periodProvider);
    final notifier = ref.read(periodProvider.notifier);
    final canShift = period.type != PeriodType.all;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VgSize.appbar),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2),
        child: Row(
          mainAxisAlignment: canShift
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            if (canShift)
              IconButton(
                icon: const Icon(Symbols.chevron_left_rounded),
                tooltip: l.previousPeriod,
                onPressed: () => notifier.shift(-1),
              ),
            Flexible(
              child: Semantics(
                button: true,
                hint: l.choosePeriod,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => showPeriodPicker(context, ref),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: VgSize.tapMin),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VgSpace.s3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              periodTitle(context, period),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: VgSpace.s1),
                          const ExcludeSemantics(
                            child: Icon(Symbols.arrow_drop_down_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (canShift)
              IconButton(
                icon: const Icon(Symbols.chevron_right_rounded),
                tooltip: l.nextPeriod,
                onPressed: () => notifier.shift(1),
              ),
          ],
        ),
      ),
    );
  }
}

/// Nút lọc tài khoản trên thanh trên của Thống kê và Lịch: cùng bộ lọc với
/// màn chính (AC-20). Chỉ hiện khi có từ hai tài khoản.
class AccountFilterButton extends ConsumerWidget {
  const AccountFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    if (accounts.length < 2) return const SizedBox.shrink();
    final selected = ref.watch(accountFilterProvider);
    final current = accounts.where((a) => a.id == selected).firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    PopupMenuItem<int> item(int value, String label, bool on) =>
        PopupMenuItem<int>(
          value: value,
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (on) Icon(Symbols.check_rounded, color: scheme.primary),
            ],
          ),
        );
    return PopupMenuButton<int>(
      icon: Icon(
        Symbols.account_balance_wallet_rounded,
        fill: current == null ? 0 : 1,
      ),
      tooltip: current == null
          ? '${l.account}: ${l.allAccounts}'
          : '${l.account}: ${accountLabel(l, current)}',
      position: PopupMenuPosition.under,
      onSelected: (id) =>
          ref.read(accountFilterProvider.notifier).select(id == -1 ? null : id),
      itemBuilder: (context) => [
        item(-1, l.allAccounts, current == null),
        for (final a in accounts)
          item(a.id, accountLabel(l, a), current?.id == a.id),
      ],
    );
  }
}

/// Một cặp cột thu/chi của [FlowBarChart].
class FlowBarItem {
  const FlowBarItem({
    required this.label,
    required this.spoken,
    required this.income,
    required this.expense,
  });

  /// Nhãn ngắn dưới cột ("Thg 11", "6").
  final String label;

  /// Tên đầy đủ để đọc và hiện ở bảng ("Tháng 11 năm 2026").
  final String spoken;
  final int income;
  final int expense;
}

/// Một điểm của [BalanceLineChart].
class BalanceItem {
  const BalanceItem({
    required this.label,
    required this.spoken,
    required this.value,
  });

  final String label;
  final String spoken;
  final int value;
}

/// Nhãn tháng ngắn dưới cột: vi "T6" (intl cho "Tháng 6", quá dài cho cột
/// hẹp), ngôn ngữ khác theo intl ("Jun").
String shortMonthLabel(BuildContext context, DateTime d) {
  final locale = Localizations.localeOf(context).languageCode;
  return locale == 'vi' ? 'T${d.month}' : DateFormat.MMM(locale).format(d);
}

/// Chỉ nhãn thứ i của n cột khi n lớn, để nhãn không dính nhau: tối đa ~7 nhãn.
bool _showLabel(int i, int n) => n <= 7 || i % ((n / 7).ceil()) == 0;

Duration _animation(BuildContext context) =>
    MediaQuery.of(context).disableAnimations
    ? Duration.zero
    : const Duration(milliseconds: 150);

/// Chú giải thu/chi: ô màu kèm chữ (không chỉ dựa vào màu, AC-40).
class FlowLegend extends StatelessWidget {
  const FlowLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget key(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: VgSpace.s2),
        Text(
          text,
          style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
    return ExcludeSemantics(
      child: Wrap(
        spacing: VgSpace.s4,
        runSpacing: VgSpace.s1,
        children: [
          key(incomeColor(context), l.income),
          key(expenseColor(context), l.expense),
        ],
      ),
    );
  }
}

/// Nút đổi biểu đồ ↔ bảng (bảng thay thế đọc được, AC-108, AC-110).
class ChartTableToggle extends StatelessWidget {
  const ChartTableToggle({
    super.key,
    required this.table,
    required this.onChanged,
  });

  final bool table;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: () => onChanged(!table),
      icon: Icon(
        table ? Symbols.bar_chart_rounded : Symbols.table_rows_rounded,
      ),
      label: Text(table ? l.statsShowChart : l.statsShowTable),
    );
  }
}

/// Bảng thay thế của biểu đồ: mỗi dòng một mục, chữ thật (đọc được, phóng to
/// được). Dùng cho chế độ "Xem dạng bảng" của mọi biểu đồ.
class ChartTable extends StatelessWidget {
  const ChartTable({super.key, required this.columns, required this.rows});

  /// Tên cột; cột đầu là nhãn, các cột sau là số tiền (canh phải).
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final large = isLargeText(context);
    final head = VgType.labelSm.copyWith(color: scheme.onSurfaceVariant);
    final cell = VgType.bodySm.copyWith(
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget line(List<String> values, TextStyle style, {bool header = false}) {
      // Chữ lớn: mỗi mục xếp dọc "Cột: giá trị" để không bị cắt ở 360 dp.
      final Widget child = large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  values.first,
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
                for (var i = 1; i < values.length; i++)
                  Text('${columns[i]}: ${values[i]}', style: style),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: Text(values.first, style: style)),
                for (var i = 1; i < values.length; i++)
                  Expanded(
                    flex: 3,
                    child: Text(
                      values[i],
                      textAlign: TextAlign.end,
                      style: style,
                    ),
                  ),
              ],
            );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VgSpace.s1),
        child: header
            ? ExcludeSemantics(child: child)
            : MergeSemantics(child: child),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!large) line(columns, head, header: true),
        if (!large) Divider(height: 1, color: scheme.outlineVariant),
        for (final r in rows) line(r, cell),
      ],
    );
  }
}

/// Biểu đồ cột thu/chi (F-35, F-36). Mỗi mục là một cặp cột thu và chi. Chạm
/// một cặp thì dòng giá trị bên dưới hiện đúng số tiền của nó. Trình đọc màn
/// hình bỏ qua phần vẽ và đọc bảng thay thế: một câu cho mỗi mục; nút "Xem
/// dạng bảng" hiện bảng thật (AC-108, AC-110).
class FlowBarChart extends StatefulWidget {
  const FlowBarChart({
    super.key,
    required this.title,
    required this.items,
    required this.currency,
    this.initialSelected,
    this.height = 200,
  });

  /// Tên biểu đồ, đọc đầu bảng thay thế.
  final String title;
  final List<FlowBarItem> items;
  final String currency;

  /// Cặp cột đánh dấu lúc đầu (Tổng quan: tháng đang chọn).
  final int? initialSelected;
  final double height;

  @override
  State<FlowBarChart> createState() => _FlowBarChartState();
}

class _FlowBarChartState extends State<FlowBarChart> {
  int? _selected;
  bool _table = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
  }

  @override
  void didUpdateWidget(FlowBarChart old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length ||
        old.initialSelected != widget.initialSelected) {
      _selected = widget.initialSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = widget.items;
    String amount(int v) => money(context, widget.currency, v);
    final toggle = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ChartTableToggle(
        table: _table,
        onChanged: (v) => setState(() => _table = v),
      ),
    );
    if (_table) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartTable(
            columns: ['', l.income, l.expense],
            rows: [
              for (final i in items)
                [i.spoken, amount(i.income), amount(i.expense)],
            ],
          ),
          toggle,
        ],
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final n = items.length;
    final peak = items.fold<int>(
      0,
      (m, i) => math.max(m, math.max(i.income, i.expense)),
    );
    final maxY = peak == 0 ? 1.0 : peak * 1.1;
    final income = incomeColor(context), expense = expenseColor(context);
    final selected = _selected != null && _selected! < n ? _selected : null;
    final spokenRows = [
      for (final i in items)
        l.statsChartRow(i.spoken, amount(i.income), amount(i.expense)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l.statsChartSummary(widget.title, spokenRows.join('. ')),
          child: ExcludeSemantics(
            child: SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (context, box) {
                  final slot = box.maxWidth / math.max(n, 1);
                  final rod = (slot * 0.3).clamp(2.0, 16.0);
                  return BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: scheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= n || !_showLabel(i, n)) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  items[i].label,
                                  maxLines: 1,
                                  textScaler: TextScaler.noScaling,
                                  style: VgType.labelSm.copyWith(
                                    color: i == selected
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    fontWeight: i == selected
                                        ? FontWeight.w700
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        handleBuiltInTouches: false,
                        touchExtraThreshold: EdgeInsets.symmetric(
                          horizontal: math.max(2, (slot - rod * 2) / 2),
                          vertical: 400,
                        ),
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final i = response?.spot?.touchedBarGroupIndex;
                          if (i != null) setState(() => _selected = i);
                        },
                      ),
                      barGroups: [
                        for (final (i, item) in items.indexed)
                          BarChartGroupData(
                            x: i,
                            barsSpace: n > 20 ? 1 : 2,
                            barRods: [
                              for (final (v, c) in [
                                (item.income, income),
                                (item.expense, expense),
                              ])
                                BarChartRodData(
                                  toY: v.toDouble(),
                                  width: rod,
                                  color: selected == null || selected == i
                                      ? c
                                      : c.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    duration: _animation(context),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: VgSpace.s2),
        const FlowLegend(),
        if (selected != null)
          ChartReadout(
            text: l.statsChartReadout(
              items[selected].spoken,
              amount(items[selected].income),
              amount(items[selected].expense),
            ),
          ),
        toggle,
      ],
    );
  }
}

/// Dòng giá trị dưới biểu đồ khi chạm một cột/điểm.
class ChartReadout extends StatelessWidget {
  const ChartReadout({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: VgSpace.s2),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: VgType.bodySm.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

/// Đường lịch sử tổng số dư (F-36). Số dư âm vẽ thêm đường 0 nét đứt. Cách
/// đọc và chạm giống [FlowBarChart].
class BalanceLineChart extends StatefulWidget {
  const BalanceLineChart({
    super.key,
    required this.title,
    required this.items,
    required this.currency,
    this.height = 160,
  });

  final String title;
  final List<BalanceItem> items;
  final String currency;
  final double height;

  @override
  State<BalanceLineChart> createState() => _BalanceLineChartState();
}

class _BalanceLineChartState extends State<BalanceLineChart> {
  int? _selected;
  bool _table = false;

  @override
  void didUpdateWidget(BalanceLineChart old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = widget.items;
    String amount(int v) => money(context, widget.currency, v);
    final toggle = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ChartTableToggle(
        table: _table,
        onChanged: (v) => setState(() => _table = v),
      ),
    );
    if (_table || items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartTable(
            columns: ['', widget.title],
            rows: [
              for (final i in items) [i.spoken, amount(i.value)],
            ],
          ),
          if (items.isNotEmpty) toggle,
        ],
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final n = items.length;
    final lo = items.map((i) => i.value).reduce(math.min);
    final hi = items.map((i) => i.value).reduce(math.max);
    final pad = math.max(1.0, (hi - lo) * 0.15);
    final minY = lo - pad, maxY = hi + pad;
    final selected = _selected != null && _selected! < n ? _selected : null;
    final line = scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l.statsChartSummary(
            widget.title,
            [for (final i in items) l.statsValueRow(i.spoken, amount(i.value))]
                .join('. '),
          ),
          child: ExcludeSemantics(
            child: SizedBox(
              height: widget.height,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: n == 1 ? -0.5 : 0,
                  maxX: n == 1 ? 0.5 : (n - 1).toDouble(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (lo < 0 && hi > 0)
                        HorizontalLine(
                          y: 0,
                          color: scheme.onSurfaceVariant,
                          strokeWidth: 1,
                          dashArray: const [4, 4],
                        ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if ((value - i).abs() > 0.01 ||
                              i < 0 ||
                              i >= n ||
                              !_showLabel(i, n)) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              items[i].label,
                              maxLines: 1,
                              textScaler: TextScaler.noScaling,
                              style: VgType.labelSm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: false,
                    touchSpotThreshold: 40,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final spot = response?.lineBarSpots?.firstOrNull;
                      if (spot != null) {
                        setState(() => _selected = spot.spotIndex);
                      }
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (final (i, item) in items.indexed)
                          FlSpot(
                            n == 1 ? 0 : i.toDouble(),
                            item.value.toDouble(),
                          ),
                      ],
                      color: line,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: n <= 12,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: index == selected ? 5 : 3,
                              color: line,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                  ],
                ),
                duration: _animation(context),
              ),
            ),
          ),
        ),
        if (selected != null)
          ChartReadout(
            text: l.statsValueRow(
              items[selected].spoken,
              amount(items[selected].value),
            ),
          ),
        toggle,
      ],
    );
  }
}
