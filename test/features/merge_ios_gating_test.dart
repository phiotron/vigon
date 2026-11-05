import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/reminder/reminder_scheduler.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/platform_features.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';

/// Lớp đặt lịch giả: không chạm plugin thông báo của nền tảng.
class _QuietScheduler implements ReminderScheduler {
  @override
  Future<void> initialize(void Function(String? payload) onTap) async {}

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> requestPermission() async => true;

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

/// Mở app trên [platform], vào Cài đặt và làm màn hình đủ cao để cả danh sách
/// được dựng (ListView chỉ dựng phần thấy được — kiểm "không có" mới đáng tin).
Future<AppDatabase> _openSettings(
  WidgetTester tester,
  TargetPlatform platform,
) async {
  debugDefaultTargetPlatformOverride = platform;
  final db = await pumpApp(
    tester,
    overrides: [
      reminderSchedulerProvider.overrideWithValue(_QuietScheduler()),
      backupFolderServiceProvider.overrideWithValue(FakeFolder()),
    ],
  );
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  // 360 × 10.000 dp: mọi mục Cài đặt nằm trong màn hình (usePhoneScreen tự reset).
  tester.view.physicalSize = const Size(1080, 30000);
  await settle(tester);
  // Mục cuối danh sách đã dựng → danh sách đã dựng hết.
  expect(find.text('Giới thiệu'), findsOneWidget);
  return db;
}

void main() {
  /// D-022 (thay phần iOS của D-019): iOS có đủ che nội dung (lớp phủ native),
  /// số tiền trên widget (WidgetKit) và sao lưu tự động (thư mục app Tệp).
  /// Tìm theo chữ để không phụ thuộc kiểu hàng cài đặt (D3 dựng lại giao diện).
  testWidgets('iOS: có đủ che nội dung, widget, sao lưu tự động (D-022)', (
    tester,
  ) async {
    try {
      final db = await _openSettings(tester, TargetPlatform.iOS);
      expect(find.text('Che nội dung khi chuyển app'), findsOneWidget);
      expect(find.text('Hiện số tiền trên widget'), findsOneWidget);
      expect(find.text('Sao lưu tự động'), findsWidgets);
      expect(find.text('Nhắc ghi chép hằng ngày'), findsOneWidget);
      expect(find.text('Xuất bản sao lưu'), findsOneWidget);
      expect(find.text('Khôi phục từ bản sao lưu'), findsOneWidget);
      await disposeApp(tester, db);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('cờ nền tảng: Android và iOS bật, nền tảng khác tắt', () {
    try {
      for (final p in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = p;
        final on = p == TargetPlatform.android || p == TargetPlatform.iOS;
        expect(supportsAutoBackup, on, reason: '$p');
        expect(supportsHomeWidget, on, reason: '$p');
        expect(supportsSecureWindow, on, reason: '$p');
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android: có đủ các mục', (tester) async {
    try {
      final db = await _openSettings(tester, TargetPlatform.android);
      expect(find.text('Che nội dung khi chuyển app'), findsOneWidget);
      expect(find.text('Hiện số tiền trên widget'), findsOneWidget);
      expect(find.text('Sao lưu tự động'), findsWidgets);
      expect(find.text('Nhắc ghi chép hằng ngày'), findsOneWidget);
      expect(find.text('Xuất bản sao lưu'), findsOneWidget);
      await disposeApp(tester, db);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
