import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'theme.dart';
import 'tokens.g.dart';

/// Kiểu nút xác nhận trong [showConfirmDialog].
enum ConfirmStyle {
  /// Nút nền `primary` (mặc định).
  normal,

  /// Nút nền `error`: bước xác nhận cuối của hành động xóa (8.9, 1.4).
  danger,

  /// Nút chữ màu `error`: lối phụ dẫn tới bước xóa (1.3 Quên mã).
  dangerText,
}

/// Hộp thoại xác nhận theo `.vg-dialog` (1.3–1.5, 5.3, 8.6, 8.9): icon tùy
/// chọn ở giữa màu `error`, tiêu đề title-md, nội dung chữ phụ, nút Hủy và
/// nút hành động bên phải. Trả về true khi người dùng chọn hành động.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  IconData? icon,
  ConfirmStyle style = ConfirmStyle.normal,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        final confirm = switch (style) {
          ConfirmStyle.normal => FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
          ConfirmStyle.danger => FilledButton(
            style: dangerButtonStyle(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
          ConfirmStyle.dangerText => TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        };
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: VgSpace.s6,
            vertical: VgSpace.s6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VgSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 28, color: scheme.error),
                  const SizedBox(height: VgSpace.s3),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: VgSpace.s3),
                Text(
                  body,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: VgSpace.s6),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: VgSpace.s2,
                  runSpacing: VgSpace.s2,
                  children: [
                    // `primary` trên nền hộp thoại chỉ đạt 4,06:1 ở chủ đề sáng
                    // (README thiết kế), nên nút Hủy dùng màu chữ chính.
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.cancel),
                    ),
                    confirm,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ??
    false;
