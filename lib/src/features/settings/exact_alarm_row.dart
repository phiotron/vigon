import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/settings_rows.dart';
import '../reminder/deadline_reminders.dart';
import '../reminder/reminder_providers.dart';

/// Báo đúng giờ (D-045): chỉ Android 12+ mới cần người dùng bật "Báo thức và
/// lời nhắc"; iPhone luôn đúng giờ nên không hiện.
bool get exactAlarmRowSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Nếu chưa được báo đúng giờ: giải thích rồi mở trang hệ thống để người dùng
/// bật (D-045). Không bật thì nhắc vẫn đến, chỉ có thể trễ vài phút.
Future<void> offerExactAlarm(BuildContext context, WidgetRef ref) async {
  if (!exactAlarmRowSupported) return;
  final access = ref.read(exactAlarmAccessProvider);
  if (await access.allowed()) return;
  if (!context.mounted) return;
  final l = AppLocalizations.of(context);
  final agreed = await showConfirmDialog(
    context,
    icon: Symbols.alarm_rounded,
    iconTone: VgDialogTone.neutral,
    title: l.exactAlarmExplainTitle,
    body: l.exactAlarmExplainBody,
    action: l.exactAlarmOpen,
  );
  if (!agreed) return;
  await access.request();
  ref.invalidate(exactAlarmAllowedProvider);
}

/// Hàng "Báo đúng giờ" trong nhóm Nhắc ghi sổ: "Đã bật" / "Chưa bật · có thể
/// trễ vài phút"; chạm để bật. Chỉ hiện khi có nhắc đang bật.
class ExactAlarmRow extends ConsumerWidget {
  const ExactAlarmRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!exactAlarmRowSupported) return const SizedBox.shrink();
    final reminder = ref.watch(reminderEnabledProvider).value ?? false;
    final deadline = ref.watch(deadlineReminderEnabledProvider).value ?? false;
    if (!reminder && !deadline) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final allowed = ref.watch(exactAlarmAllowedProvider).value;
    if (allowed == null) return const SizedBox.shrink();
    return SettingsNavRow(
      icon: Symbols.alarm_rounded,
      title: l.exactAlarmRow,
      value: allowed ? l.exactAlarmOn : l.exactAlarmOff,
      onTap: allowed ? null : () => offerExactAlarm(context, ref),
    );
  }
}
