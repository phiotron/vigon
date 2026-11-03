import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manifest nguồn không xin quyền nào, tắt sao lưu tự động (AC-43, SPEC 5)',
    () {
      final xml = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(xml.contains('<uses-permission'), isFalse);
      expect(xml.contains('android.permission.INTERNET'), isFalse);
      expect(xml.contains('android:allowBackup="false"'), isTrue);
      expect(xml.contains('android:screenOrientation="portrait"'), isTrue);
    },
  );

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
