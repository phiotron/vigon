import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/dialog.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../entry/keypad.dart' show minorUnitsToInput;
import '../settings/budget_dialog.dart' show currencySymbol;
import 'category_icons.dart';
import 'sheet_footer.dart';

/// Quản lý danh mục chi và thu: thêm, sửa, sắp xếp, xóa (F-05), theo S10
/// (6.1–6.3): hai tab Chi / Thu, nút nổi + "Thêm danh mục".
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Vạch chọn rộng 40% tab, dày 3, bo trên (`.vg-tabs`).
    final tabWidth = MediaQuery.sizeOf(context).width / 2;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l.categories),
            bottom: TabBar(
              labelStyle: VgType.titleSm,
              unselectedLabelStyle: VgType.titleSm,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              dividerColor: scheme.outlineVariant,
              dividerHeight: 1,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: scheme.primary),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                insets: EdgeInsets.symmetric(horizontal: tabWidth * 0.3),
              ),
              tabs: [
                Tab(height: VgSize.tapMin, text: l.expense),
                Tab(height: VgSize.tapMin, text: l.income),
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
            child: const Icon(Symbols.add_rounded),
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
                child: Icon(Symbols.drag_handle_rounded),
              ),
            ),
          ),
          onTap: () => showCategoryEditor(context, type: type, category: c),
        );
      },
    );
  }
}

/// Thêm hoặc sửa danh mục: tên, icon, màu (AC-16); xóa có chuyển khoản
/// (AC-17). Bảng kéo theo 6.2.
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

/// Lưới ô vuông 48 (vùng chạm tối thiểu, AC-37), tối đa [maxColumns] cột,
/// căn đều hai mép như `.vg-icongrid` / `.vg-colorgrid`. Lề hai bên 24 như
/// bản vẽ khi đủ chỗ; thiếu chỗ thì lề co tới 12 rồi mới bớt cột.
class _CellGrid extends StatelessWidget {
  const _CellGrid({required this.maxColumns, required this.children});

  final int maxColumns;
  final List<Widget> children;

