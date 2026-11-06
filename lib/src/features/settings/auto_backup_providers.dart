import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auto_backup_service.dart';
import '../../data/backup_folder_service.dart';
import '../../providers.dart';
import '../lock/app_lock.dart';
import '../reminder/reminder_providers.dart';
import 'auto_backup_scheduler.dart';

export 'auto_backup_scheduler.dart';

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

/// Lịch sao lưu theo giờ chọn (D-026): Android báo thức nền, iOS thông báo.
/// Test ghi đè bằng bản giả.
final autoBackupSchedulerProvider = Provider<AutoBackupScheduler>(
  (ref) => platformAutoBackupScheduler(),
);

/// Giữ lịch khớp cấu hình đã lưu: chạy khi mở app (đặt lại lịch nếu hệ thống
/// đã xóa, vd sau khi buộc dừng app) và mỗi khi bật/tắt, đổi giờ, đổi ngôn ngữ
/// (chữ thông báo iOS). `main.dart` giữ provider này sống.
final autoBackupScheduleSyncProvider = Provider<void>((ref) {
  final state = ref.watch(autoBackupStateProvider);
  final localeCode = ref.watch(localeCodeProvider);
  final scheduler = ref.watch(autoBackupSchedulerProvider);
  // iOS dùng chung plugin thông báo với nhắc ghi chép: chờ nó khởi tạo xong.
  final ready = scheduler.usesNotification
      ? ref.watch(reminderReadyProvider).hasValue
      : true;
  if (!state.hasValue || !localeCode.hasValue || !ready) return;
  final s = state.value!;
  if (!s.enabled) {
    unawaited(scheduler.cancel());
    return;
  }
  final l = reminderStrings(localeCode.value, ref.read(deviceLocaleProvider));
  unawaited(
    scheduler.schedule(
      s.time,
      title: l.appTitle,
      body: l.autoBackupNotificationBody,
    ),
  );
});
