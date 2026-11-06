import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/savings_repository.dart';
import '../../providers.dart';

final savingsRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => SavingsGoalRepository(ref.watch(databaseProvider)),
);

/// Mọi mục tiêu tiết kiệm (cũ trước) — F-33.
final savingsGoalsProvider = StreamProvider<List<SavingsGoal>>(
  (ref) => ref.watch(savingsRepositoryProvider).watchAll(),
);
