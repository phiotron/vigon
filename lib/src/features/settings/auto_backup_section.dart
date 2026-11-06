import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/auto_backup_service.dart';
import '../../data/backup_folder_service.dart';
import '../../data/backup_schedule.dart';
import '../../providers.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import '../reminder/reminder_providers.dart';
import 'auto_backup_providers.dart';
import 'backup_password_dialogs.dart';
import 'settings_lead.dart';

export 'backup_password_dialogs.dart' show AutoBackupPasswordDialog;

/// Thẻ "Sao lưu tự động" trong Cài đặt → Dữ liệu (F-24, AC-58..60, SCR-31):
/// công tắc + phụ đề; bật thì dưới là thư mục, dòng trạng thái (⏱ / ✓ / dải
/// lỗi), dòng "Lần tới" và cặp nút, rồi hàng "Giờ sao lưu" (D-026, chọn giờ
/// như A14). Trên iOS dùng chữ riêng (D-022).
class AutoBackupSection extends ConsumerStatefulWidget {
  const AutoBackupSection({super.key});

  @override
  ConsumerState<AutoBackupSection> createState() => _AutoBackupSectionState();
}

/// Làm mới trạng thái khi mở Cài đặt và khi app quay lại từ nền: lần sao lưu
/// chạy nền có thể vừa lỗi (AC-60: không dừng im lặng).
class _AutoBackupSectionState extends ConsumerState<AutoBackupSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.invalidate(autoBackupStateProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(autoBackupStateProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state =
        ref.watch(autoBackupStateProvider).value ?? const AutoBackupState();
    final running = ref.watch(autoBackupRunningProvider);
    final scheme = Theme.of(context).colorScheme;
    final folderError =
        state.lastFailed &&
        (state.lastResult == AutoBackupResult.permissionDenied ||
            state.lastResult == AutoBackupResult.folderMissing);
    final backupNow = _PairButton(
      icon: Symbols.backup_rounded,
      label: l.autoBackupNow,
      busy: running,
      onPressed: running ? null : () => backupNowFromSettings(context, ref),
    );
    final chooseAgain = _PairButton(
      icon: Symbols.folder_open_rounded,
      label: l.autoBackupChooseFolder,
      onPressed: running ? null : () => repickFolder(context, ref),
    );
    final ios = useIosCopy;
    final Widget? footer = !state.enabled && !ios
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // iOS (D-026): thông báo đúng giờ, chạm hoặc mở app thì sao lưu.
              if (ios)
                VgHint(
                  l.autoBackupRunsOnOpenIos,
                  padding: const EdgeInsets.only(top: VgSpace.s2),
                ),
              if (state.enabled) ...[
                const SizedBox(height: VgSpace.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.folder_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: VgSpace.s2),
                    Expanded(
                      child: Text(
                        l.autoBackupFolder(
                          state.folderName ?? l.autoBackupFolderUnknown,
                        ),
                        style: VgType.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                // iOS không phân biệt "Trên iPhone" với Google Drive/Dropbox:
                // mọi thư mục không thuộc iCloud Drive đều có cảnh báo.
                if (ios && state.folderInICloud != true)
                  VgHint(
                    l.autoBackupLocalFolderWarningIos,
                    icon: Symbols.warning_rounded,
                    padding: const EdgeInsets.only(top: VgSpace.s2),
                  ),
                const SizedBox(height: VgSpace.s2),
                SettingsStatusLine(
                  status: state.lastFailed
                      ? SettingsStatus.error
                      : state.lastAt == null
                      ? SettingsStatus.idle
                      : SettingsStatus.ok,
                  text: _lastText(context, l, state),
                ),
                _NextRunLine(state: state, ios: ios),
                // Lỗi thư mục: cách sửa (Chọn lại thư mục) lên trước, tô tonal.
                ButtonPair(
                  children: folderError
                      ? [chooseAgain.tonal(), backupNow.outlined()]
                      : [backupNow.tonal(), chooseAgain.outlined()],
                ),
              ],
            ],
          );
    return SettingsCard(
      children: [
        SettingsSwitchRow(
          icon: Symbols.backup_rounded,
          title: l.autoBackup,
          subtitle: ios ? l.autoBackupNoteIos : l.autoBackupNote,
          value: state.enabled,
          onChanged: (on) =>
              on ? enableAutoBackup(context, ref) : disableAutoBackup(ref, l),
          footer: footer,
        ),
        if (state.enabled)
          SettingsNavRow(
            icon: Symbols.schedule_rounded,
            title: l.autoBackupTime,
            value: _timeOfDay(state.time).format(context),
            onTap: running ? null : () => pickBackupTime(context, ref),
          ),
      ],
    );
  }
}

