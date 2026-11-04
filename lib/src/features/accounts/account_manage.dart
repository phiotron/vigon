import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';

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
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.deleteAccount),
            content: Text(l.deleteAccountConfirm(accountLabel(l, account))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !context.mounted) return;
    await ref.read(accountRepositoryProvider).delete(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final visible = ref.watch(accountsProvider).value ?? const <Account>[];
    final inUse = ref.watch(accountInUseProvider(account.id)).value;
    final hint = Theme.of(context).textTheme.bodyMedium;
    if (visible.length <= 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l.accountLastOneHint, style: hint),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_off_outlined),
          label: Text(l.archiveAccount),
          onPressed: () => _archive(context, ref),
        ),
        if (inUse == false)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text(l.deleteAccount),
            onPressed: () => _delete(context, ref),
          )
        else if (inUse == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.accountInUseHint, style: hint),
          ),
      ],
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
      leading: const Icon(Icons.visibility_off_outlined),
      title: Text(l.archivedAccounts),
      children: [
        for (final a in archived)
          ListTile(
            title: Text(accountLabel(l, a)),
            subtitle: Text(
              money(context, currency, balances[a.id] ?? a.initialBalance),
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
