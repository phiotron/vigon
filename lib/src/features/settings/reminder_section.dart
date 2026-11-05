import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';
import '../reminder/reminder_providers.dart';
import 'settings_lead.dart';

/// Nhóm "Nhắc ghi chép" trong Cài đặt: công tắc và giờ nhắc (AC-61).
class ReminderSection extends ConsumerWidget {
  const ReminderSection({super.key, required this.header});

  /// Tiêu đề nhóm, do màn Cài đặt dựng để cùng kiểu với các nhóm khác.
  final Widget header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(reminderEnabledProvider).value ?? false;
    final time = ref.watch(reminderTimeProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SwitchListTile(
          secondary: const SettingsLead(Symbols.notifications_rounded),
          title: Text(l.reminderSwitch),
          subtitle: Text(l.reminderSwitchNote),
          value: enabled,
          onChanged: (on) => _toggle(context, ref, on),
        ),
        ListTile(
          leading: const SettingsLead(Symbols.schedule_rounded),
          title: Text(l.reminderTime),
          subtitle: time == null ? null : Text(time.format(context)),
          onTap: time == null ? null : () => _pickTime(context, ref, time),
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
    // Giải thích trước, chỉ khi "Tiếp tục" mới xin quyền của hệ điều hành.
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.reminderExplainTitle),
        content: Text(l.reminderExplainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.reminderContinue),
          ),
        ],
      ),
    );
    if (agreed != true) return;
    final granted = await scheduler.requestPermission();
    if (!granted) {
      // Công tắc đọc từ cài đặt đã lưu nên vẫn tắt; hướng dẫn mở cài đặt hệ thống.
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.reminderDenied),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: l.reminderOpenSettings,
              onPressed: scheduler.openSystemSettings,
            ),
          ),
        );
      return;
    }
    await repo.setReminderEnabled(true);
  }

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
