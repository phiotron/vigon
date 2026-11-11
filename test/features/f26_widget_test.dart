import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/features/widget/deep_link.dart';
import 'package:vigon/src/features/widget/home_widget_bridge.dart';
import 'package:vigon/src/features/widget/widget_content.dart';
import 'package:vigon/src/features/widget/widget_sync.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../helpers.dart';

/// Bridge giả ghi lại các lệnh ghi (`show`) và xóa (`clear`).
class FakeBridge implements HomeWidgetBridge {
  final calls = <String>[];

  /// Hạn dùng đi kèm mỗi lần `show` (null nếu không có).
  final validUntils = <DateTime?>[];

  @override
  Future<void> show(
    String line, {
    DateTime? validUntil,
    WidgetHero? hero,
  }) async {
    calls.add('show:${plain(line)}');
    validUntils.add(validUntil);
  }

  @override
  Future<void> clear() async => calls.add('clear');

  /// Lần ghi gần nhất, hoặc 'clear'.
  String? get last => calls.isEmpty ? null : calls.last;
  bool get everShown => calls.any((c) => c.startsWith('show:'));
}

String spentOnly(String s) => s;

WidgetContent content({
  required bool show,
  required bool pin,
  String? budget,
  String language = 'vi',
}) => widgetContent(
  showAmounts: show,
  pinEnabled: pin,
  spentFormatted: () => '150.000 ₫',
  budgetFormatted: budget == null ? null : () => budget,
  language: language,
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(VigonApp)));

void mockDeepLink(WidgetTester tester, List<String?> routes) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel(DeepLinkChannel.channelName),
    (call) async => call.method == 'takePending' && routes.isNotEmpty
        ? routes.removeAt(0)
        : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(DeepLinkChannel.channelName),
      null,
    ),
  );
}

