import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/ui/balance_bar.dart';
import 'package:vigon/src/ui/theme.dart';

Future<void> _loadAppFont() async {
  final loader = FontLoader(vgFontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Mọi dòng của [label] bắt đầu ở đầu một từ (không bẻ giữa chữ).
void _expectNoMidWordBreak(WidgetTester tester, String label) {
  final p = tester.renderObject<RenderParagraph>(find.text(label));
  double top(int i) => p
      .getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1))
      .first
      .top;
  for (var i = 1; i < label.length; i++) {
    if (label[i] == ' ') continue;
    if (top(i) > top(i - 1) + 1) {
      expect(
        label[i - 1] == ' ' || label[i] == ' ',
        isTrue,
        reason: '"$label" bị bẻ giữa chữ ở vị trí $i',
      );
    }
  }
}

void main() {
  setUpAll(_loadAppFont);

  // D9 Galaxy A13: cỡ chữ 200% + thu phóng màn hình (≈ 340 dp bề rộng thanh):
  // "Tháng 11 năm 2026" bị ép thành "Thán / g 11 / năm…" cạnh số tiền.
  for (final width in [300.0, 340.0]) {
    testWidgets('BalanceBar chữ 200%, rộng $width: không bẻ giữa chữ (D9)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: BalanceBar(
                      amount: '8.478.000 ₫',
                      periodTitle: 'Tháng 11 năm 2026',
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectNoMidWordBreak(tester, 'Tháng 11 năm 2026');
      _expectNoMidWordBreak(tester, 'Số dư');
      expect(tester.takeException(), isNull);
    });
  }
}
