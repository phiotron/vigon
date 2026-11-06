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
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
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
      final digits = currencyDecimalDigits(
        ref.read(currencyProvider).value ?? 'VND',
      );
      _amount.text = amountInput(context, d.amount, digits);
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
    final currency = ref.read(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final person = _person.text.trim();
    final text = _amount.text.trim();
    final amount = text.isEmpty
        ? null
        : parseAmountField(context, text, digits);
    String? amountError;
    if (amount == null) {
      amountError = text.isEmpty ? l.amountMustBePositive : l.invalidExpression;
    } else if (amount <= 0) {
      amountError = l.amountMustBePositive;
    } else if (widget.view != null && amount < widget.view!.paid(digits)) {
      // Sửa số tiền gốc xuống dưới số đã trả thì "còn lại" vô nghĩa.
      amountError = l.debtAmountBelowPaid(
        money(context, currency, widget.view!.paid(digits)),
      );
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
        date: dateKey(_date),
        dueDate: due,
        note: note,
      );
    } else {
      await repo.edit(
        v.debt.id,
        person: person,
        direction: _direction,
        amount: amount!,
        date: dateKey(_date),
        dueDate: due,
        note: note,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
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
                      decoration: InputDecoration(
                        labelText: l.debtAmount,
                        suffixText: currencySymbol(currency),
                        errorText: _amountError,
                        errorMaxLines: 3,
                      ),
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
