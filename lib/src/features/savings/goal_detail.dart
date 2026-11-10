import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money_sum.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import 'goal_editor.dart';
import 'goal_money_sheet.dart';
import 'savings_providers.dart';
import 'savings_screen.dart';

/// Lịch sử ví của tài khoản [accountId] (AC-151), mới nhất trước.
final walletHistoryProvider = StreamProvider.family<List<Entry>, int>(
  (ref, accountId) =>
      ref.watch(savingsRepositoryProvider).watchHistory(accountId),
);

/// Chi tiết một mục tiêu (F-47, AC-151): tiến độ, Lịch sử mọi khoản của ví,
/// Góp tiền / Rút tiền, Sửa, Xoá, Mở lại. Tự đóng khi mục tiêu không còn.
Future<void> showGoalDetail(BuildContext context, int goalId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GoalDetail(goalId: goalId),
    );

class _GoalDetail extends ConsumerWidget {
  const _GoalDetail({required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(savingsGoalsProvider);
    final goal = all.value?.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) {
      if (all.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.maybePop(context);
        });
      }
      return const SizedBox(height: 120);
    }
    final progress =
        goalProgress(ref, goal) ??
        GoalProgress.of(goal, 0, ref.watch(todayProvider));
    final completed = goal.completedAt != null;
    final accounts = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final byId = {for (final a in accounts) a.id: a};
    final wallet = byId[goal.accountId];
    final history =
        ref.watch(walletHistoryProvider(goal.accountId)).value ??
        const <Entry>[];
    final have = moneyLinesText(context, ref, progress.balance, goal.currency);
    final target = moneyLinesText(context, ref, progress.target, goal.currency);
    final categories = {
      for (final type in CategoryType.values)
        for (final c in ref.watch(categoriesProvider(type)).value ?? const [])
          c.id: c,
    };

    Widget historyRow(Entry e) {
      final toWallet = e.toAccountId == goal.accountId;
      final String label;
      final int amount;
      final String currency;
      final IconData icon;
      String what() {
        final note = e.note;
        if (note != null && note.isNotEmpty) return note;
        final c = categories[e.categoryId];
        return c == null ? '' : categoryLabel(l, c);
      }

      switch (e.type) {
        case EntryType.transfer:
          if (toWallet) {
            final from = byId[e.accountId];
            label = l.savingsHistoryAdded(
              from == null ? '' : accountLabel(l, from),
            );
            amount = entryReceivedOriginal(e);
            currency = entryReceivedCurrency(e);
            icon = Symbols.add_circle_rounded;
          } else {
            final to = byId[e.toAccountId];
            label = l.savingsHistoryWithdrew(
              to == null ? '' : accountLabel(l, to),
            );
            amount = -entryOriginal(e);
            currency = e.currency;
            icon = Symbols.remove_circle_rounded;
          }
        case EntryType.expense:
          label = l.savingsHistorySpent(what());
          amount = -entryOriginal(e);
          currency = e.currency;
          icon = Symbols.shopping_bag_rounded;
        case EntryType.income:
          label = l.savingsHistoryIncome(what());
          amount = entryOriginal(e);
          currency = e.currency;
          icon = Symbols.payments_rounded;
      }
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(shortDate(context, parseDateKey(e.date))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyLines(
              amount: amount,
              currency: currency,
              style: VgType.bodyMd.copyWith(
                color: amount < 0 ? scheme.onSurface : scheme.primary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              secondaryStyle: VgType.bodySm,
              crossAxisAlignment: CrossAxisAlignment.end,
              textAlign: TextAlign.end,
            ),
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Symbols.delete_rounded),
              onPressed: () async {
                final repo = ref.read(entryRepositoryProvider);
                final removed = await repo.delete(e.id);
                if (removed == null) return;
                showUndoSnackBar(
                  message: l.deleted,
                  undoLabel: l.undo,
                  onUndo: () => repo.restore(removed),
                );
              },
            ),
          ],
        ),
      );
    }

    final startOriginal = wallet == null
        ? 0
        : wallet.initialBalanceOriginal ?? wallet.initialBalance;

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
                    child: Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (wallet != null)
                    Padding(
                      padding: const EdgeInsets.only(top: VgSpace.s1),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.account_balance_wallet_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: VgSpace.s1),
                          Expanded(
                            child: Text(
                              accountLabel(l, wallet),
                              style: VgType.bodySm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: VgSpace.s3),
                  if (completed)
                    Row(
                      children: [
                        Icon(
                          Symbols.check_circle_rounded,
                          color: scheme.primary,
                          fill: 1,
                        ),
                        const SizedBox(width: VgSpace.s2),
                        Expanded(
                          child: Text(
                            l.savingsDoneOn(
                              shortDate(
                                context,
                                parseDateKey(goal.completedAt!),
                              ),
                            ),
                            style: VgType.titleSm.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (goal.dueDate != null && !completed)
                    Text(
                      progress.overdue
                          ? l.savingsOverdue(-progress.daysToDue!)
                          : l.savingsDaysLeft(progress.daysToDue!),
                      style: VgType.bodyMd.copyWith(
                        color: progress.overdue
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                        fontWeight: progress.overdue ? FontWeight.w600 : null,
                      ),
                    ),
                  const SizedBox(height: VgSpace.s2),
                  Semantics(
                    label:
                        '${l.savingsProgress(have.main, target.main)}, ${progress.percent}%',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(VgRadius.full),
                          child: LinearProgressIndicator(
                            value: completed ? 1 : progress.fraction,
                            minHeight: 10,
                            backgroundColor: scheme.surfaceContainerHigh,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: VgSpace.s2),
                        Text(
                          '${l.savingsProgress(have.main, target.main)} · ${progress.percent}%',
                          style: VgType.titleSm.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        if (have.secondary != null && !have.missingRate)
                          Text(
                            l.savingsProgress(
                              have.secondary!,
                              target.secondary!,
                            ),
                            style: VgType.bodySm.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (!completed && !progress.reached)
                          Text(
                            l.savingsMissing(
                              moneyOneLine(
                                context,
                                ref,
                                progress.missing,
                                goal.currency,
                              ),
                            ),
                            style: VgType.bodyMd.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VgSpace.s3),
                  Wrap(
                    spacing: VgSpace.s2,
                    runSpacing: VgSpace.s2,
                    children: [
                      if (!completed)
                        FilledButton.icon(
                          icon: const Icon(Symbols.add_rounded),
                          label: Text(l.savingsContribute),
                          onPressed: () => showGoalMoneySheet(context, goal),
                        ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Symbols.remove_rounded),
                        label: Text(l.savingsWithdraw),
                        onPressed: () =>
                            showGoalMoneySheet(context, goal, withdraw: true),
                      ),
                    ],
                  ),
                  const Divider(height: VgSpace.s6),
                  Semantics(
                    header: true,
                    child: Text(
                      l.savingsHistory,
                      style: VgType.titleSm.copyWith(color: scheme.primary),
                    ),
                  ),
                  if (history.isEmpty && startOriginal == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: VgSpace.s2),
                      child: Text(
                        l.savingsHistoryEmpty,
                        style: VgType.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final e in history) historyRow(e),
                  if (startOriginal != 0 && wallet != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Symbols.savings_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      title: Text(l.savingsHistoryStart),
                      trailing: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: VgSize.tapMin,
                        ),
                        child: MoneyLines(
                          amount: startOriginal,
                          currency: wallet.initialCurrency ?? wallet.currency,
                          style: VgType.bodyMd.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          secondaryStyle: VgType.bodySm,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: VgSpace.s2),
                    child: Text(
                      l.savingsBalance(
                        moneyOneLine(
                          context,
                          ref,
                          progress.balance,
                          goal.currency,
                        ),
                      ),
                      textAlign: TextAlign.end,
                      style: VgType.bodyMd.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, VgSize.tapMin),
                        ),
                        icon: const Icon(Symbols.edit_rounded),
                        label: Text(l.savingsEdit),
                        onPressed: () => showGoalEditor(context, goal: goal),
                      ),
                      if (completed)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, VgSize.tapMin),
                          ),
                          icon: const Icon(Symbols.restart_alt_rounded),
                          label: Text(l.savingsReopen),
                          onPressed: () async {
                            await ref
                                .read(savingsRepositoryProvider)
                                .reopen(goal.id);
                            showMessage(l.savingsReopened);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: VgSpace.s3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
