import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/backup_crypto.dart';
import '../../ui/dialog.dart';
import '../../ui/fields.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';

/// Số ký tự tối thiểu của mật khẩu file sao lưu (AC-55).
const backupPasswordMinLength = 6;

/// Hàm mã hóa nội dung sao lưu bằng mật khẩu; thay được trong test.
typedef BackupExportEncryptor = Future<String> Function(String password);

/// Dòng cảnh báo của họ hộp mật khẩu (§10.1 #9, SCR-26/31): icon ⚠ và chữ
/// body-sm màu `error`, đặt TRÊN các ô để vẫn thấy khi bàn phím mở. Chưa có
/// tông `error` trong `VgHint` nên dựng riêng ở đây.
class PasswordWarning extends StatelessWidget {
  const PasswordWarning(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: VgSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Symbols.warning_rounded, size: 18, color: error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: VgType.bodySm.copyWith(color: error)),
          ),
        ],
      ),
    );
  }
}

/// Nút Hủy của hộp mật khẩu; đang xử lý thì tắt (A13). `VgDialog.cancelButton`
/// với `onPressed: null` vẫn bật (rơi về đóng hộp) nên tự dựng.
Widget _cancelButton(BuildContext context, {required bool busy}) => busy
    ? TextButton(
        onPressed: null,
        child: Text(AppLocalizations.of(context).cancel),
      )
    : VgDialog.cancelButton(context);

/// Hai ô mật khẩu + kiểm lỗi dùng chung cho xuất sao lưu và sao lưu tự động.
mixin _TwoPasswords<T extends StatefulWidget> on State<T> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? passwordError;
  String? confirmError;

  /// Mật khẩu hợp lệ, hoặc null (đã hiện lỗi dưới ô).
  String? validated(AppLocalizations l) {
    final pw = password.text;
    final tooShort = pw.runes.length < backupPasswordMinLength;
    final mismatch = pw != confirm.text;
    setState(() {
      passwordError = tooShort ? l.backupPasswordTooShort : null;
      confirmError = !tooShort && mismatch ? l.backupPasswordMismatch : null;
    });
    return tooShort || mismatch ? null : pw;
  }

  List<Widget> fields(
    AppLocalizations l, {
    required VoidCallback onSubmit,
    bool enabled = true,
    bool autofocus = false,
  }) => [
    PasswordField(
      controller: password,
      label: l.backupPassword,
      errorText: passwordError,
      enabled: enabled,
      autofocus: autofocus,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: VgSpace.s3),
    PasswordField(
      controller: confirm,
      label: l.backupPasswordConfirm,
      errorText: confirmError,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
    ),
  ];

  @override
  void dispose() {
    // Xóa mật khẩu khỏi ô nhập trước khi giải phóng.
    password.clear();
    confirm.clear();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }
}

/// Hộp thoại "Xuất bản sao lưu" (SCR-26): icon trung tính, nội dung
/// `backupNote`, công tắc đặt mật khẩu (mặc định tắt). Bật thì có cảnh báo và
/// hai ô mật khẩu.
///
/// Có [encrypt]: khi xuất có mật khẩu, hộp thoại ở lại và mã hóa ("Đang xử
/// lý", ô và Hủy bị tắt — A13), xong thì trả về nội dung đã mã hóa. Không có
/// [encrypt]: trả về mật khẩu. Trả về null nếu hủy, chuỗi rỗng nếu xuất không
/// mật khẩu.
class BackupExportDialog extends StatefulWidget {
  const BackupExportDialog({super.key, this.encrypt});

  final BackupExportEncryptor? encrypt;

  @override
  State<BackupExportDialog> createState() => _BackupExportDialogState();
}

class _BackupExportDialogState extends State<BackupExportDialog>
    with _TwoPasswords {
  bool _protect = false;
  bool _busy = false;

  Future<void> _submit(AppLocalizations l) async {
    if (_busy) return;
    if (!_protect) {
      Navigator.pop(context, '');
      return;
    }
    final pw = validated(l);
    if (pw == null) return;
    final encrypt = widget.encrypt;
    if (encrypt == null) {
      Navigator.pop(context, pw);
      return;
    }
    setState(() => _busy = true);
    try {
      final content = await encrypt(pw);
      if (mounted) Navigator.pop(context, content);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: VgDialog(
        icon: Symbols.upload_file_rounded,
        tone: VgDialogTone.neutral,
        title: l.backup,
        body: l.backupNote,
        content: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.backupSetPassword, style: VgType.bodyMd),
            value: _protect,
            onChanged: _busy ? null : (on) => setState(() => _protect = on),
          ),
          if (_protect) ...[
            const SizedBox(height: VgSpace.s2),
            PasswordWarning(l.backupPasswordWarning),
            ...fields(
              l,
              enabled: !_busy,
              autofocus: true,
              onSubmit: () => _submit(l),
            ),
          ],
        ],
        actions: [
          _cancelButton(context, busy: _busy),
          FilledButton(
            onPressed: _busy ? null : () => _submit(l),
            child: BusyButtonLabel(
              icon: Symbols.ios_share_rounded,
              label: _busy ? l.backupWorking : l.backupExportAction,
              busy: _busy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Giải mã nội dung phong bì bằng mật khẩu; thay được trong test.
typedef BackupDecryptor = Future<String> Function(String envelope, String pw);

/// Hộp thoại hỏi mật khẩu khi khôi phục file mã hóa (SCR-27). Sai mật khẩu
/// thì báo ngay dưới ô, chữ đã gõ giữ nguyên để sửa lại. Đang giải mã: ô và
/// Hủy tắt, nút Mở quay (A13). Trả về JSON đã giải mã, null nếu hủy.
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
      child: VgDialog(
        icon: Symbols.lock_rounded,
        tone: VgDialogTone.neutral,
        title: l.backupEnterPasswordTitle,
        body: l.backupEnterPasswordBody,
        content: [
          PasswordField(
            controller: _password,
            label: l.backupPassword,
            enabled: !_busy,
            autofocus: true,
            errorText: _wrong ? l.backupWrongPassword : null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _open(),
          ),
        ],
        actions: [
          _cancelButton(context, busy: _busy),
          FilledButton(
            onPressed: _busy ? null : _open,
            child: BusyButtonLabel(
              label: _busy ? l.backupWorking : l.backupOpen,
              busy: _busy,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại đặt mật khẩu cho sao lưu tự động (SCR-31 password): cảnh báo
/// luôn hiện, ít nhất 6 ký tự, nhập hai lần (AC-58). Trả về mật khẩu, null
/// nếu hủy.
class AutoBackupPasswordDialog extends StatefulWidget {
  const AutoBackupPasswordDialog({super.key});

  @override
  State<AutoBackupPasswordDialog> createState() =>
      _AutoBackupPasswordDialogState();
}

class _AutoBackupPasswordDialogState extends State<AutoBackupPasswordDialog>
    with _TwoPasswords {
  void _submit(AppLocalizations l) {
    final pw = validated(l);
    if (pw != null) Navigator.pop(context, pw);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VgDialog(
      icon: Symbols.backup_rounded,
      tone: VgDialogTone.neutral,
      title: l.autoBackupPasswordTitle,
      content: [
        PasswordWarning(l.autoBackupPasswordWarning),
        ...fields(l, autofocus: true, onSubmit: () => _submit(l)),
      ],
      actions: [
        VgDialog.cancelButton(context),
        FilledButton(
          onPressed: () => _submit(l),
          child: Text(l.autoBackupTurnOn),
        ),
      ],
    );
  }
}
