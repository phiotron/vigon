import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';

const keyBackspace = '⌫';
const keyEquals = '=';

/// Bàn phím số riêng của app có cộng trừ nhân chia (AC-01, AC-03).
/// Tiền không có phần lẻ (VND) thì nút "." thành "000".
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.decimalDigits,
    required this.onKey,
    required this.saveLabel,
    required this.saveColor,
    required this.onSave,
  });

  final int decimalDigits;
  final ValueChanged<String> onKey;
  final String saveLabel;
  final Color saveColor;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final extra = decimalDigits == 0 ? '000' : '.';
    final rows = [
      ['7', '8', '9', opDiv],
      ['4', '5', '6', opMul],
      ['1', '2', '3', opSub],
      [extra, '0', keyBackspace, opAdd],
    ];
    String? semantic(String key) => switch (key) {
      keyBackspace => l.keypadBackspace,
      keyEquals => l.keypadEquals,
      _ => null,
    };

    Widget key(String k, {Color? color}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor:
                color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => onKey(k),
          child: Text(
            k,
            semanticsLabel: semantic(k),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              children: [
                for (final k in row)
                  key(
                    k,
                    color: isOperator(k)
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                  ),
              ],
            ),
          Row(
            children: [
              key(
                keyEquals,
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: saveColor,
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onSave,
                    child: Text(
                      saveLabel,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Biểu thức mới sau khi bấm [key] trên bàn phím (AC-03).
/// "=" thay biểu thức bằng kết quả; bấm hai phép liền nhau thì phép sau thay phép trước.
String applyKeypadKey(
  String expression,
  String key, {
  required int decimalDigits,
}) {
  if (key == keyBackspace) {
    return expression.isEmpty
        ? expression
        : expression.substring(0, expression.length - 1);
  }
  if (key == keyEquals) {
    final v = evaluateToMinorUnits(expression, decimalDigits: decimalDigits);
    return v != null && v > 0
        ? minorUnitsToInput(v, decimalDigits)
        : expression;
  }
  if (isOperator(key)) {
    if (expression.isEmpty) return expression;
    final last = expression[expression.length - 1];
    return isOperator(last)
        ? expression.substring(0, expression.length - 1) + key
        : expression + key;
  }
  return expression.length < 30 ? expression + key : expression;
}

/// Đổi số tiền đơn vị nhỏ nhất thành chữ để sửa trên bàn phím, ví dụ 1250 cent → `12.5`.
String minorUnitsToInput(int minorUnits, int decimalDigits) {
  if (decimalDigits == 0) return '$minorUnits';
  final s = (minorUnits / BigInt.from(10).pow(decimalDigits).toInt())
      .toStringAsFixed(decimalDigits);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}
