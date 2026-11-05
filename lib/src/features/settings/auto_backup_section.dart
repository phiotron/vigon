import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/auto_backup_service.dart';
import '../../data/backup_folder_service.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import 'auto_backup_providers.dart';
import 'backup_password_dialogs.dart';
import 'settings_lead.dart';

export 'backup_password_dialogs.dart' show AutoBackupPasswordDialog;

/// Thẻ "Sao lưu tự động" trong Cài đặt → Dữ liệu (F-24, AC-58..60, SCR-31):
/// công tắc + phụ đề; bật thì dưới là thư mục, dòng trạng thái (⏱ / ✓ / dải
/// lỗi) và cặp nút. Trên iOS dùng chữ riêng (D-022).
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
              // iOS (D-022): chạy khi mở app, không theo giờ.
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
                if (ios && iosFolderMayBeLocal(state.folderUri))
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
      ],
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

/// Thư mục iOS có thể chỉ nằm "Trên iPhone" (không vào sao lưu iCloud,
/// D-021). Dịch vụ chưa báo cờ này: tạm coi mọi thư mục không thuộc iCloud
/// Drive (`Mobile Documents`) là trên máy. D4 thay bằng cờ thật khi có.
bool iosFolderMayBeLocal(String? uri) =>
    uri != null && !uri.contains('Mobile Documents');

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
  try {
    await service.enable(folder: folder, password: password);
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
