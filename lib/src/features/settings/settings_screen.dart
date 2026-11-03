import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import 'budget_dialog.dart';

/// Cài đặt (AC-12, AC-21, AC-35, AC-36 và các mục G4–G6).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.watch(settingsRepositoryProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeCode = ref.watch(localeCodeProvider).value ?? '';
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    final monthStartDay = ref.watch(monthStartDayProvider).value ?? 1;
    final budget = ref.watch(budgetProvider).value;
    final titleStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: Theme.of(context).colorScheme.primary);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(header: true, child: Text(text, style: titleStyle)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header(l.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.themeLight),
                ),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => repo.setThemeMode(s.single),
            ),
          ),
          header(l.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: '', label: Text(l.languageSystem)),
                const ButtonSegment(value: 'vi', label: Text('Tiếng Việt')),
                const ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {localeCode},
              onSelectionChanged: (s) =>
                  repo.setLocaleCode(s.single.isEmpty ? null : s.single),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l.categories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l.accounts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/accounts'),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: Text(l.budget),
            subtitle: Text(
              budget == null
                  ? l.budgetNotSet
                  : money(context, currency, budget),
            ),
            onTap: () => showBudgetDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(l.recurring),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recurring'),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l.currency),
            subtitle: Text(_currencyLabel(currency)),
            onTap: () => _pickCurrency(context, ref, currency),
          ),
          ListTile(
            leading: const Icon(Icons.view_week_outlined),
            title: Text(l.weekStart),
            subtitle: Text(weekStart == DateTime.sunday ? l.sunday : l.monday),
            onTap: () => repo.setWeekStart(
              weekStart == DateTime.sunday ? DateTime.monday : DateTime.sunday,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(l.monthStartDay),
            trailing: DropdownButton<int>(
              value: monthStartDay,
              underline: const SizedBox.shrink(),
              items: [
                for (var d = 1; d <= 28; d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (d) => d == null ? null : repo.setMonthStartDay(d),
            ),
          ),
        ],
      ),
    );
  }

  static String _currencyLabel(String code) {
    final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
    return symbol == code ? code : '$code · $symbol';
  }

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l = AppLocalizations.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.currency),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.currencyNote),
          ),
          for (final code in supportedCurrencies)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, code),
              child: Row(
                children: [
                  Expanded(child: Text(_currencyLabel(code))),
                  if (code == current) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null && picked != current) {
      await changeCurrency(ref.read(databaseProvider), picked);
    }
  }
}
