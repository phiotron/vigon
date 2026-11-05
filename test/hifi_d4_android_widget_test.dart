// D4 (Hi-Fi EXT-01, EXT-02): tài nguyên widget Android và icon thông báo.
// Chỉ đọc file, không dựng app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _res(String path) =>
    File('android/app/src/main/res/$path').readAsStringSync();

void main() {
  group('EXT-01 màu và góc theo token v2', () {
    test('màu widget-* đúng giá trị token', () {
      final colors = _res('values/widget_colors.xml');
      expect(colors, contains('<color name="widget_surface">#0E5244</color>'));
      expect(colors, contains('<color name="widget_ink">#F7FAF8</color>'));
      expect(colors, contains('<color name="widget_expense">#C62828</color>'));
      expect(colors, contains('<color name="widget_income">#2E7D32</color>'));
      expect(colors, contains('<color name="on_widget_action">#FFFFFF</color>'));
    });

    test('radius-widget 20dp, Android 12+ theo góc hệ thống, nút radius-md', () {
      expect(
        _res('values/widget_dimens.xml'),
        contains('<dimen name="vigon_widget_radius">20dp</dimen>'),
      );
      expect(
        _res('values/widget_dimens.xml'),
        contains('<dimen name="vigon_widget_button_radius">12dp</dimen>'),
      );
      expect(
        _res('values-v31/widget_dimens.xml'),
        contains('system_app_widget_background_radius'),
      );
      expect(
        _res('drawable/vigon_widget_bg.xml'),
        contains('@dimen/vigon_widget_radius'),
      );
      for (final b in ['expense', 'income']) {
        final d = _res('drawable/vigon_widget_btn_$b.xml');
        expect(d, contains('@color/widget_$b'));
        expect(d, contains('@dimen/vigon_widget_button_radius'));
      }
    });
  });

  group('EXT-01 bố cục 2×2 và 4×2', () {
    final tall = _res('layout/vigon_widget.xml');
    final wide = _res('layout/vigon_widget_wide.xml');

    String buttonsOrientation(String layout) {
      // Khối chứa hai nút là LinearLayout có weight ngay trước nút Chi.
      final i = layout.indexOf('android:id="@+id/widget_expense"');
      final before = layout.substring(0, i);
      return RegExp(
        r'android:orientation="(\w+)"',
      ).allMatches(before).last.group(1)!;
    }

    test('2×2: nút xếp dọc, dòng trạng thái tối đa 2 dòng (A15)', () {
      expect(buttonsOrientation(tall), 'vertical');
      final status = RegExp(
        r'<TextView\s+android:id="@\+id/widget_status"[^>]*>',
      ).firstMatch(tall)!.group(0)!;
      expect(status, contains('android:maxLines="2"'));
      expect(status, contains('android:visibility="gone"'));
    });

    test('4×2: nút cạnh nhau, dòng trạng thái 1 dòng', () {
      expect(buttonsOrientation(wide), 'horizontal');
      final status = RegExp(
        r'<TextView\s+android:id="@\+id/widget_status"[^>]*>',
      ).firstMatch(wide)!.group(0)!;
      expect(status, contains('android:maxLines="1"'));
    });

    test('hai bố cục cùng id, nút có dấu −/+ và chữ, mô tả đọc màn hình', () {
      for (final layout in [tall, wide]) {
        for (final id in [
          'widget_icon',
          'widget_brand',
          'widget_status',
          'widget_expense',
          'widget_income',
        ]) {
          expect(layout, contains('android:id="@+id/$id"'));
        }
        expect(layout, contains('@string/widget_glyph_expense'));
        expect(layout, contains('@string/widget_glyph_income'));
        expect(layout, contains('@string/widget_expense_desc'));
        expect(layout, contains('@string/widget_income_desc'));
        expect(layout, contains('android:id="@android:id/background"'));
        // Mặc định (cũng là bản xem trước trong bộ chọn): logo + "Ví Gọn".
        expect(layout, contains('@string/widget_label'));
        expect(layout, isNot(contains('#')), reason: 'không gõ tay mã màu');
      }
    });

    test('bản xem trước = widget thật ở trạng thái mặc định', () {
      final info = _res('xml/vigon_widget_info.xml');
      expect(info, contains('android:previewLayout="@layout/vigon_widget"'));
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
    });

    test('Kotlin chọn bố cục theo cỡ, icon khóa và cập nhật', () {
      final kt = File(
        'android/app/src/main/kotlin/com/phiotron/vigon/WidgetProvider.kt',
      ).readAsStringSync();
      expect(kt, contains('R.layout.vigon_widget_wide'));
      expect(kt, contains('onAppWidgetOptionsChanged'));
      expect(kt, contains('R.drawable.ic_widget_lock'));
      expect(kt, contains('R.drawable.ic_widget_update'));
      expect(_res('drawable/ic_widget_lock.xml'), contains('@color/widget_ink'));
      expect(
        _res('drawable/ic_widget_update.xml'),
        contains('@color/widget_ink'),
      );
    });
  });

  test('EXT-02 (A16): icon thông báo chép đúng hình lớp đơn sắc, tô trắng', () {
    final mono = _res('drawable/ic_launcher_monochrome.xml');
    final stat = _res('drawable/ic_stat_vigon.xml');
    final monoPaths = RegExp(
      r'android:pathData="([^"]+)"',
    ).allMatches(mono).map((m) => m.group(1)).toList();
    final statPaths = RegExp(
      r'android:pathData="([^"]+)"',
    ).allMatches(stat).map((m) => m.group(1)).toList();
    expect(statPaths, monoPaths);
    expect(stat, isNot(contains('#000000')));
    expect(stat, contains('android:fillColor="#FFFFFF"'));
    expect(stat, contains('android:width="24dp"'));
  });
}
