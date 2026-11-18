import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../data/database.dart';
import '../l10n_names.dart';
import '../providers.dart';

/// Nút lọc tài khoản trên thanh trên của Các khoản, Thống kê và Lịch: cùng bộ
/// lọc với màn chính (AC-20) nên vào màn nào cũng đang đúng tài khoản đang
/// chọn ở nhà, và đổi được ngay tại màn đó. Chỉ hiện khi có từ hai tài khoản.
class AccountFilterButton extends ConsumerWidget {
  const AccountFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    if (accounts.length < 2) return const SizedBox.shrink();
    final selected = ref.watch(accountFilterProvider);
    final current = accounts.where((a) => a.id == selected).firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    PopupMenuItem<int> item(int value, String label, bool on) =>
        PopupMenuItem<int>(
          value: value,
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (on) Icon(Symbols.check_rounded, color: scheme.primary),
            ],
          ),
        );
    return PopupMenuButton<int>(
      icon: Icon(
        Symbols.account_balance_wallet_rounded,
        fill: current == null ? 0 : 1,
      ),
      tooltip: current == null
          ? '${l.account}: ${l.allAccounts}'
          : '${l.account}: ${accountLabel(l, current)}',
      position: PopupMenuPosition.under,
      onSelected: (id) =>
          ref.read(accountFilterProvider.notifier).select(id == -1 ? null : id),
      itemBuilder: (context) => [
        item(-1, l.allAccounts, current == null),
        for (final a in accounts)
          item(a.id, accountLabel(l, a), current?.id == a.id),
      ],
    );
  }
}
