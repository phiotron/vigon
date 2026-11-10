import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/recurring_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import '../../data/repeat.dart';
import 'repeat_picker.dart';
import 'rule_sheet.dart';

/// Danh sách chuỗi định kỳ: dừng, chạy lại, sửa số tiền (AC-25).
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final rules =
        ref.watch(recurringRulesProvider).value ?? const <RecurringRule>[];
    final categories = {
      for (final type in CategoryType.values)
        for (final c
            in ref.watch(categoriesProvider(type)).value ?? const <Category>[])
          c.id: c,
    };
    final repo = ref.read(recurringRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    return Scaffold(
      appBar: AppBar(title: Text(l.recurring)),
      body: rules.isEmpty
          // Trống (7.3): lời nhắc giữa màn.
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.noRecurring,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              children: [
                for (final r in rules)
                  _RuleTile(
                    rule: r,
                    weekStart: weekStart,
                    category: categories[r.categoryId],
                    amount: MoneyLines(
                      amount: r.originalAmount ?? r.amount,
                      currency: r.currency,
                      style: VgType.bodyMd,
                    ),
                    onToggle: (on) => on
                        ? repo.resume(r.id, ref.read(clockProvider)())
                        : repo.stop(r.id),
                    onTap: () => _edit(context, ref, r),
                  ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    RecurringRule rule,
  ) async {
    final categories = switch (rule.type) {
      EntryType.transfer => const <Category>[],
      EntryType.income =>
        ref.read(categoriesProvider(CategoryType.income)).value,
      EntryType.expense =>
        ref.read(categoriesProvider(CategoryType.expense)).value,
    };
    // 7.2 → bảng toàn màn SCR-21.
    final saved = await showRuleSheet(
      context,
      rule: rule,
      categories: categories ?? const <Category>[],
      accounts: ref.read(accountsProvider).value ?? const <Account>[],
      weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
    );
    if (saved == null) return;
    // Số nhập là số gốc theo tiền tệ của chuỗi; cột `amount` là số dẫn xuất
    // quy về Tiền tệ chính (D-037).
    final service = await ref.read(currencyServiceProvider.future);
    final amount = service.toPrimary(saved.amount, saved.currency);
    if (amount == null) {
      if (context.mounted) {
        showMessage(
          AppLocalizations.of(context)
              .rateMissing(saved.currency, service.primary),
        );
      }
      return;
    }
    await ref
        .read(recurringRepositoryProvider)
        .edit(
          rule.id,
          amount: amount,
          originalAmount: saved.amount,
          currency: saved.currency,
          note: saved.note,
          frequency: saved.frequency,
          weekdays: saved.weekdays,
          categoryId: saved.categoryId,
          accountId: saved.accountId,
        );
  }
}

/// Một chuỗi (7.1): icon danh mục, "Tên chuỗi · số tiền", "Tần suất · ngày
/// tới hạn" hoặc "Đã dừng", công tắc; chạm dòng để sửa.
class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.weekStart,
    required this.category,
    required this.amount,
    required this.onToggle,
    required this.onTap,
  });

  final RecurringRule rule;
  final int weekStart;
  final Category? category;
  final Widget amount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repeat = repeatText(l, Repeat.of(rule), weekStart: weekStart);
    // Tên chuỗi = ghi chú nếu có, không thì tên danh mục — giống đầu bảng
    // sửa (SCR-21) và danh sách nền trong frame 21 ("Rent · ₫3,500,000").
    final note = rule.note?.trim() ?? '';
    final name = note.isNotEmpty
        ? note
        : category == null
        ? l.transfer
        : categoryLabel(l, category!);
    return ListTile(
      leading: category == null
          ? const SizedBox(
              width: 40,
              child: Center(child: Icon(Symbols.event_repeat_rounded)),
            )
          : CategoryAvatar(category: category!, size: 40),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rule.active
                ? '$repeat · '
                      '${shortDate(context, RecurringRepository.nextDate(rule))}'
                : '$repeat · ${l.repeatStopped}',
          ),
          // Số gốc theo tiền tệ của chuỗi, dưới là "≈ Tiền tệ chính" (D-037).
          amount,
        ],
      ),
      // Công tắc đọc tên chuỗi để TalkBack biết đang bật/tắt chuỗi nào.
      trailing: Semantics(
        label: name,
        child: Switch(value: rule.active, onChanged: onToggle),
      ),
      onTap: onTap,
    );
  }
}
