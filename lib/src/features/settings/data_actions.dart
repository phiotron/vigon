import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/backup.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';
import '../lock/app_lock.dart';
import '../lock/pin_pad.dart';

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

/// Xuất bản sao lưu `.vigon` (AC-28).
Future<void> exportBackupFile(WidgetRef ref) async {
  final now = ref.read(clockProvider)();
  final json = await exportBackup(ref.read(databaseProvider), now: now);
  await _shareFile('vigon-${_stamp(now)}.vigon', json, 'application/json');
}

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

/// Chọn file sao lưu, hỏi xác nhận rồi khôi phục (AC-29).
Future<void> restoreFromFile(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final picked = await FilePicker.pickFile();
  if (picked == null || !context.mounted) return;
  final String content;
  try {
    content = utf8.decode(await picked.readAsBytes());
  } catch (_) {
    showMessage(l.restoreFailed);
    return;
  }
  try {
    validateBackup(content);
  } on BackupFormatException {
    showMessage(l.restoreFailed);
    return;
  }
  if (!context.mounted) return;
  final ok = await _confirm(context, l.restore, l.restoreConfirm, l.confirm);
  if (!ok) return;
  try {
    await importBackup(ref.read(databaseProvider), content);
    ref.read(accountFilterProvider.notifier).select(null);
    showMessage(l.restoreDone);
  } on BackupFormatException {
    showMessage(l.restoreFailed);
  }
}

/// Xóa toàn bộ dữ liệu sau hai lần xác nhận (AC-34, AC-42). Trả về true nếu đã xóa.
Future<bool> deleteEverything(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  if (!await _confirm(context, l.deleteAll, l.deleteAllConfirm, l.delete)) {
    return false;
  }
  if (!context.mounted) return false;
  if (!await _confirm(context, l.deleteAll, l.deleteAllConfirm2, l.deleteAll)) {
    return false;
  }
  await deleteAllData(ref.read(databaseProvider));
  await ref.read(pinServiceProvider).disable();
  ref.invalidate(pinEnabledProvider);
  await ref
      .read(settingsRepositoryProvider)
      .ensureCurrency(ref.read(deviceLocaleProvider));
  ref.read(accountFilterProvider.notifier).select(null);
  showMessage(l.deleteAllDone);
  return true;
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Đặt mã PIN: nhập hai lần cho khớp, có cảnh báo quên mã (AC-31).
Future<void> setupPin(BuildContext context, WidgetRef ref) async {
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => const Dialog.fullscreen(child: _PinSetup()),
  );
  if (pin == null) return;
  await ref.read(pinServiceProvider).setPin(pin);
  ref.invalidate(pinEnabledProvider);
}

/// Tắt khóa PIN, phải nhập đúng mã đang dùng.
Future<void> disablePin(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) =>
        Dialog.fullscreen(child: _PinCheck(title: l.enterPin)),
  );
  if (ok != true) return;
  await ref.read(pinServiceProvider).disable();
  ref.invalidate(pinEnabledProvider);
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
    return Scaffold(
      appBar: AppBar(title: Text(l.pinLock)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            title: _first == null ? l.newPin : l.confirmPin,
            message: l.pinWarning,
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
                setState(() {
                  _first = null;
                  _error = l.pinMismatch;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}

class _PinCheck extends ConsumerStatefulWidget {
  const _PinCheck({required this.title});

  final String title;

  @override
  ConsumerState<_PinCheck> createState() => _PinCheckState();
}

class _PinCheckState extends ConsumerState<_PinCheck> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.pinLock)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PinPad(
            title: widget.title,
            error: _error,
            onCompleted: (pin) async {
              final ok = await ref.read(pinServiceProvider).verify(pin);
              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context, true);
              } else {
                setState(() => _error = l.wrongPin);
              }
            },
          ),
        ),
      ),
    );
  }
}
