import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

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
    Widget key(String k, {String? label}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: k.isEmpty
            ? const SizedBox(height: 64)
            : TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  backgroundColor: scheme.surfaceContainerHighest,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _press(k),
                child: Text(
                  k,
                  semanticsLabel: label ?? l.digit(k),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (widget.message != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(widget.message!, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          label: l.pinProgress(_pin.length),
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? scheme.primary : null,
                    border: Border.all(color: scheme.outline, width: 2),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: widget.error == null
              ? null
              : Text(widget.error!, style: TextStyle(color: scheme.error)),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final k in row) key(k)]),
        Row(
          children: [
            key(''),
            key('0'),
            key('⌫', label: l.keypadBackspace),
          ],
        ),
      ],
    );
  }
}
