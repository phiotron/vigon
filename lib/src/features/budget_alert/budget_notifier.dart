import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'budget_alerts.dart';
import 'budget_status.dart';

/// Kênh thông báo riêng "Cảnh báo ngân sách" (khác Nhắc ghi sổ, Nhắc hạn).
const budgetChannelId = 'budget_alerts';

/// Mã thông báo ngân sách nằm trong [40000, 50000): không đụng 1001 (Nhắc ghi
/// sổ) hay [20000, 30000) (Nhắc hạn, bị huỷ cả lô). Ổn định theo (ngân sách,
/// mốc) nên cùng một mốc không chồng hai thông báo.
int budgetNotificationId(BudgetAlert alert) {
  final slot = alert.milestone == BudgetMilestone.full ? 1 : 0;
  final category = alert.categoryId;
  if (category == null) return 40000 + slot;
  return 40002 + (category * 2 + slot) % 9998;
}

/// Bản thật của [BudgetNotifier] dùng `flutter_local_notifications` (plugin đã
/// được khởi tạo ở `reminderReadyProvider`, chạm thông báo đi qua
/// `reminderTapProvider`). Lỗi nền tảng được nuốt: không gửi được thì app vẫn
/// chạy bình thường.
class LocalBudgetNotifier implements BudgetNotifier {
  LocalBudgetNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> show(BudgetAlert alert, BudgetAlertContent content) async {
    try {
      await _plugin.show(
        id: budgetNotificationId(alert),
        title: content.title,
        body: content.body,
        payload: budgetAlertPayload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            budgetChannelId,
            content.channelName,
            channelDescription: content.channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            // Không rung: khỏi cần quyền VIBRATE ngoài danh sách cho phép.
            enableVibration: false,
            styleInformation: BigTextStyleInformation(content.body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }
}
