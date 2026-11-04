import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../lock/app_lock.dart';
import 'budget_dialog.dart';
import 'data_actions.dart';

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
    final pinEnabled = ref.watch(pinEnabledProvider).value ?? false;
    // Chữ lớn thì xếp dọc các lựa chọn để không cắt chữ (AC-38).
    final segmentDirection = isLargeText(context)
        ? Axis.vertical
        : Axis.horizontal;
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
              direction: segmentDirection,
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
              direction: segmentDirection,
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
            leading: const Icon(Symbols.category_rounded),
            title: Text(l.categories),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => context.push('/categories'),
          ),
          ListTile(
            leading: const Icon(Symbols.account_balance_wallet_rounded),
            title: Text(l.accounts),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => context.push('/accounts'),
          ),
          ListTile(
            leading: const Icon(Symbols.savings_rounded),
            title: Text(l.budget),
            subtitle: Text(
              budget == null
                  ? l.budgetNotSet
                  : money(context, currency, budget),
            ),
            onTap: () => showBudgetDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Symbols.repeat_rounded),
            title: Text(l.recurring),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => context.push('/recurring'),
          ),
          ListTile(
            leading: const Icon(Symbols.payments_rounded),
            title: Text(l.currency),
            subtitle: Text(_currencyLabel(currency)),
            onTap: () => _pickCurrency(context, ref, currency),
          ),
          ListTile(
            leading: const Icon(Symbols.view_week_rounded),
            title: Text(l.weekStart),
            subtitle: Text(weekStart == DateTime.sunday ? l.sunday : l.monday),
            onTap: () => repo.setWeekStart(
              weekStart == DateTime.sunday ? DateTime.monday : DateTime.sunday,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.calendar_month_rounded),
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
          header(l.security),
          SwitchListTile(
            secondary: const Icon(Symbols.lock_rounded),
            title: Text(l.pinLock),
            subtitle: Text(l.pinWarning),
            value: pinEnabled,
            onChanged: (on) =>
                on ? setupPin(context, ref) : disablePin(context, ref),
          ),
          header(l.dataSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l.backupReminder),
          ),
          ListTile(
            leading: const Icon(Symbols.upload_file_rounded),
            title: Text(l.backup),
            subtitle: Text(l.backupNote),
            onTap: () => exportBackupFile(ref),
          ),
          ListTile(
            leading: const Icon(Symbols.settings_backup_restore_rounded),
            title: Text(l.restore),
            onTap: () => restoreFromFile(context, ref),
          ),
          ListTile(
            leading: const Icon(Symbols.table_view_rounded),
            title: Text(l.exportCsv),
            onTap: () => exportCsvFile(context, ref),
          ),
          ListTile(
            leading: Icon(
              Symbols.delete_forever_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l.deleteAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => deleteEverything(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.info_rounded),
            title: Text(l.about),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => context.push('/about'),
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
                  if (code == current) const Icon(Symbols.check_rounded),
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
