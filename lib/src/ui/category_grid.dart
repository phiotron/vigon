import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../data/database.dart';
import '../l10n_names.dart';
import '../providers.dart';
import 'category_avatar.dart';

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
                Icons.more_horiz,
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

/// Lưới danh mục; chạm một danh mục là đóng bảng và trả về id của nó.
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key, required this.type, this.selectedId});

  final CategoryType type;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider(type)).value ?? const <Category>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.chooseCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.extent(
                shrinkWrap: true,
                maxCrossAxisExtent: 96,
                childAspectRatio: 0.8,
                children: [
                  for (final c in categories)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, c.id),
                      child: Semantics(
                        button: true,
                        selected: c.id == selectedId,
                        label: categoryLabel(l, c),
                        excludeSemantics: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CategoryAvatar(category: c),
                            const SizedBox(height: 4),
                            Text(
                              categoryLabel(l, c),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
