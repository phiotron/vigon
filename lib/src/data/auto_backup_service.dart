import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'backup.dart';
import 'backup_crypto.dart';
import 'backup_folder_service.dart';
import 'backup_schedule.dart';
import 'database.dart';
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
    this.folderInICloud,
    this.lastAt,
    this.lastResult,
    this.time = BackupTime.defaultTime,
    this.lastCheckAt,
  });

  final bool enabled;
  final String? folderUri;
  final String? folderName;

  /// Chỉ iOS: thư mục nằm trong iCloud Drive ([PickedFolder.inICloud]); null
  /// khi không biết (Android, cấu hình cũ). Cài đặt hiện cảnh báo
  /// `autoBackupLocalFolderWarningIos` khi giá trị khác `true`.
  final bool? folderInICloud;

  /// Lần thử gần nhất (thành công hay không).
  final DateTime? lastAt;
  final AutoBackupResult? lastResult;

  /// Giờ sao lưu hằng ngày theo giờ máy (D-026); chưa lưu thì 21:00.
  final BackupTime time;

  /// Lần gần nhất xét mốc giờ mà bỏ qua vì dữ liệu không đổi (không ghi file).
  final DateTime? lastCheckAt;

  /// Lần gần nhất mốc giờ được xử lý: thử sao lưu (được hay lỗi) hoặc xét thấy
  /// dữ liệu không đổi.
  DateTime? get handledAt {
    final a = lastAt;
    final b = lastCheckAt;
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  /// Mốc đã qua mà chưa xử lý: lần mở/ra nền app kế tiếp sẽ bù (D-026).
  bool isDue(DateTime now) =>
      enabled && isBackupDue(now: now, time: time, handledAt: handledAt);

  /// Lần chạy theo lịch kế tiếp (dòng "Lần tới" trong Cài đặt).
  DateTime nextAt(DateTime now) => nextSlot(now, time);

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
  static const iCloudKey = 'auto_backup_icloud';

  /// Giờ sao lưu `HH:MM` (D-026). Cùng chỗ với cấu hình F-24 (SecretStore,
  /// không vào bảng `settings`, D-014).
  static const timeKey = 'auto_backup_time';

  /// Lần xét mốc giờ mà bỏ qua vì dữ liệu không đổi.
  static const lastCheckKey = 'auto_backup_last_check';

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

  /// Thời điểm lưu dạng UTC (`...Z`) để đổi múi giờ không làm lệch; bản cũ
  /// không có `Z` được đọc theo giờ máy. Trả về giờ máy.
  static DateTime? _readTime(String? text) =>
      DateTime.tryParse(text ?? '')?.toLocal();

  static String _writeTime(DateTime t) => t.toUtc().toIso8601String();

  Future<AutoBackupState> state() async {
    try {
      final lastAt = _readTime(await _secrets.read(lastAtKey));
      final result = await _secrets.read(lastResultKey);
      final iCloud = await _secrets.read(iCloudKey);
      return AutoBackupState(
        time:
            BackupTime.parse(await _secrets.read(timeKey)) ??
            BackupTime.defaultTime,
        lastCheckAt: _readTime(await _secrets.read(lastCheckKey)),
        enabled: await _secrets.read(enabledKey) == '1',
        folderUri: await _secrets.read(uriKey),
        folderName: await _secrets.read(nameKey),
        folderInICloud: iCloud == null ? null : iCloud == '1',
        lastAt: lastAt,
        lastResult: AutoBackupResult.values.asNameMap()[result],
      );
    } catch (_) {
      return const AutoBackupState();
    }
  }

  /// Bật: lưu thư mục (đã chọn, đã giữ quyền), mật khẩu và giờ sao lưu. Chưa
  /// sao lưu; nơi gọi chạy [backupNow] ngay sau đó.
  Future<void> enable({
    required PickedFolder folder,
    required String password,
    BackupTime time = BackupTime.defaultTime,
  }) async {
    await _secrets.write(passwordKey, password);
    await _secrets.write(uriKey, folder.uri);
    await _saveFolderInfo(folder);
    await _secrets.write(timeKey, time.encode());
    await _secrets.delete(lastAtKey);
    await _secrets.delete(lastResultKey);
    await _secrets.delete(lastHashKey);
    await _secrets.delete(lastCheckKey);
    await _secrets.write(enabledKey, '1');
  }

  /// Đổi giờ sao lưu (D-026). Không sao lưu ngay; lịch được đặt lại theo
  /// trạng thái mới (`autoBackupScheduleSyncProvider`).
  Future<void> setTime(BackupTime time) =>
      _secrets.write(timeKey, time.encode());

  Future<void> _saveFolderInfo(PickedFolder folder) async {
    if (folder.name == null) {
      await _secrets.delete(nameKey);
    } else {
      await _secrets.write(nameKey, folder.name!);
    }
    if (folder.inICloud == null) {
      await _secrets.delete(iCloudKey);
    } else {
      await _secrets.write(iCloudKey, folder.inICloud! ? '1' : '0');
    }
  }

  /// Đổi thư mục, giữ mật khẩu; bỏ quyền thư mục cũ.
  Future<void> changeFolder(PickedFolder folder) async {
    final old = await _secrets.read(uriKey);
    await _secrets.write(uriKey, folder.uri);
    await _saveFolderInfo(folder);
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
      iCloudKey,
      timeKey,
      lastCheckKey,
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

  /// Đường bù khi app RA NỀN (Android, gọi từ `AppLifecycleWatcher`): xem
  /// [maybeRunIfDue]. Trên iOS không làm gì vì iOS có thể treo app ngay khi ra
  /// nền (D-022); iOS bù lúc mở/quay lại app ([maybeRunOnOpen]).
  Future<void> maybeRunDaily() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) return;
    await maybeRunIfDue();
  }

  /// Đường bù khi app MỞ hoặc QUAY LẠI (cả hai nền tảng, D-026); trên iOS cũng
  /// là lúc người dùng chạm thông báo "Đến giờ sao lưu". Xem [maybeRunIfDue].
  Future<void> maybeRunOnOpen() => maybeRunIfDue();

  /// Sao lưu nếu đã bật, mốc giờ gần nhất (giờ người dùng chọn, D-026) chưa
  /// được xử lý và dữ liệu đã đổi kể từ lần sao lưu thành công trước. Dùng chung
  /// cho lịch chạy nền Android, thông báo iOS và đường bù khi mở/ra nền app.
  /// Mỗi mốc xử lý tối đa một lần: lần thử LỖI cũng tính (D-014), lần thấy dữ
  /// liệu không đổi ghi [lastCheckKey] để không xuất lại dữ liệu mỗi lần ra nền.
  /// Trả kết quả nếu đã thử sao lưu, null nếu không làm gì. Không ném lỗi.
  Future<AutoBackupResult?> maybeRunIfDue() async {
    if (_running) return null;
    try {
      final s = await state();
      final now = _clock();
      if (!s.isDue(now)) return null;
      final lastHash = await _secrets.read(lastHashKey);
      if (s.lastResult == AutoBackupResult.ok &&
          lastHash != null &&
          lastHash == await _dataHash()) {
        await _secrets.write(lastCheckKey, _writeTime(now));
        return null;
      }
      return await backupNow();
    } catch (_) {
      // Không để lỗi chạy nền lọt ra ngoài.
      return null;
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
      await _secrets.write(lastAtKey, _writeTime(now));
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
