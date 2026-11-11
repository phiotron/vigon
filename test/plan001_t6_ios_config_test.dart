import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// PLAN-001 T6: cấu hình iOS đúng SPEC mục 5 và COMPLIANCE P-02, P-03.
/// Chỉ kiểm chữ trong file; build thật chạy ở `.github/workflows/ios.yml` (iOS-01).
void main() {
  String read(String path) => File(path).readAsStringSync();

  /// Giá trị ngay sau `<key>[key]</key>` trong plist (một thẻ hoặc một mảng).
  String? valueOf(String plist, String key) => RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*(<array/>|<array>.*?</array>|<[^>]+/>|<[^>]+>[^<]*</[^>]+>)',
    dotAll: true,
  ).firstMatch(plist)?.group(1);

  /// Mảng ngay sau `<key>[key]</key>`, lấy trọn cả mảng lồng bên trong
  /// ([valueOf] dừng ở `</array>` đầu tiên).
  String? arrayOf(String plist, String key) {
    final start = RegExp('<key>${RegExp.escape(key)}</key>\\s*<array>')
        .firstMatch(plist);
    if (start == null) return null;
    final tags = RegExp(r'<array>|</array>');
    var depth = 1;
    for (final t in tags.allMatches(plist, start.end)) {
      depth += t.group(0) == '<array>' ? 1 : -1;
      if (depth == 0) return plist.substring(start.start, t.end);
    }
    return null;
  }

  test('Info.plist: tên, ngôn ngữ, chỉ dọc, không xin quyền, khai mã hóa', () {
    final plist = read('ios/Runner/Info.plist');
    expect(valueOf(plist, 'CFBundleDisplayName'), '<string>Vigon</string>');
    final locales = valueOf(plist, 'CFBundleLocalizations')!;
    expect(locales, contains('<string>vi</string>'));
    expect(locales, contains('<string>en</string>'));
    // F-21 mã hóa file sao lưu AES-256-GCM: khai có mã hóa không miễn trừ
    // (người dùng quyết 2026-11-05, tự nộp khai báo Pháp).
    expect(valueOf(plist, 'ITSAppUsesNonExemptEncryption'), '<true/>');
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
    // AC-125: đúng một chuỗi mục đích, NSFaceIDUsageDescription (F-41); không
    // camera hay thư viện ảnh.
    expect(
      RegExp(r'<key>NS\w+UsageDescription</key>')
          .allMatches(plist)
          .map((m) => m[0])
          .toList(),
      ['<key>NSFaceIDUsageDescription</key>'],
    );
    expect(plist.contains('NSCamera'), isFalse);
    expect(plist.contains('NSPhotoLibrary'), isFalse);
  });

  test('chuỗi Face ID có bản vi + en và được đóng gói (F-41, AC-125)', () {
    for (final lang in ['en', 'vi']) {
      final strings = read('ios/Runner/$lang.lproj/InfoPlist.strings');
      expect(
        RegExp(r'"NSFaceIDUsageDescription" = "[^"]+";').hasMatch(strings),
        isTrue,
        reason: lang,
      );
    }
    expect(
      read('ios/Runner/vi.lproj/InfoPlist.strings'),
      contains('Face ID để mở khoá'),
    );
    final project = read('ios/Runner.xcodeproj/project.pbxproj');
    expect(project, contains('path = en.lproj/InfoPlist.strings;'));
    expect(project, contains('path = vi.lproj/InfoPlist.strings;'));
    expect(project, contains('/* InfoPlist.strings in Resources */,'));
  });

  test('privacy manifest: không theo dõi, không thu thập (D-002)', () {
    final manifest = read('ios/Runner/PrivacyInfo.xcprivacy');
    expect(valueOf(manifest, 'NSPrivacyTracking'), '<false/>');
    expect(valueOf(manifest, 'NSPrivacyCollectedDataTypes'), '<array/>');
    // Không khai tên miền theo dõi: bỏ khoá hoặc để mảng rỗng đều được.
    expect(
      valueOf(manifest, 'NSPrivacyTrackingDomains'),
      anyOf(isNull, '<array/>'),
    );
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

  // Phần lấy từ nhánh main khi gộp PLAN-001 (notes/2026-11-04-ios-ci.md).
  test('Info.plist: tắt deep link Flutter, khai UTI cho file .vigon', () {
    final plist = read('ios/Runner/Info.plist');
    expect(valueOf(plist, 'FlutterDeepLinkingEnabled'), '<false/>');
    final exported = arrayOf(plist, 'UTExportedTypeDeclarations')!;
    expect(
      valueOf(exported, 'UTTypeIdentifier'),
      '<string>com.phiotron.vigon.backup</string>',
    );
    final extensions = valueOf(exported, 'public.filename-extension')!;
    expect(extensions, contains('<string>vigon</string>'));
  });

  test('privacy manifest: khai lý do dùng API nhạy cảm (ITMS-91053)', () {
    final manifest = read('ios/Runner/PrivacyInfo.xcprivacy');
    final apis = arrayOf(manifest, 'NSPrivacyAccessedAPITypes')!;
    expect(apis, contains('NSPrivacyAccessedAPICategoryFileTimestamp'));
    expect(apis, contains('<string>C617.1</string>'));
    expect(apis, contains('NSPrivacyAccessedAPICategoryDiskSpace'));
    expect(apis, contains('<string>E174.1</string>'));
  });

  test(
    'project.pbxproj: PrivacyInfo đúng một lần trong Resources mỗi target',
    () {
      final project = read('ios/Runner.xcodeproj/project.pbxproj');
      const entry = '/* PrivacyInfo.xcprivacy in Resources */';
      final phases = RegExp(
        r'isa = PBXResourcesBuildPhase;.*?files = \((.*?)\);',
        dotAll: true,
      ).allMatches(project).toList();
      expect(phases, isNotEmpty);
      final perPhase = phases
          .map((m) => entry.allMatches(m.group(1)!).length)
          .where((n) => n > 0)
          .toList();
      // Runner và widget extension (S-21: extension có manifest riêng), mỗi
      // target đúng một lần.
      expect(perPhase, [1, 1]);
      // Hai định nghĩa PBXBuildFile + hai dòng trong Resources, không trùng ID.
      expect(entry.allMatches(project).length, 4);
    },
  );

  test('AppDelegate: đặt delegate thông báo để nhắc hiện khi app đang mở', () {
    final delegate = read('ios/Runner/AppDelegate.swift');
    expect(delegate, contains('UNUserNotificationCenter.current().delegate'));
  });

  test('AppDelegate: kênh loại cơ sở dữ liệu khỏi sao lưu iCloud', () {
    final delegate = read('ios/Runner/AppDelegate.swift');
    expect(delegate, contains('"vigon/backup_exclusion"'));
    expect(delegate, contains('"excludeFromBackup"'));
    expect(delegate, contains('isExcludedFromBackup = true'));
    expect(delegate, contains('BackupExclusionChannel.register('));
    // Plugin vẫn được đăng ký như cũ.
    expect(
      delegate,
      contains(
        'GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)',
      ),
    );
  });

  test('ios.yml: CI kiểm cờ mã hóa và cờ loại khỏi sao lưu trên simulator', () {
    final workflow = read('.github/workflows/ios.yml');
    expect(
      workflow,
      contains(
        'plutil -extract ITSAppUsesNonExemptEncryption raw ios/Runner/Info.plist)" = "true"',
      ),
    );
    expect(workflow, contains('VigonBackupExclusion: excluded='));
  });
}
