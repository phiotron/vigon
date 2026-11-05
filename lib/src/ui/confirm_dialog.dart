import 'package:flutter/material.dart';

import 'dialog.dart';
import 'theme.dart';

/// Kiểu nút xác nhận trong [showConfirmDialog].
enum ConfirmStyle {
  /// Nút nền `primary` (mặc định).
  normal,

  /// Nút nền `error`: bước xác nhận cuối của hành động xóa (8.9, 1.4).
  danger,

  /// Nút chữ màu `error`: lối phụ dẫn tới bước xóa (1.3 Quên mã).
  dangerText,
}

/// Hộp thoại xác nhận (1.3–1.5, 5.3, 6.3, 8.6, 8.9) dựng bằng [VgDialog]: icon
/// tùy chọn, tiêu đề, nội dung chữ phụ, [note] có icon ⓘ (SCR-27), nút Hủy và
/// nút hành động; thân cuộn, nút ghim khi chữ lớn. [iconTone] mặc định màu
/// `error`. Trả về true khi người dùng chọn hành động.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  IconData? icon,
  VgDialogTone iconTone = VgDialogTone.danger,
  String? note,
  ConfirmStyle style = ConfirmStyle.normal,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) {
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
        return VgDialog(
          title: title,
          body: body,
          icon: icon,
          tone: iconTone,
          note: note,
          actions: [
            VgDialog.cancelButton(
              context,
              onPressed: () => Navigator.pop(context, false),
            ),
            confirm,
          ],
        );
      },
    ) ??
    false;
