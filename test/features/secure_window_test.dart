import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/secure_window.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../helpers.dart';

/// Ghi lại các lệnh gửi tới kênh `vigon/secure`.
List<Object?> mockSecureChannel(
  WidgetTester tester, {
  Future<Object?> Function(MethodCall call)? handler,
}) {
  final calls = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel(SecureWindow.channelName),
    (call) async {
      calls.add((call.method, call.arguments));
      return handler?.call(call);
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(SecureWindow.channelName),
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('cài đặt che nội dung: mặc định tắt, lưu và đọc lại (AC-56)', (
    tester,
  ) async {
    final db = memoryDatabase();
    final repo = SettingsRepository(db);
    expect(await tester.runAsync(repo.readSecureWindow), isFalse);
    await tester.runAsync(() => repo.setSecureWindow(true));
    expect(await tester.runAsync(repo.readSecureWindow), isTrue);
    expect(await tester.runAsync(() => repo.watchSecureWindow().first), isTrue);
    await tester.runAsync(() => repo.setSecureWindow(false));
    expect(await tester.runAsync(repo.readSecureWindow), isFalse);
    await tester.runAsync(db.close);
  });

  testWidgets('dịch vụ gọi kênh đúng lệnh và tham số (AC-56)', (tester) async {
    final calls = mockSecureChannel(tester);
    const service = SecureWindow();
    await service.setSecure(true);
    await service.setSecure(false);
    expect(calls, [('setSecure', true), ('setSecure', false)]);
  });

  testWidgets('không có kênh hoặc kênh báo lỗi thì không ném lỗi (AC-56)', (
    tester,
  ) async {
    // Chưa có handler: MissingPluginException.
    await tester.runAsync(() => const SecureWindow().setSecure(true));
    mockSecureChannel(
      tester,
      handler: (_) async => throw PlatformException(code: 'bad_args'),
    );
    await tester.runAsync(() => const SecureWindow().setSecure(true));
  });

  testWidgets('công tắc đổi giá trị, lưu lại và gọi kênh (AC-56)', (
    tester,
  ) async {
    final calls = mockSecureChannel(tester);
    final db = await pumpApp(tester);
    // Khi mở app theo giá trị đã lưu (mặc định tắt).
    expect(calls, contains(('setSecure', false)));
    calls.clear();

    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    final toggle = find.widgetWithText(
      SettingsSwitchRow,
      'Che nội dung khi chuyển app',
    );
    await tester.scrollUntilVisible(
      toggle,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(toggle);
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(toggle).value, isFalse);

    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(Switch)),
    );
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(toggle).value, isTrue);
    expect(calls.last, ('setSecure', true));
    expect(
      await tester.runAsync(() => SettingsRepository(db).readSecureWindow()),
      isTrue,
    );

    await tester.tap(
      find.descendant(of: toggle, matching: find.byType(Switch)),
    );
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(toggle).value, isFalse);
    expect(calls.last, ('setSecure', false));
    await disposeApp(tester, db);
  });

  testWidgets('mở app với giá trị đã lưu bật thì gọi kênh với true (AC-56)', (
    tester,
  ) async {
    final calls = mockSecureChannel(tester);
    final db = memoryDatabase();
    await tester.runAsync(() => SettingsRepository(db).setSecureWindow(true));
    await pumpApp(tester, db: db);
    expect(calls, contains(('setSecure', true)));
    await disposeApp(tester, db);
  });
}
