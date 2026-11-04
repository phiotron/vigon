import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';

/// Số tiền trong dòng: body-md, số đều độ rộng để cột tiền thẳng hàng.
final _rowAmount = VgType.bodyMd.copyWith(
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Danh sách khoản trong kỳ, gom theo danh mục, có tổng và phần trăm (AC-08),
/// theo S06 (4.1–4.4): Số dư → Chi → Thu → Chuyển tiền.
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
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
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
    final theme = Theme.of(context);

    // Mỗi phần tử là một hàm dựng dòng; ListView.builder chỉ gọi cho dòng đang hiện.
    final items = <Widget Function()>[
      () => _AmountTile(
        minHeight: VgSize.tapMain,
        title: Text(l.balance, style: theme.textTheme.titleLarge),
        amount: Text(
          money(context, currency, summary.balance),
          style: VgType.amountMd.copyWith(color: theme.colorScheme.onSurface),
        ),
      ),
      () => const Divider(height: VgSpace.s2 + 1),
    ];

    void section(
      String prefix,
      String title,
      Color color,
      int total,
      List<CategoryTotal> totals,
    ) {
      items.add(
        () => _SectionHeader(
          title: title,
          amount: money(context, currency, total),
          color: color,
        ),
      );
      for (final t in totals) {
        final key = '$prefix${t.category.id}';
        final open = _open.contains(key);
        items.add(
          () => _CategoryTile(
            total: t,
            amount: money(context, currency, t.total),
            open: open,
            onTap: () =>
                setState(() => open ? _open.remove(key) : _open.add(key)),
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
      items.add(() => _SectionHeader(title: l.transfer));
      String name(int? id) =>
          accounts[id] == null ? '' : accountLabel(l, accounts[id]!);
      for (final r in transfers) {
        items.add(
          () => _EntryTile(
            row: r,
            title: l.transferLabel(
              name(r.entry.accountId),
              name(r.entry.toAccountId),
            ),
            amount: money(context, currency, r.entry.amount),
            leading: const Icon(Symbols.swap_horiz_rounded),
          ),
        );
      }
    }
    items.add(() => const SizedBox(height: VgSpace.s6));

    return Scaffold(
      appBar: AppBar(title: Text(periodTitle(context, period))),
      body: rows.isEmpty
          // Kỳ trống (4.4): không có số dư, không có danh sách.
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.noEntries,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => items[i](),
            ),
    );
  }
}

/// Tiêu đề phần Chi / Thu / Chuyển tiền (`.vg-section.plain`): title-sm màu
/// chữ chính, tổng màu thu hoặc chi ở cuối; chữ lớn thì tổng xuống dòng.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.amount, this.color});

  final String title;
  final String? amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    final titleText = Semantics(header: true, child: Text(title, style: style));
    final amountText = amount == null
        ? null
        : Text(
            amount!,
            style: style?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s1,
      ),
      child: amountText == null
          ? titleText
          : isLargeText(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleText, amountText],
            )
          : Row(
              children: [
                Expanded(child: titleText),
                amountText,
              ],
            ),
    );
  }
}

/// Dòng tổng: số tiền cuối dòng, hoặc dưới tiêu đề khi chữ lớn (AC-38).
class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.title,
    required this.amount,
    this.minHeight = VgSize.tapKey,
  });

  final Widget title;
  final Widget amount;
  final double minHeight;

  @override
  Widget build(BuildContext context) => isLargeText(context)
      ? ListTile(minTileHeight: minHeight, title: title, subtitle: amount)
      : ListTile(minTileHeight: minHeight, title: title, trailing: amount);
}

/// Dòng danh mục: icon 40, tên, phần trăm, tổng, mũi tên mở/thu gọn (4.1).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.total,
    required this.amount,
    required this.open,
    required this.onTap,
  });

  final CategoryTotal total;
  final String amount;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large = isLargeText(context);
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      expanded: open,
      child: ListTile(
        leading: CategoryAvatar(category: total.category, size: 40),
        title: Text(categoryLabel(l, total.category)),
        subtitle: Text(
          large
              ? '${percent(context, total.percent)} · $amount'
              : percent(context, total.percent),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!large) Text(amount, style: _rowAmount.copyWith(color: ink)),
            const SizedBox(width: VgSpace.s1),
            Icon(
              open ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Một khoản; chạm để sửa (AC-13), vuốt trái để xóa có hoàn tác (AC-14, 4.2,
/// 4.3). Khoản của danh mục thụt vào 72; chuyển tiền có icon ⇄ ở đầu dòng.
class _EntryTile extends ConsumerWidget {
  const _EntryTile({
    required this.row,
    required this.title,
    required this.amount,
    this.leading,
  });

  final EntryView row;
  final String title;
  final String amount;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entry = row.entry;
    final isTransfer = entry.type == EntryType.transfer;
    final large = isLargeText(context);
    final date = shortDate(context, parseDateKey(entry.date));
    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      // Nền `swipe-delete`, thùng rác màu `error` (theme đặt errorContainer
      // và onErrorContainer theo hai token này).
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VgSpace.s6),
        child: Icon(Symbols.delete_rounded, color: scheme.onErrorContainer),
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
        contentPadding: EdgeInsets.only(
          left: leading == null ? 72 : VgSpace.s4,
          right: VgSpace.s4,
        ),
        leading: leading == null
            ? null
            : SizedBox(width: 40, child: Center(child: leading)),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(large ? '$date\n$amount' : date),
        trailing: large
            ? null
            : Text(amount, style: _rowAmount.copyWith(color: scheme.onSurface)),
        onTap: () => context.push(
          isTransfer ? '/transfer/${entry.id}' : '/entry/${entry.id}',
        ),
      ),
    );
  }
}
