import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../features/categories/category_icons.dart';
import 'theme.dart';

/// Icon danh mục (bản tô đầy) trên nền màu của nó (CategoryAvatar.html): 48 ở
/// lưới và quanh biểu đồ, 40 ở danh sách, 24 trong chip; vùng chạm 48×48 dp
/// (AC-37). [selected] vẽ vòng chọn: khe 3 rồi viền 2 màu chữ chính quanh
/// icon (ô đang chọn ở lưới 3.3 / SCR-07), không đổi kích thước bố cục.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 48,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  final Category category;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    Widget avatar = Material(
      color: Color(category.color),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            iconFor(category.icon),
            fill: 1,
            color: context.vg.onCat,
            size: _iconSize(size),
          ),
        ),
      ),
    );
    if (selected) {
      avatar = CustomPaint(
        foregroundPainter: SelectedRingPainter(
          Theme.of(context).colorScheme.onSurface,
        ),
        child: avatar,
      );
    }
    if (semanticLabel == null) return ExcludeSemantics(child: avatar);
    // excludeSemantics bỏ cả hành động chạm của InkWell, nên phải gắn onTap
    // ở đây để TalkBack bấm được (AC-39).
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

/// Vòng chọn quanh một hình tròn (`box-shadow: 0 0 0 3px …, 0 0 0 5px ink`):
/// viền 2 cách mép 3, vẽ ra ngoài khung nên không đổi bố cục.
class SelectedRingPainter extends CustomPainter {
  const SelectedRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2;
    canvas.drawCircle(
      size.center(Offset.zero),
      r + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(SelectedRingPainter old) => old.color != color;
}

/// Viền nét đứt 2 dp quanh hình tròn (ô ⋯ "Danh mục khác", `.vg-caticon.more`).
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter(this.color, {this.strokeWidth = 2});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    // Nét 4, hở 3 như `border: 2px dashed` của trình duyệt (xấp xỉ).
    final count = (2 * math.pi * r / 7).floor().clamp(8, 64);
    final step = 2 * math.pi / count;
    final dash = step * 4 / 7;
    final rect = Rect.fromCircle(center: center, radius: r);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * step, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Cỡ icon theo bản vẽ: 24 trên vòng tròn 48, 22 trên 40, 16 trong chấm 24.
double _iconSize(double avatar) => switch (avatar) {
  >= 48 => 24,
  >= 40 => 22,
  _ => avatar * 2 / 3,
};
