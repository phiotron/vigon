import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'tokens.g.dart';

/// Thành phần màn Cài đặt v2 (SettingsRows.html, SCR-12/33, CHANGELOG P2
/// 5.1/5.2): nhóm là thẻ `surface-container-low` bo `radius-lg`, tiêu đề nhóm
/// màu `primary`, hàng có icon đầu màu chữ phụ, giá trị là phụ đề.

/// Tiêu đề nhóm (`.vg-gtitle`): title-sm `primary`, lề 24/32/8 (nhóm đầu
/// trên cùng lề trên 8). Trình đọc màn hình đọc là tiêu đề.
class SettingsGroupTitle extends StatelessWidget {
  const SettingsGroupTitle(this.text, {super.key, this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      VgSpace.s8,
      first ? VgSpace.s2 : VgSpace.s6,
      VgSpace.s8,
      VgSpace.s2,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: VgType.titleSm.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// Thẻ nhóm (`.vg-card`): nền `surface-container-low`, bo `radius-lg`, lề
/// ngang 16, không bóng. Giữa các hàng có vạch `outline-variant` thụt 56 (thẳng
/// cột chữ). Hai thẻ liền nhau cách [gap].
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.children,
    this.dividers = true,
    this.margin = const EdgeInsets.symmetric(horizontal: VgSpace.s4),
  });

  final List<Widget> children;
  final bool dividers;
  final EdgeInsetsGeometry margin;

  /// Khoảng giữa hai thẻ liền nhau.
  static const gap = VgSpace.s3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = [
      for (final (i, c) in children.indexed) ...[
        if (i > 0 && dividers)
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: scheme.outlineVariant,
          ),
        c,
      ],
    ];
    return Padding(
      padding: margin,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VgRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

/// Hàng điều hướng / giá trị (`.vg-row`, `.vg-row.two`): icon 24 màu chữ phụ,
/// tên body-md, [value] là phụ đề body-sm màu chữ phụ (hàng cao tối thiểu 72
/// `row-two-line`; không có phụ đề thì 56), mũi tên › khi chạm được. [danger]:
/// icon và chữ màu `error`, không mũi tên (Xóa toàn bộ dữ liệu).
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  final IconData? icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  /// Thay mũi tên › mặc định (ví dụ ô xổ xuống "1 ▾").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = danger ? scheme.error : scheme.onSurface;
    final muted = danger ? scheme.error : scheme.onSurfaceVariant;
    final end =
        trailing ??
        (onTap != null && !danger
            ? Icon(
                Symbols.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              )
            : null);
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: value != null ? VgSize.rowTwoLine : VgSize.tapKey,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VgSpace.s4,
              vertical: VgSpace.s2,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: muted),
                  const SizedBox(width: VgSpace.s4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: VgType.bodyMd.copyWith(color: ink)),
                      if (value != null)
                        Text(
                          value!,
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (end != null) ...[const SizedBox(width: VgSpace.s1), end],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng công tắc (`.vg-srow`): icon, tên body-md, [subtitle] dài nhiều dòng
/// (không cắt), [footer] dưới phụ đề (ví dụ [StatusPill] "Đã khóa bằng PIN",
/// dòng trạng thái sao lưu, cặp nút); công tắc bên phải, căn trên. Cao tối
/// thiểu 72. Chạm cả hàng để bật/tắt; trình đọc màn hình đọc tên + phụ đề +
/// trạng thái trong một lần. [onChanged] null = khóa.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.footer,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Phần dưới phụ đề. Không nằm trong vùng chạm bật/tắt của hàng (có thể
  /// chứa nút riêng).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final toggle = onChanged == null ? null : () => onChanged!(!value);
    final head = MergeSemantics(
      child: InkWell(
        onTap: toggle,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            VgSpace.s4,
            VgSpace.s3,
            VgSpace.s4,
            footer == null ? VgSpace.s3 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: VgSpace.s4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: VgSpace.s4),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VgSize.rowTwoLine),
      child: footer == null
          ? head
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    icon != null ? 56 : VgSpace.s4,
                    0,
                    VgSpace.s4,
                    VgSpace.s3,
                  ),
                  child: footer,
                ),
              ],
            ),
    );
  }
}

/// Hàng có nút chọn một bên dưới (`.vg-seg` trong thẻ): [title] (nếu có) là
/// hàng icon + tên, rồi [segments] thụt vào thẳng cột chữ (Ngày đầu tuần);
/// không có [title] (Giao diện, Ngôn ngữ — tiêu đề nằm ở [SettingsGroupTitle])
/// thì [segments] lề 12/16.
class SettingsSegmentRow extends StatelessWidget {
  const SettingsSegmentRow({
    super.key,
    this.icon,
    this.title,
    required this.segments,
  });

