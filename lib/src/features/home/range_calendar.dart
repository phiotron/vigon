import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/dates.dart';
import '../../data/period.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';

/// Mở lịch "Khoảng tùy chọn" (2.5) trong bảng kéo, giống nhau trên iPhone và
/// Android. Trả về khoảng đã chọn (đã đổi chỗ nếu chọn ngược), hoặc null khi
/// Hủy hay đóng bảng để giữ kỳ cũ.
Future<DateTimeRange?> showRangeCalendar(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTime today,
  int weekStart = DateTime.monday,
}) => showModalBottomSheet<DateTimeRange>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => RangeCalendarSheet(
    initialStart: initialStart,
    initialEnd: initialEnd,
    firstDate: firstDate,
    lastDate: lastDate,
    today: today,
    weekStart: weekStart,
  ),
);

/// Nội dung bảng lịch khoảng ngày (`.vg-cal`): dòng khoảng đang chọn, hàng
/// tháng ‹ ›, hàng thứ, lưới 7 cột ô cao 40, nút Hủy và Áp dụng.
class RangeCalendarSheet extends StatefulWidget {
  const RangeCalendarSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    this.weekStart = DateTime.monday,
  });

  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime today;

  /// `DateTime.monday` hoặc `DateTime.sunday` theo cài đặt (AC-12).
  final int weekStart;

  @override
  State<RangeCalendarSheet> createState() => _RangeCalendarSheetState();
}

class _RangeCalendarSheetState extends State<RangeCalendarSheet> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _month;

  DateTime get _firstMonth =>
      DateTime(widget.firstDate.year, widget.firstDate.month);
  DateTime get _lastMonth =>
      DateTime(widget.lastDate.year, widget.lastDate.month);

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart == null
        ? null
        : dateOnly(widget.initialStart!);
    _end = widget.initialEnd == null ? null : dateOnly(widget.initialEnd!);
    final shown = _start ?? widget.today;
    _month = _clampMonth(DateTime(shown.year, shown.month));
  }

  DateTime _clampMonth(DateTime m) => m.isBefore(_firstMonth)
      ? _firstMonth
      : (m.isAfter(_lastMonth) ? _lastMonth : m);

  /// Chạm lần đầu chọn ngày đầu, lần hai chọn ngày cuối; chọn ngược thì đổi
  /// chỗ. Đã có đủ hai đầu thì chạm tiếp là bắt đầu khoảng mới.
  void _tap(DateTime day) => setState(() {
    final start = _start;
    if (start == null || _end != null) {
      _start = day;
      _end = null;
    } else if (day.isBefore(start)) {
      _start = day;
      _end = start;
    } else {
      _end = day;
    }
  });

  void _apply() {
    final start = _start;
    if (start == null) return;
    // Chỉ chọn một ngày thì khoảng là đúng ngày đó.
    Navigator.pop(context, DateTimeRange(start: start, end: _end ?? start));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final start = _start;
    final rangeText = start == null || _end == null
        ? l.rangeHint
        : periodTitle(context, Period.custom(start, _end!));
    final monthName = DateFormat.yMMMM(locale).format(_month);
    final canBack = _month.isAfter(_firstMonth);
    final canForward = _month.isBefore(_lastMonth);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(l.periodCustom),
          Flexible(
            // Lề 12 thay cho 16 để 7 cột đủ rộng 48 ở màn 360 (AC-37).
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s1,
                      0,
                      VgSpace.s1,
                      VgSpace.s2,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        rangeText,
                        style: VgType.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: VgSpace.s2),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Symbols.chevron_left_rounded),
                          tooltip: l.previousMonth,
                          onPressed: canBack
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month - 1,
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            monthName.isEmpty
                                ? monthName
                                : monthName[0].toUpperCase() +
                                      monthName.substring(1),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.chevron_right_rounded),
                          tooltip: l.nextMonth,
                          onPressed: canForward
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month + 1,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  _MonthGrid(
                    month: _month,
                    weekStart: widget.weekStart,
                    start: _start,
                    end: _end,
                    today: dateOnly(widget.today),
                    firstDate: dateOnly(widget.firstDate),
                    lastDate: dateOnly(widget.lastDate),
                    onTap: _tap,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s4,
              VgSpace.s4,
              VgSpace.s4,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: VgSpace.s2,
              runSpacing: VgSpace.s2,
              children: [
                // Chữ `primary` trên `surface-container` chỉ 4,34:1, chưa đạt
                // 4,5:1 (AC-40), nên nút Hủy dùng màu chữ chính.
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: start == null ? null : _apply,
                  child: Text(l.apply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lưới một tháng: hàng thứ (chữ hẹp theo ngôn ngữ, bắt đầu theo ngày đầu
/// tuần) và các ô ngày. Ô chạm cao 48 (AC-37); vòng tròn và dải nền cao 40
/// như bản vẽ, nên giữa hai hàng hở 8 thay vì 2.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.weekStart,
    required this.start,
    required this.end,
    required this.today,
    required this.firstDate,
    required this.lastDate,
    required this.onTap,
  });

  final DateTime month;
  final int weekStart;
  final DateTime? start;
  final DateTime? end;
  final DateTime today;
  final DateTime firstDate;
  final DateTime lastDate;
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

    return Column(
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
                      ? const SizedBox(height: VgSize.tapMin)
                      : _DayCell(
                          day: day,
                          start: start,
                          end: end,
                          isToday: day == today,
                          enabled:
                              !day.isBefore(firstDate) &&
                              !day.isAfter(lastDate),
                          onTap: () => onTap(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Một ô ngày: ngày đầu/cuối tròn 40 nền `primary`, giữa khoảng nền
/// `primary-container`, hôm nay viền `primary` 1. Nhãn đọc là ngày đầy đủ.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.start,
    required this.end,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final DateTime? start;
  final DateTime? end;
  final bool isToday;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final s = start, e = end;
    final isStart = s != null && day == s;
    final isEnd = e != null && day == e;
    final isEdge = isStart || isEnd;
    final inside = s != null && e != null && day.isAfter(s) && day.isBefore(e);
    final hasRange = s != null && e != null && s != e;

    // Dải nền `primary-container` nối ngày đầu tới ngày cuối: ô giữa phủ kín,
    // ô đầu phủ nửa phải, ô cuối phủ nửa trái.
    Widget? band;
    if (inside) {
      band = ColoredBox(color: scheme.primaryContainer);
    } else if (hasRange && isEdge) {
      band = Row(
        children: [
          Expanded(
            child: isEnd
                ? ColoredBox(color: scheme.primaryContainer)
                : const SizedBox(),
          ),
          Expanded(
            child: isStart
                ? ColoredBox(color: scheme.primaryContainer)
                : const SizedBox(),
          ),
        ],
      );
    }

    final color = !enabled
        ? scheme.onSurfaceVariant
        : isEdge
        ? scheme.onPrimary
        : inside
        ? scheme.onPrimaryContainer
        : scheme.onSurface;

    return Semantics(
      button: true,
      selected: isEdge || inside,
      enabled: enabled,
      label: DateFormat.yMMMMEEEEd(locale).format(day),
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: VgSize.tapMin,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (band != null)
              Center(
                child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: band,
                ),
              ),
            Center(
              child: SizedBox.square(
                dimension: 40,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: isEdge ? scheme.primary : null,
                    shape: CircleBorder(
                      side: isToday && !isEdge
                          ? BorderSide(color: scheme.primary)
                          : BorderSide.none,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: enabled ? onTap : null,
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: VgType.bodySm.copyWith(
                            color: color,
                            fontWeight: isEdge ? FontWeight.w600 : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
