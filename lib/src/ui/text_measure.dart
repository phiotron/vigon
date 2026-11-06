import 'package:flutter/widgets.dart';

/// Bề rộng một dòng của [text] đúng như `Text` sẽ vẽ trong [context]:
/// cùng cỡ chữ hệ thống (`textScaler`), chiều chữ, và **chữ đậm hệ thống**
/// (`MediaQuery.boldText`, Android "Chữ đậm" / iOS "Bold Text").
///
/// `Text` tự đổi sang `FontWeight.bold` khi máy bật chữ đậm, còn `TextPainter`
/// thì không, nên đo bằng `TextPainter` trần sẽ hụt bề rộng và ô ôm chữ bị bẻ
/// dòng (D9: "Thứ Hai" xuống hai dòng trên Galaxy A13 bật Chữ đậm).
double measureTextWidth(BuildContext context, String text, TextStyle style) {
  final effective = MediaQuery.boldTextOf(context)
      ? style.merge(const TextStyle(fontWeight: FontWeight.bold))
      : style;
  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
