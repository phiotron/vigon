import 'package:flutter/material.dart';

import '../../ui/format.dart';
import '../../ui/tokens.g.dart';

/// Nội dung một ô ngày của Lịch chi tiêu.
class CalendarCellData {
  const CalendarCellData({
    required this.label,
    this.amount,
    this.hasIncome = false,
  });

  /// Câu trình đọc màn hình đọc, vd "6 tháng 11, chi 250.000 ₫" (AC-114).
  final String label;

  /// Tổng chi rút gọn ("50k", "1,2tr"); null khi ngày không có chi.
  final String? amount;

  /// Có khoản thu → chấm.
  final bool hasIncome;
}

/// Lưới một tháng của Lịch chi tiêu (F-38). Cùng cách dựng lưới với lịch
/// "Khoảng tùy chọn" (`home/range_calendar.dart`): hàng thứ chữ hẹp theo ngôn
/// ngữ bắt đầu theo Ngày đầu tuần (AC-12), 7 cột, ô trống trước ngày 1 và sau
/// ngày cuối. Ô cao hơn (56) để có chỗ cho số tiền rút gọn.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.weekStart,
    required this.today,
    required this.selected,
    required this.cellFor,
    required this.onTap,
  });

  /// Ngày bất kỳ trong tháng cần vẽ.
  final DateTime month;

  /// `DateTime.monday` hoặc `DateTime.sunday`.
  final int weekStart;
  final DateTime today;
  final DateTime? selected;
  final CalendarCellData Function(DateTime day) cellFor;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // narrowWeekdays bắt đầu từ Chủ nhật; DateTime.weekday: Thứ Hai = 1 … CN = 7.
    final weekdays = [
      for (var i = 0; i < 7; i++) material.narrowWeekdays[(weekStart + i) % 7],
    ];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = (DateTime(month.year, month.month).weekday - weekStart) % 7;
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    // Ô hẹp (~51 dp ở 360 dp): chữ trong ô phóng tối đa 130%; trình đọc màn
    // hình đọc nhãn đầy đủ của ô.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2),
        child: Column(
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    for (final w in weekdays)
                      Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: VgType.labelSm.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            for (var r = 0; r < cells.length ~/ 7; r++)
              Row(
                children: [
                  for (final day in cells.sublist(r * 7, r * 7 + 7))
                    Expanded(
                      child: day == null
                          ? const SizedBox(height: _cellHeight)
                          : _Cell(
                              day: day,
                              data: cellFor(day),
                              isToday: day == today,
                              isSelected: day == selected,
                              onTap: () => onTap(day),
                            ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

const _cellHeight = 60.0;

class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.data,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final CalendarCellData data;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = isSelected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: isSelected,
      label: data.label,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        height: _cellHeight,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VgRadius.sm),
              side: isToday
                  ? BorderSide(color: scheme.primary)
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(VgRadius.sm),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${day.day}',
                      style: VgType.bodySm.copyWith(
                        color: fg,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (data.amount != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          data.amount!,
                          maxLines: 1,
                          style: VgType.labelSm.copyWith(
                            color: isSelected ? fg : expenseColor(context),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                    SizedBox(
                      height: 6,
                      child: data.hasIncome
                          ? Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: incomeColor(context),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
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
