// D9 (Galaxy A13, 2026-11-06): launcher báo "Không thể thêm tiện ích" vì layout
// widget có `<Space>`: `InflateException: Class not allowed to be inflated
// android.widget.Space`. RemoteViews chỉ dựng được một số class nhất định
// (developer.android.com/develop/ui/views/appwidgets/build-ui). Test này đọc mọi
// layout mà widget dùng và cấm class ngoài danh sách đó.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Class RemoteViews cho phép (minSdk 24). CheckBox/RadioButton/Switch chỉ từ
/// API 31 nên KHÔNG nằm ở đây (app chạy cả Android 7–11).
const _allowed = {
  'FrameLayout',
  'LinearLayout',
  'RelativeLayout',
  'GridLayout',
  'AnalogClock',
  'Button',
  'Chronometer',
  'ImageButton',
  'ImageView',
  'ProgressBar',
  'TextView',
  'ViewFlipper',
  'ListView',
  'GridView',
  'StackView',
  'AdapterViewFlipper',
  'ViewStub',
};

void main() {
  test('chạm phần tên/dòng trạng thái mở màn chính (D9)', () {
    for (final name in ['vigon_widget', 'vigon_widget_wide']) {
      final xml = File('android/app/src/main/res/layout/$name.xml')
          .readAsStringSync();
      expect(xml, contains('android:id="@+id/widget_header"'), reason: name);
      // Hàng đầu chứa icon, tên và dòng trạng thái.
      final header = xml.indexOf('widget_header');
      for (final id in ['widget_icon', 'widget_brand', 'widget_status']) {
        expect(xml.indexOf(id), greaterThan(header), reason: '$name: $id');
      }
    }
    final kt = File(
      'android/app/src/main/kotlin/com/phiotron/vigon/WidgetProvider.kt',
    ).readAsStringSync();
    expect(
      RegExp(
        r'setOnClickPendingIntent\(\s*R\.id\.widget_header,\s*openEntry\(context, 2, "/"\)',
      ).hasMatch(kt),
      isTrue,
    );
    // Ba mã yêu cầu khác nhau để PendingIntent không đè extra của nhau.
    for (final code in [0, 1, 2]) {
      expect(kt, contains('openEntry(context, $code,'));
    }
  });

  test('layout widget chỉ dùng class RemoteViews cho phép (D9)', () {
    final res = Directory('android/app/src/main/res');
    // Layout nào được widget dùng: initialLayout/previewLayout trong
    // appwidget-provider + mọi R.layout.* trong WidgetProvider.kt.
    final names = <String>{};
    final info = File('${res.path}/xml/vigon_widget_info.xml')
        .readAsStringSync();
    for (final m in RegExp(r'@layout/([a-z0-9_]+)').allMatches(info)) {
      names.add(m.group(1)!);
    }
    final kt = File(
      'android/app/src/main/kotlin/com/phiotron/vigon/WidgetProvider.kt',
    ).readAsStringSync();
    for (final m in RegExp(r'R\.layout\.([a-z0-9_]+)').allMatches(kt)) {
      names.add(m.group(1)!);
    }
    expect(names, containsAll(['vigon_widget', 'vigon_widget_wide']));

    for (final name in names) {
      final xml = File('${res.path}/layout/$name.xml')
          .readAsStringSync()
          .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      final tags = RegExp(r'<([A-Za-z][A-Za-z0-9_.]*)')
          .allMatches(xml)
          .map((m) => m.group(1)!)
          .where((t) => t != 'merge' && t != 'include')
          .toSet();
      expect(tags, isNotEmpty, reason: '$name.xml không có view nào?');
      for (final tag in tags) {
        expect(
          _allowed.contains(tag),
          isTrue,
          reason:
              '$name.xml dùng <$tag>: RemoteViews không dựng được '
              '(widget sẽ báo "Không thể thêm tiện ích")',
        );
      }
    }
  });
}
