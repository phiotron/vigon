import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/tokens.g.dart';
import '../settings/data_actions.dart';
import 'app_lock.dart';
import 'biometric.dart';
import 'biometric_switch.dart';
import 'pin_pad.dart';

/// Màn khóa phủ lên toàn app khi bật PIN (AC-32, AC-34). Có Navigator riêng
/// vì nằm ngoài Navigator của router.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.checking});

  final bool checking;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surface;
    if (checking) {
      return ColoredBox(color: background, child: const SizedBox.expand());
    }
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const _LockBody()),
    );
  }
}

class _LockBody extends ConsumerStatefulWidget {
  const _LockBody();

  @override
  ConsumerState<_LockBody> createState() => _LockBodyState();
}

class _LockBodyState extends ConsumerState<_LockBody> {
  String? _error;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    // F-41 (AC-120): bật sinh trắc thì tự mở hộp của hệ thống một lần khi màn
    // khoá hiện (mở app, quay lại sau > 1 phút, vào từ widget hay thông báo).
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  /// Hỏi sinh trắc. Đúng → vào app; huỷ, sai, bị khoá tạm → ở lại màn PIN,
  /// nhập PIN vẫn được, nút sinh trắc để thử lại.
  Future<void> _tryBiometric() async {
    if (_biometricBusy || !mounted) return;
    _biometricBusy = true;
    try {
      if (!await ref.read(biometricEnabledProvider.future)) return;
      final availability = await ref.read(biometricAvailabilityProvider.future);
      if (!availability.available || !mounted) return;
      final l = AppLocalizations.of(context);
      final ok = await ref
          .read(biometricAuthProvider)
          .authenticate(
            BiometricPromptText(
              reason: l.biometricReason,
              cancel: l.biometricCancel,
            ),
          );
      if (ok) ref.read(lockProvider.notifier).unlockWithBiometric();
    } catch (_) {
      // Lỗi đọc cờ hay plugin: ở lại màn PIN.
    } finally {
      _biometricBusy = false;
    }
  }

  /// Quên mã (1.3): báo không lấy lại được mã; đồng ý thì sang hai bước xác
  /// nhận xóa (1.4, 1.5) trong [deleteEverything]. Hủy ở bước nào cũng về
  /// màn khóa.
  Future<void> _forgot() async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.lock_reset_rounded,
      title: l.forgotPin,
      body: l.forgotPinBody,
      action: l.deleteAll,
      style: ConfirmStyle.dangerText,
    );
    if (!ok || !mounted) return;
    if (await deleteEverything(context, ref)) {
      ref.read(lockProvider.notifier).unlockAfterReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Nút thử lại sinh trắc chỉ hiện khi đã bật và máy còn sinh trắc mạnh.
    final availability = ref.watch(biometricAvailabilityProvider).value;
    final biometric =
        (ref.watch(biometricEnabledProvider).value ?? false) &&
            (availability?.available ?? false)
        ? availability
        : null;
    // Bố cục `.vg-pin` (1.1, 1.2): icon khóa, tiêu đề, chấm, dòng lỗi ở trên;
    // bàn phím dồn xuống đáy, "Quên mã" dưới cùng. Thiếu chỗ (cỡ chữ 200%)
    // thì cả khối cuộn được.
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(top: VgSpace.s6),
                child: Column(
                  children: [
                    Expanded(
                      child: PinPad(
                        expand: true,
                        leading: Icon(
                          Symbols.lock_rounded,
                          fill: 1,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: l.enterPin,
                        titleStyle: Theme.of(context).textTheme.titleLarge,
                        error: _error,
                        onCompleted: (pin) async {
                          final ok = await ref
                              .read(lockProvider.notifier)
                              .unlock(pin);
                          if (ok || !mounted) return;
                          // Sai mã: rung nhẹ trên cả hai nền tảng (1.2).
                          HapticFeedback.lightImpact();
                          setState(() => _error = l.wrongPin);
                        },
                      ),
                    ),
                    if (biometric != null)
                      Padding(
                        padding: const EdgeInsets.only(top: VgSpace.s4),
                        child: TextButton.icon(
                          onPressed: _tryBiometric,
                          icon: Icon(biometricIcon(biometric.kind)),
                          label: Text(l.biometricUnlockButton),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: VgSpace.s4,
                        bottom: VgSpace.s2,
                      ),
                      child: TextButton(
                        onPressed: _forgot,
                        child: Text(l.forgotPin),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
