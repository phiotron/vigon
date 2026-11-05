import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../data/recurring_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
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
    return Scaffold(
      appBar: AppBar(title: Text(l.recurring)),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noRecurring, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              children: [
                for (final r in rules)
                  ListTile(
                    leading: categories[r.categoryId] == null
                        ? const Icon(Icons.repeat)
                        : CategoryAvatar(
                            category: categories[r.categoryId]!,
                            size: 40,
                          ),
                    title: Text(
                      '${categories[r.categoryId] == null ? '' : categoryLabel(l, categories[r.categoryId]!)}'
                      ' · ${money(context, currency, r.amount)}',
                    ),
                    subtitle: Text(
                      r.active
                          ? '${repeatLabel(l, r.frequency)} · ${shortDate(context, RecurringRepository.nextDate(r))}'
                          : '${repeatLabel(l, r.frequency)} · ${l.repeatStopped}',
                    ),
                    trailing: Switch(
                      value: r.active,
                      onChanged: (on) => on
                          ? repo.resume(r.id, ref.read(clockProvider)())
                          : repo.stop(r.id),
                    ),
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
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'VND',
    );
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
        digits: digits,
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
