import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Nơi lưu khóa-giá trị cho mã PIN. Trên máy là bộ nhớ an toàn của hệ điều
/// hành (Android Keystore); test dùng bản trong bộ nhớ.
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
class PinService {
  PinService(this._store, {Random? random})
    : _random = random ?? Random.secure();

  final SecretStore _store;
  final Random _random;

  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';
  static const _iterations = 20000;

  static bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<bool> isEnabled() async => await _store.read(_hashKey) != null;

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('Mã PIN phải gồm 4 số');
    final salt = base64Encode(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    await _store.write(_saltKey, salt);
    await _store.write(_hashKey, hashPin(pin, salt));
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
  }

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
