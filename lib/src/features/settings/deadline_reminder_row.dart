import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/settings_repository.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import '../reminder/deadline_reminders.dart';
import '../reminder/reminder_providers.dart';
import 'exact_alarm_row.dart';

/// Hàng "Nhắc trước hạn" ở nhóm Kế hoạch (F-48, AC-155): giá trị "Trước 7
/// ngày · 09:00" hoặc "Tắt"; chạm mở bảng chỉnh.
class DeadlineReminderRow extends ConsumerWidget {
  const DeadlineReminderRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(deadlineReminderEnabledProvider).value ?? true;
    final days =
        ref.watch(deadlineReminderDaysProvider).value ?? defaultDeadlineDays;
    final time =
        ref.watch(deadlineReminderTimeProvider).value ?? defaultDeadlineTime;
    return SettingsNavRow(
      icon: Symbols.notifications_active_rounded,
      title: l.deadlineReminders,
      value: enabled
          ? l.deadlineRemindersValue(days, time.format(context))
          : l.deadlineRemindersOff,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => const _DeadlineSheet(),
      ),
    );
  }
}

class _DeadlineSheet extends ConsumerWidget {
  const _DeadlineSheet();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final repo = ref.read(settingsRepositoryProvider);
    if (!on) {
      await repo.setDeadlineReminderEnabled(false);
      return;
    }
    final l = AppLocalizations.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    // Giải thích trước, "Tiếp tục" mới xin quyền của hệ điều hành (AC-155).
    final agreed = await showConfirmDialog(
      context,
      icon: Symbols.notifications_rounded,
      iconTone: VgDialogTone.neutral,
      title: l.deadlineExplainTitle,
      body: l.deadlineExplainBody,
      action: l.reminderContinue,
    );
    if (!agreed) return;
    await repo.setDeadlinePermissionAsked();
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
    await repo.setDeadlineReminderEnabled(true);
    if (context.mounted) await offerExactAlarm(context, ref); // D-045
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(deadlineReminderEnabledProvider).value ?? true;
    final days =
        ref.watch(deadlineReminderDaysProvider).value ?? defaultDeadlineDays;
    final time =
        ref.watch(deadlineReminderTimeProvider).value ?? defaultDeadlineTime;
    final repo = ref.read(settingsRepositoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: VgSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.deadlineReminders),
            SettingsSwitchRow(
              icon: Symbols.notifications_active_rounded,
              title: l.deadlineRemindersSwitch,
              subtitle: l.deadlineRemindersNote,
              value: enabled,
              onChanged: (on) => _toggle(context, ref, on),
            ),
            SettingsNavRow(
              icon: Symbols.event_upcoming_rounded,
              title: l.deadlineDaysBefore,
              value: l.deadlineDaysValue(days),
              onTap: () async {
                final picked = await showChoiceSheet<int>(
                  context,
                  title: l.deadlineDaysBefore,
                  selected: days,
                  options: [
                    for (final d in const [1, 2, 3, 5, 7, 10, 14, 21, 30])
                      ChoiceOption(d, l.deadlineDaysValue(d)),
                  ],
                );
                if (picked != null) {
                  await repo.setDeadlineReminderDays(picked.$1);
                }
              },
            ),
            SettingsNavRow(
              icon: Symbols.schedule_rounded,
              title: l.deadlineTime,
              value: time.format(context),
              onTap: () async {
                final picked = await showTimePicker(
                  // Kiểu nhập bàn phím lỗi "BoxConstraints non-normalized" khi cỡ chữ
                  // hệ thống nhỏ (Galaxy A13 0.8) — giữ mặt đồng hồ như A001 `b0f32fa`.
                  initialEntryMode: TimePickerEntryMode.dialOnly,
                  context: context,
                  initialTime: time,
                );
                if (picked != null) await repo.setDeadlineReminderTime(picked);
              },
            ),
          ],
        ),
      ),
    );
  }
}
