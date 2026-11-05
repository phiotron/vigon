import 'package:flutter/material.dart';

import '../../ui/format.dart';
import '../../ui/tokens.g.dart';

/// Hàng nút ghim ở đáy bảng kéo (`.sfoot`, SCR-16/18/21): nền
/// `surface-container`, vạch `outline-variant` phía trên (tắt bằng [border]),
/// lề 12/16. Các nút chia đều bề ngang; một nút thì chiếm cả hàng; chữ ≥ 130%
/// thì xếp dọc để nhãn không bị cắt (`.sfoot { flex-wrap: wrap }`).
///
/// Dựng tạm trong feature của D2 vì `lib/src/ui/` chưa có (ghi ở notes D2:
/// nên chuyển vào `ui/` cùng [sheetFilledButtonStyle]).
class SheetFooter extends StatelessWidget {
  const SheetFooter({super.key, required this.children, this.border = true});

  final List<Widget> children;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stack = children.length == 1 || isLargeText(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: border
            ? Border(top: BorderSide(color: scheme.outlineVariant))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VgSpace.s4,
          vertical: VgSpace.s3,
        ),
        child: stack
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) const SizedBox(height: VgSpace.s2),
                    c,
                  ],
                ],
              )
            : Row(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) const SizedBox(width: VgSpace.s3),
                    Expanded(child: c),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Nút lớn trong [SheetFooter] (`.vg-btn.big`): cao 48, bo `radius-lg`,
/// lề ngang 24, chữ label-lg.
ButtonStyle sheetFilledButtonStyle() => FilledButton.styleFrom(
  minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
  padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
  textStyle: VgType.labelLg.copyWith(fontFamily: vgFontFamily),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VgRadius.lg),
  ),
);

/// Nút viền lớn (`.vg-btn.outline.big`): Hủy ở SCR-21.
ButtonStyle sheetOutlinedButtonStyle() => OutlinedButton.styleFrom(
  minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
  padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
  textStyle: VgType.labelLg.copyWith(fontFamily: vgFontFamily),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VgRadius.lg),
  ),
);
