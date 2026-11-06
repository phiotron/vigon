import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/debt_repository.dart';
import '../../providers.dart';

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DebtRepository(ref.watch(databaseProvider)),
);

/// Mọi khoản nợ (mới nhất trước) kèm các lần trả — F-34.
final debtsProvider = StreamProvider<List<DebtView>>(
  (ref) => ref.watch(debtRepositoryProvider).watchAll(),
);
