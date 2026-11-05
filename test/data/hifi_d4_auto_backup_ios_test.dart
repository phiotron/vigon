// D4 (D-022): sao lưu tự động trên iOS chạy khi mở/quay lại app, cùng định
// dạng file và luật một lần mỗi ngày như Android; kênh trả thêm `inICloud`.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';

import '../fake_backup_folder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late FakeFolder folder;
  late MemorySecretStore secrets;
  late DateTime now;
  late AutoBackupService service;
  const uri = 'ios-bookmark:6B1C0A55-0000-4000-8000-000000000001';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    folder = FakeFolder();
    secrets = MemorySecretStore();
    now = DateTime(2026, 11, 26, 8, 5);
    service = AutoBackupService(
      db: db,
      folder: folder,
      secrets: secrets,
      clock: () => now,
      encrypt: (json, pw) => encryptBackup(json, pw, iterations: 1000),
    );
    await db.select(db.accounts).get();
  });
  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await db.close();
  });

  Future<void> addEntry(int amount) => db
      .into(db.entries)
      .insert(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          accountId: 1,
          date: '2026-11-26',
        ),
      );

  Future<void> enable({bool? inICloud = true}) => service.enable(
    folder: PickedFolder(uri: uri, name: 'Ví Gọn', inICloud: inICloud),
    password: 'mat-khau-123',
  );

  test('iOS: chạy khi mở app, KHÔNG chạy lúc ra nền', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AutoBackupService.runsOnOpen, isTrue);
    await addEntry(50000);
    await enable();
    await service.maybeRunDaily(); // ra nền: iOS bỏ qua
    expect(folder.writes, 0);
    await service.maybeRunOnOpen();
    expect(folder.files.keys, ['vigon-auto-20261126-0805.vigon']);
  });

  test(
    'iOS: tối đa một lần mỗi ngày, hôm sau chạy lại khi dữ liệu đổi',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await addEntry(50000);
      await enable();
      await service.maybeRunOnOpen();
      await addEntry(10000);
      now = DateTime(2026, 11, 26, 21, 0);
      await service.maybeRunOnOpen(); // cùng ngày: không chạy
      expect(folder.writes, 1);
      now = DateTime(2026, 11, 27, 7, 30);
      await service.maybeRunOnOpen();
      expect(folder.writes, 2);
      now = DateTime(2026, 11, 28, 7, 30);
      await service.maybeRunOnOpen(); // dữ liệu không đổi: bỏ qua
      expect(folder.writes, 2);
    },
  );

  test('Android: vẫn chạy lúc ra nền, mở app không làm gì', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AutoBackupService.runsOnOpen, isFalse);
    await addEntry(50000);
    await enable(inICloud: null);
    await service.maybeRunOnOpen();
    expect(folder.writes, 0);
    await service.maybeRunDaily();
    expect(folder.writes, 1);
  });

  test('lưu inICloud của thư mục; đổi thư mục cập nhật; tắt thì xóa', () async {
    await enable(inICloud: false);
    expect((await service.state()).folderInICloud, isFalse);
    await service.changeFolder(
      const PickedFolder(uri: 'ios-bookmark:x', name: 'iCloud', inICloud: true),
    );
    expect((await service.state()).folderInICloud, isTrue);
    await service.changeFolder(const PickedFolder(uri: 'content://tree/a'));
    expect((await service.state()).folderInICloud, isNull);
    await service.disable();
    expect(await secrets.read(AutoBackupService.iCloudKey), isNull);
  });

  test(
    'lỗi thư mục iOS (bookmark mất / bị thu hồi) ánh xạ vào trạng thái sẵn có',
    () async {
      await enable();
      folder.failWith = BackupFolderError.folderMissing;
      expect(await service.backupNow(), AutoBackupResult.folderMissing);
      folder.failWith = BackupFolderError.permissionDenied;
      expect(await service.backupNow(), AutoBackupResult.permissionDenied);
      expect((await service.state()).lastFailed, isTrue);
    },
  );

  group('kênh vigon/backup_folder', () {
    const channel = MethodChannel(BackupFolderService.channelName);
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    void reply(Object? value) => TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => value);

    test('pickFolder đọc inICloud của iOS', () async {
      reply({'uri': uri, 'name': 'Ví Gọn', 'inICloud': true});
      final picked = await const BackupFolderService().pickFolder();
      expect(picked!.uri, uri);
      expect(picked.inICloud, isTrue);
    });

    test('Android không gửi inICloud → null', () async {
      reply({'uri': 'content://tree/a', 'name': 'Drive'});
      expect(
        (await const BackupFolderService().pickFolder())!.inICloud,
        isNull,
      );
    });

    test('mã lỗi iOS giống Android', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'permission_denied');
          });
      expect(
        () => const BackupFolderService().listFiles(uri),
        throwsA(
          isA<BackupFolderException>().having(
            (e) => e.error,
            'error',
            BackupFolderError.permissionDenied,
          ),
        ),
      );
    });
  });
}
