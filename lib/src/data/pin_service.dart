import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'settings_repository.dart';

/// Nơi lưu khóa-giá trị cho mã PIN. Trên máy là bộ nhớ an toàn của hệ điều
/// hành (Android Keystore, iOS Keychain); test dùng bản trong bộ nhớ.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemorySecretStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Mã PIN 4 số khóa app (F-11). Chỉ lưu muối và mã băm, không lưu mã (AC-33).
///
/// iOS giữ Keychain sau khi gỡ app trong khi cơ sở dữ liệu bị xóa (iOS-02).
/// Vì vậy khi có [settings], lúc đặt PIN ghi thêm một mã cài đặt ngẫu nhiên vào
/// cả bộ nhớ an toàn và bảng settings; [clearIfReinstalled] xóa PIN khi hai mã
/// không khớp (cơ sở dữ liệu mới). [settings] là hàm, chỉ gọi khi thật cần, để
/// mở app không có PIN thì không phải mở cơ sở dữ liệu ở bước này.
class PinService {
  PinService(this._store, {this._settings, Random? random})
    : _random = random ?? Random.secure();

  final SecretStore _store;
  final SettingsRepository Function()? _settings;
  final Random _random;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _installKey = 'pin_install_id';
  static const _iterations = 20000;

  static bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<bool> isEnabled() async => await _store.read(_hashKey) != null;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('Mã PIN phải gồm 4 số');
    final settings = _settings?.call();
    if (settings != null) {
      // Dùng lại mã đã có trong cơ sở dữ liệu: đổi PIN mà ghi Keychain lỗi giữa
      // chừng thì PIN cũ vẫn khớp mã, không bị xóa nhầm lần mở sau.
      var installId = await settings.readPinInstallId();
      if (installId == null) {
        installId = _randomBase64();
        await settings.setPinInstallId(installId);
      }
      await _store.write(_installKey, installId);
    }
    final salt = _randomBase64();
    await _store.write(_saltKey, salt);
    await _store.write(_hashKey, hashPin(pin, salt));
  }

  /// Gọi một lần khi mở app, trước khi hỏi PIN. Bộ nhớ an toàn có mã cài đặt
  /// mà bảng settings không có đúng mã đó, tức là cơ sở dữ liệu vừa tạo mới
  /// (gỡ rồi cài lại trên iOS): xóa PIN cũ để người dùng không bị khóa ngoài.
  /// PIN đặt trước khi có mã cài đặt thì giữ nguyên. Trả về true nếu đã xóa.
  Future<bool> clearIfReinstalled() async {
    final settings = _settings;
    if (settings == null) return false;
    final installId = await _store.read(_installKey);
    if (installId == null) return false;
    if (await settings().readPinInstallId() == installId) return false;
    await disable();
    return true;
  }

  Future<bool> verify(String pin) async {
    final salt = await _store.read(_saltKey);
    final hash = await _store.read(_hashKey);
    if (salt == null || hash == null) return false;
    return _constantTimeEquals(hashPin(pin, salt), hash);
  }

  Future<void> disable() async {
    await _store.delete(_hashKey);
    await _store.delete(_saltKey);
    await _store.delete(_installKey);
  }

  String _randomBase64() =>
      base64Encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  /// SHA-256 lặp nhiều vòng trên muối + mã, làm chậm việc dò thử.
  static String hashPin(String pin, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Encode(digest);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
