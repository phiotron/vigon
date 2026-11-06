import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/email_mailbox_form.dart';
import 'package:vigon/src/import/mail/bank_senders.dart';
import 'package:vigon/src/import/mail/imap_gateway.dart';
import 'package:vigon/src/import/mail/mail_check_scheduler.dart';
import 'package:vigon/src/import/mail/mail_provider.dart';
import 'package:vigon/src/import/mail/mail_providers.dart';
import 'package:vigon/src/import/mail/mailbox_service.dart';
import 'package:vigon/src/import/mail/mailbox_store.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../helpers.dart';
import '../import/mail/fake_imap.dart';

const _address = 'me@gmail.com';
const _password = 'abcd efgh ijkl mnop';
const _bank = 'thongbao@mbbank-test.vn';

class _FakeScheduler implements MailCheckScheduler {
  final calls = <String>[];

  @override
  Future<void> enable() async => calls.add('enable');

  @override
  Future<void> disable() async => calls.add('disable');
}

class _Rig {
  final secrets = MemorySecretStore();
  final marker = MemoryInstallMarker();
  final server = FakeImapServer(passwords: {_address: _password});
  final scheduler = _FakeScheduler();

  List get overrides => [
    imapConnectorProvider.overrideWithValue(server),
    mailInstallMarkerProvider.overrideWithValue(marker),
    mailCheckSchedulerProvider.overrideWithValue(scheduler),
    senderAllowlistProvider.overrideWithValue(
      const SenderAllowlist([
        BankSource(id: 'mb', name: 'MB Bank', senders: {_bank}),
      ]),
    ),
  ];

  MailboxService service() => MailboxService(
    store: MailboxStore(secrets, marker: marker),
    connector: server,
    senders: const SenderAllowlist([
      BankSource(id: 'mb', name: 'MB Bank', senders: {_bank}),
    ]),
    clock: () => testToday,
  );
}

