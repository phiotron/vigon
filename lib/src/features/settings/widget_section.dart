import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../widget/widget_sync.dart';

/// Công tắc "Hiện số tiền trên widget" trong nhóm Bảo mật (AC-64).
class WidgetAmountsSwitch extends ConsumerWidget {
  const WidgetAmountsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SwitchListTile(
      secondary: const Icon(Icons.widgets_outlined),
      title: Text(l.widgetShowAmounts),
      subtitle: Text(l.widgetShowAmountsNote),
      value: ref.watch(widgetShowAmountsProvider).value ?? false,
      onChanged: ref.read(settingsRepositoryProvider).setWidgetShowAmounts,
    );
  }
}
