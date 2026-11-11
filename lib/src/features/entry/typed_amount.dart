import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/money.dart';
import '../../data/rate_repository.dart';
import '../../ui/format.dart';
import '../settings/currency_picker.dart';

/// Quy [amount] (đơn vị nhỏ nhất của [from]) sang [to] làm tròn **xuống**
/// sao cho quy ngược về [from] không vượt [amount] (D-048: "Điền đủ" / "Trả
/// hết" theo tiền tệ đang gõ không bao giờ vượt giới hạn). Cùng tiền tệ thì
/// giữ nguyên; thiếu tỷ giá thì null.
int? convertDown(CurrencyService service, int amount, String from, String to) {
  if (from == to || amount <= 0) return amount;
  var c = service.convert(amount, from, to);
  if (c == null) return null;
  for (var i = 0; c! > 0 && i < 100000; i++) {
    final back = service.convert(c, to, from);
    if (back == null) return null;
    if (back <= amount) break;
    c--;
  }
  return c;
}

/// Ô số tiền theo tiền tệ đang gõ (AC-167): mặc định Tiền tệ chính, đổi bằng
/// chip; đổi chip giữ nguyên con số đã gõ (AC-168, `rescaleMinorUnits`).
/// "Điền đủ" nhớ số chính xác ở tiền tệ đích để lưu đúng tới đơn vị nhỏ nhất
/// khi người dùng không sửa số.
class TypedAmount {
  TypedAmount(this.currency);

  final controller = TextEditingController();
  String currency;

  /// Số chính xác theo tiền tệ đích của lần "Điền đủ" gần nhất, kèm chữ đã
  /// điền; người dùng sửa chữ thì bỏ.
  ({String text, int exact})? _fill;

  void dispose() => controller.dispose();

  /// Số đã gõ theo [currency]; null khi trống hoặc sai.
  int? value(BuildContext context) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return parseAmountField(context, text, currencyDecimalDigits(currency));
  }

  /// Số đã gõ quy sang [target] (half-up); "Điền đủ" chưa sửa thì đúng số
  /// chính xác đã điền.
  int? valueIn(
    BuildContext context,
    CurrencyService service,
    String target, {
    String? fillTarget,
  }) {
    final fill = _fill;
    if (fill != null &&
        fill.text == controller.text &&
        (fillTarget ?? target) == target) {
      return fill.exact;
    }
    final typed = value(context);
    if (typed == null) return null;
    return service.convert(typed, currency, target);
  }

  /// Điền [exact] (theo [target]) quy về tiền tệ đang gõ, làm tròn xuống.
  void fill(
    BuildContext context,
    CurrencyService service,
    int exact,
    String target,
  ) {
    final typed = convertDown(service, exact, target, currency) ?? 0;
    controller.text = amountInput(
      context,
      typed,
      currencyDecimalDigits(currency),
    );
    _fill = (text: controller.text, exact: exact);
  }

  /// Đổi tiền tệ đang gõ, giữ con số (AC-168).
  void switchTo(BuildContext context, String next) {
    if (next == currency) return;
    final oldDigits = currencyDecimalDigits(currency);
    final newDigits = currencyDecimalDigits(next);
    final typed = value(context);
    currency = next;
    _fill = null;
    if (typed != null) {
      controller.text = amountInput(
        context,
        rescaleMinorUnits(typed, oldDigits, newDigits),
        newDigits,
      );
    }
  }
}

/// Chip tiền tệ cạnh ô số tiền (AC-167): chạm mở bộ chọn tiền tệ (AC-147).
class TypedCurrencyChip extends StatelessWidget {
  const TypedCurrencyChip({
    super.key,
    required this.currency,
    required this.onPicked,
  });

  final String currency;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Tooltip(
      message: l.currencyChipTooltip(currency),
      child: ActionChip(
        avatar: const Icon(Symbols.currency_exchange_rounded, size: 18),
        label: Text(currency),
        onPressed: () async {
          final picked = await showCurrencyPicker(context, currency);
          if (picked != null) onPicked(picked);
        },
      ),
    );
  }
}
