import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers.dart';
import 'format.dart';
import 'tokens.g.dart';

/// Số tiền gốc + dòng "≈ Tiền tệ chính" bên dưới (D-037), như A001.
///
/// Số gốc luôn đứng trên, đúng tiền tệ người dùng đã nhập; dòng dưới chỉ là
/// cách nhìn theo Tiền tệ chính. Cặp thiếu tỷ giá thì ghi chú thay vì đoán số.
class MoneyLines extends ConsumerWidget {
  const MoneyLines({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.secondaryStyle,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.compact = false,
  });

  /// Số gốc, đơn vị nhỏ nhất của [currency].
  final int amount;
  final String currency;
  final TextStyle? style;
  final TextStyle? secondaryStyle;
  final TextAlign? textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  /// Chỉ hiện dòng quy đổi khi khác tiền tệ; dùng trong dòng chật.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final service = ref.watch(currencyServiceProvider).value;
    final original = Text(
      money(context, currency, amount),
      style: style,
      textAlign: textAlign,
    );
    if (currency == primary) return original;
    final converted = service?.toPrimary(amount, currency);
    final scheme = Theme.of(context).colorScheme;
    final secondary = (secondaryStyle ?? VgType.bodySm).copyWith(
      color: converted == null ? scheme.error : scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        original,
        if (!compact)
          Text(
            converted == null
                ? l.rateMissing(currency, primary)
                : '≈ ${money(context, primary, converted)}',
            style: secondary,
            textAlign: textAlign,
          ),
      ],
    );
  }
}

/// Chuỗi "≈ …" của [amount] theo Tiền tệ chính, hoặc null khi cùng tiền tệ.
/// Nơi cần một chuỗi (SnackBar, ngữ nghĩa) dùng hàm này.
String? approxMoneyText(
  BuildContext context,
  WidgetRef ref,
  int amount,
  String currency,
) {
  final primary = ref.watch(currencyProvider).value ?? 'USD';
  if (currency == primary) return null;
  final converted = ref
      .watch(currencyServiceProvider)
      .value
      ?.toPrimary(amount, currency);
  if (converted == null) return null;
  return '≈ ${money(context, primary, converted)}';
}
