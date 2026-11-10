// D9 (thử máy 2026-11-05): bản release thu gọn tài nguyên xóa icon thông báo
// `ic_stat_vigon` vì nó chỉ được gọi bằng TÊN từ Dart. Plugin thông báo khởi
// tạo lỗi (bị nuốt) nên nhắc ghi sổ không bao giờ chạy trên máy thật.
// Test này giữ mọi tên tài nguyên Dart gọi bằng chữ nằm trong `raw/keep.xml`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tài nguyên Android gọi bằng tên từ Dart được giữ khi thu gọn (D9)', () {
    final names = <String>{};
    final pattern = RegExp(r"AndroidInitializationSettings\(\s*'([a-z0-9_]+)'");
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final m in pattern.allMatches(f.readAsStringSync())) {
        names.add(m.group(1)!);
      }
    }
    expect(names, contains('ic_stat_vigon'), reason: 'không tìm thấy chỗ gọi');

    final keep = File('android/app/src/main/res/raw/keep.xml')
        .readAsStringSync();
    final kept = RegExp(r'tools:keep="([^"]*)"').firstMatch(keep)?.group(1);
    expect(kept, isNotNull, reason: 'keep.xml thiếu tools:keep');
    final list = kept!.split(',').map((s) => s.trim()).toSet();
    for (final name in names) {
      expect(list, contains('@drawable/$name'));
      expect(
        File('android/app/src/main/res/drawable/$name.xml').existsSync() ||
            File('android/app/src/main/res/drawable/$name.png').existsSync(),
        isTrue,
        reason: 'thiếu file drawable $name',
      );
    }
  });
}
