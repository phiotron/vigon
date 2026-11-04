import 'dart:convert';
import 'dart:typed_data';

import 'backup.dart';
import 'backup_crypto.dart';
import 'backup_folder_service.dart';
import 'database.dart';
import 'dates.dart';
import 'pin_service.dart';

/// Kết quả lần sao lưu tự động gần nhất (AC-60).
enum AutoBackupResult {
  ok,

  /// Quyền ghi vào thư mục bị thu hồi.
  permissionDenied,

  /// Thư mục bị xóa hoặc không truy cập được.
  folderMissing,

  /// Lỗi khác (mã hóa, ghi file, bộ nhớ an toàn...).
  failed,

  /// Chưa bật hoặc thiếu thư mục/mật khẩu; không làm gì.
  notConfigured,

  /// Đang có một lần sao lưu khác chạy; không làm gì, không ghi kết quả.
  busy,
}

/// Cấu hình và kết quả gần nhất, đọc từ [SecretStore].
class AutoBackupState {
  const AutoBackupState({
    this.enabled = false,
    this.folderUri,
    this.folderName,
    this.lastAt,
    this.lastResult,
  });

  final bool enabled;
  final String? folderUri;
  final String? folderName;

  /// Lần thử gần nhất (thành công hay không).
  final DateTime? lastAt;
  final AutoBackupResult? lastResult;

  bool get lastFailed =>
      lastResult != null &&
      lastResult != AutoBackupResult.ok &&
      lastResult != AutoBackupResult.notConfigured &&
      lastResult != AutoBackupResult.busy;
}

/// Hàm mã hóa nội dung sao lưu; test thay bằng bản ít vòng lặp.
typedef BackupEncryptor = Future<String> Function(String json, String password);

/// Sao lưu tự động vào thư mục người dùng chọn (F-24, AC-58..60, D-014).
///
/// Mọi trạng thái nằm trong [SecretStore] (Keystore), KHÔNG nằm trong bảng
/// `settings`: bảng đó đi theo file sao lưu và bị xóa khi khôi phục, còn thư
/// mục và mật khẩu chỉ có nghĩa trên máy này. Mật khẩu không bao giờ vào file,
/// log hay cơ sở dữ liệu. File ghi ra luôn mã hóa (AES-256-GCM, D-012).
/// [backupNow] và [maybeRunDaily] không ném lỗi: kết quả được ghi lại để hiện
/// trong Cài đặt.
class AutoBackupService {
  AutoBackupService({
    required this._db,
    required this._folder,
    required this._secrets,
    required this._clock,
    this._encrypt = encryptBackupOffThread,
  });

  final AppDatabase _db;
  final BackupFolderService _folder;
  final SecretStore _secrets;
  final DateTime Function() _clock;
  final BackupEncryptor _encrypt;

  static const enabledKey = 'auto_backup_enabled';
  static const uriKey = 'auto_backup_uri';
  static const nameKey = 'auto_backup_name';
  static const passwordKey = 'auto_backup_password';
  static const lastAtKey = 'auto_backup_last_at';
  static const lastResultKey = 'auto_backup_last_result';
  static const lastHashKey = 'auto_backup_last_hash';

  /// Số file tự động giữ lại trong thư mục (AC-59).
  static const keepFiles = 7;

  /// Tên file do app tạo: `vigon-auto-AAAAMMDD-GGPP.vigon`. Chỉ file khớp đúng
  /// mẫu này mới bị dọn; file khác trong thư mục không bao giờ bị đụng.
  static final fileNamePattern = RegExp(r'^vigon-auto-\d{8}-\d{4}\.vigon$');

  bool _running = false;

  static String fileName(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'vigon-auto-${d.year}${two(d.month)}${two(d.day)}'
        '-${two(d.hour)}${two(d.minute)}.vigon';
  }

  Future<AutoBackupState> state() async {
    try {
      final lastAt = DateTime.tryParse(await _secrets.read(lastAtKey) ?? '');
      final result = await _secrets.read(lastResultKey);
      return AutoBackupState(
        enabled: await _secrets.read(enabledKey) == '1',
        folderUri: await _secrets.read(uriKey),
        folderName: await _secrets.read(nameKey),
        lastAt: lastAt,
        lastResult: AutoBackupResult.values.asNameMap()[result],
      );
    } catch (_) {
      return const AutoBackupState();
    }
  }

  /// Bật: lưu thư mục (đã chọn, đã giữ quyền) và mật khẩu. Chưa sao lưu; nơi
  /// gọi chạy [backupNow] ngay sau đó.
  Future<void> enable({
    required PickedFolder folder,
    required String password,
  }) async {
    await _secrets.write(passwordKey, password);
    await _secrets.write(uriKey, folder.uri);
    if (folder.name == null) {
      await _secrets.delete(nameKey);
    } else {
      await _secrets.write(nameKey, folder.name!);
    }
    await _secrets.delete(lastAtKey);
    await _secrets.delete(lastResultKey);
    await _secrets.delete(lastHashKey);
    await _secrets.write(enabledKey, '1');
  }

