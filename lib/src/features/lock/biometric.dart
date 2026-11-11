import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

import '../../data/pin_service.dart';
import 'app_lock.dart';

/// Loại sinh trắc để đặt tên công tắc (AC-119): Android luôn "vân tay";
/// iPhone theo máy (Face ID hoặc Touch ID).
enum BiometricKind { fingerprint, faceId, touchId }

/// Máy có sinh trắc MẠNH đã đăng ký hay không, và loại nào.
class BiometricAvailability {
  const BiometricAvailability({required this.available, required this.kind});

  const BiometricAvailability.none()
    : available = false,
      kind = BiometricKind.fingerprint;

  final bool available;
  final BiometricKind kind;
}

/// Chữ trên hộp sinh trắc của hệ điều hành.
class BiometricPromptText {
  const BiometricPromptText({required this.reason, required this.cancel});

  final String reason;
  final String cancel;
}

/// Lớp ngăn giữa app và sinh trắc của hệ điều hành, để test dùng bản giả
/// (AC-119, AC-120). App không bao giờ thấy dữ liệu sinh trắc: chỉ nhận
/// đúng/sai.
abstract class BiometricAuth {
  Future<BiometricAvailability> availability();

  /// true chỉ khi người dùng xác thực đúng. Huỷ, sai, bị khoá tạm, lỗi → false.
  Future<bool> authenticate(BiometricPromptText text);
}

/// Bản thật dùng `local_auth`. Chỉ sinh trắc (không cho mã khoá máy thay thế,
/// `biometricOnly`); Android còn đòi máy có sinh trắc lớp MẠNH (Class 3), máy
/// chỉ có loại yếu (mở khoá khuôn mặt 2D) coi như không có.
class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricAvailability> availability() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return const BiometricAvailability.none();
      }
      final types = await _auth.getAvailableBiometrics();
      return biometricAvailabilityOf(types, defaultTargetPlatform);
    } catch (_) {
      return const BiometricAvailability.none();
    }
  }

  @override
  Future<bool> authenticate(BiometricPromptText text) async {
    try {
      return await _auth.authenticate(
        localizedReason: text.reason,
        biometricOnly: true,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: text.reason,
            cancelButton: text.cancel,
          ),
          // Chuỗi rỗng ẩn nút "Nhập mật mã" của iOS: PIN của app là đường dự
          // phòng, không phải mã khoá máy (AC-120).
          IOSAuthMessages(
            cancelButton: text.cancel,
            localizedFallbackTitle: '',
          ),
        ],
      );
    } catch (_) {
      // LocalAuthException: huỷ, sai quá số lần, bị khoá tạm, không có UI…
      return false;
    }
  }
}

/// Suy loại và tính khả dụng từ danh sách sinh trắc đã đăng ký (hàm thuần để
/// test). Android: phải có `strong`. iOS: Face ID hoặc Touch ID (đều mạnh).
BiometricAvailability biometricAvailabilityOf(
  List<BiometricType> types,
  TargetPlatform platform,
) {
  if (platform == TargetPlatform.iOS) {
    if (types.contains(BiometricType.face)) {
      return const BiometricAvailability(
        available: true,
        kind: BiometricKind.faceId,
      );
    }
    if (types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong)) {
      return const BiometricAvailability(
        available: true,
        kind: BiometricKind.touchId,
      );
    }
    return const BiometricAvailability(
      available: false,
      kind: BiometricKind.faceId,
    );
  }
  return BiometricAvailability(
    available: types.contains(BiometricType.strong),
    kind: BiometricKind.fingerprint,
  );
}

/// Cờ bật/tắt sinh trắc, nằm trong bộ nhớ an toàn cạnh PIN
/// ([PinService.biometricKey]) nên tắt PIN hay xoá toàn bộ dữ liệu là tắt
/// luôn. Không đi theo file sao lưu.
class BiometricSettings {
  BiometricSettings(this._store, this._pin);

  final SecretStore _store;
  final PinService _pin;

  /// Bật chỉ có nghĩa khi PIN còn bật (AC-119).
  Future<bool> isEnabled() async {
    if (!await _pin.isEnabled()) return false;
    return await _store.read(PinService.biometricKey) == '1';
  }

  Future<void> setEnabled(bool on) async {
    if (on) {
      if (!await _pin.isEnabled()) return;
      await _store.write(PinService.biometricKey, '1');
    } else {
      await _store.delete(PinService.biometricKey);
    }
  }
}

/// Bản thật; test ghi đè bằng bản giả.
final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => LocalBiometricAuth(),
);

final biometricSettingsProvider = Provider<BiometricSettings>(
  (ref) => BiometricSettings(
    ref.watch(secretStoreProvider),
    ref.watch(pinServiceProvider),
  ),
);

/// Sinh trắc đang bật (và PIN đang bật). Đổi PIN thì tính lại.
final biometricEnabledProvider = FutureProvider<bool>((ref) {
  ref.watch(pinEnabledProvider);
  return ref.watch(biometricSettingsProvider).isEnabled();
});

/// Máy có sinh trắc mạnh đã đăng ký không. Đọc lại khi màn Cài đặt mở lại
/// (`ref.invalidate`) vì người dùng có thể vừa đăng ký trong cài đặt máy.
final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>(
  (ref) => ref.watch(biometricAuthProvider).availability(),
);
