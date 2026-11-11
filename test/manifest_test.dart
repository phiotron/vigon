import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Quyền duy nhất được phép khai báo (F-25, AC-62; INTERNET chỉ để tải tỉ giá
/// khi đổi tiền tệ, D-025; USE_BIOMETRIC cho mở khoá bằng vân tay, F-41,
/// AC-125).
const allowedPermissions = {
  'android.permission.INTERNET',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.RECEIVE_BOOT_COMPLETED',
  'android.permission.USE_BIOMETRIC',
};

/// Quyền tuyệt đối không có: trạng thái mạng, báo thức chính xác.
const forbiddenPermissions = [
  'android.permission.ACCESS_NETWORK_STATE',
  // AC-125 (D-032): không camera, ảnh, bộ nhớ, SMS, đọc thông báo, dịch vụ nền.
  'android.permission.CAMERA',
  'android.permission.READ_MEDIA_',
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WRITE_EXTERNAL_STORAGE',
  'android.permission.READ_SMS',
  'android.permission.RECEIVE_SMS',
  'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
  'android.permission.FOREGROUND_SERVICE',
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
    'manifest nguồn chỉ xin quyền mạng (tỉ giá), thông báo và khởi động, tắt '
    'sao lưu tự động (AC-43, AC-62, D-025, SPEC 5)',
    () {
      final xml = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(declaredPermissions(xml), allowedPermissions);
      for (final banned in forbiddenPermissions) {
        expect(xml.contains(banned), isFalse, reason: 'có $banned');
      }
      expect(xml.contains('android:allowBackup="false"'), isTrue);
      expect(xml.contains('android:screenOrientation="portrait"'), isTrue);
      // Chỉ HTTPS (S-60): không cho HTTP thường.
      expect(xml.contains('usesCleartextTraffic="true"'), isFalse);
      expect(xml.contains('networkSecurityConfig'), isFalse);
    },
  );

  test('iOS không thêm ngoại lệ ATS: chỉ HTTPS (D-025, S-60)', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('NSAppTransportSecurity'), isFalse);
    expect(plist.contains('NSAllowsArbitraryLoads'), isFalse);
    final privacy = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    expect(
      RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>').hasMatch(privacy),
      isTrue,
    );
    expect(
      RegExp(r'<key>NSPrivacyTrackingDomains</key>\s*<array/>')
          .hasMatch(privacy),
      isTrue,
    );
  });

  test('mã gọi mạng Dart chỉ ở hai chỗ: tỉ giá (HTTPS) và IMAP (TLS) '
      '(D-025, D-031, AC-125)', () {
    final dart = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart'))
          (f.path.replaceAll(r'\', '/'), f.readAsStringSync()),
    ];
    List<String> using(bool Function(String src) uses) => [
      for (final (path, src) in dart)
        if (uses(src)) path,
    ];
    // Tỉ giá: HttpClient của dart:io.
    expect(using((s) => s.contains('HttpClient(')), [
      'lib/src/data/exchange_rate.dart',
    ]);
    final rates = File('lib/src/data/exchange_rate.dart').readAsStringSync();
    expect(rates.contains('http://'), isFalse);
    // IMAP: chỉ một file dùng thư viện IMAP; không ai mở socket trực tiếp.
    expect(using((s) => s.contains('package:enough_mail')), [
      'lib/src/import/mail/enough_imap.dart',
    ]);
    expect(
      using(
        (s) =>
            s.contains('Socket.connect') ||
            s.contains('RawSocket') ||
            s.contains('SecureSocket') ||
            s.contains('WebSocket'),
      ),
      isEmpty,
    );
    final imap = File('lib/src/import/mail/enough_imap.dart')
        .readAsStringSync();
    expect(imap, contains('isSecure: true'));
    expect(imap.contains('isSecure: false'), isFalse);
    expect(imap.contains('onBadCertificate'), isFalse);
  });

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
