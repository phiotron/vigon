import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D-020: dữ liệu chỉ ở trên máy. Android 11 trở xuống dùng
/// `allowBackup="false"`; Android 12+ cần thêm `dataExtractionRules` loại cả
/// `device-transfer` (một số hãng vẫn cho chuyển máy trực tiếp dù tắt backup).
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  test('manifest tham chiếu quy tắc trích xuất dữ liệu', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:allowBackup="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('quy tắc loại toàn bộ dữ liệu khỏi sao lưu và chuyển máy', () {
    final rules = read(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    );
    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));
    // Mỗi vùng dữ liệu bị loại ở cả hai phần, không chỉ cơ sở dữ liệu.
    const domains = [
      'root',
      'file',
      'database',
      'sharedpref',
      'device_root',
      'device_file',
      'device_database',
      'device_sharedpref',
    ];
    for (final domain in domains) {
      expect(
        RegExp('<exclude domain="$domain"').allMatches(rules).length,
        2,
        reason: 'vùng $domain phải bị loại ở cloud-backup và device-transfer',
      );
    }
  });
}