  /// Đổi thư mục, giữ mật khẩu; bỏ quyền thư mục cũ.
  Future<void> changeFolder(PickedFolder folder) async {
    final old = await _secrets.read(uriKey);
    await _secrets.write(uriKey, folder.uri);
    if (folder.name == null) {
      await _secrets.delete(nameKey);
    } else {
      await _secrets.write(nameKey, folder.name!);
    }
    await _secrets.delete(lastHashKey);
    if (old != null && old != folder.uri) await _release(old);
  }

  /// Tắt: xóa mật khẩu khỏi Keystore, bỏ quyền thư mục, xóa cài đặt. KHÔNG xóa
  /// file đã ghi trong thư mục (AC-60).
  Future<void> disable() async {
    String? uri;
    try {
      uri = await _secrets.read(uriKey);
    } catch (_) {}
    for (final key in [
      passwordKey,
      enabledKey,
      uriKey,
      nameKey,
      lastAtKey,
      lastResultKey,
      lastHashKey,
    ]) {
      try {
        await _secrets.delete(key);
      } catch (_) {}
    }
    if (uri != null) await _release(uri);
  }

  Future<void> _release(String uri) async {
    try {
      await _folder.releaseFolder(uri);
    } catch (_) {
      // Quyền đã mất hoặc không có kênh: coi như đã bỏ.
    }
  }

  /// Gọi khi app ra nền: sao lưu nếu đã bật, hôm nay chưa thử lần nào và dữ
  /// liệu đã đổi kể từ lần sao lưu thành công trước (AC-59). Không ném lỗi.
  Future<void> maybeRunDaily() async {
    if (_running) return;
    try {
      final s = await state();
      if (!s.enabled) return;
      final now = _clock();
      final last = s.lastAt;
      if (last != null && dateOnly(last) == dateOnly(now)) return;
      final lastHash = await _secrets.read(lastHashKey);
      if (s.lastResult == AutoBackupResult.ok &&
          lastHash != null &&
          lastHash == await _dataHash()) {
        return;
      }
      await backupNow();
    } catch (_) {
      // Không để lỗi chạy nền lọt ra ngoài.
    }
  }

  /// Dấu vết dữ liệu: mã băm SHA-256 phần bảng của file sao lưu.
  Future<String> _dataHash() async {
    final root = jsonDecode(
      await exportBackup(_db, now: _clock()),
    ) as Map<String, dynamic>;
    return root['checksum'] as String;
  }

  /// Sao lưu ngay (không xét ngày hay dữ liệu có đổi). Không ném lỗi; kết quả
  /// được ghi lại và trả về. Đang có lần chạy khác thì trả [AutoBackupResult.busy]
  /// (không ghi gì, không đụng kết quả lần trước).
  Future<AutoBackupResult> backupNow() async {
    if (_running) return AutoBackupResult.busy;
    _running = true;
    try {
      return await _backup();
    } finally {
      _running = false;
    }
  }

  Future<AutoBackupResult> _backup() async {
    final now = _clock();
    var result = AutoBackupResult.failed;
    String? hash;
    try {
      final s = await state();
      final password = await _secrets.read(passwordKey);
      final uri = s.folderUri;
      if (!s.enabled || uri == null || password == null) {
        return AutoBackupResult.notConfigured;
      }
      final json = await exportBackup(_db, now: now);
      hash = (jsonDecode(json) as Map<String, dynamic>)['checksum'] as String;
      final sealed = await _encrypt(json, password);
      final name = fileName(now);
      await _folder.writeFile(
        uri,
        name,
        Uint8List.fromList(utf8.encode(sealed)),
      );
      result = AutoBackupResult.ok;
      await _prune(uri, name);
    } on BackupFolderException catch (e) {
      result = switch (e.error) {
        BackupFolderError.permissionDenied => AutoBackupResult.permissionDenied,
        BackupFolderError.folderMissing => AutoBackupResult.folderMissing,
        BackupFolderError.unavailable => AutoBackupResult.failed,
      };
    } catch (_) {
      result = AutoBackupResult.failed;
    }
    try {
      await _secrets.write(lastAtKey, now.toIso8601String());
      await _secrets.write(lastResultKey, result.name);
      if (result == AutoBackupResult.ok && hash != null) {
        await _secrets.write(lastHashKey, hash);
      }
    } catch (_) {
      // Không ghi được kết quả: chấp nhận, lần sau thử lại.
    }
    return result;
  }

  /// Giữ [keepFiles] file tự động mới nhất (xếp theo tên, tên có ngày giờ).
  /// Lỗi dọn dẹp không làm hỏng lần sao lưu đã ghi xong.
  Future<void> _prune(String uri, String justWritten) async {
    try {
      final mine = [
        for (final n in await _folder.listFiles(uri))
          if (fileNamePattern.hasMatch(n)) n,
      ]..sort((a, b) => b.compareTo(a));
      for (final old in mine.skip(keepFiles)) {
        if (old == justWritten) continue;
        await _folder.deleteFile(uri, old);
      }
    } catch (_) {}
  }
}
