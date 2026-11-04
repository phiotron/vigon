import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/period.dart';
import '../../providers.dart';

/// Chọn loại kỳ xem: ngày, tuần, tháng, năm, tất cả, khoảng tùy chọn (AC-10).
Future<void> showPeriodPicker(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final current = ref.read(periodProvider);
  final labels = {
    PeriodType.day: l.periodDay,
    PeriodType.week: l.periodWeek,
    PeriodType.month: l.periodMonth,
    PeriodType.year: l.periodYear,
    PeriodType.all: l.periodAll,
    PeriodType.custom: l.periodCustom,
  };
  final type = await showModalBottomSheet<PeriodType>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final entry in labels.entries)
            ListTile(
              title: Text(entry.value),
              selected: entry.key == current.type,
              trailing: entry.key == current.type
                  ? const Icon(Symbols.check_rounded)
                  : null,
              onTap: () => Navigator.pop(context, entry.key),
            ),
        ],
      ),
    ),
  );
  if (type == null || !context.mounted) return;
  final notifier = ref.read(periodProvider.notifier);
  if (type != PeriodType.custom) {
    notifier.selectType(type);
    return;
  }
  final now = ref.read(clockProvider)();
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 10),
    initialDateRange: DateTimeRange(start: current.start, end: current.end),
  );
  if (range != null) notifier.select(Period.custom(range.start, range.end));
}
