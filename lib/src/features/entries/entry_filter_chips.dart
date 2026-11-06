import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import 'entry_filter_state.dart';

/// Hàng chip dưới thanh tìm (N-04, AC-115): mỗi điều kiện của bộ lọc một chip
/// gỡ được (số tiền, từng danh mục, khoảng ngày) và nút "Xoá lọc" gỡ hết.
/// Nhiều chip thì xuống dòng.
class EntryFilterChips extends ConsumerWidget {
  const EntryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(entryFilterProvider);
    if (!filter.isActive) return const SizedBox.shrink();
    final notifier = ref.read(entryFilterProvider.notifier);
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final scheme = Theme.of(context).colorScheme;
    final categories = {
      for (final t in CategoryType.values)
        for (final c in ref.watch(categoriesProvider(t)).value ?? const [])
          c.id: c,
    };

    Widget chip(String text, VoidCallback onRemove, {Key? key}) => InputChip(
      key: key,
      label: Text(text),
      backgroundColor: scheme.secondaryContainer,
      labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      side: BorderSide.none,
      deleteIcon: const Icon(Symbols.close_rounded, size: 18),
      deleteIconColor: scheme.onSecondaryContainer,
      deleteButtonTooltipMessage: l.filterRemove(text),
      onDeleted: onRemove,
    );

    final amount = filter.hasAmount
        ? switch ((filter.minAmount, filter.maxAmount)) {
            (final a?, final b?) =>
              '${money(context, currency, a)} – ${money(context, currency, b)}',
            (final a?, null) => l.filterChipFrom(money(context, currency, a)),
            (null, final b?) => l.filterChipUpTo(money(context, currency, b)),
            _ => '',
          }
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s1,
        VgSpace.s4,
        VgSpace.s1,
      ),
      child: Wrap(
        spacing: VgSpace.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (amount != null)
            chip(
              amount,
              () => notifier.remove(amount: true),
              key: const ValueKey('chip-amount'),
            ),
          for (final id in filter.categoryIds)
            if (categories[id] != null)
              chip(
                categoryLabel(l, categories[id]!),
                () => notifier.remove(category: id),
                key: ValueKey('chip-category-$id'),
              ),
          if (filter.hasDates)
            chip(
              periodTitle(context, Period.custom(filter.from!, filter.to!)),
              () => notifier.remove(dates: true),
              key: const ValueKey('chip-dates'),
            ),
          TextButton(
            onPressed: notifier.clear,
            child: Text(l.filterClearAll),
          ),
        ],
      ),
    );
  }
}
