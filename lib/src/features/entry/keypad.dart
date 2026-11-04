import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';

const keyBackspace = '⌫';
const keyEquals = '=';

/// Bàn phím số riêng của app có cộng trừ nhân chia (AC-01, AC-03), theo
/// T2_BanPhim: lưới 4 cột, phím 56, cách 8; phím phép tính nền
/// `secondary-container`; nút Lưu chiếm 3 cột. Tiền không có phần lẻ (VND)
/// thì nút "." thành "000".
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.decimalDigits,
    required this.onKey,
    required this.saveLabel,
    required this.saveColor,
    required this.saveForeground,
    required this.onSave,
  });

  final int decimalDigits;
  final ValueChanged<String> onKey;
  final String saveLabel;
  final Color saveColor;
  final Color saveForeground;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final extra = decimalDigits == 0 ? '000' : '.';
    final rows = [
      ['7', '8', '9', opDiv],
      ['4', '5', '6', opMul],
      ['1', '2', '3', opSub],
      [extra, '0', keyBackspace, opAdd],
    ];

    Widget key(String k, double width) {
      final op = isOperator(k) || k == keyEquals;
      return SizedBox(
        width: width,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(VgSize.tapKey),
            padding: EdgeInsets.zero,
            backgroundColor: op
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHigh,
            foregroundColor: op
                ? scheme.onSecondaryContainer
                : scheme.onSurface,
            textStyle: VgType.keyDigit,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VgRadius.md),
            ),
          ),
          onPressed: () => onKey(k),
          child: switch (k) {
            keyBackspace => Icon(
              Symbols.backspace_rounded,
              semanticLabel: l.keypadBackspace,
            ),
            keyEquals => Text(k, semanticsLabel: l.keypadEquals),
            _ => Text(k),
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s3,
        VgSpace.s2,
        VgSpace.s3,
        VgSpace.s1,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 4 cột bằng nhau cách 8; nút Lưu rộng đúng 3 cột cộng 2 khoảng cách
          // để thẳng hàng với các phím phía trên.
          const gap = VgSpace.s2;
          final w = (constraints.maxWidth - 3 * gap) / 4;
          Widget row(List<Widget> children) => Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                children[i],
              ],
            ],
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final r in rows) ...[
                row([for (final k in r) key(k, w)]),
                const SizedBox(height: gap),
              ],
              row([
                key(keyEquals, w),
                SizedBox(
                  width: 3 * w + 2 * gap,
                  child: FilledButton(
                    style: bigButtonStyle(
                      background: saveColor,
                      foreground: saveForeground,
                    ),
                    onPressed: onSave,
                    child: Text(saveLabel),
                  ),
                ),
              ]),
            ],
          );
        },
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
