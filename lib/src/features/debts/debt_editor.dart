import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/balance_guard.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/debt_repository.dart';
import '../../data/interest.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_segments.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../entry/ledger_guard.dart';
import '../reminder/deadline_reminders.dart';
import '../settings/exact_alarm_row.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import '../settings/currency_picker.dart';
import 'debts_providers.dart';

/// Thêm hoặc sửa khoản nợ (AC-104, D-049): người ≤ 50, chiều Cho vay / Đi
/// vay, số tiền > 0, **tài khoản** (mặc định theo bộ lọc, hoặc "Không qua tài
/// khoản"), **lãi suất** tuỳ chọn (%/tháng | %/năm) + ngày bắt đầu tính lãi,
/// ngày, hạn (tuỳ chọn), ghi chú ≤ 200. Có tài khoản thì số tiền vay là một
/// Debt movement (AC-169); cho vay chịu "có thu mới có chi" (AC-160).
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

/// Giá trị chọn "Không qua tài khoản" trong bảng chọn tài khoản.
const _noAccount = -1;

/// Lãi suất gõ (phần trăm, tối đa 2 chữ số lẻ) → phần trăm × 100; null khi
/// sai hoặc ngoài 0 < r ≤ 100 (AC-171).
int? parseInterestRate(BuildContext context, String text) {
  final v = parseAmountField(context, text, 2);
  if (v == null || v <= 0 || v > 10000) return null;
  return v;
}

/// Lãi suất phần trăm × 100 → chữ theo ngôn ngữ, vd "12" hoặc "1,5".
String formatInterestRate(BuildContext context, int rate) =>
    amountInput(context, rate, 2);

