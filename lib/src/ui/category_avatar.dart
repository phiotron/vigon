import 'package:flutter/material.dart';

import '../data/database.dart';
import '../features/categories/category_icons.dart';
import 'theme.dart';

/// Icon danh mục (bản tô đầy) trên nền màu của nó: 48 ở lưới và quanh biểu
/// đồ, 40 ở danh sách, 24 trong chip; vùng chạm 48×48 dp (AC-37).
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 48,
    this.onTap,
    this.semanticLabel,
  });

  final Category category;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final avatar = Material(
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
    if (semanticLabel == null) return ExcludeSemantics(child: avatar);
    // excludeSemantics bỏ cả hành động chạm của InkWell, nên phải gắn onTap
    // ở đây để TalkBack bấm được (AC-39).
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: avatar,
    );
  }
}

/// Cỡ icon theo bản vẽ: 24 trên vòng tròn 48, 22 trên 40, 16 trong chấm 24.
double _iconSize(double avatar) => switch (avatar) {
  >= 48 => 24,
  >= 40 => 22,
  _ => avatar * 2 / 3,
};
