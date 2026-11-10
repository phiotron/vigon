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
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import 'goal_detail.dart';
import 'goal_editor.dart';
import 'goal_money_sheet.dart';
import 'savings_providers.dart';

/// Tiến độ của một mục tiêu (AC-150): số dư ví so với mục tiêu, cùng tiền tệ
/// của mục tiêu.
class GoalProgress {
  const GoalProgress({
    required this.balance,
    required this.target,
    required this.daysToDue,
    this.completed = false,
  });

  /// Số dư ví theo tiền tệ mục tiêu (gồm số dư ban đầu), có thể âm.
  final int balance;

  /// Số tiền mục tiêu theo tiền tệ mục tiêu.
  final int target;

  /// Số ngày tới hạn (âm: quá hạn); null nếu không có hạn.
  final int? daysToDue;

  /// Đã ghi "Đã xong" (vĩnh viễn, AC-153).
  final bool completed;

  /// Số dư đã đủ mục tiêu (lúc này).
  bool get reached => balance >= target;

  /// Còn thiếu bao nhiêu, không âm.
  int get missing => reached ? 0 : target - balance;

  /// Số nguyên 0–100, làm tròn xuống: chưa đạt thì không bao giờ hiện 100%.
  int get percent =>
      balance <= 0 ? 0 : (balance * 100 ~/ target).clamp(0, 100).toInt();

  /// 0…1 cho thanh tiến độ.
  double get fraction => balance <= 0 ? 0 : (balance / target).clamp(0.0, 1.0);

  /// Quá hạn mà chưa xong.
  bool get overdue =>
      !completed && !reached && daysToDue != null && daysToDue! < 0;

  static GoalProgress of(SavingsGoal goal, int balance, DateTime today) {
    final due = goal.dueDate;
    return GoalProgress(
      balance: balance,
      target: goal.originalTargetAmount ?? goal.targetAmount,
      daysToDue: due == null
          ? null
          : parseDateKey(due).difference(today).inDays,
      completed: goal.completedAt != null,
    );
  }
}

/// Số dư ví của [goal] theo tiền tệ mục tiêu, cộng gốc rồi quy đổi một lần
/// (AC-148); null khi chưa nạp xong.
int? goalWalletBalance(WidgetRef ref, SavingsGoal goal) {
  final bags = ref.watch(accountBalanceBagsProvider).value;
  final service = ref.watch(currencyServiceProvider).value;
  if (bags == null || service == null) return null;
  return (bags[goal.accountId] ?? MoneyBag()).convertTo(service, goal.currency);
}

/// Tiến độ của [goal] (null khi chưa nạp xong).
GoalProgress? goalProgress(WidgetRef ref, SavingsGoal goal) {
  final balance = goalWalletBalance(ref, goal);
  if (balance == null) return null;
  return GoalProgress.of(goal, balance, ref.watch(todayProvider));
}

