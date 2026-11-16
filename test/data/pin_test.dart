import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/providers.dart';

void main() {
  group('mã PIN (AC-31, AC-33)', () {
    test('chỉ lưu muối và mã băm, không lưu mã', () async {
      final store = MemorySecretStore();
      final pin = PinService(store);
      expect(await pin.isEnabled(), isFalse);
      await pin.setPin('2468');
      expect(await pin.isEnabled(), isTrue);
      expect(store.values.values.any((v) => v.contains('2468')), isFalse);
      expect(store.values.keys.toSet(), {'pin_hash', 'pin_salt'});
    });

    test('đúng mã thì mở, sai mã thì không', () async {
      final pin = PinService(MemorySecretStore());
      await pin.setPin('2468');
      expect(await pin.verify('2468'), isTrue);
      expect(await pin.verify('8642'), isFalse);
      expect(await pin.verify(''), isFalse);
    });

    test('hai lần đặt cùng mã ra mã băm khác nhau nhờ muối', () async {
      final a = MemorySecretStore(), b = MemorySecretStore();
      await PinService(a).setPin('1111');
      await PinService(b).setPin('1111');
      expect(a.values['pin_hash'], isNot(b.values['pin_hash']));
    });

    test('mã không phải 4 số thì từ chối', () async {
      final pin = PinService(MemorySecretStore());
      expect(() => pin.setPin('123'), throwsArgumentError);
      expect(() => pin.setPin('12a4'), throwsArgumentError);
    });

    test('tắt khóa xóa mã băm', () async {
      final store = MemorySecretStore();
      final pin = PinService(store);
      await pin.setPin('1234');
      await pin.disable();
      expect(store.values, isEmpty);
      expect(await pin.verify('1234'), isFalse);
    });
  });

  group('đếm lần sai và khoá tạm (D-007)', () {
    final start = DateTime(2026, 11, 16, 9);
    late MemorySecretStore store;
    late PinService pin;

    setUp(() async {
      store = MemorySecretStore();
      pin = PinService(store);
      await pin.setPin('2468');
    });

    test('sai 4 lần chưa khoá; lần thứ 5 khoá 30 giây', () async {
      for (var i = 1; i <= 4; i++) {
        final r = await pin.verifyAttempt('0000', start);
        expect(r.ok, isFalse);
        expect(r.failures, i);
        expect(r.lockedUntil, isNull, reason: 'lần $i');
      }
      final fifth = await pin.verifyAttempt('0000', start);
      expect(fifth.failures, 5);
      expect(fifth.lockedUntil, start.add(const Duration(seconds: 30)));
      expect(fifth.isLockedAt(start.add(const Duration(seconds: 29))), isTrue);
      expect(fifth.isLockedAt(start.add(const Duration(seconds: 30))), isFalse);
    });

    test(
      'đang khoá thì mã đúng cũng không mở; hết khoá mở và đặt lại',
      () async {
        for (var i = 0; i < 5; i++) {
          await pin.verifyAttempt('0000', start);
        }
        final during = await pin.verifyAttempt(
          '2468',
          start.add(const Duration(seconds: 10)),
        );
        expect(during.ok, isFalse);
        expect(during.failures, 5);
        expect(
          during.isLockedAt(start.add(const Duration(seconds: 10))),
          isTrue,
        );

        final after = await pin.verifyAttempt(
          '2468',
          start.add(const Duration(seconds: 31)),
        );
        expect(after.ok, isTrue);
        final cleared = await pin.currentAttempt(
          start.add(const Duration(seconds: 31)),
        );
        expect(cleared.failures, 0);
        expect(cleared.lockedUntil, isNull);

        // Đúng mã xong thì sai lại tính từ đầu, chưa khoá.
        final wrong = await pin.verifyAttempt('0000', start);
        expect(wrong.failures, 1);
        expect(wrong.lockedUntil, isNull);
      },
    );

    test('mỗi lần sai sau khi hết khoá tăng mức khoá', () async {
      var now = start;
      for (var i = 0; i < 5; i++) {
        await pin.verifyAttempt('0000', now);
      }
      now = now.add(const Duration(seconds: 31));
      final sixth = await pin.verifyAttempt('0000', now);
      expect(sixth.lockedUntil, now.add(const Duration(minutes: 1)));

      now = now.add(const Duration(minutes: 1, seconds: 1));
      final seventh = await pin.verifyAttempt('0000', now);
      expect(seventh.lockedUntil, now.add(const Duration(minutes: 5)));

      now = now.add(const Duration(minutes: 5, seconds: 1));
      final eighth = await pin.verifyAttempt('0000', now);
      expect(eighth.lockedUntil, now.add(const Duration(minutes: 15)));

      now = now.add(const Duration(minutes: 15, seconds: 1));
      final ninth = await pin.verifyAttempt('0000', now);
      expect(ninth.lockedUntil, now.add(const Duration(minutes: 15)));
    });

    test('bộ đếm ở bộ nhớ an toàn: mở lại app vẫn còn khoá', () async {
      for (var i = 0; i < 5; i++) {
        await pin.verifyAttempt('0000', start);
      }
      final reopened = PinService(store);
      final state = await reopened.currentAttempt(
        start.add(const Duration(seconds: 5)),
      );
      expect(state.isLockedAt(start.add(const Duration(seconds: 5))), isTrue);
      expect(state.lockedUntil, start.add(const Duration(seconds: 30)));
    });

    test('tắt PIN xoá bộ đếm; đổi PIN cũng đặt lại', () async {
      for (var i = 0; i < 5; i++) {
        await pin.verifyAttempt('0000', start);
      }
      await pin.disable();
      expect(store.values, isEmpty);

      await pin.setPin('1357');
      final r = await pin.verifyAttempt('0000', start);
      expect(r.failures, 1);
      expect(r.lockedUntil, isNull);
    });

    test(
      'mốc thời gian khoá: 5 → 30 giây, 6 → 1 phút, 7 → 5 phút, 8+ → 15 phút',
      () {
        expect(PinService.lockDuration(4), Duration.zero);
        expect(PinService.lockDuration(5), const Duration(seconds: 30));
        expect(PinService.lockDuration(6), const Duration(minutes: 1));
        expect(PinService.lockDuration(7), const Duration(minutes: 5));
        expect(PinService.lockDuration(8), const Duration(minutes: 15));
        expect(PinService.lockDuration(20), const Duration(minutes: 15));
      },
    );
  });

  group('khóa lại sau hơn 1 phút ở nền (AC-32)', () {
    late DateTime now;
    late MemorySecretStore store;

    Future<ProviderContainer> start() async {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          secretStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(c.dispose);
      c.listen(lockProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    setUp(() {
      now = DateTime(2026, 11, 3, 9);
      store = MemorySecretStore();
    });

    test('mở app là khóa; nhập đúng thì mở', () async {
      await PinService(store).setPin('1234');
      final c = await start();
      expect(c.read(lockProvider), AppLockState.locked);
      expect(await c.read(lockProvider.notifier).unlock('0000'), isFalse);
      expect(c.read(lockProvider), AppLockState.locked);
      expect(await c.read(lockProvider.notifier).unlock('1234'), isTrue);
      expect(c.read(lockProvider), AppLockState.unlocked);
    });

    test('ra nền dưới 1 phút không khóa, hơn 1 phút thì khóa', () async {
      await PinService(store).setPin('1234');
      final c = await start();
      final lock = c.read(lockProvider.notifier);
      await lock.unlock('1234');

      lock.onHidden();
      now = now.add(const Duration(seconds: 50));
      await lock.onResumed();
      expect(c.read(lockProvider), AppLockState.unlocked);

      lock.onHidden();
      now = now.add(const Duration(seconds: 61));
      await lock.onResumed();
      expect(c.read(lockProvider), AppLockState.locked);
    });

    test('không bật PIN thì không bao giờ khóa', () async {
      final c = await start();
      expect(c.read(lockProvider), AppLockState.unlocked);
      c.read(lockProvider.notifier).onHidden();
      now = now.add(const Duration(hours: 1));
      await c.read(lockProvider.notifier).onResumed();
      expect(c.read(lockProvider), AppLockState.unlocked);
    });
  });
}
