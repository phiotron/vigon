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
