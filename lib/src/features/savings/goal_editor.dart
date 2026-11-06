import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../data/savings_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import 'savings_providers.dart';

/// Id giả cho lựa chọn "Tạo tài khoản mới" trong bảng chọn tài khoản (id thật
/// của tài khoản bắt đầu từ 1).
const _newAccount = 0;

/// Thêm hoặc sửa mục tiêu tiết kiệm (AC-100): tên ≤ 50, số tiền > 0, hạn tuỳ
/// chọn, tài khoản gắn (chọn tài khoản chưa gắn mục tiêu khác hoặc tạo mới).
Future<void> showGoalEditor(BuildContext context, {SavingsGoal? goal}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _GoalEditor(goal: goal),
      ),
    );

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.goal});

  final SavingsGoal? goal;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  String? _nameError;
  String? _targetError;
  String? _accountError;
  DateTime? _due;
  int _accountId = _newAccount;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = widget.goal;
    if (g != null && _name.text.isEmpty) {
      _name.text = g.name;
      final digits = currencyDecimalDigits(
        ref.read(currencyProvider).value ?? 'USD',
      );
      _target.text = amountInput(context, g.targetAmount, digits);
      _due = g.dueDate == null ? null : parseDateKey(g.dueDate!);
      _accountId = g.accountId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? today,
      firstDate: _due != null && _due!.isBefore(DateTime(2000))
          ? _due!
          : DateTime(2000),
      lastDate: DateTime(today.year + 30),
    );
    if (picked != null) setState(() => _due = dateOnly(picked));
  }

  /// Tài khoản chọn được khi tạo: tài khoản hiện chưa gắn mục tiêu nào (AC-100).
  Future<void> _pickAccount(Set<int> linked, List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final picked = await showChoiceSheet<int>(
      context,
      title: l.savingsAccount,
      selected: _accountId,
      options: [
        ChoiceOption(
          _newAccount,
          l.savingsNewAccount,
          icon: Symbols.add_circle_rounded,
        ),
        for (final a in accounts)
          if (!linked.contains(a.id))
            ChoiceOption(
              a.id,
              accountLabel(l, a),
              icon: Symbols.account_balance_wallet_rounded,
            ),
      ],
    );
    if (picked != null) {
      setState(() {
        _accountId = picked.$1;
        _accountError = null;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'USD',
    );
    final text = _target.text.trim();
    final amount = text.isEmpty
        ? null
        : parseAmountField(context, text, digits);
    setState(() {
      _nameError = name.isEmpty ? l.nameRequired : null;
      _targetError = amount == null
          ? (text.isEmpty ? l.amountMustBePositive : l.invalidExpression)
          : (amount <= 0 ? l.amountMustBePositive : null);
    });
    if (_nameError != null || amount == null || amount <= 0) return;
    _saving = true;
    final repo = ref.read(savingsRepositoryProvider);
    final dueKey = _due == null ? null : dateKey(_due!);
    try {
      final g = widget.goal;
      if (g != null) {
        await repo.edit(
          g.id,
          name: name,
          targetAmount: amount,
          dueDate: dueKey,
        );
      } else if (_accountId == _newAccount) {
        await repo.addWithNewAccount(
          name: name,
          targetAmount: amount,
          dueDate: dueKey,
        );
      } else {
        await repo.add(
          name: name,
          targetAmount: amount,
          accountId: _accountId,
          dueDate: dueKey,
        );
      }
    } on AccountHasGoalException {
      // Tài khoản vừa bị mục tiêu khác chiếm (hiếm): báo rồi cho chọn lại.
      _saving = false;
      if (mounted) {
        setState(() {
          _accountId = _newAccount;
          _accountError = l.savingsAccountTaken;
        });
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.delete_rounded,
      title: l.savingsDeleteTitle,
      body: l.savingsDeleteBody,
      action: l.delete,
      style: ConfirmStyle.danger,
    );
    if (!ok || !mounted) return;
    await ref.read(savingsRepositoryProvider).delete(widget.goal!.id);
    if (!mounted) return;
    Navigator.pop(context);
    showMessage(l.savingsDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final goal = widget.goal;
    final visible = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? visible;
    final linked = <int>{
      for (final g in ref.watch(savingsGoalsProvider).value ?? const [])
        g.accountId,
    };
    final accountName = _accountId == _newAccount
        ? l.savingsNewAccount
        : all
                  .where((a) => a.id == _accountId)
                  .map((a) => accountLabel(l, a))
                  .firstOrNull ??
              '';
    final hint = goal != null
        ? l.savingsAccountFixed
        : (_accountId == _newAccount ? l.savingsNewAccountNote : '');
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(goal == null ? l.savingsAdd : l.savingsEdit),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s2,
                      VgSpace.s4,
                      0,
                    ),
                    child: TextField(
                      controller: _name,
                      maxLength: 50,
                      autofocus: goal == null,
                      decoration: InputDecoration(
                        labelText: l.name,
                        errorText: _nameError,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s2,
                      VgSpace.s4,
                      0,
                    ),
                    child: TextField(
                      controller: _target,
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
                        labelText: l.savingsTarget,
                        suffixText: currencySymbol(currency),
                        errorText: _targetError,
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s3,
                      VgSpace.s4,
                      0,
                    ),
                    child: Wrap(
                      spacing: VgSpace.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_due == null)
                          ActionChip(
                            avatar: const Icon(Symbols.event_rounded, size: 18),
                            label: Text(l.savingsDue),
                            onPressed: _pickDue,
                          )
                        else
                          InputChip(
                            avatar: const Icon(Symbols.event_rounded, size: 18),
                            label: Text(shortDate(context, _due!)),
                            onPressed: _pickDue,
                            deleteButtonTooltipMessage: l.savingsClearDue,
                            onDeleted: () => setState(() => _due = null),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s3,
                      VgSpace.s4,
                      0,
                    ),
                    child: goal == null
                        ? _AccountField(
                            label: l.savingsAccount,
                            value: accountName,
                            error: _accountError,
                            onTap: () => _pickAccount(linked, visible),
                          )
                        : _AccountField(
                            label: l.savingsAccount,
                            value: accountName,
                          ),
                  ),
                  if (hint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s4,
                        VgSpace.s2,
                        VgSpace.s4,
                        0,
                      ),
                      child: VgHint(hint),
                    ),
                  if (goal != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s4,
                        VgSpace.s3,
                        VgSpace.s4,
                        0,
                      ),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                          minimumSize: const Size(0, VgSize.tapMin),
                        ),
                        icon: const Icon(Symbols.delete_rounded),
                        label: Text(l.savingsDelete),
                        onPressed: _delete,
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                ],
              ),
            ),
          ),
          SheetFooter(
            border: false,
            children: [
              FilledButton(
                style: sheetFilledButtonStyle(),
                onPressed: _save,
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ô chỉ đọc có mũi tên ▾ để mở bảng chọn tài khoản; [onTap] null = không đổi
/// được (khi sửa).
class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.label,
    required this.value,
    this.error,
    this.onTap,
  });

  final String label;
  final String value;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final field = InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        enabled: onTap != null,
        suffixIcon: onTap == null
            ? null
            : const Icon(Symbols.arrow_drop_down_rounded),
      ),
      child: Text(
        value,
        style: VgType.bodyMd.copyWith(
          color: onTap == null ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
    if (onTap == null) return field;
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(VgRadius.sm),
        onTap: onTap,
        child: field,
      ),
    );
  }
}
