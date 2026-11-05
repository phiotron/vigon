import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import 'accounts_screen.dart' show accountIcon;

/// Nút Ẩn và Xóa trong bảng sửa tài khoản (AC-44, AC-45, AC-46). Xong thì đóng bảng.
class AccountRemoveSection extends ConsumerWidget {
  const AccountRemoveSection({super.key, required this.account});

  final Account account;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    await ref.read(accountRepositoryProvider).archive(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l.deleteAccount,
      body: l.deleteAccountConfirm(accountLabel(l, account)),
      action: l.delete,
      icon: Symbols.delete_rounded,
      style: ConfirmStyle.danger,
    );
    if (!ok || !context.mounted) return;
    await ref.read(accountRepositoryProvider).delete(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final visible = ref.watch(accountsProvider).value ?? const <Account>[];
    final inUse = ref.watch(accountInUseProvider(account.id)).value;
    final hint = VgType.bodyMd.copyWith(
      fontFamily: vgFontFamily,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    // Lề ngang theo bảng sửa tài khoản (6.4): 24.
    const pad = EdgeInsets.fromLTRB(VgSpace.s6, VgSpace.s2, VgSpace.s6, 0);
    if (visible.length <= 1) {
      return Padding(
        padding: pad,
        child: Text(l.accountLastOneHint, style: hint),
      );
    }
    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: VgSpace.s6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
            ),
            icon: const Icon(Symbols.visibility_off_rounded),
            label: Text(l.archiveAccount),
            onPressed: () => _archive(context, ref),
          ),
          if (inUse == false)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
              ),
              icon: const Icon(Symbols.delete_rounded),
              label: Text(l.deleteAccount),
              onPressed: () => _delete(context, ref),
            )
          else if (inUse == true)
            Padding(
              padding: const EdgeInsets.only(top: VgSpace.s2),
              child: Text(l.accountInUseHint, style: hint),
            ),
        ],
      ),
    );
  }
}

/// Mục "Tài khoản đã ẩn" cuối màn Tài khoản: thu gọn, chạm một tài khoản để
/// hiện lại (AC-47). Không vẽ gì khi chưa có tài khoản nào bị ẩn.
class ArchivedAccountsSection extends ConsumerWidget {
  const ArchivedAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final archived =
        ref.watch(archivedAccountsProvider).value ?? const <Account>[];
    if (archived.isEmpty) return const SizedBox.shrink();
    final balances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    return ExpansionTile(
      leading: const SizedBox(
        width: 40,
        child: Center(child: Icon(Symbols.visibility_off_rounded)),
      ),
      title: Text(l.archivedAccounts),
      children: [
        for (final a in archived)
          ListTile(
            leading: SizedBox(
              width: 40,
              child: Center(child: Icon(accountIcon(a))),
            ),
            title: Text(accountLabel(l, a)),
            subtitle: Text(
              money(context, currency, balances[a.id] ?? a.initialBalance),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(accountRepositoryProvider).unarchive(a.id),
              child: Text(l.unarchiveAccount),
            ),
            onTap: () => ref.read(accountRepositoryProvider).unarchive(a.id),
          ),
      ],
    );
  }
}
