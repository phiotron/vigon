import 'package:flutter/material.dart';

import '../data/database.dart';
import '../features/categories/category_icons.dart';

/// Icon danh mục trên nền màu của nó; vùng chạm 48×48 dp (AC-37).
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
            color: Colors.white,
            size: size * 0.5,
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
