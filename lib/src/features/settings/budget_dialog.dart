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
  final l = AppLocalizations.of(context);
  final digits = currencyDecimalDigits(
    ref.read(currencyProvider).value ?? 'VND',
  );
  final current = ref.read(budgetProvider).value;
  final controller = TextEditingController(
    text: current == null ? '' : minorUnitsToInput(current, digits),
  );
  String? error;
  final result = await showDialog<(int?,)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.budget),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(errorText: error),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, (null,)),
              child: Text(l.budgetRemove),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = evaluateToMinorUnits(
                controller.text.trim().replaceAll(',', '.'),
                decimalDigits: digits,
              );
              if (v == null || v <= 0) {
                setState(() => error = l.amountMustBePositive);
                return;
              }
              Navigator.pop(context, (v,));
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (result != null) {
    await ref.read(settingsRepositoryProvider).setBudget(result.$1);
  }
}
