import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';

import '../helpers.dart';

Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(TextButton, d));
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  testWidgets(
    'bật PIN thì mở app phải nhập mã; sai báo lỗi, đúng thì vào (AC-32)',
    (tester) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsNothing);

      await enterPin(tester, '1111');
      expect(find.text('Sai mã PIN'), findsOneWidget);
      await enterPin(tester, '2468');
      expect(find.text('Nhập mã PIN'), findsNothing);
      expect(find.text('Bấm − để ghi khoản chi đầu tiên'), findsOneWidget);
      await disposeApp(tester, db);
    },
  );

  testWidgets(
    'quên mã: xác nhận hai bước thì xóa dữ liệu và vào lại được (AC-34)',
    (tester) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = memoryDatabase();
      await pumpApp(tester, db: db, secrets: secrets);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 1000,
        categoryId: 1,
      );

      await tester.tap(find.text('Quên mã'));
      await settle(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Xóa toàn bộ dữ liệu'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await settle(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Xóa toàn bộ dữ liệu'),
      );
      await settle(tester);

      expect(find.text('Nhập mã PIN'), findsNothing);
      expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
      expect(
        await tester.runAsync(() => PinService(secrets).isEnabled()),
        isFalse,
      );
      await disposeApp(tester, db);
    },
  );

  testWidgets('đặt PIN trong Cài đặt: nhập hai lần phải khớp (AC-31)', (
    tester,
  ) async {
    final secrets = MemorySecretStore();
    final db = await pumpApp(tester, secrets: secrets);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Khóa bằng mã PIN'), 200);
    await tester.tap(find.text('Khóa bằng mã PIN'));
    await settle(tester);
    expect(find.text('Đặt mã PIN 4 số'), findsOneWidget);
    await enterPin(tester, '1357');
    expect(find.text('Nhập lại mã PIN'), findsOneWidget);
    await enterPin(tester, '1358');
    expect(find.text('Hai lần nhập không khớp'), findsOneWidget);
    await enterPin(tester, '1357');
    await enterPin(tester, '1357');
    expect(
      await tester.runAsync(() => PinService(secrets).verify('1357')),
      isTrue,
    );
    await disposeApp(tester, db);
  });

  testWidgets('bộ nhớ an toàn lỗi thì vẫn hiện màn khóa, không kẹt màn trắng', (
    tester,
  ) async {
    final db = await pumpApp(tester, secrets: _BrokenSecretStore());
    expect(find.text('Nhập mã PIN'), findsOneWidget);
    expect(find.text('Quên mã'), findsOneWidget);
    // Nhập mã không mở khóa được và không ném lỗi ra ngoài.
    await enterPin(tester, '1234');
    expect(find.text('Nhập mã PIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester, db);
  });
}

class _BrokenSecretStore implements SecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('keystore lỗi');

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
