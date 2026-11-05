import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/settings_rows.dart';
import '../widget/widget_sync.dart';

/// Công tắc "Hiện số tiền trên widget" trong nhóm Bảo mật (AC-64, SCR-12).
/// Khi khóa PIN đang bật, công tắc vẫn bấm được nhưng widget luôn ẩn số, nên
/// có nhãn "Đã khóa bằng PIN" (A08, §10.1 #11).
class WidgetAmountsSwitch extends ConsumerWidget {
  const WidgetAmountsSwitch({super.key, this.pinEnabled = false});

  final bool pinEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SettingsSwitchRow(
      icon: Symbols.widgets_rounded,
      title: l.widgetShowAmounts,
      subtitle: l.widgetShowAmountsNote,
      value: ref.watch(widgetShowAmountsProvider).value ?? false,
      onChanged: ref.read(settingsRepositoryProvider).setWidgetShowAmounts,
      footer: pinEnabled
          ? StatusPill(icon: Symbols.lock_rounded, label: l.widgetLockedByPin)
          : null,
    );
  }
}
