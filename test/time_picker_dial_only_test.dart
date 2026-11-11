import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Canh lỗi màn đỏ "BoxConstraints has non-normalized height constraints":
/// bộ chọn giờ của Flutter ở kiểu nhập bàn phím lỗi khi cỡ chữ hệ thống nhỏ
/// (Galaxy A13 để 0.8). Mọi lời gọi `showTimePicker` phải giữ mặt đồng hồ
/// (`TimePickerEntryMode.dialOnly`), như A001 `b0f32fa`.
void main() {
  test('mọi showTimePicker dùng TimePickerEntryMode.dialOnly', () {
    final missing = <String>[];
    var calls = 0;
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      var i = src.indexOf('showTimePicker(');
      while (i >= 0) {
        calls++;
        // dialOnly đặt là tham số đầu, ngay sau lời gọi (sau một dòng chú
        // thích): phải có trong 400 ký tự kế tiếp.
        final end = (i + 400).clamp(0, src.length);
        if (!src.substring(i, end).contains('TimePickerEntryMode.dialOnly')) {
          final line = '\n'.allMatches(src.substring(0, i)).length + 1;
          missing.add('${f.path}:$line');
        }
        i = src.indexOf('showTimePicker(', i + 1);
      }
    }
    expect(calls, greaterThan(0));
    expect(missing, isEmpty, reason: 'Thiếu dialOnly: $missing');
  });
}
