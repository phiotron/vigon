import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/tokens.g.dart';

/// Nhập mã PIN 4 số bằng bàn phím của app; đủ 4 số thì gọi [onCompleted].
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.error,
    this.message,
  });

  final String title;
  final String? message;
  final String? error;

  /// Gọi khi đủ 4 số; xong thì ô nhập tự xóa để nhập lại nếu cần.
  final Future<void> Function(String pin) onCompleted;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  Future<void> _press(String key) async {
    if (_busy) return;
    if (key == '⌫') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) {
      _busy = true;
      await widget.onCompleted(_pin);
      _busy = false;
      if (mounted) setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Phím PIN (1.1, 8.1): bầu dục 88×64 nền `surface-container-high`; phím
    // xóa lùi không có nền, màu chữ phụ.
    Widget key(String k) => SizedBox(
      width: 88,
      height: VgSize.tapMain,
      child: k.isEmpty
          ? null
          : TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: k == '⌫' ? null : scheme.surfaceContainerHigh,
                foregroundColor: k == '⌫'
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
                textStyle: VgType.keyDigit,
                shape: const StadiumBorder(),
              ),
              onPressed: () => _press(k),
              child: k == '⌫'
                  ? Icon(
                      Symbols.backspace_rounded,
                      semanticLabel: l.keypadBackspace,
                    )
                  : Text(k, semanticsLabel: l.digit(k)),
            ),
    );
    Widget row(List<String> keys) => Padding(
      padding: const EdgeInsets.only(top: VgSpace.s3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: VgSpace.s6),
            key(keys[i]),
          ],
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s8,
              VgSpace.s2,
              VgSpace.s8,
              0,
            ),
            child: Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: VgSpace.s6),
        Semantics(
          liveRegion: true,
          label: l.pinProgress(_pin.length),
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: VgSpace.s4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? scheme.onSurface : null,
                    border: Border.all(
                      color: i < _pin.length
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Dòng lỗi cao cố định để bàn phím không nhảy (S01).
        Container(
          height: 24,
          margin: const EdgeInsets.only(top: VgSpace.s3),
          alignment: Alignment.center,
          child: widget.error == null
              ? null
              : Semantics(
                  liveRegion: true,
                  child: Text(
                    widget.error!,
                    style: VgType.bodySm.copyWith(color: scheme.error),
                  ),
                ),
        ),
        row(const ['1', '2', '3']),
        row(const ['4', '5', '6']),
        row(const ['7', '8', '9']),
        row(const ['', '0', '⌫']),
      ],
    );
  }
}
