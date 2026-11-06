import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/backup.dart';
import '../../data/backup_crypto.dart';
import '../../data/money.dart';
import '../../import/mail/mail_providers.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../lock/app_lock.dart';
import '../lock/pin_pad.dart';
import 'auto_backup_providers.dart';
import 'backup_password_dialogs.dart';

String _stamp(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
    '-${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';

/// Ghi file tạm rồi mở bảng chia sẻ của hệ điều hành; app không xin quyền bộ nhớ (AC-28).
Future<void> _shareFile(String name, String content, String mimeType) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsString(content, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
  );
}

/// Xuất bản sao lưu `.vigon` (AC-28, AC-55, SCR-26): hộp thoại hỏi có đặt
/// mật khẩu không; có thì mã hóa ngay trong hộp thoại ("Đang xử lý", A13),
/// xong mới mở bảng chia sẻ.
Future<void> exportBackupFile(BuildContext context, WidgetRef ref) async {
  final now = ref.read(clockProvider)();
  final plain = await exportBackup(ref.read(databaseProvider), now: now);
  if (!context.mounted) return;
  final result = await showDialog<String>(
    context: context,
    builder: (_) => BackupExportDialog(
      encrypt: (password) => encryptBackupOffThread(plain, password),
    ),
  );
  if (result == null || !context.mounted) return;
  final content = result.isEmpty ? plain : result;
  await _shareFile('vigon-${_stamp(now)}.vigon', content, 'application/json');
}

/// Định dạng CSV theo ngôn ngữ app: tiêu đề, tên loại, hai cột 2.0 Giờ và
/// Nguồn (Ghi tay / Email MB, AC-124).
CsvFormat csvFormatFor(AppLocalizations l) => CsvFormat.forLanguage(
  l.localeName,
  header: [
    l.csvColDate,
    l.csvColType,
    l.csvColAmount,
    l.csvColCurrency,
    l.csvColCategory,
    l.csvColAccount,
    l.csvColToAccount,
    l.csvColNote,
  ],
  expense: l.csvTypeExpense,
  income: l.csvTypeIncome,
  transfer: l.csvTypeTransfer,
  timeHeader: l.csvColTime,
  sourceHeader: l.csvColSource,
  manualSource: l.csvSourceManual,
  emailMbSource: l.csvSourceEmailMb,
);

/// Xuất CSV toàn bộ khoản (AC-30).
Future<void> exportCsvFile(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final db = ref.read(databaseProvider);
  final currency = ref.read(currencyProvider).value ?? 'VND';
  final categories = {
    for (final c in await db.select(db.categories).get()) c.id: c,
  };
  final accounts = {
    for (final a in await db.select(db.accounts).get()) a.id: a,
  };
  final csv = exportCsv(
    entries: await db.select(db.entries).get(),
    currency: currency,
    decimalDigits: currencyDecimalDigits(currency),
    format: csvFormatFor(l),
    categoryName: (id) =>
        categories[id] == null ? '' : categoryLabel(l, categories[id]!),
    accountName: (id) =>
        accounts[id] == null ? '' : accountLabel(l, accounts[id]!),
  );
  await _shareFile(
    'vigon-${_stamp(ref.read(clockProvider)())}.csv',
    csv,
    'text/csv',
  );
}

/// Chọn file sao lưu, hỏi xác nhận rồi khôi phục (AC-29, 8.6–8.8). Kiểm hết
/// file trước rồi mới hỏi, để file hỏng không bao giờ tới bước thay dữ liệu.
Future<void> restoreFromFile(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final picked = await FilePicker.pickFile();
  if (picked == null || !context.mounted) return;
  String content;
  try {
    content = utf8.decode(await picked.readAsBytes());
  } catch (_) {
    showMessage(l.restoreFailed);
    return;
  }
  if (isEncryptedBackup(content)) {
    // File có mật khẩu (AC-55): kiểm hình dạng, hỏi mật khẩu, rồi đi tiếp như file thường.
    try {
      checkEncryptedBackup(content);
    } on BackupFormatException {
      showMessage(l.restoreFailed);
      return;
    }
    if (!context.mounted) return;
    final envelope = content;
    final plain = await showDialog<String>(
      context: context,
      builder: (_) => BackupUnlockDialog(envelope: envelope),
    );
    if (plain == null || !context.mounted) return;
    content = plain;
  }
  try {
    validateBackup(content);
  } on BackupFormatException {
    showMessage(l.restoreFailed);
    return;
  }
  if (!context.mounted) return;
  final ok = await showConfirmDialog(
    context,
    icon: Symbols.settings_backup_restore_rounded,
    iconTone: VgDialogTone.neutral,
    title: l.restore,
    body: l.restoreConfirm,
    // Nhắc ghi chép và số tiền trên widget là cài đặt của máy, về tắt sau khi
    // khôi phục. iOS cũng có widget (D-022) nên dùng chung một câu.
    note: l.restoreSwitchesNote,
    action: l.confirm,
  );
  if (!ok) return;
  try {
    await importBackup(ref.read(databaseProvider), content);
    ref.read(accountFilterProvider.notifier).select(null);
    showMessage(l.restoreDone);
  } on BackupFormatException {
    showMessage(l.restoreFailed);
  }
}

