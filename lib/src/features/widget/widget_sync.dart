import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/money.dart';
import '../../providers.dart';
import '../lock/app_lock.dart';
import 'home_widget_bridge.dart';
import 'widget_content.dart';

final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (ref) => const MethodChannelHomeWidgetBridge(),
);

/// Công tắc "Hiện số tiền trên widget" (AC-64), mặc định tắt.
final widgetShowAmountsProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchWidgetShowAmounts(),
);

/// Đẩy nội dung widget sang Android khi mở app và mỗi khi thứ gì ảnh hưởng đổi:
/// công tắc, bật/tắt PIN, số đã chi, hạn mức, tiền tệ, ngôn ngữ, sang ngày mới
/// (`todayProvider` đổi khi app quay lại từ nền). `VigonApp` theo dõi provider này.
///
/// Số tiền chỉ được tính và đẩy khi công tắc bật VÀ PIN tắt VÀ trạng thái PIN đã
/// biết chắc; mọi trường hợp khác (kể cả đang đọc trạng thái PIN, hay đọc lỗi)
/// thì không đụng tới số tiền, và công tắc tắt thì xóa sạch chuỗi cũ khỏi bộ
/// nhớ widget.
final widgetSyncProvider = Provider<void>((ref) {
  final bridge = ref.watch(homeWidgetBridgeProvider);
  final show = ref.watch(widgetShowAmountsProvider);
  if (!show.hasValue) return; // Chưa đọc xong cài đặt: chờ lần đổi tiếp theo.
  if (!show.requireValue) {
    unawaited(bridge.clear());
    return;
  }
  final pin = ref.watch(pinEnabledProvider);
  final pinKnownOff = pin.hasValue && !pin.isLoading && !pin.requireValue;
  if (!pinKnownOff) {
    // PIN bật, đang đọc, hoặc đọc lỗi: coi như bật, không tính số tiền.
    _push(
      bridge,
      widgetContent(
        showAmounts: true,
        pinEnabled: true,
        spentFormatted: _never,
        language: _language(ref),
      ),
    );
    return;
  }
  final spent = ref.watch(budgetSpentProvider);
  final budget = ref.watch(budgetProvider);
  final currency = ref.watch(currencyProvider);
  final locale = ref.watch(localeCodeProvider);
  if (!spent.hasValue ||
      !budget.hasValue ||
      !currency.hasValue ||
      !locale.hasValue) {
    return; // Chờ dữ liệu; lần đổi tiếp theo sẽ chạy lại.
  }
  final language = _language(ref);
  String fmt(int v) =>
      formatMoney(v, currencyCode: currency.requireValue, locale: language);
  final b = budget.requireValue;
  _push(
    bridge,
    widgetContent(
      showAmounts: true,
      pinEnabled: false,
      spentFormatted: () => fmt(spent.requireValue),
      budgetFormatted: b == null ? null : () => fmt(b),
      language: language,
    ),
  );
});

String _never() => throw StateError('Không được tính số tiền khi PIN bật');

/// Ngôn ngữ giao diện: lựa chọn trong app, hoặc ngôn ngữ máy; chỉ có vi và en.
String _language(Ref ref) {
  final chosen = ref.watch(localeCodeProvider).value;
  final String code = chosen ?? ref.read(deviceLocaleProvider);
  return code.toLowerCase().startsWith('vi') ? 'vi' : 'en';
}

void _push(HomeWidgetBridge bridge, WidgetContent content) {
  final line = content.line;
  unawaited(line == null ? bridge.clear() : bridge.show(line));
}
