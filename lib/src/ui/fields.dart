import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'tokens.g.dart';

/// Ô mật khẩu (TextFields.html "Password", Dialogs.html "Form"): ô viền cao
/// tối thiểu 56 theo theme, chấm che chữ, nút 👁 ở cuối hiện/ẩn mật khẩu
/// (vùng chạm 48, đọc "Hiện mật khẩu" / "Ẩn mật khẩu"). Tắt gợi ý bàn phím
/// và tự sửa để bàn phím không học mật khẩu.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.controller,
    required this.label,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String label;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.helperText,
        helperMaxLines: 3,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: _visible ? l.hidePassword : l.showPassword,
          onPressed: widget.enabled
              ? () => setState(() => _visible = !_visible)
              : null,
          icon: Icon(
            _visible
                ? Symbols.visibility_off_rounded
                : Symbols.visibility_rounded,
          ),
        ),
      ),
    );
  }
}

/// Ô tìm trong thanh tiêu đề (SearchField.html, SCR-11, SCR-13): viên thuốc
/// cao 48 (cao lên theo chữ), nền `surface-container`, gợi ý màu chữ phụ, nút
/// ✕ "Xóa nội dung tìm" chỉ hiện khi có chữ (giữ con trỏ trong ô). [leading]
/// là nút quay lại / đóng đặt trước ô (do màn quyết định).
class VgSearchField extends StatefulWidget {
  const VgSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<VgSearchField> createState() => _VgSearchFieldState();
}

class _VgSearchFieldState extends State<VgSearchField> {
  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VgSize.tapMin),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(VgRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: VgSpace.s4,
            end: VgSpace.s1,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  textInputAction: TextInputAction.search,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    isCollapsed: true,
                    constraints: const BoxConstraints(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: VgSpace.s3,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: widget.controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox(width: VgSpace.s2)
                    : IconButton(
                        tooltip: l.searchClear,
                        onPressed: _clear,
                        icon: Icon(
                          Symbols.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cặp chip chọn phạm vi tìm (Chips.html "Filter chip pair", `.vg-fchip`,
/// A21): chọn một; chip cao 32 viền `outline` bo `radius-sm`, chip đang chọn
/// nền `secondary-container` có dấu ✓, vùng chạm cao 48. Ví dụ
/// `[(false, 'Tháng 11 năm 2026'), (true, 'Tất cả thời gian')]`.
class ScopeChips<T> extends StatelessWidget {
  const ScopeChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(VgRadius.sm);

    Widget chip(T value, String label) {
      final on = value == selected;
      final fg = on ? scheme.onSecondaryContainer : scheme.onSurface;
      return Semantics(
        button: true,
        selected: on,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VgSize.tapMin),
            child: Center(
              widthFactor: 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: 32),
                padding: EdgeInsetsDirectional.fromSTEB(
                  on ? VgSpace.s2 : VgSpace.s3,
                  VgSpace.s1,
                  VgSpace.s4,
                  VgSpace.s1,
                ),
                decoration: BoxDecoration(
                  color: on ? scheme.secondaryContainer : null,
                  border: on ? null : Border.all(color: scheme.outline),
                  borderRadius: shape,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (on) ...[
                      Icon(Symbols.check_rounded, size: 18, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: VgType.labelMd.copyWith(color: fg),
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

    return Wrap(
      spacing: VgSpace.s2,
      children: [for (final (value, label) in options) chip(value, label)],
    );
  }
}