/// Màn Tiết kiệm (F-47): "Đang tiết kiệm" + "Đã xong" (thu gọn); chạm thẻ mở
/// Chi tiết; lần đầu đủ tiền thì ghi "Đã xong" và chúc mừng (AC-153).
class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  bool _showDone = false;
  final _celebrating = <int>{};

  /// Ghi "Đã xong" lần đầu rồi hiện hộp chúc mừng (AC-153).
  Future<void> _complete(SavingsGoal goal, GoalProgress progress) async {
    if (!_celebrating.add(goal.id)) return;
    try {
      // Ghi có điều kiện "chưa xong" nên chỉ lần đầu trả true (kể cả sau
      // "Mở lại" mà vẫn đủ tiền: ghi lại ngay, không chúc mừng hai lần).
      final repo = ref.read(savingsRepositoryProvider);
      final first = await repo.markCompleted(
        goal.id,
        dateKey(ref.read(todayProvider)),
      );
      if (!first || !mounted) return;
      await showGoalReachedDialog(context, ref, goal, progress.balance);
    } finally {
      _celebrating.remove(goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final goals = ref.watch(savingsGoalsProvider).value ?? const [];
    final open = <SavingsGoal>[];
    final done = <SavingsGoal>[];
    for (final g in goals) {
      final p = goalProgress(ref, g);
      if (g.completedAt != null) {
        done.add(g);
      } else {
        open.add(g);
        if (p != null && p.reached) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _complete(g, p);
          });
        }
      }
    }
    final children = <Widget>[
      if (open.isNotEmpty) _SectionTitle(l.savingsInProgress),
      for (final g in open)
        Padding(
          padding: const EdgeInsets.only(bottom: VgSpace.s3),
          child: GoalCard(goal: g),
        ),
      if (done.isNotEmpty)
        Semantics(
          button: true,
          expanded: _showDone,
          child: InkWell(
            borderRadius: BorderRadius.circular(VgRadius.md),
            onTap: () => setState(() => _showDone = !_showDone),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapKey),
              child: Row(
                children: [
                  Icon(
                    Symbols.check_circle_rounded,
                    color: scheme.primary,
                    fill: 1,
                  ),
                  const SizedBox(width: VgSpace.s3),
                  Expanded(
                    child: Text(
                      l.savingsDoneSection(done.length),
                      style: VgType.titleSm.copyWith(color: scheme.onSurface),
                    ),
                  ),
                  Icon(
                    _showDone
                        ? Symbols.expand_less_rounded
                        : Symbols.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      if (_showDone)
        for (final g in done)
          Padding(
            padding: const EdgeInsets.only(bottom: VgSpace.s3),
            child: GoalCard(goal: g),
          ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.savings)),
      body: goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.savingsEmpty,
                  textAlign: TextAlign.center,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              // Đệm đáy để nút + không che thẻ cuối.
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                88,
              ),
              children: children,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalEditor(context),
        icon: const Icon(Symbols.add_rounded),
        label: Text(l.savingsAdd, style: VgType.labelLg),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s1,
        VgSpace.s2,
        VgSpace.s1,
        VgSpace.s2,
      ),
      child: Text(
        text,
        style: VgType.titleSm.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// Hộp "Tiết kiệm thành công" (AC-153): số tiền đã đủ + nút Rút tiền.
Future<void> showGoalReachedDialog(
  BuildContext context,
  WidgetRef ref,
  SavingsGoal goal,
  int balance,
) {
  final l = AppLocalizations.of(context);
  final amount = moneyOneLine(context, ref, balance, goal.currency);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(
          Symbols.celebration_rounded,
          size: 40,
          color: scheme.primary,
          fill: 1,
        ),
        title: Text(l.savingsReachedTitle, textAlign: TextAlign.center),
        content: Text(
          l.savingsReachedBody(amount, goal.name),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showGoalMoneySheet(context, goal, withdraw: true);
            },
            child: Text(l.savingsWithdraw),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.savingsReachedOk),
          ),
        ],
      );
    },
  );
}

/// Thẻ một mục tiêu: tên, ví, trạng thái, thanh tiến độ, "Đã có X / Y" (Tiền
/// tệ chính trên, gốc dưới), "Còn thiếu Z", nút Góp tiền. Chạm → Chi tiết.
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final progress =
        goalProgress(ref, goal) ??
        GoalProgress.of(goal, 0, ref.watch(todayProvider));
    final accounts = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final wallet = accounts.where((a) => a.id == goal.accountId).firstOrNull;
    final have = moneyLinesText(context, ref, progress.balance, goal.currency);
    final target = moneyLinesText(context, ref, progress.target, goal.currency);
    final completed = goal.completedAt != null;

    // Trạng thái bằng chữ + icon, không chỉ màu.
    final (IconData icon, String text, Color color) = completed
        ? (
            Symbols.check_circle_rounded,
            l.savingsDoneOn(
              shortDate(context, parseDateKey(goal.completedAt!)),
            ),
            scheme.primary,
          )
        : progress.overdue
        ? (
            Symbols.warning_rounded,
            l.savingsOverdue(-progress.daysToDue!),
            scheme.error,
          )
        : progress.daysToDue != null
        ? (
            Symbols.schedule_rounded,
            l.savingsDaysLeft(progress.daysToDue!),
            scheme.onSurfaceVariant,
          )
        : (
            Symbols.savings_rounded,
            '${progress.percent}%',
            scheme.onSurfaceVariant,
          );

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VgRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(VgRadius.lg),
        onTap: () => showGoalDetail(context, goal.id),
        child: Padding(
          padding: const EdgeInsets.all(VgSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                goal.name,
                style: VgType.titleMd.copyWith(color: scheme.onSurface),
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
              const SizedBox(height: VgSpace.s2),
              Row(
                children: [
                  Icon(icon, size: 18, color: color, fill: 1),
                  const SizedBox(width: VgSpace.s1),
                  Expanded(
                    child: Text(
                      text,
                      style: VgType.bodyMd.copyWith(
                        color: color,
                        fontWeight: completed || progress.overdue
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VgSpace.s3),
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
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHigh,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: VgSpace.s2),
                    Text(
                      l.savingsProgress(have.main, target.main),
                      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                    ),
                    if (have.secondary != null && !have.missingRate)
                      Text(
                        l.savingsProgress(have.secondary!, target.secondary!),
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
                        style: VgType.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!completed) ...[
                const SizedBox(height: VgSpace.s3),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Symbols.add_rounded),
                    label: Text(l.savingsContribute),
                    onPressed: () => showGoalMoneySheet(context, goal),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
