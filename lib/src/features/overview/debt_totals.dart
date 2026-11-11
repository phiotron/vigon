import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/debt_repository.dart';
import '../../data/money_sum.dart';
import '../debts/debts_providers.dart';
import '../stats/stats_providers.dart';

/// Tổng nợ cho thẻ "Nợ" của Tổng quan, theo Tiền tệ chính. Không thuộc Tổng
/// số dư (khoản nợ không đụng số dư tài khoản, AC-104).
class DebtTotals {
  const DebtTotals({
    required this.owedToYou,
    required this.youOwe,
    required this.openCount,
  });

  /// Người khác nợ bạn (khoản "Tôi cho vay" chưa xong).
  final int owedToYou;

  /// Bạn nợ (khoản "Tôi đi vay" chưa xong).
  final int youOwe;

  /// Số khoản nợ chưa xong.
  final int openCount;
}

/// Số còn lại của các khoản nợ chưa xong, gom theo tiền tệ gốc từng chiều
/// (D-042, AC-148).
({MoneyBag owedToYou, MoneyBag youOwe, int openCount}) debtBagsOf(
  Iterable<DebtView> debts,
) {
  final lent = MoneyBag(), borrowed = MoneyBag();
  var open = 0;
  for (final v in debts) {
    final left = v.remaining();
    if (left == 0) continue;
    open++;
    (v.debt.direction == DebtDirection.lent ? lent : borrowed).add(
      v.debt.currency,
      left,
    );
  }
  return (owedToYou: lent, youOwe: borrowed, openCount: open);
}

/// Tổng nợ của thẻ "Nợ" (đợt 5). Đây là chỗ DUY NHẤT Tổng quan lấy số nợ:
/// phiên C1 sẽ đổi cách tính thành gốc + lãi tới hôm nay mà không phải sửa
/// màn.
final debtTotalsProvider = Provider<AsyncValue<DebtTotals>>((ref) {
  final convert = ref.watch(moneyConvertProvider);
  final debts = ref.watch(debtsProvider);
  if (debts.hasError) return AsyncError(debts.error!, StackTrace.current);
  if (!debts.hasValue || convert == null) return const AsyncLoading();
  final bags = debtBagsOf(debts.requireValue);
  return AsyncData(
    DebtTotals(
      owedToYou: convert(bags.owedToYou),
      youOwe: convert(bags.youOwe),
      openCount: bags.openCount,
    ),
  );
});
