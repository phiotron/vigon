import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'format.dart';
import 'tokens.g.dart';

/// Nút chọn một (`.vg-seg`, SettingsRows.html, 5.1): viền `outline`, bo tròn, cao 40
/// (vùng chạm 48), ô đang chọn nền `secondary-container` có dấu ✓. Mỗi ô rộng
/// theo chữ của nó rồi chia đều phần dư, nên "Theo hệ thống" không xuống dòng.
/// Chữ lớn (≥ 130%) hoặc không đủ chỗ thì xếp dọc (D-008, AC-38).
class ChoiceSegments<T> extends StatelessWidget {
  const ChoiceSegments({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  static const _height = 40.0;
  static const _inset = (VgSize.tapMin - _height) / 2;
  static const _check = 18.0;
  static const _gap = VgSpace.s1;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Gộp với kiểu chữ mặc định để đo đúng họ chữ của app (Be Vietnam Pro).
    final style = DefaultTextStyle.of(context).style
        .merge(VgType.labelMd)
        .copyWith(color: scheme.onSurface);
    final border = BorderSide(color: scheme.outline);

    Widget label(T value, String text) {
      final on = value == selected;
      final fg = on ? scheme.onSecondaryContainer : scheme.onSurface;
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (on) ...[
            Icon(Symbols.check_rounded, size: _check, color: fg),
            const SizedBox(width: _gap),
          ],
          Flexible(
            child: Text(
              text,
              style: style.copyWith(color: fg),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    Widget tap(T value, Widget child) => Semantics(
      button: true,
      selected: value == selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(onTap: () => onChanged(value), child: child),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double natural((T, String) o) {
          final painter = TextPainter(
            text: TextSpan(text: o.$2, style: style),
            textScaler: scaler,
            textDirection: direction,
            maxLines: 1,
          )..layout();
          final width =
              painter.width +
              2 * VgSpace.s2 +
              (o.$1 == selected ? _check + _gap : 0) +
              1;
          painter.dispose();
          return width;
        }

        final widths = [for (final o in options) natural(o)];
        final inner = constraints.maxWidth - 2;
        final total = widths.fold<double>(0, (a, b) => a + b);

        if (isLargeText(context) || total > inner) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.fromBorderSide(border),
              borderRadius: BorderRadius.circular(VgRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, (value, text)) in options.indexed)
                  tap(
                    value,
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: VgSize.tapMin,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: VgSpace.s4,
                        vertical: VgSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: value == selected
                            ? scheme.secondaryContainer
                            : null,
                        border: i == 0 ? null : Border(top: border),
                      ),
                      child: label(value, text),
                    ),
                  ),
              ],
            ),
          );
        }

        // Phần dư chia đều cho các ô (giống `flex: 1 1 auto` của bản vẽ).
        final extra = (inner - total) / options.length;
        final cells = [for (final w in widths) w + extra];
        return Stack(
          children: [
            // Lớp nền: khung viền cao 40 nằm giữa vùng chạm 48.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: _inset),
              child: Container(
                height: _height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(border),
                  borderRadius: BorderRadius.circular(VgRadius.full),
                ),
                child: Row(
                  children: [
                    for (final (i, (value, _)) in options.indexed)
                      Container(
                        width: cells[i],
                        decoration: BoxDecoration(
                          color: value == selected
                              ? scheme.secondaryContainer
                              : null,
                          border: i == 0 ? null : Border(left: border),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Lớp chữ và vùng chạm.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  for (final (i, (value, text)) in options.indexed)
                    tap(
                      value,
                      SizedBox(
                        width: cells[i],
                        height: VgSize.tapMin,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VgSpace.s2,
                          ),
                          child: label(value, text),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
