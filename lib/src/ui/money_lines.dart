import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers.dart';
import 'format.dart';
import 'tokens.g.dart';

/// Số tiền theo **Tiền tệ chính to ở trên**, số gốc nhỏ ở dưới (D-042,
/// AC-146).
///
/// Cùng tiền tệ thì chỉ một dòng. Thiếu tỷ giá thì dòng trên là số gốc và dòng
/// dưới ghi chú "Thiếu tỷ giá" thay vì đoán số.
class MoneyLines extends ConsumerWidget {
  const MoneyLines({
    super.key,
    required this.amount,
    required this.currency,
    this.primaryAmount,
    this.style,
    this.secondaryStyle,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.compact = false,
  });

  /// Số gốc, đơn vị nhỏ nhất của [currency].
  final int amount;
  final String currency;

  /// Số theo Tiền tệ chính đã tính sẵn chính xác (vd số dư cộng gốc rồi quy
  /// đổi một lần, AC-148); null thì quy đổi [amount] tại tỷ giá hiện tại.
  final int? primaryAmount;
  final TextStyle? style;
  final TextStyle? secondaryStyle;
  final TextAlign? textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  /// Chỉ hiện dòng trên; dùng trong dòng chật.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = moneyLinesText(
      context,
      ref,
      amount,
      currency,
      primaryAmount: primaryAmount,
    );
    final main = Text(lines.main, style: style, textAlign: textAlign);
    if (lines.secondary == null || compact) return main;
    final scheme = Theme.of(context).colorScheme;
    final secondary = (secondaryStyle ?? VgType.bodySm).copyWith(
      color: lines.missingRate ? scheme.error : scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        Text(lines.secondary!, style: secondary, textAlign: textAlign),
      ],
    );
  }
}

/// Chữ hai dòng của một số tiền (D-042): [main] theo Tiền tệ chính (hoặc số
/// gốc khi thiếu tỷ giá), [secondary] là số gốc / ghi chú thiếu tỷ giá, null
/// khi cùng tiền tệ.
typedef MoneyLinesText = ({String main, String? secondary, bool missingRate});

MoneyLinesText moneyLinesText(
  BuildContext context,
  WidgetRef ref,
  int amount,
  String currency, {
  int? primaryAmount,
}) {
  final primary = ref.watch(currencyProvider).value ?? 'USD';
  final original = money(context, currency, amount);
  if (currency == primary) {
    return (main: original, secondary: null, missingRate: false);
  }
  final converted =
      primaryAmount ??
      ref.watch(currencyServiceProvider).value?.toPrimary(amount, currency);
  if (converted == null) {
    final l = AppLocalizations.of(context);
    return (
      main: original,
      secondary: l.rateMissing(currency, primary),
      missingRate: true,
    );
  }
  return (
    main: money(context, primary, converted),
    secondary: original,
    missingRate: false,
  );
}

/// Chữ một dòng "chính · gốc" cho SnackBar, ngữ nghĩa, thông báo.
String moneyOneLine(
  BuildContext context,
  WidgetRef ref,
  int amount,
  String currency, {
  int? primaryAmount,
}) {
  final t = moneyLinesText(
    context,
    ref,
    amount,
    currency,
    primaryAmount: primaryAmount,
  );
  return t.secondary == null || t.missingRate
      ? t.main
      : '${t.main} (${t.secondary})';
}
