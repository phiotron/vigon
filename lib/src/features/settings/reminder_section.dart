import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../reminder/reminder_providers.dart';

/// Nhóm "Nhắc ghi sổ" trong Cài đặt (AC-61, SCR-30): tiêu đề nhóm, thẻ gồm
/// công tắc và giờ nhắc. Giờ nhắc sửa được cả khi công tắc tắt (chỉ lưu giờ).
class ReminderSection extends ConsumerWidget {
  const ReminderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(reminderEnabledProvider).value ?? false;
    final time = ref.watch(reminderTimeProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroupTitle(l.reminderSection),
        SettingsCard(
          children: [
            SettingsSwitchRow(
              icon: Symbols.notifications_rounded,
              title: l.reminderSwitch,
              subtitle: l.reminderSwitchNote,
              value: enabled,
              onChanged: (on) => _toggle(context, ref, on),
            ),
            SettingsNavRow(
              icon: Symbols.schedule_rounded,
              title: l.reminderTime,
              value: time?.format(context),
              onTap: time == null ? null : () => _pickTime(context, ref, time),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (!on) {
      await repo.setReminderEnabled(false);
      return;
    }
    final l = AppLocalizations.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    // S-40: giải thích trước, chỉ khi "Tiếp tục" mới xin quyền của hệ điều hành.
    final agreed = await showConfirmDialog(
      context,
      icon: Symbols.notifications_rounded,
      iconTone: VgDialogTone.neutral,
      title: l.reminderExplainTitle,
      body: l.reminderExplainBody,
      action: l.reminderContinue,
    );
    if (!agreed) return;
    final granted = await scheduler.requestPermission();
    if (!granted) {
      // Công tắc đọc từ cài đặt đã lưu nên vẫn tắt; thanh 10 s có vạch thời
      // gian và nút mở cài đặt thông báo của hệ thống (SCR-30 denied).
      showVgSnackBar(
        l.reminderDenied,
        actionLabel: l.reminderOpenSettings,
        onAction: scheduler.openSystemSettings,
        long: true,
      );
      return;
    }
    await repo.setReminderEnabled(true);
  }

  /// Chọn giờ (A14): `showTimePicker` Material trên cả hai nền tảng, 12/24 h
  /// theo máy. Lưu xong giá trị hiện ngay ở hàng, không snackbar.
  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
  ) async {
    final l = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: l.reminderTime,
    );
    if (picked != null && picked != current) {
      await ref.read(settingsRepositoryProvider).setReminderTime(picked);
    }
  }
}
