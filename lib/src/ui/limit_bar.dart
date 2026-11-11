import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'theme.dart';
import 'tokens.g.dart';

/// Thanh hạn mức (`.vg-catbudget` 4 dp ở danh sách khoản SCR-10, `.vg-budget`
/// 8 dp ngân sách tháng ở màn chính): một dòng chữ body-sm màu chữ phụ rồi
/// thanh tiến độ bo tròn trên nền `surface-container-high`, phần đã dùng
/// `primary`. Vượt: chữ `error` đậm + icon ⚠ 16 + thanh đầy màu `error` —
/// không chỉ dựa vào màu (AC-27, AC-54). Sắp vượt ([near], F-37 AC-111): chữ +
/// icon ⓘ + phần đã dùng màu `warning` (hổ phách, khác đỏ của Vượt). [text] do
/// màn ghép sẵn, ví dụ
/// `categoryLimitThisMonth(budgetProgress(...))` khi đang xem kỳ khác tháng
/// này (A05). Trình đọc màn hình đọc đúng [text].
class LimitBar extends StatelessWidget {
  const LimitBar({
    super.key,
    required this.text,
    required this.progress,
    required this.over,
    this.near = false,
    this.thickness = 4,
  });

  final String text;

  /// Đã dùng / hạn mức; tự kẹp trong 0…1.
  final double progress;
  final bool over;

  /// Đã chạm ngưỡng "Sắp vượt" mà chưa vượt (AC-111). Bỏ qua khi [over].
  final bool near;

  /// 4 cho hạn mức danh mục, 8 cho ngân sách tháng.
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warn = near && !over;
    final color = over
        ? scheme.error
        : warn
        ? context.vg.warning
        : scheme.onSurfaceVariant;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (over || warn) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    over ? Symbols.warning_rounded : Symbols.error_rounded,
                    fill: 1,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: VgSpace.s1),
              ],
              Expanded(
                child: Text(
                  text,
                  style: VgType.bodySm.copyWith(
                    color: color,
                    fontWeight: over || warn ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(VgRadius.full),
            child: LinearProgressIndicator(
              value: over ? 1 : progress.clamp(0, 1).toDouble(),
              minHeight: thickness,
              backgroundColor: scheme.surfaceContainerHigh,
              color: over
                  ? scheme.error
                  : warn
                  ? context.vg.warning
                  : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
