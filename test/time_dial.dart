import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chọn [hour]:[minute] trên mặt đồng hồ của bộ chọn giờ đang mở rồi nhận OK.
///
/// App chỉ cho mặt đồng hồ (`TimePickerEntryMode.dialOnly`, xem
/// `test/time_picker_dial_only_test.dart`), nên test không gõ được giờ. Chế độ
/// 24 giờ có hai vòng số: chạm vòng ngoài trước, nếu ô giờ ở đầu hộp không ra
/// đúng thì quay lại chế độ giờ và chạm vòng trong. [minute] nên là bội của 5.
Future<void> pickTimeOnDial(WidgetTester tester, int hour, int minute) async {
  final dialog = find.byType(TimePickerDialog);
  final dial = find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Dial');
  String two(int v) => v.toString().padLeft(2, '0');

  Future<void> tapDial(double turns, double radiusFraction) async {
    final center = tester.getCenter(dial);
    final r = tester.getSize(dial).shortestSide / 2 * radiusFraction;
    final a = turns * 2 * pi;
    await tester.tapAt(center + Offset(r * sin(a), -r * cos(a)));
    await tester.pumpAndSettle();
  }

  Finder header(String text) =>
      find.descendant(of: dialog, matching: find.text(text));

  final hourTurns = (hour % 12) / 12;
  for (final radius in const [0.78, 0.5]) {
    await tapDial(hourTurns, radius);
    final shown = [
      for (final e
          in find
              .descendant(of: dialog, matching: find.byType(Text))
              .evaluate())
        (e.widget as Text).data,
    ];
    // 12 giờ (h = 12) hiện "12"; 24 giờ hiện 2 chữ số.
    if (shown.contains(two(hour)) || shown.contains('$hour')) break;
    // Sai vòng: chạm lại ô giờ ở đầu hộp để về chế độ chọn giờ.
    final wrong = shown.firstWhere(
      (t) => t != null && RegExp(r'^\d{1,2}$').hasMatch(t),
      orElse: () => null,
    );
    if (wrong != null) {
      await tester.tap(header(wrong).first);
      await tester.pumpAndSettle();
    }
  }
  // Sau khi chọn giờ, mặt đồng hồ tự sang phút.
  await tapDial(minute / 60, 0.78);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}
