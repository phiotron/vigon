import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/data/auto_backup_background.dart';
import 'src/data/database.dart';
import 'src/features/reminder/reminder_providers.dart';
import 'src/features/settings/auto_backup_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Chỉ màn hình dọc (SPEC mục 5); Android còn khóa trong manifest.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Font đóng trong app phải hiện giấy phép ở màn Giấy phép nguồn mở (AC-41).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Be Vietnam Pro',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final container = ProviderContainer();
  runAutoBackupOnOpen(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const VigonApp()),
  );
}

/// Sao lưu tự động theo giờ chọn (F-24, D-026), phần trong app:
/// - giữ lịch (Android báo thức nền, iOS thông báo) khớp cấu hình đã lưu;
/// - đường BÙ khi lỡ giờ: MỞ app (vài giây sau khung hình đầu, để không giành
///   việc với lúc khởi động) và mỗi khi QUAY LẠI app, cả hai nền tảng; Android
///   còn bù lúc ra nền (`AppLifecycleWatcher` → `maybeRunDaily`);
/// - iOS: chạm thông báo "Đến giờ sao lưu" cũng chạy đường bù.
/// Quy tắc "mỗi mốc giờ tối đa một lần, chỉ khi dữ liệu đổi" nằm trong
/// `AutoBackupService.maybeRunIfDue`; nó không ném lỗi.
void runAutoBackupOnOpen(
  ProviderContainer container, {
  Duration delay = const Duration(seconds: 3),
}) {
  void run() =>
      unawaited(container.read(autoBackupServiceProvider).maybeRunOnOpen());
  container.listen(autoBackupScheduleSyncProvider, (_, _) {});
  container.listen(reminderTapProvider, (_, next) {
    if (next?.payload == autoBackupPayload) run();
  });
  WidgetsBinding.instance.addPostFrameCallback((_) => Timer(delay, run));
  // Sống cùng app; không cần gỡ.
  AppLifecycleListener(onResume: run);
}

/// Điểm vào Dart khi app ĐÓNG (Android, D-026): `BackupJobService.kt` dựng một
/// FlutterEngine không giao diện và chạy hàm này lúc báo thức giờ sao lưu nổ.
/// Xong (dù được hay lỗi) thì báo `done` để Kotlin kết thúc việc và hủy engine.
@pragma('vm:entry-point')
Future<void> autoBackupBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final result = await runScheduledAutoBackup(openDatabase: AppDatabase.new);
  try {
    await const MethodChannel(backupJobChannel)
        .invokeMethod<void>('done', result?.name);
  } catch (_) {
    // Kotlin tự kết thúc sau thời hạn.
  }
}

/// Kênh báo xong của `BackupJobService.kt`.
const backupJobChannel = 'vigon/backup_job';
