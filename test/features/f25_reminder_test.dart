import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';

import '../helpers.dart';

/// Bản giả của lớp đặt lịch: ghi lại mọi lời gọi, không chạm nền tảng.
class FakeReminderScheduler implements ReminderScheduler {
  bool permission = true;
  String? launch;
  void Function(String?)? onTap;
  int permissionRequests = 0;
  int settingsOpened = 0;
  int cancels = 0;
  final scheduled = <({TimeOfDay time, String title, String body})>[];

  /// Thứ tự các lời gọi đổi lịch, để kiểm "hủy" hay "đặt" là việc cuối.
  final log = <String>[];

  @override
  Future<void> initialize(void Function(String? payload) onTap) async =>
      this.onTap = onTap;

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    scheduled.add((time: time, title: title, body: body));
    log.add('schedule');
  }

  @override
  Future<void> cancel() async {
    cancels++;
    log.add('cancel');
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
}

Future<void> scrollToReminder(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Giờ nhắc'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('đặt lịch và quyền (AC-61, AC-62)', () {
    testWidgets('mặc định tắt, chỉ hủy lịch cũ, giờ mặc định 20:00', (
      tester,
    ) async {
      final fake = FakeReminderScheduler();
      final db = await pumpApp(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(fake.scheduled, isEmpty);
      expect(fake.permissionRequests, 0);
      await openSettings(tester);
      await scrollToReminder(tester);
      expect(find.text('Nhắc ghi chép'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Nhắc ghi chép hằng ngày'),
            )
            .value,
        isFalse,
      );
      expect(find.text('8:00 CH'), findsNothing);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Giờ nhắc'),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data == '20:00' ||
                    w.data == '8:00 PM' ||
                    w.data == '8:00 CH'),
          ),
        ),
        findsOneWidget,
      );
      await disposeApp(tester, db);
    });

    testWidgets(
      'bật: giải thích trước; Hủy thì không xin quyền; Tiếp tục thì xin quyền '
      'rồi đặt lịch 20:00; tắt thì hủy',
      (tester) async {
        final fake = FakeReminderScheduler();
        final db = await pumpApp(
          tester,
          overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
        );
        await openSettings(tester);
        await scrollToReminder(tester);
        await tester.ensureVisible(find.text('Nhắc ghi chép hằng ngày'));
        await tester.pump();
        await tester.tap(find.text('Nhắc ghi chép hằng ngày'));
        await settle(tester);
        expect(
          find.text(
            'Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc ghi '
            'khoản. Thông báo không chứa số liệu.',
          ),
          findsOneWidget,
        );
        // Chưa xin quyền hệ điều hành khi mới hiện lời giải thích.
        expect(fake.permissionRequests, 0);

        await tester.tap(find.text('Hủy'));
        await settle(tester);
        expect(fake.permissionRequests, 0);
        expect(fake.scheduled, isEmpty);
        expect(
          await tester.runAsync(
            () => SettingsRepository(db).readReminderEnabled(),
          ),
          isFalse,
        );

        await tester.ensureVisible(find.text('Nhắc ghi chép hằng ngày'));
        await tester.pump();
        await tester.tap(find.text('Nhắc ghi chép hằng ngày'));
        await settle(tester);
        await tester.tap(find.text('Tiếp tục'));
        await settle(tester);
        expect(fake.permissionRequests, 1);
        expect(fake.scheduled, hasLength(1));
        expect(
          fake.scheduled.single.time,
          const TimeOfDay(hour: 20, minute: 0),
        );
        expect(fake.scheduled.single.title, 'Ví Gọn');
        expect(fake.scheduled.single.body, 'Hôm nay bạn đã ghi chi tiêu chưa?');

        final cancelsBefore = fake.cancels;
        await tester.ensureVisible(find.text('Nhắc ghi chép hằng ngày'));
        await tester.pump();
        await tester.tap(find.text('Nhắc ghi chép hằng ngày'));
        await settle(tester);
        expect(fake.cancels, cancelsBefore + 1);
        expect(fake.log.last, 'cancel');
        expect(
          await tester.runAsync(
            () => SettingsRepository(db).readReminderEnabled(),
          ),
          isFalse,
        );
        await disposeApp(tester, db);
      },
    );

    testWidgets(
      'bị từ chối quyền: công tắc về tắt, hiện hướng dẫn mở cài đặt',
      (tester) async {
        final fake = FakeReminderScheduler()..permission = false;
        final db = await pumpApp(
          tester,
          overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
        );
        await openSettings(tester);
        await scrollToReminder(tester);
        await tester.ensureVisible(find.text('Nhắc ghi chép hằng ngày'));
        await tester.pump();
        await tester.tap(find.text('Nhắc ghi chép hằng ngày'));
        await settle(tester);
        await tester.tap(find.text('Tiếp tục'));
        await settle(tester);
        expect(fake.permissionRequests, 1);
        expect(fake.scheduled, isEmpty);
        expect(
          tester
              .widget<SwitchListTile>(
                find.widgetWithText(SwitchListTile, 'Nhắc ghi chép hằng ngày'),
              )
              .value,
          isFalse,
        );
        expect(
          await tester.runAsync(
            () => SettingsRepository(db).readReminderEnabled(),
          ),
          isFalse,
        );
        expect(
          find.textContaining('Chưa có quyền gửi thông báo'),
          findsOneWidget,
        );
        await tester.tap(find.text('Mở cài đặt'));
        await tester.pump();
        expect(fake.settingsOpened, 1);
        await disposeApp(tester, db);
      },
    );

    testWidgets('đổi giờ thì đặt lại lịch ở giờ mới', (tester) async {
      final fake = FakeReminderScheduler();
      final db = memoryDatabase();
      await tester.runAsync(() async {
        final repo = SettingsRepository(db);
        await repo.setReminderEnabled(true);
        await repo.setReminderTime(const TimeOfDay(hour: 20, minute: 0));
      });
      await pumpApp(
        tester,
        db: db,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(fake.scheduled.last.time, const TimeOfDay(hour: 20, minute: 0));
      final before = fake.scheduled.length;

      await openSettings(tester);
      await scrollToReminder(tester);
      await tester.tap(find.text('Giờ nhắc'));
      await settle(tester);
      // Chuyển sang nhập bằng bàn phím cho dễ thao tác.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await settle(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '8');
      await tester.enterText(fields.at(1), '45');
      await tester.pump();
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(fake.scheduled.length, before + 1);
      expect(fake.scheduled.last.time, const TimeOfDay(hour: 20, minute: 45));
      expect(
        await tester.runAsync(() => SettingsRepository(db).readReminderTime()),
        const TimeOfDay(hour: 20, minute: 45),
      );
      await disposeApp(tester, db);
    });

    testWidgets('nội dung thông báo không chứa chữ số, cả tiếng Việt lẫn Anh', (
      tester,
    ) async {
      for (final code in ['vi', 'en']) {
        final fake = FakeReminderScheduler();
        final db = memoryDatabase();
        await tester.runAsync(() async {
          await SettingsRepository(db).setReminderEnabled(true);
        });
        await pumpApp(
          tester,
          db: db,
          localeCode: code,
          overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
        );
        final n = fake.scheduled.last;
        expect(n.title, 'Ví Gọn');
        expect(
          n.body,
          code == 'vi'
              ? 'Hôm nay bạn đã ghi chi tiêu chưa?'
              : 'Have you recorded your spending today?',
        );
        expect(RegExp(r'\d').hasMatch('${n.title} ${n.body}'), isFalse);
        await disposeApp(tester, db);
      }
    });
  });

  group('đồng bộ lại lịch khi mở app (AC-62)', () {
    testWidgets('đã bật và lưu giờ 07:30 thì mở app đặt lại lịch đúng giờ', (
      tester,
    ) async {
      final fake = FakeReminderScheduler();
      final db = memoryDatabase();
      await tester.runAsync(() async {
        final repo = SettingsRepository(db);
        await repo.setReminderEnabled(true);
        await repo.setReminderTime(const TimeOfDay(hour: 7, minute: 30));
      });
      await pumpApp(
        tester,
        db: db,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(fake.scheduled, isNotEmpty);
      expect(fake.scheduled.last.time, const TimeOfDay(hour: 7, minute: 30));
      expect(fake.log.last, 'schedule');
      await disposeApp(tester, db);
    });

    testWidgets('đang tắt thì mở app chỉ hủy, không đặt lịch', (tester) async {
      final fake = FakeReminderScheduler();
      final db = await pumpApp(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(fake.scheduled, isEmpty);
      expect(fake.log, everyElement('cancel'));
      expect(fake.log, isNotEmpty);
      await disposeApp(tester, db);
    });
  });

  group('chạm thông báo mở màn Nhập khoản chi (AC-62)', () {
    testWidgets('app bị tắt hẳn rồi mở bằng thông báo', (tester) async {
      final fake = FakeReminderScheduler()..launch = reminderPayload;
      final db = await pumpApp(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(find.text('Khoản chi mới'), findsOneWidget);
      expect(find.byTooltip('Cài đặt'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets('app đang chạy nền, chạm thông báo', (tester) async {
      final fake = FakeReminderScheduler();
      final db = await pumpApp(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      expect(find.byTooltip('Cài đặt'), findsOneWidget);
      fake.onTap!(reminderPayload);
      await settle(tester);
      expect(find.byTooltip('Cài đặt'), findsNothing);
      expect(find.text('Khoản chi mới'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('payload lạ bị bỏ qua', (tester) async {
      final fake = FakeReminderScheduler();
      final db = await pumpApp(
        tester,
        overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
      );
      fake.onTap!('/settings');
      fake.onTap!(null);
      await settle(tester);
      expect(find.byTooltip('Cài đặt'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets(
      'đang bật PIN: vẫn hiện màn khóa, mở khóa xong mới vào màn nhập',
      (tester) async {
        final secrets = MemorySecretStore();
        await tester.runAsync(() => PinService(secrets).setPin('2468'));
        final fake = FakeReminderScheduler()..launch = reminderPayload;
        final db = await pumpApp(
          tester,
          secrets: secrets,
          overrides: [reminderSchedulerProvider.overrideWithValue(fake)],
        );
        expect(find.text('Nhập mã PIN'), findsOneWidget);
        expect(find.text('Khoản chi mới'), findsNothing);
        for (final d in '2468'.split('')) {
          await tester.tap(find.widgetWithText(TextButton, d));
          await tester.pump();
        }
        await settle(tester);
        expect(find.text('Nhập mã PIN'), findsNothing);
        expect(find.text('Khoản chi mới'), findsOneWidget);
        await disposeApp(tester, db);
      },
    );
  });

  group('thời điểm kế tiếp và cài đặt giờ', () {
    setUpAll(tzdata.initializeTimeZones);

    test('hôm nay nếu chưa tới giờ, ngày mai nếu đã qua', () {
      final vn = tz.getLocation('Asia/Ho_Chi_Minh');
      const eight = TimeOfDay(hour: 20, minute: 0);
      final morning = tz.TZDateTime(vn, 2026, 11, 4, 9);
      expect(
        nextReminderInstant(morning, eight, vn),
        tz.TZDateTime(vn, 2026, 11, 4, 20),
      );
      final night = tz.TZDateTime(vn, 2026, 11, 4, 21);
      expect(
        nextReminderInstant(night, eight, vn),
        tz.TZDateTime(vn, 2026, 11, 5, 20),
      );
      // Đúng giờ thì tính là đã qua.
      final exact = tz.TZDateTime(vn, 2026, 11, 4, 20);
      expect(
        nextReminderInstant(exact, eight, vn),
        tz.TZDateTime(vn, 2026, 11, 5, 20),
      );
    });

    test('cuối tháng sang tháng sau', () {
      final vn = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = tz.TZDateTime(vn, 2026, 11, 30, 23);
      expect(
        nextReminderInstant(now, const TimeOfDay(hour: 20, minute: 0), vn),
        tz.TZDateTime(vn, 2026, 12, 1, 20),
      );
    });

    test('parseReminderTime: mặc định 20:00, bỏ giá trị sai', () {
      expect(parseReminderTime(null), defaultReminderTime);
      expect(parseReminderTime('abc'), defaultReminderTime);
      expect(parseReminderTime('24:00'), defaultReminderTime);
      expect(parseReminderTime('07:05'), const TimeOfDay(hour: 7, minute: 5));
      expect(parseReminderTime('23:59'), const TimeOfDay(hour: 23, minute: 59));
    });
  });
}
