import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../data/recurring_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
import '../entry/keypad.dart' show minorUnitsToInput;

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
    final l = AppLocalizations.of(context);
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'VND',
    );
    final amount = TextEditingController(
      text: minorUnitsToInput(rule.amount, digits),
    );
    final note = TextEditingController(text: rule.note ?? '');
    String? error;
    final saved = await showDialog<(int, String?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.recurring),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(errorText: error),
              ),
              TextField(
                controller: note,
                maxLength: 200,
                decoration: InputDecoration(hintText: l.noteHint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final v = evaluateToMinorUnits(
                  amount.text.trim().replaceAll(',', '.'),
                  decimalDigits: digits,
                );
                if (v == null || v <= 0) {
                  setState(() => error = l.amountMustBePositive);
                  return;
                }
                final n = note.text.trim();
                Navigator.pop(context, (v, n.isEmpty ? null : n));
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
    note.dispose();
    if (saved != null) {
      await ref
          .read(recurringRepositoryProvider)
          .edit(rule.id, amount: saved.$1, note: saved.$2);
    }
  }
}
