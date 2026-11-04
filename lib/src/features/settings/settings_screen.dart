import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import '../lock/app_lock.dart';
import 'budget_dialog.dart';
import 'choice_segments.dart';
import 'data_actions.dart';

/// Cài đặt (AC-12, AC-21, AC-35, AC-36 và các mục G4–G6), theo S08 (5.1, 5.2):
/// Giao diện, Ngôn ngữ → các dòng mở màn/hộp thoại → Bảo mật → Dữ liệu →
/// Giới thiệu.
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
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall
        ?.copyWith(color: scheme.primary);

    // Tiêu đề nhóm (`.vg-section`): title-sm màu primary.
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s1,
      ),
      child: Semantics(header: true, child: Text(text, style: titleStyle)),
    );

    // Nút chọn một (`.vg-seg`): lề 4/16/12, vùng chạm 48 đã gồm 4 trên dưới.
    Widget segments<T>(
      List<(T, String)> options,
      T selected,
      ValueChanged<T> onChanged,
    ) => Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s2),
      child: ChoiceSegments<T>(
        options: options,
        selected: selected,
        onChanged: onChanged,
      ),
    );

    const chevron = Icon(Symbols.chevron_right_rounded);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: VgSpace.s8),
        children: [
          header(l.theme),
          segments<ThemeMode>(
            [
              (ThemeMode.system, l.themeSystem),
              (ThemeMode.light, l.themeLight),
              (ThemeMode.dark, l.themeDark),
            ],
            themeMode,
            repo.setThemeMode,
          ),
          header(l.language),
          segments<String>(
            [('', l.languageSystem), ('vi', 'Tiếng Việt'), ('en', 'English')],
            localeCode,
            (code) => repo.setLocaleCode(code.isEmpty ? null : code),
          ),
          const _Divider(),
          _Row(
            icon: Symbols.category_rounded,
            title: l.categories,
            trailing: chevron,
            onTap: () => context.push('/categories'),
          ),
          _Row(
            icon: Symbols.account_balance_wallet_rounded,
            title: l.accounts,
            trailing: chevron,
            onTap: () => context.push('/accounts'),
          ),
          _Row(
            icon: Symbols.savings_rounded,
            title: l.budget,
            subtitle: budget == null
                ? l.budgetNotSet
                : money(context, currency, budget),
            onTap: () => showBudgetDialog(context, ref),
          ),
          _Row(
            icon: Symbols.event_repeat_rounded,
            title: l.recurring,
            trailing: chevron,
            onTap: () => context.push('/recurring'),
          ),
          _Row(
            icon: Symbols.currency_exchange_rounded,
            title: l.currency,
            subtitle: _currencyLabel(currency),
            onTap: () => _pickCurrency(context, ref, currency),
          ),
          _Row(
            icon: Symbols.view_week_rounded,
            title: l.weekStart,
            subtitle: weekStart == DateTime.sunday ? l.sunday : l.monday,
            onTap: () => repo.setWeekStart(
              weekStart == DateTime.sunday ? DateTime.monday : DateTime.sunday,
            ),
          ),
          _MonthStartRow(
            value: monthStartDay,
            onChanged: repo.setMonthStartDay,
          ),
          header(l.security),
          SwitchListTile(
            secondary: const _Lead(Symbols.lock_rounded),
            title: Text(l.pinLock),
            // Cảnh báo luôn hiện đủ, không cắt.
            subtitle: Text(l.pinWarning),
            value: pinEnabled,
            onChanged: (on) =>
                on ? setupPin(context, ref) : disablePin(context, ref),
          ),
          header(l.dataSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              0,
              VgSpace.s4,
              VgSpace.s2,
            ),
            child: Text(
              l.backupReminder,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          _Row(
            icon: Symbols.upload_file_rounded,
            title: l.backup,
            subtitle: l.backupNote,
            onTap: () => exportBackupFile(ref),
          ),
          _Row(
            icon: Symbols.settings_backup_restore_rounded,
            title: l.restore,
            onTap: () => restoreFromFile(context, ref),
          ),
          _Row(
            icon: Symbols.table_view_rounded,
            title: l.exportCsv,
            onTap: () => exportCsvFile(context, ref),
          ),
          _Row(
            icon: Symbols.delete_forever_rounded,
            title: l.deleteAll,
            color: scheme.error,
            onTap: () => deleteEverything(context, ref),
          ),
          const _Divider(),
          _Row(
            icon: Symbols.info_rounded,
            title: l.about,
            trailing: chevron,
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }

  static String _currencyLabel(String code) {
    final symbol = currencySymbol(code);
    return symbol == code ? code : '$code · $symbol';
  }

  /// Chọn tiền tệ (5.5): ghi chú "chỉ đổi ký hiệu", mã đang dùng có ✓.
  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => _CurrencyDialog(current: current),
    );
    if (picked != null && picked != current) {
      await changeCurrency(ref.read(databaseProvider), picked);
    }
  }
}

