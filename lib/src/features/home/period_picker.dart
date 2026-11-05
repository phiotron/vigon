import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/period.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import 'range_calendar.dart';

/// Bảng "Xem theo" (2.4): ngày, tuần, tháng, năm, tất cả, khoảng tùy chọn
/// (AC-10). Chọn loại nào thì nhảy tới kỳ chứa hôm nay của loại đó; khoảng
/// tùy chọn mở lịch riêng của app (2.5).
Future<void> showPeriodPicker(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final current = ref.read(periodProvider);
  final picked = await showChoiceSheet<PeriodType>(
    context,
    title: l.viewBy,
    selected: current.type,
    options: [
      ChoiceOption(PeriodType.day, l.periodDay, icon: Symbols.today_rounded),
      ChoiceOption(
        PeriodType.week,
        l.periodWeek,
        icon: Symbols.date_range_rounded,
      ),
      ChoiceOption(
        PeriodType.month,
        l.periodMonth,
        icon: Symbols.calendar_month_rounded,
      ),
      ChoiceOption(
        PeriodType.year,
        l.periodYear,
        icon: Symbols.event_note_rounded,
      ),
      ChoiceOption(
        PeriodType.all,
        l.periodAll,
        icon: Symbols.all_inclusive_rounded,
      ),
      ChoiceOption(
        PeriodType.custom,
        l.periodCustom,
        icon: Symbols.edit_calendar_rounded,
      ),
    ],
  );
  if (picked == null || !context.mounted) return;
  final type = picked.$1;
  final notifier = ref.read(periodProvider.notifier);
  if (type != PeriodType.custom) {
    notifier.selectType(type);
    return;
  }
  final now = ref.read(clockProvider)();
  // Kỳ "Tất cả" không có ngày đầu cuối thật, nên mở lịch chưa chọn ngày nào.
  final hasRange = current.type != PeriodType.all;
  final range = await showRangeCalendar(
    context,
    initialStart: hasRange ? current.start : null,
    initialEnd: hasRange ? current.end : null,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 10, 12, 31),
    today: now,
    weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
  );
  if (range != null) notifier.select(Period.custom(range.start, range.end));
}
