import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/backup_crypto.dart';

/// Số ký tự tối thiểu của mật khẩu file sao lưu (AC-55).
const backupPasswordMinLength = 6;

/// Hộp thoại "Xuất bản sao lưu": hỏi có đặt mật khẩu không (mặc định không).
/// Trả về null nếu hủy, chuỗi rỗng nếu xuất không mật khẩu, còn lại là mật khẩu.
class BackupExportDialog extends StatefulWidget {
  const BackupExportDialog({super.key});

  @override
  State<BackupExportDialog> createState() => _BackupExportDialogState();
}

class _BackupExportDialogState extends State<BackupExportDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _protect = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    // Xóa mật khẩu khỏi ô nhập trước khi giải phóng.
    _password.clear();
    _confirm.clear();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l) {
    if (!_protect) {
      Navigator.pop(context, '');
      return;
    }
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
      title: Text(l.backup),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.backupSetPassword),
              value: _protect,
              onChanged: (on) => setState(() => _protect = on),
            ),
            if (_protect) ...[
              TextField(
                controller: _password,
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
                l.backupPasswordWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
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
          child: Text(l.backupExportAction),
        ),
      ],
    );
  }
}

/// Giải mã nội dung phong bì bằng mật khẩu; thay được trong test.
typedef BackupDecryptor = Future<String> Function(String envelope, String pw);

/// Hộp thoại hỏi mật khẩu khi khôi phục file mã hóa. Sai mật khẩu thì báo ngay
/// trong hộp thoại và cho thử lại. Trả về JSON sao lưu đã giải mã, null nếu hủy.
class BackupUnlockDialog extends StatefulWidget {
  const BackupUnlockDialog({
    super.key,
    required this.envelope,
    this.decrypt = decryptBackupOffThread,
  });

  final String envelope;
  final BackupDecryptor decrypt;

  @override
  State<BackupUnlockDialog> createState() => _BackupUnlockDialogState();
}

class _BackupUnlockDialogState extends State<BackupUnlockDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _wrong = false;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _wrong = false;
    });
    try {
      final json = await widget.decrypt(widget.envelope, _password.text);
      if (mounted) Navigator.pop(context, json);
    } catch (_) {
      // Sai mật khẩu và file bị sửa không phân biệt được; hộp thoại ở lại.
      if (!mounted) return;
      _password.clear();
      setState(() {
        _busy = false;
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l.backupEnterPasswordTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.backupEnterPasswordBody),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                enabled: !_busy,
                autofocus: true,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                onSubmitted: (_) => _open(),
                decoration: InputDecoration(
                  labelText: l.backupPassword,
                  errorText: _wrong ? l.backupWrongPassword : null,
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                Center(
                  child: Semantics(
                    label: l.backupWorking,
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: _busy ? null : _open,
            child: Text(l.backupOpen),
          ),
        ],
      ),
    );
  }
}

/// Chạy [task] sau một hộp thoại quay tròn không đóng được, chặn bấm lặp.
Future<T> runWithProgress<T>(
  BuildContext context,
  Future<T> Function() task,
) async {
  final l = AppLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(l.backupWorking)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}
