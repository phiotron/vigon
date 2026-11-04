import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Quyền duy nhất được phép khai báo (F-25, AC-62).
const allowedPermissions = {
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.RECEIVE_BOOT_COMPLETED',
};

/// Quyền tuyệt đối không có: mạng và báo thức chính xác.
const forbiddenPermissions = [
  'android.permission.INTERNET',
  'android.permission.SCHEDULE_EXACT_ALARM',
  'android.permission.USE_EXACT_ALARM',
];

/// Tên các quyền được khai báo (`<uses-permission>` và `-sdk-23`), bỏ qua
/// dòng gỡ quyền (`tools:node="remove"`).
Set<String> declaredPermissions(String xml) {
  final granted = <String>{};
  for (final m in RegExp(r'<uses-permission[^>]*>').allMatches(xml)) {
    final tag = m[0]!;
    if (tag.contains('tools:node="remove"')) continue;
    final name = RegExp(r'android:name="([^"]+)"').firstMatch(tag)?[1];
    // androidx.core tự thêm quyền chữ ký riêng của app khi hợp nhất manifest;
    // đó không phải quyền hệ thống nên không tính.
    if (name != null && !name.startsWith('com.phiotron.vigon.')) {
      granted.add(name);
    }
  }
  return granted;
}

void main() {
  test(
    'manifest nguồn chỉ xin quyền thông báo và khởi động, tắt sao lưu tự động '
    '(AC-43, AC-62, SPEC 5)',
    () {
      final xml = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(declaredPermissions(xml), allowedPermissions);
      for (final banned in forbiddenPermissions) {
        expect(xml.contains(banned), isFalse, reason: 'có $banned');
      }
      expect(xml.contains('android:allowBackup="false"'), isTrue);
      expect(xml.contains('android:screenOrientation="portrait"'), isTrue);
    },
  );

  test('manifest hợp nhất bản release (nếu đã build) không có quyền ngoài danh '
      'sách cho phép (AC-43, AC-62)', () {
    final dir = Directory('build/app/intermediates/merged_manifests/release');
    final files = dir.existsSync()
        ? dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('AndroidManifest.xml'))
              .toList()
        : <File>[];
    if (files.isEmpty) {
      markTestSkipped('Chưa build release: chạy flutter build apk --release');
      return;
    }
    for (final file in files) {
      final xml = file.readAsStringSync();
      expect(declaredPermissions(xml), allowedPermissions);
      for (final banned in forbiddenPermissions) {
        expect(xml.contains(banned), isFalse, reason: 'có $banned');
      }
    }
  });

  test('pubspec không kéo SDK mạng, quảng cáo hay phân tích (D-002)', () {
    final yaml = File('pubspec.yaml').readAsStringSync();
    for (final banned in [
      'firebase',
      'http:',
      'dio:',
      'google_mobile_ads',
      'sentry',
      'amplitude',
      'mixpanel',
      'webview',
    ]) {
      expect(
        yaml.contains(banned),
        isFalse,
        reason: 'có $banned trong pubspec',
      );
    }
  });
}
