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

/// Kết quả một lần nhập PIN (F-11, D-007): đúng hay sai, đã sai bao nhiêu lần
/// và đang bị khoá tạm tới lúc nào. Bộ đếm nằm trong bộ nhớ an toàn nên gỡ app
/// hay khởi động lại không xoá được (chống dò 10.000 mã bằng tay).
class PinAttemptResult {
  const PinAttemptResult({
    required this.ok,
    this.failures = 0,
    this.lockedUntil,
  });

  /// Lần nhập này đúng.
  final bool ok;

  /// Tổng số lần sai liên tiếp (đặt lại về 0 khi đúng mã).
  final int failures;

  /// Đang bị khoá tạm tới thời điểm này; null khi không khoá.
  final DateTime? lockedUntil;

  /// Còn phải chờ bao lâu tại [now]; [Duration.zero] khi hết khoá.
  Duration remaining(DateTime now) {
    final until = lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isLockedAt(DateTime now) => remaining(now) > Duration.zero;
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
  static const _failuresKey = 'pin_failures';
  static const _lockedUntilKey = 'pin_locked_until';

  /// Sai liên tiếp bao nhiêu lần thì bắt đầu khoá tạm (D-007).
  static const maxFailures = 5;

  /// Thời gian khoá theo mức: lần sai thứ 5 → 30 giây, 6 → 1 phút, 7 → 5 phút,
  /// 8 trở đi → 15 phút. Đúng mã là đặt lại hết.
  static const _lockSteps = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
  ];

  /// Thời gian khoá sau [failures] lần sai liên tiếp; không khoá khi chưa tới
  /// [maxFailures].
  static Duration lockDuration(int failures) {
    final index = failures - maxFailures;
    if (index < 0) return Duration.zero;
    return _lockSteps[min(index, _lockSteps.length - 1)];
  }

  /// Cờ "Mở khoá bằng sinh trắc" (F-41). Nằm cùng chỗ PIN để [disable] (tắt PIN,
  /// Xoá toàn bộ dữ liệu, cài lại trên iOS) tắt luôn sinh trắc (AC-119).
  static const biometricKey = 'biometric_enabled';
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
    // Đổi PIN là một lần bắt đầu mới: bỏ bộ đếm lần sai và khoá tạm cũ.
    await _clearAttempts();
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

  /// Trạng thái đếm lần sai hiện tại (không thử mã): dùng lúc mở màn khoá để
  /// biết có đang bị khoá tạm hay không.
  Future<PinAttemptResult> currentAttempt(DateTime now) async {
    final failures = await _readFailures();
    final until = await _readLockedUntil();
    if (until == null || !until.isAfter(now)) {
      return PinAttemptResult(ok: false, failures: failures);
    }
    return PinAttemptResult(ok: false, failures: failures, lockedUntil: until);
  }

  /// Thử mã và cập nhật bộ đếm (D-007). Đang trong thời gian khoá thì không
  /// băm mã (trả kết quả khoá ngay), đúng mã thì xoá bộ đếm, sai thì tăng và
  /// khoá tạm khi tới [maxFailures].
  Future<PinAttemptResult> verifyAttempt(String pin, DateTime now) async {
    final lockedUntil = await _readLockedUntil();
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return PinAttemptResult(
        ok: false,
        failures: await _readFailures(),
        lockedUntil: lockedUntil,
      );
    }
    if (await verify(pin)) {
      await _clearAttempts();
      return const PinAttemptResult(ok: true);
    }
    final failures = await _readFailures() + 1;
    final duration = lockDuration(failures);
    final until = duration == Duration.zero ? null : now.add(duration);
    await _store.write(_failuresKey, '$failures');
    if (until == null) {
      await _store.delete(_lockedUntilKey);
    } else {
      await _store.write(_lockedUntilKey, until.toIso8601String());
    }
    return PinAttemptResult(ok: false, failures: failures, lockedUntil: until);
  }

  Future<int> _readFailures() async =>
      int.tryParse(await _store.read(_failuresKey) ?? '') ?? 0;

  Future<DateTime?> _readLockedUntil() async =>
      DateTime.tryParse(await _store.read(_lockedUntilKey) ?? '');

  Future<void> _clearAttempts() async {
    await _store.delete(_failuresKey);
    await _store.delete(_lockedUntilKey);
  }

  Future<void> disable() async {
    await _store.delete(_hashKey);
    await _store.delete(_saltKey);
    await _store.delete(_installKey);
    await _store.delete(biometricKey);
    await _clearAttempts();
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
