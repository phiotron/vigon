import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/recurring_repository.dart';
import '../../l10n_names.dart';
import '../../ui/category_avatar.dart';
import '../../ui/category_grid.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/settings_rows.dart' show PillTone, StatusPill;
import '../../ui/tokens.g.dart';
import '../accounts/accounts_screen.dart' show accountIcon;
import '../categories/sheet_footer.dart';
import '../entry/entry_editor_screen.dart' show repeatLabel;
import '../entry/keypad.dart' show minorUnitsToInput;

/// Kết quả bảng sửa chuỗi định kỳ (AC-25, AC-50).
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

/// Mở bảng sửa chuỗi định kỳ toàn màn (SCR-21, thay hộp thoại 7.2). Trả về
/// [RuleEdit] khi Lưu, null khi Hủy / ✕ / vuốt xuống.
Future<RuleEdit?> showRuleSheet(
  BuildContext context, {
  required RecurringRule rule,
  required int digits,
  String symbol = '',
  required List<Category> categories,
  required List<Account> accounts,
}) => showModalBottomSheet<RuleEdit>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => RuleSheet(
    rule: rule,
    digits: digits,
    symbol: symbol,
    categories: categories,
    accounts: accounts,
  ),
);

/// Bảng sửa chuỗi định kỳ (SCR-21): thanh ✕ + tiêu đề; đầu chuỗi chỉ đọc
/// (danh mục · ngày tới hạn / Đã dừng); Số tiền, Ghi chú, Lặp lại (4 chip chọn
/// một), gợi ý bắt đầu lại khi đổi tần suất (A12), ô chọn Danh mục và Tài
/// khoản (chỉ khi có > 1 tài khoản hiện); Hủy / Lưu ghim ở đáy.
class RuleSheet extends StatefulWidget {
  const RuleSheet({
    super.key,
    required this.rule,
    required this.digits,
    this.symbol = '',
    required this.categories,
    required this.accounts,
  });

  final RecurringRule rule;
  final int digits;

  /// Ký hiệu tiền tệ cuối ô số tiền.
  final String symbol;

  /// Danh mục cùng loại thu/chi với chuỗi; rỗng với chuỗi chuyển tiền.
  final List<Category> categories;

  /// Tài khoản đang hiện.
  final List<Account> accounts;

