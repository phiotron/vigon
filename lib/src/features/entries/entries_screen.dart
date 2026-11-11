import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/money_lines.dart';
import '../../ui/status.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../../data/money_sum.dart' show isDebtInflow;
import '../debts/debt_movement.dart';
import '../entry/entry_time.dart';
import '../entry/ledger_guard.dart';
import '../home/home_extras.dart';
import 'category_budget.dart';
import 'entry_search.dart';

/// Lề ngang của dòng `.vg-row` (SCR-10): 16 hai bên.
const _rowPadding = EdgeInsets.symmetric(horizontal: VgSpace.s4);

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
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final transfers = rows
        .where((r) => r.entry.type == EntryType.transfer)
        .toList();
    // Debt movement (D-049): không thu/chi, nhóm riêng như chuyển tiền.
    final debtMoves = rows
        .where((r) => r.entry.type == EntryType.debt)
        .toList();
    final persons = ref.watch(debtPersonsProvider);
    final byCategory = <int, List<EntryView>>{};
    for (final r in rows) {
      final id = r.category?.id;
      if (id != null) (byCategory[id] ??= []).add(r);
    }
    final theme = Theme.of(context);
    String accountName(int id) =>
        accounts[id] == null ? '' : accountLabel(l, accounts[id]!);

    // Mỗi phần tử là một hàm dựng dòng; ListView.builder chỉ gọi cho dòng đang hiện.
    final items = <Widget Function()>[
      () => _AmountTile(
        minHeight: VgSize.tapMain,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.balance, style: theme.textTheme.titleLarge),
            // "theo USD" (mockup v4 SCR-10, D-042).
            Text(
              l.mainFirstNote(currency),
              style: VgType.bodySm.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
        // Thanh hạn mức tháng ngay dưới dòng danh mục chi có hạn mức, thụt
        // vào cột chữ (AC-54, SCR-10).
        if (prefix == 'e' && t.category.budget != null) {
          items.add(() => CategoryBudgetBar(category: t.category));
        }
        if (open) {
          for (final r in byCategory[t.category.id] ?? const <EntryView>[]) {
            items.add(
              () => _EntryTile(
                row: r,
                title: r.entry.note ?? categoryLabel(l, t.category),
                amount: MoneyLines(
                  amount: r.entry.originalAmount ?? r.entry.amount,
                  currency: r.entry.currency,
                  style: _rowAmount.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  secondaryStyle: VgType.bodySm,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textAlign: TextAlign.end,
                ),
                accountName: accountName(r.entry.accountId),
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
            amount: MoneyLines(
              amount: r.entry.originalAmount ?? r.entry.amount,
              currency: r.entry.currency,
              style: _rowAmount.copyWith(color: theme.colorScheme.onSurface),
              secondaryStyle: VgType.bodySm,
              crossAxisAlignment: CrossAxisAlignment.end,
              textAlign: TextAlign.end,
            ),
            leading: const Icon(Symbols.swap_horiz_rounded),
            accountName: name(r.entry.accountId),
          ),
        );
      }
    }
    if (debtMoves.isNotEmpty) {
      items.add(() => _SectionHeader(title: l.debtMovementsSection));
      for (final r in debtMoves) {
        final e = r.entry;
        final amount = e.originalAmount ?? e.amount;
        items.add(
          () => _EntryTile(
            row: r,
            title: debtMovementLabel(l, e, persons),
            amount: MoneyLines(
              amount: isDebtInflow(e) ? amount : -amount,
              currency: e.currency,
              style: _rowAmount.copyWith(color: theme.colorScheme.onSurface),
              secondaryStyle: VgType.bodySm,
              crossAxisAlignment: CrossAxisAlignment.end,
              textAlign: TextAlign.end,
            ),
            leading: const Icon(debtMovementIcon),
            accountName: accountName(e.accountId),
          ),
        );
      }
    }
    items.add(() => const SizedBox(height: VgSpace.s6));

    return Scaffold(
      appBar: EntriesAppBar(title: periodTitle(context, period)),
      body: ref.watch(entrySearchProvider.select((s) => s.active))
          ? const EntrySearchResults()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tài khoản đang lọc hiện rõ ở đầu danh sách (§10.1 #1).
                if (ref.watch(accountFilterProvider) != null)
                  const ActiveAccountChip(),
                Expanded(child: _list(context, rows.isEmpty, items)),
              ],
            ),
    );
  }

  Widget _list(
    BuildContext context,
    bool empty,
    List<Widget Function()> items,
  ) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return empty
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
      ? ListTile(
          minTileHeight: minHeight,
          contentPadding: _rowPadding,
          title: title,
          subtitle: amount,
        )
      : ListTile(
          minTileHeight: minHeight,
          contentPadding: _rowPadding,
          title: title,
          trailing: amount,
        );
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
        // Lề phải 16 như `.vg-row` (M3 mặc định 24) để tổng danh mục thẳng
        // cột với số tiền khoản bên dưới (rãnh 24, §10.1 #12).
        contentPadding: _rowPadding,
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
    this.accountName = '',
  });

  final EntryView row;
  final String title;
  final Widget amount;
  final Widget? leading;

  /// Tên tài khoản của khoản; chỉ hiện cạnh giờ khi khoản có giờ (AC-76).
  final String accountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entry = row.entry;
    // ✉ cho khoản lưu từ email MB hoặc khoản ghi tay đã ghép với email
    // (mockup v4 SCR-10).
    final fromEmail =
        entry.source == EntrySource.emailMb || entry.referenceNumber != null;
    final large = isLargeText(context);
    // Khoản của hôm nay ghi "Hôm nay" như frame SCR-10/11 (A05, A06).
    final day = parseDateKey(entry.date);
    final date = day == ref.watch(todayProvider)
        ? l.today
        : shortDate(context, day);
    // Khoản có giờ: "<ngày> · <tài khoản> · <giờ>" (AC-76); không giờ: chỉ ngày.
    final time = entry.time;
    final when = time == null
        ? date
        : [
            date,
            if (accountName.isNotEmpty) accountName,
            formatTimeKey(context, time),
          ].join(' · ');
    return Dismissible(
      key: ValueKey('entry-${entry.id}'),
      // Khoản thuộc khoản nợ: sửa/xoá trong Chi tiết khoản nợ (AC-170).
      direction: opensDebtDetail(entry)
          ? DismissDirection.none
          : DismissDirection.endToStart,
      // Nền `swipe-delete`, thùng rác màu `error`. Từ token v2 errorContainer
      // của theme là dải lỗi (khác màu ở chủ đề tối), nên dùng token riêng.
      background: Container(
        color: context.vg.swipeDelete,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VgSpace.s6),
        child: Icon(Symbols.delete_rounded, color: context.vg.error),
      ),
      // Có thu mới có chi (AC-161): xoá làm âm tài khoản thì báo, không xoá.
      confirmDismiss: (_) => canDeleteEntry(context, ref, entry),
      onDismissed: (_) => deleteEntryWithUndo(context, ref, entry),
      child: ListTile(
        contentPadding: EdgeInsets.only(
          left: leading == null ? 72 : VgSpace.s4,
          right: VgSpace.s4,
        ),
        leading: leading == null
            ? null
            : SizedBox(width: 40, child: Center(child: leading)),
        title: fromEmail
            ? Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: title),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: MailMarker(semanticLabel: l.mbLinked),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: large
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(when), const SizedBox(height: 2), amount],
              )
            : Text(when),
        // Số tiền khoản thẳng mép phải với tổng danh mục: rãnh 24 (+4) thay
        // chỗ mũi tên mở/thu (§10.1 #12, SCR-10).
        trailing: large
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  amount,
                  const SizedBox(width: VgSpace.s1 + 24),
                ],
              ),
        onTap: () => openEntry(context, entry),
      ),
    );
  }
}