/// Đường kẻ giữa các nhóm (`.vg-divider`, cách trên dưới 4).
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(height: VgSpace.s2 + 1);
}

/// Icon đầu dòng (`.lead.plain`): ô 40, màu chữ phụ (hoặc màu riêng).
class _Lead extends StatelessWidget {
  const _Lead(this.icon, {this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    child: Center(child: Icon(icon, color: color)),
  );
}

/// Một dòng cài đặt (`.vg-row`): icon, tên, phụ đề hiện đủ, phần cuối tùy chọn.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: _Lead(icon, color: color),
    title: Text(title, style: color == null ? null : TextStyle(color: color)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: trailing,
    onTap: onTap,
  );
}

/// Tháng bắt đầu từ ngày (5.6): nút thả viền `outline` mở menu 1–28, ngày đang
/// chọn nền `secondary-container`. Chạm cả dòng cũng mở menu.
class _MonthStartRow extends StatefulWidget {
  const _MonthStartRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_MonthStartRow> createState() => _MonthStartRowState();
}

class _MonthStartRowState extends State<_MonthStartRow> {
  final _menu = MenuController();

  void _toggle() => _menu.isOpen ? _menu.close() : _menu.open();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Kiểu chữ của nút không tự lấy họ chữ của theme, nên khai rõ.
    const digits = TextStyle(
      fontFamily: vgFontFamily,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return ListTile(
      leading: const _Lead(Symbols.calendar_month_rounded),
      title: Text(l.monthStartDay),
      onTap: _toggle,
      trailing: MenuAnchor(
        controller: _menu,
        alignmentOffset: const Offset(0, VgSpace.s1),
        // Menu nhỏ cuộn được (5.6): khoảng 7 dòng, không phủ cả màn.
        style: const MenuStyle(
          maximumSize: WidgetStatePropertyAll(
            Size(double.infinity, 7 * VgSize.tapMin + 2 * VgSpace.s2),
          ),
        ),
        menuChildren: [
          for (var d = 1; d <= 28; d++)
            MenuItemButton(
              style: MenuItemButton.styleFrom(
                minimumSize: const Size(96, VgSize.tapMin),
                backgroundColor: d == widget.value
                    ? scheme.secondaryContainer
                    : null,
                foregroundColor: d == widget.value
                    ? scheme.onSecondaryContainer
                    : scheme.onSurface,
                textStyle: VgType.bodyMd.merge(digits),
              ),
              onPressed: () => widget.onChanged(d),
              child: Semantics(selected: d == widget.value, child: Text('$d')),
            ),
        ],
        builder: (context, controller, _) => Semantics(
          label: '${l.monthStartDay}: ${widget.value}',
          excludeSemantics: true,
          button: true,
          onTap: _toggle,
          child: OutlinedButton(
            onPressed: _toggle,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(VgSize.tapMin, 40),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.fromLTRB(VgSpace.s3, 0, VgSpace.s2, 0),
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VgRadius.sm),
              ),
              textStyle: VgType.bodyMd.merge(digits),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.value}'),
                const Icon(Symbols.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại chọn tiền tệ (5.5): ghi chú ở trên, danh sách mã cuộn được, mã
/// đang dùng có ✓, nút Hủy.
class _CurrencyDialog extends StatelessWidget {
  const _CurrencyDialog({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(l.currency),
      contentPadding: const EdgeInsets.fromLTRB(
        VgSpace.s6,
        VgSpace.s3,
        VgSpace.s6,
        0,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.currencyNote,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VgSpace.s2),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final code in supportedCurrencies)
                    Semantics(
                      selected: code == current,
                      button: true,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, code),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: VgSize.tapMin,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(code, style: textTheme.bodyLarge),
                              ),
                              if (code == current)
                                Icon(
                                  Symbols.check_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
