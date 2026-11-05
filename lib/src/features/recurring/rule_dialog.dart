import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../ui/tokens.g.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
import '../entry/keypad.dart' show minorUnitsToInput;

/// Kết quả hộp thoại sửa chuỗi định kỳ (AC-25, AC-50).
class RuleEdit {
  const RuleEdit({
    required this.amount,
    required this.note,
    required this.frequency,
    required this.categoryId,
    required this.accountId,
  });

  final int amount;
  final String? note;
  final RecurrenceFrequency frequency;

  /// Null với chuỗi chuyển tiền (không có danh mục).
  final int? categoryId;
  final int accountId;
}

/// Hộp thoại sửa chuỗi định kỳ: số tiền, ghi chú, tần suất, danh mục, tài khoản.
/// Tự giữ ô nhập để giải phóng đúng lúc, sau hiệu ứng đóng.
class RuleDialog extends StatefulWidget {
  const RuleDialog({
    super.key,
    required this.rule,
    required this.digits,
    this.symbol = '',
    required this.categories,
    required this.accounts,
  });

  final RecurringRule rule;
  final int digits;

  /// Ký hiệu tiền tệ cuối ô số tiền (7.2).
  final String symbol;

  /// Danh mục cùng loại thu/chi với chuỗi; rỗng với chuỗi chuyển tiền.
  final List<Category> categories;

  /// Tài khoản đang hiện.
  final List<Account> accounts;

  @override
  State<RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<RuleDialog> {
  late final _amount = TextEditingController(
    text: minorUnitsToInput(widget.rule.amount, widget.digits),
  );
  late final _note = TextEditingController(text: widget.rule.note ?? '');
  late RecurrenceFrequency _frequency = widget.rule.frequency;
  late int? _categoryId = widget.rule.categoryId;
  late int _accountId = widget.rule.accountId;
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
    Navigator.pop(
      context,
      RuleEdit(
        amount: v,
        note: n.isEmpty ? null : n,
        frequency: _frequency,
        categoryId: _categoryId,
        accountId: _accountId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Chuyển tiền: tài khoản nguồn không được trùng tài khoản nhận.
    final accounts = [
      for (final a in widget.accounts)
        if (a.id != widget.rule.toAccountId) a,
    ];
    final categories = widget.categories;
    // Ô chọn (`.vg-field`): mũi tên Material Symbols, cách nhau 16.
    const gap = SizedBox(height: VgSpace.s4);
    const arrow = Icon(Symbols.arrow_drop_down_rounded);
    // Sửa chuỗi (7.2): Số tiền tự focus, ghi chú áp dụng cho các lần sinh sau;
    // bản 1.1 thêm tần suất, danh mục, tài khoản (AC-50).
    return AlertDialog(
      title: Text(l.recurring),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: VgSpace.s2),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: l.amountLabel,
              suffixText: widget.symbol.isEmpty ? null : widget.symbol,
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
          gap,
          DropdownButtonFormField<RecurrenceFrequency>(
            key: const Key('rule-frequency'),
            initialValue: _frequency,
            isExpanded: true,
            icon: arrow,
            decoration: InputDecoration(labelText: l.repeat),
            items: [
              for (final f in RecurrenceFrequency.values)
                DropdownMenuItem(value: f, child: Text(repeatLabel(l, f))),
            ],
            onChanged: (f) => setState(() => _frequency = f ?? _frequency),
          ),
          if (categories.isNotEmpty && _categoryId != null) ...[
            gap,
            DropdownButtonFormField<int>(
              key: const Key('rule-category'),
              initialValue: categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              isExpanded: true,
              icon: arrow,
              decoration: InputDecoration(labelText: l.categories),
              items: [
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      categoryLabel(l, c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) =>
                  setState(() => _categoryId = id ?? _categoryId),
            ),
          ],
          if (accounts.length > 1) ...[
            gap,
            DropdownButtonFormField<int>(
              key: const Key('rule-account'),
              // Tài khoản hiện tại đã ẩn thì để trống, giữ nguyên tới khi chọn lại.
              initialValue: accounts.any((a) => a.id == _accountId)
                  ? _accountId
                  : null,
              isExpanded: true,
              icon: arrow,
              decoration: InputDecoration(labelText: l.account),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(
                      accountLabel(l, a),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => _accountId = id ?? _accountId),
            ),
          ],
        ],
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
