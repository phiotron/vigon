import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/summary.dart';
import 'format.dart';
import 'tokens.g.dart';

/// Vòng chi tiêu theo danh mục (ChartRing.html, 2.1, SCR-01): cung màu danh
/// mục từ lớn tới nhỏ, bắt đầu 12 giờ, cách nhau 2; vòng dày 30, lỗ giữa bán
/// kính 77 (nhân [scale]). Chỉ có thu thì vòng đầy màu thu.
///
/// Giữa vòng (v2): nhãn label-sm màu chữ phụ "Thu" trên tổng thu, "Chi" trên
/// tổng chi — không phân biệt chỉ bằng màu. [showTotals] = false khi màn tự
/// đưa tổng ra danh sách dưới vòng (chữ ≥ 130%, A04).
class SpendingRing extends StatelessWidget {
  const SpendingRing({
    super.key,
    required this.summary,
    required this.currency,
    this.scale = 1,
    this.showTotals = true,
  });

  final PeriodSummary summary;
  final String currency;
  final double scale;
  final bool showTotals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
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
    final label = VgType.labelSm.copyWith(color: muted);
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
        if (showTotals)
          Center(
            child: SizedBox.square(
              dimension: inner * 2 - VgSpace.s4,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.income, style: label),
                      Text(
                        money(context, currency, summary.income),
                        style: VgType.amountMd.copyWith(
                          color: incomeColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l.expense, style: label),
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
