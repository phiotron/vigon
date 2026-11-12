import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/balance_guard.dart';
import '../../l10n_names.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import '../accounts/accounts_screen.dart' show showAccountEditor;
import '../categories/sheet_footer.dart';

/// Lưu mục hàng đợi như lựa chọn ban đầu; trả về hàm Hoàn tác, hoặc null
/// nếu mục không còn trong hàng đợi.
typedef TopUpConfirm = Future<Future<void> Function()?> Function();

/// Bảng **Bù tiền** (Top-up sheet, D-046, AC-165): mục hàng đợi email mà tài
/// khoản liên kết thiếu tiền ở lại hàng đợi; bảng nói "MB …1234 thiếu
/// 200.000 ₫" và cho ba cách bù — ghi khoản thu vào tài khoản đó (số gợi ý =
/// số thiếu), chuyển tiền vào, sửa số dư ban đầu. Sau mỗi cách, [check] kiểm
/// lại; đủ tiền thì [confirm] lưu mục như lựa chọn ban đầu, đóng bảng và hiện
/// thanh Hoàn tác. Hủy → mục vẫn chờ. Trả về true khi đã lưu mục.
Future<bool> showTopUpSheet(
  BuildContext context,
  WidgetRef ref,
  Shortfall shortfall, {
  required TopUpConfirm confirm,
  required Future<Shortfall?> Function() check,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _TopUpSheet(shortfall: shortfall, confirm: confirm, check: check),
    ) ??
    false;

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet({
    required this.shortfall,
    required this.confirm,
    required this.check,
  });

  final Shortfall shortfall;
  final TopUpConfirm confirm;
  final Future<Shortfall?> Function() check;

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  late Shortfall _short = widget.shortfall;
  bool _busy = false;

  /// Chạy một cách bù rồi kiểm lại; đủ thì lưu mục.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
      final left = await widget.check();
      if (!mounted) return;
      if (left != null) {
        setState(() => _short = left);
        return;
      }
      final l = AppLocalizations.of(context);
      final undo = await widget.confirm();
      if (!mounted) return;
      Navigator.pop(context, true);
      if (undo != null) {
        showUndoSnackBar(
          message: l.topUpSaved,
          undoLabel: l.undo,
          onUndo: undo,
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final account = _short.account;
    final name = accountLabel(l, account);
    final missing = _short.missing;
    Widget option(IconData icon, String label, Future<void> Function() go) =>
        ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => _run(go),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(l.topUpTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s2,
              VgSpace.s4,
              VgSpace.s1,
            ),
            child: Text(
              l.topUpShort(
                name,
                moneyOneLine(context, ref, missing, account.currency),
              ),
              key: const Key('top-up-short'),
              style: VgType.titleSm.copyWith(color: scheme.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              0,
              VgSpace.s4,
              VgSpace.s2,
            ),
            child: Text(
              l.topUpBody,
              style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          option(
            Symbols.add_circle_rounded,
            l.topUpIncome(name),
            () => context.push(
              '/entry/new?type=income&account=${account.id}'
              '&amount=$missing&currency=${account.currency}',
            ),
          ),
          option(
            Symbols.swap_horiz_rounded,
            l.topUpTransfer(name),
            () => context.push('/transfer?to=${account.id}'),
          ),
          option(
            Symbols.edit_rounded,
            l.topUpEditInitial,
            () => showAccountEditor(context, account: account),
          ),
          SheetFooter(
            border: false,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
