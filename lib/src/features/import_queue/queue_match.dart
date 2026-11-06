import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';
import '../entry/entry_time.dart';
import 'import_queue_providers.dart';

/// Kết quả một lần ghép ngược (AC-94): mục hàng đợi vừa gắn vào khoản ghi tay.
class QueueMatch {
  QueueMatch._(this._message, this._undoLabel, this._undo);

  final String _message;
  final String _undoLabel;
  final Future<void> Function() _undo;

  /// Thanh "Đã ghép với email MB 12:02 · Hoàn tác"; Hoàn tác trả mục về hàng
  /// đợi. Gọi sau khi đóng màn Nhập khoản (thanh nằm ở khung gốc).
  void showUndo() =>
      showUndoSnackBar(message: _message, undoLabel: _undoLabel, onUndo: _undo);
}

/// Sau khi LƯU một khoản ghi tay (hoặc chuyển tiền đi): nếu hàng đợi có mục
/// thoả luật ghép AC-91 với khoản [entryId] thì ghép luôn (mục rời hàng đợi,
/// khoản chỉ được gắn nguồn + số tham chiếu) và trả về [QueueMatch] để hiện
/// thanh Hoàn tác (AC-94). Không có mục khớp thì trả về null, không đổi gì.
Future<QueueMatch?> matchQueueFor(
  WidgetRef ref,
  BuildContext context,
  int entryId,
) async {
  final entries = ref.read(entryRepositoryProvider);
  final service = ref.read(mbImportServiceProvider);
  final entry = await entries.find(entryId);
  if (entry == null) return null;
  final item = await service.findQueueMatchFor(entry);
  if (item == null) return null;
  final removed = await service.attachQueueItem(item, entryId);
  if (removed == null || !context.mounted) return null;
  final l = AppLocalizations.of(context);
  return QueueMatch._(
    l.queueMatched(formatTimeKey(context, removed.time)),
    l.undo,
    () => service.undoAttach(removed, entryId),
  );
}
