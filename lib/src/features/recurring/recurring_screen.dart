import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

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
                        ? const Icon(Symbols.repeat_rounded)
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
    final saved = await showDialog<(int, String?)>(
      context: context,
      builder: (context) => _RuleDialog(rule: rule, digits: digits),
    );
    if (saved != null) {
      await ref
          .read(recurringRepositoryProvider)
          .edit(rule.id, amount: saved.$1, note: saved.$2);
    }
  }
}

/// Hộp thoại tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class _RuleDialog extends StatefulWidget {
  const _RuleDialog({required this.rule, required this.digits});

  final RecurringRule rule;
  final int digits;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final _amount = TextEditingController(
    text: minorUnitsToInput(widget.rule.amount, widget.digits),
  );
  late final _note = TextEditingController(text: widget.rule.note ?? '');
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final v = evaluateToMinorUnits(
      _amount.text.trim().replaceAll(',', '.'),
      decimalDigits: widget.digits,
    );
    if (v == null || v <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    final n = _note.text.trim();
    Navigator.pop(context, (v, n.isEmpty ? null : n));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.recurring),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(errorText: _error),
          ),
          TextField(
            controller: _note,
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
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