  static const _cell = VgSize.tapMin;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final pad = ((width - maxColumns * _cell) / 2).clamp(
        VgSpace.s3,
        VgSpace.s6,
      );
      final inner = width - 2 * pad;
      final columns = (inner / _cell).floor().clamp(1, maxColumns);
      final gap = columns > 1 ? (inner - columns * _cell) / (columns - 1) : 0.0;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: pad),
        child: Wrap(
          // Trừ một chút để sai số làm tròn không đẩy ô cuối xuống dòng.
          spacing: (gap - 0.01).clamp(0, double.infinity),
          children: [
            for (final c in children)
              SizedBox.square(
                dimension: _cell,
                child: Center(child: c),
              ),
          ],
        ),
      );
    },
  );
}

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
  late final int _digits = currencyDecimalDigits(
    ref.read(currencyProvider).value ?? 'VND',
  );
  late final _budget = TextEditingController(
    text: widget.category?.budget == null
        ? ''
        : minorUnitsToInput(widget.category!.budget!, _digits),
  );
  String? _error;
  String? _budgetError;

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
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l.nameRequired);
      return;
    }
    // Hạn mức tháng chỉ cho danh mục chi; để trống là không đặt (AC-54).
    int? budget;
    final budgetText = _budget.text.trim();
    if (widget.type == CategoryType.expense && budgetText.isNotEmpty) {
      budget = evaluateToMinorUnits(
        budgetText.replaceAll(',', '.'),
        decimalDigits: _digits,
      );
      if (budget == null || budget <= 0) {
        setState(() {
          _error = null;
          _budgetError = l.amountMustBePositive;
        });
        return;
      }
    }
    final repo = ref.read(categoryRepositoryProvider);
    final c = widget.category;
    if (c == null) {
      await repo.add(
        type: widget.type,
        name: name,
        icon: _icon,
        color: _color,
        budget: budget,
      );
    } else {
      // Không đổi tên thì giữ tên mặc định theo ngôn ngữ.
      final unchangedName = name == categoryLabel(l, c) && c.nameKey != null;
      await repo.edit(
        c.id,
        name: unchangedName ? null : name,
        icon: _icon,
        color: _color,
        budget: widget.type == CategoryType.expense
            ? Value(budget)
            : const Value.absent(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  /// Xóa (6.3): có khoản hoặc chuỗi định kỳ thì chọn danh mục nhận, chạm là
  /// xóa; chưa dùng ở đâu thì chỉ hỏi xác nhận.
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
    final usedByRule =
        (ref.read(recurringRulesProvider).value ?? const <RecurringRule>[]).any(
          (r) => r.categoryId == c.id,
        );
    if (!mounted) return;
    final int? target;
    if (count == 0 && !usedByRule) {
      final ok = await showConfirmDialog(
        context,
        title: l.deleteCategoryConfirm,
        body: l.deleteCategoryEmptyBody,
        action: l.delete,
        icon: Symbols.delete_rounded,
        style: ConfirmStyle.danger,
      );
      target = ok ? others.first.id : null;
    } else {
      target = await showDialog<int>(
        context: context,
        builder: (context) => _MoveToDialog(count: count, categories: others),
      );
    }
    if (target == null) return;
    await repo.delete(c.id, moveTo: target);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.category != null;
    final canDelete =
        isEdit &&
        (ref.watch(categoriesProvider(widget.type)).value?.length ?? 0) > 1;
    // Nhãn nhóm (`.vg-flabel`): label-md màu chữ phụ, lề 16/24/8.
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s6,
        VgSpace.s4,
        VgSpace.s6,
        VgSpace.s2,
      ),
      child: Text(
        text,
        style: VgType.labelMd.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(isEdit ? l.editCategory : l.addCategory),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s6,
                      VgSpace.s2,
                      VgSpace.s6,
                      0,
                    ),
                    child: TextField(
                      controller: _name,
                      maxLength: 50,
                      autofocus: !isEdit,
                      decoration: InputDecoration(
                        labelText: l.name,
                        errorText: _error,
                      ),
                    ),
                  ),
                  label(l.icon),
                  // 31 biểu tượng, 7 cột; ô đang chọn nền màu danh mục, icon tô đầy.
                  _CellGrid(
                    maxColumns: 7,
                    children: [
                      for (final (index, entry)
                          in categoryIcons.entries.indexed)
                        IconButton(
                          key: ValueKey('icon-${entry.key}'),
                          isSelected: entry.key == _icon,
                          iconSize: 22,
                          style: IconButton.styleFrom(
                            backgroundColor: entry.key == _icon
                                ? Color(_color)
                                : null,
                            foregroundColor: entry.key == _icon
                                ? context.vg.onCat
                                : scheme.onSurfaceVariant,
                          ),
                          icon: Icon(
                            entry.value,
                            fill: entry.key == _icon ? 1 : 0,
                          ),
                          tooltip: l.iconNumber(index + 1),
                          onPressed: () => setState(() => _icon = entry.key),
                        ),
                    ],
                  ),
                  label(l.color),
                  // 16 màu; ô đang chọn có vòng `ink` và dấu ✓ (màu không phải kênh
                  // duy nhất).
                  _CellGrid(
                    maxColumns: 8,
                    children: [
                      for (final (index, color) in categoryColors.indexed)
                        _ColorSwatch(
                          color: Color(color),
                          selected: color == _color,
                          label: '${l.color} ${index + 1}',
                          onTap: () => setState(() => _color = color),
                        ),
                    ],
                  ),
                  // SCR-16: ô hạn mức sau Màu, chỉ danh mục chi, có ký hiệu
                  // tiền tệ; lỗi thay chỗ dòng gợi ý (AC-54).
                  if (widget.type == CategoryType.expense)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s4,
                        VgSpace.s6,
                        VgSpace.s4,
                        VgSpace.s4,
                      ),
                      child: TextField(
                        key: const ValueKey('category-budget'),
                        controller: _budget,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          labelText: l.categoryBudget,
                          suffixText: currencySymbol(
                            ref.watch(currencyProvider).value ?? 'VND',
                          ),
                          helperText: l.categoryBudgetHint,
                          helperMaxLines: 3,
                          errorText: _budgetError,
                          errorMaxLines: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Footer ghim ngoài vùng cuộn, nằm trên bàn phím (SCR-16).
          SheetFooter(
            children: [
              if (canDelete)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
                  ),
                  icon: const Icon(Symbols.delete_rounded),
                  label: Text(l.deleteCategory),
                  onPressed: _delete,
                ),
              FilledButton(
                style: sheetFilledButtonStyle(),
                onPressed: _save,
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ô màu tròn 32 trong vùng chạm 48; đang chọn thì có vòng `ink` dày 2 cách
/// 3 và dấu ✓ (`.vg-colorgrid > span.on`).
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox.square(
        dimension: VgSize.tapMin,
        child: Center(
          child: Container(
            key: selected ? const ValueKey('color-selected') : null,
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(5),
            decoration: selected
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 2,
                    ),
                  )
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: selected
                  ? Icon(
                      Symbols.check_rounded,
                      size: 18,
                      color: context.vg.onCat,
                    )
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Chọn danh mục nhận các khoản khi xóa (6.3): [VgDialog] thân cuộn (200%),
/// chạm một danh mục là xóa, có nút Hủy.
class _MoveToDialog extends StatelessWidget {
  const _MoveToDialog({required this.count, required this.categories});

  final int count;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VgDialog(
      title: l.deleteCategoryConfirm,
      icon: Symbols.delete_rounded,
      body: l.moveEntriesTo(count),
      content: [
        for (final o in categories)
          InkWell(
            borderRadius: BorderRadius.circular(VgRadius.sm),
            onTap: () => Navigator.pop(context, o.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapKey),
              child: Row(
                children: [
                  CategoryAvatar(category: o, size: 40),
                  const SizedBox(width: VgSpace.s4),
                  Expanded(
                    child: Text(categoryLabel(l, o), style: VgType.bodyMd),
                  ),
                ],
              ),
            ),
          ),
      ],
      actions: [VgDialog.cancelButton(context)],
    );
  }
}
