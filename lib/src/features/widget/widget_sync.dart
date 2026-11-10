import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dates.dart';
import '../../data/money.dart';
import '../../data/period.dart';
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
/// Khi app không chạy, Dart không đẩy được gì: dòng số tiền đi kèm hạn dùng (hết
/// kỳ tháng) để phía Android tự bỏ số của kỳ cũ. Số "đang tải lại" (giữ giá trị
/// kỳ trước lúc `todayProvider` vừa sang kỳ mới) cũng không bao giờ được đẩy.
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
  final startDay = ref.watch(monthStartDayProvider);
  final today = ref.watch(todayProvider);
  final budget = ref.watch(budgetProvider);
  final currency = ref.watch(currencyProvider);
  final locale = ref.watch(localeCodeProvider);
  // `isLoading` với `hasValue`: số của kỳ cũ còn giữ lại khi đang tính lại cho kỳ
  // mới (đổi ngày, đổi ngày bắt đầu tháng); không được coi là số của kỳ này.
  if (!spent.hasValue ||
      spent.isLoading ||
      !startDay.hasValue ||
      startDay.isLoading ||
      !budget.hasValue ||
      !currency.hasValue ||
      !locale.hasValue) {
    return; // Chờ dữ liệu; lần đổi tiếp theo sẽ chạy lại.
  }
  final language = _language(ref);
  String fmt(int v) =>
      formatMoney(v, currencyCode: currency.requireValue, locale: language);
  final b = budget.requireValue;
  final month = Period.containing(
    PeriodType.month,
    today,
    monthStartDay: startDay.requireValue,
  );
  _push(
    bridge,
    widgetContent(
      showAmounts: true,
      pinEnabled: false,
      spentFormatted: () => fmt(spent.requireValue),
      budgetFormatted: b == null ? null : () => fmt(b),
      percent: b == null || b <= 0
          ? null
          : (spent.requireValue * 100 / b).round(),
      overFormatted: b == null ? null : () => fmt(spent.requireValue - b),
      validUntil: addDays(month.end, 1),
      language: language,
    ),
  );
});

String _never() => throw StateError('Không được tính số tiền khi PIN bật');

/// Ngôn ngữ giao diện: lựa chọn trong app, chưa chọn = English (D-036); chỉ có vi và en.
String _language(Ref ref) {
  final chosen = ref.watch(localeCodeProvider).value;
  return (chosen ?? 'en').toLowerCase().startsWith('vi') ? 'vi' : 'en';
}

void _push(HomeWidgetBridge bridge, WidgetContent content) {
  final line = content.line;
  unawaited(
    line == null
        ? bridge.clear()
        : bridge.show(line, validUntil: content.validUntil, hero: content.hero),
  );
}
