import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/balance_guard.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/dialog.dart';
import '../../ui/status.dart';
import '../../ui/tokens.g.dart';

/// Id các tài khoản vừa được tự bật "Cho phép số dư âm" khi nâng cấp
/// (AC-163); rỗng khi không có gì để báo.
final negativeNoticeProvider = StreamProvider<List<int>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.settings,
  )..where((s) => s.key.equals(negativeNoticeKey))).watchSingleOrNull().map(
    (row) => [for (final p in (row?.value ?? '').split(',')) ?int.tryParse(p)],
  );
});

/// Thông báo của "có thu mới có chi" ở màn chính (D-046): thanh "Bỏ qua N
/// khoản định kỳ vì Trip thiếu tiền" đóng được (AC-164), và hộp một lần "Đã
/// cho phép số dư âm cho: …" sau nâng cấp (AC-163).
class LedgerNotices extends ConsumerStatefulWidget {
  const LedgerNotices({super.key});

  @override
  ConsumerState<LedgerNotices> createState() => _LedgerNoticesState();
}

class _LedgerNoticesState extends ConsumerState<LedgerNotices> {
  bool _shown = false;

  Future<void> _showNegativeNotice(List<int> ids) async {
    if (_shown) return;
    _shown = true;
    final db = ref.read(databaseProvider);
    final accounts = await db.select(db.accounts).get();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final names = [
      for (final a in accounts)
        if (ids.contains(a.id)) accountLabel(l, a),
    ].join(', ');
    // Xoá trước khi hiện: báo đúng một lần kể cả khi app bị đóng giữa chừng.
    await (db.delete(
      db.settings,
    )..where((s) => s.key.equals(negativeNoticeKey))).go();
    if (!mounted || names.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => VgDialog(
        title: l.ledgerUpgradeTitle,
        body: l.ledgerUpgradeBody(names),
        icon: Symbols.credit_card_rounded,
        tone: VgDialogTone.neutral,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.ledgerOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(negativeNoticeProvider).value ?? const [];
    if (notice.isNotEmpty && !_shown) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showNegativeNotice(notice),
      );
    }
    final skipped = ref.watch(skippedOccurrencesProvider);
    if (skipped.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final names = {
      for (final s in skipped)
        if (accounts[s.accountId] case final a?) accountLabel(l, a),
    }.join(', ');
    final (bg, fg) = statusColors(context, StatusTone.warn);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s2),
      child: Material(
        key: const Key('skipped-recurring-bar'),
        color: bg,
        borderRadius: BorderRadius.circular(VgRadius.md),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: VgSpace.s3),
          child: Row(
            children: [
              Icon(Symbols.event_busy_rounded, color: fg, size: 20),
              const SizedBox(width: VgSpace.s2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: VgSpace.s2),
                  child: Text(
                    l.ledgerSkipped(skipped.length, names),
                    style: VgType.bodySm.copyWith(color: fg),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.ledgerDismiss,
                icon: Icon(Symbols.close_rounded, color: fg),
                onPressed: () =>
                    ref.read(skippedOccurrencesProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
