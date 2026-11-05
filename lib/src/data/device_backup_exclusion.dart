import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Tên cơ sở dữ liệu của drift; file là `<Documents>/vigon.sqlite`.
const databaseName = 'vigon';

/// Đuôi các file SQLite đi kèm file chính (rỗng = chính file `.sqlite`).
const sqliteFileSuffixes = ['', '-wal', '-shm', '-journal'];

/// Loại cơ sở dữ liệu khỏi bản sao lưu iCloud/máy tính trên iOS, cho giống
/// Android `allowBackup="false"`. Gọi kênh `vigon/backup_exclusion`; phần iOS
/// nằm trong `ios/Runner/AppDelegate.swift` (đặt `isExcludedFromBackup`).
///
/// Gửi cả thư mục chứa (Documents, nơi drift đặt cơ sở dữ liệu và app không
/// để gì khác) để file `-journal` sinh ra giữa chừng cũng không vào bản sao
/// lưu. Phía iOS bỏ qua đường dẫn chưa tồn tại.
///
/// Không bao giờ ném lỗi: lỗi chỉ ghi log, việc mở app không bị ảnh hưởng.
class DeviceBackupExclusion {
  const DeviceBackupExclusion({
    this.channel = const MethodChannel(channelName),
    this.documentsDirectory = _documentsPath,
    this.isIOS = _platformIsIOS,
    this.log = _debugLog,
  });

  static const channelName = 'vigon/backup_exclusion';
  static const method = 'excludeFromBackup';

  final MethodChannel channel;

  /// Thư mục drift đặt cơ sở dữ liệu (mặc định của `driftDatabase`).
  final Future<String> Function() documentsDirectory;
  final bool Function() isIOS;
  final void Function(String message) log;

  /// Đường dẫn gửi sang iOS: thư mục chứa, rồi file chính và các file kèm.
  static List<String> pathsFor(String directory, [String name = databaseName]) {
    final base = '$directory${Platform.pathSeparator}$name.sqlite';
    return [directory, for (final suffix in sqliteFileSuffixes) '$base$suffix'];
  }

  /// Đặt cờ loại khỏi sao lưu; trả số mục đã đặt (0 khi không phải iOS hoặc lỗi).
  Future<int> excludeDatabase({String name = databaseName}) async {
    if (!isIOS()) return 0;
    try {
      final paths = pathsFor(await documentsDirectory(), name);
      final count = await channel.invokeMethod<int>(method, {'paths': paths});
      log('backup exclusion: ${count ?? 0} item(s) excluded');
      return count ?? 0;
    } catch (e) {
      // MissingPluginException, PlatformException, lỗi path_provider...
      log('backup exclusion failed: $e');
      return 0;
    }
  }
}

Future<String> _documentsPath() async =>
    (await getApplicationDocumentsDirectory()).path;

bool _platformIsIOS() => !kIsWeb && Platform.isIOS;

void _debugLog(String message) => debugPrint(message);
