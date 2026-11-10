import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'format.dart';
import 'hint.dart';
import 'tokens.g.dart';

/// Màu icon đầu hộp thoại (`.dicon`).
enum VgDialogTone {
  /// `error`: xác nhận xóa, cảnh báo (mặc định, như 1.4, 8.9).
  danger,

  /// `ink-muted`: hộp thoại thường (khôi phục, nhắc ghi sổ).
  neutral,
}

/// Hộp thoại theo `.vg-dialog` v2 (Dialogs.html): nền `surface-container-high`,
/// bo `radius-xl`, lề 24. Thân (icon, tiêu đề, nội dung, [note], [content])
/// cuộn được; hàng nút luôn ghim ở đáy — chữ ≥ 130% thì có vạch ngăn trên
/// hàng nút (CHANGELOG P2: 5.3, 6.3, 8.6…). Nút xuống dòng khi không đủ chỗ.
///
/// Ba loại trong design-system: thường (chỉ chữ), xóa (icon `danger` + nút
/// [dangerButtonStyle]), form ([content] là ô nhập, ví dụ [PasswordField]).
class VgDialog extends StatelessWidget {
  const VgDialog({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.tone = VgDialogTone.danger,
    this.note,
    this.content = const [],
    required this.actions,
  });

  final String title;

  /// Nội dung màu chữ phụ: body-md ở hộp xác nhận; body-sm khi hộp có
  /// [content] (hộp form SCR-26/27/31, `.dbody.body-sm`).
  final String? body;
  final IconData? icon;
  final VgDialogTone tone;

  /// Dòng ghi chú có icon ⓘ dưới nội dung (`.vg-hint.info`, SCR-27:
  /// `restoreSwitchesNote`).
  final String? note;

  /// Phần thêm trong thân cuộn: ô nhập, công tắc, cảnh báo.
  final List<Widget> content;

  /// Nút, từ trái sang phải; nút chính đặt cuối.
  final List<Widget> actions;

  /// Nút Hủy chuẩn: chữ màu chữ chính (`primary` trên nền hộp thoại chỉ
  /// 4,06:1 ở chủ đề sáng).
  /// [enabled] false: nút tắt (đang xử lý, A13); [onPressed] null = đóng hộp.
  static Widget cancelButton(
    BuildContext context, {
    VoidCallback? onPressed,
    bool enabled = true,
  }) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
    ),
    onPressed: !enabled ? null : onPressed ?? () => Navigator.pop(context),
    child: Text(AppLocalizations.of(context).cancel),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final large = isLargeText(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(VgSpace.s6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(VgSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 24,
                          color: tone == VgDialogTone.danger
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: VgSpace.s3),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: icon != null
                              ? TextAlign.center
                              : TextAlign.start,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: VgSpace.s3),
                        Text(
                          body!,
                          style:
                              (content.isEmpty ? VgType.bodyMd : VgType.bodySm)
                                  .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      if (note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: VgSpace.s3),
                          child: VgHint(note!, icon: Symbols.info_rounded),
                        ),
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: VgSpace.s4),
                        ...content,
                      ],
                    ],
                  ),
                ),
              ),
              if (large) ...[
                const SizedBox(height: VgSpace.s3),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: VgSpace.s3),
              ] else
                const SizedBox(height: VgSpace.s6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: VgSpace.s2,
                runSpacing: VgSpace.s2,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
