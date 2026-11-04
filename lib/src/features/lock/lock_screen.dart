import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../settings/data_actions.dart';
import 'app_lock.dart';
import 'pin_pad.dart';

/// Màn khóa phủ lên toàn app khi bật PIN (AC-32, AC-34). Có Navigator riêng
/// vì nằm ngoài Navigator của router.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.checking});

  final bool checking;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surface;
    if (checking) {
      return ColoredBox(color: background, child: const SizedBox.expand());
    }
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const _LockBody()),
    );
  }
}

class _LockBody extends ConsumerStatefulWidget {
  const _LockBody();

  @override
  ConsumerState<_LockBody> createState() => _LockBodyState();
}

class _LockBodyState extends ConsumerState<_LockBody> {
  String? _error;

  Future<void> _forgot() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.forgotPin),
        content: Text(l.forgotPinBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteAll),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (await deleteEverything(context, ref)) {
      ref.read(lockProvider.notifier).unlockAfterReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.lock_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  PinPad(
                    title: l.enterPin,
                    error: _error,
                    onCompleted: (pin) async {
                      final ok = await ref
                          .read(lockProvider.notifier)
                          .unlock(pin);
                      if (!ok && mounted) setState(() => _error = l.wrongPin);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _forgot, child: Text(l.forgotPin)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
