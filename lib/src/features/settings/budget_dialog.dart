import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/money.dart';
import '../../data/rate_repository.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/dialog.dart';
import '../../ui/hint.dart';
import '../../ui/tokens.g.dart';
import 'currency_picker.dart';

/// Ký hiệu tiền tệ, ví dụ "₫"; không có ký hiệu riêng thì là chính mã.
String currencySymbol(String code) =>
    NumberFormat.simpleCurrency(name: code).currencySymbol;

/// Đặt hoặc bỏ hạn mức chi mỗi tháng (AC-26), theo 5.3 và 5.4: ô Số tiền tự
/// focus, lỗi ngay dưới ô; Bỏ ngân sách (khi đang đặt), Hủy, Lưu. Ngân sách
/// có tiền tệ riêng (D-037): đổi tiền tệ thì quy đổi số theo tỉ giá hiện tại.
Future<void> showBudgetDialog(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final settings = ref.read(settingsRepositoryProvider);
  final primary = ref.read(currencyProvider).value ?? 'USD';
  final derived = await settings.readBudget();
  final original = await settings.readBudgetOriginal();
  final currency = await settings.readBudgetCurrency() ?? primary;
  final service = await ref.read(currencyServiceProvider.future);
  if (!context.mounted) return;
  final result = await showDialog<(int?, String)>(
    context: context,
    builder: (context) => _BudgetDialog(
      current: original ?? derived,
      currency: currency,
      primary: primary,
      service: service,
    ),
  );
  if (result == null) return;
  final (amount, picked) = result;
  if (amount == null) {
    await settings.setBudget(null);
    await settings.setBudgetOriginal(null);
    await settings.setBudgetCurrency(null);
    return;
  }
  final derivedAmount = service.toPrimary(amount, picked);
  if (derivedAmount == null) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l.rateMissing(picked, primary))));
    }
    return;
  }
  await settings.setBudget(derivedAmount);
  await settings.setBudgetOriginal(amount);
  await settings.setBudgetCurrency(picked);
}

/// Hộp thoại tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.current,
    required this.currency,
    required this.primary,
    required this.service,
  });

  /// Số gốc đang đặt, đơn vị nhỏ nhất của [currency].
  final int? current;
  final String currency;
  final String primary;
  final CurrencyService service;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late String _currency = widget.currency;
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : amountInput(
            context,
            widget.current!,
            currencyDecimalDigits(widget.currency),
          ),
  );
  String? _error;

  int get _digits => currencyDecimalDigits(_currency);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Đổi tiền tệ ngân sách: quy đổi số đang nhập sang tiền tệ mới (Q14 A).
  Future<void> _pickCurrency() async {
    final l = AppLocalizations.of(context);
    final picked = await showCurrencyPicker(context, _currency);
    if (picked == null || picked == _currency || !mounted) return;
    final text = _controller.text.trim();
    final parsed = text.isEmpty ? 0 : parseAmountField(context, text, _digits);
    if (parsed == null) {
      setState(() => _error = l.invalidExpression);
      return;
    }
    final converted = widget.service.convert(parsed, _currency, picked);
    if (converted == null) {
      setState(() => _error = l.rateMissing(_currency, picked));
      return;
    }
    setState(() {
      _currency = picked;
      _controller.text = amountInput(
        context,
        converted,
        currencyDecimalDigits(picked),
      );
      _error = null;
    });
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final v = parseAmountField(context, _controller.text.trim(), _digits);
    if (v == null || v <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    Navigator.pop(context, (v, _currency));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final typed = parseAmountField(context, _controller.text.trim(), _digits);
    final converted = typed == null || _currency == widget.primary
        ? null
        : widget.service.toPrimary(typed, _currency);
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
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l.amountLabel,
            suffixText: currencySymbol(_currency),
            helperText: converted == null
                ? null
                : '≈ ${money(context, widget.primary, converted)}',
            errorText: _error,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: VgSpace.s3),
        InkWell(
          borderRadius: BorderRadius.circular(VgRadius.sm),
          onTap: _pickCurrency,
          child: InputDecorator(
            decoration: InputDecoration(labelText: l.currency),
            child: Row(
              children: [
                Expanded(child: Text(currencyCodeLabel(_currency))),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: VgSpace.s2),
        VgHint(l.primaryCurrencyNote),
      ],
      actions: [
        if (widget.current != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, (null, _currency)),
            child: Text(l.budgetRemove),
          ),
        VgDialog.cancelButton(context),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
