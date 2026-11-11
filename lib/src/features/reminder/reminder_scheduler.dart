import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Đường dẫn app mở khi chạm thông báo nhắc: màn Nhập khoản chi (AC-62).
const reminderPayload = '/entry/new?type=expense';

/// Mã thông báo của lịch nhắc hằng ngày; chỉ có một lịch nên một mã.
const reminderNotificationId = 1001;

const reminderChannelId = 'daily_reminder';

/// Lớp ngăn giữa logic nhắc và plugin thông báo của hệ điều hành, để test dùng
/// bản giả (AC-61, AC-62). Mọi lỗi nền tảng được nuốt bên trong bản thật.
abstract class ReminderScheduler {
  /// Gọi một lần khi mở app. [onTap] nhận `payload` khi người dùng chạm thông
  /// báo lúc app đang chạy (nền hoặc trước).
  Future<void> initialize(void Function(String? payload) onTap);

  /// `payload` của thông báo đã mở app từ trạng thái bị tắt hẳn; null nếu app
  /// không được mở bằng thông báo.
  Future<String?> launchPayload();

  /// Xin quyền thông báo của hệ điều hành (Android 13 trở lên mới có hộp thoại).
  /// Trả true nếu thông báo được phép.
  Future<bool> requestPermission();

  /// Đặt lịch lặp mỗi ngày lúc [time] theo múi giờ máy, thay lịch cũ nếu có.
  Future<void> schedule({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  /// Hủy lịch nhắc.
  Future<void> cancel();

  /// Mở màn cài đặt thông báo của hệ thống cho app này.
  Future<void> openSystemSettings();
}

/// Thời điểm kế tiếp đúng [time] theo múi giờ [location], sau [now].
/// Với lặp theo giờ (`DateTimeComponents.time`), plugin tự lặp từ mốc này.
tz.TZDateTime nextReminderInstant(
  tz.TZDateTime now,
  TimeOfDay time,
  tz.Location location,
) {
  final local = tz.TZDateTime.from(now, location);
  var next = tz.TZDateTime(
    location,
    local.year,
    local.month,
    local.day,
    time.hour,
    time.minute,
  );
  if (!next.isAfter(local)) {
    next = tz.TZDateTime(
      location,
      local.year,
      local.month,
      local.day + 1,
      time.hour,
      time.minute,
    );
  }
  return next;
}

/// Chế độ đặt lịch của Android (D-045): đúng phút (`exactAllowWhileIdle`) khi
/// người dùng đã bật "Báo thức và lời nhắc" (SCHEDULE_EXACT_ALARM), không thì
/// xấp xỉ (`inexactAllowWhileIdle`, có thể trễ vài phút). Lỗi nền tảng → xấp xỉ.
Future<AndroidScheduleMode> reminderScheduleMode(
  FlutterLocalNotificationsPlugin plugin,
) async {
  try {
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null &&
        (await android.canScheduleExactNotifications() ?? false)) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
  } catch (_) {}
  return AndroidScheduleMode.inexactAllowWhileIdle;
}

/// Quyền báo đúng giờ (SCHEDULE_EXACT_ALARM, D-045). iPhone luôn đúng giờ.
class ExactAlarmAccess {
  ExactAlarmAccess([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// true nếu lịch nhắc sẽ đến đúng phút (Android đã cho phép, hoặc iPhone).
  Future<bool> allowed() async {
    try {
      final android = _android;
      if (android == null) return true;
      return await android.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mở trang "Báo thức và lời nhắc" của hệ thống; trả kết quả sau khi quay
  /// lại app.
  Future<bool> request() async {
    try {
      final android = _android;
      if (android == null) return true;
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }
}

bool _localZoneReady = false;

/// Nạp dữ liệu múi giờ và đặt `tz.local` theo múi giờ của máy (một lần). Dùng
/// chung cho lịch nhắc ghi sổ (F-25) và thông báo giờ sao lưu iOS (D-026).
Future<void> ensureLocalTimeZone() async {
  if (_localZoneReady) return;
  tzdata.initializeTimeZones();
  tz.Location? found;
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    found = tz.getLocation(info.identifier);
  } catch (_) {
    // Múi giờ lạ hoặc không đọc được: chọn múi giờ cùng độ lệch hiện tại.
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
        found = location;
        break;
      }
    }
  }
  tz.setLocalLocation(found ?? tz.UTC);
  _localZoneReady = true;
}

/// Bản thật dùng `flutter_local_notifications`. Đúng phút khi người dùng đã
/// bật "Báo thức và lời nhắc", không thì xấp xỉ (D-045, [reminderScheduleMode]).
class LocalNotificationsScheduler implements ReminderScheduler {
  LocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _zonesReady = false;

  @override
  Future<void> initialize(void Function(String? payload) onTap) async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_vigon'),
          // iOS: KHÔNG xin quyền lúc khởi tạo; chỉ xin khi người dùng bật
          // công tắc nhắc, sau lời giải thích (AC-61, D-019).
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) => onTap(response.payload),
      );
      _ready = true;
    } catch (_) {
      // Không có plugin (test, nền tảng khác): nhắc không hoạt động, app vẫn chạy.
    }
  }

  @override
  Future<String?> launchPayload() async {
    if (!_ready) return null;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        return details?.notificationResponse?.payload;
      }
    } catch (_) {}
    return null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    try {
      final ios = _ios;
      if (ios != null) {
        // Hộp thoại cho phép thông báo của iOS (chỉ hiện lần đầu); đã từ chối
        // thì trả về false ngay và người dùng phải mở Cài đặt của iPhone.
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      final android = _android;
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      if (granted != null) {
        // Dưới Android 13 không có hộp thoại: kiểm xem người dùng có tắt thông
        // báo của app trong cài đặt hệ thống không.
        return granted && (await android.areNotificationsEnabled() ?? true);
      }
      return await android.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureZones() async {
    if (_zonesReady) return;
    await ensureLocalTimeZone();
    _zonesReady = true;
  }

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_ready) return;
    try {
      await _ensureZones();
      // Hủy rồi đặt lại để chắc chắn chỉ còn một lịch ở giờ mới.
      await _plugin.cancel(id: reminderNotificationId);
      await _plugin.zonedSchedule(
        id: reminderNotificationId,
        title: title,
        body: body,
        payload: reminderPayload,
        scheduledDate: nextReminderInstant(
          tz.TZDateTime.now(tz.local),
          time,
          tz.local,
        ),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            // Không rung: khỏi cần quyền VIBRATE ngoài danh sách cho phép.
            enableVibration: false,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Đúng phút nếu đã bật "Báo thức và lời nhắc" (D-045).
        androidScheduleMode: await reminderScheduleMode(_plugin),
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: reminderNotificationId);
    } catch (_) {}
  }

  @override
  Future<void> openSystemSettings() async {
    try {
      final android = _android;
      if (android != null) {
        await android.openAppNotificationSettings();
      } else if (_ios != null) {
        // iOS không có API mở thẳng mục thông báo; mở trang cài đặt của app.
        await launchUrl(Uri.parse('app-settings:'));
      }
    } catch (_) {}
  }
}