  final IconData? icon;
  final String? title;
  final Widget segments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (title == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VgSpace.s4,
          vertical: VgSpace.s3,
        ),
        child: segments,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VgSize.tapMin),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s3,
              VgSpace.s4,
              VgSpace.s2,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: scheme.onSurfaceVariant),
                  const SizedBox(width: VgSpace.s4),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            icon != null ? 56 : VgSpace.s4,
            0,
            VgSpace.s4,
            VgSpace.s3,
          ),
          child: segments,
        ),
      ],
    );
  }
}

/// Trạng thái của [SettingsStatusLine].
enum SettingsStatus { idle, running, ok, error }

/// Dòng trạng thái sao lưu tự động (`.vg-statusline`, SCR-31): ⏱ chưa chạy
/// (chữ phụ), vòng quay khi đang chạy, ✓ `primary` khi xong, ⚠ trên dải
/// `error-container` / chữ `on-error-container` khi lỗi (không chỉ dựa vào
/// màu: luôn có icon và chữ). Là vùng thông báo trực tiếp để trình đọc màn
/// hình đọc khi trạng thái đổi.
class SettingsStatusLine extends StatelessWidget {
  const SettingsStatusLine({
    super.key,
    required this.status,
    required this.text,
  });

  final SettingsStatus status;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = status == SettingsStatus.error;
    final fg = error ? scheme.onErrorContainer : scheme.onSurfaceVariant;
    final Widget lead = switch (status) {
      SettingsStatus.idle => Icon(
        Symbols.schedule_rounded,
        fill: 1,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      SettingsStatus.running => SizedBox.square(
        dimension: 20,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
      ),
      SettingsStatus.ok => Icon(
        Symbols.check_circle_rounded,
        fill: 1,
        size: 20,
        color: scheme.primary,
      ),
      SettingsStatus.error => Icon(
        Symbols.error_rounded,
        fill: 1,
        size: 20,
        color: scheme.onErrorContainer,
      ),
    };
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: lead),
        const SizedBox(width: VgSpace.s2),
        Expanded(
          child: Text(text, style: VgType.bodySm.copyWith(color: fg)),
        ),
      ],
    );
    return Semantics(
      liveRegion: true,
      child: error
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(VgRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VgSpace.s3,
                  vertical: VgSpace.s2,
                ),
                child: row,
              ),
            )
          : row,
    );
  }
}

/// Màu của [StatusPill].
enum PillTone {
  /// `secondary-container`: "Đã khóa bằng PIN" (A08).
  lock,

  /// `primary-container`.
  ok,

  /// `error-container`.
  error,
}

/// Nhãn viên thuốc nhỏ (`.vg-pill`): icon 16 tô đầy + label-sm, cao tối
/// thiểu 24, bo tròn. Ví dụ dưới công tắc "Hiện số tiền trên widget" khi đang
/// khóa PIN.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.tone = PillTone.lock,
  });

  final IconData icon;
  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      PillTone.lock => (s.secondaryContainer, s.onSecondaryContainer),
      PillTone.ok => (s.primaryContainer, s.onPrimaryContainer),
      PillTone.error => (s.errorContainer, s.onErrorContainer),
    };
    return Padding(
      padding: const EdgeInsets.only(top: VgSpace.s2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(VgRadius.full),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 10, 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, fill: 1, size: 16, color: fg),
                  const SizedBox(width: VgSpace.s1),
                  Flexible(
                    child: Text(
                      label,
                      style: VgType.labelSm.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cặp nút xuống dòng khi hẹp (`.vg-btnpair`): cách nhau 8, lề trên 12. Ví dụ
/// `FilledButton.tonal` "Sao lưu ngay" + `OutlinedButton` "Chọn lại thư mục".
class ButtonPair extends StatelessWidget {
  const ButtonPair({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: VgSpace.s3),
    child: Wrap(
      spacing: VgSpace.s2,
      runSpacing: VgSpace.s2,
      children: children,
    ),
  );
}

/// Nhãn nút có trạng thái bận (Feedback.html "Button working"): khi [busy]
/// thì vòng quay 18 thay icon. Nút vẫn phải tự tắt `onPressed` khi bận.
class BusyButtonLabel extends StatelessWidget {
  const BusyButtonLabel({
    super.key,
    required this.label,
    this.icon,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (busy || icon != null) const SizedBox(width: VgSpace.s2),
        Flexible(child: Text(label)),
      ],
    );
  }
}
