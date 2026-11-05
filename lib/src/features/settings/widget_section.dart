import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../widget/widget_sync.dart';
import 'settings_lead.dart';

/// Công tắc "Hiện số tiền trên widget" trong nhóm Bảo mật (AC-64).
class WidgetAmountsSwitch extends ConsumerWidget {
  const WidgetAmountsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SwitchListTile(
      secondary: const SettingsLead(Symbols.widgets_rounded),
      title: Text(l.widgetShowAmounts),
      subtitle: Text(l.widgetShowAmountsNote),
      value: ref.watch(widgetShowAmountsProvider).value ?? false,
      onChanged: ref.read(settingsRepositoryProvider).setWidgetShowAmounts,
    );
  }
}