  @override
  State<RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<RuleSheet> {
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

  Category? _category(int? id) {
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _pickCategory() async {
    final type = widget.rule.type == EntryType.income
        ? CategoryType.income
        : CategoryType.expense;
    final id = await showCategorySheet(
      context,
      type: type,
      selectedId: _categoryId,
    );
    if (id != null && mounted) setState(() => _categoryId = id);
  }

  Future<void> _pickAccount(List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final picked = await showChoiceSheet<int>(
      context,
      title: l.account,
      selected: _accountId,
      options: [
        for (final a in accounts)
          ChoiceOption(a.id, accountLabel(l, a), icon: accountIcon(a)),
      ],
    );
    if (picked != null && mounted) setState(() => _accountId = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rule = widget.rule;
    // Chuyển tiền: tài khoản nguồn không được trùng tài khoản nhận.
    final accounts = [
      for (final a in widget.accounts)
        if (a.id != rule.toAccountId) a,
    ];
    final original = _category(rule.categoryId);
    final selectedCategory = _category(_categoryId);
    Account? selectedAccount;
    for (final a in accounts) {
      if (a.id == _accountId) selectedAccount = a;
    }
    final nextDue = shortDate(context, RecurringRepository.nextDate(rule));
    final status = rule.active
        ? '${repeatLabel(l, rule.frequency)} · $nextDue'
        : l.repeatStopped;
    final note = rule.note?.trim() ?? '';
    final seriesName = note.isNotEmpty
        ? note
        : original != null
        ? categoryLabel(l, original)
        : l.transfer;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh trên (`.sbar`): ✕ = Hủy (iOS cần lối đóng thấy được).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s1,
                VgSpace.s1,
                VgSpace.s2,
                VgSpace.s1,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Symbols.close_rounded),
                    tooltip: l.cancel,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: VgSpace.s1),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l.recurring,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Đầu chuỗi chỉ đọc (`.vg-series`).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s1,
                VgSpace.s4,
                VgSpace.s4,
              ),
              child: Row(
                children: [
                  if (original != null)
                    CategoryAvatar(category: original, size: 40)
                  else
                    SizedBox(
                      width: 40,
                      child: Icon(
                        Symbols.event_repeat_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: VgSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seriesName,
                          style: VgType.titleSm.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          status,
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!rule.active)
                    StatusPill(
                      icon: Symbols.stop_circle_rounded,
                      label: l.repeatStopped,
                      tone: PillTone.lock,
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4,
                  VgSpace.s2,
                  VgSpace.s4,
                  VgSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('rule-amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        labelText: l.amountLabel,
                        suffixText: widget.symbol.isEmpty
                            ? null
                            : widget.symbol,
                        errorText: _error,
                        errorMaxLines: 3,
                      ),
                    ),
                    const SizedBox(height: VgSpace.s4 + VgSpace.s1),
                    TextField(
                      controller: _note,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: l.noteHint,
                        helperText: l.recurringEditNote,
                        // 200%: gợi ý cạnh bộ đếm cần 4–5 dòng, không cắt "…".
                        helperMaxLines: 6,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: VgSpace.s4 + VgSpace.s1,
                        bottom: VgSpace.s2,
                      ),
                      child: Text(
                        l.repeat,
                        style: VgType.labelMd.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Semantics(
                      key: const Key('rule-frequency'),
                      label: l.repeat,
                      container: true,
                      child: Wrap(
                        spacing: VgSpace.s2,
                        runSpacing: VgSpace.s2,
                        children: [
                          for (final f in RecurrenceFrequency.values)
                            _FrequencyChip(
                              key: ValueKey('rule-frequency-${f.name}'),
                              label: repeatLabel(l, f),
                              selected: f == _frequency,
                              onTap: () => setState(() => _frequency = f),
                            ),
                        ],
                      ),
                    ),
                    // A12: đổi tần suất thì chuỗi bắt đầu lại từ ngày tới hạn
                    // kế tiếp theo lịch cũ (AC-50).
                    if (_frequency != rule.frequency)
                      VgHint(
                        l.recurringRestartHint(nextDue),
                        icon: Symbols.restart_alt_rounded,
                        padding: const EdgeInsets.only(top: 6),
                      ),
                    if (widget.categories.isNotEmpty &&
                        _categoryId != null) ...[
                      const SizedBox(height: VgSpace.s6),
                      _PickerField(
                        key: const Key('rule-category'),
                        label: l.categories,
                        leading: selectedCategory == null
                            ? null
                            : CategoryAvatar(
                                category: selectedCategory,
                                size: 32,
                              ),
                        value: selectedCategory == null
                            ? ''
                            : categoryLabel(l, selectedCategory),
                        onTap: _pickCategory,
                      ),
                    ],
                    if (accounts.length > 1) ...[
                      const SizedBox(height: VgSpace.s4),
                      _PickerField(
                        key: const Key('rule-account'),
                        label: l.account,
                        // Tài khoản hiện tại đã ẩn thì để trống, giữ nguyên
                        // tới khi chọn lại.
                        leading: selectedAccount == null
                            ? null
                            : SizedBox(
                                width: 32,
                                child: Icon(
                                  accountIcon(selectedAccount),
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                        value: selectedAccount == null
                            ? ''
                            : accountLabel(l, selectedAccount),
                        onTap: () => _pickAccount(accounts),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SheetFooter(
              children: [
                OutlinedButton(
                  style: sheetOutlinedButtonStyle(),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  style: sheetFilledButtonStyle(),
                  onPressed: _save,
                  child: Text(l.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip chọn một (`.vg-choice > span`): cao tối thiểu 40 trong vùng chạm 48,
/// bo `radius-sm`, viền `outline`; đang chọn nền `secondary-container` + ✓.
class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VgRadius.sm),
      side: selected ? BorderSide.none : BorderSide(color: scheme.outline),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VgSize.tapMin),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: selected ? VgSpace.s2 : VgSpace.s4,
                    end: VgSpace.s4,
                    top: VgSpace.s1,
                    bottom: VgSpace.s1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        Icon(Symbols.check_rounded, size: 18, color: fg),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: VgType.labelMd.copyWith(color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô chọn (`.vg-pickrow`): viền như ô nhập, nhãn nổi, icon đầu 32, tên,
/// mũi tên ▾; chạm mở bảng chọn có sẵn (07 danh mục / 08 tài khoản).
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String value;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(VgRadius.sm),
        onTap: onTap,
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsetsDirectional.only(
              start: VgSpace.s3,
              end: VgSpace.s2,
              top: VgSpace.s3,
              bottom: VgSpace.s3,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: VgSpace.s3),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                ),
              ),
              Icon(
                Symbols.arrow_drop_down_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
