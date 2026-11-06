import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/ui/choice_segments.dart';
import 'package:vigon/src/ui/text_measure.dart';
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/tokens.g.dart';

/// Nạp Be Vietnam Pro thật: font test mặc định có chữ đậm rộng bằng chữ thường
/// nên không lộ được lỗi đo.
Future<void> _loadAppFont() async {
  final loader = FontLoader(vgFontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Widget _host({
  required bool bold,
  required double scale,
  required Widget child,
}) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(boldText: bold, textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadAppFont);

  testWidgets('measureTextWidth tính chữ đậm hệ thống như Text (D9)', (
    tester,
  ) async {
    late double plain;
    late double bold;
    for (final on in [false, true]) {
      await tester.pumpWidget(
        _host(
          bold: on,
          scale: 0.8,
          child: Builder(
            builder: (context) {
              final w = measureTextWidth(context, 'Thứ Hai', VgType.labelMd);
              on ? bold = w : plain = w;
              return const SizedBox();
            },
          ),
        ),
      );
    }
    expect(bold, greaterThan(plain));
  });

  // Galaxy A13 bật "Chữ đậm" + cỡ chữ 0,8: ô "Thứ Hai" đang chọn (compact,
  // ôm chữ) bị bẻ thành hai dòng vì đo bằng chữ thường.
  for (final scale in [0.8, 1.0, 1.2]) {
    testWidgets('ChoiceSegments compact: chữ đậm hệ thống, cỡ $scale, '
        'mỗi nút một dòng (D9)', (tester) async {
      await tester.pumpWidget(
        _host(
          bold: true,
          scale: scale,
          child: Align(
            alignment: Alignment.topLeft,
            child: ChoiceSegments<int>(
              compact: true,
              options: const [(1, 'Thứ Hai'), (7, 'Chủ Nhật')],
              selected: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      for (final label in ['Thứ Hai', 'Chủ Nhật']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        final lines = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: label.length),
            )
            .map((b) => b.top)
            .toSet();
        expect(lines.length, 1, reason: '"$label" bị bẻ dòng ở cỡ $scale');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
