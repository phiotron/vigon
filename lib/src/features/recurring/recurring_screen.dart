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
import '../../ui/tokens.g.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
import '../entry/keypad.dart' show minorUnitsToInput;
import '../settings/budget_dialog.dart' show currencySymbol;

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
    final saved = await showDialog<(int, String?)>(
      context: context,
      builder: (context) => _RuleDialog(
        rule: rule,
        digits: currencyDecimalDigits(currency),
        symbol: currencySymbol(currency),
      ),
    );
    if (saved != null) {
      await ref
          .read(recurringRepositoryProvider)
          .edit(rule.id, amount: saved.$1, note: saved.$2);
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

/// Hộp thoại tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class _RuleDialog extends StatefulWidget {
  const _RuleDialog({
    required this.rule,
    required this.digits,
    required this.symbol,
  });

  final RecurringRule rule;
  final int digits;
  final String symbol;

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
    // Sửa chuỗi (7.2): Số tiền tự focus, ghi chú áp dụng cho các lần sinh sau.
    return AlertDialog(
      title: Text(l.recurring),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: VgSpace.s2),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l.amountLabel,
                suffixText: widget.symbol,
                errorText: _error,
              ),
            ),
            const SizedBox(height: VgSpace.s6),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.noteHint,
                helperText: l.recurringEditNote,
                helperMaxLines: 3,
              ),
            ),
          ],
        ),
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
