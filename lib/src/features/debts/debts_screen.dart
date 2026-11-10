import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/debt_repository.dart';
import '../../data/money_sum.dart';
import '../../data/money.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/money_lines.dart';
import '../../ui/tokens.g.dart';
import 'debt_detail.dart';
import 'debt_editor.dart';
import 'debts_providers.dart';

/// Khoản nợ chưa xong mà đã quá hạn (AC-105): hạn trước hôm nay.
bool isDebtOverdue(DebtView v, DateTime today, int digits) {
  final due = v.debt.dueDate;
  return due != null &&
      !v.isSettled(digits) &&
      parseDateKey(due).isBefore(today);
}

/// Màn Khoản nợ (F-34, AC-104..AC-106): sổ ghi nhớ hai nhóm "Người khác nợ
/// bạn" / "Bạn nợ người khác" kèm tổng còn lại, mục "Đã xong" thu gọn. Không
/// tạo khoản, không đổi số dư. Dựng tạm bằng component Hi-Fi hiện có.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final debts = ref.watch(debtsProvider).value ?? const <DebtView>[];
    final currency = ref.watch(currencyProvider).value ?? 'USD';
    final digits = currencyDecimalDigits(currency);
    final today = ref.watch(todayProvider);

    final open = [
      for (final v in debts)
        if (!v.isSettled(digits)) v,
    ];
    final done = [
      for (final v in debts)
        if (v.isSettled(digits)) v,
    ];
    final lent = [
      for (final v in open)
        if (v.debt.direction == DebtDirection.lent) v,
    ];
    final borrowed = [
      for (final v in open)
        if (v.debt.direction == DebtDirection.borrowed) v,
    ];

    // Cộng số còn lại theo từng tiền tệ rồi quy đổi một lần (AC-148).
    final service = ref.watch(currencyServiceProvider).value;
    int total(List<DebtView> list) {
      final bag = MoneyBag();
      for (final v in list) {
        bag.add(v.debt.currency, v.remaining());
      }
      return service == null
          ? bag.parts[currency] ?? 0
          : bag.convertTo(service, currency) ?? 0;
    }

    Widget group(String title, List<DebtView> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(
          title: title,
          total: l.debtGroupTotal(money(context, currency, total(list))),
        ),
        for (final v in list) _DebtTile(view: v, today: today, digits: digits),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.debts)),
      body: debts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.debtsEmpty,
                  textAlign: TextAlign.center,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                VgHint(
                  l.debtsNote,
                  padding: const EdgeInsets.fromLTRB(
                    VgSpace.s4,
                    VgSpace.s2,
                    VgSpace.s4,
                    0,
                  ),
                ),
                if (lent.isNotEmpty) group(l.debtGroupLent, lent),
                if (borrowed.isNotEmpty) group(l.debtGroupBorrowed, borrowed),
                if (done.isNotEmpty) ...[
                  InkWell(
                    onTap: () => setState(() => _showDone = !_showDone),
                    child: Semantics(
                      expanded: _showDone,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: VgSize.tapMin,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VgSpace.s4,
                            VgSpace.s2,
                            VgSpace.s4,
                            VgSpace.s2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.debtDoneSection(done.length),
                                  style: VgType.titleSm.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                _showDone
                                    ? Symbols.expand_less_rounded
                                    : Symbols.expand_more_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showDone)
                    for (final v in done)
                      _DebtTile(view: v, today: today, digits: digits),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDebtEditor(context),
        icon: const Icon(Symbols.add_rounded),
        label: Text(l.debtAdd, style: VgType.labelLg),
      ),
    );
  }
}

/// Tiêu đề nhóm: tên nhóm và tổng còn lại; chữ lớn thì tổng xuống dòng.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.total});

  final String title;
  final String total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleText = Semantics(
      header: true,
      child: Text(title, style: VgType.titleSm.copyWith(color: scheme.primary)),
    );
    final totalText = Text(
      total,
      style: VgType.bodyMd.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s4,
        VgSpace.s1,
      ),
      child: isLargeText(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleText, totalText],
            )
          : Row(
              children: [
                Expanded(child: titleText),
                totalText,
              ],
            ),
    );
  }
}

/// Một khoản nợ: người, trạng thái (Quá hạn / Hạn …/ Đã xong), còn lại; chạm
/// mở chi tiết (các lần trả, sửa, xoá).
class _DebtTile extends ConsumerWidget {
  const _DebtTile({
    required this.view,
    required this.today,
    required this.digits,
  });

  final DebtView view;
  final DateTime today;
  final int digits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final d = view.debt;
    final settled = view.isSettled();
    final overdue = isDebtOverdue(view, today, digits);
    // Số theo tiền tệ khoản nợ, tính thẳng từ số gốc (AC-148).
    final originalAmount = view.total;
    final ownRemaining = view.remaining();
    final ownPaid = view.paid();
    final lines = <Widget>[
      if (settled)
        Row(
          children: [
            Icon(Symbols.check_circle_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: VgSpace.s1),
            Expanded(
              child: Text(
                l.debtDone,
                style: VgType.bodySm.copyWith(color: scheme.primary),
              ),
            ),
          ],
        )
      else if (overdue)
        // Quá hạn bằng chữ + icon, không chỉ màu (AC-105).
        Row(
          children: [
            Icon(
              Symbols.warning_rounded,
              size: 16,
              fill: 1,
              color: scheme.error,
            ),
            const SizedBox(width: VgSpace.s1),
            Expanded(
              child: Text(
                '${l.debtOverdue} · ${l.debtDueOn(shortDate(context, parseDateKey(d.dueDate!)))}',
                style: VgType.bodySm.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        )
      else if (d.dueDate != null)
        Text(
          l.debtDueOn(shortDate(context, parseDateKey(d.dueDate!))),
          style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
      if (view.payments.isNotEmpty)
        Text(
          l.debtPaidOf(
            money(context, d.currency, ownPaid),
            money(context, d.currency, originalAmount),
          ),
          style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
        ),
    ];
    final amount = MoneyLines(
      amount: settled ? originalAmount : ownRemaining,
      currency: d.currency,
      style: VgType.bodyMd.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      secondaryStyle: VgType.bodySm,
      crossAxisAlignment: CrossAxisAlignment.end,
      textAlign: TextAlign.end,
    );
    final large = isLargeText(context);
    return ListTile(
      minTileHeight: VgSize.rowTwoLine,
      contentPadding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
      leading: SizedBox(
        width: 40,
        child: Center(
          child: Icon(
            d.direction == DebtDirection.lent
                ? Symbols.arrow_outward_rounded
                : Symbols.arrow_downward_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(d.person, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [if (large) amount, ...lines],
      ),
      trailing: large ? null : amount,
      onTap: () => showDebtDetail(context, d.id),
    );
  }
}
