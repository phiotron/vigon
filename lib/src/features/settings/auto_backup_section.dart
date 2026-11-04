import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/auto_backup_service.dart';
import '../../data/backup_folder_service.dart';
import '../../ui/messenger.dart';
import 'auto_backup_providers.dart';
import 'backup_password_dialogs.dart';

/// Nhóm "Sao lưu tự động" trong Cài đặt → Dữ liệu (F-24, AC-58..60).
class AutoBackupSection extends ConsumerWidget {
  const AutoBackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state =
        ref.watch(autoBackupStateProvider).value ?? const AutoBackupState();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.cloud_upload_outlined),
          title: Text(l.autoBackup),
          subtitle: Text(l.autoBackupNote),
          value: state.enabled,
          onChanged: (on) =>
              on ? enableAutoBackup(context, ref) : disableAutoBackup(ref, l),
        ),
        if (state.enabled) ...[
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 72,
              end: 16,
            ),
            title: Text(
              l.autoBackupFolder(state.folderName ?? l.autoBackupFolderUnknown),
            ),
            subtitle: Text(
              _lastText(context, l, state),
              style: state.lastFailed ? TextStyle(color: scheme.error) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 72,
              end: 16,
              bottom: 8,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => backupNowFromSettings(context, ref),
                  child: Text(l.autoBackupNow),
                ),
                OutlinedButton(
                  onPressed: () => repickFolder(context, ref),
                  child: Text(l.autoBackupChooseFolder),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _lastText(BuildContext context, AppLocalizations l, AutoBackupState s) {
  if (s.lastFailed) {
    return switch (s.lastResult) {
      AutoBackupResult.permissionDenied ||
      AutoBackupResult.folderMissing => l.autoBackupErrorFolder,
      _ => l.autoBackupErrorOther,
    };
  }
  final at = s.lastAt;
  if (at == null) return l.autoBackupNever;
  final locale = Localizations.localeOf(context).languageCode;
  return l.autoBackupLast(
    '${DateFormat.MMMd(locale).format(at)}, ${DateFormat.Hm(locale).format(at)}',
  );
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
  if (folder == null || !context.mounted) return;
  final password = await showDialog<String>(
    context: context,
    builder: (_) => const AutoBackupPasswordDialog(),
  );
  if (password == null) {
    // Đã giữ quyền thư mục lúc chọn: bỏ đi vì không bật nữa.
    try {
      await folders.releaseFolder(folder.uri);
    } on BackupFolderException {
      // Không có gì để bỏ.
    }
    return;
  }
  try {
    await service.enable(folder: folder, password: password);
  } catch (_) {
    // Bộ nhớ an toàn (Keystore) lỗi: không bật được.
    await service.disable();
    showMessage(l.autoBackupErrorOther);
    return;
  }
  ref.invalidate(autoBackupStateProvider);
  if (!context.mounted) return;
  await backupNowFromSettings(context, ref);
}

/// Tắt: xóa mật khẩu và quyền thư mục; file đã ghi giữ nguyên (AC-60).
Future<void> disableAutoBackup(WidgetRef ref, AppLocalizations l) async {
  await ref.read(autoBackupServiceProvider).disable();
  ref.invalidate(autoBackupStateProvider);
  showMessage(l.autoBackupOffDone);
}

/// "Sao lưu ngay": chạy và báo kết quả (AC-60).
Future<void> backupNowFromSettings(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final service = ref.read(autoBackupServiceProvider);
  final result = await runWithProgress(context, service.backupNow);
  ref.invalidate(autoBackupStateProvider);
  showMessage(switch (result) {
    AutoBackupResult.ok => l.autoBackupDone,
    AutoBackupResult.permissionDenied ||
    AutoBackupResult.folderMissing => l.autoBackupErrorFolder,
    _ => l.autoBackupErrorOther,
  });
}

/// "Chọn lại thư mục": đổi thư mục, giữ mật khẩu, sao lưu ngay để kiểm (AC-60).
Future<void> repickFolder(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final PickedFolder? folder;
  try {
    folder = await ref.read(backupFolderServiceProvider).pickFolder();
  } on BackupFolderException {
    showMessage(l.autoBackupPickFailed);
    return;
  }
  if (folder == null || !context.mounted) return;
  await ref.read(autoBackupServiceProvider).changeFolder(folder);
  ref.invalidate(autoBackupStateProvider);
  if (!context.mounted) return;
  await backupNowFromSettings(context, ref);
}

/// Hộp thoại đặt mật khẩu cho sao lưu tự động: ít nhất 6 ký tự, nhập hai lần,
/// có cảnh báo quên mật khẩu (AC-58). Trả về mật khẩu, null nếu hủy.
class AutoBackupPasswordDialog extends StatefulWidget {
  const AutoBackupPasswordDialog({super.key});

  @override
  State<AutoBackupPasswordDialog> createState() =>
      _AutoBackupPasswordDialogState();
}

class _AutoBackupPasswordDialogState extends State<AutoBackupPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _password.clear();
    _confirm.clear();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l) {
    final password = _password.text;
    final tooShort = password.runes.length < backupPasswordMinLength;
    final mismatch = password != _confirm.text;
    setState(() {
      _passwordError = tooShort ? l.backupPasswordTooShort : null;
      _confirmError = !tooShort && mismatch ? l.backupPasswordMismatch : null;
    });
    if (!tooShort && !mismatch) Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.autoBackupPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _password,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l.backupPassword,
                errorText: _passwordError,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirm,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l.backupPasswordConfirm,
                errorText: _confirmError,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.autoBackupPasswordWarning,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => _submit(l),
          child: Text(l.autoBackupTurnOn),
        ),
      ],
    );
  }
}
