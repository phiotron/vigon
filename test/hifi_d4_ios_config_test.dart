// D4 (D-022): cấu hình iOS cho F-22, F-24, F-26 và widget extension. Chỉ kiểm
// chữ trong file; build thật (simulator, gồm extension) chạy ở `ios.yml`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  final native = _read('ios/Runner/VigonNative.swift');
  final widget = _read('ios/VigonWidget/VigonWidget.swift');
  final project = _read('ios/Runner.xcodeproj/project.pbxproj');

  group('kênh native trùng tên với Android', () {
    for (final name in [
      'vigon/secure',
      'vigon/deeplink',
      'vigon/widget',
      'vigon/backup_folder',
    ]) {
      test(name, () => expect(native, contains('"$name"')));
    }

    test('AppDelegate đăng ký sau plugin', () {
      final delegate = _read('ios/Runner/AppDelegate.swift');
      expect(
        delegate,
        contains('VigonNative.register(registry: engineBridge.pluginRegistry)'),
      );
    });

    test('mã lỗi thư mục giống BackupFolderChannel.kt', () {
      for (final code in [
        'permission_denied',
        'folder_missing',
        'busy',
        'bad_args',
        'io_error',
      ]) {
        expect(native, contains('"$code"'), reason: code);
      }
    });
  });

  group('F-22 che nội dung', () {
    test('phủ khi rời trạng thái hoạt động, gỡ khi quay lại', () {
      expect(native, contains('@objc(sceneWillResignActive:)'));
      expect(native, contains('@objc(sceneDidEnterBackground:)'));
      expect(native, contains('@objc(sceneDidBecomeActive:)'));
      expect(native, contains('PrivacyCoverView'));
      expect(
        File('ios/Runner/Assets.xcassets/PrivacyLogo.imageset/Contents.json')
            .existsSync(),
        isTrue,
      );
    });
  });

  group('F-26 widget iOS', () {
    test('URL scheme vigon, Flutter deep link vẫn tắt', () {
      final plist = _read('ios/Runner/Info.plist');
      expect(plist, contains('<string>vigon</string>'));
      expect(
        RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>')
            .hasMatch(plist),
        isTrue,
      );
      // Chỉ chuyển host "open"; Dart lọc tiếp bằng allowedDeepLinkRoute.
      expect(native, contains('static let urlHost = "open"'));
      expect(widget, contains('vigon://open/entry/new?type='));
    });

    test('App Group cho Runner và extension', () {
      for (final f in [
        'ios/Runner/Runner.entitlements',
        'ios/VigonWidget/VigonWidget.entitlements',
      ]) {
        expect(_read(f), contains('<string>group.com.phiotron.vigon</string>'));
      }
      expect(
        project,
        contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
      );
      expect(
        project,
        contains(
          'CODE_SIGN_ENTITLEMENTS = VigonWidget/VigonWidget.entitlements;',
        ),
      );
      expect(native, contains('"group.com.phiotron.vigon"'));
      expect(widget, contains('"group.com.phiotron.vigon"'));
    });

    test('D-016: clear XÓA chuỗi; dòng khóa không có hạn dùng', () {
      final clear = native.substring(native.indexOf('case "clear":'));
      expect(clear, contains('removeObject(forKey: lineKey)'));
      expect(clear, contains('removeObject(forKey: validUntilKey)'));
      expect(widget, contains('if ms <= 0 { return (.locked(line), nil) }'));
      // Bộ chọn widget không bao giờ thấy số.
      expect(widget, contains('context.isPreview'));
    });

    test('extension: WidgetKit, nhỏ + vừa, PrivacyInfo riêng (S-21)', () {
      final info = _read('ios/VigonWidget/Info.plist');
      expect(info, contains('com.apple.widgetkit-extension'));
      expect(info, contains(r'$(FLUTTER_BUILD_NAME)'));
      expect(
        widget,
        contains('.supportedFamilies([.systemSmall, .systemMedium])'),
      );
      expect(widget, contains('containerBackground(for: .widget)'));
      final privacy = _read('ios/VigonWidget/PrivacyInfo.xcprivacy');
      expect(privacy, contains('<false/>'));
      expect(privacy, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
      expect(privacy, contains('<string>1C8F.1</string>'));
      final runnerPrivacy = _read('ios/Runner/PrivacyInfo.xcprivacy');
      expect(
        runnerPrivacy,
        contains('NSPrivacyAccessedAPICategoryUserDefaults'),
      );
      expect(runnerPrivacy, contains('<string>CA92.1</string>'));
    });

    test('màu widget-* trùng Android', () {
      final xml = _read('android/app/src/main/res/values/widget_colors.xml');
      String hex(String name) =>
          RegExp('<color name="$name">#([0-9A-F]{6})</color>')
              .firstMatch(xml)!
              .group(1)!;
      String swift(String name) {
        final m = RegExp(
          'static let $name = Color\\(red: 0x(..) / 255, green: 0x(..) / 255, blue: 0x(..) / 255\\)',
        ).firstMatch(widget)!;
        return '${m.group(1)}${m.group(2)}${m.group(3)}';
      }

      expect(swift('surface'), hex('widget_surface'));
      expect(swift('ink'), hex('widget_ink'));
      expect(swift('expense'), hex('widget_expense'));
      expect(swift('income'), hex('widget_income'));
    });

    test('chữ widget EN + VI chép đúng từ .arb', () {
      for (final lang in ['en', 'vi']) {
        final arb =
            jsonDecode(_read('lib/l10n/app_$lang.arb')) as Map<String, dynamic>;
        final strings = _read(
          'ios/VigonWidget/$lang.lproj/Localizable.strings',
        );
        final keys = RegExp(
          r'^"(\w+)" = ',
          multiLine: true,
        ).allMatches(strings).map((m) => m.group(1)!).toList();
        expect(keys, isNotEmpty);
        for (final key in keys) {
          expect(
            strings,
            contains('"$key" = "${arb[key]}";'),
            reason: '$lang $key',
          );
        }
        for (final key in [
          'widgetPickerName',
          'widgetPickerDescription',
          'widgetExpenseButton',
          'widgetIncomeButton',
          'widgetStale',
          'addExpense',
          'addIncome',
        ]) {
          expect(keys, contains(key), reason: '$lang $key');
        }
      }
    });

    test(
      'project: target extension, nhúng trước Thin Binary, Runner phụ thuộc',
      () {
        expect(
          project,
          contains('productType = "com.apple.product-type.app-extension";'),
        );
        expect(
          project,
          contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.phiotron.vigon.VigonWidget;',
          ),
        );
        expect(project, contains('dstSubfolderSpec = 13;'));
        final runnerPhases = RegExp(
          r'97C146ED1CF9000F007C117D /\* Runner \*/ = \{.*?buildPhases = \((.*?)\);',
          dotAll: true,
        ).firstMatch(project)!.group(1)!;
        final embed = runnerPhases.indexOf('Embed Foundation Extensions');
        final thin = runnerPhases.indexOf('Thin Binary');
        expect(embed, greaterThan(0));
        expect(embed, lessThan(thin));
        expect(project, contains('VigonNative.swift in Sources'));
        expect(project, contains('VigonWidget.swift in Sources'));
        // Mã đối tượng mới không trùng nhau.
        final ids = RegExp(
          r'^\t\t(A0020004[0-9A-F]{16}) ',
          multiLine: true,
        ).allMatches(project).map((m) => m.group(1)).toList();
        expect(ids.toSet().length, ids.length);
      },
    );
  });
}
