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
import '../../ui/confirm_dialog.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../categories/sheet_footer.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import 'debt_editor.dart';
import 'debts_providers.dart';
import 'debts_screen.dart' show isDebtOverdue;

/// Chi tiết một khoản nợ (AC-105): thông tin, các lần trả (xoá được), "Thêm
/// lần trả", sửa, xoá. Tự đóng khi khoản nợ không còn.
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
          if (context.mounted) Navigator.maybePop(context);
        });
      }
      return const SizedBox(height: 120);
    }
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final today = ref.watch(todayProvider);
    final d = view.debt;
    final settled = view.isSettled(digits);
    final overdue = isDebtOverdue(view, today, digits);

    Widget line(
      String label,
      String value, {
      Color? color,
      bool bold = false,
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
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: VgType.bodyMd.copyWith(
                color: color ?? scheme.onSurface,
                fontWeight: bold ? FontWeight.w600 : null,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
                  line(
                    l.debtDirection,
                    d.direction == DebtDirection.lent
                        ? l.debtLent
                        : l.debtBorrowed,
                  ),
                  line(l.debtAmount, money(context, currency, d.amount)),
                  line(l.debtDate, shortDate(context, parseDateKey(d.date))),
                  if (d.dueDate != null)
                    line(
                      overdue ? l.debtOverdue : l.debtDue,
                      shortDate(context, parseDateKey(d.dueDate!)),
                      color: overdue ? scheme.error : null,
                      bold: overdue,
                    ),
                  if (d.note != null) line(l.noteHint, d.note!),
                  const Divider(height: VgSpace.s6),
                  if (settled)
                    Row(
                      children: [
                        Icon(
                          Symbols.check_circle_rounded,
                          color: scheme.primary,
                          fill: 1,
                        ),
                        const SizedBox(width: VgSpace.s2),
                        Text(
                          l.debtDone,
                          style: VgType.titleSm.copyWith(color: scheme.primary),
                        ),
                      ],
                    )
                  else
                    line(
                      l.debtRemainingLabel,
                      money(context, currency, view.remaining(digits)),
                      bold: true,
                    ),
                  const SizedBox(height: VgSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(
                      l.debtPayments,
                      style: VgType.titleSm.copyWith(color: scheme.primary),
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
                      title: Text(
                        money(context, currency, p.amount),
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      subtitle: Text(shortDate(context, parseDateKey(p.date))),
                      trailing: IconButton(
                        tooltip: l.debtDeletePayment,
                        icon: const Icon(Symbols.delete_rounded),
                        onPressed: () => ref
                            .read(debtRepositoryProvider)
                            .deletePayment(p.id),
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
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
                        onPressed: () => _delete(context, ref),
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

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.delete_rounded,
      title: l.debtDeleteTitle,
      body: l.debtDeleteBody,
      action: l.delete,
      style: ConfirmStyle.danger,
    );
    if (!ok || !context.mounted) return;
    await ref.read(debtRepositoryProvider).delete(debtId);
    if (!context.mounted) return;
    Navigator.pop(context);
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

/// Thêm lần trả: số tiền > 0 và không vượt số còn lại (báo lỗi, AC-105), ngày.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.debtId});

  final int debtId;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _amount = TextEditingController();
  late DateTime _date = ref.read(todayProvider);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(DateTime(2000)) ? _date : DateTime(2000),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final currency = ref.read(currencyProvider).value ?? 'VND';
    final text = _amount.text.trim();
    final amount = text.isEmpty
        ? null
        : parseAmountField(context, text, currencyDecimalDigits(currency));
    if (amount == null || amount <= 0) {
      setState(
        () => _error = text.isNotEmpty && amount == null
            ? l.invalidExpression
            : l.amountMustBePositive,
      );
      return;
    }
    _saving = true;
    try {
      await ref
          .read(debtRepositoryProvider)
          .addPayment(widget.debtId, amount: amount, date: dateKey(_date));
    } on DebtOverpaymentException catch (e) {
      // Vượt số còn lại: báo lỗi, không lưu (AC-105).
      _saving = false;
      if (mounted) {
        setState(
          () => _error = l.debtOverpay(money(context, currency, e.remaining)),
        );
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final today = ref.watch(todayProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(l.debtAddPayment),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s2,
              VgSpace.s4,
              0,
            ),
            child: TextField(
              controller: _amount,
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
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l.debtPaymentAmount,
                suffixText: currencySymbol(currency),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s3,
              VgSpace.s4,
              VgSpace.s3,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionChip(
                avatar: const Icon(Symbols.calendar_today_rounded, size: 18),
                label: Text(
                  _date == today ? l.today : shortDate(context, _date),
                ),
                tooltip: l.debtDate,
                onPressed: _pickDate,
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
