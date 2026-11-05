import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/pin_service.dart';
import '../../providers.dart';
import '../settings/auto_backup_providers.dart';

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const SecureSecretStore(),
);

final pinServiceProvider = Provider<PinService>(
  (ref) => PinService(
    ref.watch(secretStoreProvider),
    settings: () => ref.read(settingsRepositoryProvider),
  ),
);

/// Bật khóa PIN hay chưa, để màn Cài đặt hiện đúng công tắc.
final pinEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(pinServiceProvider).isEnabled(),
);

enum AppLockState { checking, locked, unlocked }

/// Trạng thái khóa app: khóa khi mở app và khi quay lại sau hơn 1 phút ở nền (AC-32).
class LockNotifier extends Notifier<AppLockState> {
  static const relockAfter = Duration(minutes: 1);

  DateTime? _hiddenAt;

  @override
  AppLockState build() {
    _init();
    return AppLockState.checking;
  }

  Future<void> _init() async {
    final pin = ref.read(pinServiceProvider);
    try {
      // Cài lại trên iOS: Keychain còn PIN cũ nhưng cơ sở dữ liệu mới (iOS-02).
      if (await pin.clearIfReinstalled()) ref.invalidate(pinEnabledProvider);
    } catch (_) {
      // Không đọc được bộ nhớ an toàn hay cơ sở dữ liệu: không xóa gì.
    }
    var enabled = true;
    try {
      enabled = await pin.isEnabled();
    } catch (_) {
      // Không đọc được bộ nhớ an toàn (Keystore hỏng): coi như đang khóa để
      // người dùng thấy màn khóa và nút "Quên mã" thay vì màn trắng.
    }
    state = enabled ? AppLockState.locked : AppLockState.unlocked;
  }

  void onHidden() => _hiddenAt ??= ref.read(clockProvider)();

  Future<void> onResumed() async {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (state != AppLockState.unlocked || hiddenAt == null) return;
    if (ref.read(clockProvider)().difference(hiddenAt) <= relockAfter) return;
    if (await ref.read(pinServiceProvider).isEnabled()) {
      state = AppLockState.locked;
    }
  }

  Future<bool> unlock(String pin) async {
    var ok = false;
    try {
      ok = await ref.read(pinServiceProvider).verify(pin);
    } catch (_) {
      // Lỗi bộ nhớ an toàn: không mở khóa.
    }
    if (ok) state = AppLockState.unlocked;
    return ok;
  }

  /// Mở khóa sau khi người dùng đã xóa toàn bộ dữ liệu vì quên mã (AC-34).
  void unlockAfterReset() => state = AppLockState.unlocked;
}

final lockProvider = NotifierProvider<LockNotifier, AppLockState>(
  LockNotifier.new,
);

/// Theo dõi app ra nền và quay lại: khóa lại khi cần, tạo khoản định kỳ tới hạn (AC-24, AC-32).
class AppLifecycleWatcher extends ConsumerStatefulWidget {
  const AppLifecycleWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleWatcher> createState() =>
      _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends ConsumerState<AppLifecycleWatcher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: () {
        ref.read(lockProvider.notifier).onHidden();
        // Sao lưu tự động (F-24): không chặn giao diện, không ném lỗi.
        unawaited(ref.read(autoBackupServiceProvider).maybeRunDaily());
      },
      onResume: () {
        ref.read(lockProvider.notifier).onResumed();
        ref.read(todayProvider.notifier).refresh();
        ref
            .read(recurringRepositoryProvider)
            .generateDue(ref.read(clockProvider)());
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
