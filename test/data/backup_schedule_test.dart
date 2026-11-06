// D10 (D-026): giờ sao lưu theo giờ máy — tính "lần tới", quyết định bù khi
// lỡ, không chạy hai lần cho một mốc; đổi múi giờ và giờ mùa hè (DST).
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vigon/src/data/auto_backup_background.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/backup_schedule.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';

import '../fake_backup_folder.dart';

const nine = BackupTime(21, 0);

void main() {
  tzdata.initializeTimeZones();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// Hàm dựng giờ địa phương của một múi giờ (thay giờ máy).
  LocalDateTimeBuilder inZone(tz.Location loc) =>
      (y, mo, d, h, mi) => tz.TZDateTime(loc, y, mo, d, h, mi);

  group('BackupTime', () {
    test('mặc định 21:00; lưu dạng HH:MM và đọc lại', () {
      expect(BackupTime.defaultTime, nine);
      expect(const BackupTime(7, 5).encode(), '07:05');
      expect(BackupTime.parse('07:05'), const BackupTime(7, 5));
      expect(BackupTime.parse('23:59'), const BackupTime(23, 59));
      for (final bad in [null, '', '24:00', '12:60', 'ab:cd', '7:5', '1200']) {
        expect(BackupTime.parse(bad), isNull, reason: '$bad');
      }
    });
  });

  group('lần tới (giờ máy)', () {
    test('chưa tới giờ: hôm nay; đúng hoặc quá giờ: ngày mai', () {
      expect(
        nextSlot(DateTime(2026, 11, 6, 20, 59), nine),
        DateTime(2026, 11, 6, 21),
      );
      expect(
        nextSlot(DateTime(2026, 11, 6, 21), nine),
        DateTime(2026, 11, 7, 21),
      );
      expect(
        nextSlot(DateTime(2026, 11, 6, 23), nine),
        DateTime(2026, 11, 7, 21),
      );
      expect(
        isToday(DateTime(2026, 11, 6, 8), DateTime(2026, 11, 6, 21)),
        isTrue,
      );
      expect(
        isToday(DateTime(2026, 11, 6, 22), DateTime(2026, 11, 7, 21)),
        isFalse,
      );
    });

    test('qua nửa đêm, cuối tháng, cuối năm', () {
      const early = BackupTime(0, 15);
      expect(
        nextSlot(DateTime(2026, 11, 30, 23, 30), early),
        DateTime(2026, 12, 1, 0, 15),
      );
      expect(
        nextSlot(DateTime(2026, 12, 31, 0, 10), early),
        DateTime(2026, 12, 31, 0, 15),
      );
      expect(
        nextSlot(DateTime(2026, 12, 31, 0, 20), early),
        DateTime(2027, 1, 1, 0, 15),
      );
      expect(
        lastSlot(DateTime(2027, 1, 1, 0, 10), early),
        DateTime(2026, 12, 31, 0, 15),
      );
      expect(
        lastSlot(DateTime(2026, 3, 1, 8), nine),
        DateTime(2026, 2, 28, 21),
      );
    });
  });

  group('bù khi lỡ', () {
    test('chưa từng sao lưu: chạy ngay', () {
      expect(isBackupDue(now: DateTime(2026, 11, 6, 8), time: nine), isTrue);
    });

    test('trước giờ chọn mà mốc hôm qua đã xử lý: chưa chạy', () {
      expect(
        isBackupDue(
          now: DateTime(2026, 11, 6, 20, 59),
          time: nine,
          handledAt: DateTime(2026, 11, 5, 21, 4),
        ),
        isFalse,
      );
    });

    test('qua giờ chọn, hôm nay chưa xử lý: chạy (bù)', () {
      expect(
        isBackupDue(
          now: DateTime(2026, 11, 6, 21, 0),
          time: nine,
          handledAt: DateTime(2026, 11, 5, 21, 4),
        ),
        isTrue,
      );
    });

    test('một mốc chỉ xử lý một lần: đã chạy sau giờ chọn thì thôi', () {
      for (final later in [
        DateTime(2026, 11, 6, 21, 30),
        DateTime(2026, 11, 6, 23, 59),
        DateTime(2026, 11, 7, 8, 0),
        DateTime(2026, 11, 7, 20, 59),
      ]) {
        expect(
          isBackupDue(
            now: later,
            time: nine,
            handledAt: DateTime(2026, 11, 6, 21, 2),
          ),
          isFalse,
          reason: '$later',
        );
      }
    });

    test('máy tắt mấy ngày: mở lại bù đúng một lần', () {
      final handled = DateTime(2026, 11, 1, 21, 3);
      final open = DateTime(2026, 11, 5, 9, 0);
      expect(isBackupDue(now: open, time: nine, handledAt: handled), isTrue);
      // Bù xong lúc 9:00: tới 21:00 hôm đó mới tới mốc kế tiếp.
      expect(
        isBackupDue(
          now: DateTime(2026, 11, 5, 12),
          time: nine,
          handledAt: open,
        ),
        isFalse,
      );
      expect(
        isBackupDue(
          now: DateTime(2026, 11, 5, 21),
          time: nine,
          handledAt: open,
        ),
        isTrue,
      );
    });

    test('sao lưu tay trước giờ chọn không thay lần theo lịch', () {
      expect(
        isBackupDue(
          now: DateTime(2026, 11, 6, 21, 1),
          time: nine,
          handledAt: DateTime(2026, 11, 6, 20, 0),
        ),
        isTrue,
      );
    });
  });

  group('múi giờ', () {
    final hcm = tz.getLocation('Asia/Ho_Chi_Minh'); // UTC+7
    final tokyo = tz.getLocation('Asia/Tokyo'); // UTC+9
    final london = tz.getLocation('Europe/London');

    test('đổi múi giờ: giờ chọn theo giờ địa phương mới', () {
      // Cùng một thời điểm: 13:30 UTC = 20:30 Hà Nội = 22:30 Tokyo.
      final instant = DateTime.utc(2026, 11, 6, 13, 30);
      final atHcm = tz.TZDateTime.from(instant, hcm);
      final atTokyo = tz.TZDateTime.from(instant, tokyo);
      final nextHcm = nextSlot(atHcm, nine, at: inZone(hcm));
      final nextTokyo = nextSlot(atTokyo, nine, at: inZone(tokyo));
      expect(nextHcm.toUtc(), DateTime.utc(2026, 11, 6, 14)); // 21:00 hôm nay
      expect(nextTokyo.toUtc(), DateTime.utc(2026, 11, 7, 12)); // 21:00 mai
    });

    test('bay sang múi giờ sớm hơn sau khi đã sao lưu: không chạy lần hai', () {
      // Sao lưu 21:05 Hà Nội (14:05 UTC); tới Tokyo lúc 23:30 cùng tối.
      final handled = DateTime.utc(2026, 11, 6, 14, 5);
      final nowTokyo = tz.TZDateTime(tokyo, 2026, 11, 6, 23, 30);
      expect(
        isBackupDue(
          now: nowTokyo,
          time: nine,
          handledAt: handled,
          at: inZone(tokyo),
        ),
        isFalse,
        reason: 'mốc 21:00 Tokyo (12:00 UTC) trước lần đã chạy',
      );
      // Sang ngày ở Tokyo, qua 21:00: chạy.
      expect(
        isBackupDue(
          now: tz.TZDateTime(tokyo, 2026, 11, 7, 21, 1),
          time: nine,
          handledAt: handled,
          at: inZone(tokyo),
        ),
        isTrue,
      );
    });

    test('giờ mùa hè (DST): không mất mốc, không chạy hai lần', () {
      // London 2026-03-29 01:00 → 02:00; 2026-10-25 02:00 → 01:00.
      const t = BackupTime(1, 30);
      final springBefore = tz.TZDateTime(london, 2026, 3, 28, 23);
      final spring = nextSlot(springBefore, t, at: inZone(london));
      expect(spring.isAfter(springBefore), isTrue);
      expect(
        spring.difference(springBefore),
        lessThanOrEqualTo(const Duration(hours: 4)),
        reason:
            '01:30 không tồn tại ngày 29/3: dời sau khoảng nhảy, vẫn trong đêm',
      );

      final fallBefore = tz.TZDateTime(london, 2026, 10, 24, 23);
      final fall = nextSlot(fallBefore, t, at: inZone(london));
      expect(fall.isAfter(fallBefore), isTrue);
      // Sau khi xử lý mốc 01:30 (dù là lần nào trong hai lần 01:30), giờ lặp
      // lại không tạo mốc mới.
      final afterRepeat = tz.TZDateTime.from(
        fall.toUtc().add(const Duration(hours: 1, minutes: 5)),
        london,
      );
      expect(
        isBackupDue(
          now: afterRepeat,
          time: t,
          handledAt: fall.toUtc().add(const Duration(minutes: 1)),
          at: inZone(london),
        ),
        isFalse,
      );
      // Ngày thường hai mốc liên tiếp cách nhau 24 giờ.
      final a = nextSlot(
        tz.TZDateTime(london, 2026, 6, 1, 12),
        nine,
        at: inZone(london),
      );
      final b = nextSlot(a, nine, at: inZone(london));
      expect(b.difference(a), const Duration(hours: 24));
    });
  });

  group('AutoBackupService (D-026)', () {
    late AppDatabase db;
    late FakeFolder folder;
    late MemorySecretStore secrets;
    late DateTime now;
    late AutoBackupService service;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      folder = FakeFolder();
      secrets = MemorySecretStore();
      now = DateTime(2026, 11, 6, 15, 0);
      service = AutoBackupService(
        db: db,
        folder: folder,
        secrets: secrets,
        clock: () => now,
        encrypt: (json, pw) => encryptBackup(json, pw, iterations: 1000),
      );
      await db.select(db.accounts).get();
    });
    tearDown(() => db.close());

    test(
      'giờ lưu trong SecretStore, không trong bảng settings (D-014)',
      () async {
        await service.enable(
          folder: const PickedFolder(uri: 'content://tree/a'),
          password: 'mat-khau-123',
          time: const BackupTime(22, 15),
        );
        expect(secrets.values[AutoBackupService.timeKey], '22:15');
        expect((await service.state()).time, const BackupTime(22, 15));
        await service.setTime(const BackupTime(6, 0));
        expect((await service.state()).time, const BackupTime(6, 0));
        for (final s in await db.select(db.settings).get()) {
          expect(s.key.contains('auto_backup'), isFalse);
        }
        await service.disable();
        expect(secrets.values, isEmpty);
      },
    );

    test('cấu hình cũ chưa có giờ: 21:00', () async {
      secrets.values[AutoBackupService.enabledKey] = '1';
      expect((await service.state()).time, nine);
      secrets.values[AutoBackupService.timeKey] = 'rác';
      expect((await service.state()).time, nine);
    });

    test('lastAt lưu theo UTC; bản cũ không có múi giờ vẫn đọc được', () async {
      await service.enable(
        folder: const PickedFolder(uri: 'content://tree/a'),
        password: 'mat-khau-123',
      );
      await service.backupNow();
      expect(secrets.values[AutoBackupService.lastAtKey], endsWith('Z'));
      expect((await service.state()).lastAt, now);
      secrets.values[AutoBackupService.lastAtKey] = '2026-11-05T21:04:00.000';
      expect((await service.state()).lastAt, DateTime(2026, 11, 5, 21, 4));
    });

    test('trạng thái: lần tới và đang chờ bù', () async {
      await service.enable(
        folder: const PickedFolder(uri: 'content://tree/a'),
        password: 'mat-khau-123',
      );
      await service.backupNow(); // 15:00
      var s = await service.state();
      expect(s.isDue(now), isFalse);
      expect(s.nextAt(now), DateTime(2026, 11, 6, 21));
      final late = DateTime(2026, 11, 6, 22);
      expect(s.isDue(late), isTrue, reason: 'qua 21:00 chưa chạy: chờ bù');
      expect(s.nextAt(late), DateTime(2026, 11, 7, 21));
      await service.disable();
      s = await service.state();
      expect(s.isDue(late), isFalse, reason: 'tắt thì không chờ gì');
    });

    test('maybeRunIfDue trả kết quả khi chạy, null khi không làm gì', () async {
      expect(await service.maybeRunIfDue(), isNull, reason: 'chưa bật');
      await service.enable(
        folder: const PickedFolder(uri: 'content://tree/a'),
        password: 'mat-khau-123',
      );
      expect(await service.maybeRunIfDue(), AutoBackupResult.ok);
      expect(await service.maybeRunIfDue(), isNull, reason: 'cùng mốc');
      now = DateTime(2026, 11, 6, 21, 3);
      expect(
        await service.maybeRunIfDue(),
        isNull,
        reason: 'dữ liệu không đổi',
      );
      expect(secrets.values[AutoBackupService.lastCheckKey], isNotNull);
      now = DateTime(2026, 11, 7, 21, 3);
      await db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              type: EntryType.expense,
              amount: 1000,
              accountId: 1,
              date: '2026-11-07',
            ),
          );
      folder.failWith = BackupFolderError.folderMissing;
      expect(await service.maybeRunIfDue(), AutoBackupResult.folderMissing);
      folder.failWith = null;
      now = DateTime(2026, 11, 7, 23);
      expect(await service.maybeRunIfDue(), isNull, reason: 'lỗi cũng tính');
    });
  });

  group('chạy nền Android (runScheduledAutoBackup)', () {
    late FakeFolder folder;
    late MemorySecretStore secrets;
    late List<AppDatabase> opened;

    setUp(() {
      folder = FakeFolder();
      secrets = MemorySecretStore();
      opened = [];
    });

    AppDatabase open() {
      final db = AppDatabase(NativeDatabase.memory());
      opened.add(db);
      return db;
    }

    Future<AutoBackupResult?> run(DateTime now) => runScheduledAutoBackup(
      openDatabase: open,
      secrets: secrets,
      folder: folder,
      clock: () => now,
      encrypt: (json, pw) => encryptBackup(json, pw, iterations: 1000),
    );

    Future<void> enable() async {
      final db = AppDatabase(NativeDatabase.memory());
      await AutoBackupService(
        db: db,
        folder: folder,
        secrets: secrets,
        clock: () => DateTime(2026, 11, 5, 21, 2),
      ).enable(
        folder: const PickedFolder(uri: 'content://tree/a'),
        password: 'mat-khau-123',
      );
      // Lần sao lưu đầu (khi bật) đã chạy lúc 21:02 hôm qua.
      secrets.values[AutoBackupService.lastAtKey] = DateTime(
        2026,
        11,
        5,
        21,
        2,
      ).toUtc().toIso8601String();
      secrets.values[AutoBackupService.lastResultKey] = 'failed';
      await db.close();
    }

    test('tắt: không làm gì', () async {
      expect(await run(DateTime(2026, 11, 6, 21)), isNull);
      expect(folder.writes, 0);
    });

    test('báo thức nổ đúng giờ: mở DB, mã hoá, ghi, rồi đóng DB', () async {
      await enable();
      expect(await run(DateTime(2026, 11, 6, 21, 4)), AutoBackupResult.ok);
      expect(folder.files.keys, ['vigon-auto-20261106-2104.vigon']);
      expect(opened, hasLength(1));
      // Đóng rồi thì truy vấn ném lỗi.
      await expectLater(
        opened.single.select(opened.single.accounts).get(),
        throwsA(anything),
      );
    });

    test(
      'báo thức nổ lại cùng tối (hệ thống lặp): không ghi lần hai',
      () async {
        await enable();
        await run(DateTime(2026, 11, 6, 21, 4));
        expect(await run(DateTime(2026, 11, 6, 21, 40)), isNull);
        expect(folder.writes, 1);
      },
    );

    test('nổ sớm hơn giờ chọn (đổi múi giờ): không chạy', () async {
      await enable();
      expect(await run(DateTime(2026, 11, 6, 19)), isNull);
      expect(folder.writes, 0);
    });
  });
}
