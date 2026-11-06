import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/backup_schedule.dart';
import '../reminder/reminder_scheduler.dart';

/// Mã thông báo "Đến giờ sao lưu" (iOS). Khác mã nhắc ghi chép
/// [reminderNotificationId] để hai lịch không đè nhau (F-25, D-026).
const autoBackupNotificationId = 1002;

/// `payload` của thông báo giờ sao lưu; chạm vào thì app chạy đường bù.
const autoBackupPayload = 'vigon:auto-backup';

/// Đặt lịch sao lưu tự động theo giờ người dùng chọn (D-026). Test thay bằng
/// bản giả. Bản thật nuốt mọi lỗi nền tảng.
abstract class AutoBackupScheduler {
  /// Đặt (hoặc đặt lại) lịch hằng ngày lúc [time] theo giờ máy. [title], [body]
  /// là chữ thông báo (chỉ iOS dùng).
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  });

  /// Hủy lịch (tắt sao lưu tự động).
  Future<void> cancel();

  /// Cách này có cần quyền thông báo không (iOS: có; Android chạy nền: không).
  bool get usesNotification;

  /// Quyền thông báo đã có chưa (không hiện hộp thoại). Android luôn true.
  Future<bool> hasNotificationPermission();
}

/// Không làm gì (nền tảng khác, test).
class NoopAutoBackupScheduler implements AutoBackupScheduler {
  const NoopAutoBackupScheduler();

  @override
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel() async {}

  @override
  bool get usesNotification => false;

  @override
  Future<bool> hasNotificationPermission() async => true;
}

/// Android: kênh `vigon/backup_schedule` tới `BackupScheduleChannel.kt`. Phía
/// Kotlin lưu giờ (không bí mật) vào SharedPreferences riêng để đặt lại lịch
/// sau khi khởi động máy, cập nhật app, đổi giờ/múi giờ mà không cần Dart, rồi
/// đặt báo thức KHÔNG chính xác (`setAndAllowWhileIdle`, không cần quyền báo
/// thức chính xác). Báo thức nổ → `BackupJobService` chạy Dart nền
/// (`autoBackupBackgroundMain`).
class AndroidAutoBackupScheduler implements AutoBackupScheduler {
  const AndroidAutoBackupScheduler([this.channel = const MethodChannel(name)]);

  static const name = 'vigon/backup_schedule';

  final MethodChannel channel;

  @override
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  }) async {
    try {
      await channel.invokeMethod<void>('schedule', {
        'hour': time.hour,
        'minute': time.minute,
      });
    } catch (_) {
      // Không có kênh (test) hay lỗi hệ thống: vẫn còn đường bù khi mở app.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await channel.invokeMethod<void>('cancel');
    } catch (_) {}
  }

  @override
  bool get usesNotification => false;

  @override
  Future<bool> hasNotificationPermission() async => true;
}

/// iOS: iOS không cho app đã đóng tự chạy đúng giờ, nên đúng giờ đã chọn hiện
/// một thông báo cục bộ lặp hằng ngày; chạm vào (hay mở app bất kỳ lúc nào sau
/// giờ đó) thì đường bù sao lưu chạy (D-026). Dùng chung plugin
/// `flutter_local_notifications` với nhắc ghi chép: plugin được khởi tạo MỘT lần
/// ở `reminderReadyProvider` (khởi tạo lại sẽ thay hàm nhận chạm), nên lớp này
/// không gọi `initialize`.
class IosAutoBackupScheduler implements AutoBackupScheduler {
  IosAutoBackupScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  }) async {
    try {
      await ensureLocalTimeZone();
      await _plugin.cancel(id: autoBackupNotificationId);
      await _plugin.zonedSchedule(
        id: autoBackupNotificationId,
        title: title,
        body: body,
        payload: autoBackupPayload,
        scheduledDate: tz.TZDateTime.from(
          nextSlot(
            tz.TZDateTime.now(tz.local),
            time,
            at: (y, mo, d, h, mi) => tz.TZDateTime(tz.local, y, mo, d, h, mi),
          ),
          tz.local,
        ),
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: autoBackupNotificationId);
    } catch (_) {}
  }

  @override
  bool get usesNotification => true;

  @override
  Future<bool> hasNotificationPermission() async {
    try {
      final options = await _ios?.checkPermissions();
      return options?.isEnabled ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Bản đúng cho nền tảng đang chạy.
AutoBackupScheduler platformAutoBackupScheduler() =>
    switch (defaultTargetPlatform) {
      TargetPlatform.android => const AndroidAutoBackupScheduler(),
      TargetPlatform.iOS => IosAutoBackupScheduler(),
      _ => const NoopAutoBackupScheduler(),
    };
