import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/providers.dart';

/// PLAN-001 T6, iOS-02: Keychain giữ PIN sau khi gỡ app, cơ sở dữ liệu thì mất.
/// Cài lại (cơ sở dữ liệu mới) không được bị khóa bởi PIN cũ.
void main() {
  const installKey = 'pin_install_id';
  late MemorySecretStore keychain;
  final databases = <AppDatabase>[];

  AppDatabase newDatabase() {
    final db = AppDatabase(NativeDatabase.memory());
    databases.add(db);
    return db;
  }

  // Mỗi test mở hai cơ sở dữ liệu trong bộ nhớ riêng biệt (máy cũ, máy cài lại).
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() => keychain = MemorySecretStore());
  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
    databases.clear();
  });

  PinService service(AppDatabase db) =>
      PinService(keychain, settings: () => SettingsRepository(db));

  /// Mở app với [db] và chờ màn khóa quyết định khóa hay không.
  Future<ProviderContainer> openApp(AppDatabase db) async {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        secretStoreProvider.overrideWithValue(keychain),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 4, 9)),
      ],
    );
    addTearDown(c.dispose);
    c.listen(lockProvider, (_, _) {});
    for (
      var i = 0;
      i < 20 && c.read(lockProvider) == AppLockState.checking;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return c;
  }

  group('mã cài đặt đi kèm PIN', () {
    test(
      'đặt PIN ghi cùng một mã vào bộ nhớ an toàn và bảng settings',
      () async {
        final db = newDatabase();
        await service(db).setPin('2468');
        final id = await SettingsRepository(db).readPinInstallId();
        expect(id, isNotNull);
        expect(keychain.values[installKey], id);
        expect(keychain.values.keys.toSet(), {
          'pin_hash',
          'pin_salt',
          installKey,
        });
      },
    );

    test(
      'đổi PIN dùng lại mã cũ; tắt PIN xóa mã trong bộ nhớ an toàn',
      () async {
        final db = newDatabase();
        final pin = service(db);
        await pin.setPin('2468');
        final id = keychain.values[installKey];
        await pin.setPin('1357');
        expect(keychain.values[installKey], id);
        expect(await SettingsRepository(db).readPinInstallId(), id);
        await pin.disable();
        expect(keychain.values, isEmpty);
      },
    );
  });

  group('mở app (iOS-02)', () {
    test(
      'cơ sở dữ liệu mới, bộ nhớ an toàn còn PIN có mã: xóa PIN, không khóa',
      () async {
        await service(newDatabase()).setPin('2468');
        // Gỡ app rồi cài lại: Keychain còn nguyên, cơ sở dữ liệu là bản mới.
        final fresh = newDatabase();
        final c = await openApp(fresh);
        expect(c.read(lockProvider), AppLockState.unlocked);
        expect(keychain.values, isEmpty);
        expect(await c.read(pinEnabledProvider.future), isFalse);
      },
    );

    test('PIN đặt trước bản này (không có mã) thì giữ, vẫn khóa', () async {
      await PinService(keychain).setPin('2468');
      expect(keychain.values.containsKey(installKey), isFalse);
      final c = await openApp(newDatabase());
      expect(c.read(lockProvider), AppLockState.locked);
      expect(await c.read(lockProvider.notifier).unlock('2468'), isTrue);
    });

    test('cơ sở dữ liệu có đúng mã thì giữ PIN, vẫn khóa', () async {
      final db = newDatabase();
      await service(db).setPin('2468');
      final c = await openApp(db);
      expect(c.read(lockProvider), AppLockState.locked);
      expect(await service(db).isEnabled(), isTrue);
      expect(await c.read(lockProvider.notifier).unlock('2468'), isTrue);
    });

    test(
      'mã trong cơ sở dữ liệu khác mã trong bộ nhớ an toàn thì xóa PIN',
      () async {
        final db = newDatabase();
        await service(db).setPin('2468');
        await SettingsRepository(db).setPinInstallId('khac');
        expect(await service(db).clearIfReinstalled(), isTrue);
        expect(await service(db).isEnabled(), isFalse);
      },
    );
  });

  group('sao lưu không mang mã cài đặt (D-006)', () {
    test('file xuất không chứa mã cài đặt', () async {
      final db = newDatabase();
      await SettingsRepository(db).ensureCurrency(defaultCode: 'VND');
      await service(db).setPin('2468');
      final id = (await SettingsRepository(db).readPinInstallId())!;
      final json = await exportBackup(db, now: DateTime(2026, 11, 4));
      expect(json.contains(id), isFalse);
      expect(json.contains(SettingsRepository.pinInstallIdKey), isFalse);
      final settings =
          (jsonDecode(json) as Map<String, dynamic>)['tables']['settings']
              as List;
      expect(settings.map((s) => s['key']), contains('currency'));
    });

    test(
      'khôi phục giữ mã của máy, bỏ qua mã trong file, PIN không bị xóa',
      () async {
        final source = newDatabase();
        await SettingsRepository(source).setBudget(500);
        final json = await exportBackup(source, now: DateTime(2026, 11, 4));
        // File sửa tay có chèn mã cài đặt lạ.
        final root = jsonDecode(json) as Map<String, dynamic>;
        final tables = root['tables'] as Map<String, dynamic>;
        (tables['settings'] as List).add({
          'key': SettingsRepository.pinInstallIdKey,
          'value': 'ma-trong-file',
        });
        root['checksum'] = sha256
            .convert(utf8.encode(jsonEncode(tables)))
            .toString();

        final db = newDatabase();
        await service(db).setPin('2468');
        final id = await SettingsRepository(db).readPinInstallId();
        await importBackup(db, jsonEncode(root));

        expect(await SettingsRepository(db).readPinInstallId(), id);
        expect(await SettingsRepository(db).readBudget(), 500);
        expect(await service(db).clearIfReinstalled(), isFalse);
        expect(await service(db).isEnabled(), isTrue);
      },
    );

    test('xóa toàn bộ dữ liệu không làm lệch mã', () async {
      final db = newDatabase();
      await service(db).setPin('2468');
      final id = await SettingsRepository(db).readPinInstallId();
      await deleteAllData(db);
      expect(await SettingsRepository(db).readPinInstallId(), id);
      expect(await service(db).clearIfReinstalled(), isFalse);
      final rows = await db.select(db.settings).get();
      expect(rows.map((r) => r.key), [SettingsRepository.pinInstallIdKey]);
    });
  });
}
