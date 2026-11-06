import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Nhận route từ intent Android (nút Chi/Thu của widget) qua kênh `vigon/deeplink`.
///
/// Phía Android giữ route chờ xử lý: [takePending] lấy và xóa nó (mỗi route chỉ
/// dùng một lần). Khi app đang chạy và nhận intent mới, Android gọi
/// `routeAvailable` để Dart đi lấy. Nền tảng không có kênh thì không có route.
class DeepLinkChannel {
  DeepLinkChannel([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'vigon/deeplink';

  final MethodChannel _channel;

  Future<String?> takePending() async {
    try {
      return await _channel.invokeMethod<String>('takePending');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Đăng ký hàm chạy khi Android báo có route mới; truyền null để gỡ.
  void listen(VoidCallback? onRouteAvailable) {
    _channel.setMethodCallHandler(
      onRouteAvailable == null
          ? null
          : (call) async {
              if (call.method == 'routeAvailable') onRouteAvailable();
              return null;
            },
    );
  }
}

final deepLinkChannelProvider = Provider<DeepLinkChannel>(
  (ref) => DeepLinkChannel(),
);

/// Chỉ nhận đúng hai route nhập khoản mới và màn chính `/` (chạm phần tên/dòng
/// trạng thái của widget, D9); route lạ (intent từ app khác) bị bỏ.
String? allowedDeepLinkRoute(String? route) {
  if (route == null) return null;
  final uri = Uri.tryParse(route);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (route == '/') return '/';
  if (uri.path != '/entry/new') return null;
  final type = uri.queryParameters['type'];
  if (type != 'expense' && type != 'income') return null;
  return '/entry/new?type=$type';
}

/// Đưa route từ intent vào `go_router`. Màn khóa PIN là lớp phủ của app nên vẫn
/// hiện trước; mở khóa xong mới thấy màn đã chọn (AC-63).
class DeepLinkBinder extends ConsumerStatefulWidget {
  const DeepLinkBinder({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<DeepLinkBinder> createState() => _DeepLinkBinderState();
}

class _DeepLinkBinderState extends ConsumerState<DeepLinkBinder> {
  late final DeepLinkChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = ref.read(deepLinkChannelProvider);
    _channel.listen(_check);
    // Khởi động nguội: lấy route đã chờ sau khung hình đầu tiên.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final route = allowedDeepLinkRoute(await _channel.takePending());
    if (route == null || !mounted) return;
    // `go` dựng ngăn xếp [Trang chủ, màn nhập], nên nút Back về trang chủ.
    widget.router.go(route);
  }

  @override
  void dispose() {
    _channel.listen(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
