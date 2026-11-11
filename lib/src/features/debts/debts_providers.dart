import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart' show DebtDirection;
import '../../data/debt_repository.dart';
import '../../data/money_sum.dart';
import '../../providers.dart';

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) =>
      DebtRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

/// Mọi khoản nợ (mới nhất trước) kèm các lần trả — F-34.
final debtsProvider = StreamProvider<List<DebtView>>(
  (ref) => ref.watch(debtRepositoryProvider).watchAll(),
);

/// Tổng "Còn lại" (gốc còn lại + lãi tới hôm nay chưa trả, AC-174) của các
/// khoản nợ chưa xong theo chiều, gom theo tiền tệ khoản nợ (AC-148). Màn
/// Khoản nợ, thẻ Nợ ở Tổng quan dùng số này; quy sang Tiền tệ chính bằng
/// `MoneyBag.convertTo`.
final debtRemainingByDirectionProvider =
    Provider<Map<DebtDirection, MoneyBag>>((ref) {
      final totals = {
        DebtDirection.lent: MoneyBag(),
        DebtDirection.borrowed: MoneyBag(),
      };
      for (final v in ref.watch(debtsProvider).value ?? const <DebtView>[]) {
        totals[v.debt.direction]!.add(v.debt.currency, v.remaining());
      }
      return totals;
    });
