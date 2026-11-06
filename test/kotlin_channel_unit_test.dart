// D9 (Galaxy A13, 2026-11-05/06): kênh thư mục sao lưu gửi `kotlin.Unit` qua
// `result.success(...)` khi ghi/xóa file thành công. StandardMessageCodec ném
// IllegalArgumentException trên luồng chính → app crash sau mỗi lần sao lưu tự
// động (Samsung báo "Ví Gọn thường xuyên bị lỗi"). Không có test Kotlin, nên
// test này đọc mã nguồn: mọi `result.success(x)` với x là kết quả của một khối
// lệnh phải đổi Unit thành null trước.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupFolderChannel.runAsync không gửi kotlin.Unit qua kênh (D9)', () {
    final src = File(
      'android/app/src/main/kotlin/com/phiotron/vigon/BackupFolderChannel.kt',
    ).readAsStringSync();
    final start = src.indexOf('private fun runAsync(');
    expect(start, isNot(-1), reason: 'không thấy runAsync');
    // Hết hàm: dòng "    }" đầu tiên sau đó (file có thể là CRLF).
    final end = RegExp(r'\r?\n    \}\r?\n').firstMatch(src.substring(start));
    expect(end, isNotNull, reason: 'không thấy cuối runAsync');
    final body = src.substring(start, start + end!.start);
    expect(body, contains('block()'));
    expect(
      RegExp(r'if \(it == Unit\) null').hasMatch(body),
      isTrue,
      reason: 'kết quả block() phải đổi Unit thành null trước result.success',
    );
    // Các khối ghi/xóa thật sự trả Unit (nên cần đổi).
    for (final fn in ['writeFile', 'deleteFile', 'releaseFolder']) {
      expect(
        RegExp('private fun $fn\\([^)]*\\) \\{').hasMatch(src),
        isTrue,
        reason: '$fn không còn trả Unit? Xem lại test',
      );
    }
  });

  test('các kênh Kotlin khác chỉ gọi result.success với null/giá trị rõ', () {
    final dir = Directory('android/app/src/main/kotlin/com/phiotron/vigon');
    final call = RegExp(r'result\.success\(([^)]*)\)');
    for (final f in dir.listSync().whereType<File>()) {
      for (final m in call.allMatches(f.readAsStringSync())) {
        expect(
          m.group(1),
          isNot(equals('Unit')),
          reason: '${f.path}: result.success(Unit)',
        );
      }
    }
  });
}
