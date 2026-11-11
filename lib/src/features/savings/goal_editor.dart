import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../reminder/deadline_reminders.dart';
import '../settings/exact_alarm_row.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import '../settings/currency_picker.dart';
import 'savings_providers.dart';

/// Thêm hoặc sửa mục tiêu tiết kiệm (F-47, AC-149): tên mục tiêu, tên ví
/// ("Tài khoản"), số tiền mục tiêu + tiền tệ (mặc định Tiền tệ chính), "Đã có
/// sẵn" (số dư ban đầu của ví), hạn tuỳ chọn. Tạo mới **luôn** tạo ví mới.
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
  final _account = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController();
  String? _nameError;
  String? _accountError;
  String? _targetError;
  String? _savedError;
  DateTime? _due;
  String? _currency;

  /// Ô tên ví còn theo tên mục tiêu (người dùng chưa tự sửa).
  bool _accountFollowsName = true;

  /// Ví đã có khoản → khoá tiền tệ (AC-149).
  bool _currencyLocked = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final g = widget.goal;
    if (g == null) return;
    _name.text = g.name;
    _currency = g.currency;
    _target.text = amountInput(
      context,
      g.originalTargetAmount ?? g.targetAmount,
      currencyDecimalDigits(g.currency),
    );
    _due = g.dueDate == null ? null : parseDateKey(g.dueDate!);
    _accountFollowsName = false;
    final l = AppLocalizations.of(context);
    final accounts = ref.read(allAccountsProvider).value ?? const <Account>[];
    final wallet = accounts.where((a) => a.id == g.accountId).firstOrNull;
    if (wallet != null) _account.text = accountLabel(l, wallet);
    ref.read(savingsRepositoryProvider).walletHasEntries(g.accountId).then((
      has,
    ) {
      if (mounted) setState(() => _currencyLocked = has);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _account.dispose();
    _target.dispose();
    _saved.dispose();
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

  Future<void> _pickCurrency() async {
    final primary = ref.read(currencyProvider).value ?? 'USD';
    final current = _currency ?? primary;
    final picked = await showCurrencyPicker(context, current);
    if (picked == null || picked == current || !mounted) return;
    // Giữ nguyên chữ số đã gõ, chỉ đổi số chữ số lẻ cho hợp tiền tệ mới.
    String reformat(TextEditingController c) {
      final text = c.text.trim();
      if (text.isEmpty) return text;
      final parsed = parseAmountField(
        context,
        text,
        currencyDecimalDigits(current),
      );
      return parsed == null
          ? text
          : amountInput(
              context,
              rescaleMinorUnits(
                parsed,
                currencyDecimalDigits(current),
                currencyDecimalDigits(picked),
              ),
              currencyDecimalDigits(picked),
            );
    }

    setState(() {
      _target.text = reformat(_target);
      _saved.text = reformat(_saved);
      _currency = picked;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    final accountName = _account.text.trim().isEmpty
        ? name
        : _account.text.trim();
    final primary = ref.read(currencyProvider).value ?? 'USD';
    final currency = _currency ?? primary;
    final digits = currencyDecimalDigits(currency);
    final text = _target.text.trim();
    final target = text.isEmpty
        ? null
        : parseAmountField(context, text, digits);
    final savedText = _saved.text.trim();
    final saved = savedText.isEmpty
        ? 0
        : parseAmountField(context, savedText, digits);
    setState(() {
      _nameError = name.isEmpty ? l.nameRequired : null;
      _accountError = null;
      _targetError = target == null
          ? (text.isEmpty ? l.amountMustBePositive : l.invalidExpression)
          : (target <= 0 ? l.amountMustBePositive : null);
      _savedError = saved == null
          ? l.invalidExpression
          : (saved < 0 ? l.amountMustBePositive : null);
    });
    if (_nameError != null ||
        _targetError != null ||
        _savedError != null ||
        target == null ||
        saved == null) {
      return;
    }
    // Cột dẫn xuất trong DB là số quy về Tiền tệ chính (D-037).
    final service = await ref.read(currencyServiceProvider.future);
    final derived = service.toPrimary(target, currency);
    final savedDerived = service.toPrimary(saved, currency);
    if (derived == null || savedDerived == null) {
      if (mounted) {
        setState(() => _targetError = l.rateMissing(currency, service.primary));
      }
      return;
    }
    _saving = true;
    final repo = ref.read(savingsRepositoryProvider);
    final dueKey = _due == null ? null : dateKey(_due!);
    final g = widget.goal;
    if (g != null) {
      await repo.edit(
        g.id,
        name: name,
        targetAmount: derived < 1 ? 1 : derived,
        originalTargetAmount: target,
        currency: _currencyLocked ? null : currency,
        dueDate: dueKey,
      );
      await repo.renameWallet(g.accountId, accountName);
    } else {
      await repo.addWithWallet(
        name: name,
        accountName: accountName,
        targetAmount: derived < 1 ? 1 : derived,
        originalTargetAmount: target,
        currency: currency,
        alreadySaved: saved,
        alreadySavedDerived: savedDerived,
        dueDate: dueKey,
      );
    }
    if (!mounted) return;
    // Lần đầu có hạn: giải thích + xin quyền thông báo nhắc hạn (AC-155),
    // ngay trên bảng này rồi mới đóng.
    if (dueKey != null) {
      await ensureDeadlinePermission(
        context,
        ref,
        explain: () => showConfirmDialog(
          context,
          icon: Symbols.notifications_rounded,
          iconTone: VgDialogTone.neutral,
          title: l.deadlineExplainTitle,
          body: l.deadlineExplainBody,
          action: l.reminderContinue,
        ),
        afterGranted: () => offerExactAlarm(context, ref), // D-045
      );
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
    final repo = ref.read(savingsRepositoryProvider);
    Navigator.pop(context);
    await repo.delete(widget.goal!.id);
    showMessage(l.savingsDeleted);
  }

  Widget _amountField({
    required TextEditingController controller,
    required String label,
    required String currency,
    String? helper,
    String? error,
  }) {
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final service = ref.watch(currencyServiceProvider).value;
    final typed = parseAmountField(
      context,
      controller.text.trim(),
      currencyDecimalDigits(currency),
    );
    final converted = typed == null || currency == primary
        ? null
        : service?.toPrimary(typed, currency);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: currencySymbol(currency),
        helperText: converted == null
            ? helper
            : '≈ ${money(context, primary, converted)}',
        helperMaxLines: 3,
        errorText: error,
        errorMaxLines: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final currency = _currency ?? primary;
    final goal = widget.goal;
    EdgeInsets pad([double top = VgSpace.s2]) =>
        EdgeInsets.fromLTRB(VgSpace.s4, top, VgSpace.s4, 0);
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
                    padding: pad(),
                    child: TextField(
                      controller: _name,
                      maxLength: 50,
                      autofocus: goal == null,
                      onChanged: (v) {
                        if (_accountFollowsName) _account.text = v;
                      },
                      decoration: InputDecoration(
                        labelText: l.savingsGoalName,
                        errorText: _nameError,
                      ),
                    ),
                  ),
                  Padding(
                    padding: pad(),
                    child: TextField(
                      controller: _account,
                      maxLength: 50,
                      onChanged: (_) => _accountFollowsName = false,
                      decoration: InputDecoration(
                        labelText: l.savingsAccount,
                        prefixIcon: const Icon(
                          Symbols.account_balance_wallet_rounded,
                        ),
                        helperText: goal == null
                            ? l.savingsAccountHelper
                            : l.savingsAccountEditHelper,
                        helperMaxLines: 3,
                        errorText: _accountError,
                      ),
                    ),
                  ),
                  Padding(
                    padding: pad(),
                    child: _amountField(
                      controller: _target,
                      label: l.savingsTarget,
                      currency: currency,
                      error: _targetError,
                    ),
                  ),
                  Padding(
                    padding: pad(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(VgRadius.sm),
                      onTap: _currencyLocked ? null : _pickCurrency,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.currency,
                          suffixIcon: Icon(
                            _currencyLocked
                                ? Symbols.lock_rounded
                                : Symbols.arrow_drop_down_rounded,
                          ),
                        ),
                        child: Text(currencyCodeLabel(currency)),
                      ),
                    ),
                  ),
                  if (_currencyLocked)
                    Padding(
                      padding: pad(),
                      child: VgHint(
                        l.savingsCurrencyLocked,
                        icon: Symbols.lock_rounded,
                      ),
                    ),
                  if (goal == null)
                    Padding(
                      padding: pad(VgSpace.s3),
                      child: _amountField(
                        controller: _saved,
                        label: l.savingsAlreadySaved,
                        currency: currency,
                        helper: l.savingsAlreadySavedHelper,
                        error: _savedError,
                      ),
                    ),
                  Padding(
                    padding: pad(VgSpace.s3),
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
                  if (goal != null)
                    Padding(
                      padding: pad(VgSpace.s3),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
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