/// Xóa toàn bộ dữ liệu sau hai lần xác nhận (AC-34, AC-42, 8.9–8.11); cũng là
/// bước 2–3 của Quên mã ở màn khóa. Trả về true nếu đã xóa.
Future<bool> deleteEverything(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final first = await showConfirmDialog(
    context,
    icon: Symbols.delete_forever_rounded,
    title: l.deleteAllTitle,
    body: l.deleteAllConfirm,
    action: l.delete,
    style: ConfirmStyle.danger,
  );
  if (!first || !context.mounted) return false;
  final second = await showConfirmDialog(
    context,
    icon: Symbols.warning_rounded,
    title: l.cannotUndo,
    body: l.deleteAllConfirm2,
    action: l.deleteAll,
    style: ConfirmStyle.danger,
  );
  if (!second) return false;
  await deleteAllData(ref.read(databaseProvider));
  await ref.read(pinServiceProvider).disable();
  ref.invalidate(pinEnabledProvider);
  // Xóa hết thì cũng tắt sao lưu tự động (mật khẩu, quyền thư mục), để một
  // bản sao lưu rỗng không đẩy dần các file tốt ra khỏi thư mục.
  await ref.read(autoBackupServiceProvider).disable();
  ref.invalidate(autoBackupStateProvider);
  // AC-123: hộp thư, mật khẩu ứng dụng (Keystore/Keychain), tắt kiểm thư nền.
  await eraseEmailImport(ref);
  await ref
      .read(settingsRepositoryProvider)
      .ensureCurrency(ref.read(deviceLocaleProvider));
  ref.read(accountFilterProvider.notifier).select(null);
  HapticFeedback.lightImpact();
  showMessage(l.deleteAllDone);
  return true;
}

/// Đặt mã PIN (AC-31, 8.1–8.3): màn toàn khung nhập hai lần cho khớp. Mũi tên
/// quay lại, Back hoặc vuốt mép trái là hủy, PIN không bật.
Future<void> setupPin(BuildContext context, WidgetRef ref) async {
  final pin = await Navigator.of(context)
      .push<String>(MaterialPageRoute(builder: (_) => const _PinSetup()));
  if (pin == null) return;
  await ref.read(pinServiceProvider).setPin(pin);
  ref.invalidate(pinEnabledProvider);
}

/// Tắt khóa PIN (8.4), phải nhập đúng mã đang dùng.
Future<void> disablePin(BuildContext context, WidgetRef ref) async {
  final ok = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const _PinCheck()));
  if (ok != true) return;
  await ref.read(pinServiceProvider).disable();
  ref.invalidate(pinEnabledProvider);
}

/// Khung chung của màn PIN trong Cài đặt (`.vg-pin`): thanh tiêu đề "Khóa bằng
/// mã PIN" có mũi tên quay lại; tiêu đề, chấm, dòng lỗi ở trên, bàn phím dồn
/// xuống đáy; thiếu chỗ (cỡ chữ lớn) thì cả màn cuộn được. [pad] phải bật
/// `expand`.
class _PinScaffold extends StatelessWidget {
  const _PinScaffold({required this.pad});

  final PinPad pad;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pinLock)),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4,
                  VgSpace.s6,
                  VgSpace.s4,
                  VgSpace.s6,
                ),
                child: pad,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinSetup extends StatefulWidget {
  const _PinSetup();

  @override
  State<_PinSetup> createState() => _PinSetupState();
}

class _PinSetupState extends State<_PinSetup> {
  String? _first;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final firstStep = _first == null;
    return _PinScaffold(
      pad: PinPad(
        expand: true,
        titleStyle: Theme.of(context).textTheme.titleLarge,
        title: firstStep ? l.newPin : l.confirmPin,
        // Cảnh báo quên mã chỉ ở lần nhập đầu (8.1, 8.3), không ở 8.2.
        message: firstStep ? l.pinWarning : null,
        error: _error,
        onCompleted: (pin) async {
          if (_first == null) {
            setState(() {
              _first = pin;
              _error = null;
            });
          } else if (pin == _first) {
            Navigator.pop(context, pin);
          } else {
            HapticFeedback.lightImpact();
            setState(() {
              _first = null;
              _error = l.pinMismatch;
            });
          }
        },
      ),
    );
  }
}

class _PinCheck extends ConsumerStatefulWidget {
  const _PinCheck();

  @override
  ConsumerState<_PinCheck> createState() => _PinCheckState();
}

class _PinCheckState extends ConsumerState<_PinCheck> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _PinScaffold(
      pad: PinPad(
        expand: true,
        titleStyle: Theme.of(context).textTheme.titleLarge,
        title: l.enterPin,
        error: _error,
        onCompleted: (pin) async {
          final ok = await ref.read(pinServiceProvider).verify(pin);
          if (!context.mounted) return;
          if (ok) {
            Navigator.pop(context, true);
          } else {
            HapticFeedback.lightImpact();
            setState(() => _error = l.wrongPin);
          }
        },
      ),
    );
  }
}
