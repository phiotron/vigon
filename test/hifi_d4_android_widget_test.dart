// D4 (Hi-Fi EXT-01, EXT-02): tài nguyên widget Android và icon thông báo.
// Chỉ đọc file, không dựng app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _res(String path) =>
    File('android/app/src/main/res/$path').readAsStringSync();

void main() {
  group('EXT-01 màu và góc theo token v3 (widget B)', () {
    final tokens = jsonDecode(
      File('design/hifi/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final colorTokens = {
      for (final t in (tokens['color']['tokens'] as List))
        t['name'] as String: Map<String, String>.from(t['value'] as Map),
    };

    test('màu widget-* sáng (values) và tối (values-night) đúng token', () {
      for (final (dir, theme) in [
        ('values', 'light'),
        ('values-night', 'dark'),
      ]) {
        final colors = _res('$dir/widget_colors.xml');
        for (final name in [
          'widget-surface',
          'widget-surface-end',
          'widget-ink',
          'widget-gold',
          'widget-outline',
          'widget-action',
          'widget-expense',
          'widget-income',
          'on-widget-action',
        ]) {
          final res = name.replaceAll('-', '_');
          expect(
            colors,
            contains('<color name="$res">${colorTokens[name]![theme]}</color>'),
            reason: '$dir $name',
          );
        }
      }
    });

    test(
      'radius-widget 20dp, Android 12+ theo góc hệ thống, nút radius-lg',
      () {
        expect(
          _res('values/widget_dimens.xml'),
          contains('<dimen name="vigon_widget_radius">20dp</dimen>'),
        );
        expect(
          _res('values/widget_dimens.xml'),
          contains('<dimen name="vigon_widget_button_radius">16dp</dimen>'),
        );
        expect(
          _res('values-v31/widget_dimens.xml'),
          contains('system_app_widget_background_radius'),
        );
        final bg = _res('drawable/vigon_widget_bg.xml');
        expect(bg, contains('@dimen/vigon_widget_radius'));
        expect(bg, contains('android:startColor="@color/widget_surface"'));
        expect(bg, contains('android:endColor="@color/widget_surface_end"'));
        expect(bg, contains('android:color="@color/widget_outline"'));
        final action = _res('drawable/vigon_widget_btn_action.xml');
        expect(action, contains('@color/widget_action'));
        expect(action, contains('@dimen/vigon_widget_button_radius'));
        for (final b in ['expense', 'income']) {
          final d = _res('drawable/vigon_widget_btn_$b.xml');
          expect(d, contains('android:shape="oval"'));
          expect(d, contains('@color/widget_$b'));
        }
        for (final i in ['minus', 'plus']) {
          expect(
            _res('drawable/ic_widget_$i.xml'),
            contains('@color/on_widget_action'),
          );
        }
      },
    );
  });

  group('EXT-01 bố cục 2×2 và 4×2', () {
    final tall = _res('layout/vigon_widget.xml');
    final wide = _res('layout/vigon_widget_wide.xml');

    String buttonsOrientation(String layout) {
      // Khối chứa hai nút là LinearLayout có weight ngay trước nút Chi.
      final i = layout.indexOf('android:id="@+id/widget_expense"');
      final before = layout.substring(0, i);
      return RegExp(r'android:orientation="(\w+)"')
          .allMatches(before)
          .last
          .group(1)!;
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

    test(
      'hai bố cục cùng id, nút có huy hiệu −/+ và chữ, mô tả đọc màn hình',
      () {
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
          // Huy hiệu tròn −/+ trên mỗi nút: không chỉ dựa vào màu.
          expect(layout, contains('android:src="@drawable/ic_widget_minus"'));
          expect(layout, contains('android:src="@drawable/ic_widget_plus"'));
          expect(layout, contains('@drawable/vigon_widget_btn_action'));
          // Dòng trạng thái màu vàng, tên app màu chữ widget.
          expect(layout, contains('@color/widget_gold'));
          expect(layout, contains('@color/widget_ink'));
          expect(layout, contains('@string/widget_expense_desc'));
          expect(layout, contains('@string/widget_income_desc'));
          expect(layout, contains('android:id="@android:id/background"'));
          // Mặc định (cũng là bản xem trước trong bộ chọn): logo + "Ví Gọn".
          expect(layout, contains('@string/widget_label'));
          expect(layout, isNot(contains('#')), reason: 'không gõ tay mã màu');
        }
      },
    );

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
      expect(
        _res('drawable/ic_widget_lock.xml'),
        contains('@color/widget_gold'),
      );
      expect(
        _res('drawable/ic_widget_update.xml'),
        contains('@color/widget_gold'),
      );
      // Logo bo góc riêng cho widget (mipmap vuông góc nhọn trong RemoteViews).
      expect(kt, contains('R.drawable.ic_widget_logo'));
    });
  });

  test('EXT-02 (A16): icon thông báo chép đúng hình lớp đơn sắc, tô trắng', () {
    final mono = _res('drawable/ic_launcher_monochrome.xml');
    final stat = _res('drawable/ic_stat_vigon.xml');
    final monoPaths = RegExp(r'android:pathData="([^"]+)"')
        .allMatches(mono)
        .map((m) => m.group(1))
        .toList();
    final statPaths = RegExp(r'android:pathData="([^"]+)"')
        .allMatches(stat)
        .map((m) => m.group(1))
        .toList();
    expect(statPaths, monoPaths);
    expect(stat, isNot(contains('#000000')));
    expect(stat, contains('android:fillColor="#FFFFFF"'));
    expect(stat, contains('android:width="24dp"'));
  });
}
