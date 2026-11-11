import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../reminder/reminder_providers.dart';
import 'budget_alert_providers.dart';
import 'budget_status.dart';

/// Hàng "Ngưỡng Sắp vượt" ở nhóm Kế hoạch (AC-111): 50–95 %, bước 5, mặc
/// định 80 %; chạm mở bảng chọn.
class BudgetThresholdRow extends ConsumerWidget {
  const BudgetThresholdRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final percent =
        ref.watch(budgetWarnPercentProvider).value ?? defaultBudgetWarnPercent;
    return SettingsNavRow(
      icon: Symbols.data_thresholding_rounded,
      title: l.budgetAlertThreshold,
      value: l.budgetAlertPercent(percent),
      onTap: () async {
        final picked = await showChoiceSheet<int>(
          context,
          title: l.budgetAlertThreshold,
          selected: percent,
          options: [
            for (final p in budgetWarnPercentChoices)
              ChoiceOption(p, l.budgetAlertPercent(p)),
          ],
        );
        if (picked != null && picked.$1 != percent) {
          await ref.read(budgetAlertSettingsProvider).setThreshold(picked.$1);
        }
      },
    );
  }
}

/// Công tắc "Thông báo ngân sách" ở nhóm Kế hoạch (AC-112), mặc định tắt.
class BudgetAlertSwitchRow extends ConsumerWidget {
  const BudgetAlertSwitchRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(budgetAlertEnabledProvider).value ?? false;
    return SettingsSwitchRow(
      icon: Symbols.notifications_rounded,
      title: l.budgetAlertSwitch,
      subtitle: l.budgetAlertSwitchNote,
      value: enabled,
      onChanged: (on) => _toggle(context, ref, on),
    );
  }

  /// Bật: giải thích trước, chỉ khi "Tiếp tục" mới xin quyền thông báo của hệ
  /// điều hành, như Nhắc ghi sổ (AC-61); bị từ chối thì công tắc ở lại tắt.
  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final settings = ref.read(budgetAlertSettingsProvider);
    if (!on) {
      await settings.setEnabled(false);
      return;
    }
    final l = AppLocalizations.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    final agreed = await showConfirmDialog(
      context,
      icon: Symbols.notifications_rounded,
      iconTone: VgDialogTone.neutral,
      title: l.budgetAlertExplainTitle,
      body: l.budgetAlertExplainBody,
      action: l.reminderContinue,
    );
    if (!agreed) return;
    final granted = await scheduler.requestPermission();
    if (!granted) {
      showVgSnackBar(
        l.reminderDenied,
        actionLabel: l.reminderOpenSettings,
        onAction: scheduler.openSystemSettings,
        long: true,
      );
      return;
    }
    await settings.setEnabled(true);
  }
}
