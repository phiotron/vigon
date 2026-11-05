import 'package:flutter/services.dart';

/// Lý do không ghi được vào thư mục sao lưu (AC-60).
enum BackupFolderError {
  /// Quyền ghi bị thu hồi.
  permissionDenied,

  /// Thư mục đã bị xóa hoặc không truy cập được.
  folderMissing,

  /// Lỗi khác, hoặc nền tảng không có kênh (test).
  unavailable,
}

class BackupFolderException implements Exception {
  BackupFolderException(this.error, [this.detail]);

  final BackupFolderError error;
  final String? detail;

  @override
  String toString() => 'BackupFolderException: ${error.name} $detail';
}

/// Thư mục người dùng vừa chọn.
class PickedFolder {
  const PickedFolder({required this.uri, this.name, this.inICloud});

  /// Android: URI của cây thư mục (Storage Access Framework). iOS: mã
  /// `ios-bookmark:<uuid>` trỏ tới bookmark do phía iOS giữ.
  final String uri;

  /// Tên thân thiện để hiện trong Cài đặt; null nếu hệ thống không cho biết.
  final String? name;

  /// Chỉ iOS: thư mục nằm trong iCloud Drive (sống sót khi mất máy). `false`:
  /// "Trên iPhone" HOẶC nhà cung cấp khác (Google Drive, Dropbox…), iOS không
  /// cho phân biệt hai loại này. Android: null.
  final bool? inICloud;
}

/// Ghi file vào thư mục người dùng chọn qua kênh `vigon/backup_folder` (F-24).
/// Phần Android là `BackupFolderChannel.kt`; phần iOS là `BackupFolderChannel`
/// trong `ios/Runner/VigonNative.swift` (bộ chọn thư mục của app Tệp, bookmark). Mọi lỗi được đổi thành
/// [BackupFolderException]; test thay lớp này bằng bản giả.
class BackupFolderService {
  const BackupFolderService([this.channel = const MethodChannel(channelName)]);

  static const channelName = 'vigon/backup_folder';

  final MethodChannel channel;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      throw BackupFolderException(BackupFolderError.unavailable, 'no channel');
    } on PlatformException catch (e) {
      throw BackupFolderException(switch (e.code) {
        'permission_denied' => BackupFolderError.permissionDenied,
        'folder_missing' => BackupFolderError.folderMissing,
        _ => BackupFolderError.unavailable,
      }, e.message);
    }
  }

  /// Mở bộ chọn thư mục của hệ thống và giữ quyền đọc+ghi lâu dài. Null nếu hủy.
  Future<PickedFolder?> pickFolder() async {
    final map = await _invoke<Map<Object?, Object?>>('pickFolder');
    final uri = map?['uri'];
    if (uri is! String) return null;
    final name = map?['name'];
    final inICloud = map?['inICloud'];
    return PickedFolder(
      uri: uri,
      name: name is String ? name : null,
      inICloud: inICloud is bool ? inICloud : null,
    );
  }

  /// Ghi [bytes] vào file [name] trong thư mục (ghi đè nếu trùng tên).
  Future<void> writeFile(String treeUri, String name, Uint8List bytes) =>
      _invoke<void>('writeFile', {
        'treeUri': treeUri,
        'name': name,
        'bytes': bytes,
      });

  /// Tên các mục con của thư mục.
  Future<List<String>> listFiles(String treeUri) async {
    final list = await _invoke<List<Object?>>('listFiles', {
      'treeUri': treeUri,
    });
    return [for (final n in list ?? const []) n as String];
  }

  Future<void> deleteFile(String treeUri, String name) =>
      _invoke<void>('deleteFile', {'treeUri': treeUri, 'name': name});

  /// Bỏ quyền đã giữ với thư mục (không xóa gì trong thư mục).
  Future<void> releaseFolder(String treeUri) =>
      _invoke<void>('releaseFolder', {'treeUri': treeUri});
}
