import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../data/recurring_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
import '../settings/budget_dialog.dart' show currencySymbol;
import 'rule_dialog.dart';

/// Danh sách chuỗi định kỳ: dừng, chạy lại, sửa số tiền (AC-25).
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rules =
        ref.watch(recurringRulesProvider).value ?? const <RecurringRule>[];
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final categories = {
      for (final type in CategoryType.values)
        for (final c
            in ref.watch(categoriesProvider(type)).value ?? const <Category>[])
          c.id: c,
    };
    final repo = ref.read(recurringRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.recurring)),
      body: rules.isEmpty
          // Trống (7.3): lời nhắc giữa màn.
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.noRecurring,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              children: [
                for (final r in rules)
                  _RuleTile(
                    rule: r,
                    category: categories[r.categoryId],
                    amount: money(context, currency, r.amount),
                    onToggle: (on) => on
                        ? repo.resume(r.id, ref.read(clockProvider)())
                        : repo.stop(r.id),
                    onTap: () => _edit(context, ref, r),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
  ) async {
    final currency = ref.read(currencyProvider).value ?? 'VND';
    final categories = switch (rule.type) {
      EntryType.transfer => const <Category>[],
      EntryType.income =>
        ref.read(categoriesProvider(CategoryType.income)).value,
      EntryType.expense =>
        ref.read(categoriesProvider(CategoryType.expense)).value,
    };
    final saved = await showDialog<RuleEdit>(
      context: context,
      builder: (context) => RuleDialog(
        rule: rule,
        digits: currencyDecimalDigits(currency),
        symbol: currencySymbol(currency),
        categories: categories ?? const <Category>[],
        accounts: ref.read(accountsProvider).value ?? const <Account>[],
      ),
    );
    if (saved != null) {
      await ref
          .read(recurringRepositoryProvider)
          .edit(
            rule.id,
            amount: saved.amount,
            note: saved.note,
            frequency: saved.frequency,
            categoryId: saved.categoryId,
            accountId: saved.accountId,
          );
    }
  }
}

/// Một chuỗi (7.1): icon danh mục, "Danh mục · số tiền", "Tần suất · ngày
/// tới hạn" hoặc "Đã dừng", công tắc; chạm dòng để sửa.
class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.category,
    required this.amount,
    required this.onToggle,
    required this.onTap,
  });

  final RecurringRule rule;
  final Category? category;
  final String amount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = category == null ? '' : categoryLabel(l, category!);
    final title = '$name · $amount';
    return ListTile(
      leading: category == null
          ? const SizedBox(
              width: 40,
              child: Center(child: Icon(Symbols.event_repeat_rounded)),
            )
          : CategoryAvatar(category: category!, size: 40),
      title: Text(title),
      subtitle: Text(
        rule.active
            ? '${repeatLabel(l, rule.frequency)} · '
                  '${shortDate(context, RecurringRepository.nextDate(rule))}'
            : '${repeatLabel(l, rule.frequency)} · ${l.repeatStopped}',
      ),
      // Công tắc đọc tên chuỗi để TalkBack biết đang bật/tắt chuỗi nào.
      trailing: Semantics(
        label: title,
        child: Switch(value: rule.active, onChanged: onToggle),
      ),
      onTap: onTap,
    );
  }
}
