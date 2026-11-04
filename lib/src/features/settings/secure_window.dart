import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Bật/tắt `FLAG_SECURE` của cửa sổ Android qua kênh `vigon/secure` (AC-56).
/// Nền tảng không có kênh này (test, iOS) thì bỏ qua, không lỗi.
class SecureWindow {
  const SecureWindow([this.channel = const MethodChannel(channelName)]);

  static const channelName = 'vigon/secure';

  final MethodChannel channel;

  Future<void> setSecure(bool on) async {
    try {
      await channel.invokeMethod<void>('setSecure', on);
    } on MissingPluginException {
      // Không có phần Android: không làm gì.
    } on PlatformException {
      // Android từ chối: giữ nguyên trạng thái cũ.
    }
  }
}

final secureWindowProvider = Provider<SecureWindow>(
  (ref) => const SecureWindow(),
);

final secureWindowEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSecureWindow(),
);

/// Đẩy giá trị đã lưu sang Android khi mở app và mỗi khi công tắc đổi.
/// `VigonApp` theo dõi provider này.
final secureWindowSyncProvider = Provider<void>((ref) {
  final service = ref.watch(secureWindowProvider);
  ref.listen(secureWindowEnabledProvider, (_, next) {
    final on = next.value;
    if (on != null) service.setSecure(on);
  }, fireImmediately: true);
});
