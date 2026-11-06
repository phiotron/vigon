import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/money.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/dialog.dart';

/// Ký hiệu tiền tệ, ví dụ "₫"; không có ký hiệu riêng thì là chính mã.
String currencySymbol(String code) =>
    NumberFormat.simpleCurrency(name: code).currencySymbol;

/// Đặt hoặc bỏ hạn mức chi mỗi tháng (AC-26), theo 5.3 và 5.4: ô Số tiền tự
/// focus, lỗi ngay dưới ô; Bỏ ngân sách (khi đang đặt), Hủy, Lưu.
Future<void> showBudgetDialog(BuildContext context, WidgetRef ref) async {
  final currency = ref.read(currencyProvider).value ?? 'USD';
  final current = ref.read(budgetProvider).value;
  final result = await showDialog<(int?,)>(
    context: context,
    builder: (context) => _BudgetDialog(
      current: current,
      digits: currencyDecimalDigits(currency),
      symbol: currencySymbol(currency),
    ),
  );
  if (result != null) {
    await ref.read(settingsRepositoryProvider).setBudget(result.$1);
  }
}

/// Hộp thoại tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.current,
    required this.digits,
    required this.symbol,
  });

  final int? current;
  final int digits;
  final String symbol;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : amountInput(context, widget.current!, widget.digits),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final v = parseAmountField(context, _controller.text.trim(), widget.digits);
    if (v == null || v <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    Navigator.pop(context, (v,));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 5.3/5.4 (P2): thân cuộn, nút ghim khi chữ lớn; ô 56 theo theme.
    return VgDialog(
      title: l.budget,
      content: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l.amountLabel,
            suffixText: widget.symbol,
            errorText: _error,
            errorMaxLines: 3,
          ),
        ),
      ],
      actions: [
        if (widget.current != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, (null,)),
            child: Text(l.budgetRemove),
          ),
        VgDialog.cancelButton(context),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
