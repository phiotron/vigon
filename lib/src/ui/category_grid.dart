import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../data/database.dart';
import '../l10n_names.dart';
import '../providers.dart';
import 'category_avatar.dart';
import 'choice_sheet.dart';
import 'tokens.g.dart';

/// Mở bảng chọn từ dưới lên chứa lưới mọi danh mục của [type]; trả về id danh
/// mục được chọn (AC-02, AC-51).
Future<int?> showCategorySheet(
  BuildContext context, {
  required CategoryType type,
  int? selectedId,
}) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => CategoryGrid(type: type, selectedId: selectedId),
);

/// Ô "Danh mục khác" (dấu ba chấm ngang) cuối vòng icon ở màn chính, mở lưới
/// đầy đủ khi không đủ chỗ xếp mọi danh mục (AC-51).
class MoreCategoriesAvatar extends StatelessWidget {
  const MoreCategoriesAvatar({super.key, this.size = 48, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l.otherCategories,
      child: Semantics(
        button: true,
        label: l.otherCategories,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: scheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                Symbols.more_horiz_rounded,
                color: scheme.onSurfaceVariant,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bảng "Chọn danh mục" (3.3): lưới 4 cột, ô rộng tối đa 96, icon 48, tên
/// label-sm tối đa 2 dòng. Chạm một ô là đóng bảng và trả về id danh mục.
/// Dùng ở màn ghi khoản và ô "Danh mục khác" của màn chính (AC-02, AC-51).
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key, required this.type, this.selectedId});

  final CategoryType type;
  final int? selectedId;

  static const _columns = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider(type)).value ?? const <Category>[];
    final rows = (categories.length / _columns).ceil();

    Widget cell(Category c) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 96),
        child: Semantics(
          button: true,
          selected: c.id == selectedId,
          label: categoryLabel(l, c),
          excludeSemantics: true,
          onTap: () => Navigator.pop(context, c.id),
          child: InkWell(
            borderRadius: BorderRadius.circular(VgRadius.md),
            onTap: () => Navigator.pop(context, c.id),
            child: Padding(
              padding: const EdgeInsets.all(VgSpace.s1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryAvatar(category: c),
                  const SizedBox(height: 6),
                  Text(
                    categoryLabel(l, c),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VgType.labelSm.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: VgSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.chooseCategory),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s3),
                child: Column(
                  children: [
                    for (var r = 0; r < rows; r++)
                      Padding(
                        padding: EdgeInsets.only(top: r == 0 ? 0 : VgSpace.s2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < _columns; i++)
                              Expanded(
                                child: r * _columns + i < categories.length
                                    ? cell(categories[r * _columns + i])
                                    : const SizedBox(),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
