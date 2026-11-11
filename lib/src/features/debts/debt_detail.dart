import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/balance_guard.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/debt_repository.dart';
import '../../data/money.dart';
import '../../data/rate_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_segments.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/status.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../entry/ledger_guard.dart';
import '../entry/typed_amount.dart';
import '../reminder/deadline_reminders.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import 'debt_editor.dart';
import 'debts_providers.dart';
import 'debts_screen.dart' show isDebtOverdue, nextDeadlineReminder;

/// Chi tiết một khoản nợ (AC-105, D-049): còn lại = gốc + lãi tới hôm nay
/// (AC-174), chip lãi suất, các mốc lãi suất + "Đổi lãi suất" (AC-171), các
/// lần trả tách lãi/gốc (xoá có Hoàn tác, chịu AC-161), "Thêm lần trả", sửa,
/// xoá. Tự đóng khi khoản nợ không còn.
Future<void> showDebtDetail(BuildContext context, int debtId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DebtDetail(debtId: debtId),
    );

class _DebtDetail extends ConsumerWidget {
  const _DebtDetail({required this.debtId});

  final int debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(debtsProvider);
    final view = all.value?.where((v) => v.debt.id == debtId).firstOrNull;
    if (view == null) {
      // Đã xoá (hoặc chưa nạp): không có gì để hiện.
      if (all.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Chỉ đóng khi bảng này còn là route trên cùng: lúc đang chạy hoạt
          // ảnh đóng (đã pop) mà dữ liệu biến mất thì maybePop sẽ đóng nhầm
          // màn bên dưới (AC-158).
          if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.maybePop(context);
          }
        });
      }
      return const SizedBox(height: 120);
    }
    final digits = currencyDecimalDigits(view.debt.currency);
    final today = ref.watch(todayProvider);
    final d = view.debt;
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    String accountName(int? id) =>
        accounts[id] == null ? '' : accountLabel(l, accounts[id]!);
    // Số theo tiền tệ khoản nợ tính thẳng từ số gốc (AC-148); hiện Tiền tệ
    // chính trên, số gốc dưới (AC-146).
    MoneyLinesText lines(int amount) =>
        moneyLinesText(context, ref, amount, d.currency);

    final settled = view.isSettled(digits);
    final overdue = isDebtOverdue(view, today, digits);
    final remindOn = ref.watch(deadlineReminderEnabledProvider).value ?? false;
    final remindDays = ref.watch(deadlineReminderDaysProvider).value;
    final remindAt = !settled && !overdue && remindOn && remindDays != null
        ? nextDeadlineReminder(
            d.dueDate == null ? null : parseDateKey(d.dueDate!),
            remindDays,
            today,
          )
        : null;
    final rate = d.interestRate;

    Widget line(
      String label,
      String value, {
      Color? color,
      bool bold = false,
      String? secondary,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: VgSpace.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: VgSpace.s3),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: VgType.bodyMd.copyWith(
                    color: color ?? scheme.onSurface,
                    fontWeight: bold ? FontWeight.w600 : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (secondary != null)
                  Text(
                    secondary,
                    textAlign: TextAlign.end,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s2,
                        VgSpace.s2,
                        VgSpace.s2,
                        VgSpace.s1,
                      ),
                      child: Text(
                        d.person,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  // Mockup v4 SCR-42 detail: chip chiều nợ, số còn lại là số
                  // lớn, thanh đã trả, chip hạn + ngày nhắc trước hạn (D-044).
                  Wrap(
                    spacing: VgSpace.s2,
                    runSpacing: VgSpace.s1,
                    children: [
                      StatusChip(
                        label: d.direction == DebtDirection.lent
                            ? l.debtLent
                            : l.debtBorrowed,
                        icon: d.direction == DebtDirection.lent
                            ? Symbols.call_made_rounded
                            : Symbols.call_received_rounded,
                      ),
                      // Chip lãi suất (AC-171), mốc đang áp dụng hôm nay.
                      if (rate != null || view.rateChanges.isNotEmpty)
                        StatusChip(
                          key: const Key('debt-rate-chip'),
                          label: _currentRateLabel(context, view, today),
                          icon: Symbols.percent_rounded,
                          tone: StatusTone.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: VgSpace.s3),
                  Text(
                    settled ? l.debtAmount : l.debtRemainingLabel,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final big = lines(
                        settled ? view.total : view.remaining(),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              big.main,
                              style: VgType.amountXl.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (big.secondary != null)
                            Text(
                              big.secondary!,
                              style: VgType.bodySm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  // "Gốc X · Lãi tới hôm nay Y" (AC-174).
                  if (view.hasInterest && !settled)
                    Text(
                      l.debtPrincipalInterest(
                        money(context, d.currency, view.principalLeft),
                        money(context, d.currency, view.unpaidInterest),
                      ),
                      key: const Key('debt-principal-interest'),
                      style: VgType.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VgRadius.full),
                    child: LinearProgressIndicator(
                      value: view.total <= 0
                          ? 0
                          : (view.paid() / view.total).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHigh,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: VgSpace.s1),
                  Text(
                    l.debtPaidOf(
                      money(context, d.currency, view.paid()),
                      money(context, d.currency, view.total),
                    ),
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VgSpace.s2),
                  Wrap(
                    spacing: VgSpace.s2,
                    runSpacing: VgSpace.s1,
                    children: [
                      if (settled)
                        StatusChip(
                          label: l.debtDone,
                          icon: Symbols.check_circle_rounded,
                          tone: StatusTone.ok,
                        )
                      else if (overdue)
                        StatusChip(
                          label:
                              '${l.debtOverdue} · '
                              '${shortDate(context, parseDateKey(d.dueDate!))}',
                          icon: Symbols.schedule_rounded,
                          tone: StatusTone.warn,
                        )
                      else if (d.dueDate != null)
                        StatusChip(
                          label: l.debtDueOn(
                            shortDate(context, parseDateKey(d.dueDate!)),
                          ),
                          icon: Symbols.event_rounded,
                        ),
                      if (remindAt != null)
                        StatusChip(
                          label: l.remindNext(shortDate(context, remindAt)),
                          icon: Symbols.notifications_rounded,
                          tone: StatusTone.info,
                        ),
                    ],
                  ),
                  const Divider(height: VgSpace.s6),
                  line(l.debtDate, shortDate(context, parseDateKey(d.date))),
                  line(
                    l.account,
                    d.accountId == null
                        ? l.debtNoAccount
                        : accountName(d.accountId),
                  ),
                  if (d.note != null) line(l.noteHint, d.note!),
                  // Các mốc lãi suất + Đổi lãi suất (AC-171).
                  if (view.hasInterest) ...[
                    const SizedBox(height: VgSpace.s2),
                    Semantics(
                      header: true,
                      child: Text(
                        l.debtRateSteps,
                        style: VgType.titleSm.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    if (rate != null && d.interestPeriod != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Symbols.percent_rounded),
                        title: Text(
                          interestRateLabel(context, rate, d.interestPeriod!),
                        ),
                        subtitle: Text(
                          l.debtRateFrom(
                            shortDate(
                              context,
                              parseDateKey(d.interestStart ?? d.date),
                            ),
                          ),
                        ),
                      ),
                    for (final c in view.rateChanges)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Symbols.trending_flat_rounded),
                        title: Text(
                          interestRateLabel(context, c.rate, c.period),
                        ),
                        subtitle: Text(
                          l.debtRateFrom(
                            shortDate(context, parseDateKey(c.date)),
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Symbols.delete_rounded),
                          onPressed: () => ref
                              .read(debtRepositoryProvider)
                              .deleteRateChange(c.id),
                        ),
                      ),
                  ],
                  if (view.hasInterest || rate != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: const Key('debt-change-rate'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          minimumSize: const Size(0, VgSize.tapMin),
                        ),
                        icon: const Icon(Symbols.edit_rounded),
                        label: Text(l.debtChangeRate),
                        onPressed: () =>
                            showRateChangeDialog(context, ref, view),
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(
                      l.debtPayments,
                      style: VgType.titleSm.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  if (view.payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: VgSpace.s2),
                      child: Text(
                        l.debtNoPayments,
                        style: VgType.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final p in view.payments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: MoneyLines(
                        amount: (p.originalAmount ?? p.amount) + p.interest,
                        currency: p.currency,
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        secondaryStyle: VgType.bodySm,
                      ),
                      subtitle: Text(
                        [
                          shortDate(context, parseDateKey(p.date)),
                          if (p.accountId != null) accountName(p.accountId),
                          // Lần trả tách lãi/gốc (AC-173).
                          if (p.interest > 0)
                            l.debtPaymentSplit(
                              money(context, p.currency, p.interest),
                              money(
                                context,
                                p.currency,
                                p.originalAmount ?? p.amount,
                              ),
                            ),
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: l.debtDeletePayment,
                        icon: const Icon(Symbols.delete_rounded),
                        onPressed: () => _deletePayment(context, ref, p.id),
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          minimumSize: const Size(0, VgSize.tapMin),
                        ),
                        icon: const Icon(Symbols.edit_rounded),
                        label: Text(l.debtEdit),
                        onPressed: () => showDebtEditor(context, view: view),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                          minimumSize: const Size(0, VgSize.tapMin),
                        ),
                        icon: const Icon(Symbols.delete_rounded),
                        label: Text(l.debtDelete),
                        onPressed: () => _delete(context, ref, d.person),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!settled)
            SheetFooter(
              border: false,
              children: [
                FilledButton(
                  style: sheetFilledButtonStyle(),
                  onPressed: () => _addPayment(context, view),
                  child: Text(l.debtAddPayment),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Lãi suất áp dụng hôm nay: mốc đổi gần nhất ≤ hôm nay, không thì lãi
  /// suất ban đầu.
  static String _currentRateLabel(
    BuildContext context,
    DebtView view,
    DateTime today,
  ) {
    final d = view.debt;
    var rate = d.interestRate;
    var period = d.interestPeriod ?? InterestPeriod.year;
    for (final c in view.rateChanges) {
      if (parseDateKey(c.date).isAfter(today)) break;
      rate = c.rate;
      period = c.period;
    }
    if (rate == null) {
      final first = view.rateChanges.first;
      rate = first.rate;
      period = first.period;
    }
    return interestRateLabel(context, rate, period);
  }

  /// Xoá lần trả cùng các khoản của nó; xoá lần thu nợ làm âm tài khoản thì
  /// báo, không xoá (AC-161); có Hoàn tác (AC-170).
  Future<void> _deletePayment(
    BuildContext context,
    WidgetRef ref,
    int paymentId,
  ) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final repo = ref.read(debtRepositoryProvider);
    final service = await ref.read(currencyServiceProvider.future);
    try {
      final deleted = await repo.deletePayment(paymentId, service: service);
      if (deleted == null) return;
      showUndoSnackBar(
        message: l.deleted,
        undoLabel: l.undo,
        onUndo: () async {
          try {
            await repo.restorePayment(deleted, service: service);
          } on InsufficientFundsException catch (e) {
            showMessage(shortfallText(l, locale, e.shortfall));
          }
        },
      );
    } on InsufficientFundsException catch (e) {
      if (context.mounted) await showDeleteBlocked(context, ref, e.shortfall);
    }
  }

  /// Xoá khoản nợ (AC-175): khoản nợ, lần trả, lịch lãi suất bị xoá; các
  /// khoản trong sổ giữ nguyên ("Khoản nợ đã xoá").
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String person,
  ) async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.delete_rounded,
      title: l.debtDeleteTitlePerson(person),
      body: l.debtDeleteKeepsEntries,
      action: l.delete,
      style: ConfirmStyle.danger,
    );
    if (!ok || !context.mounted) return;
    // Đóng Chi tiết TRƯỚC rồi mới xoá: nếu xoá trước, Chi tiết tự đóng khi
    // khoản nợ biến mất và lần pop thứ hai đóng luôn màn Khoản nợ (AC-158).
    final repo = ref.read(debtRepositoryProvider);
    Navigator.pop(context);
    await repo.delete(debtId);
    showMessage(l.debtDeleted);
  }

  Future<void> _addPayment(BuildContext context, DebtView view) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _PaymentSheet(debtId: view.debt.id),
        ),
      );
}

/// Hộp "Đổi lãi suất" (AC-171): lãi suất mới (0 < r ≤ 100, 2 chữ số lẻ) +
/// kỳ + ngày áp dụng (≥ ngày bắt đầu tính lãi).
Future<void> showRateChangeDialog(
  BuildContext context,
  WidgetRef ref,
  DebtView view,
) => showDialog<void>(
  context: context,
  builder: (context) => _RateChangeDialog(view: view),
);

class _RateChangeDialog extends ConsumerStatefulWidget {
  const _RateChangeDialog({required this.view});

  final DebtView view;

  @override
  ConsumerState<_RateChangeDialog> createState() => _RateChangeDialogState();
}

class _RateChangeDialogState extends ConsumerState<_RateChangeDialog> {
  final _rate = TextEditingController();
  late InterestPeriod _period =
      widget.view.debt.interestPeriod ?? InterestPeriod.year;
  late DateTime _date = ref.read(todayProvider);
  String? _error;

  DateTime get _start =>
      parseDateKey(widget.view.debt.interestStart ?? widget.view.debt.date);

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final rate = parseInterestRate(context, _rate.text.trim());
    if (rate == null) {
      setState(() => _error = l.debtRateInvalid);
      return;
    }
    if (_date.isBefore(_start)) {
      setState(() => _error = l.debtRateBeforeStart);
      return;
    }
    await ref
        .read(debtRepositoryProvider)
        .addRateChange(
          widget.view.debt.id,
          date: dateKey(_date),
          rate: rate,
          period: _period,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VgDialog(
      title: l.debtChangeRate,
      icon: Symbols.percent_rounded,
      tone: VgDialogTone.neutral,
      content: [
        TextField(
          key: const Key('rate-change-field'),
          controller: _rate,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: l.debtNewRate,
            suffixText: '%',
            errorText: _error,
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
        const SizedBox(height: VgSpace.s2),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionChip(
            avatar: const Icon(Symbols.calendar_today_rounded, size: 18),
            label: Text(l.debtRateFrom(shortDate(context, _date))),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: _start.isBefore(DateTime(2000))
                    ? _start
                    : DateTime(2000),
                lastDate: DateTime(_date.year + 30),
              );
              if (picked != null) {
                setState(() {
                  _date = dateOnly(picked);
                  _error = null;
                });
              }
            },
          ),
        ),
      ],
      actions: [
        VgDialog.cancelButton(context),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}

/// Lần trả (AC-105, AC-167, AC-170, AC-173): số tiền theo Tiền tệ chính +
/// chip; tài khoản (bắt buộc với khoản nợ có tài khoản; khoản nợ ghi nhớ có
/// thêm "Không qua tài khoản"); có lãi thì tự chia **lãi trước** (Lãi = lãi
/// tới ngày trả chưa trả, Gốc = phần còn lại), sửa được hai ô; "Chỉ trả lãi",
/// "Trả hết"; ngày.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.debtId});

  final int debtId;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final _amount = TypedAmount(ref.read(currencyProvider).value ?? 'USD');
  final _interest = TextEditingController();
  final _principal = TextEditingController();
  late DateTime _date = ref.read(todayProvider);
  String? _error;
  String? _interestError;
  String? _principalError;
  bool _saving = false;

  /// Đã chọn tài khoản; [_none] = không qua tài khoản; null = mặc định.
  int? _accountId;
  static const _none = -1;

  /// Người dùng đã tự sửa ô Lãi/Gốc: không tự chia lại theo số tổng.
  bool _manualSplit = false;

  @override
  void dispose() {
    _amount.dispose();
    _interest.dispose();
    _principal.dispose();
    super.dispose();
  }

  DebtView? _view() => ref
      .read(debtsProvider)
      .value
      ?.where((v) => v.debt.id == widget.debtId)
      .firstOrNull;

  /// Tài khoản của lần trả: chọn tay, không thì tài khoản của khoản nợ (khoản
  /// nợ ghi nhớ: không qua tài khoản).
  int? _account(DebtView view) {
    if (_accountId != null) return _accountId == _none ? null : _accountId;
    return view.debt.accountId;
  }

  /// Lãi tới ngày trả còn chưa trả (tiền tệ khoản nợ).
  int _dueInterest(DebtView view) => view.interest.unpaidInterest(_date);

  /// Tự chia số tổng (đã quy về tiền tệ khoản nợ) theo lãi trước (AC-173).
  void _autoSplit(DebtView view, CurrencyService service) {
    if (!view.hasInterest || _manualSplit) return;
    final total = _amount.valueIn(context, service, view.debt.currency);
    final digits = currencyDecimalDigits(view.debt.currency);
    if (total == null) {
      _interest.clear();
      _principal.clear();
      return;
    }
    final split = view.interest.split(total, _date);
    _interest.text = amountInput(context, split.interest, digits);
    _principal.text = amountInput(context, split.principal, digits);
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(DateTime(2000)) ? _date : DateTime(2000),
      lastDate: DateTime(today.year + 10),
    );
    if (picked == null || !mounted) return;
    final view = _view();
    final service = ref.read(currencyServiceProvider).value;
    setState(() {
      _date = dateOnly(picked);
      if (view != null && service != null) _autoSplit(view, service);
    });
  }

  Future<void> _pickAccount(DebtView view, List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final memo = view.debt.accountId == null;
    final picked = await showChoiceSheet<int>(
      context,
      title: l.account,
      selected: _account(view) ?? _none,
      options: [
        for (final a in accounts)
          ChoiceOption(
            a.id,
            accountLabel(l, a),
            icon: Symbols.account_balance_wallet_rounded,
          ),
        if (memo)
          ChoiceOption(_none, l.debtNoAccount, icon: Symbols.edit_note_rounded),
      ],
    );
    if (picked != null) {
      setState(() {
        _accountId = picked.$1;
        _error = null;
      });
    }
  }

  /// "Chỉ trả lãi" / "Trả hết": điền số tổng (quy về tiền tệ đang gõ, làm
  /// tròn xuống) và hai ô Lãi/Gốc đúng tới đơn vị nhỏ nhất.
  void _fill(DebtView view, CurrencyService service, {required bool all}) {
    final digits = currencyDecimalDigits(view.debt.currency);
    final interest = _dueInterest(view);
    final principal = all ? view.principalLeft : 0;
    _amount.fill(context, service, interest + principal, view.debt.currency);
    _interest.text = amountInput(context, interest, digits);
    _principal.text = amountInput(context, principal, digits);
    _manualSplit = true;
    _error = _interestError = _principalError = null;
  }

  Future<void> _save(DebtView view) async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final debt = view.debt;
    final currency = debt.currency;
    final digits = currencyDecimalDigits(currency);
    final service = await ref.read(currencyServiceProvider.future);
    if (!mounted) return;
    final typed = _amount.value(context);
    if (typed == null || typed <= 0) {
      setState(
        () =>
            _error = _amount.controller.text.trim().isNotEmpty && typed == null
            ? l.invalidExpression
            : l.amountMustBePositive,
      );
      return;
    }
    final total = _amount.valueIn(context, service, currency);
    if (total == null) {
      setState(() => _error = l.rateMissing(_amount.currency, currency));
      return;
    }
    int interest = 0, principal = total;
    if (view.hasInterest) {
      final i = parseAmountField(context, _interest.text.trim(), digits);
      final p = parseAmountField(context, _principal.text.trim(), digits);
      if (i == null || p == null) {
        final split = view.interest.split(total, _date);
        interest = i ?? split.interest;
        principal = p ?? split.principal;
      } else {
        interest = i;
        principal = p;
      }
    }
    // Lãi ≤ lãi tới ngày trả, Gốc ≤ gốc còn lại (AC-173, AC-105); báo theo
    // tiền tệ khoản nợ.
    final due = _dueInterest(view);
    setState(() {
      _interestError = interest > due
          ? l.debtInterestOver(money(context, currency, due))
          : null;
      _principalError = view.hasInterest && principal > view.principalLeft
          ? l.debtPrincipalOver(money(context, currency, view.principalLeft))
          : null;
      _error = !view.hasInterest && principal > view.principalLeft
          ? l.debtOverpay(
              money(
                context,
                _amount.currency,
                convertDown(
                      service,
                      view.principalLeft,
                      currency,
                      _amount.currency,
                    ) ??
                    0,
              ),
            )
          : null;
    });
    if (_interestError != null || _principalError != null || _error != null) {
      return;
    }
    if (interest + principal <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    final amount = service.toPrimary(principal, currency);
    if (amount == null) {
      setState(() => _error = l.rateMissing(currency, service.primary));
      return;
    }
    _saving = true;
    try {
      await ref
          .read(debtRepositoryProvider)
          .addPayment(
            widget.debtId,
            amount: amount,
            originalAmount: principal,
            currency: currency,
            interest: interest,
            date: dateKey(_date),
            accountId: _account(view),
            service: service,
          );
    } on DebtOverpaymentException catch (e) {
      // Vượt số còn lại: báo lỗi, không lưu (AC-105).
      _saving = false;
      if (mounted) {
        setState(
          () => _error = l.debtOverpay(money(context, currency, e.remaining)),
        );
      }
      return;
    } on DebtInterestOverException catch (e) {
      _saving = false;
      if (mounted) {
        setState(
          () => _interestError = l.debtInterestOver(
            money(context, currency, e.due),
          ),
        );
      }
      return;
    } on InsufficientFundsException catch (e) {
      // Trả nợ làm tài khoản âm (AC-160).
      _saving = false;
      if (mounted) {
        setState(() => _error = shortfallMessage(context, ref, e.shortfall));
      }
      return;
    } on StateError {
      _saving = false;
      if (mounted) {
        setState(() => _error = l.rateMissing(currency, service.primary));
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ref
        .watch(debtsProvider)
        .value
        ?.where((v) => v.debt.id == widget.debtId)
        .firstOrNull;
    if (view == null) return const SizedBox(height: 120);
    final debt = view.debt;
    final today = ref.watch(todayProvider);
    final service = ref.watch(currencyServiceProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? accounts;
    final accountId = _account(view);
    final account = all.where((a) => a.id == accountId).firstOrNull;
    final lent = debt.direction == DebtDirection.lent;
    final typedCurrency = _amount.currency;
    final typed = _amount.value(context);
    // Hai phía khi khác tiền tệ (AC-167).
    final notes = <String>[];
    if (service != null && typed != null && typed > 0) {
      if (debt.currency != typedCurrency) {
        final inDebt = _amount.valueIn(context, service, debt.currency);
        if (inDebt != null) {
          notes.add(l.ledgerDebtSide(money(context, debt.currency, inDebt)));
        }
      }
      if (account != null && account.currency != typedCurrency) {
        final inAccount = _amount.valueIn(context, service, account.currency);
        if (inAccount != null) {
          final shown = money(context, account.currency, inAccount);
          notes.add(
            lent
                ? l.ledgerInto(accountLabel(l, account), shown)
                : l.ledgerFrom(accountLabel(l, account), shown),
          );
        }
      }
    }
    EdgeInsets pad([double top = VgSpace.s2]) =>
        EdgeInsets.fromLTRB(VgSpace.s4, top, VgSpace.s4, 0);
    final debtDigits = currencyDecimalDigits(debt.currency);
    Widget splitField(
      Key key,
      TextEditingController c,
      String label,
      String? error,
    ) => Expanded(
      child: TextField(
        key: key,
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        onChanged: (_) => setState(() {
          _manualSplit = true;
          _interestError = _principalError = null;
        }),
        decoration: InputDecoration(
          labelText: label,
          suffixText: currencySymbol(debt.currency),
          errorText: error,
          errorMaxLines: 3,
        ),
      ),
    );
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
                  SheetHeader(l.debtAddPayment),
                  Padding(
                    padding: pad(),
                    child: TextField(
                      key: const Key('payment-amount'),
                      controller: _amount.controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      onChanged: (_) => setState(() {
                        _error = null;
                        _manualSplit = false;
                        if (service != null) _autoSplit(view, service);
                      }),
                      decoration: InputDecoration(
                        labelText: l.debtPaymentAmount,
                        suffixText: currencySymbol(typedCurrency),
                        helperText: notes.isEmpty ? null : notes.join('\n'),
                        helperMaxLines: 3,
                        errorText: _error,
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                  if (view.hasInterest)
                    Padding(
                      padding: pad(VgSpace.s3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          splitField(
                            const Key('payment-interest'),
                            _interest,
                            l.debtPaymentInterest,
                            _interestError,
                          ),
                          const SizedBox(width: VgSpace.s3),
                          splitField(
                            const Key('payment-principal'),
                            _principal,
                            l.debtPaymentPrincipal,
                            _principalError,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: Wrap(
                      spacing: VgSpace.s2,
                      runSpacing: VgSpace.s2,
                      children: [
                        TypedCurrencyChip(
                          currency: typedCurrency,
                          onPicked: (c) => setState(() {
                            _amount.switchTo(context, c);
                            _error = null;
                            if (service != null) _autoSplit(view, service);
                          }),
                        ),
                        if (service != null &&
                            view.hasInterest &&
                            _dueInterest(view) > 0)
                          ActionChip(
                            key: const Key('payment-interest-only'),
                            avatar: const Icon(
                              Symbols.percent_rounded,
                              size: 18,
                            ),
                            label: Text(l.debtInterestOnly),
                            onPressed: () => setState(
                              () => _fill(view, service, all: false),
                            ),
                          ),
                        if (service != null)
                          ActionChip(
                            key: const Key('payment-pay-all'),
                            avatar: const Icon(
                              Symbols.select_all_rounded,
                              size: 18,
                            ),
                            label: Text(l.debtPayAll),
                            onPressed: () =>
                                setState(() => _fill(view, service, all: true)),
                          ),
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
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: pad(VgSpace.s3),
                    child: InkWell(
                      key: const Key('payment-account'),
                      borderRadius: BorderRadius.circular(VgRadius.sm),
                      onTap: () => _pickAccount(view, accounts),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.account,
                          suffixIcon: const Icon(
                            Symbols.arrow_drop_down_rounded,
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
                  if (view.hasInterest)
                    Padding(
                      padding: pad(),
                      child: Text(
                        l.debtPrincipalInterest(
                          amountInput(context, view.principalLeft, debtDigits),
                          money(context, debt.currency, _dueInterest(view)),
                        ),
                        style: VgType.bodySm.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: VgSpace.s3),
                ],
              ),
            ),
          ),
          SheetFooter(
            border: false,
            children: [
              FilledButton(
                style: sheetFilledButtonStyle(),
                onPressed: () => _save(view),
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
