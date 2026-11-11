import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import 'biometric.dart';

/// Tên công tắc theo loại sinh trắc của máy (AC-119).
String biometricTitle(AppLocalizations l, BiometricKind kind) => switch (kind) {
  BiometricKind.fingerprint => l.biometricFingerprint,
  BiometricKind.faceId => l.biometricFaceId,
  BiometricKind.touchId => l.biometricTouchId,
};

IconData biometricIcon(BiometricKind kind) => kind == BiometricKind.faceId
    ? Symbols.face_rounded
    : Symbols.fingerprint_rounded;

/// Công tắc "Mở khoá bằng vân tay / Face ID / Touch ID" ở nhóm Bảo mật
/// (AC-119). Màn Cài đặt chỉ đặt hàng này khi PIN đang bật. Máy không có hoặc
/// chưa đăng ký sinh trắc mạnh → công tắc tắt, không chạm được, kèm lý do. Bật
/// phải xác thực sinh trắc một lần; mặc định tắt.
class BiometricSwitchRow extends ConsumerWidget {
  const BiometricSwitchRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final availability =
        ref.watch(biometricAvailabilityProvider).value ??
        const BiometricAvailability.none();
    final enabled = ref.watch(biometricEnabledProvider).value ?? false;
    final usable = availability.available;
    return SettingsSwitchRow(
      icon: biometricIcon(availability.kind),
      title: biometricTitle(l, availability.kind),
      subtitle: usable ? l.biometricNote : l.biometricUnavailable,
      value: usable && enabled,
      onChanged: usable ? (on) => _toggle(ref, l, on) : null,
    );
  }

  Future<void> _toggle(WidgetRef ref, AppLocalizations l, bool on) async {
    final settings = ref.read(biometricSettingsProvider);
    if (on) {
      final ok = await ref
          .read(biometricAuthProvider)
          .authenticate(
            BiometricPromptText(
              reason: l.biometricEnableReason,
              cancel: l.cancel,
            ),
          );
      if (!ok) {
        showMessage(l.biometricEnableFailed);
        return;
      }
    }
    await settings.setEnabled(on);
    ref.invalidate(biometricEnabledProvider);
  }
}
