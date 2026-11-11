import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/debt_repository.dart';
import '../../data/money.dart';
import '../../providers.dart';
import '../../ui/choice_segments.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../reminder/deadline_reminders.dart';
import '../settings/exact_alarm_row.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import '../settings/currency_picker.dart';
import 'debts_providers.dart';

/// Thêm hoặc sửa khoản nợ (AC-104): người ≤ 50, chiều Cho vay / Đi vay, số
/// tiền > 0, ngày, hạn (tuỳ chọn), ghi chú ≤ 200. Sửa thì [view] là khoản
/// đang sửa. Không tạo khoản, không đụng số dư (AC-106).
Future<void> showDebtEditor(BuildContext context, {DebtView? view}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _DebtEditor(view: view),
      ),
    );

class _DebtEditor extends ConsumerStatefulWidget {
  const _DebtEditor({this.view});

  final DebtView? view;

  @override
  ConsumerState<_DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends ConsumerState<_DebtEditor> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DebtDirection _direction = DebtDirection.lent;
  late DateTime _date = ref.read(todayProvider);
  DateTime? _due;
  String? _personError;
  String? _amountError;

  /// Tiền tệ của khoản nợ (D-037); khóa sau lần trả đầu.
  String? _currency;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = widget.view;
    if (v != null && _person.text.isEmpty) {
      final d = v.debt;
      _person.text = d.person;
      _note.text = d.note ?? '';
      _direction = d.direction;
      _date = parseDateKey(d.date);
      _due = d.dueDate == null ? null : parseDateKey(d.dueDate!);
      _currency ??= d.currency;
      final digits = currencyDecimalDigits(d.currency);
      _amount.text = amountInput(context, d.originalAmount ?? d.amount, digits);
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool due}) async {
    final today = ref.read(todayProvider);
    final current = due ? (_due ?? _date) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: current.isBefore(DateTime(2000)) ? current : DateTime(2000),
      lastDate: DateTime(today.year + 30),
    );
    if (picked == null) return;
    setState(() => due ? _due = dateOnly(picked) : _date = dateOnly(picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final primary = ref.read(currencyProvider).value ?? 'USD';
    final currency = _currency ?? primary;
    final digits = currencyDecimalDigits(currency);
    final person = _person.text.trim();
    final text = _amount.text.trim();
    final amountOriginal = text.isEmpty
        ? null
        : parseAmountField(context, text, digits);
    final service = await ref.read(currencyServiceProvider.future);
    if (!mounted) return;
    final amount = amountOriginal == null
        ? null
        : service.toPrimary(amountOriginal, currency);
    String? amountError;
    if (amountOriginal == null || amount == null) {
      amountError = amountOriginal == null
          ? (text.isEmpty ? l.amountMustBePositive : l.invalidExpression)
          : l.rateMissing(currency, primary);
    } else if (amountOriginal <= 0) {
      amountError = l.amountMustBePositive;
    } else if (widget.view != null) {
      // Sửa số tiền gốc xuống dưới số đã trả thì "còn lại" vô nghĩa.
      // So bằng số gốc theo tiền tệ khoản nợ (AC-148).
      final paid = widget.view!.paid();
      if (amountOriginal < paid) {
        amountError = l.debtAmountBelowPaid(money(context, currency, paid));
      }
    }
    setState(() {
      _personError = person.isEmpty ? l.nameRequired : null;
      _amountError = amountError;
    });
    if (_personError != null || amountError != null) return;
    _saving = true;
    final repo = ref.read(debtRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final due = _due == null ? null : dateKey(_due!);
    final v = widget.view;
    if (v == null) {
      await repo.add(
        person: person,
        direction: _direction,
        amount: amount!,
        originalAmount: amountOriginal,
        currency: currency,
        date: dateKey(_date),
        dueDate: due,
        note: note,
      );
    } else {
      // Tiền tệ khóa sau lần trả đầu (D-037): repo giữ tiền tệ cũ, ở đây cũng
      // gửi đúng tiền tệ đang hiện để số gốc khớp.
      await repo.edit(
        v.debt.id,
        person: person,
        direction: _direction,
        amount: amount!,
        originalAmount: amountOriginal,
        currency: v.payments.isEmpty ? currency : v.debt.currency,
        date: dateKey(_date),
        dueDate: due,
        note: note,
      );
    }
    // Lần đầu có hạn: giải thích + xin quyền nhắc trước hạn (AC-155).
    if (due != null && mounted) {
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

  /// Đổi tiền tệ khoản nợ: giữ nguyên số đã nhập, chỉ đổi đơn vị (D-037).
  Future<void> _pickCurrency() async {
    final primary = ref.read(currencyProvider).value ?? 'USD';
    final current = _currency ?? primary;
    final picked = await showCurrencyPicker(context, current);
    if (picked == null || picked == current || !mounted) return;
    final oldDigits = currencyDecimalDigits(current);
    final newDigits = currencyDecimalDigits(picked);
    final text = _amount.text.trim();
    final parsed = text.isEmpty
        ? 0
        : parseAmountField(context, text, oldDigits);
    setState(() {
      _currency = picked;
      if (parsed != null && text.isNotEmpty) {
        _amount.text = amountInput(
          context,
          rescaleMinorUnits(parsed, oldDigits, newDigits),
          newDigits,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final currency = _currency ?? primary;
    final digits = currencyDecimalDigits(currency);
    final service = ref.watch(currencyServiceProvider).value;
    final typed = parseAmountField(context, _amount.text.trim(), digits);
    final converted = typed == null || currency == primary
        ? null
        : service?.toPrimary(typed, currency);
    final locked = widget.view?.payments.isNotEmpty ?? false;
    final today = ref.watch(todayProvider);
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
                  SheetHeader(widget.view == null ? l.debtAdd : l.debtEdit),
                  Padding(
                    padding: pad(),
                    child: ChoiceSegments<DebtDirection>(
                      options: [
                        (DebtDirection.lent, l.debtLent),
                        (DebtDirection.borrowed, l.debtBorrowed),
                      ],
                      selected: _direction,
                      onChanged: (d) => setState(() => _direction = d),
                    ),
                  ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: TextField(
                      controller: _person,
                      maxLength: 50,
                      autofocus: widget.view == null,
                      decoration: InputDecoration(
                        labelText: l.debtPerson,
                        errorText: _personError,
                      ),
                    ),
                  ),
                  Padding(
                    padding: pad(),
                    child: TextField(
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
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l.debtAmount,
                        suffixText: currencySymbol(currency),
                        helperText: converted == null
                            ? null
                            : '≈ ${money(context, primary, converted)}',
                        errorText: _amountError,
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                  Padding(
                    padding: pad(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: locked ? null : _pickCurrency,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.currency,
                          suffixIcon: Icon(
                            locked
                                ? Symbols.lock_rounded
                                : Symbols.arrow_drop_down_rounded,
                          ),
                        ),
                        child: Text(currencyCodeLabel(currency)),
                      ),
                    ),
                  ),
                  if (locked)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s4,
                        VgSpace.s2,
                        VgSpace.s4,
                        0,
                      ),
                      child: VgHint(
                        l.currencyLockedPayments,
                        icon: Symbols.lock_rounded,
                      ),
                    ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: Wrap(
                      spacing: VgSpace.s2,
                      children: [
                        ActionChip(
                          avatar: const Icon(
                            Symbols.calendar_today_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _date == today
                                ? l.today
                                : shortDate(context, _date),
                          ),
                          tooltip: l.debtDate,
                          onPressed: () => _pick(due: false),
                        ),
                        if (_due == null)
                          ActionChip(
                            avatar: const Icon(Symbols.event_rounded, size: 18),
                            label: Text(l.debtDue),
                            onPressed: () => _pick(due: true),
                          )
                        else
                          InputChip(
                            avatar: const Icon(Symbols.event_rounded, size: 18),
                            label: Text(l.debtDueOn(shortDate(context, _due!))),
                            onPressed: () => _pick(due: true),
                            deleteButtonTooltipMessage: l.debtClearDue,
                            onDeleted: () => setState(() => _due = null),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: TextField(
                      controller: _note,
                      maxLength: 200,
                      decoration: InputDecoration(hintText: l.noteHint),
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
