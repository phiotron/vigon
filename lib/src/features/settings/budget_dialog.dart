import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/money.dart';
import '../../providers.dart';
import '../entry/keypad.dart' show minorUnitsToInput;

/// Đặt hoặc bỏ hạn mức chi mỗi tháng (AC-26).
Future<void> showBudgetDialog(BuildContext context, WidgetRef ref) async {
  final digits = currencyDecimalDigits(
    ref.read(currencyProvider).value ?? 'VND',
  );
  final current = ref.read(budgetProvider).value;
  final result = await showDialog<(int?,)>(
    context: context,
    builder: (context) => _BudgetDialog(current: current, digits: digits),
  );
  if (result != null) {
    await ref.read(settingsRepositoryProvider).setBudget(result.$1);
  }
}

/// Hộp thoại tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.current, required this.digits});

  final int? current;
  final int digits;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : minorUnitsToInput(widget.current!, widget.digits),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final v = evaluateToMinorUnits(
      _controller.text.trim().replaceAll(',', '.'),
      decimalDigits: widget.digits,
    );
    if (v == null || v <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    Navigator.pop(context, (v,));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.budget),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(errorText: _error),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.pop(context, (null,)),
            child: Text(l.budgetRemove),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
