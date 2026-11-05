import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tokens.g.dart';

/// Tiêu đề bảng kéo (`.shead`): title-md, lề 8/24/12.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      VgSpace.s6,
      VgSpace.s2,
      VgSpace.s6,
      VgSpace.s3,
    ),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// Một lựa chọn trong [showChoiceSheet].
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Một dòng chọn trong bảng kéo (2.4, 3.5, 3.6): cao tối thiểu 56, icon đầu
/// màu chữ phụ; dòng đang chọn nền `primary-container`, bo tròn, có dấu ✓.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: selected ? VgSpace.s3 : 0),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        shape: selected
            ? const StadiumBorder()
            : const RoundedRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapKey),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VgSpace.s4,
                  vertical: VgSpace.s2,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg),
                      const SizedBox(width: VgSpace.s4),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: VgType.bodyMd.copyWith(
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    if (selected) Icon(Symbols.check_rounded, color: fg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bảng kéo chọn một trong [options] (2.4 Xem theo, 3.5 Lặp lại, 3.6 Tài
/// khoản). Trả về `(giá trị,)` khi chọn, `null` khi đóng mà không chọn; bọc
/// trong record để giá trị `null` (ví dụ "Không lặp") vẫn phân biệt được.
Future<(T,)?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceOption<T>> options,
  required T selected,
}) => showModalBottomSheet<(T,)>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(bottom: VgSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ChoiceRow(
                    label: o.label,
                    icon: o.icon,
                    selected: o.value == selected,
                    onTap: () => Navigator.pop(context, (o.value,)),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