/// "12 %/năm" / "1,5 %/tháng".
String interestRateLabel(
  BuildContext context,
  int rate,
  InterestPeriod period,
) {
  final l = AppLocalizations.of(context);
  return '${formatInterestRate(context, rate)} '
      '${period == InterestPeriod.month ? l.debtPerMonth : l.debtPerYear}';
}

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
  final _rate = TextEditingController();
  DebtDirection _direction = DebtDirection.lent;
  late DateTime _date = ref.read(todayProvider);
  DateTime? _due;
  String? _personError;
  String? _amountError;
  String? _rateError;
  InterestPeriod _period = InterestPeriod.year;

  /// Ngày bắt đầu tính lãi; null = theo ngày vay (AC-171).
  DateTime? _interestStart;

  /// Tài khoản của khoản nợ; [_noAccount] = "Không qua tài khoản"; null =
  /// chưa chọn (mặc định theo bộ lọc, D-047).
  int? _accountId;

  /// Tiền tệ của khoản nợ (D-037); khóa sau lần trả đầu và khi đã có Debt
  /// movement (AC-176).
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
      _accountId = d.accountId ?? _noAccount;
      final digits = currencyDecimalDigits(d.currency);
      _amount.text = amountInput(context, d.originalAmount ?? d.amount, digits);
      final rate = d.interestRate;
      if (rate != null) {
        _rate.text = formatInterestRate(context, rate);
        _period = d.interestPeriod ?? InterestPeriod.year;
        _interestStart = d.interestStart == null
            ? null
            : parseDateKey(d.interestStart!);
      }
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    _rate.dispose();
    super.dispose();
  }

  /// Tài khoản đang chọn: chọn tay, không thì tài khoản đang lọc ở màn chính,
  /// không thì tài khoản hiện đầu tiên (D-047, AC-169).
  int? _account(List<Account> accounts) {
    if (_accountId != null) return _accountId == _noAccount ? null : _accountId;
    final filter = ref.read(accountFilterProvider);
    if (filter != null && accounts.any((a) => a.id == filter)) return filter;
    return accounts.firstOrNull?.id;
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

  Future<void> _pickInterestStart() async {
    final today = ref.read(todayProvider);
    final current = _interestStart ?? _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: current.isBefore(DateTime(2000)) ? current : DateTime(2000),
      lastDate: DateTime(today.year + 30),
    );
    if (picked != null) setState(() => _interestStart = dateOnly(picked));
  }

  Future<void> _pickAccount(List<Account> accounts, int? current) async {
    final l = AppLocalizations.of(context);
    // Khoản nợ đã đi qua tài khoản không bỏ được tài khoản (giữ Debt
    // movement); khoản nợ ghi nhớ cũ giữ là ghi nhớ.
    final canNone = widget.view == null;
    final picked = await showChoiceSheet<int>(
      context,
      title: l.account,
      selected: current ?? _noAccount,
      options: [
        for (final a in accounts)
          ChoiceOption(
            a.id,
            accountLabel(l, a),
            icon: Symbols.account_balance_wallet_rounded,
          ),
        if (canNone)
          ChoiceOption(
            _noAccount,
            l.debtNoAccount,
            icon: Symbols.edit_note_rounded,
          ),
      ],
    );
    if (picked != null) {
      setState(() {
        _accountId = picked.$1;
        _amountError = null;
      });
    }
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
    final rateText = _rate.text.trim();
    final rate = rateText.isEmpty ? null : parseInterestRate(context, rateText);
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    final accountId = _account(accounts);
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
      _rateError = rateText.isNotEmpty && rate == null
          ? l.debtRateInvalid
          : null;
    });
    if (_personError != null || amountError != null || _rateError != null) {
      return;
    }
    _saving = true;
    final repo = ref.read(debtRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final due = _due == null ? null : dateKey(_due!);
    final start = rate == null || _interestStart == null
        ? null
        : dateKey(_interestStart!);
    final v = widget.view;
    try {
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
          accountId: accountId,
          interestRate: rate,
          interestPeriod: _period,
          interestStart: start,
          service: service,
        );
      } else {
        // Tiền tệ khóa sau lần trả đầu / khi có Debt movement (AC-176): repo
        // giữ tiền tệ cũ, ở đây cũng gửi đúng tiền tệ đang hiện.
        await repo.edit(
          v.debt.id,
          person: person,
          direction: _direction,
          amount: amount!,
          originalAmount: amountOriginal,
          currency: _locked(v) ? v.debt.currency : currency,
          date: dateKey(_date),
          dueDate: due,
          note: note,
          accountId: accountId,
          interestRate: rate,
          interestPeriod: _period,
          interestStart: start,
          service: service,
        );
      }
    } on InsufficientFundsException catch (e) {
      // Cho vay làm tài khoản âm (AC-160): báo dưới ô số tiền, không lưu.
      _saving = false;
      if (mounted) {
        setState(
          () => _amountError = shortfallMessage(context, ref, e.shortfall),
        );
      }
      return;
    } on StateError {
      _saving = false;
      if (mounted) {
        final account = accounts.where((a) => a.id == accountId).firstOrNull;
        setState(
          () => _amountError = l.rateMissing(
            currency,
            account?.currency ?? primary,
          ),
        );
      }
      return;
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

  /// Tiền tệ khoá: đã có lần trả, hoặc khoản nợ đi qua tài khoản (AC-176).
  bool _locked(DebtView? v) =>
      v != null && (v.payments.isNotEmpty || v.debt.accountId != null);

  /// Đổi tiền tệ khoản nợ: giữ nguyên số đã nhập, chỉ đổi đơn vị (AC-168).
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
    final locked = _locked(widget.view);
    final today = ref.watch(todayProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? accounts;
    final accountId = _account(accounts);
    final account = all.where((a) => a.id == accountId).firstOrNull;
    final memo = widget.view != null && widget.view!.debt.accountId == null;
    // Hai phía khi khác tiền tệ (AC-167): "Trừ từ TCB: …" / "Vào TCB: …".
    String? accountLine;
    if (account != null &&
        typed != null &&
        typed > 0 &&
        service != null &&
        account.currency != currency) {
      final inAccount = service.convert(typed, currency, account.currency);
      if (inAccount != null) {
        final shown = money(context, account.currency, inAccount);
        accountLine = _direction == DebtDirection.lent
            ? l.ledgerFrom(accountLabel(l, account), shown)
            : l.ledgerInto(accountLabel(l, account), shown);
      }
    }
    final helper = [
      if (converted != null) '≈ ${money(context, primary, converted)}',
      ?accountLine,
    ].join('\n');
    // Xem trước lãi 30 ngày đầu (AC-172).
    final rate = parseInterestRate(context, _rate.text.trim());
    String? preview;
    if (rate != null && typed != null && typed > 0) {
      final start = _interestStart ?? _date;
      final accrued = DebtInterest(
        principal: typed,
        start: start,
        rates: [(from: start, annual: annualRateOf(rate, _period))],
        payments: const [],
      ).accrued(addDays(start, 30));
      preview = l.debtInterestPreview(money(context, currency, accrued));
    }
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
                      onChanged: (widget.view?.payments.isNotEmpty ?? false)
                          ? (_) {}
                          : (d) => setState(() {
                              _direction = d;
                              _amountError = null;
                            }),
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
                      key: const Key('debt-amount'),
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
                      onChanged: (_) => setState(() => _amountError = null),
                      decoration: InputDecoration(
                        labelText: l.debtAmount,
                        suffixText: currencySymbol(currency),
                        helperText: helper.isEmpty ? null : helper,
                        helperMaxLines: 3,
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
                        widget.view!.payments.isNotEmpty
                            ? l.currencyLockedPayments
                            : l.debtCurrencyLockedMovement,
                        icon: Symbols.lock_rounded,
                      ),
                    ),
                  // Tài khoản (D-049, AC-169): mặc định theo bộ lọc; "Không
                  // qua tài khoản" = chỉ ghi nhớ.
                  Padding(
                    padding: pad(),
                    child: InkWell(
                      key: const Key('debt-account'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: memo
                          ? null
                          : () => _pickAccount(accounts, accountId),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.account,
                          helperText: account == null
                              ? l.debtNoAccountHelper
                              : null,
                          suffixIcon: Icon(
                            memo
                                ? Symbols.lock_rounded
                                : Symbols.arrow_drop_down_rounded,
                          ),
                        ),
                        child: Text(
                          account == null
                              ? l.debtNoAccount
                              : accountLabel(l, account),
                        ),
                      ),
                    ),
                  ),
                  // Lãi suất tuỳ chọn (AC-171): trống = không lãi.
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('debt-rate'),
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          onChanged: (_) => setState(() => _rateError = null),
                          decoration: InputDecoration(
                            labelText: l.debtInterestRate,
                            suffixText: '%',
                            helperText: preview,
                            helperMaxLines: 2,
                            errorText: _rateError,
                            errorMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: VgSpace.s2),
                        ChoiceSegments<InterestPeriod>(
                          options: [
                            (InterestPeriod.month, l.debtPerMonth),
                            (InterestPeriod.year, l.debtPerYear),
                          ],
                          selected: _period,
                          onChanged: (p) => setState(() => _period = p),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: Wrap(
                      spacing: VgSpace.s2,
                      runSpacing: VgSpace.s1,
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
                        if (_rate.text.trim().isNotEmpty)
                          ActionChip(
                            key: const Key('debt-interest-start'),
                            avatar: const Icon(
                              Symbols.percent_rounded,
                              size: 18,
                            ),
                            label: Text(
                              l.debtInterestStartOn(
                                shortDate(context, _interestStart ?? _date),
                              ),
                            ),
                            tooltip: l.debtInterestStart,
                            onPressed: _pickInterestStart,
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
