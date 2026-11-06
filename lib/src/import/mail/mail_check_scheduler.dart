import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lịch kiểm thư nền (AC-82): chỉ Android, khoảng mỗi giờ khi app đóng. iOS
/// chỉ kiểm khi mở/quay lại app nên không có lịch.
abstract class MailCheckScheduler {
  /// Bật lịch (có ít nhất một hộp thư).
  Future<void> enable();

  /// Tắt lịch (không còn hộp thư, hoặc "Xóa toàn bộ dữ liệu").
  Future<void> disable();
}

class NoopMailCheckScheduler implements MailCheckScheduler {
  const NoopMailCheckScheduler();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

/// Android: kênh `vigon/mail_schedule` tới `MailCheckJob.kt`. Phía Kotlin đặt
/// một job định kỳ ~1 giờ của JobScheduler (lịch không chính xác, giữ qua khởi
/// động lại máy bằng `setPersisted` — dùng quyền `RECEIVE_BOOT_COMPLETED` đã
/// có; không quyền báo thức chính xác, không điều kiện mạng vì điều kiện mạng
/// cần `ACCESS_NETWORK_STATE`). Job dựng FlutterEngine không giao diện như sao
/// lưu tự động và chạy `mailCheckBackgroundMain`.
class AndroidMailCheckScheduler implements MailCheckScheduler {
  const AndroidMailCheckScheduler([this.channel = const MethodChannel(name)]);

  static const name = 'vigon/mail_schedule';

  final MethodChannel channel;

  @override
  Future<void> enable() async {
    try {
      await channel.invokeMethod<void>('enable');
    } catch (_) {
      // Không có kênh (test) hay lỗi hệ thống: vẫn kiểm khi mở app.
    }
  }

  @override
  Future<void> disable() async {
    try {
      await channel.invokeMethod<void>('disable');
    } catch (_) {}
  }
}

/// Bản đúng cho nền tảng đang chạy.
MailCheckScheduler platformMailCheckScheduler() =>
    defaultTargetPlatform == TargetPlatform.android
    ? const AndroidMailCheckScheduler()
    : const NoopMailCheckScheduler();
