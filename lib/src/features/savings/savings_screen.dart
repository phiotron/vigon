import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money_sum.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/money_lines.dart';
import '../../ui/status.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../reminder/deadline_reminders.dart';
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

/// Số dư ví của [goal] quy MỘT lần từ tổng gốc sang Tiền tệ chính (AC-148),
/// không qua số đã làm tròn theo tiền tệ mục tiêu: dòng chính của thẻ khớp
/// đúng thẻ tổng "Ví tiết kiệm" (lỗi lệch 37 ₫: hai chỗ làm tròn khác nhau).
int? goalWalletPrimary(WidgetRef ref, SavingsGoal goal) {
  final bags = ref.watch(accountBalanceBagsProvider).value;
  final service = ref.watch(currencyServiceProvider).value;
  if (bags == null || service == null) return null;
  return (bags[goal.accountId] ?? MoneyBag()).convertTo(
    service,
    service.primary,
  );
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
      _SavingsHero(goals: goals),
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
    final have = moneyLinesText(
      context,
      ref,
      progress.balance,
      goal.currency,
      primaryAmount: goalWalletPrimary(ref, goal),
    );
    final target = moneyLinesText(context, ref, progress.target, goal.currency);
    final completed = goal.completedAt != null;

    // Chip trạng thái bên phải (mockup v4 SCR-41): còn N ngày (trung tính) ·
    // Đã xong ✓ (xanh) · quá hạn (hổ phách). Luôn icon + chữ.
    final (IconData icon, String text, StatusTone tone) = completed
        ? (
            Symbols.check_circle_rounded,
            l.savingsDoneOn(
              shortDate(context, parseDateKey(goal.completedAt!)),
            ),
            StatusTone.ok,
          )
        : progress.overdue
        ? (
            Symbols.schedule_rounded,
            l.savingsOverdue(-progress.daysToDue!),
            StatusTone.warn,
          )
        : progress.daysToDue != null
        ? (
            Symbols.event_rounded,
            l.savingsDaysLeft(progress.daysToDue!),
            StatusTone.neutral,
          )
        : (Symbols.savings_rounded, '', StatusTone.neutral);
    // Nhắc trước hạn chung (D-044): hiện "Trước N ngày" khi bật và mục còn hạn.
    final remindOn = ref.watch(deadlineReminderEnabledProvider).value ?? false;
    final remindDays = ref.watch(deadlineReminderDaysProvider).value;
    final showRemind =
        !completed &&
        remindOn &&
        remindDays != null &&
        progress.daysToDue != null &&
        !progress.overdue;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeadIcon(icon: Symbols.savings_rounded),
                  const SizedBox(width: VgSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: VgType.titleSm.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          wallet == null
                              ? l.savingsWallet
                              : '${l.savingsWallet} · ${wallet.currency}',
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(width: VgSpace.s2),
                    Flexible(
                      child: StatusChip(label: text, icon: icon, tone: tone),
                    ),
                  ],
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
                        // Thanh theo số dư ví thật, kể cả khi đã rút sau Đã
                        // xong — chip "Đã xong" giữ trạng thái (D-043).
                        value: progress.fraction,
                        minHeight: 8,
                        backgroundColor: scheme.surfaceContainerHigh,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: VgSpace.s2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.savingsProgress(have.main, target.main),
                            style: VgType.bodySm.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${progress.percent}%',
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (have.secondary != null && !have.missingRate)
                      Text(
                        l.savingsProgress(have.secondary!, target.secondary!),
                        style: VgType.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (!completed && !progress.reached)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.savingsMissing(
                                moneyOneLine(
                                  context,
                                  ref,
                                  progress.missing,
                                  goal.currency,
                                ),
                              ),
                              style: VgType.bodySm.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (showRemind) ...[
                            Icon(
                              Symbols.notifications_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                l.remindDays(remindDays),
                                style: VgType.bodySm.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (!completed) ...[
                const SizedBox(height: VgSpace.s3),
                Align(
                  alignment: AlignmentDirectional.centerStart,
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

/// Icon đầu thẻ (`.lead`): tròn 40, nền secondary-container.
class _LeadIcon extends StatelessWidget {
  const _LeadIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: scheme.onSecondaryContainer),
    );
  }
}

/// Thẻ "Ví tiết kiệm · Tổng theo USD" đầu màn (mockup v4 SCR-41 `.ov-hero`):
/// cộng số dư mọi ví mục tiêu theo tiền tệ gốc rồi quy đổi MỘT lần (AC-148).
class _SavingsHero extends ConsumerWidget {
  const _SavingsHero({required this.goals});

  final List<SavingsGoal> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final service = ref.watch(currencyServiceProvider).value;
    final bags = ref.watch(accountBalanceBagsProvider).value;
    if (service == null || bags == null || goals.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = MoneyBag();
    for (final id in {for (final g in goals) g.accountId}) {
      final bag = bags[id];
      if (bag != null) total.addBag(bag);
    }
    final primary = service.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: VgSpace.s3),
      child: Container(
        padding: const EdgeInsets.all(VgSpace.s4),
        decoration: BoxDecoration(
          color: context.vg.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VgRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.savingsWallet} · ${l.totalInMain(primary)}',
              style: VgType.bodySm.copyWith(color: muted),
            ),
            const SizedBox(height: VgSpace.s1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                money(context, primary, total.convertTo(service, primary) ?? 0),
                style: VgType.amountXl.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: VgSpace.s1),
            Text(
              l.walletBalanceNote,
              style: VgType.bodySm.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
