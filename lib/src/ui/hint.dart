import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tokens.g.dart';

/// Dòng gợi ý nhỏ (`.vg-hint`): icon 18 rồi chữ body-sm màu chữ phụ. Icon
/// ⓘ ([Symbols.info_rounded], mặc định) màu chữ phụ; icon khác màu
/// `primary`. Dùng cho: ghi chú trong hộp thoại (SCR-27 `restoreSwitchesNote`),
/// `recurringRestartHint` (SCR-21), cảnh báo thư mục iOS.
/// [VgHintTone.error]: icon và chữ màu `error` (cảnh báo mật khẩu SCR-26/31).
class VgHint extends StatelessWidget {
  const VgHint(
    this.text, {
    super.key,
    this.icon = Symbols.info_rounded,
    this.padding = EdgeInsets.zero,
    this.tone = VgHintTone.neutral,
  });

  final String text;
  final IconData icon;
  final EdgeInsetsGeometry padding;
  final VgHintTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = tone == VgHintTone.error;
    final iconColor = error
        ? scheme.error
        : icon == Symbols.info_rounded
        ? scheme.onSurfaceVariant
        : scheme.primary;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: iconColor, fill: error ? 1 : 0),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: VgType.bodySm.copyWith(
                color: error ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tông của [VgHint].
enum VgHintTone { neutral, error }
