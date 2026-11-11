import 'package:vigon/src/features/lock/biometric.dart';

/// Sinh trắc giả cho test F-41: chọn máy có/không có sinh trắc mạnh, loại
/// sinh trắc, và kết quả của từng lần xác thực.
class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({
    this.available = true,
    this.kind = BiometricKind.fingerprint,
    this.result = true,
  });

  bool available;
  BiometricKind kind;

  /// Kết quả trả cho lần xác thực kế tiếp (true = đúng; false = huỷ/sai/khoá).
  bool result;
  final prompts = <BiometricPromptText>[];

  @override
  Future<BiometricAvailability> availability() async =>
      BiometricAvailability(available: available, kind: kind);

  @override
  Future<bool> authenticate(BiometricPromptText text) async {
    prompts.add(text);
    return result;
  }
}
