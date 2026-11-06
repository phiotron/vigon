import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/backup_schedule.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/providers.dart';

import 'package:vigon/src/ui/settings_rows.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';

const _tree = 'content://tree/Vigon';

/// Mở app với thư mục giả và dịch vụ mã hóa ít vòng; vào Cài đặt.
Future<({FakeFolder folder, MemorySecretStore secrets, dynamic db})> _open(
  WidgetTester tester, {
  List extra = const [],
}) async {
  final folder = FakeFolder()
    ..pickResult = const PickedFolder(uri: _tree, name: 'Vigon');
  final secrets = MemorySecretStore();
  final db = memoryDatabase();
  await pumpApp(
    tester,
    db: db,
    secrets: secrets,
    overrides: [
      backupFolderServiceProvider.overrideWithValue(folder),
      autoBackupServiceProvider.overrideWith(
        (ref) => AutoBackupService(
          db: ref.watch(databaseProvider),
          folder: folder,
          secrets: secrets,
          clock: ref.watch(clockProvider),
          encrypt: (json, pw) => encryptBackup(json, pw, iterations: 1000),
        ),
      ),
      ...extra,
    ],
  );
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.scrollUntilVisible(
    find.text('Sao lưu tự động'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await settle(tester);
  return (folder: folder, secrets: secrets, db: db);
}

Finder get _switch => find.widgetWithText(SettingsSwitchRow, 'Sao lưu tự động');

/// D-026: sau hộp mật khẩu là bộ chọn giờ điền sẵn 21:00; nhận giờ đó.
Future<void> _acceptTimePicker(WidgetTester tester) async {
  expect(find.byType(TimePickerDialog), findsOneWidget);
  await tester.tap(find.text('OK'));
  await settle(tester);
}

void main() {
  testWidgets('bật: chọn thư mục, đặt mật khẩu, sao lưu ngay (AC-58, AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    // Mặc định tắt; có chú thích về Drive/Dropbox.
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(
      find.text(
        'Ví Gọn chỉ ghi file vào thư mục bạn chọn. '
        'Việc tải lên Google Drive hay Dropbox do app đó thực hiện.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sao lưu ngay'), findsNothing);

    await tester.tap(_switch);
    await settle(tester);
    expect(find.text('Mật khẩu sao lưu tự động'), findsOneWidget);
    expect(
      find.textContaining('Quên mật khẩu thì không mở được các file sao lưu'),
      findsOneWidget,
    );
    final fields = find.byType(TextField);
    for (final f in tester.widgetList<TextField>(fields)) {
      expect(f.obscureText, isTrue);
    }

    // Ngắn quá, rồi không khớp: báo lỗi, chưa lưu gì.
    await tester.enterText(fields.at(0), 'abc');
    await tester.enterText(fields.at(1), 'abc');
    await tester.tap(find.text('Bật'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
    await tester.enterText(fields.at(0), 'abcdef');
    await tester.enterText(fields.at(1), 'abcdeg');
    await tester.tap(find.text('Bật'));
    await tester.pumpAndSettle();
    expect(find.text('Hai mật khẩu không khớp'), findsOneWidget);
    expect(h.secrets.values, isEmpty);

    await tester.enterText(fields.at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await _acceptTimePicker(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);

    expect(h.secrets.values[AutoBackupService.passwordKey], 'abcdef');
    expect(h.folder.files.keys, ['vigon-auto-20261103-0900.vigon']);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);
    expect(find.text('Thư mục: Vigon'), findsOneWidget);
    expect(find.textContaining('Lần cuối: '), findsOneWidget);
    expect(find.text('Sao lưu ngay'), findsOneWidget);
    expect(find.text('Chọn lại thư mục'), findsOneWidget);
    // D-026: giờ sao lưu 21:00 và lần tới (đã sao lưu lúc 9:00 khi bật).
    expect(h.secrets.values[AutoBackupService.timeKey], '21:00');
    expect(find.widgetWithText(SettingsNavRow, 'Giờ sao lưu'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(SettingsNavRow, 'Giờ sao lưu'),
        matching: find.text('21:00'),
      ),
      findsOneWidget,
    );
    expect(find.text('Lần tới: hôm nay, 21:00'), findsOneWidget);

    await disposeApp(tester, h.db);
  });

  testWidgets('hủy ở hộp mật khẩu: không bật, bỏ quyền thư mục', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(h.folder.released, [_tree]);
    expect(h.folder.files, isEmpty);
    expect(h.secrets.values, isEmpty);
    await disposeApp(tester, h.db);
  });

  testWidgets('"Sao lưu ngay" và lỗi quyền có nút chọn lại (AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await _acceptTimePicker(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.writes, 1);

    // Giao diện mới cao hơn: cuộn nút vào màn trước khi chạm (gộp 2026-11-05).
    await tester.ensureVisible(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.tap(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.writes, 2);
    expect(find.text('Đã sao lưu'), findsOneWidget);

    // Quyền bị thu hồi: báo lỗi rõ, app không văng, công tắc vẫn bật.
    h.folder.failWith = BackupFolderError.permissionDenied;
    // Giao diện mới cao hơn: cuộn nút vào màn trước khi chạm (gộp 2026-11-05).
    await tester.ensureVisible(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.tap(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    const error = 'Không ghi được vào thư mục. Chọn lại thư mục';
    expect(find.text(error), findsWidgets);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);

    // Chọn lại thư mục: sao lưu lại và hết lỗi.
    h.folder
      ..failWith = null
      ..pickResult = const PickedFolder(uri: 'content://tree/Moi', name: 'Mới');
    await tester.ensureVisible(find.text('Chọn lại thư mục'));
    await tester.pump();
    await tester.tap(find.text('Chọn lại thư mục'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('Thư mục: Mới'), findsOneWidget);
    expect(find.text(error), findsNothing);
    expect(h.folder.released, [_tree]);
    expect(h.folder.writes, 3);

    await disposeApp(tester, h.db);
  });

  testWidgets('tắt: xóa mật khẩu, bỏ quyền thư mục, giữ file (AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await _acceptTimePicker(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.files.length, 1);

    await tester.tap(_switch);
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(h.secrets.values, isEmpty);
    expect(h.folder.released, [_tree]);
    expect(h.folder.files.length, 1);
    expect(find.text('Sao lưu ngay'), findsNothing);
    expect(
      find.textContaining('File đã ghi vẫn còn trong thư mục'),
      findsOneWidget,
    );
    await disposeApp(tester, h.db);
  });

  testWidgets('app ra nền thì tự sao lưu một lần mỗi ngày (AC-59)', (
    tester,
  ) async {
    final h = await _open(tester);
    final service = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(service);
    await tester.runAsync(
      () => container
          .read(autoBackupServiceProvider)
          .enable(
            folder: const PickedFolder(uri: _tree, name: 'Vigon'),
            password: 'abcdef',
          ),
    );

    Future<void> goToBackgroundAndBack() async {
      final b = tester.binding;
      b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
    }

    await goToBackgroundAndBack();
    expect(h.folder.writes, 1);
    await goToBackgroundAndBack();
    expect(h.folder.writes, 1, reason: 'cùng ngày, dữ liệu không đổi');
    await disposeApp(tester, h.db);
  });
  Future<void> enableWithPassword(WidgetTester tester) async {
    // Chạm vào tiêu đề: trên iOS chú thích dài dưới công tắc làm tâm của cả
    // hàng rơi vào chữ chú thích.
    await tester.tap(find.text('Sao lưu tự động'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
  }

  Future<void> finishBackup(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
  }

  /// Đổi giờ trong bộ chọn đang mở bằng chế độ nhập bàn phím rồi nhận.
  Future<void> typeTime(WidgetTester tester, String hour, String minute) async {
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), hour);
    await tester.enterText(fields.at(1), minute);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await settle(tester);
  }

  testWidgets('D-026: chọn giờ khi bật; đổi giờ ở hàng "Giờ sao lưu"', (
    tester,
  ) async {
    final h = await _open(tester);
    await enableWithPassword(tester);
    // Bộ chọn giờ điền sẵn 21:00, tiêu đề "Giờ sao lưu".
    final picker = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(picker.initialTime, const TimeOfDay(hour: 21, minute: 0));
    expect(picker.helpText, 'Giờ sao lưu');
    // Màn test dùng 12 giờ: bộ chọn giữ "CH" của 21:00, nên 7:30 là 19:30.
    await typeTime(tester, '07', '30');
    await finishBackup(tester);
    expect(h.secrets.values[AutoBackupService.timeKey], '19:30');
    expect(h.folder.writes, 1, reason: 'vẫn sao lưu ngay lần đầu');
    // Vừa sao lưu lúc 9:00, chưa tới 19:30: lần tới là tối nay.
    expect(find.text('Lần tới: hôm nay, 19:30'), findsOneWidget);

    final row = find.widgetWithText(SettingsNavRow, 'Giờ sao lưu');
    await tester.ensureVisible(row);
    await settle(tester);
    await tester.tap(row);
    await settle(tester);
    expect(
      tester
          .widget<TimePickerDialog>(find.byType(TimePickerDialog))
          .initialTime,
      const TimeOfDay(hour: 19, minute: 30),
    );
    await typeTime(tester, '10', '15');
    expect(h.secrets.values[AutoBackupService.timeKey], '22:15');
    expect(
      find.descendant(of: row, matching: find.text('22:15')),
      findsOneWidget,
    );
    expect(find.text('Lần tới: hôm nay, 22:15'), findsOneWidget);
    expect(h.folder.writes, 1, reason: 'đổi giờ không sao lưu ngay');

    // Hủy bộ chọn: giữ giờ cũ.
    await tester.tap(row);
    await settle(tester);
    await tester.tap(find.text('Huỷ'));
    await settle(tester);
    expect(h.secrets.values[AutoBackupService.timeKey], '22:15');
    await disposeApp(tester, h.db);
  });

  testWidgets('D-026: đóng bộ chọn giờ khi bật vẫn bật với 21:00', (
    tester,
  ) async {
    final h = await _open(tester);
    await enableWithPassword(tester);
    await tester.tap(find.text('Huỷ')); // nút Hủy của bộ chọn giờ (Material vi)
    await settle(tester);
    await finishBackup(tester);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);
    expect(h.secrets.values[AutoBackupService.timeKey], '21:00');
    expect(h.folder.writes, 1);
    await disposeApp(tester, h.db);
  });

  testWidgets('D-026: chưa bật thì không có hàng giờ', (tester) async {
    final h = await _open(tester);
    expect(find.widgetWithText(SettingsNavRow, 'Giờ sao lưu'), findsNothing);
    await disposeApp(tester, h.db);
  });

  group('iOS (D-026, S-40): quyền thông báo giờ sao lưu', () {
    Future<
      ({
        _FakeSchedulers s,
        ({FakeFolder folder, MemorySecretStore secrets, dynamic db}) h,
      })
    >
    openIos(
      WidgetTester tester, {
      required bool granted,
      required bool allow,
    }) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final s = _FakeSchedulers(granted: granted, allow: allow);
      final h = await _open(
        tester,
        extra: [
          autoBackupSchedulerProvider.overrideWithValue(s.backup),
          reminderSchedulerProvider.overrideWithValue(s.reminder),
        ],
      );
      return (s: s, h: h);
    }

    testWidgets('chưa có quyền: giải thích trước, từ chối thì báo nhẹ', (
      tester,
    ) async {
      final o = await openIos(tester, granted: false, allow: false);
      await enableWithPassword(tester);
      await _acceptTimePicker(tester);
      await finishBackup(tester);
      expect(find.text('Báo khi đến giờ sao lưu'), findsOneWidget);
      expect(o.s.reminder.requests, 0, reason: 'chưa xin trước lời giải thích');
      await tester.tap(find.text('Tiếp tục'));
      await settle(tester);
      expect(o.s.reminder.requests, 1);
      expect(
        find.text(
          'Không có thông báo giờ sao lưu. '
          'Ví Gọn vẫn sao lưu bù khi bạn mở app.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mở cài đặt'), findsOneWidget);
      // Vẫn bật, vẫn có bản sao lưu đầu.
      expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);
      expect(o.h.folder.writes, 1);
      await disposeApp(tester, o.h.db);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('đã có quyền: không hỏi lại', (tester) async {
      final o = await openIos(tester, granted: true, allow: true);
      await enableWithPassword(tester);
      await _acceptTimePicker(tester);
      await finishBackup(tester);
      expect(find.text('Báo khi đến giờ sao lưu'), findsNothing);
      expect(o.s.reminder.requests, 0);
      await disposeApp(tester, o.h.db);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Android: không hỏi quyền thông báo', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final h = await _open(tester);
      await enableWithPassword(tester);
      await _acceptTimePicker(tester);
      await finishBackup(tester);
      expect(find.text('Báo khi đến giờ sao lưu'), findsNothing);
      await disposeApp(tester, h.db);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

class _FakeBackupScheduler implements AutoBackupScheduler {
  _FakeBackupScheduler(this.granted);

  bool granted;

  @override
  bool get usesNotification => true;

  @override
  Future<bool> hasNotificationPermission() async => granted;

  @override
  Future<void> schedule(
    BackupTime time, {
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel() async {}
}

class _FakeReminder implements ReminderScheduler {
  _FakeReminder(this.allow);

  final bool allow;
  int requests = 0;

  @override
  Future<void> initialize(void Function(String? payload) onTap) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async {
    requests++;
    return allow;
  }

  @override
  Future<void> schedule({
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> openSystemSettings() async {}
}

class _FakeSchedulers {
  _FakeSchedulers({required bool granted, required bool allow})
    : backup = _FakeBackupScheduler(granted),
      reminder = _FakeReminder(allow);

  final _FakeBackupScheduler backup;
  final _FakeReminder reminder;
}
