import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../../data/pin_service.dart';
import 'imap_gateway.dart';
import 'mail_provider.dart';

/// Một hộp thư người dùng đã thêm (F-28). Cấu hình theo máy: không vào cơ sở
/// dữ liệu, file sao lưu, CSV/Excel/PDF hay log (AC-79, AC-121).
class Mailbox {
  const Mailbox({
    required this.id,
    required this.provider,
    required this.address,
    required this.connectedAt,
    required this.uidValidity,
    required this.lastUid,
    this.lastCheckAt,
    this.lastError,
    this.needsPassword = false,
    this.unreadable = 0,
  });

  /// Id ô lưu (`m0`, `m1`, `m2`), không phải địa chỉ.
  final String id;
  final MailProvider provider;

  /// Địa chỉ, viết thường.
  final String address;

  /// Lúc kết nối: chỉ nhận thư từ lúc này trở đi (AC-81).
  final DateTime connectedAt;

  /// UIDVALIDITY của INBOX khi ghi [lastUid]; đổi thì UID cũ mất nghĩa.
  final int uidValidity;

  /// UID lớn nhất đã xử lý (hoặc UIDNEXT − 1 lúc kết nối): không tải lại.
  final int lastUid;

  /// Lần kiểm cuối (kể cả lần lỗi).
  final DateTime? lastCheckAt;

  /// Lỗi của lần kiểm cuối, null nếu được.
  final MailErrorKind? lastError;

  /// Sai mật khẩu: dừng kiểm tự động tới khi người dùng nhập lại (AC-82).
  final bool needsPassword;

  /// "N email MB không đọc được" (AC-85).
  final int unreadable;

  Mailbox copyWith({
    int? uidValidity,
    int? lastUid,
    DateTime? lastCheckAt,
    MailErrorKind? lastError,
    bool clearError = false,
    bool? needsPassword,
    int? unreadable,
  }) => Mailbox(
    id: id,
    provider: provider,
    address: address,
    connectedAt: connectedAt,
    uidValidity: uidValidity ?? this.uidValidity,
    lastUid: lastUid ?? this.lastUid,
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
    needsPassword: needsPassword ?? this.needsPassword,
    unreadable: unreadable ?? this.unreadable,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'provider': provider.name,
    'address': address,
    'connectedAt': connectedAt.toUtc().toIso8601String(),
    'uidValidity': uidValidity,
    'lastUid': lastUid,
    'lastCheckAt': lastCheckAt?.toUtc().toIso8601String(),
    'lastError': lastError?.name,
    'needsPassword': needsPassword,
    'unreadable': unreadable,
  };

