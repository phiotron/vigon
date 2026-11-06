import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import 'goal_editor.dart';
import 'savings_providers.dart';

/// Tiến độ của một mục tiêu (AC-101): số dư của tài khoản gắn so với mục tiêu.
class GoalProgress {
  const GoalProgress({
    required this.balance,
    required this.target,
    required this.daysToDue,
  });

  /// Số dư hiện tại của tài khoản gắn (gồm số dư ban đầu), có thể âm.
  final int balance;
  final int target;

  /// Số ngày tới hạn (âm: quá hạn); null nếu không có hạn.
  final int? daysToDue;

  /// "Đã đạt": số dư ≥ mục tiêu. Rút tiền làm số dư giảm thì mất (AC-101).
  bool get reached => balance >= target;

  /// Còn thiếu bao nhiêu, không âm.
  int get missing => reached ? 0 : target - balance;

  /// Số nguyên 0–100, làm tròn xuống: chưa đạt thì không bao giờ hiện 100%.
  int get percent =>
      balance <= 0 ? 0 : (balance * 100 ~/ target).clamp(0, 100).toInt();

  /// 0…1 cho thanh tiến độ.
  double get fraction => balance <= 0 ? 0 : (balance / target).clamp(0.0, 1.0);

  /// Quá hạn mà chưa đạt (AC-101).
  bool get overdue => !reached && daysToDue != null && daysToDue! < 0;

  static GoalProgress of(SavingsGoal goal, int balance, DateTime today) {
    final due = goal.dueDate;
    return GoalProgress(
      balance: balance,
      target: goal.targetAmount,
      daysToDue: due == null
          ? null
          : parseDateKey(due).difference(today).inDays,
    );
  }
}

/// Màn Tiết kiệm (F-33, AC-100..AC-103): danh sách mục tiêu với tiến độ,
/// "Góp tiền", thêm/sửa/xoá. Dựng tạm bằng component Hi-Fi hiện có; bản vẽ của
/// Claude Design (phiên điều phối #4) thay sau.
class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final goals = ref.watch(savingsGoalsProvider).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
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
          : ListView.builder(
              // Đệm đáy để nút + không che thẻ cuối.
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                88,
              ),
              itemCount: goals.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: VgSpace.s3),
                child: GoalCard(goal: goals[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalEditor(context),
        icon: const Icon(Symbols.add_rounded),
        label: Text(l.savingsAdd, style: VgType.labelLg),
      ),
    );
  }
}

/// Thẻ một mục tiêu: tên, trạng thái, thanh tiến độ, "Đã có X / Y", "Còn thiếu
/// Z", nút "Góp tiền" (AC-101, AC-102).
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final balances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    final accounts = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final account = accounts.where((a) => a.id == goal.accountId).firstOrNull;
    final balance = balances[goal.accountId] ?? account?.initialBalance ?? 0;
    final progress = GoalProgress.of(goal, balance, ref.watch(todayProvider));
    final have = money(context, currency, balance);
    final target = money(context, currency, goal.targetAmount);

    // Trạng thái bằng chữ + icon, không chỉ màu (AC-101).
    final (IconData icon, String text, Color color) = progress.reached
        ? (Symbols.check_circle_rounded, l.savingsReached, scheme.primary)
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
      child: Padding(
        padding: const EdgeInsets.all(VgSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: VgSpace.s3),
                    child: Text(
                      goal.name,
                      style: VgType.titleMd.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.savingsEdit,
                  icon: const Icon(Symbols.edit_rounded),
                  onPressed: () => showGoalEditor(context, goal: goal),
                ),
              ],
            ),
            const SizedBox(height: VgSpace.s1),
            Row(
              children: [
                Icon(icon, size: 18, color: color, fill: 1),
                const SizedBox(width: VgSpace.s1),
                Expanded(
                  child: Text(
                    text,
                    style: VgType.bodyMd.copyWith(
                      color: color,
                      fontWeight: progress.reached || progress.overdue
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VgSpace.s3),
            Semantics(
              label: '${l.savingsProgress(have, target)}, ${progress.percent}%',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VgRadius.full),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHigh,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: VgSpace.s2),
                  Text(
                    l.savingsProgress(have, target),
                    style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                  ),
                  if (!progress.reached)
                    Text(
                      l.savingsMissing(
                        money(context, currency, progress.missing),
                      ),
                      style: VgType.bodySm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: VgSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                icon: const Icon(Symbols.add_rounded),
                label: Text(l.savingsContribute),
                onPressed: () => _contribute(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Góp tiền" (AC-102): màn Chuyển tiền với Đến = tài khoản của mục tiêu.
  /// Cần có ít nhất một tài khoản hiện khác để chuyển từ đó.
  Future<void> _contribute(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final visible = ref.read(accountsProvider).value ?? const <Account>[];
    if (!visible.any((a) => a.id != goal.accountId)) {
      showMessage(l.savingsNeedOtherAccount);
      return;
    }
    await context.push('/transfer?to=${goal.accountId}');
  }
}
