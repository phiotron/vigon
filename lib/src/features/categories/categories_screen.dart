import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import 'category_icons.dart';

/// Quản lý danh mục chi và thu: thêm, sửa, sắp xếp, xóa (F-05).
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l.categories),
            bottom: TabBar(
              tabs: [
                Tab(text: l.expense),
                Tab(text: l.income),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _CategoryList(type: CategoryType.expense),
              _CategoryList(type: CategoryType.income),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: l.addCategory,
            onPressed: () {
              final index = DefaultTabController.of(context).index;
              showCategoryEditor(
                context,
                type: index == 0 ? CategoryType.expense : CategoryType.income,
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider(type)).value ?? const <Category>[];
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: categories.length,
      onReorderItem: (oldIndex, newIndex) {
        final ids = categories.map((c) => c.id).toList();
        ids.insert(newIndex, ids.removeAt(oldIndex));
        ref.read(categoryRepositoryProvider).reorder(ids);
      },
      itemBuilder: (context, i) {
        final c = categories[i];
        return ListTile(
          key: ValueKey(c.id),
          leading: CategoryAvatar(category: c, size: 40),
          title: Text(categoryLabel(l, c)),
          trailing: ReorderableDragStartListener(
            index: i,
            child: Tooltip(
              message: l.reorderHint,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
          onTap: () => showCategoryEditor(context, type: type, category: c),
        );
      },
    );
  }
}

/// Thêm hoặc sửa danh mục: tên, icon, màu (AC-16); xóa có chuyển khoản (AC-17).
Future<void> showCategoryEditor(
  BuildContext context, {
  required CategoryType type,
  Category? category,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _CategoryEditor(type: type, category: category),
  ),
);

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.type, this.category});

  final CategoryType type;
  final Category? category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final _name = TextEditingController();
  late String _icon = widget.category?.icon ?? 'more_horiz';
  late int _color = widget.category?.color ?? categoryColors.first;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = widget.category;
    if (c != null && _name.text.isEmpty) {
      _name.text = categoryLabel(AppLocalizations.of(context), c);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l.nameRequired);
      return;
    }
    final repo = ref.read(categoryRepositoryProvider);
    final c = widget.category;
    if (c == null) {
      await repo.add(type: widget.type, name: name, icon: _icon, color: _color);
    } else {
      // Không đổi tên thì giữ tên mặc định theo ngôn ngữ.
      final unchangedName = name == categoryLabel(l, c) && c.nameKey != null;
      await repo.edit(
        c.id,
        name: unchangedName ? null : name,
        icon: _icon,
        color: _color,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final c = widget.category!;
    final repo = ref.read(categoryRepositoryProvider);
    final others =
        (ref.read(categoriesProvider(widget.type)).value ?? const <Category>[])
            .where((o) => o.id != c.id)
            .toList();
    if (others.isEmpty) return;
    final count = await repo.usageCount(c.id);
    if (!mounted) return;
    final target = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.deleteCategoryConfirm),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.moveEntriesTo(count)),
          ),
          for (final o in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, o.id),
              child: Row(
                children: [
                  CategoryAvatar(category: o, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(categoryLabel(l, o))),
                ],
              ),
            ),
        ],
      ),
    );
    if (target == null) return;
    await repo.delete(c.id, moveTo: target);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEdit = widget.category != null;
    final canDelete =
        isEdit &&
        (ref.watch(categoriesProvider(widget.type)).value?.length ?? 0) > 1;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? l.editCategory : l.addCategory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 50,
              autofocus: !isEdit,
              decoration: InputDecoration(labelText: l.name, errorText: _error),
            ),
            Text(l.icon, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final (index, entry) in categoryIcons.entries.indexed)
                  IconButton(
                    isSelected: entry.key == _icon,
                    style: IconButton.styleFrom(
                      backgroundColor: entry.key == _icon
                          ? Color(_color)
                          : null,
                      foregroundColor: entry.key == _icon ? Colors.white : null,
                    ),
                    icon: Icon(entry.value),
                    key: ValueKey('icon-${entry.key}'),
                    tooltip: l.iconNumber(index + 1),
                    onPressed: () => setState(() => _icon = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.color, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in categoryColors)
                  Semantics(
                    button: true,
                    selected: color == _color,
                    label: '${l.color} ${categoryColors.indexOf(color) + 1}',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: color == _color
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: color == _color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (canDelete)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.deleteCategory),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: Text(l.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
