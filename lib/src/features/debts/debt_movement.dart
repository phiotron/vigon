import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import 'debt_detail.dart';
import 'debts_providers.dart';

/// Icon riêng của Debt movement trong Các khoản (AC-169).
const debtMovementIcon = Symbols.handshake_rounded;

/// Tên người của mỗi khoản nợ còn tồn tại, theo id — để gọi nhãn Debt
/// movement "Cho vay · An" (AC-169).
final debtPersonsProvider = Provider<Map<int, String>>(
  (ref) => {
    for (final v in ref.watch(debtsProvider).value ?? const [])
      v.debt.id: v.debt.person,
  },
);

/// Nhãn của Debt movement (AC-169, AC-170): "Cho vay · An", "Đi vay · Bình",
/// "Thu nợ · An", "Trả nợ · Bình"; khoản nợ đã xoá → "Khoản nợ đã xoá"
/// (AC-175).
String debtMovementLabel(
  AppLocalizations l,
  Entry e,
  Map<int, String> persons,
) {
  final person = e.debtId == null ? null : persons[e.debtId];
  final kind = e.debtKind;
  if (person == null || kind == null) return l.debtMovementOrphan;
  return switch (kind) {
    DebtMovementKind.lend => l.debtMovementLend(person),
    DebtMovementKind.borrow => l.debtMovementBorrow(person),
    DebtMovementKind.collect => l.debtMovementCollect(person),
    DebtMovementKind.repay => l.debtMovementRepay(person),
  };
}

/// Khoản thuộc một khoản nợ còn tồn tại (Debt movement hoặc khoản lãi):
/// chạm mở Chi tiết khoản nợ thay vì màn sửa khoản (AC-170). Debt movement
/// mồ côi mở màn sửa khoản để xoá (AC-175).
bool opensDebtDetail(Entry e) => e.debtId != null;

/// Mở màn của khoản [e] khi chạm trong danh sách: chuyển tiền → Chuyển tiền,
/// khoản thuộc khoản nợ → Chi tiết khoản nợ, còn lại → màn sửa khoản.
void openEntry(BuildContext context, Entry e) {
  if (e.type == EntryType.transfer) {
    context.push('/transfer/${e.id}');
  } else if (opensDebtDetail(e)) {
    showDebtDetail(context, e.debtId!);
  } else {
    context.push('/entry/${e.id}');
  }
}
