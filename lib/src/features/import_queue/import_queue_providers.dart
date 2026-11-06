import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/import_repositories.dart';
import '../../import/mb/mb_import_service.dart';
import '../../providers.dart';
import 'import_queue_actions.dart';

final importQueueRepositoryProvider = Provider<ImportQueueRepository>(
  (ref) => ImportQueueRepository(ref.watch(databaseProvider)),
);

final payeeSuggestionRepositoryProvider = Provider<PayeeSuggestionRepository>(
  (ref) => PayeeSuggestionRepository(ref.watch(databaseProvider)),
);

final importQueueActionsProvider = Provider<ImportQueueActions>(
  (ref) => ImportQueueActions(ref.watch(databaseProvider)),
);

/// Luồng nhập email MB (ghép, thẻ Account tự tạo) của M1.
final mbImportServiceProvider = Provider<MbImportService>(
  (ref) => MbImportService(ref.watch(databaseProvider)),
);

/// Mọi mục hàng đợi, mới nhất trước (AC-95).
final importQueueProvider = StreamProvider<List<ImportQueueItem>>(
  (ref) => ref.watch(importQueueRepositoryProvider).watchAll(),
);

/// Số mục đang chờ: "N khoản chờ chọn danh mục" (AC-95).
final importQueueCountProvider = StreamProvider<int>(
  (ref) => ref.watch(importQueueRepositoryProvider).watchCount(),
);

/// "Gợi ý đã nhớ" (AC-97).
final payeeSuggestionsProvider = StreamProvider<List<PayeeSuggestion>>(
  (ref) => ref.watch(payeeSuggestionRepositoryProvider).watchAll(),
);

/// Id các Account tự tạo còn thẻ "Gắn vào tài khoản có sẵn" (AC-89).
final autoAccountNoticesProvider = StreamProvider<List<int>>(
  (ref) => ref.watch(mbImportServiceProvider).watchAutoAccountNotices(),
);
