import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'backup.dart';

/// Phong bì mã hóa file sao lưu (AC-55, D-010).
///
/// `{"format":"vigon-backup-encrypted","version":1,"kdf":"pbkdf2-hmac-sha256",
/// "iterations":N,"salt":b64,"nonce":b64,"ciphertext":b64}`. Khóa 256-bit suy ra
/// bằng PBKDF2-HMAC-SHA256 từ mật khẩu (UTF-8, không cắt khoảng trắng, không
/// chuẩn hóa Unicode) và muối 16 byte; mã hóa AES-256-GCM, nonce 12 byte;
/// `ciphertext` = bản mã nối thẻ xác thực GCM 16 byte; AAD = UTF-8 của
/// `"<format>:<version>"`.
const encryptedBackupFormat = 'vigon-backup-encrypted';
const encryptedBackupVersion = 1;
const backupKdf = 'pbkdf2-hmac-sha256';

/// Số vòng mặc định. Thư viện chạy Dart thuần (không có mã máy), nên 100.000
/// vòng là mức vài giây trên điện thoại tầm thấp; con số nằm trong phong bì
/// nên sau này tăng được mà không làm hỏng file cũ.
const backupKdfIterations = 100000;

/// Trần số vòng chấp nhận khi đọc, để file độc hại không treo máy.
const backupKdfMaxIterations = 1000000;

const _saltLength = 16;
const _nonceLength = 12;
const _tagLength = 16;

/// Sai mật khẩu, hoặc phong bì bị sửa (không phân biệt được hai trường hợp).
class BackupPasswordException implements Exception {
  @override
  String toString() => 'BackupPasswordException';
}

Uint8List _randomBytes(int n) {
  final r = Random.secure();
  return Uint8List.fromList([for (var i = 0; i < n; i++) r.nextInt(256)]);
}

List<int> _aad(String format, int version) => utf8.encode('$format:$version');

Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) =>
    Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);

/// Nội dung có phải phong bì mã hóa không (chỉ xem trường `format`).
bool isEncryptedBackup(String content) {
  try {
    final root = jsonDecode(content);
    return root is Map && root['format'] == encryptedBackupFormat;
  } catch (_) {
    return false;
  }
}

typedef _Envelope = ({
  int iterations,
  Uint8List salt,
  Uint8List nonce,
  Uint8List cipherText,
  Uint8List tag,
});

_Envelope _parseEnvelope(String content) {
  final Map<String, dynamic> root;
  try {
    root = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    throw BackupFormatException('không phải JSON');
  }
  if (root['format'] != encryptedBackupFormat) {
    throw BackupFormatException('sai định dạng');
  }
  final version = root['version'];
  if (version is! int || version < 1 || version > encryptedBackupVersion) {
    throw BackupFormatException('phiên bản $version không hỗ trợ');
  }
  if (root['kdf'] != backupKdf) {
    throw BackupFormatException('kdf không hỗ trợ');
  }
  final iterations = root['iterations'];
  if (iterations is! int ||
      iterations < 1 ||
      iterations > backupKdfMaxIterations) {
    throw BackupFormatException('số vòng không hợp lệ');
  }
  Uint8List field(String name, {int? length, int minLength = 0}) {
    final v = root[name];
    if (v is! String) throw BackupFormatException('thiếu $name');
    final Uint8List bytes;
    try {
      bytes = base64.decode(v);
    } catch (_) {
      throw BackupFormatException('$name không phải base64');
    }
    if ((length != null && bytes.length != length) ||
        bytes.length < minLength) {
      throw BackupFormatException('$name sai độ dài');
    }
    return bytes;
  }

  final salt = field('salt', length: _saltLength);
  final nonce = field('nonce', length: _nonceLength);
  final sealed = field('ciphertext', minLength: _tagLength);
  return (
    iterations: iterations,
    salt: salt,
    nonce: nonce,
    cipherText: Uint8List.sublistView(sealed, 0, sealed.length - _tagLength),
    tag: Uint8List.sublistView(sealed, sealed.length - _tagLength),
  );
}

/// Kiểm hình dạng phong bì (không cần mật khẩu, không tốn thời gian). Ném
/// [BackupFormatException] nếu sai định dạng, phiên bản, độ dài trường...
void checkEncryptedBackup(String content) => _parseEnvelope(content);

/// Mã hóa [json] (nội dung `exportBackup`) bằng [password]; trả về phong bì JSON.
/// Hai lần gọi với cùng dữ liệu cho kết quả khác nhau (muối và nonce ngẫu nhiên).
Future<String> encryptBackup(
  String json,
  String password, {
  int iterations = backupKdfIterations,
}) async {
  final salt = _randomBytes(_saltLength);
  final nonce = _randomBytes(_nonceLength);
  final key = await _deriveKey(password, salt, iterations);
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(json),
    secretKey: key,
    nonce: nonce,
    aad: _aad(encryptedBackupFormat, encryptedBackupVersion),
  );
  return jsonEncode({
    'format': encryptedBackupFormat,
    'version': encryptedBackupVersion,
    'kdf': backupKdf,
    'iterations': iterations,
    'salt': base64.encode(salt),
    'nonce': base64.encode(nonce),
    'ciphertext': base64.encode([...box.cipherText, ...box.mac.bytes]),
  });
}

/// Giải mã phong bì. Ném [BackupFormatException] nếu hình dạng sai,
/// [BackupPasswordException] nếu sai mật khẩu hoặc bản mã/muối/nonce/số vòng bị sửa.
Future<String> decryptBackup(String envelope, String password) async {
  final e = _parseEnvelope(envelope);
  final key = await _deriveKey(password, e.salt, e.iterations);
  try {
    final plain = await AesGcm.with256bits().decrypt(
      SecretBox(e.cipherText, nonce: e.nonce, mac: Mac(e.tag)),
      secretKey: key,
      aad: _aad(encryptedBackupFormat, encryptedBackupVersion),
    );
    return utf8.decode(plain);
  } on SecretBoxAuthenticationError {
    throw BackupPasswordException();
  } on FormatException {
    // Giải mã được nhưng không phải UTF-8: coi như hỏng.
    throw BackupPasswordException();
  }
}

/// Như [encryptBackup] nhưng chạy ở isolate riêng để màn hình không bị đơ
/// trong lúc suy ra khóa (có thể vài giây).
Future<String> encryptBackupOffThread(String json, String password) =>
    Isolate.run(() => encryptBackup(json, password));

/// Như [decryptBackup] nhưng chạy ở isolate riêng.
Future<String> decryptBackupOffThread(String envelope, String password) =>
    Isolate.run(() => decryptBackup(envelope, password));
