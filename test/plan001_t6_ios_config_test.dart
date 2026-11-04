import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PLAN-001 T6: cấu hình iOS đúng SPEC mục 5 và COMPLIANCE P-02, P-03.
/// Chỉ kiểm chữ trong file; build thật chạy ở job `ios` của CI (iOS-01).
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// Giá trị ngay sau `<key>[key]</key>` trong plist (một thẻ hoặc một mảng).
  String? valueOf(String plist, String key) => RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*(<array/>|<array>.*?</array>|<[^>]+/>|<[^>]+>[^<]*</[^>]+>)',
    dotAll: true,
  ).firstMatch(plist)?.group(1);

  test('Info.plist: tên, ngôn ngữ, chỉ dọc, không xin quyền, không mã hóa', () {
    final plist = read('ios/Runner/Info.plist');
    expect(valueOf(plist, 'CFBundleDisplayName'), '<string>Ví Gọn</string>');
    final locales = valueOf(plist, 'CFBundleLocalizations')!;
    expect(locales, contains('<string>vi</string>'));
    expect(locales, contains('<string>en</string>'));
    expect(valueOf(plist, 'ITSAppUsesNonExemptEncryption'), '<false/>');
    final schemes = valueOf(plist, 'LSApplicationQueriesSchemes')!;
    expect(schemes, contains('<string>mailto</string>'));
    expect(schemes, contains('<string>https</string>'));
    final orientations = valueOf(plist, 'UISupportedInterfaceOrientations')!;
    expect(
      RegExp('<string>').allMatches(orientations).length,
      1,
      reason: orientations,
    );
    expect(orientations, contains('UIInterfaceOrientationPortrait<'));
    expect(plist.contains('~ipad'), isFalse);
    expect(plist.contains('UsageDescription'), isFalse);
  });

  test('privacy manifest: không theo dõi, không thu thập (D-002)', () {
    final manifest = read('ios/Runner/PrivacyInfo.xcprivacy');
    expect(valueOf(manifest, 'NSPrivacyTracking'), '<false/>');
    expect(valueOf(manifest, 'NSPrivacyCollectedDataTypes'), '<array/>');
    expect(manifest.contains('NSPrivacyTrackingDomains'), isFalse);
  });

  test('project.pbxproj: bundle id, chỉ iPhone, manifest nằm trong Runner', () {
    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    expect(
      project.contains('PRODUCT_BUNDLE_IDENTIFIER = com.phiotron.vigon;'),
      isTrue,
    );
    expect(project.contains('TARGETED_DEVICE_FAMILY = "1,2"'), isFalse);
    expect(project.contains('TARGETED_DEVICE_FAMILY = 1;'), isTrue);
    expect(
      project.contains('/* PrivacyInfo.xcprivacy in Resources */,'),
      isTrue,
    );
  });
}
