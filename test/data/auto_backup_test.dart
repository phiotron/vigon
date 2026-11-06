import 'dart:convert';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';

import '../fake_backup_folder.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late FakeFolder folder;
  late MemorySecretStore secrets;
  late DateTime now;
  late AutoBackupService service;
  const tree = 'content://tree/Vigon';
  const password = 'mat-khau-bi-mat-123';

  Future<String> encryptFast(String json, String pw) =>
      encryptBackup(json, pw, iterations: 1000);

  AutoBackupService makeService({BackupEncryptor? encrypt}) =>
      AutoBackupService(
        db: db,
        folder: folder,
        secrets: secrets,
        clock: () => now,
        encrypt: encrypt ?? encryptFast,
      );

  Future<void> addEntry(int amount, {String? note}) => db
      .into(db.entries)
      .insert(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          accountId: 1,
          date: '2026-11-03',
          note: Value(note),
        ),
      );

  Future<void> enable() => service.enable(
    folder: const PickedFolder(uri: tree, name: 'Vigon'),
    password: password,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    folder = FakeFolder();
    secrets = MemorySecretStore();
    now = DateTime(2026, 11, 3, 18, 30);
    service = makeService();
    // Chạm vào DB để seed xong trước khi test.
    await db.select(db.accounts).get();
  });
  tearDown(() => db.close());

  test(
    'ghi đúng tên, file mã hóa và đọc lại được bằng mật khẩu (AC-58)',
    () async {
      await addEntry(155000, note: 'phở bò');
      await enable();
      expect(await service.backupNow(), AutoBackupResult.ok);

      expect(folder.files.keys, ['vigon-auto-20261103-1830.vigon']);
      final text = utf8.decode(folder.files.values.single);
      expect(isEncryptedBackup(text), isTrue);
      expect(text.contains('phở'), isFalse);
      expect(text.contains('155000'), isFalse);
      expect(text.contains('"tables"'), isFalse);
      expect(text.contains(password), isFalse);

      final json = await decryptBackup(text, password);
      validateBackup(json);
      expect(json.contains('phở bò'), isTrue);
      await expectLater(
        decryptBackup(text, 'sai-mat-khau'),
        throwsA(isA<BackupPasswordException>()),
      );

      // File khôi phục được vào một cơ sở dữ liệu khác bằng đường khôi phục hiện có.
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, json);
      final notes = await other.select(other.entries).get();
      expect(notes.single.note, 'phở bò');
      expect(notes.single.amount, 155000);
    },
  );

  test('mã hóa mặc định (isolate, 100.000 vòng) cũng chạy được', () async {
    service = makeService(encrypt: encryptBackupOffThread);
    await enable();
    expect(await service.backupNow(), AutoBackupResult.ok);
    final text = utf8.decode(folder.files.values.single);
    expect((jsonDecode(text) as Map)['iterations'], backupKdfIterations);
    validateBackup(await decryptBackup(text, password));
  });

  test(
    'mật khẩu chỉ ở SecretStore: không trong bảng settings, không trong file',
    () async {
      await addEntry(1000);
      await enable();
      await service.backupNow();
      expect(secrets.values[AutoBackupService.passwordKey], password);
      final settings = await db.select(db.settings).get();
      for (final s in settings) {
        expect(s.key.contains('auto_backup'), isFalse);
        expect(s.value.contains(password), isFalse);
      }
      for (final bytes in folder.files.values) {
        expect(utf8.decode(bytes).contains(password), isFalse);
      }
      // Cũng không lọt vào nội dung xuất ra: trạng thái không đi theo file sao lưu.
      expect((await exportBackup(db, now: now)).contains(password), isFalse);
    },
  );

  test('giữ 7 file tự động gần nhất, không đụng file khác (AC-59)', () async {
    // File người dùng và file sao lưu tay có sẵn trong thư mục.
    final others = [
      'notes.txt',
      'vigon-20261101-0900.vigon',
      'vigon-auto-20261101-1000 (1).vigon',
      'vigon-auto-latest.vigon',
      'vigon-auto-20261031-0900.vigon.bak',
    ];
    for (final n in others) {
      folder.files[n] = Uint8List.fromList([1]);
    }
    await enable();
    for (var day = 1; day <= 10; day++) {
      now = DateTime(2026, 10, day, 8, 5);
      await service.backupNow();
    }
    final auto =
        folder.files.keys
            .where(AutoBackupService.fileNamePattern.hasMatch)
            .toList()
          ..sort();
    expect(auto.length, 7);
    expect(auto.first, 'vigon-auto-20261004-0805.vigon');
    expect(auto.last, 'vigon-auto-20261010-0805.vigon');
    for (final n in others) {
      expect(folder.files.containsKey(n), isTrue, reason: '$n bị xóa');
    }
  });

  test(
    'mỗi mốc giờ tối đa một lần và chỉ khi dữ liệu đổi (AC-59, D-026)',
    () async {
      await enable(); // 18:30, giờ mặc định 21:00
      await service.maybeRunDaily();
      expect(folder.files.length, 1, reason: 'chưa từng sao lưu: chạy');

      // Trước 21:00, dù dữ liệu đổi: chưa tới mốc.
      await addEntry(2000);
      now = DateTime(2026, 11, 3, 20, 59);
      await service.maybeRunDaily();
      expect(folder.files.length, 1);

      // Qua 21:00, dữ liệu đã đổi: chạy.
      now = DateTime(2026, 11, 3, 21, 5);
      await service.maybeRunDaily();
      expect(folder.files.length, 2);

      // Cùng mốc, dữ liệu lại đổi: không chạy lần hai.
      await addEntry(3000);
      now = DateTime(2026, 11, 3, 23, 0);
      await service.maybeRunDaily();
      expect(folder.files.length, 2);

      // Mốc hôm sau: chạy.
      now = DateTime(2026, 11, 4, 21, 10);
      await service.maybeRunDaily();
      expect(folder.files.length, 3);

      // Mốc hôm sau nữa, dữ liệu không đổi: bỏ qua và ghi đã xét...
      now = DateTime(2026, 11, 5, 21, 10);
      await service.maybeRunDaily();
      expect(folder.files.length, 3);
      expect(secrets.values[AutoBackupService.lastCheckKey], isNotNull);
      // ...nên ra nền lần nữa cùng mốc không xuất lại dữ liệu để so.
      await addEntry(4000);
      now = DateTime(2026, 11, 5, 22, 0);
      await service.maybeRunDaily();
      expect(folder.files.length, 3);

      // Mốc kế tiếp: dữ liệu đã đổi từ lần sao lưu trước → chạy.
      now = DateTime(2026, 11, 6, 21, 0);
      await service.maybeRunDaily();
      expect(folder.files.length, 4);
    },
  );

  test('tắt thì không chạy nền', () async {
    await addEntry(1000);
    await service.maybeRunDaily();
    expect(folder.files, isEmpty);
    expect((await service.state()).enabled, isFalse);
  });

  test('"Sao lưu ngay" chạy cả khi dữ liệu không đổi (AC-60)', () async {
    await enable();
    await service.maybeRunDaily();
    now = DateTime(2026, 11, 3, 19, 0);
    expect(await service.backupNow(), AutoBackupResult.ok);
    expect(folder.files.length, 2);
    final s = await service.state();
    expect(s.lastAt, now);
    expect(s.lastResult, AutoBackupResult.ok);
    expect(s.lastFailed, isFalse);
    expect(s.folderName, 'Vigon');
  });

  test(
    'quyền bị thu hồi hoặc thư mục mất: ghi nhận lỗi, không ném (AC-60)',
    () async {
      await enable();
      await service.backupNow();

      folder.failWith = BackupFolderError.permissionDenied;
      now = DateTime(2026, 11, 4, 9, 0);
      await addEntry(500);
      await service.maybeRunDaily(); // không ném
      var s = await service.state();
      expect(s.lastResult, AutoBackupResult.permissionDenied);
      expect(s.lastFailed, isTrue);
      expect(
        s.enabled,
        isTrue,
        reason: 'không tự tắt, chờ người dùng chọn lại',
      );

      folder.failWith = BackupFolderError.folderMissing;
      expect(await service.backupNow(), AutoBackupResult.folderMissing);
      s = await service.state();
      expect(s.lastResult, AutoBackupResult.folderMissing);

      folder.failWith = BackupFolderError.unavailable;
      expect(await service.backupNow(), AutoBackupResult.failed);

      // Chọn lại thư mục rồi sao lưu: hết lỗi.
      folder.failWith = null;
      await service.changeFolder(
        const PickedFolder(uri: 'content://tree/New', name: 'Mới'),
      );
      expect(folder.released, [tree]);
      expect(await service.backupNow(), AutoBackupResult.ok);
      s = await service.state();
      expect(s.folderUri, 'content://tree/New');
      expect(s.folderName, 'Mới');
      expect(s.lastFailed, isFalse);
    },
  );

  test('lỗi hôm nay thì hôm sau thử lại dù dữ liệu không đổi', () async {
    await enable();
    folder.failWith = BackupFolderError.permissionDenied;
    await service.maybeRunDaily();
    expect(folder.files, isEmpty);

    folder.failWith = null;
    now = DateTime(2026, 11, 3, 20, 0);
    await service.maybeRunDaily();
    expect(folder.files, isEmpty, reason: 'cùng ngày: chưa thử lại');

    now = DateTime(2026, 11, 4, 9, 0);
    await service.maybeRunDaily();
    expect(folder.files.length, 1);
  });

  test('lỗi mã hóa hoặc ngoại lệ lạ cũng không ném', () async {
    service = makeService(encrypt: (_, _) async => throw StateError('hỏng'));
    await enable();
    expect(await service.backupNow(), AutoBackupResult.failed);
    expect(folder.files, isEmpty);
    await service.maybeRunDaily();
  });

  test(
    'tắt: xóa mật khẩu, bỏ quyền thư mục, giữ file đã ghi (AC-60)',
    () async {
      await enable();
      await service.backupNow();
      expect(folder.files.length, 1);

      await service.disable();
      expect(secrets.values, isEmpty);
      expect(folder.released, [tree]);
      expect(folder.files.length, 1, reason: 'không xóa file đã ghi');
      final s = await service.state();
      expect(s.enabled, isFalse);
      expect(s.folderUri, isNull);

      // Tắt rồi ra nền: không còn tự chạy.
      now = DateTime(2026, 11, 9, 9, 0);
      await addEntry(1);
      await service.maybeRunDaily();
      expect(folder.files.length, 1);
    },
  );

  test('thiếu mật khẩu thì không ghi gì, không ghi bản rõ', () async {
    await enable();
    secrets.values.remove(AutoBackupService.passwordKey);
    expect(await service.backupNow(), AutoBackupResult.notConfigured);
    expect(folder.files, isEmpty);
  });

  test('kênh Kotlin ánh xạ mã lỗi sang BackupFolderError', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('test/backup_folder');
    String? code;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'pickFolder') {
            return {'uri': 'content://x', 'name': 'X'};
          }
          if (code == null) throw MissingPluginException();
          throw PlatformException(code: code);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    const svc = BackupFolderService(channel);
    final picked = await svc.pickFolder();
    expect(picked?.uri, 'content://x');
    expect(picked?.name, 'X');

    Future<BackupFolderError> errorOf() async {
      try {
        await svc.listFiles('content://x');
      } on BackupFolderException catch (e) {
        return e.error;
      }
      fail('phải ném');
    }

    expect(await errorOf(), BackupFolderError.unavailable);
    code = 'permission_denied';
    expect(await errorOf(), BackupFolderError.permissionDenied);
    code = 'folder_missing';
    expect(await errorOf(), BackupFolderError.folderMissing);
    code = 'io_error';
    expect(await errorOf(), BackupFolderError.unavailable);
  });
}
