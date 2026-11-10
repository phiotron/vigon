import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/repeat.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/hint.dart';
import '../../ui/tokens.g.dart';

/// Short weekday name: "T2" … "CN" / "Mon" … "Sun".
String weekdayShort(AppLocalizations l, int weekday) => switch (weekday) {
  DateTime.monday => l.weekdayMon,
  DateTime.tuesday => l.weekdayTue,
  DateTime.wednesday => l.weekdayWed,
  DateTime.thursday => l.weekdayThu,
  DateTime.friday => l.weekdayFri,
  DateTime.saturday => l.weekdaySat,
  _ => l.weekdaySun,
};

/// The 7 weekdays in display order, starting at [weekStart] (Week start).
List<int> weekdayOrder(int weekStart) => [
  for (var i = 0; i < 7; i++) (weekStart - 1 + i) % 7 + 1,
];

/// Label of a repeat choice; "Pick days" lists the days, eg "T2, T3".
String repeatText(
  AppLocalizations l,
  Repeat? r, {
  int weekStart = DateTime.monday,
}) {
  if (r == null) return l.repeatNone;
  final mask = r.weekdays;
  if (mask != null) {
    return [
      for (final d in weekdayOrder(weekStart))
        if (mask & weekdayBit(d) != 0) weekdayShort(l, d),
    ].join(', ');
  }
  return switch (r.frequency) {
    RecurrenceFrequency.daily => l.repeatDaily,
    RecurrenceFrequency.weekly => l.repeatWeekly,
    RecurrenceFrequency.monthly => l.repeatMonthly,
    RecurrenceFrequency.yearly => l.repeatYearly,
  };
}

/// "T2 16/11" / "Mon 11/16" — date of the first record of a series (F-45).
String weekdayDate(BuildContext context, DateTime d) {
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return '${weekdayShort(l, d.weekday)} ${DateFormat.Md(locale).format(d)}';
}

enum _Kind { none, daily, weekly, pickDays, monthly, yearly }

/// "Repeat" sheet of a new record (3.5 + F-45): Does not repeat · Daily ·
/// Weekly · Pick days… · Monthly · Yearly. "Pick days…" opens
/// [showWeekdaySheet] (pre-selected: the current days, else the weekday of
/// [date]). Returns `(repeat,)` (null = Does not repeat), or null when closed.
Future<(Repeat?,)?> showRepeatSheet(
  BuildContext context, {
  required Repeat? selected,
  required DateTime date,
  required int weekStart,
}) async {
  final l = AppLocalizations.of(context);
  final current = switch (selected) {
    null => _Kind.none,
    Repeat(isPickDays: true) => _Kind.pickDays,
    Repeat(frequency: RecurrenceFrequency.daily) => _Kind.daily,
    Repeat(frequency: RecurrenceFrequency.weekly) => _Kind.weekly,
    Repeat(frequency: RecurrenceFrequency.monthly) => _Kind.monthly,
    Repeat(frequency: RecurrenceFrequency.yearly) => _Kind.yearly,
  };
  final picked = await showChoiceSheet<_Kind>(
    context,
    title: l.repeat,
    selected: current,
    options: [
      ChoiceOption(_Kind.none, l.repeatNone),
      ChoiceOption(_Kind.daily, l.repeatDaily),
      ChoiceOption(_Kind.weekly, l.repeatWeekly),
      ChoiceOption(
        _Kind.pickDays,
        selected?.isPickDays == true
            ? '${l.repeatPickDays} (${repeatText(l, selected, weekStart: weekStart)})'
            : l.repeatPickDays,
      ),
      ChoiceOption(_Kind.monthly, l.repeatMonthly),
      ChoiceOption(_Kind.yearly, l.repeatYearly),
    ],
  );
  if (picked == null) return null;
  if (picked.$1 == _Kind.pickDays) {
    if (!context.mounted) return null;
    return _pickDays(context, selected, date, weekStart);
  }
  return switch (picked.$1) {
    _Kind.daily => (const Repeat(RecurrenceFrequency.daily),),
    _Kind.weekly => (const Repeat(RecurrenceFrequency.weekly),),
    _Kind.monthly => (const Repeat(RecurrenceFrequency.monthly),),
    _Kind.yearly => (const Repeat(RecurrenceFrequency.yearly),),
    _ => (null,),
  };
}

Future<(Repeat?,)?> _pickDays(
  BuildContext context,
  Repeat? selected,
  DateTime date,
  int weekStart,
) async {
  final mask = await showWeekdaySheet(
    context,
    initialMask: selected?.weekdays ?? weekdayBit(date.weekday),
    weekStart: weekStart,
  );
  return mask == null ? null : (Repeat.days(mask),);
}

/// Sheet of 7 weekday chips (like an alarm clock). Returns the picked mask
/// (> 0) on Done, null when closed. All 7 picked = Daily ([Repeat.days]).
Future<int?> showWeekdaySheet(
  BuildContext context, {
  required int initialMask,
  required int weekStart,
}) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) =>
      _WeekdaySheet(initialMask: initialMask, weekStart: weekStart),
);

class _WeekdaySheet extends StatefulWidget {
  const _WeekdaySheet({required this.initialMask, required this.weekStart});

  final int initialMask;
  final int weekStart;

  @override
  State<_WeekdaySheet> createState() => _WeekdaySheetState();
}

class _WeekdaySheetState extends State<_WeekdaySheet> {
  late int _mask = widget.initialMask & allWeekdaysMask;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: VgSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.repeatPickDaysTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
              child: Wrap(
                spacing: VgSpace.s2,
                runSpacing: VgSpace.s2,
                children: [
                  for (final d in weekdayOrder(widget.weekStart))
                    FilterChip(
                      key: ValueKey('weekday-$d'),
                      label: Text(weekdayShort(l, d)),
                      selected: _mask & weekdayBit(d) != 0,
                      onSelected: (on) => setState(
                        () => _mask = on
                            ? _mask | weekdayBit(d)
                            : _mask & ~weekdayBit(d),
                      ),
                    ),
                ],
              ),
            ),
            VgHint(
              l.repeatAllDaysHint,
              icon: Symbols.info_rounded,
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s6,
                VgSpace.s3,
                VgSpace.s6,
                0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s6,
                VgSpace.s4,
                VgSpace.s6,
                0,
              ),
              child: FilledButton(
                key: const Key('weekday-done'),
                onPressed: _mask == 0
                    ? null
                    : () => Navigator.pop(context, _mask),
                child: Text(l.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
