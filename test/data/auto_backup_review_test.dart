import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/features/settings/auto_backup_section.dart';
import 'package:vigon/src/ui/messenger.dart';

import '../fake_backup_folder.dart';

/// Hồi quy cho các lỗi tìm ra khi kiểm chứng độc lập F-24 (AC-58..60).
/// Phần Kotlin (ghi file tạm rồi đổi tên) không test tự động được: xem ghi chú
/// "CHƯA kiểm chứng trên máy" trong BackupFolderChannel.kt / báo cáo.
const _tree = 'content://tree/Vigon';

/// Thư mục giả cho phép giữ kết quả bộ chọn thư mục cho tới khi test cho phép.
class _GatedFolder extends FakeFolder {
  final gate = Completer<PickedFolder?>();

  @override
  Future<PickedFolder?> pickFolder() => gate.future;
}

/// Dựng một "màn hình" có nút gọi [onTap] với context của nó; trả về hàm gỡ màn hình.
Future<void> _pumpHost(
  WidgetTester tester, {
  required FakeFolder folder,
  required AutoBackupService service,
  required Future<void> Function(BuildContext, WidgetRef) onTap,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backupFolderServiceProvider.overrideWithValue(folder),
        autoBackupServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootMessengerKey,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => onTap(context, ref),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  AutoBackupService makeService(
    AppDatabase db,
    FakeFolder folder,
    MemorySecretStore secrets, {
    BackupEncryptor? encrypt,
    DateTime? now,
  }) => AutoBackupService(
    db: db,
    folder: folder,
    secrets: secrets,
    clock: () => now ?? DateTime(2026, 11, 3, 9, 0),
    encrypt: encrypt ?? (j, p) => encryptBackup(j, p, iterations: 1000),
  );

  group('dịch vụ', () {
    late AppDatabase db;
    late FakeFolder folder;
    late MemorySecretStore secrets;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      folder = FakeFolder();
      secrets = MemorySecretStore();
      await db.select(db.accounts).get();
    });
    tearDown(() => db.close());

    test('đang có lần chạy khác: trả busy, không ghi gì, không đổi kết quả '
        'lần trước', () async {
      final gate = Completer<void>();
      final service = makeService(
        db,
        folder,
        secrets,
        encrypt: (j, p) async {
          await gate.future;
          return encryptBackup(j, p, iterations: 1000);
        },
      );
      await service.enable(
        folder: const PickedFolder(uri: _tree, name: 'Vigon'),
        password: 'abcdef',
      );
      final first = service.backupNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(await service.backupNow(), AutoBackupResult.busy);
      expect(folder.writes, 0);
      expect(
        (await service.state()).lastResult,
        isNull,
        reason: 'busy không được ghi như một kết quả',
      );
      expect((await service.state()).lastFailed, isFalse);

      gate.complete();
      expect(await first, AutoBackupResult.ok);
      expect(folder.writes, 1);
      expect((await service.state()).lastResult, AutoBackupResult.ok);
    });

    test('lỗi ghi: lastAt vẫn được ghi (tối đa một lần/ngày kể cả lỗi) và '
        'trạng thái cho UI thấy lỗi kèm thời gian', () async {
      final service = makeService(db, folder, secrets);
      await service.enable(
        folder: const PickedFolder(uri: _tree, name: 'Vigon'),
        password: 'abcdef',
      );
      folder.failWith = BackupFolderError.folderMissing;
      expect(await service.backupNow(), AutoBackupResult.folderMissing);
      final s = await service.state();
      expect(s.lastFailed, isTrue);
      expect(s.lastAt, DateTime(2026, 11, 3, 9, 0));
    });
  });

  group('giao diện', () {
    testWidgets('lỗi hiện kèm thời gian lần thử và cập nhật khi app quay lại '
        'từ nền (AC-60)', (tester) async {
      final secrets = MemorySecretStore();
      final folder = FakeFolder();
      final db = AppDatabase(NativeDatabase.memory());
      final service = makeService(db, folder, secrets);
      await service.enable(
        folder: const PickedFolder(uri: _tree, name: 'Vigon'),
        password: 'abcdef',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backupFolderServiceProvider.overrideWithValue(folder),
            autoBackupServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: AutoBackupSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa sao lưu lần nào'), findsOneWidget);

      // Lần chạy nền (app đang ở nền) lỗi và ghi kết quả; Cài đặt vẫn mở.
      secrets.values[AutoBackupService.lastAtKey] = DateTime(
        2026,
        11,
        3,
        18,
        30,
      ).toIso8601String();
      secrets.values[AutoBackupService.lastResultKey] =
          AutoBackupResult.permissionDenied.name;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Lần thử 3 thg 11, 18:30: '
          'Không ghi được vào thư mục. Chọn lại thư mục',
        ),
        findsOneWidget,
      );
    });

    testWidgets('chọn thư mục xong mà màn hình đã bị gỡ: bỏ quyền thư mục, '
        'không lưu gì (bật)', (tester) async {
      final secrets = MemorySecretStore();
      final folder = _GatedFolder();
      final db = AppDatabase(NativeDatabase.memory());
      final service = makeService(db, folder, secrets);
      await _pumpHost(
        tester,
        folder: folder,
        service: service,
        onTap: enableAutoBackup,
      );
      await tester.tap(find.text('go'));
      await tester.pump();

      // Gỡ màn hình rồi mới trả kết quả bộ chọn.
      await tester.pumpWidget(const SizedBox());
      folder.gate.complete(const PickedFolder(uri: _tree, name: 'Vigon'));
      await tester.pump();

      expect(folder.released, [_tree]);
      expect(secrets.values, isEmpty);
    });

    testWidgets('chọn lại thư mục mà màn hình đã bị gỡ: bỏ quyền thư mục mới, '
        'nhưng giữ quyền nếu trùng thư mục đang dùng', (tester) async {
      Future<List<String>> run(String picked) async {
        final secrets = MemorySecretStore();
        final folder = _GatedFolder();
        final db = AppDatabase(NativeDatabase.memory());
        final service = makeService(db, folder, secrets);
        await service.enable(
          folder: const PickedFolder(uri: _tree, name: 'Vigon'),
          password: 'abcdef',
        );
        await _pumpHost(
          tester,
          folder: folder,
          service: service,
          onTap: repickFolder,
        );
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        folder.gate.complete(PickedFolder(uri: picked, name: 'X'));
        await tester.pump();
        expect(secrets.values[AutoBackupService.uriKey], _tree);
        return folder.released;
      }

      expect(await run('content://tree/Moi'), ['content://tree/Moi']);
      expect(await run(_tree), isEmpty);
    });

    testWidgets('"Sao lưu ngay" khi đang chạy: báo đang sao lưu, không báo '
        'thất bại', (tester) async {
      final secrets = MemorySecretStore();
      final folder = FakeFolder();
      final db = AppDatabase(NativeDatabase.memory());
      final gate = Completer<void>();
      final service = makeService(
        db,
        folder,
        secrets,
        encrypt: (j, p) async {
          await gate.future;
          return encryptBackup(j, p, iterations: 1000);
        },
      );
      await service.enable(
        folder: const PickedFolder(uri: _tree, name: 'Vigon'),
        password: 'abcdef',
      );
      await _pumpHost(
        tester,
        folder: folder,
        service: service,
        onTap: backupNowFromSettings,
      );

      // Lần chạy nền đang giữ khóa.
      late Future<AutoBackupResult> running;
      await tester.runAsync(() async {
        running = service.backupNow();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Đang sao lưu, thử lại sau giây lát'), findsOneWidget);
      expect(find.textContaining('không thành công'), findsNothing);
      gate.complete();
      expect(await tester.runAsync(() => running), AutoBackupResult.ok);
    });
  });
}