Future<void> _go(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // Danh sách dựng lười: kéo tới khi phần tử được dựng.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

/// Thao tác IMAP giả chạy trong `runAsync` qua nút Kết nối: chờ thêm vài vòng.
Future<void> _connect(WidgetTester tester, String label) async {
  await _tap(tester, find.widgetWithText(FilledButton, label));
  for (var i = 0; i < 3; i++) {
    await settle(tester);
  }
}

void main() {
  testWidgets('Cài đặt → Nhập từ email ngân hàng: màn giải thích trước, rồi '
      'thêm Gmail; sai mật khẩu báo rõ, đúng thì "Đã kết nối" (AC-78, AC-79)', (
    tester,
  ) async {
    final rig = _Rig();
    final db = await pumpApp(
      tester,
      secrets: rig.secrets,
      overrides: rig.overrides,
    );
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    final entry = find.widgetWithText(
      SettingsNavRow,
      'Nhập từ email ngân hàng',
    );
    await tester.scrollUntilVisible(entry, 200);
    expect(
      find.descendant(of: entry, matching: find.text('Chưa có hộp thư')),
      findsOneWidget,
    );
    await _tap(tester, entry);

    // Màn giải thích (AC-78).
    expect(find.text('Ghi khoản chi từ email biên lai'), findsOneWidget);
    expect(
      find.text('Chỉ trên máy này: nội dung email không được gửi đi đâu.'),
      findsOneWidget,
    );
    expect(
      find.text('Không sửa, không xoá, không đánh dấu đã đọc thư nào.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('không phải mật khẩu đăng nhập chính'),
      findsOneWidget,
    );
    expect(find.text('Hiện chỉ hỗ trợ MB Bank.'), findsOneWidget);
    await _tap(tester, find.text('Thêm hộp thư'));
    expect(await rig.secrets.read(MailboxStore.introKey), '1');

    // Form: ba nhà cung cấp, hướng dẫn đổi theo nhà cung cấp.
    expect(find.byType(EmailMailboxForm), findsOneWidget);
    for (final p in ['Gmail', 'Yahoo', 'iCloud']) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.textContaining('Xác minh 2 bước'), findsOneWidget);
    await _tap(tester, find.text('Yahoo'));
    expect(find.textContaining('Bảo mật tài khoản Yahoo'), findsOneWidget);
    await _tap(tester, find.text('Gmail'));
    expect(
      find.widgetWithText(OutlinedButton, 'Mở trang tạo mật khẩu ứng dụng'),
      findsOneWidget,
    );

    // Bỏ trống → lỗi dưới ô, không kết nối.
    await _connect(tester, 'Kết nối');
    expect(find.text('Nhập đúng địa chỉ email'), findsOneWidget);
    expect(find.text('Nhập mật khẩu ứng dụng'), findsOneWidget);
    expect(rig.server.opens, 0);

    await tester.enterText(
      find.widgetWithText(TextField, 'Địa chỉ email'),
      _address,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Mật khẩu ứng dụng'),
      'sai-mat-khau',
    );
    // Ô mật khẩu che chữ, không gợi ý bàn phím.
    final pw = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Mật khẩu ứng dụng'),
    );
    expect(pw.obscureText, isTrue);
    expect(pw.enableSuggestions, isFalse);
    await _connect(tester, 'Kết nối');
    expect(find.text('Sai địa chỉ hoặc mật khẩu ứng dụng'), findsOneWidget);
    expect(await rig.service().mailboxes(), isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Mật khẩu ứng dụng'),
      _password,
    );
    await _connect(tester, 'Kết nối');
    expect(find.byType(EmailMailboxForm), findsNothing);
    expect(rig.server.hostsUsed.toSet(), {'imap.gmail.com'});
    expect(find.text(_address), findsOneWidget);
    expect(find.text('Gmail'), findsOneWidget);
    expect(find.textContaining('Đã kết nối'), findsWidgets);
    expect(find.textContaining('khoảng mỗi giờ khi app đóng'), findsOneWidget);
    // Mật khẩu chỉ ở khoá riêng trong Keystore giả.
    final withPassword = [
      for (final e in rig.secrets.values.entries)
        if (e.value.contains(_password)) e.key,
    ];
    expect(withPassword, [MailboxStore.passwordKey('m0')]);
    await disposeApp(tester, db);
  });

  for (final (kind, text) in [
    (MailErrorKind.imapDisabled, 'Hộp thư chưa bật IMAP'),
    (MailErrorKind.noNetwork, 'Không có mạng'),
  ]) {
    testWidgets('thêm hộp thư lỗi ${kind.name} → "$text"', (tester) async {
      final rig = _Rig()..server.failOpen = MailException(kind);
      await rig.secrets.write(MailboxStore.introKey, '1');
      final db = await pumpApp(
        tester,
        secrets: rig.secrets,
        overrides: rig.overrides,
      );
      await _go(tester, '/email-import/add');
      await tester.enterText(
        find.widgetWithText(TextField, 'Địa chỉ email'),
        _address,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu ứng dụng'),
        _password,
      );
      await _connect(tester, 'Kết nối');
      expect(find.text(text), findsOneWidget);
      expect(rig.secrets.values.keys, [MailboxStore.introKey]);
      await disposeApp(tester, db);
    });
  }

  testWidgets('hộp thư sai mật khẩu: báo lỗi + dừng, nhập lại mật khẩu thì '
      'chạy lại; xoá hộp thư xoá mật khẩu (AC-79, AC-82)', (tester) async {
    final rig = _Rig();
    await tester.runAsync(() async {
      await rig.service().add(
        provider: MailProvider.gmail,
        address: _address,
        password: _password,
      );
      // Người dùng đổi mật khẩu ứng dụng ở Google: lần kiểm sau sai.
      rig.server.passwords[_address] = 'moi';
      await rig.service().checkAll(MailCheckTrigger.manual);
    });
    final db = await pumpApp(
      tester,
      secrets: rig.secrets,
      overrides: rig.overrides,
    );
    await _go(tester, '/email-import');
    expect(
      find.textContaining('Sai địa chỉ hoặc mật khẩu ứng dụng'),
      findsOneWidget,
    );
    expect(find.textContaining('Đã dừng kiểm thư'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilledButton, 'Nhập lại mật khẩu'));
    expect(find.text('$_address · Gmail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Địa chỉ email'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'Mật khẩu ứng dụng'),
      'moi',
    );
    await _connect(tester, 'Lưu và kết nối lại');
    expect(find.textContaining('Đã dừng kiểm thư'), findsNothing);
    expect(await rig.secrets.read(MailboxStore.passwordKey('m0')), 'moi');

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Xoá hộp thư'));
    expect(find.text('Xoá hộp thư?'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Xoá hộp thư'));
    expect(find.text(_address), findsNothing);
    expect(await rig.secrets.read(MailboxStore.passwordKey('m0')), isNull);
    expect(await rig.secrets.read(MailboxStore.boxesKey), isNull);
    await disposeApp(tester, db);
  });

  testWidgets('đủ 3 hộp thư thì không còn nút Thêm; email MB không đọc được '
      'hiện bộ đếm (AC-78, AC-85)', (tester) async {
    final rig = _Rig();
    final now = testToday.toUtc().toIso8601String();
    await rig.secrets.write(MailboxStore.boxesKey, '''[
      {"id":"m0","provider":"gmail","address":"a@gmail.com","connectedAt":"$now","uidValidity":1,"lastUid":0,"unreadable":2},
      {"id":"m1","provider":"yahoo","address":"b@yahoo.com","connectedAt":"$now","uidValidity":1,"lastUid":0},
      {"id":"m2","provider":"icloud","address":"c@icloud.com","connectedAt":"$now","uidValidity":1,"lastUid":0,"lastError":"noNetwork","lastCheckAt":"$now"}
    ]''');
    final db = await pumpApp(
      tester,
      secrets: rig.secrets,
      overrides: rig.overrides,
    );
    await _go(tester, '/email-import');
    expect(find.text('2 email MB không đọc được'), findsOneWidget);
    expect(find.textContaining('Không có mạng'), findsOneWidget);
    expect(find.widgetWithText(SettingsNavRow, 'Thêm hộp thư'), findsNothing);
    expect(find.textContaining('Đã đủ 3 hộp thư'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Xóa toàn bộ dữ liệu xoá hộp thư, mật khẩu ứng dụng và tắt '
      'kiểm thư nền (AC-123)', (tester) async {
    final rig = _Rig();
    await tester.runAsync(
      () => rig.service().add(
        provider: MailProvider.gmail,
        address: _address,
        password: _password,
      ),
    );
    final db = await pumpApp(
      tester,
      secrets: rig.secrets,
      overrides: rig.overrides,
    );
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    final row = find.widgetWithText(SettingsNavRow, 'Xóa toàn bộ dữ liệu');
    await tester.scrollUntilVisible(row, 300);
    await _tap(tester, row);
    await _tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Xóa toàn bộ dữ liệu'),
    );
    for (final key in MailboxStore.allKeys) {
      expect(await rig.secrets.read(key), isNull, reason: key);
    }
    expect(rig.secrets.values.values, isNot(contains(_password)));
    expect(rig.scheduler.calls.last, 'disable');
    await disposeApp(tester, db);
  });

  testWidgets('đường dẫn ?id lạ thì là màn thêm mới, không lỗi', (
    tester,
  ) async {
    final rig = _Rig();
    final db = await pumpApp(
      tester,
      secrets: rig.secrets,
      overrides: rig.overrides,
    );
    await _go(tester, '/email-import/add?id=../../x');
    expect(find.widgetWithText(TextField, 'Địa chỉ email'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester, db);
  });

  // AC-126: màn mới đạt vùng chạm 48, nhãn, tương phản; sáng/tối; chữ 200%.
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('màn hộp thư đạt accessibility · ${theme.name} · '
          '${(scale * 100).round()}%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final rig = _Rig();
        final now = testToday.toUtc().toIso8601String();
        await rig.secrets.write(MailboxStore.boxesKey, '''[
          {"id":"m0","provider":"gmail","address":"me@gmail.com","connectedAt":"$now","uidValidity":1,"lastUid":0,"unreadable":1,"lastCheckAt":"$now"},
          {"id":"m1","provider":"yahoo","address":"b@yahoo.com","connectedAt":"$now","uidValidity":1,"lastUid":0,"needsPassword":true,"lastError":"badCredentials","lastCheckAt":"$now"}
        ]''');
        final db = memoryDatabase();
        await tester.runAsync(() => SettingsRepository(db).setThemeMode(theme));
        await pumpApp(
          tester,
          db: db,
          secrets: rig.secrets,
          overrides: rig.overrides,
        );
        final problems = <String>[];
        for (final route in [
          '/email-import',
          '/email-import/add',
          '/email-import/add?id=m1',
        ]) {
          await _go(tester, route);
          expect(tester.takeException(), isNull, reason: route);
          for (final (name, guideline) in [
            ('vùng chạm', androidTapTargetGuideline),
            ('nhãn', labeledTapTargetGuideline),
            ('tương phản', textContrastGuideline),
          ]) {
            final result = await guideline.evaluate(tester);
            if (!result.passed) {
              problems.add('$route · $name: ${result.reason}');
            }
          }
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
        handle.dispose();
        await disposeApp(tester, db);
      });
    }
  }

  test('khoá secret của hộp thư không trùng khoá khác của app', () {
    expect(MailboxStore.allKeys.toSet().length, MailboxStore.allKeys.length);
    expect(MailboxStore.allKeys.every((k) => k.startsWith('mail_')), isTrue);
  });
}
