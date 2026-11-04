import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.g.dart';

/// Nút lớn "− Chi" / "+ Thu" ở màn chính (T1_Nut, 2.1): cao 64, nền màu thu
/// hoặc chi, luôn có dấu và chữ để không phân biệt chỉ bằng màu (AC-01,
/// AC-40). Trình đọc màn hình đọc [semanticLabel] ("Thêm khoản chi").
class MainActionButton extends StatelessWidget {
  const MainActionButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.semanticLabel,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String glyph;
  final String label;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: semanticLabel,
    excludeFromSemantics: true,
    child: Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: FilledButton(
        style: bigButtonStyle(
          background: background,
          foreground: foreground,
          height: VgSize.tapMain,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(glyph, style: VgType.keyGlyph),
            const SizedBox(width: VgSpace.s2),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    ),
  );
}
