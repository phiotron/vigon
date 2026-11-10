import 'package:flutter/services.dart';

/// Cầu nối tới widget Android của Ví Gọn qua kênh `vigon/widget`.
///
/// Phía Android giữ dữ liệu của widget trong một file `SharedPreferences` riêng
/// của app (chế độ riêng tư) và chỉ chứa dòng trạng thái đã định dạng sẵn.
/// Nền tảng không có kênh này (test, iOS) thì bỏ qua, không lỗi.
/// Phần "số lớn" của widget vẽ lại (mockup v4 EXT-01): nhãn, số tiền, dòng
/// phụ dưới thanh, % hạn mức (null = không có thanh), [warn] ≥ 80 %.
class WidgetHero {
  const WidgetHero({
    required this.label,
    required this.amount,
    this.caption,
    this.percent,
    this.warn = false,
  });

  final String label;
  final String amount;
  final String? caption;
  final int? percent;
  final bool warn;

  Map<String, Object?> toArgs() => {
    'label': label,
    'amount': amount,
    'caption': caption,
    'percent': percent,
    'warn': warn,
  };

  @override
  bool operator ==(Object other) =>
      other is WidgetHero &&
      other.label == label &&
      other.amount == amount &&
      other.caption == caption &&
      other.percent == percent &&
      other.warn == warn;

  @override
  int get hashCode => Object.hash(label, amount, caption, percent, warn);
}

abstract class HomeWidgetBridge {
  /// Ghi dòng trạng thái [line] vào bộ nhớ widget rồi vẽ lại widget.
  ///
  /// [validUntil]: với dòng số tiền, lúc hết kỳ tháng của số liệu. Quá lúc đó mà
  /// app chưa đẩy số mới, phía Android xóa dòng và hiện "Mở app để cập nhật".
  ///
  /// [hero]: số tiền tách nhãn / số / dòng phụ để widget vẽ số lớn; [line] vẫn
  /// là cả câu (đọc cho TalkBack, và cho widget bản cũ).
  Future<void> show(String line, {DateTime? validUntil, WidgetHero? hero});

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
  Future<void> show(String line, {DateTime? validUntil, WidgetHero? hero}) =>
      _invoke('show', {
        'line': line,
        'validUntil': validUntil?.millisecondsSinceEpoch,
        ...?hero?.toArgs(),
      });

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