TimeOfDay _timeOfDay(BackupTime t) => TimeOfDay(hour: t.hour, minute: t.minute);

/// "Lần tới: hôm nay/ngày mai, 21:00" theo giờ máy (D-026). Mốc đã qua mà chưa
/// sao lưu thì báo đường bù: Android khi rời app, iOS khi mở lại app.
class _NextRunLine extends ConsumerWidget {
  const _NextRunLine({required this.state, required this.ios});

  final AutoBackupState state;
  final bool ios;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final String text;
    if (state.isDue(now)) {
      text = ios ? l.autoBackupNextSoonIos : l.autoBackupNextSoon;
    } else {
      final next = state.nextAt(now);
      final time = TimeOfDay.fromDateTime(next).format(context);
      text = isToday(now, next)
          ? l.autoBackupNextToday(time)
          : l.autoBackupNextTomorrow(time);
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: VgSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Symbols.event_upcoming_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: VgSpace.s2),
          Expanded(
            child: Text(
              text,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một nút của cặp nút sao lưu tự động; kiểu (tonal / viền) đổi theo trạng
/// thái lỗi (SCR-31 folder-error).
class _PairButton {
  const _PairButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  Widget get _label => BusyButtonLabel(icon: icon, label: label, busy: busy);

  Widget tonal() => FilledButton.tonal(onPressed: onPressed, child: _label);

  Widget outlined() => OutlinedButton(onPressed: onPressed, child: _label);
}

String _lastText(BuildContext context, AppLocalizations l, AutoBackupState s) {
  final at = s.lastAt;
  final locale = Localizations.localeOf(context).languageCode;
  // A03: ngày ngắn theo ngôn ngữ app ("Nov 25, 21:04", "25 thg 11, 21:04").
  final time = at == null
      ? null
      : '${DateFormat.MMMd(locale).format(at)}, ${DateFormat.Hm(locale).format(at)}';
  if (s.lastFailed) {
    // AC-60: lỗi cũng hiện thời gian lần thử gần nhất.
    final error = switch (s.lastResult) {
      AutoBackupResult.permissionDenied ||
      AutoBackupResult.folderMissing => l.autoBackupErrorFolder,
      _ => l.autoBackupErrorOther,
    };
    return time == null ? error : l.autoBackupFailedAt(time, error);
  }
  if (time == null) return l.autoBackupNever;
  return l.autoBackupLast(time);
}

/// Chọn thư mục rồi đặt mật khẩu, lưu và sao lưu ngay lần đầu (AC-58).
Future<void> enableAutoBackup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final folders = ref.read(backupFolderServiceProvider);
  final service = ref.read(autoBackupServiceProvider);
  final PickedFolder? folder;
  try {
    folder = await folders.pickFolder();
  } on BackupFolderException {
    showMessage(l.autoBackupPickFailed);
    return;
  }
  if (folder == null) return;
  if (!context.mounted) {
    // Đã giữ quyền thư mục lúc chọn nhưng không còn màn hình để hỏi mật khẩu: bỏ quyền.
    await _releaseQuietly(folders, folder.uri);
    return;
  }
  final password = await showDialog<String>(
    context: context,
    builder: (_) => const AutoBackupPasswordDialog(),
  );
  if (password == null) {
    // Đã giữ quyền thư mục lúc chọn: bỏ đi vì không bật nữa.
    await _releaseQuietly(folders, folder.uri);
    return;
  }
  // D-026: chọn giờ ngay sau mật khẩu, điền sẵn 21:00 (24 h/12 h theo máy như
  // A14). Đóng bộ chọn không hủy việc bật: giữ 21:00, đổi được sau.
  var time = BackupTime.defaultTime;
  if (context.mounted) {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(time),
      helpText: l.autoBackupTime,
    );
    if (picked != null) time = BackupTime(picked.hour, picked.minute);
  }
  try {
    await service.enable(folder: folder, password: password, time: time);
  } catch (_) {
    // Bộ nhớ an toàn (Keystore) lỗi: không bật được.
    await service.disable();
    await _releaseQuietly(folders, folder.uri);
    showMessage(l.autoBackupErrorOther);
    return;
  }
  ref.invalidate(autoBackupStateProvider);
  if (!context.mounted) return;
  await backupNowFromSettings(context, ref);
  // iOS: xin quyền thông báo SAU lần sao lưu đầu để lời báo bị từ chối không
  // bị thanh "Đã sao lưu" che mất.
  if (!context.mounted) return;
  await ensureBackupNotificationPermission(context, ref);
}

/// Hàng "Giờ sao lưu": `showTimePicker` Material như A14 (giờ nhắc), lưu ngay,
/// lịch được đặt lại qua `autoBackupScheduleSyncProvider` (D-026).
Future<void> pickBackupTime(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final service = ref.read(autoBackupServiceProvider);
  final current = (await service.state()).time;
  if (!context.mounted) return;
  final picked = await showTimePicker(
    context: context,
    initialTime: _timeOfDay(current),
    helpText: l.autoBackupTime,
  );
  if (picked == null) return;
  final time = BackupTime(picked.hour, picked.minute);
  if (time != current) {
    await service.setTime(time);
    ref.invalidate(autoBackupStateProvider);
  }
  if (!context.mounted) return;
  await ensureBackupNotificationPermission(context, ref);
}

/// iOS (D-026, S-40): thông báo giờ sao lưu cần quyền. Đã có thì thôi; chưa có
/// thì giải thích trước, chỉ khi "Tiếp tục" mới hiện hộp thoại của iOS. Bị từ
/// chối hay "Hủy": báo nhẹ, sao lưu tự động vẫn bật và vẫn bù khi mở app.
/// Android chạy nền, không cần quyền thông báo: không làm gì.
Future<void> ensureBackupNotificationPermission(
  BuildContext context,
  WidgetRef ref,
) async {
  final scheduler = ref.read(autoBackupSchedulerProvider);
  if (!scheduler.usesNotification) return;
  if (await scheduler.hasNotificationPermission()) return;
  if (!context.mounted) return;
  final l = AppLocalizations.of(context);
  final agreed = await showConfirmDialog(
    context,
    icon: Symbols.notifications_rounded,
    iconTone: VgDialogTone.neutral,
    title: l.autoBackupNotifyTitleIos,
    body: l.autoBackupNotifyBodyIos,
    action: l.reminderContinue,
  );
  final reminders = ref.read(reminderSchedulerProvider);
  if (agreed && await reminders.requestPermission()) {
    // Đặt lại lịch để chắc thông báo dùng quyền mới.
    ref.invalidate(autoBackupStateProvider);
    return;
  }
  showVgSnackBar(
    l.autoBackupNotifyDeniedIos,
    actionLabel: agreed ? l.reminderOpenSettings : null,
    onAction: agreed ? reminders.openSystemSettings : null,
    long: agreed,
  );
}

Future<void> _releaseQuietly(BackupFolderService folders, String uri) async {
  try {
    await folders.releaseFolder(uri);
  } catch (_) {
    // Không có gì để bỏ.
  }
}

/// Tắt: xóa mật khẩu và quyền thư mục; file đã ghi giữ nguyên (AC-60).
Future<void> disableAutoBackup(WidgetRef ref, AppLocalizations l) async {
  await ref.read(autoBackupServiceProvider).disable();
  ref.invalidate(autoBackupStateProvider);
  showMessage(l.autoBackupOffDone);
}

/// "Sao lưu ngay": chạy và báo kết quả (AC-60). Trong lúc chạy nút quay và
/// bỏ qua chạm (SCR-31 running); trạng thái cũ giữ nguyên tới khi xong.
Future<void> backupNowFromSettings(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final service = ref.read(autoBackupServiceProvider);
  if (ref.read(autoBackupRunningProvider)) return;
  final running = ref.read(autoBackupRunningProvider.notifier)..set(true);
  final AutoBackupResult result;
  try {
    result = await service.backupNow();
  } finally {
    running.set(false);
  }
  if (context.mounted) ref.invalidate(autoBackupStateProvider);
  showMessage(switch (result) {
    AutoBackupResult.ok => l.autoBackupDone,
    AutoBackupResult.busy => l.autoBackupBusy,
    AutoBackupResult.permissionDenied ||
    AutoBackupResult.folderMissing => l.autoBackupErrorFolder,
    _ => l.autoBackupErrorOther,
  });
}

/// "Chọn lại thư mục": đổi thư mục, giữ mật khẩu, sao lưu ngay để kiểm (AC-60).
Future<void> repickFolder(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final folders = ref.read(backupFolderServiceProvider);
  final service = ref.read(autoBackupServiceProvider);
  final PickedFolder? folder;
  try {
    folder = await folders.pickFolder();
  } on BackupFolderException {
    showMessage(l.autoBackupPickFailed);
    return;
  }
  if (folder == null) return;
  if (!context.mounted) {
    // Không còn màn hình để lưu lựa chọn: bỏ quyền thư mục mới, trừ khi nó chính là
    // thư mục đang dùng (bỏ sẽ làm mất quyền của sao lưu hiện tại).
    if (folder.uri != (await service.state()).folderUri) {
      await _releaseQuietly(folders, folder.uri);
    }
    return;
  }
  await service.changeFolder(folder);
  ref.invalidate(autoBackupStateProvider);
  if (!context.mounted) return;
  await backupNowFromSettings(context, ref);
}
