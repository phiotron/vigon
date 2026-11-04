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
/// Dựng lười (chỉ các dòng đang nhìn thấy) để nhóm hàng nghìn khoản vẫn mượt (NFR 5b).
class EntriesScreen extends ConsumerStatefulWidget {
  const EntriesScreen({super.key});

  @override
  ConsumerState<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends ConsumerState<EntriesScreen> {
  /// Các nhóm đang mở, khóa dạng `e<id>` (chi) hoặc `i<id>` (thu).
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(periodProvider);
    final rows = ref.watch(periodEntriesProvider).value ?? const <EntryView>[];
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final transfers = rows
        .where((r) => r.entry.type == EntryType.transfer)
        .toList();
    final byCategory = <int, List<EntryView>>{};
    for (final r in rows) {
      final id = r.category?.id;
      if (id != null) (byCategory[id] ??= []).add(r);
    }
    final large = isLargeText(context);
    final theme = Theme.of(context);

    // Mỗi phần tử là một hàm dựng dòng; ListView.builder chỉ gọi cho dòng đang hiện.
    final items = <Widget Function()>[
      () => _AmountTile(
        title: Text(l.balance, style: theme.textTheme.titleLarge),
        amount: Text(
          money(context, currency, summary.balance),
          style: theme.textTheme.titleLarge,
        ),
      ),
      () => const Divider(),
    ];

    void section(
      String prefix,
      String title,
      Color color,
      int total,
      List<CategoryTotal> totals,
    ) {
      items.add(
        () => _AmountTile(
          title: Text(title, style: theme.textTheme.titleMedium),
          amount: Text(
            money(context, currency, total),
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      );
      for (final t in totals) {
        final key = '$prefix${t.category.id}';
        final open = _open.contains(key);
        items.add(
          () => Semantics(
            expanded: open,
            child: ListTile(
              leading: CategoryAvatar(category: t.category, size: 40),
              title: Text(categoryLabel(l, t.category)),
              subtitle: Text(
                large
                    ? '${percent(context, t.percent)} · '
                          '${money(context, currency, t.total)}'
                    : percent(context, t.percent),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!large) Text(money(context, currency, t.total)),
                  Icon(open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              onTap: () =>
                  setState(() => open ? _open.remove(key) : _open.add(key)),
            ),
          ),
        );
        if (open) {
          for (final r in byCategory[t.category.id] ?? const <EntryView>[]) {
            items.add(
              () => _EntryTile(
                row: r,
                title: r.entry.note ?? categoryLabel(l, t.category),
                amount: money(context, currency, r.entry.amount),
              ),
            );
          }
        }
      }
    }

    if (summary.expense > 0) {
      section(
        'e',
        l.expense,
        expenseColor(context),
        summary.expense,
        summary.expenseByCategory,
      );
    }
    if (summary.income > 0) {
      section(
        'i',
        l.income,
        incomeColor(context),
        summary.income,
        summary.incomeByCategory,
      );
    }
    if (transfers.isNotEmpty) {
      items.add(
        () => ListTile(
          title: Text(l.transfer, style: theme.textTheme.titleMedium),
        ),
      );
      for (final r in transfers) {
        items.add(
          () => _EntryTile(
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
        );
      }
    }
    items.add(() => const SizedBox(height: 24));

    return Scaffold(
      appBar: AppBar(title: Text(periodTitle(context, period))),
      body: rows.isEmpty
          ? Center(child: Text(l.noEntries))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => items[i](),
            ),
    );
  }
}

/// Dòng tổng: số tiền cuối dòng, hoặc dưới tiêu đề khi chữ lớn (AC-38).
class _AmountTile extends StatelessWidget {
  const _AmountTile({required this.title, required this.amount});

  final Widget title;
  final Widget amount;

  @override
  Widget build(BuildContext context) => isLargeText(context)
      ? ListTile(title: title, subtitle: amount)
      : ListTile(title: title, trailing: amount);
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
        subtitle: Text(
          isLargeText(context)
              ? '${shortDate(context, parseDateKey(entry.date))}\n$amount'
              : shortDate(context, parseDateKey(entry.date)),
        ),
        trailing: isLargeText(context) ? null : Text(amount),
        onTap: () => context.push(
          isTransfer ? '/transfer/${entry.id}' : '/entry/${entry.id}',
        ),
      ),
    );
  }
}
