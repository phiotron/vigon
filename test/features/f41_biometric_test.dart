import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/features/lock/biometric.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../fake_biometric.dart';
import '../helpers.dart';

/// F-41 Mở khoá bằng vân tay / Face ID (AC-119, AC-120), với lớp sinh trắc giả.
void main() {
  group('loại và tính khả dụng (AC-119)', () {
    test('Android: chỉ sinh trắc mạnh, luôn gọi là vân tay', () {
      final strong = biometricAvailabilityOf([
        BiometricType.strong,
        BiometricType.weak,
      ], TargetPlatform.android);
      expect(strong.available, isTrue);
      expect(strong.kind, BiometricKind.fingerprint);
      expect(
        biometricAvailabilityOf([
          BiometricType.weak,
        ], TargetPlatform.android).available,
        isFalse,
        reason: 'chỉ có sinh trắc yếu (khuôn mặt 2D) coi như không có',
      );
      expect(
        biometricAvailabilityOf([], TargetPlatform.android).available,
        isFalse,
      );
    });

    test('iPhone: Face ID hoặc Touch ID theo máy', () {
      expect(
        biometricAvailabilityOf([BiometricType.face], TargetPlatform.iOS).kind,
        BiometricKind.faceId,
      );
      expect(
        biometricAvailabilityOf([
          BiometricType.fingerprint,
        ], TargetPlatform.iOS).kind,
        BiometricKind.touchId,
      );
      expect(
        biometricAvailabilityOf([], TargetPlatform.iOS).available,
        isFalse,
      );
    });
  });

  group('cờ sinh trắc gắn với PIN', () {
    test('chưa có PIN thì không bật được; tắt PIN thì tắt luôn', () async {
      final store = MemorySecretStore();
      final pin = PinService(store);
      final settings = BiometricSettings(store, pin);
      await settings.setEnabled(true);
      expect(await settings.isEnabled(), isFalse);
      await pin.setPin('2468');
      await settings.setEnabled(true);
      expect(await settings.isEnabled(), isTrue);
      // Tắt PIN, "Xoá toàn bộ dữ liệu" và cài lại iOS đều đi qua disable().
      await pin.disable();
      expect(store.values, isNot(contains(PinService.biometricKey)));
      await pin.setPin('1357');
      expect(
        await settings.isEnabled(),
        isFalse,
        reason: 'bật lại PIN không tự bật lại sinh trắc',
      );
    });
  });

  group('Cài đặt → Bảo mật (AC-119)', () {
    testWidgets('chưa bật PIN thì không có công tắc sinh trắc', (tester) async {
      final db = await pumpApp(
        tester,
        overrides: [
          biometricAuthProvider.overrideWithValue(FakeBiometricAuth()),
        ],
      );
      await goTo(tester, '/settings');
      expect(find.text('Mở khoá bằng vân tay'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets('bật phải xác thực một lần; huỷ thì vẫn tắt', (tester) async {
      final secrets = MemorySecretStore();
      await PinService(secrets).setPin('2468');
      final fake = FakeBiometricAuth(result: false);
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      // Mở khoá màn PIN bằng mã (sinh trắc chưa bật nên không tự hỏi).
      expect(fake.prompts, isEmpty);
      for (final d in '2468'.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await settle(tester);
      final row = find.text('Mở khoá bằng vân tay');
      await _openSettingsAt(tester, row);
      await tester.tap(row);
      await settle(tester);
      expect(fake.prompts, hasLength(1));
      expect(
        tester.widget<Switch>(_switchOf(row)).value,
        isFalse,
        reason: 'xác thực huỷ/sai thì công tắc ở lại tắt',
      );
      fake.result = true;
      await tester.tap(row);
      await settle(tester);
      expect(fake.prompts, hasLength(2));
      expect(tester.widget<Switch>(_switchOf(row)).value, isTrue);
      expect(secrets.values[PinService.biometricKey], '1');
      await disposeApp(tester, db);
    });

    testWidgets('máy không có sinh trắc mạnh: công tắc tắt kèm lý do', (
      tester,
    ) async {
      final secrets = MemorySecretStore();
      await PinService(secrets).setPin('2468');
      final fake = FakeBiometricAuth(available: false);
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      for (final d in '2468'.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await settle(tester);
      final reason = find.text(
        'Máy không có hoặc chưa đăng ký sinh trắc học mạnh',
      );
      await _openSettingsAt(tester, reason);
      expect(reason, findsOneWidget);
      final row = find.text('Mở khoá bằng vân tay');
      expect(tester.widget<Switch>(_switchOf(row)).onChanged, isNull);
      await tester.tap(row);
      await settle(tester);
      expect(fake.prompts, isEmpty);
      await disposeApp(tester, db);
    });
  });

  group('màn khoá (AC-120)', () {
    Future<MemorySecretStore> pinWithBiometric() async {
      final secrets = MemorySecretStore();
      final pin = PinService(secrets);
      await pin.setPin('2468');
      await BiometricSettings(secrets, pin).setEnabled(true);
      return secrets;
    }

    testWidgets('tự mở hộp sinh trắc; đúng thì vào app', (tester) async {
      final secrets = await pinWithBiometric();
      final fake = FakeBiometricAuth();
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      expect(fake.prompts, hasLength(1));
      expect(fake.prompts.single.reason, 'Mở khoá Ví Gọn');
      expect(fake.prompts.single.cancel, 'Dùng mã PIN');
      expect(find.text('Nhập mã PIN'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets('huỷ/sai: ở lại màn PIN, PIN vẫn dùng được, nút thử lại', (
      tester,
    ) async {
      final secrets = await pinWithBiometric();
      final fake = FakeBiometricAuth(result: false);
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      expect(fake.prompts, hasLength(1));
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      final retry = find.text('Mở bằng sinh trắc học');
      expect(retry, findsOneWidget);
      // Thử lại bằng nút, lần này đúng.
      fake.result = true;
      await tester.tap(retry);
      await settle(tester);
      expect(fake.prompts, hasLength(2));
      expect(find.text('Nhập mã PIN'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets('huỷ sinh trắc rồi nhập PIN đúng vẫn vào app', (tester) async {
      final secrets = await pinWithBiometric();
      final fake = FakeBiometricAuth(result: false);
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      for (final d in '2468'.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await settle(tester);
      expect(find.text('Nhập mã PIN'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets('máy mất sinh trắc (xoá vân tay): không hỏi, không có nút', (
      tester,
    ) async {
      final secrets = await pinWithBiometric();
      final fake = FakeBiometricAuth(available: false);
      final db = await pumpApp(
        tester,
        secrets: secrets,
        overrides: [biometricAuthProvider.overrideWithValue(fake)],
      );
      expect(fake.prompts, isEmpty);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.text('Mở bằng sinh trắc học'), findsNothing);
      await disposeApp(tester, db);
    });
  });
}

/// Mở Cài đặt và cuộn tới [target].
Future<void> _openSettingsAt(WidgetTester tester, Finder target) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await settle(tester);
  await tester.ensureVisible(target);
  await settle(tester);
}

/// Công tắc của hàng cài đặt có tiêu đề [title].
Finder _switchOf(Finder title) => find.descendant(
  of: find.ancestor(of: title, matching: find.byType(SettingsSwitchRow)),
  matching: find.byType(Switch),
);
