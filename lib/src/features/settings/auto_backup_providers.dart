import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auto_backup_service.dart';
import '../../data/backup_folder_service.dart';
import '../../providers.dart';
import '../lock/app_lock.dart';

/// Kênh ghi file vào thư mục đã chọn; test ghi đè bằng bản giả.
final backupFolderServiceProvider = Provider<BackupFolderService>(
  (ref) => const BackupFolderService(),
);

final autoBackupServiceProvider = Provider<AutoBackupService>(
  (ref) => AutoBackupService(
    db: ref.watch(databaseProvider),
    folder: ref.watch(backupFolderServiceProvider),
    secrets: ref.watch(secretStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Cấu hình và kết quả gần nhất cho mục "Sao lưu tự động"; làm mới bằng
/// `ref.invalidate` sau mỗi thao tác.
final autoBackupStateProvider = FutureProvider<AutoBackupState>(
  (ref) => ref.watch(autoBackupServiceProvider).state(),
);

/// "Sao lưu ngay" đang chạy từ Cài đặt (SCR-31 running): nút hiện vòng quay
/// và bỏ qua chạm cho tới khi xong.
class AutoBackupRunning extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final autoBackupRunningProvider = NotifierProvider<AutoBackupRunning, bool>(
  AutoBackupRunning.new,
);
