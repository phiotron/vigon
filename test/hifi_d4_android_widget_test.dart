// D4 (Hi-Fi EXT-01, EXT-02): tài nguyên widget Android và icon thông báo.
// Chỉ đọc file, không dựng app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _res(String path) =>
    File('android/app/src/main/res/$path').readAsStringSync();

void main() {
  group('EXT-01 màu và góc theo token v3 (widget vẽ lại, mockup v4)', () {
    final tokens = jsonDecode(
      File('design/hifi/tokens/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final colorTokens = {
      for (final t in (tokens['color']['tokens'] as List))
        t['name'] as String: Map<String, String>.from(t['value'] as Map),
    };

    test('màu widget cố định (không có values-night), đúng token', () {
      // Màu thương hiệu cố định trên hình nền sáng lẫn tối (mockup v4 EXT-01).
      expect(
        File('android/app/src/main/res/values-night/widget_colors.xml')
            .existsSync(),
        isFalse,
      );
      final colors = _res('values/widget_colors.xml');
      for (final (res, token, theme) in [
        ('widget_surface', 'widget-surface', 'light'),
        ('widget_ink', 'widget-ink', 'light'),
        ('widget_expense', 'widget-expense', 'light'),
        ('widget_income', 'widget-income', 'light'),
        ('on_widget_action', 'on-widget-action', 'light'),
        ('widget_mint', 'brand-mint', 'light'),
        ('widget_paper', 'brand-paper', 'light'),
        ('widget_deep', 'brand-deep', 'light'),
        // Cảnh báo trên nền ngọc dùng giá trị tối (đọc được trên nền đậm).
        ('widget_warning', 'warning', 'dark'),
      ]) {
        expect(
          colors,
          contains('<color name="$res">${colorTokens[token]![theme]}</color>'),
          reason: res,
        );
      }
    });

    test('radius-widget 24dp, Android 12+ theo góc hệ thống, nút radius-lg', () {
      expect(
        _res('values/widget_dimens.xml'),
        contains('<dimen name="vigon_widget_radius">24dp</dimen>'),
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
      expect(bg, contains('<solid android:color="@color/widget_surface" />'));
      final action = _res('drawable/vigon_widget_btn_action.xml');
      expect(action, contains('@color/widget_paper'));
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
      expect(
        _res('drawable/vigon_widget_progress.xml'),
        contains('@color/widget_mint'),
      );
      expect(
        _res('drawable/vigon_widget_progress_warn.xml'),
        contains('@color/widget_warning'),
      );
    });
  });

  group('EXT-01 bố cục 2×2 và 4×2', () {
    final tall = _res('layout/vigon_widget.xml');
    final wide = _res('layout/vigon_widget_wide.xml');

    String buttonsOrientation(String layout) {
      // Khối chứa hai nút là LinearLayout ngay trước nút Chi.
      final i = layout.indexOf('android:id="@+id/widget_expense"');
      final before = layout.substring(0, i);
      return RegExp(r'android:orientation="(\w+)"')
          .allMatches(before)
          .last
          .group(1)!;
    }

    test('2×2: hai nút cạnh nhau cao ≥ 60, số 22 sp', () {
      expect(buttonsOrientation(tall), 'horizontal');
      expect(tall, contains('android:minHeight="60dp"'));
      expect(tall, contains('android:textSize="22sp"'));
    });

    test('4×2: hai nút xếp dọc bên phải rộng 132, số 26 sp', () {
      expect(buttonsOrientation(wide), 'vertical');
      expect(wide, contains('android:layout_width="132dp"'));
      expect(wide, contains('android:textSize="26sp"'));
    });

    test('hai bố cục cùng id, nút có đĩa −/+ và chữ, mô tả đọc màn hình', () {
      for (final layout in [tall, wide]) {
        for (final id in [
          'widget_header',
          'widget_icon',
          'widget_brand',
          'widget_msg_row',
          'widget_msg_icon',
          'widget_msg',
          'widget_amount',
          'widget_bar',
          'widget_bar_warn',
          'widget_caption_row',
          'widget_caption_icon',
          'widget_caption',
          'widget_caption_warn',
          'widget_expense',
          'widget_income',
        ]) {
          expect(layout, contains('android:id="@+id/$id"'), reason: id);
        }
        // Đĩa tròn −/+ trên mỗi nút: không chỉ dựa vào màu.
        expect(layout, contains('android:src="@drawable/ic_widget_minus"'));
        expect(layout, contains('android:src="@drawable/ic_widget_plus"'));
        expect(layout, contains('@drawable/vigon_widget_btn_action'));
        expect(layout, contains('@color/widget_mint'));
        expect(layout, contains('@color/widget_ink'));
        expect(layout, contains('@color/widget_deep'));
        expect(layout, contains('@string/widget_expense_desc'));
        expect(layout, contains('@string/widget_income_desc'));
        expect(layout, contains('android:id="@android:id/background"'));
        // Mặc định (cũng là bản xem trước trong bộ chọn): logo + "Ví Gọn" + lời
        // giới thiệu, không có gì về tiền.
        expect(layout, contains('@string/widget_label'));
        expect(layout, contains('@string/widget_description'));
        final amount = RegExp(
          r'<TextView\s+android:id="@\+id/widget_amount"[^>]*>',
        ).firstMatch(layout)!.group(0)!;
        expect(amount, contains('android:visibility="gone"'));
        expect(layout, isNot(contains('#')), reason: 'không gõ tay mã màu');
      }
    });

    test('bản xem trước = widget thật ở trạng thái mặc định', () {
      final info = _res('xml/vigon_widget_info.xml');
      expect(info, contains('android:previewLayout="@layout/vigon_widget"'));
      expect(info, contains('android:resizeMode="horizontal|vertical"'));
    });

    test('Kotlin chọn bố cục theo cỡ, icon khóa / cập nhật / cảnh báo', () {
      final kt = File(
        'android/app/src/main/kotlin/com/phiotron/vigon/WidgetProvider.kt',
      ).readAsStringSync();
      expect(kt, contains('R.layout.vigon_widget_wide'));
      expect(kt, contains('onAppWidgetOptionsChanged'));
      expect(kt, contains('R.drawable.ic_widget_lock'));
      expect(kt, contains('R.id.widget_msg_icon'));
      expect(kt, contains('R.id.widget_bar_warn'));
      expect(
        _res('drawable/ic_widget_lock.xml'),
        contains('@color/widget_mint'),
      );
      expect(
        _res('drawable/ic_widget_update.xml'),
        contains('@color/widget_mint'),
      );
      expect(
        _res('drawable/ic_widget_warning.xml'),
        contains('@color/widget_warning'),
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
