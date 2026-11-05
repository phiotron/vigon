import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_grid.dart';
import '../../ui/tokens.g.dart';

/// SCR-07: lưới đủ mọi danh mục chi mở từ ô ⋯. Bảng cao tối đa = màn hình −
/// thanh trạng thái − 40; nội dung cuộn dưới tiêu đề cố định.
Future<int?> showMoreCategoriesSheet(BuildContext context) {
  final media = MediaQuery.of(context);
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: media.size.height - media.padding.top - 40,
    ),
    builder: (context) => const CategoryGrid(type: CategoryType.expense),
  );
}

/// Chip tài khoản đang lọc (§10.1 #1, P2 — chưa có frame): hiện tên tài
/// khoản đang lọc ngay dưới đầu kỳ; nút ✕ bỏ lọc (về "Tất cả tài khoản").
class ActiveAccountChip extends ConsumerWidget {
  const ActiveAccountChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final id = ref.watch(accountFilterProvider);
    final accounts = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final account = accounts.where((a) => a.id == id).firstOrNull;
    if (account == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
      child: Center(
        child: InputChip(
          avatar: Icon(
            Symbols.account_balance_wallet_rounded,
            color: scheme.onSecondaryContainer,
          ),
          label: Text(
            '${l.account}: ${accountLabel(l, account)}',
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: scheme.secondaryContainer,
          labelStyle: TextStyle(color: scheme.onSecondaryContainer),
          side: BorderSide.none,
          deleteIcon: const Icon(Symbols.close_rounded, size: 18),
          deleteIconColor: scheme.onSecondaryContainer,
          deleteButtonTooltipMessage: l.allAccounts,
          onDeleted: () =>
              ref.read(accountFilterProvider.notifier).select(null),
        ),
      ),
    );
  }
}