void main() {
  group('widgetContent (AC-64)', () {
    test('công tắc tắt: không hiện gì, dù PIN thế nào, dù có ngân sách', () {
      for (final lang in ['vi', 'en']) {
        for (final pin in [false, true]) {
          for (final budget in [null, '1.000.000 ₫']) {
            expect(
              content(show: false, pin: pin, budget: budget, language: lang),
              WidgetContent.hidden,
            );
          }
        }
      }
    });

    test('công tắc bật, PIN tắt: số đã chi, kèm hạn mức nếu có', () {
      expect(
        content(show: true, pin: false).line,
        'Tháng này đã chi 150.000 ₫',
      );
      expect(
        content(show: true, pin: false, budget: '1.000.000 ₫').line,
        'Tháng này đã chi 150.000 ₫ / 1.000.000 ₫',
      );
      expect(
        content(show: true, pin: false, language: 'en').line,
        'Spent this month: 150.000 ₫',
      );
      expect(
        content(
          show: true,
          pin: false,
          budget: '1.000.000 ₫',
          language: 'en',
        ).line,
        'Spent this month: 150.000 ₫ / 1.000.000 ₫',
      );
    });

    test('công tắc bật, PIN bật: chỉ chữ khóa, không tính và không lộ số', () {
      var computed = false;
      String spent() {
        computed = true;
        return '150.000 ₫';
      }

      for (final (lang, text) in [
        ('vi', 'Đã khóa bằng PIN'),
        ('en', 'Locked with PIN'),
      ]) {
        final c = widgetContent(
          showAmounts: true,
          pinEnabled: true,
          spentFormatted: spent,
          budgetFormatted: spent,
          language: lang,
        );
        expect(c.line, text);
        expect(c.line, isNot(contains(RegExp(r'\d'))));
      }
      expect(computed, isFalse);
    });
  });

  test('allowedDeepLinkRoute chỉ nhận màn nhập khoản mới (AC-63)', () {
    expect(
      allowedDeepLinkRoute('/entry/new?type=expense'),
      '/entry/new?type=expense',
    );
    expect(
      allowedDeepLinkRoute('/entry/new?type=income'),
      '/entry/new?type=income',
    );
    expect(allowedDeepLinkRoute(null), isNull);
    expect(allowedDeepLinkRoute('/entry/new?type=transfer'), isNull);
    expect(allowedDeepLinkRoute('/entry/new'), isNull);
    expect(allowedDeepLinkRoute('/settings'), isNull);
    expect(allowedDeepLinkRoute('/entries'), isNull);
    expect(
      allowedDeepLinkRoute('https://x.test/entry/new?type=expense'),
      isNull,
    );
    // D9: chạm phần tên/dòng trạng thái của widget mở màn chính.
    expect(allowedDeepLinkRoute('/'), '/');
    expect(allowedDeepLinkRoute('/?x=1'), isNull);
    expect(allowedDeepLinkRoute('https://x.test/'), isNull);
  });

  testWidgets('kênh bridge gửi đúng lệnh ghi và lệnh xóa', (tester) async {
    final calls = <(String, Object?)>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(MethodChannelHomeWidgetBridge.channelName),
      (call) async {
        calls.add((call.method, call.arguments));
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(MethodChannelHomeWidgetBridge.channelName),
        null,
      ),
    );
    const bridge = MethodChannelHomeWidgetBridge();
    await bridge.show('Đã khóa bằng PIN');
    await bridge.show('Tháng này đã chi 1 ₫', validUntil: DateTime(2026, 12));
    await bridge.clear();
    expect(calls.map((c) => c.$1), ['show', 'show', 'clear']);
    expect(calls[0].$2, {'line': 'Đã khóa bằng PIN', 'validUntil': null});
    expect(calls[1].$2, {
      'line': 'Tháng này đã chi 1 ₫',
      'validUntil': DateTime(2026, 12).millisecondsSinceEpoch,
    });
    expect(calls[2].$2, isNull);
  });

  testWidgets('không có phần Android thì bridge không ném lỗi', (tester) async {
    await tester.runAsync(() async {
      await const MethodChannelHomeWidgetBridge().show('x');
      await const MethodChannelHomeWidgetBridge().clear();
    });
  });

  testWidgets('mặc định không đẩy số nào: chỉ lệnh xóa (AC-64)', (
    tester,
  ) async {
    final bridge = FakeBridge();
    final db = memoryDatabase();
    await pumpApp(
      tester,
      db: db,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 150000,
      categoryId: 1,
    );
    expect(bridge.calls, isNotEmpty);
    expect(bridge.everShown, isFalse);
    expect(bridge.last, 'clear');
    await disposeApp(tester, db);
  });

  testWidgets('bật công tắc, PIN tắt: đẩy số, theo dữ liệu và ngân sách; '
      'tắt công tắc thì xóa (AC-64)', (tester) async {
    final bridge = FakeBridge();
    final db = memoryDatabase();
    await pumpApp(
      tester,
      db: db,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 150000,
      categoryId: 1,
    );
    // Khoản của tháng khác không tính vào.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 999000,
      categoryId: 1,
      date: '2026-10-20',
    );
    final repo = SettingsRepository(db);
    await tester.runAsync(() => repo.setWidgetShowAmounts(true));
    await settle(tester);
    expect(bridge.last, 'show:Tháng này đã chi 150.000 ₫');

    await tester.runAsync(() => repo.setBudget(1000000));
    await settle(tester);
    expect(bridge.last, 'show:Tháng này đã chi 150.000 ₫ / 1.000.000 ₫');

    // Dữ liệu đổi thì đẩy lại.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 50000,
      categoryId: 1,
    );
    expect(bridge.last, 'show:Tháng này đã chi 200.000 ₫ / 1.000.000 ₫');

    // Đổi ngôn ngữ thì đẩy lại bằng ngôn ngữ mới.
    await tester.runAsync(() => repo.setLocaleCode('en'));
    await settle(tester);
    expect(bridge.last, startsWith('show:Spent this month: '));

    await tester.runAsync(() => repo.setWidgetShowAmounts(false));
    await settle(tester);
    expect(bridge.last, 'clear');
    await disposeApp(tester, db);
  });

  testWidgets('bật PIN thì widget không bao giờ nhận số; đổi PIN đẩy lại ngay '
      '(AC-64)', (tester) async {
    final bridge = FakeBridge();
    final secrets = MemorySecretStore();
    final db = memoryDatabase();
    await pumpApp(
      tester,
      db: db,
      secrets: secrets,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 150000,
      categoryId: 1,
    );
    await tester.runAsync(
      () => SettingsRepository(db).setWidgetShowAmounts(true),
    );
    await settle(tester);
    expect(bridge.last, 'show:Tháng này đã chi 150.000 ₫');

    // Bật PIN: số cũ bị thay bằng dòng khóa, và từ đó không còn số nào.
    final container = containerOf(tester);
    await tester.runAsync(
      () => container.read(pinServiceProvider).setPin('2468'),
    );
    container.invalidate(pinEnabledProvider);
    await settle(tester);
    expect(bridge.last, 'show:Đã khóa bằng PIN');
    final afterPin = bridge.calls.length;
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 70000,
      categoryId: 1,
    );
    await tester.runAsync(() => SettingsRepository(db).setBudget(500000));
    await settle(tester);
    expect(
      bridge.calls.skip(afterPin).where((c) => RegExp(r'\d').hasMatch(c)),
      isEmpty,
    );

    // Tắt PIN: số hiện lại, đúng với dữ liệu mới.
    await tester.runAsync(() => container.read(pinServiceProvider).disable());
    container.invalidate(pinEnabledProvider);
    await settle(tester);
    expect(bridge.last, 'show:Tháng này đã chi 220.000 ₫ / 500.000 ₫');
    await disposeApp(tester, db);
  });

  testWidgets('mở app khi PIN đã bật và công tắc bật: không từng đẩy số '
      '(AC-64)', (tester) async {
    final bridge = FakeBridge();
    final secrets = MemorySecretStore();
    await tester.runAsync(() => PinService(secrets).setPin('2468'));
    final db = memoryDatabase();
    await tester.runAsync(
      () => SettingsRepository(db).setWidgetShowAmounts(true),
    );
    await pumpApp(
      tester,
      db: db,
      secrets: secrets,
      overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 150000,
      categoryId: 1,
    );
    expect(bridge.calls, isNotEmpty);
    expect(bridge.calls.every((c) => !RegExp(r'\d').hasMatch(c)), isTrue);
    expect(bridge.last, 'show:Đã khóa bằng PIN');
    await disposeApp(tester, db);
  });

  testWidgets(
    'công tắc trong Cài đặt: mặc định tắt, có cảnh báo, lưu (AC-64)',
    (tester) async {
      final bridge = FakeBridge();
      final db = await pumpApp(
        tester,
        overrides: [homeWidgetBridgeProvider.overrideWithValue(bridge)],
      );
      await tester.tap(find.byTooltip('Cài đặt'));
      await settle(tester);
      final toggle = find.widgetWithText(
        SettingsSwitchRow,
        'Hiện số tiền trên widget',
      );
      await tester.scrollUntilVisible(
        toggle,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(toggle);
      await settle(tester);
      expect(tester.widget<SettingsSwitchRow>(toggle).value, isFalse);
      expect(
        find.text(
          'Ai cầm máy cũng nhìn thấy số này trên màn hình chờ. '
          'Khi đang bật khóa PIN, widget luôn ẩn số.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(Switch)),
      );
      await settle(tester);
      expect(tester.widget<SettingsSwitchRow>(toggle).value, isTrue);
      expect(
        await tester.runAsync(
          () => SettingsRepository(db).watchWidgetShowAmounts().first,
        ),
        isTrue,
      );
      expect(bridge.last, startsWith('show:Tháng này đã chi'));
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(Switch)),
      );
      await settle(tester);
      expect(bridge.last, 'clear');
      await disposeApp(tester, db);
    },
  );

  group('liên kết sâu từ widget (AC-63)', () {
    testWidgets('khởi động nguội với route chi mở màn Khoản chi mới', (
      tester,
    ) async {
      mockDeepLink(tester, ['/entry/new?type=expense']);
      final db = await pumpApp(tester);
      expect(find.text('Khoản chi mới'), findsOneWidget);
      // Back về trang chủ.
      await tester.tap(find.byTooltip('Quay lại'));
      await settle(tester);
      expect(find.text('Khoản chi mới'), findsNothing);
      expect(find.text('Ghi khoản chi đầu tiên'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('route thu mở màn Khoản thu mới', (tester) async {
      mockDeepLink(tester, ['/entry/new?type=income']);
      final db = await pumpApp(tester);
      expect(find.text('Khoản thu mới'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('route lạ bị bỏ, vẫn ở trang chủ', (tester) async {
      mockDeepLink(tester, ['/settings']);
      final db = await pumpApp(tester);
      expect(find.text('Ghi khoản chi đầu tiên'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('app đang chạy nhận route mới qua routeAvailable', (
      tester,
    ) async {
      final routes = <String?>[];
      mockDeepLink(tester, routes);
      final db = await pumpApp(tester);
      expect(find.text('Khoản thu mới'), findsNothing);

      routes.add('/entry/new?type=income');
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        DeepLinkChannel.channelName,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('routeAvailable'),
        ),
        (_) {},
      );
      await settle(tester);
      expect(find.text('Khoản thu mới'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('PIN bật: hiện màn khóa trước, mở khóa xong mới vào màn nhập', (
      tester,
    ) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      mockDeepLink(tester, ['/entry/new?type=expense']);
      final db = await pumpApp(tester, secrets: secrets);
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.text('Khoản chi mới').hitTestable(), findsNothing);

      for (final d in '2468'.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await settle(tester);
      expect(find.text('Nhập mã PIN'), findsNothing);
      expect(find.text('Khoản chi mới'), findsOneWidget);
      await disposeApp(tester, db);
    });
  });

  group('tài nguyên Android của widget (AC-63)', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    test('receiver khai báo, không xuất ra ngoài, không thêm quyền', () {
      expect(manifest, contains('android:name=".VigonWidgetProvider"'));
      expect(manifest, contains('android.appwidget.action.APPWIDGET_UPDATE'));
      expect(manifest, contains('@xml/vigon_widget_info'));
      final receiver = RegExp(r'<receiver[^>]*>')
          .firstMatch(manifest)!
          .group(0)!;
      expect(receiver, contains('android:exported="false"'));
      // Widget không thêm quyền nào; chỉ còn hai quyền thông báo của F-25 và
      // INTERNET để tải tỉ giá (D-025). Bỏ qua dòng GỠ quyền (tools:node="remove").
      final perms = RegExp(r'<uses-permission[^>]*>')
          .allMatches(manifest)
          .map((m) => m.group(0)!)
          .where((tag) => !tag.contains('tools:node="remove"'))
          .map(
            (tag) =>
                RegExp(r'android:name="([^"]+)"').firstMatch(tag)!.group(1)!,
          )
          .toSet();
      expect(
        perms.difference({
          'android.permission.INTERNET',
          'android.permission.POST_NOTIFICATIONS',
          'android.permission.RECEIVE_BOOT_COMPLETED',
          'android.permission.SCHEDULE_EXACT_ALARM', // D-045
        }),
        isEmpty,
      );
    });

    test(
      'bố cục: hai nút có mô tả đọc màn hình, phần số tiền ẩn mặc định',
      () {
        final layout = File('android/app/src/main/res/layout/vigon_widget.xml')
            .readAsStringSync();
        expect(layout, contains('@string/widget_expense_desc'));
        expect(layout, contains('@string/widget_income_desc'));
        // Nút 2×2 cao ≥ 60 (mockup v4 EXT-01), vùng chạm ≥ 48.
        expect(layout, contains('android:minHeight="60dp"'));
        // Số tiền chỉ hiện khi Dart cho phép (AC-64): mặc định ẩn.
        final amount = RegExp(
          r'<TextView\s+android:id="@\+id/widget_amount"[^>]*>',
        ).firstMatch(layout)!.group(0)!;
        expect(amount, contains('android:visibility="gone"'));
        String res(String dir) =>
            File('android/app/src/main/res/$dir/widget_strings.xml')
                .readAsStringSync();
        expect(res('values-vi'), contains('>Thêm khoản chi<'));
        expect(res('values-vi'), contains('>Thêm khoản thu<'));
        expect(res('values'), contains('>Add expense<'));
      },
    );

    test('cỡ tối thiểu 2x2 (110dp), cập nhật 30 phút để bỏ số cũ', () {
      final info = File('android/app/src/main/res/xml/vigon_widget_info.xml')
          .readAsStringSync();
      expect(info, contains('android:minWidth="110dp"'));
      expect(info, contains('android:minHeight="110dp"'));
      expect(info, contains('android:updatePeriodMillis="1800000"'));
    });
  });
}
