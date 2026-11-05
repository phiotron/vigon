import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/device_backup_exclusion.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';

/// Loại cơ sở dữ liệu khỏi sao lưu iCloud/máy tính trên iOS (người dùng quyết
/// 2026-11-05, cho giống Android `allowBackup="false"`).
///
/// Ở đây chỉ kiểm phần Dart gọi kênh (kênh giả). Phần Swift đặt cờ thật được
/// CI iOS kiểm trên simulator (dòng log `VigonBackupExclusion`); việc iCloud
/// thật sự bỏ file khi sao lưu/khôi phục CHỈ kiểm được trên iPhone thật.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DeviceBackupExclusion.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final dir = Platform.isWindows ? r'C:\docs' : '/docs';
  final sep = Platform.pathSeparator;
  late List<MethodCall> calls;
  late List<String> logs;

  setUp(() {
    calls = [];
    logs = [];
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void mockChannel(Object? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return handler(call);
      });

  DeviceBackupExclusion exclusion({bool ios = true}) => DeviceBackupExclusion(
    documentsDirectory: () async => dir,
    isIOS: () => ios,
    log: logs.add,
  );

  test('đường dẫn: thư mục chứa, file chính và các file kèm của SQLite', () {
    expect(DeviceBackupExclusion.pathsFor(dir), [
      dir,
      '$dir${sep}vigon.sqlite',
      '$dir${sep}vigon.sqlite-wal',
      '$dir${sep}vigon.sqlite-shm',
      '$dir${sep}vigon.sqlite-journal',
    ]);
  });

  test('iOS: gọi excludeFromBackup với đủ đường dẫn, trả số mục', () async {
    mockChannel((_) => 3);
    expect(await exclusion().excludeDatabase(), 3);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'excludeFromBackup');
    expect(calls.single.arguments, {
      'paths': DeviceBackupExclusion.pathsFor(dir),
    });
  });

  test('không phải iOS (Android): không gọi kênh', () async {
    mockChannel((_) => 3);
    expect(await exclusion(ios: false).excludeDatabase(), 0);
    expect(calls, isEmpty);
  });

  test('lỗi phía iOS: không ném, ghi log, trả 0', () async {
    mockChannel((_) => throw PlatformException(code: 'bad_args'));
    expect(await exclusion().excludeDatabase(), 0);
    expect(logs.single, contains('backup exclusion failed'));
  });

  test('chưa có kênh (MissingPluginException): không ném', () async {
    // Không đặt handler giả → kênh không có phía nền tảng.
    expect(await exclusion().excludeDatabase(), 0);
    expect(logs.single, contains('backup exclusion failed'));
  });

  test('không lấy được thư mục: không ném, không gọi kênh', () async {
    mockChannel((_) => 3);
    final broken = DeviceBackupExclusion(
      documentsDirectory: () async => throw const FileSystemException('x'),
      isIOS: () => true,
      log: logs.add,
    );
    expect(await broken.excludeDatabase(), 0);
    expect(calls, isEmpty);
  });

  group('AppDatabase gọi sau khi mở', () {
    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    test('mỗi lần mở gọi afterOpen một lần', () async {
      var count = 0;
      final db = AppDatabase(NativeDatabase.memory(), () async => count++);
      addTearDown(db.close);
      await db.select(db.accounts).get();
      await db.select(db.categories).get();
      expect(count, 1);
    });

    test('afterOpen lỗi hoặc treo không làm hỏng việc mở', () async {
      final never = Completer<void>();
      final db1 = AppDatabase(NativeDatabase.memory(), () => never.future);
      final db2 = AppDatabase(
        NativeDatabase.memory(),
        () async => throw StateError('boom'),
      );
      addTearDown(db1.close);
      addTearDown(db2.close);
      expect(await db1.select(db1.accounts).get(), isNotEmpty);
      expect(await db2.select(db2.accounts).get(), isNotEmpty);
    });

    test('cơ sở dữ liệu trong bộ nhớ (test) không gọi kênh', () async {
      mockChannel((_) => 1);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.select(db.accounts).get();
      expect(calls, isEmpty);
    });
  });

  // D-017: Keychain (PIN) vẫn theo bản sao lưu iCloud sang máy mới, còn cơ sở
  // dữ liệu thì không → giống cài lại: PIN cũ phải bị xóa, không khóa người dùng
  // ngoài một ví trống. Cùng đường mã với plan001_t6_pin_reinstall_test.dart.
  test(
    'khôi phục iCloud sang máy mới: Keychain có PIN, DB mới → xóa PIN',
    () async {
      final keychain = MemorySecretStore();
      final oldDb = AppDatabase(NativeDatabase.memory());
      final newDb = AppDatabase(NativeDatabase.memory());
      addTearDown(oldDb.close);
      addTearDown(newDb.close);
      await PinService(
        keychain,
        settings: () => SettingsRepository(oldDb),
      ).setPin('2468');
      expect(keychain.values, isNotEmpty);

      final onNewPhone = PinService(
        keychain,
        settings: () => SettingsRepository(newDb),
      );
      expect(await onNewPhone.clearIfReinstalled(), isTrue);
      expect(keychain.values, isEmpty);
    },
  );
}
