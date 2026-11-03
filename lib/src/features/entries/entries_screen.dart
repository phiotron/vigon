import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';

/// Danh sách khoản trong kỳ, gom theo danh mục, có tổng và phần trăm (AC-08).
class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(periodProvider);
    final rows = ref.watch(periodEntriesProvider).value ?? const <EntryView>[];
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final transfers = rows
        .where((r) => r.entry.type == EntryType.transfer)
        .toList();

    List<Widget> section(
      String title,
      Color color,
      int total,
      List<CategoryTotal> totals,
    ) => [
      ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Text(
          money(context, currency, total),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color),
        ),
      ),
      for (final t in totals)
        ExpansionTile(
          leading: CategoryAvatar(category: t.category, size: 40),
          title: Text(categoryLabel(l, t.category)),
          subtitle: Text(percent(context, t.percent)),
          trailing: Text(money(context, currency, t.total)),
          children: [
            for (final r in rows.where((r) => r.category?.id == t.category.id))
              _EntryTile(
                row: r,
                title: r.entry.note ?? categoryLabel(l, t.category),
                amount: money(context, currency, r.entry.amount),
              ),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(periodTitle(context, period))),
      body: rows.isEmpty
          ? Center(child: Text(l.noEntries))
          : ListView(
              children: [
                ListTile(
                  title: Text(
                    l.balance,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  trailing: Text(
                    money(context, currency, summary.balance),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(),
                if (summary.expense > 0)
                  ...section(
                    l.expense,
                    expenseColor(context),
                    summary.expense,
                    summary.expenseByCategory,
                  ),
                if (summary.income > 0)
                  ...section(
                    l.income,
                    incomeColor(context),
                    summary.income,
                    summary.incomeByCategory,
                  ),
                if (transfers.isNotEmpty) ...[
                  ListTile(
                    title: Text(
                      l.transfer,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final r in transfers)
                    _EntryTile(
                      row: r,
                      title: l.transferLabel(
                        accounts[r.entry.accountId] == null
                            ? ''
                            : accountLabel(l, accounts[r.entry.accountId]!),
                        accounts[r.entry.toAccountId] == null
                            ? ''
                            : accountLabel(l, accounts[r.entry.toAccountId]!),
                      ),
                      amount: money(context, currency, r.entry.amount),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

/// Một khoản; chạm để sửa (AC-13), vuốt để xóa có hoàn tác (AC-14).
class _EntryTile extends ConsumerWidget {
  const _EntryTile({
    required this.row,
    required this.title,
    required this.amount,
  });

  final EntryView row;
  final String title;
  final String amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entry = row.entry;
    final isTransfer = entry.type == EntryType.transfer;
    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
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
        contentPadding: const EdgeInsets.only(left: 72, right: 16),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(shortDate(context, parseDateKey(entry.date))),
        trailing: Text(amount),
        onTap: () => context.push(
          isTransfer ? '/transfer/${entry.id}' : '/entry/${entry.id}',
        ),
      ),
    );
  }
}
