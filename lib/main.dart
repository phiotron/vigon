import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/data/auto_backup_service.dart';
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
  if (AutoBackupService.runsOnOpen) runAutoBackupOnOpen(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const VigonApp()),
  );
}

/// Sao lưu tự động trên iOS (F-24, D-022): iOS không cho app chạy theo giờ và
/// có thể treo app ngay khi ra nền, nên chạy khi MỞ app (vài giây sau khung hình
/// đầu, để không giành việc với lúc khởi động) và mỗi khi QUAY LẠI app. Quy tắc
/// "tối đa một lần mỗi ngày, chỉ khi dữ liệu đổi" nằm trong
/// [AutoBackupService.maybeRunOnOpen]; nó không ném lỗi.
void runAutoBackupOnOpen(
  ProviderContainer container, {
  Duration delay = const Duration(seconds: 3),
}) {
  void run() =>
      unawaited(container.read(autoBackupServiceProvider).maybeRunOnOpen());
  WidgetsBinding.instance.addPostFrameCallback((_) => Timer(delay, run));
  // Sống cùng app; không cần gỡ.
  AppLifecycleListener(onResume: run);
}
