import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 11, 3, 10, 30);
  const fast = 1000; // số vòng nhỏ cho test chạy nhanh

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> sampleJson() async {
    // Máy xuất file đã qua Màn chào (F-44); cờ cài mới không theo file.
    await SettingsRepository(db).finishOnboarding();
    await AccountRepository(db).add(name: 'Thẻ', initialBalance: 1000);
    await db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: 155000,
            accountId: 1,
            date: '2026-11-03',
            note: const Value('phở 🍜'),
          ),
        );
    return exportBackup(db, now: now);
  }

  Future<Map<String, List<Object?>>> snapshot(AppDatabase d) async => {
    'accounts': await d.select(d.accounts).get(),
    'categories': await d.select(d.categories).get(),
    'entries': await d.select(d.entries).get(),
    'settings': await d.select(d.settings).get(),
  };

  /// Sửa một byte của trường base64 [field] trong phong bì.
  String flipByte(String envelope, String field) {
    final root = jsonDecode(envelope) as Map<String, dynamic>;
    final bytes = base64.decode(root[field] as String);
    bytes[bytes.length ~/ 2] ^= 0x01;
    root[field] = base64.encode(bytes);
    return jsonEncode(root);
  }

  String edit(String envelope, void Function(Map<String, dynamic>) change) {
    final root = jsonDecode(envelope) as Map<String, dynamic>;
    change(root);
    return jsonEncode(root);
  }

  group('mã hóa file sao lưu (AC-55)', () {
    test('xuất mã hóa rồi khôi phục ra đúng dữ liệu', () async {
      final json = await sampleJson();
      final envelope = await encryptBackup(json, 'matkhau1', iterations: fast);
      final root = jsonDecode(envelope) as Map<String, dynamic>;
      expect(root['format'], 'vigon-backup-encrypted');
      expect(root['version'], 1);
      expect(root['kdf'], 'pbkdf2-hmac-sha256');
      expect(root['iterations'], fast);
      expect(base64.decode(root['salt'] as String), hasLength(16));
      expect(base64.decode(root['nonce'] as String), hasLength(12));
      expect(envelope, isNot(contains('155000')));
      expect(envelope, isNot(contains('vigon-backup"')));

      expect(isEncryptedBackup(envelope), isTrue);
      checkEncryptedBackup(envelope);
      final plain = await decryptBackup(envelope, 'matkhau1');
      expect(plain, json); // đúng từng byte
      validateBackup(plain);

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await importBackup(other, plain);
      expect(await snapshot(other), await snapshot(db));
    });

    test('sai mật khẩu bị từ chối', () async {
      final envelope = await encryptBackup(
        await sampleJson(),
        'matkhau1',
        iterations: fast,
      );
      for (final bad in ['matkhau2', 'MATKHAU1', '', 'matkhau1 ']) {
        await expectLater(
          decryptBackup(envelope, bad),
          throwsA(isA<BackupPasswordException>()),
        );
      }
    });

    test('phong bì bị sửa một byte thì bị từ chối', () async {
      final envelope = await encryptBackup(
        await sampleJson(),
        'matkhau1',
        iterations: fast,
      );
      for (final field in ['ciphertext', 'salt', 'nonce']) {
        await expectLater(
          decryptBackup(flipByte(envelope, field), 'matkhau1'),
          throwsA(isA<BackupPasswordException>()),
          reason: field,
        );
      }
      // Thẻ xác thực là 16 byte cuối của ciphertext.
      final root = jsonDecode(envelope) as Map<String, dynamic>;
      final sealed = base64.decode(root['ciphertext'] as String);
      sealed[sealed.length - 1] ^= 0x80;
      final badTag = edit(
        envelope,
        (r) => r['ciphertext'] = base64.encode(sealed),
      );
      await expectLater(
        decryptBackup(badTag, 'matkhau1'),
        throwsA(isA<BackupPasswordException>()),
      );
      final badIterations = edit(envelope, (r) => r['iterations'] = fast + 1);
      await expectLater(
        decryptBackup(badIterations, 'matkhau1'),
        throwsA(isA<BackupPasswordException>()),
      );
    });

    test('dữ liệu gắn thêm (AAD) bị đổi thì bị từ chối', () async {
      final envelope = await encryptBackup(
        await sampleJson(),
        'matkhau1',
        iterations: fast,
      );
      final root = jsonDecode(envelope) as Map<String, dynamic>;
      final key =
          await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: fast,
            bits: 256,
          ).deriveKeyFromPassword(
            password: 'matkhau1',
            nonce: base64.decode(root['salt'] as String),
          );
      final sealed = base64.decode(root['ciphertext'] as String);
      final box = SecretBox(
        sealed.sublist(0, sealed.length - 16),
        nonce: base64.decode(root['nonce'] as String),
        mac: Mac(sealed.sublist(sealed.length - 16)),
      );
      final aes = AesGcm.with256bits();
      // Đúng AAD thì mở được (đảm bảo test này dựng đúng).
      await aes.decrypt(
        box,
        secretKey: key,
        aad: utf8.encode('vigon-backup-encrypted:1'),
      );
      for (final aad in ['vigon-backup-encrypted:2', 'vigon-backup:1', '']) {
        await expectLater(
          aes.decrypt(box, secretKey: key, aad: utf8.encode(aad)),
          throwsA(isA<SecretBoxAuthenticationError>()),
          reason: aad,
        );
      }
      // Sửa format/version trong phong bì thì bị chặn ngay từ hình dạng.
      for (final bad in [
        edit(envelope, (r) => r['format'] = 'vigon-backup'),
        edit(envelope, (r) => r['version'] = 2),
        edit(envelope, (r) => r['version'] = 0),
        edit(envelope, (r) => r['kdf'] = 'scrypt'),
      ]) {
        await expectLater(
          decryptBackup(bad, 'matkhau1'),
          throwsA(isA<BackupFormatException>()),
        );
      }
    });

    test('hình dạng phong bì sai bị báo BackupFormatException', () async {
      final envelope = await encryptBackup('{}', 'matkhau1', iterations: fast);
      final bads = [
        'không phải json',
        edit(envelope, (r) => r['iterations'] = 0),
        edit(envelope, (r) => r['iterations'] = 2000000000),
        edit(envelope, (r) => r['iterations'] = '1000'),
        edit(envelope, (r) => r['salt'] = base64.encode([1, 2, 3])),
        edit(envelope, (r) => r['nonce'] = '***'),
        edit(envelope, (r) => r['ciphertext'] = base64.encode([1, 2, 3])),
        edit(envelope, (r) => r.remove('ciphertext')),
      ];
      for (final bad in bads) {
        expect(
          () => checkEncryptedBackup(bad),
          throwsA(isA<BackupFormatException>()),
        );
        await expectLater(
          decryptBackup(bad, 'matkhau1'),
          throwsA(isA<BackupFormatException>()),
        );
      }
    });

    test('file cũ không mã hóa không bị nhận nhầm', () async {
      final json = await sampleJson();
      expect(isEncryptedBackup(json), isFalse);
      expect(isEncryptedBackup('abc'), isFalse);
      expect(isEncryptedBackup('[1]'), isFalse);
      validateBackup(json); // vẫn khôi phục như cũ
    });

    test('mật khẩu tiếng Việt và emoji', () async {
      const pw = 'Mật khẩu Đẹp 🔐🇻🇳';
      final json = await sampleJson();
      final envelope = await encryptBackup(json, pw, iterations: fast);
      expect(await decryptBackup(envelope, pw), json);
      // Khác một dấu hoặc thiếu emoji là sai.
      await expectLater(
        decryptBackup(envelope, 'Mat khẩu Đẹp 🔐🇻🇳'),
        throwsA(isA<BackupPasswordException>()),
      );
      await expectLater(
        decryptBackup(envelope, 'Mật khẩu Đẹp 🔐'),
        throwsA(isA<BackupPasswordException>()),
      );
    });

    test('hai lần mã hóa cùng dữ liệu cho kết quả khác nhau', () async {
      final json = await sampleJson();
      final a = jsonDecode(
        await encryptBackup(json, 'matkhau1', iterations: fast),
      );
      final b = jsonDecode(
        await encryptBackup(json, 'matkhau1', iterations: fast),
      );
      expect(a['salt'], isNot(b['salt']));
      expect(a['nonce'], isNot(b['nonce']));
      expect(a['ciphertext'], isNot(b['ciphertext']));
    });

    test('chạy ở isolate riêng với số vòng mặc định, đo thời gian', () async {
      final json = await sampleJson();
      final sw = Stopwatch()..start();
      final envelope = await encryptBackupOffThread(json, 'matkhau1');
      final encMs = sw.elapsedMilliseconds;
      sw.reset();
      expect(await decryptBackupOffThread(envelope, 'matkhau1'), json);
      // ignore: avoid_print
      print(
        'PBKDF2 $backupKdfIterations vòng: mã hóa ${encMs}ms, '
        'giải mã ${sw.elapsedMilliseconds}ms (máy tính, JIT)',
      );
      await expectLater(
        decryptBackupOffThread(envelope, 'sai-roi'),
        throwsA(isA<BackupPasswordException>()),
      );
    });
  });
}
