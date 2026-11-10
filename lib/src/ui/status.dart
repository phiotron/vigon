import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.g.dart';

/// Kiểu của [StatusChip] (token v3): luôn có icon + chữ, không chỉ màu.
enum StatusTone { ok, warn, err, info, neutral }

/// Chip trạng thái nhỏ (mockup v4 "Status chip"): Quá hạn, Tỷ giá ngoại
/// tuyến, Đã xong, Gợi ý… Nền/chữ theo [tone].
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(context, tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VgRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 16, color: fg)),
          const SizedBox(width: VgSpace.s1),
          Flexible(
            child: Text(
              label,
              style: VgType.labelMd.copyWith(color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Màu nền + chữ của một [StatusTone].
(Color, Color) statusColors(BuildContext context, StatusTone tone) {
  final vg = context.vg;
  return switch (tone) {
    StatusTone.ok => (vg.secondaryContainer, vg.onSecondaryContainer),
    StatusTone.warn => (vg.warningContainer, vg.onWarningContainer),
    StatusTone.err => (vg.errorContainer, vg.onErrorContainer),
    StatusTone.info => (vg.infoContainer, vg.onInfoContainer),
    StatusTone.neutral => (vg.surfaceContainerHigh, vg.inkMuted),
  };
}

/// Dải thông tin một dòng (`.vg-banner`): nền `info-container`, icon 20,
/// chữ body-sm, mũi tên › khi chạm được. Cao tối thiểu 44 (+ vùng chạm 48).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.tone = StatusTone.info,
    this.margin = const EdgeInsets.fromLTRB(
      VgSpace.s4,
      0,
      VgSpace.s4,
      VgSpace.s2,
    ),
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final StatusTone tone;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(context, tone);
    return Padding(
      padding: margin,
      child: Semantics(
        button: onTap != null,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(VgRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(VgRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: onTap == null ? 44 : VgSize.tapMin,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  VgSpace.s3,
                  6,
                  VgSpace.s2,
                  6,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(child: Icon(icon, size: 20, color: fg)),
                    const SizedBox(width: VgSpace.s2),
                    Expanded(
                      child: Text(
                        text,
                        style: VgType.bodySm.copyWith(color: fg),
                      ),
                    ),
                    if (onTap != null)
                      ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: fg,
                        ),
                      ),
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

/// Nút icon có số đếm đỏ (`.bdg`, token `badge`/`on-badge`): hộp thư hàng
/// đợi ở Màn chính. [count] = 0 thì không có số.
class BadgedIconButton extends StatelessWidget {
  const BadgedIconButton({
    super.key,
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vg = context.vg;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: vg.badge,
        textColor: vg.onBadge,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon),
      ),
    );
  }
}

/// Dấu ✉ nhỏ sau tên khoản lưu/ghép từ email ngân hàng (mockup v4
/// `.mail-mk`): ô 18 bo 4, nền `info-container`, icon 13.
class MailMarker extends StatelessWidget {
  const MailMarker({super.key, required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final vg = context.vg;
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsetsDirectional.only(start: VgSpace.s1),
        decoration: BoxDecoration(
          color: vg.infoContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.mail_rounded, size: 13, color: vg.onInfoContainer),
      ),
    );
  }
}
