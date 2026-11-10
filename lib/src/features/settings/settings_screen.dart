import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../platform_features.dart';
import '../../data/exchange_rate.dart';
import '../../data/rate_repository.dart';
import '../../providers.dart';
import '../../ui/choice_segments.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import '../import_queue/import_queue_providers.dart';
import '../lock/app_lock.dart';
import 'appearance_sheet.dart';
import 'about_section.dart';
import 'auto_backup_section.dart';
import 'budget_dialog.dart';
import 'currency_picker.dart';
import 'data_actions.dart';
import 'deadline_reminder_row.dart';
import 'email_import_screen.dart';
import 'rates_format.dart';
import 'reminder_section.dart';
import 'secure_window.dart';
import 'settings_lead.dart';
import 'widget_section.dart';

/// Cài đặt (SCR-12, iOS SCR-33; CHANGELOG P2 5.1–5.5): nhóm là thẻ
/// `surface-container-low`, tiêu đề nhóm màu `primary`; mọi nhóm đều có tiêu
/// đề. Thứ tự (2026-11-10): Danh mục & tài khoản · Kế hoạch (ngân sách, định
/// kỳ, tiết kiệm, nợ) · Tiền tệ & kỳ (tiền tệ chính, tỷ giá, ngày đầu tuần,
/// tháng bắt đầu) · Nhập từ email (email ngân hàng, khoản chờ chọn danh mục) ·
/// Bảo mật · Nhắc ghi sổ · Dữ liệu (kết thúc bằng Xóa toàn bộ dữ liệu) ·
/// Giao diện & ngôn ngữ (một nhóm, hai hàng cùng mở bảng kéo — D-038) ·
/// Giới thiệu. Mục chỉ có khi nền tảng hỗ trợ (D-022) đọc cờ trong
/// `platform_features.dart`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.watch(settingsRepositoryProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeCode = ref.watch(localeCodeProvider).value ?? '';
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final weekStart = ref.watch(weekStartProvider).value ?? DateTime.monday;
    final monthStartDay = ref.watch(monthStartDayProvider).value ?? 1;
    final budget = ref.watch(budgetProvider).value;
    final pinEnabled = ref.watch(pinEnabledProvider).value ?? false;
    final scheme = Theme.of(context).colorScheme;
    final queueCount = ref.watch(importQueueCountProvider).value ?? 0;
    final now = ref.watch(clockProvider)();

    const cardGap = SizedBox(height: SettingsCard.gap);

    // Ba hàng sao lưu tay + hàng xóa dùng chung cho cả hai nền tảng: trên
    // Android hàng xóa nối vào cuối thẻ Sao lưu tự động, trên iOS đứng cuối
    // thẻ Dữ liệu (không có sao lưu tự động).
    final backupRow = SettingsNavRow(
      icon: Symbols.upload_file_rounded,
      title: l.backup,
      value: l.backupNote,
      chevron: false,
      onTap: () => exportBackupFile(context, ref),
    );
    final restoreRow = SettingsNavRow(
      icon: Symbols.settings_backup_restore_rounded,
      title: l.restore,
      chevron: false,
      onTap: () => restoreFromFile(context, ref),
    );
    final csvRow = SettingsNavRow(
      icon: Symbols.table_view_rounded,
      title: l.exportCsv,
      // Định dạng CSV theo ngôn ngữ app (F-18).
      value: l.localeName == 'vi' ? l.csvFormatVi : l.csvFormatEn,
      chevron: false,
      onTap: () => exportCsvFile(context, ref),
    );
    final deleteRow = SettingsNavRow(
      icon: Symbols.delete_forever_rounded,
      title: l.deleteAll,
      danger: true,
      onTap: () => deleteEverything(context, ref),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: VgSpace.s6),
        children: [
          // Nhóm đầu (A24): danh mục & tài khoản — thứ hay sửa nhất, đứng
          // trên cùng như A001; nhóm đầu không có lề trên.
          SettingsGroupTitle(l.categoriesAccountsSection, first: true),
          SettingsCard(
            children: [
              SettingsNavRow(
                icon: Symbols.category_rounded,
                title: l.categories,
                onTap: () => context.push('/categories'),
              ),
              SettingsNavRow(
                icon: Symbols.account_balance_wallet_rounded,
                title: l.accounts,
                onTap: () => context.push('/accounts'),
              ),
            ],
          ),
          SettingsGroupTitle(l.planSection),
          SettingsCard(
            children: [
              SettingsNavRow(
                icon: Symbols.payments_rounded,
                title: l.budget,
                value: budget == null
                    ? l.budgetNotSet
                    : money(context, currency, budget),
                onTap: () => showBudgetDialog(context, ref),
              ),
              SettingsNavRow(
                icon: Symbols.event_repeat_rounded,
                title: l.recurring,
                onTap: () => context.push('/recurring'),
              ),
              SettingsNavRow(
                icon: Symbols.savings_rounded,
                title: l.savings,
                onTap: () => context.push('/savings'),
              ),
              SettingsNavRow(
                icon: Symbols.handshake_rounded,
                title: l.debts,
                onTap: () => context.push('/debts'),
              ),
              const DeadlineReminderRow(),
            ],
          ),
          SettingsGroupTitle(l.currencyPeriodSection),
          SettingsCard(
            children: [
              SettingsNavRow(
                icon: Symbols.currency_exchange_rounded,
                title: l.primaryCurrency,
                value: currencyCodeLabel(currency),
                onTap: () => _pickCurrency(context, ref, currency),
              ),
              SettingsNavRow(
                icon: Symbols.refresh_rounded,
                title: l.exchangeRates,
                value: _ratesSummary(ref, l, now, currency),
                onTap: () => context.push('/rates'),
              ),
              // Ngày đầu tuần: hai nút chọn một thay cho chạm để đổi (§10.1 #4).
              SettingsSegmentRow(
                icon: Symbols.view_week_rounded,
                title: l.weekStart,
                segments: ChoiceSegments<int>(
                  compact: true,
                  options: [
                    (DateTime.monday, l.monday),
                    (DateTime.sunday, l.sunday),
                  ],
                  selected: weekStart == DateTime.sunday
                      ? DateTime.sunday
                      : DateTime.monday,
                  onChanged: repo.setWeekStart,
                ),
              ),
              _MonthStartRow(
                value: monthStartDay,
                onChanged: repo.setMonthStartDay,
              ),
            ],
          ),
          // Nhập từ email: nguồn nhập từ email ngân hàng và các khoản email còn
          // chờ chọn danh mục dùng chung một thẻ.
          SettingsGroupTitle(l.emailImportGroup),
          SettingsCard(
            children: [
              const EmailImportRow(),
              SettingsNavRow(
                icon: Symbols.inbox_rounded,
                title: l.importQueueRow,
                value: queueCount == 0
                    ? l.importQueueNone
                    : l.importQueueRowCount(queueCount),
                onTap: () => context.push('/import-queue'),
              ),
            ],
          ),
          SettingsGroupTitle(l.security),
          SettingsCard(
            children: [
              SettingsSwitchRow(
                icon: Symbols.lock_rounded,
                title: l.pinLock,
                // Cảnh báo luôn hiện đủ, không cắt.
                subtitle: l.pinWarning,
                value: pinEnabled,
                onChanged: (on) =>
                    on ? setupPin(context, ref) : disablePin(context, ref),
              ),
              if (supportsSecureWindow)
                SettingsSwitchRow(
                  icon: Symbols.visibility_off_rounded,
                  title: l.secureWindow,
                  // iOS không chặn được chụp màn hình (D-022).
                  subtitle: useIosCopy
                      ? l.secureWindowNoteIos
                      : l.secureWindowNote,
                  value: ref.watch(secureWindowEnabledProvider).value ?? false,
                  onChanged: repo.setSecureWindow,
                ),
              if (supportsHomeWidget)
                WidgetAmountsSwitch(pinEnabled: pinEnabled),
            ],
          ),
          const ReminderSection(),
          // Nhóm Dữ liệu: sao lưu tay, CSV, sao lưu tự động (Android) và dòng
          // nguy hiểm luôn nằm cuối nhóm.
          SettingsGroupTitle(l.dataSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s8,
              0,
              VgSpace.s8,
              VgSpace.s2,
            ),
            child: Text(
              l.backupReminder,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (supportsAutoBackup) ...[
            SettingsCard(children: [backupRow, restoreRow, csvRow]),
            cardGap,
            AutoBackupSection(extraRows: [deleteRow]),
          ] else
            SettingsCard(children: [backupRow, restoreRow, csvRow, deleteRow]),
          SettingsGroupTitle(l.appearanceLanguage),
          SettingsCard(
            children: [
              SettingsNavRow(
                icon: Symbols.palette_rounded,
                title: l.theme,
                value: switch (themeMode) {
                  ThemeMode.system => l.themeSystem,
                  ThemeMode.light => l.themeLight,
                  ThemeMode.dark => l.themeDark,
                },
                valueInline: true,
                onTap: () => showAppearanceSheet(context),
              ),
              SettingsNavRow(
                icon: Symbols.translate_rounded,
                title: l.language,
                value: localeCode == 'vi' ? 'Tiếng Việt' : 'English',
                valueInline: true,
                onTap: () => showAppearanceSheet(context),
              ),
            ],
          ),
          const AboutSection(),
        ],
      ),
    );
  }

  /// "Tự động · hôm qua" · "Có sẵn" · "Bạn đặt tay" như A001.
  String _ratesSummary(
    WidgetRef ref,
    AppLocalizations l,
    DateTime now,
    String primary,
  ) {
    final table = ref.watch(rateTableProvider).value ?? RateTable.fallback;
    final used = ref.watch(usedCurrenciesProvider).value ?? const <String>{};
    return ratesSummaryLabel(l, table, used, primary, now);
  }

  /// Chọn Tiền tệ chính (D-037): chỉ đổi cách cộng/hiển thị, không ghi đè số
  /// gốc. Số dẫn xuất được tính lại theo bảng tỷ giá hiện tại.
  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showCurrencyPicker(
      context,
      current,
      primaryNote: true,
    );
    if (picked == null || picked == current || !context.mounted) return;
    final settings = ref.read(settingsRepositoryProvider);
    final db = ref.read(databaseProvider);
    // Dữ liệu cũ chưa có cột số gốc: chốt số hiện tại là số gốc ở tiền tệ cũ
    // trước khi đổi, để không diễn giải sai.
    await promoteLegacyAmounts(db, current);
    await settings.setPrimaryCurrency(picked);
    final table = await ref.read(rateRepositoryProvider).load();
    await recomputeDerivedAmounts(db, CurrencyService(table, picked));
    if (!context.mounted) return;
    showMessage(AppLocalizations.of(context).primaryCurrencyChanged(picked));
  }
}

/// Tháng bắt đầu từ ngày (5.6, `#r-month`): icon, tên, ô xổ viền `outline`
/// "1 ▾" mở menu 1–28 (ngày đang chọn nền `secondary-container`). Chạm cả
/// hàng cũng mở menu. Cao tối thiểu 56.
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
    final dropdown = MenuAnchor(
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
    );
    return InkWell(
      onTap: _toggle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VgSize.tapKey),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s4,
            VgSpace.s1,
            VgSpace.s2,
            VgSpace.s1,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Symbols.calendar_month_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: VgSpace.s4),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    l.monthStartDay,
                    style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: VgSpace.s2),
              dropdown,
            ],
          ),
        ),
      ),
    );
  }
}
