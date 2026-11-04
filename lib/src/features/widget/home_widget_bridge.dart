import 'package:flutter/services.dart';

/// Cầu nối tới widget Android của Ví Gọn qua kênh `vigon/widget`.
///
/// Phía Android giữ dữ liệu của widget trong một file `SharedPreferences` riêng
/// của app (chế độ riêng tư) và chỉ chứa dòng trạng thái đã định dạng sẵn.
/// Nền tảng không có kênh này (test, iOS) thì bỏ qua, không lỗi.
abstract class HomeWidgetBridge {
  /// Ghi dòng trạng thái [line] vào bộ nhớ widget rồi vẽ lại widget.
  Future<void> show(String line);

  /// XÓA dòng trạng thái khỏi bộ nhớ widget (không chỉ ẩn) rồi vẽ lại widget.
  Future<void> clear();
}

class MethodChannelHomeWidgetBridge implements HomeWidgetBridge {
  const MethodChannelHomeWidgetBridge([
    this.channel = const MethodChannel(channelName),
  ]);

  static const channelName = 'vigon/widget';

  final MethodChannel channel;

  @override
  Future<void> show(String line) => _invoke('show', line);

  @override
  Future<void> clear() => _invoke('clear');

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Không có phần Android: không làm gì.
    } on PlatformException {
      // Android từ chối: widget giữ trạng thái cũ, lần đổi sau sẽ thử lại.
    }
  }
}
