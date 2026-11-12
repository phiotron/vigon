import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import '../../data/balance_guard.dart';
import '../../data/rate_repository.dart';
import '../entry/ledger_guard.dart';
import '../entry/typed_amount.dart';
import '../categories/sheet_footer.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import 'savings_screen.dart';

/// Bảng **Góp tiền** (vào ví, ≤ số còn thiếu) hoặc **Rút tiền** (ra khỏi ví,
/// ≤ số dư ví) của một mục tiêu (F-47, AC-152). Lưu ra một chuyển tiền bình
/// thường; khác tiền tệ thì tính số gửi/nhận theo tỷ giá hiện tại.
Future<void> showGoalMoneySheet(
  BuildContext context,
  SavingsGoal goal, {
  bool withdraw = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _GoalMoneySheet(goal: goal, withdraw: withdraw),
  ),
);

class _GoalMoneySheet extends ConsumerStatefulWidget {
  const _GoalMoneySheet({required this.goal, required this.withdraw});

  final SavingsGoal goal;
  final bool withdraw;

  @override
  ConsumerState<_GoalMoneySheet> createState() => _GoalMoneySheetState();
}

class _GoalMoneySheetState extends ConsumerState<_GoalMoneySheet> {
  /// Ô số tiền theo Tiền tệ chính + chip (D-048, AC-167).
  late final _amount = TypedAmount(ref.read(currencyProvider).value ?? 'USD');
  late DateTime _date = ref.read(todayProvider);
  int? _otherId;
  String? _error;
  bool _saving = false;

  SavingsGoal get goal => widget.goal;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Giới hạn theo tiền tệ mục tiêu: góp ≤ còn thiếu, rút ≤ số dư ví.
  int _limit(GoalProgress p) =>
      widget.withdraw ? (p.balance < 0 ? 0 : p.balance) : p.missing;

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickAccount(List<Account> others) async {
    final l = AppLocalizations.of(context);
    final balances =
        ref.read(accountOwnBalancesProvider).value ?? const <int, int>{};
    final primaryBalances =
        ref.read(accountBalancesProvider).value ?? const <int, int>{};
    final picked = await showChoiceSheet<int>(
      context,
      title: widget.withdraw ? l.savingsToAccount : l.savingsFromAccount,
      selected: _otherId ?? others.first.id,
      options: [
        for (final a in others)
          ChoiceOption(
            a.id,
            '${accountLabel(l, a)} · ${moneyOneLine(context, ref, balances[a.id] ?? 0, a.currency, primaryAmount: primaryBalances[a.id])}',
            icon: Symbols.account_balance_wallet_rounded,
          ),
      ],
    );
    if (picked != null) setState(() => _otherId = picked.$1);
  }

  /// Số đã gõ (tiền tệ đang gõ) quy về hai phía: số trừ ở tài khoản gửi, số
  /// vào ở tài khoản nhận; "Điền đủ"/"Rút hết" chưa sửa thì phía ví đúng
  /// bằng giới hạn (D-048).
  ({int sent, int received})? _sides(
    CurrencyService service,
    Account from,
    Account to,
    Account wallet,
  ) {
    final sent = _amount.valueIn(
      context,
      service,
      from.currency,
      fillTarget: from.id == wallet.id ? goal.currency : null,
    );
    final received = _amount.valueIn(
      context,
      service,
      to.currency,
      fillTarget: to.id == wallet.id ? goal.currency : null,
    );
    if (sent == null || received == null) return null;
    return (sent: sent, received: received);
  }

