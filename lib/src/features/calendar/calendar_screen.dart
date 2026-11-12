import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/compact_amount.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../data/stats.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../debts/debt_movement.dart';
import '../entry/entry_time.dart';
import '../home/home_extras.dart';
import '../stats/stats_providers.dart';
import '../stats/stats_widgets.dart';
import 'calendar_grid.dart';
import 'calendar_providers.dart';

/// Lịch chi tiêu (F-38): lưới tháng, mỗi ngày tổng chi rút gọn và chấm nếu có
/// thu; ‹ › hoặc vuốt để đổi tháng; theo Ngày đầu tuần và bộ lọc tài khoản.
/// Chạm một ngày → các khoản của ngày đó kèm tổng thu/chi (AC-114).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final month = ref.watch(calendarMonthStartProvider);
    final flows = ref.watch(calendarFlowProvider).value ?? const <DailyFlow>[];
    final convert = ref.watch(moneyConvertProvider) ?? sumParts;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final today = ref.watch(todayProvider);
    final selected = ref.watch(calendarDayProvider);
    final rows =
        ref.watch(calendarDayEntriesProvider).value ?? const <EntryView>[];

    // Mỗi ngày quy đổi một lần (D-042).
    final byDay = <String, ({int expense, bool income})>{
      for (final f in flows)
        f.date: (expense: convert(f.expense), income: !f.income.isZero),
    };
    final selectedFlow = selected == null
        ? null
        : flows.where((f) => f.date == dateKey(selected)).firstOrNull;

    void shift(int delta) {
      ref.read(calendarMonthProvider.notifier).shift(delta);
      final next = ref.read(calendarMonthStartProvider);
      final inMonth = today.year == next.year && today.month == next.month;
      ref.read(calendarDayProvider.notifier).select(inMonth ? today : null);
    }

    final title = DateFormat.yMMMM(locale).format(month);
    final items = <Widget Function()>[
      () => CalendarGrid(
        month: month,
        weekStart: ref.watch(weekStartProvider).value ?? DateTime.monday,
        today: today,
        selected: selected,
        cellFor: (day) {
          final info = byDay[dateKey(day)];
          final expense = info?.expense ?? 0;
          final spoken = DateFormat.MMMMd(locale).format(day);
          final amountText = money(context, currency, expense);
          return CalendarCellData(
            amount: expense > 0
                ? compactAmount(
                    expense,
                    decimalDigits: currencyDecimalDigits(currency),
                    languageCode: locale,
                  )
                : null,
            hasIncome: info?.income ?? false,
            label: switch ((expense > 0, info?.income ?? false)) {
              (true, true) => l.calendarDaySpentIncome(spoken, amountText),
              (true, false) => l.calendarDaySpent(spoken, amountText),
              (false, true) => l.calendarDayIncome(spoken),
              (false, false) => spoken,
            },
          );
        },
        onTap: (day) => ref.read(calendarDayProvider.notifier).select(day),
      ),
      () => Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s4,
          VgSpace.s2,
          VgSpace.s4,
          VgSpace.s2,
        ),
        child: Text(
          l.calendarTapHint,
          style: VgType.bodySm.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      () => const Divider(height: 1),
    ];
    if (selected != null) {
      items.add(
        () => _DayHeader(
          day: selected,
          expense: selectedFlow == null ? 0 : convert(selectedFlow.expense),
          income: selectedFlow == null ? 0 : convert(selectedFlow.income),
          currency: currency,
        ),
      );
      if (rows.isEmpty) {
        items.add(
          () => Padding(
            padding: const EdgeInsets.all(VgSpace.s4),
            child: Text(
              l.calendarDayEmpty,
              style: VgType.bodyMd.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      for (final r in rows) {
        items.add(() => _DayEntryTile(row: r));
      }
    }
    items.add(() => const SizedBox(height: VgSpace.s6));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.calendarTitle),
        actions: const [AccountFilterButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            MonthHeader(
              title: title.isEmpty
                  ? title
                  : title[0].toUpperCase() + title.substring(1),
              onPrevious: () => shift(-1),
              onNext: () => shift(1),
            ),
            if (ref.watch(accountFilterProvider) != null)
              const ActiveAccountChip(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  shift(v < 0 ? 1 : -1);
                },
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) => items[i](),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Đầu danh sách của ngày đang chọn: tên ngày, "Chi X · Thu Y".
class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.expense,
    required this.income,
    required this.currency,
  });

  final DateTime day;
  final int expense;
  final int income;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final name = DateFormat.yMMMMEEEEd(locale).format(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s3,
        VgSpace.s4,
        VgSpace.s1,
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                name[0].toUpperCase() + name.substring(1),
                style: VgType.titleSm.copyWith(color: scheme.onSurface),
              ),
            ),
            Text(
              l.calendarDayTotals(
                money(context, currency, expense),
                money(context, currency, income),
              ),
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Một khoản trong ngày: chạm để sửa, vuốt trái để xoá có Hoàn tác (như Các
/// khoản, AC-13, AC-14).
class _DayEntryTile extends ConsumerWidget {
  const _DayEntryTile({required this.row});

  final EntryView row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entry = row.entry;
    final category = row.category;
    final isTransfer = entry.type == EntryType.transfer;
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    String name(int? id) =>
        accounts[id] == null ? '' : accountLabel(l, accounts[id]!);
    final title = isTransfer
        ? l.transferLabel(name(entry.accountId), name(entry.toAccountId))
        : (entry.note ?? (category == null ? '' : categoryLabel(l, category)));
    final time = entry.time;
    final subtitle = [
      if (!isTransfer && category != null && entry.note != null)
        categoryLabel(l, category),
      name(entry.accountId),
      if (time != null) formatTimeKey(context, time),
    ].where((s) => s.isNotEmpty).join(' · ');
    final large = isLargeText(context);
    final amount = MoneyLines(
      amount: entry.originalAmount ?? entry.amount,
      currency: entry.currency,
      style: VgType.bodyMd.copyWith(
        color: entry.type == EntryType.income
            ? incomeColor(context)
            : scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      secondaryStyle: VgType.bodySm,
      crossAxisAlignment: large
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      textAlign: large ? TextAlign.start : TextAlign.end,
    );
    final typeWord = switch (entry.type) {
      EntryType.income => l.income,
      EntryType.expense => l.expense,
      EntryType.transfer => l.transfer,
      EntryType.debt => debtMovementLabel(
        l,
        entry,
        ref.watch(debtPersonsProvider),
      ),
    };
    // Khoản thuộc khoản nợ xoá ở Chi tiết khoản nợ, không vuốt xoá (AC-170).
    final locked = opensDebtDetail(entry);
    return Dismissible(
      key: ValueKey('calendar-entry-${entry.id}'),
      direction: locked ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: context.vg.swipeDelete,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VgSpace.s6),
        child: Icon(Symbols.delete_rounded, color: context.vg.error),
      ),
      onDismissed: (_) async {
        final repo = ref.read(entryRepositoryProvider);
        final deleted = await repo.delete(entry.id);
        if (deleted != null) {
          showUndoSnackBar(
            message: l.deleted,
            undoLabel: l.undo,
            onUndo: () => repo.restore(deleted),
          );
        }
      },
      child: ListTile(
        leading: isTransfer || category == null
            ? SizedBox(
                width: 40,
                child: Center(
                  child: Icon(
                    entry.type == EntryType.debt
                        ? debtMovementIcon
                        : Symbols.swap_horiz_rounded,
                  ),
                ),
              )
            : ExcludeSemantics(
                child: CategoryAvatar(category: category, size: 40),
              ),
        title: Text(
          '$typeWord · $title',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: large
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle.isNotEmpty) Text(subtitle),
                  const SizedBox(height: 2),
                  amount,
                ],
              )
            : (subtitle.isEmpty ? null : Text(subtitle)),
        trailing: large ? null : amount,
        onTap: () => openEntry(context, entry),
      ),
    );
  }
}
