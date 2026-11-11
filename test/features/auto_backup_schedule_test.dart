// D10 (D-026): lịch sao lưu theo giờ chọn — Android qua kênh
// `vigon/backup_schedule` (báo thức nền), iOS thông báo cục bộ hằng ngày khác
// mã nhắc ghi sổ; provider đồng bộ đặt/hủy lịch theo cấu hình; phía Kotlin và
// manifest đúng hợp đồng (không quyền báo thức chính xác, đặt lại lịch).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/main.dart' show backupJobChannel;
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/backup_schedule.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/providers.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';

/// Bản giả: ghi lại mọi lời gọi.
class FakeAutoBackupScheduler implements AutoBackupScheduler {
  FakeAutoBackupScheduler({this.usesNotification = false, this.granted = true});

  @override
  final bool usesNotification;
  bool granted;
  final log = <String>[];
  final bodies = <String>[];

  @override
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  }) async {
    log.add('schedule ${time.encode()}');
    bodies.add(body);
  }

  @override
  Future<void> cancel() async => log.add('cancel');

  @override
  Future<bool> hasNotificationPermission() async => granted;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('Android: kênh vigon/backup_schedule', () {
    const channel = MethodChannel(AndroidAutoBackupScheduler.name);
    final calls = <MethodCall>[];
    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('đặt lịch gửi giờ/phút, hủy gọi cancel; không cần quyền', () async {
      const s = AndroidAutoBackupScheduler();
      await s.schedule(const BackupTime(21, 30), title: 'x', body: 'y');
      await s.cancel();
      expect(calls.map((c) => c.method), ['schedule', 'cancel']);
      expect(calls.first.arguments, {'hour': 21, 'minute': 30});
      expect(s.usesNotification, isFalse);
      expect(await s.hasNotificationPermission(), isTrue);
    });

    test('không có kênh hay kênh lỗi: không ném', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'bad_args');
      });
      const s = AndroidAutoBackupScheduler();
      await s.schedule(BackupTime.defaultTime, title: 'x', body: 'y');
      await s.cancel();
      messenger.setMockMethodCallHandler(channel, null);
      await s.schedule(BackupTime.defaultTime, title: 'x', body: 'y');
    });
  });

  group('iOS: thông báo hằng ngày', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final calls = <MethodCall>[];
    Map<String, Object?> permissions = {'isEnabled': false};
    FlutterLocalNotificationsPlatform? saved;

    setUp(() {
      calls.clear();
      try {
        saved = FlutterLocalNotificationsPlatform.instance;
      } catch (_) {
        saved = null; // chưa có bản nào được đăng ký trong test
      }
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'checkPermissions') return permissions;
        return null;
      });
    });
    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      if (saved != null) FlutterLocalNotificationsPlatform.instance = saved!;
      debugDefaultTargetPlatformOverride = null;
    });

    test('mã 1002 (khác nhắc ghi sổ 1001), lặp theo giờ, có payload', () async {
      expect(autoBackupNotificationId, isNot(reminderNotificationId));
      final s = IosAutoBackupScheduler();
      expect(s.usesNotification, isTrue);
      await s.schedule(
        const BackupTime(21, 0),
        title: 'Ví Gọn',
        body: 'Đến giờ sao lưu Ví Gọn. Chạm để sao lưu.',
      );
      final cancel = calls.firstWhere((c) => c.method == 'cancel');
      expect(cancel.arguments, autoBackupNotificationId);
      final zoned = calls.singleWhere((c) => c.method == 'zonedSchedule');
      final args = Map<String, Object?>.from(zoned.arguments as Map);
      expect(args['id'], autoBackupNotificationId);
      expect(args['payload'], autoBackupPayload);
      expect(args['matchDateTimeComponents'], DateTimeComponents.time.index);
      // Ngày giờ gửi đi đúng 21:00 theo múi giờ đã nạp.
      expect(args['scheduledDateTime'] as String, contains('T21:00'));
      // Không hủy mọi thông báo (lịch nhắc F-25 giữ nguyên).
      expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
      expect(
        calls.where(
          (c) => c.method == 'cancel' && c.arguments == reminderNotificationId,
        ),
        isEmpty,
      );
    });

    test('kiểm quyền không hiện hộp thoại', () async {
      final s = IosAutoBackupScheduler();
      permissions = {'isEnabled': false};
      expect(await s.hasNotificationPermission(), isFalse);
      permissions = {'isEnabled': true};
      expect(await s.hasNotificationPermission(), isTrue);
      expect(calls.where((c) => c.method == 'requestPermissions'), isEmpty);
    });

    test('hủy chỉ hủy mã 1002', () async {
      await IosAutoBackupScheduler().cancel();
      expect(calls.single.method, 'cancel');
      expect(calls.single.arguments, autoBackupNotificationId);
    });
  });

  test('chữ thông báo không chứa số (không lộ số liệu ở màn khóa)', () {
    for (final code in ['vi', 'en']) {
      final l = lookupAppLocalizations(Locale(code));
      expect(RegExp(r'\d').hasMatch(l.autoBackupNotificationBody), isFalse);
      expect(l.autoBackupNotificationBody, isNotEmpty);
    }
  });

  group('autoBackupScheduleSyncProvider', () {
    test('bật → đặt lịch theo giờ; đổi giờ → đặt lại; tắt → hủy', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      await SettingsRepository(db).setLocaleCode('vi');
      final secrets = MemorySecretStore();
      final fake = FakeAutoBackupScheduler();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          autoBackupSchedulerProvider.overrideWithValue(fake),
          autoBackupServiceProvider.overrideWith(
            (ref) => AutoBackupService(
              db: db,
              folder: FakeFolder(),
              secrets: secrets,
              clock: () => DateTime(2026, 11, 6, 9),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(autoBackupScheduleSyncProvider, (_, _) {});
      Future<void> pump() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      await pump();
      expect(fake.log, ['cancel'], reason: 'tắt: hủy lịch còn sót');

      final service = container.read(autoBackupServiceProvider);
      await service.enable(
        folder: const PickedFolder(uri: 'content://tree/a'),
        password: 'mat-khau-123',
      );
      container.invalidate(autoBackupStateProvider);
      await pump();
      expect(fake.log.last, 'schedule 21:00');
      expect(fake.bodies.last, 'Đến giờ sao lưu Ví Gọn. Chạm để sao lưu.');

      await service.setTime(const BackupTime(6, 45));
      container.invalidate(autoBackupStateProvider);
      await pump();
      expect(fake.log.last, 'schedule 06:45');

      await service.disable();
      container.invalidate(autoBackupStateProvider);
      await pump();
      expect(fake.log.last, 'cancel');
    });
  });

  group('Android gốc (đọc mã nguồn, không có test Kotlin)', () {
    String read(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');
    final kotlin = read(
      'android/app/src/main/kotlin/com/phiotron/vigon/BackupSchedule.kt',
    );
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    final mainDart = read('lib/main.dart');

    test('báo thức KHÔNG chính xác, không quyền báo thức chính xác', () {
      expect(kotlin, contains('setAndAllowWhileIdle('));
      for (final exact in [
        'setExact(',
        'setExactAndAllowWhileIdle(',
        'setAlarmClock(',
        'canScheduleExactAlarms',
        'SCHEDULE_EXACT_ALARM',
        'USE_EXACT_ALARM',
      ]) {
        // Sao lưu tự động vẫn KHÔNG dùng báo thức chính xác. Manifest được
        // có SCHEDULE_EXACT_ALARM từ D-045 (nhắc trước hạn đúng phút), nhưng
        // không bao giờ USE_EXACT_ALARM.
        expect(kotlin.contains(exact), isFalse, reason: exact);
      }
      expect(manifest.contains('android.permission.USE_EXACT_ALARM'), isFalse);
    });

    test('receiver không xuất ra ngoài, đặt lại lịch khi khởi động, cập nhật, '
        'đổi giờ, đổi múi giờ', () {
      final receiver = RegExp(
        r'<receiver[^>]*\.BackupAlarmReceiver"[^>]*>([\s\S]*?)</receiver>',
      ).firstMatch(manifest);
      expect(receiver, isNotNull);
      expect(receiver![0], contains('android:exported="false"'));
      for (final action in [
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
        'android.intent.action.TIME_SET',
        'android.intent.action.TIMEZONE_CHANGED',
      ]) {
        expect(receiver[1], contains(action));
      }
      // Báo thức nổ: đặt lịch hôm sau TRƯỚC rồi mới chạy job.
      final fire = kotlin.indexOf('BackupAlarm.ACTION_FIRE ->');
      final next = kotlin.indexOf('BackupAlarm.scheduleNext(context)', fire);
      final job = kotlin.indexOf('BackupAlarm.startJob(context)', fire);
      expect(fire, isNot(-1));
      expect(next, lessThan(job));
    });

    test('job chỉ JobScheduler gọi được, chạy đúng hàm Dart nền', () {
      final service = RegExp(r'<service[\s\S]*?\.BackupJobService"[\s\S]*?/>')
          .firstMatch(manifest)?[0];
      expect(service, isNotNull);
      expect(service, contains('android.permission.BIND_JOB_SERVICE'));
      expect(service, contains('android:exported="false"'));
      expect(kotlin, contains('ENTRYPOINT = "autoBackupBackgroundMain"'));
      expect(
        mainDart,
        contains(
          "@pragma('vm:entry-point')\n"
          'Future<void> autoBackupBackgroundMain()',
        ),
      );
      expect(kotlin, contains('JOB_CHANNEL = "$backupJobChannel"'));
      expect(
        kotlin,
        contains('SCHEDULE_CHANNEL = "${AndroidAutoBackupScheduler.name}"'),
      );
      // Kênh thư mục dùng được khi không có Activity (chạy nền).
      expect(kotlin, contains('BackupFolderChannel(applicationContext, null,'));
      expect(
        File('android/app/src/main/kotlin/com/phiotron/vigon/MainActivity.kt')
            .readAsStringSync(),
        contains('BackupAlarm.registerChannel('),
      );
    });
  });
}