  static Mailbox? fromJson(Object? json) {
    if (json is! Map) return null;
    final provider = MailProvider.byName(json['provider'] as String?);
    final id = json['id'];
    final address = json['address'];
    final connectedAt = DateTime.tryParse('${json['connectedAt']}');
    if (provider == null ||
        id is! String ||
        address is! String ||
        connectedAt == null) {
      return null;
    }
    MailErrorKind? error;
    for (final k in MailErrorKind.values) {
      if (k.name == json['lastError']) error = k;
    }
    final lastCheck = json['lastCheckAt'];
    return Mailbox(
      id: id,
      provider: provider,
      address: address,
      connectedAt: connectedAt.toLocal(),
      uidValidity: (json['uidValidity'] as num?)?.toInt() ?? 0,
      lastUid: (json['lastUid'] as num?)?.toInt() ?? 0,
      lastCheckAt: lastCheck is String
          ? DateTime.tryParse(lastCheck)?.toLocal()
          : null,
      lastError: error,
      needsPassword: json['needsPassword'] == true,
      unreadable: (json['unreadable'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'Mailbox($id, ${provider.name})'; // không in địa chỉ
}

/// Dấu cài đặt nằm trong bộ nhớ riêng của app (bị xoá khi gỡ app). iOS giữ
/// Keychain sau khi gỡ app (như PIN, D-017): Keychain có hộp thư mà dấu không
/// khớp → app vừa cài lại → xoá hộp thư cũ.
abstract class InstallMarker {
  /// Mã đang có; null nếu chưa có; ném lỗi nếu không đọc được.
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class FileInstallMarker implements InstallMarker {
  const FileInstallMarker();

  Future<File> _file() async => File(
    '${(await getApplicationSupportDirectory()).path}/vigon_mail_install',
  );

  @override
  Future<String?> read() async {
    final f = await _file();
    return f.existsSync() ? (await f.readAsString()).trim() : null;
  }

  @override
  Future<void> write(String value) async {
    final f = await _file();
    await f.parent.create(recursive: true);
    await f.writeAsString(value, flush: true);
  }

  @override
  Future<void> delete() async {
    final f = await _file();
    if (f.existsSync()) await f.delete();
  }
}

class MemoryInstallMarker implements InstallMarker {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> delete() async => value = null;
}

/// Lưu hộp thư trong [SecretStore] (Keystore/Keychain), như cấu hình sao lưu
/// tự động: danh sách (không có mật khẩu) ở một khoá, mật khẩu ứng dụng của
/// mỗi ô ở khoá riêng. Không có gì trong bảng `settings`.
class MailboxStore {
  MailboxStore(this._secrets, {InstallMarker? marker, Random? random})
    : _marker = marker ?? const FileInstallMarker(),
      _random = random ?? Random.secure();

  final SecretStore _secrets;
  final InstallMarker _marker;
  final Random _random;

  static const boxesKey = 'mail_boxes';
  static const introKey = 'mail_intro_seen';
  static const installKey = 'mail_install_id';

  /// Id ô cố định để xoá hết được kể cả khi danh sách hỏng.
  static const slotIds = ['m0', 'm1', 'm2'];

  static String passwordKey(String id) => 'mail_pw_$id';

  /// Mọi khoá app có thể ghi cho phần hộp thư.
  static List<String> get allKeys => [
    boxesKey,
    introKey,
    installKey,
    for (final id in slotIds) passwordKey(id),
  ];

  Future<List<Mailbox>> load() async {
    final raw = await _secrets.read(boxesKey);
    if (raw == null) return [];
    List<Mailbox> boxes;
    try {
      final list = jsonDecode(raw);
      boxes = [
        if (list is List)
          for (final item in list) ?Mailbox.fromJson(item),
      ];
    } catch (_) {
      boxes = [];
    }
    if (boxes.isNotEmpty && await _reinstalled()) {
      await clear();
      return [];
    }
    return boxes;
  }

  Future<bool> _reinstalled() async {
    final saved = await _secrets.read(installKey);
    if (saved == null) return false; // chưa từng đặt dấu
    try {
      return await _marker.read() != saved;
    } catch (_) {
      return false; // không đọc được thì không xoá nhầm
    }
  }

  Future<void> save(List<Mailbox> boxes) async {
    if (boxes.isEmpty) {
      await _secrets.delete(boxesKey);
      return;
    }
    await _ensureMarker();
    await _secrets.write(
      boxesKey,
      jsonEncode([for (final b in boxes) b.toJson()]),
    );
  }

  Future<void> _ensureMarker() async {
    try {
      final saved = await _secrets.read(installKey);
      final current = await _marker.read();
      if (saved != null && saved == current) return;
      final id =
          current ??
          base64Url.encode(List.generate(12, (_) => _random.nextInt(256)));
      if (current == null) await _marker.write(id);
      await _secrets.write(installKey, id);
    } catch (_) {
      // Không đặt được dấu: chỉ mất phần dọn khi cài lại trên iOS.
    }
  }

  Future<String?> password(String id) => _secrets.read(passwordKey(id));

  Future<void> setPassword(String id, String password) =>
      _secrets.write(passwordKey(id), password);

  Future<void> deletePassword(String id) => _secrets.delete(passwordKey(id));

  Future<bool> introSeen() async => await _secrets.read(introKey) == '1';

  Future<void> setIntroSeen() => _secrets.write(introKey, '1');

  /// Ô trống đầu tiên, null nếu đã đủ [maxMailboxes].
  String? freeSlot(List<Mailbox> boxes) {
    final used = {for (final b in boxes) b.id};
    for (final id in slotIds.take(maxMailboxes)) {
      if (!used.contains(id)) return id;
    }
    return null;
  }

  /// Xoá MỌI thứ của hộp thư khỏi Keystore/Keychain (AC-79, AC-123).
  Future<void> clear() async {
    for (final key in allKeys) {
      await _secrets.delete(key);
    }
    try {
      await _marker.delete();
    } catch (_) {}
  }
}