  Future<void> _save(
    GoalProgress progress,
    Account other,
    Account wallet,
  ) async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final typedCurrency = _amount.currency;
    final value = _amount.value(context);
    final service = await ref.read(currencyServiceProvider.future);
    if (!mounted) return;
    if (value == null || value <= 0) {
      setState(
        () =>
            _error = _amount.controller.text.trim().isNotEmpty && value == null
            ? l.invalidExpression
            : l.amountMustBePositive,
      );
      return;
    }
    // Giới hạn so bằng số gốc theo tiền tệ mục tiêu (D-048), báo theo tiền
    // tệ đang gõ (làm tròn xuống).
    final limit = _limit(progress);
    final inGoal = _amount.valueIn(context, service, goal.currency);
    if (inGoal == null) {
      setState(() => _error = l.rateMissing(typedCurrency, goal.currency));
      return;
    }
    if (inGoal > limit) {
      final cap = money(
        context,
        typedCurrency,
        convertDown(service, limit, goal.currency, typedCurrency) ?? 0,
      );
      setState(
        () => _error = widget.withdraw
            ? l.savingsOverBalance(cap)
            : l.savingsOverTarget(cap),
      );
      return;
    }
    final from = widget.withdraw ? wallet : other;
    final to = widget.withdraw ? other : wallet;
    // Lưu số gốc theo tiền tệ từng tài khoản như AC-132.
    final sides = _sides(service, from, to, wallet);
    final sentDerived = sides == null
        ? null
        : service.toPrimary(sides.sent, from.currency);
    final receivedDerived = sides == null
        ? null
        : service.toPrimary(sides.received, to.currency);
    if (sides == null || sentDerived == null || receivedDerived == null) {
      setState(() => _error = l.rateMissing(typedCurrency, from.currency));
      return;
    }
    // Có thu mới có chi (AC-160): góp → tài khoản nguồn, rút → ví.
    final short = await BalanceGuard(ref.read(databaseProvider), service).check(
      add: [
        (accountId: from.id, currency: from.currency, minor: -sides.sent),
        (accountId: to.id, currency: to.currency, minor: sides.received),
      ],
    );
    if (!mounted) return;
    if (short != null) {
      setState(() => _error = shortfallMessage(context, ref, short));
      return;
    }
    _saving = true;
    final cross = from.currency != to.currency;
    await ref
        .read(entryRepositoryProvider)
        .addTransfer(
          fromAccountId: from.id,
          toAccountId: to.id,
          amount: sentDerived,
          originalAmount: sides.sent,
          currency: from.currency,
          toAmount: cross ? receivedDerived : null,
          toOriginalAmount: cross ? sides.received : null,
          toCurrency: cross ? to.currency : null,
          date: dateKey(_date),
        );
    if (!mounted) return;
    final shown = moneyOneLine(context, ref, value, typedCurrency);
    Navigator.pop(context);
    showMessage(
      widget.withdraw ? l.savingsWithdrawn(shown) : l.savingsAdded(shown),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final progress =
        goalProgress(ref, goal) ??
        GoalProgress.of(goal, 0, ref.watch(todayProvider));
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? accounts;
    final wallet = all.where((a) => a.id == goal.accountId).firstOrNull;
    final others = [
      for (final a in accounts)
        if (a.id != goal.accountId) a,
    ];
    final other =
        others.where((a) => a.id == _otherId).firstOrNull ?? others.firstOrNull;
    final limit = _limit(progress);
    final today = ref.watch(todayProvider);
    final service = ref.watch(currencyServiceProvider).value;
    final typedCurrency = _amount.currency;
    final typed = _amount.value(context);
    // Số đã gõ theo tiền tệ mục tiêu (để xem trước tiến độ).
    final typedInGoal = service == null
        ? null
        : _amount.valueIn(context, service, goal.currency);
    // Hai dòng ghi rõ hai phía khi khác tiền tệ (AC-167): "Vào ví: 19,23 $"
    // · "Trừ từ Tiền mặt: 500.000 ₫".
    String? sidesNote;
    if (typed != null &&
        typed > 0 &&
        other != null &&
        wallet != null &&
        service != null &&
        (wallet.currency != typedCurrency || other.currency != typedCurrency)) {
      final from = widget.withdraw ? wallet : other;
      final to = widget.withdraw ? other : wallet;
      final sides = _sides(service, from, to, wallet);
      if (sides != null) {
        final walletLine = money(
          context,
          wallet.currency,
          widget.withdraw ? sides.sent : sides.received,
        );
        final otherLine = money(
          context,
          other.currency,
          widget.withdraw ? sides.received : sides.sent,
        );
        sidesNote = widget.withdraw
            ? '${l.ledgerOutOfWallet(walletLine)}\n'
                  '${l.ledgerInto(accountLabel(l, other), otherLine)}'
            : '${l.ledgerIntoWallet(walletLine)}\n'
                  '${l.ledgerFrom(accountLabel(l, other), otherLine)}';
      }
    }
    // Giới hạn theo tiền tệ đang gõ, làm tròn xuống (D-048).
    final limitTyped = service == null
        ? null
        : convertDown(service, limit, goal.currency, typedCurrency);
    final title = widget.withdraw ? l.savingsWithdraw : l.savingsContribute;
    if (other == null || wallet == null) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title),
            Padding(
              padding: const EdgeInsets.all(VgSpace.s4),
              child: Text(
                widget.withdraw
                    ? l.queueNoOtherAccount
                    : l.savingsNeedOtherAccount,
                style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    final ownBalances =
        ref.watch(accountOwnBalancesProvider).value ?? const <int, int>{};
    final primaryBalances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    EdgeInsets pad([double top = VgSpace.s2]) =>
        EdgeInsets.fromLTRB(VgSpace.s4, top, VgSpace.s4, 0);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title),
          Padding(
            padding: pad(),
            child: Text(
              goal.name,
              style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: pad(VgSpace.s3),
            child: TextField(
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
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l.savingsMoveAmount,
                suffixText: currencySymbol(typedCurrency),
                helperText: sidesNote,
                helperMaxLines: 4,
                errorText: _error,
                errorMaxLines: 3,
              ),
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
                  }),
                ),
                if (limit > 0 && limitTyped != null && service != null)
                  ActionChip(
                    avatar: Icon(
                      widget.withdraw
                          ? Symbols.select_all_rounded
                          : Symbols.flag_rounded,
                      size: 18,
                    ),
                    label: Text(
                      '${widget.withdraw ? l.savingsWithdrawAll : l.savingsFillToTarget} · ${money(context, typedCurrency, limitTyped)}',
                    ),
                    onPressed: () => setState(() {
                      _amount.fill(context, service, limit, goal.currency);
                      _error = null;
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Symbols.calendar_today_rounded, size: 18),
                  label: Text(
                    _date == today ? l.today : shortDate(context, _date),
                  ),
                  tooltip: l.debtDate,
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
          Padding(
            padding: pad(VgSpace.s3),
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label:
                  '${widget.withdraw ? l.savingsToAccount : l.savingsFromAccount}: ${accountLabel(l, other)}',
              onTap: () => _pickAccount(others),
              child: InkWell(
                borderRadius: BorderRadius.circular(VgRadius.sm),
                onTap: () => _pickAccount(others),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.withdraw
                        ? l.savingsToAccount
                        : l.savingsFromAccount,
                    suffixIcon: const Icon(Symbols.arrow_drop_down_rounded),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(accountLabel(l, other))),
                      MoneyLines(
                        amount: ownBalances[other.id] ?? 0,
                        currency: other.currency,
                        primaryAmount: primaryBalances[other.id],
                        style: VgType.bodyMd.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        secondaryStyle: VgType.bodySm,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Thẻ xem trước tiến độ sau lần góp / rút này (mockup v4 SCR-41
          // add-money): thanh và "Đã có X / Y" tính theo số vừa gõ.
          Padding(
            padding: pad(VgSpace.s3),
            child: Builder(
              builder: (context) {
                final delta = (typedInGoal ?? 0).clamp(0, limit);
                final after = widget.withdraw
                    ? progress.balance - delta
                    : progress.balance + delta;
                final fraction = progress.target <= 0
                    ? 0.0
                    : (after / progress.target).clamp(0.0, 1.0);
                final percent = progress.target <= 0
                    ? 0
                    : (after * 100 / progress.target).floor().clamp(0, 999);
                return Container(
                  padding: const EdgeInsets.all(VgSpace.s3),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VgRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Symbols.savings_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: VgSpace.s2),
                          Expanded(
                            child: Text(
                              '${l.savingsWallet} · ${goal.currency}',
                              style: VgType.bodySm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: VgType.bodySm.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VgSpace.s2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VgRadius.full),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHigh,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: VgSpace.s1),
                      Text(
                        l.savingsProgress(
                          money(context, goal.currency, after),
                          money(context, goal.currency, progress.target),
                        ),
                        style: VgType.bodySm.copyWith(color: scheme.onSurface),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: VgSpace.s3),
          SheetFooter(
            border: false,
            children: [
              FilledButton(
                style: sheetFilledButtonStyle(),
                onPressed: limit <= 0
                    ? null
                    : () => _save(progress, other, wallet),
                child: Text(title),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
