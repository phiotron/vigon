import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/import/mail/bank_senders.dart';
import 'package:vigon/src/import/mail/imap_gateway.dart';
import 'package:vigon/src/import/mail/mail_provider.dart';
import 'package:vigon/src/import/mail/mailbox_service.dart';
import 'package:vigon/src/import/mail/mailbox_store.dart';
import 'package:vigon/src/import/mail/raw_mail.dart';

import 'fake_imap.dart';

const _bank = 'thongbao@mbbank-test.vn';
const _address = 'me@gmail.com';
const _password = 'abcd efgh ijkl mnop';

const _allow = SenderAllowlist([
  BankSource(id: 'mb', name: 'MB Bank', senders: {_bank}),
]);

class _RecordingHandler implements ReceiptMailHandler {
  final batches = <List<RawMail>>[];
  int unreadablePerBatch = 0;
  bool fail = false;

  List<int> get uids => [
    for (final b in batches)
      for (final m in b) m.uid,
  ];

  @override
  Future<MailHandleResult> handle(List<RawMail> mails) async {
    if (fail) throw StateError('reader failed');
    batches.add(mails);
    return MailHandleResult(unreadable: unreadablePerBatch);
  }
}

class _Rig {
  _Rig({SenderAllowlist senders = _allow}) {
    service = MailboxService(
      store: MailboxStore(secrets, marker: marker),
      connector: server,
      senders: senders,
      handler: handler,
      clock: () => now,
    );
  }

  final secrets = MemorySecretStore();
  final marker = MemoryInstallMarker();
  final server = FakeImapServer(passwords: {_address: _password});
  final handler = _RecordingHandler();
  DateTime now = DateTime(2026, 11, 6, 9);
  late final MailboxService service;

  Future<Mailbox> addGmail() => service.add(
    provider: MailProvider.gmail,
    address: _address,
    password: _password,
  );

  Future<Mailbox> box() async => (await service.mailboxes()).single;
}

void main() {
  group('thêm hộp thư (AC-78, AC-79)', () {
    test('đăng nhập thử, lưu địa chỉ + mật khẩu chỉ trong SecretStore; thư '
        'có từ trước không được đọc (AC-81)', () async {
      final rig = _Rig();
      rig.server.deliver(_address, FakeMessage(uid: 40, from: _bank));
      final box = await rig.service.add(
        provider: MailProvider.gmail,
        address: '  Me@Gmail.com ',
        password: _password,
      );
      expect(box.address, _address);
      expect(box.lastUid, 40); // UIDNEXT − 1
      expect(rig.server.hostsUsed, ['imap.gmail.com']);
      expect(rig.server.log, contains('EXAMINE INBOX'));
      expect(rig.server.log.last, 'LOGOUT');
      // Mật khẩu chỉ nằm ở khoá riêng, không trong danh sách hộp thư.
      final values = rig.secrets.values;
      expect(values[MailboxStore.passwordKey(box.id)], _password);
      expect(values[MailboxStore.boxesKey], isNot(contains(_password)));
      expect(
        values.entries
            .where((e) => e.value.contains(_password))
            .map((e) => e.key),
        [MailboxStore.passwordKey(box.id)],
      );
      expect('$box', isNot(contains(_address)));

      rig.now = rig.now.add(const Duration(hours: 1));
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, isEmpty);
    });

    test('sai mật khẩu ứng dụng → báo badCredentials, không lưu gì', () async {
      final rig = _Rig();
      await expectLater(
        rig.service.add(
          provider: MailProvider.gmail,
          address: _address,
          password: 'sai',
        ),
        throwsA(
          isA<MailException>().having(
            (e) => e.kind,
            'kind',
            MailErrorKind.badCredentials,
          ),
        ),
      );
      expect(rig.secrets.values, isEmpty);
      expect(await rig.service.mailboxes(), isEmpty);
    });

    for (final kind in [
      MailErrorKind.imapDisabled,
      MailErrorKind.noNetwork,
      MailErrorKind.secureConnection,
    ]) {
      test('lỗi ${kind.name} khi thêm → báo đúng loại, không lưu gì', () async {
        final rig = _Rig()..server.failOpen = MailException(kind);
        await expectLater(
          rig.addGmail(),
          throwsA(isA<MailException>().having((e) => e.kind, 'kind', kind)),
        );
        expect(rig.secrets.values, isEmpty);
      });
    }

    test('tối đa 3 hộp thư, không trùng, địa chỉ phải đúng dạng', () async {
      final rig = _Rig();
      final server = rig.server;
      final pw = {
        _address: _password,
        'b@yahoo.com': 'p2',
        'c@icloud.com': 'p3',
        'd@gmail.com': 'p4',
      };
      final service = MailboxService(
        store: MailboxStore(rig.secrets, marker: rig.marker),
        connector: FakeImapServer(passwords: pw),
        senders: _allow,
      );
      await service.add(
        provider: MailProvider.gmail,
        address: _address,
        password: _password,
      );
      await expectLater(
        service.add(
          provider: MailProvider.gmail,
          address: 'ME@gmail.com',
          password: _password,
        ),
        throwsA(
          isA<MailboxAddException>().having(
            (e) => e.error,
            'error',
            MailboxAddError.duplicate,
          ),
        ),
      );
      await service.add(
        provider: MailProvider.yahoo,
        address: 'b@yahoo.com',
        password: 'p2',
      );
      await service.add(
        provider: MailProvider.icloud,
        address: 'c@icloud.com',
        password: 'p3',
      );
      await expectLater(
        service.add(
          provider: MailProvider.gmail,
          address: 'd@gmail.com',
          password: 'p4',
        ),
        throwsA(
          isA<MailboxAddException>().having(
            (e) => e.error,
            'error',
            MailboxAddError.limit,
          ),
        ),
      );
      await expectLater(
        rig.service.add(
          provider: MailProvider.gmail,
          address: 'khong-phai-email',
          password: 'x',
        ),
        throwsA(isA<MailboxAddException>()),
      );
      expect(server.opens, 0);
      expect(
        [for (final b in await service.mailboxes()) b.id],
        ['m0', 'm1', 'm2'],
      );
    });
  });

  group('lấy thư (AC-81, AC-82)', () {
    test(
      'chưa có ngân hàng nào hỗ trợ → không mở kết nối nào (AC-83)',
      () async {
        const none = SenderAllowlist([
          BankSource(id: 'mb', name: 'MB Bank', senders: {}),
        ]);
        final rig = _Rig(senders: none);
        await rig.addGmail();
        final opens = rig.server.opens;
        await rig.service.checkAll(MailCheckTrigger.manual);
        expect(rig.server.opens, opens);
        expect(none.supported, isEmpty);
      },
    );

    test('danh sách của bản build: MB Bank có đúng một địa chỉ gửi (M1)', () {
      expect(defaultSenderAllowlist.supported.map((s) => s.id), ['mb']);
      expect(defaultSenderAllowlist.addresses, {mbSenderAddress});
      expect(defaultSenderAllowlist.allows('MBeBanking@mbbank.com.vn'), isTrue);
      expect(defaultSenderAllowlist.allows('x$mbSenderAddress'), isFalse);
    });

    test('chỉ thư từ ĐÚNG địa chỉ cho phép được tải thân thư; theo UID tăng '
        'dần; thư khác không tải', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.server
        ..deliver(_address, FakeMessage(uid: 3, from: 'ban@be.vn'))
        ..deliver(_address, FakeMessage(uid: 5, from: _bank, text: 'A'))
        // Chứa địa chỉ cho phép như chuỗi con: IMAP tìm ra nhưng phải bỏ.
        ..deliver(_address, FakeMessage(uid: 6, from: 'x$_bank'))
        ..deliver(_address, FakeMessage(uid: 4, from: _bank.toUpperCase()));
      final outcome = await rig.service.checkAll(MailCheckTrigger.manual);
      expect(outcome.delivered, 2);
      expect(rig.handler.uids, [4, 5]);
      expect(rig.server.bodiesFetched, [4, 5]);
      final mail = rig.handler.batches.single.last;
      expect(mail.from, _bank);
      expect(mail.bank.id, 'mb');
      expect(mail.bodyText, 'A');
      expect(mail.mailboxId, 'm0');
      expect((await rig.box()).lastUid, 6);
      expect((await rig.box()).lastError, isNull);
    });

    test('nhớ UID đã đọc: không tải lại, chỉ thư mới', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.server.deliver(_address, FakeMessage(uid: 1, from: _bank));
      await rig.service.checkAll(MailCheckTrigger.manual);
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, [1]);
      rig.server.deliver(_address, FakeMessage(uid: 2, from: _bank));
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, [1, 2]);
      expect(rig.server.bodiesFetched, [1, 2]);
    });

    test('thư > 256 KB bị bỏ, không tải thân thư', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.server
        ..deliver(
          _address,
          FakeMessage(uid: 1, from: _bank, size: maxMailBytes + 1),
        )
        ..deliver(
          _address,
          FakeMessage(uid: 2, from: _bank, size: maxMailBytes),
        );
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.server.bodiesFetched, [2]);
      expect((await rig.box()).lastUid, 2);
    });

    test('mở app: chỉ kiểm khi lần trước cách ≥ 15 phút; kéo làm mới luôn '
        'kiểm', () async {
      final rig = _Rig();
      await rig.addGmail();
      final opens = rig.server.opens;
      rig.now = rig.now.add(const Duration(minutes: 14));
      await rig.service.checkAll(MailCheckTrigger.open);
      await rig.service.checkAll(MailCheckTrigger.background);
      expect(rig.server.opens, opens);
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.server.opens, opens + 1);
      rig.now = rig.now.add(const Duration(minutes: 15));
      await rig.service.checkAll(MailCheckTrigger.open);
      expect(rig.server.opens, opens + 2);
      expect((await rig.box()).lastCheckAt, rig.now);
    });

    test('sai mật khẩu khi kiểm → dừng kiểm hộp thư đó (cả kéo làm mới) tới '
        'khi nhập lại mật khẩu', () async {
      final rig = _Rig();
      await rig.addGmail();
      final server2 = FakeImapServer(passwords: {_address: 'moi'});
      final service = MailboxService(
        store: MailboxStore(rig.secrets, marker: rig.marker),
        connector: server2,
        senders: _allow,
        handler: rig.handler,
        clock: () => rig.now,
      );
      await service.checkAll(MailCheckTrigger.manual);
      var box = (await service.mailboxes()).single;
      expect(box.needsPassword, isTrue);
      expect(box.lastError, MailErrorKind.badCredentials);
      final opens = server2.opens;
      await service.checkAll(MailCheckTrigger.manual);
      expect(server2.opens, opens);

      await expectLater(
        service.updatePassword(box.id, 'van-sai'),
        throwsA(isA<MailException>()),
      );
      expect(
        await rig.secrets.read(MailboxStore.passwordKey(box.id)),
        _password,
      );
      box = await service.updatePassword(box.id, 'moi');
      expect(box.needsPassword, isFalse);
      expect(box.lastError, isNull);
      expect(await rig.secrets.read(MailboxStore.passwordKey(box.id)), 'moi');
      server2.deliver(_address, FakeMessage(uid: 9, from: _bank));
      await service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, [9]);
    });

    test('mất mạng → lỗi noNetwork, giữ UID, lần sau đọc tiếp', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.server
        ..deliver(_address, FakeMessage(uid: 1, from: _bank))
        ..failSearch = const MailException(MailErrorKind.noNetwork);
      final outcome = await rig.service.checkAll(MailCheckTrigger.manual);
      expect(outcome.failed, 1);
      var box = await rig.box();
      expect(box.lastError, MailErrorKind.noNetwork);
      expect(box.needsPassword, isFalse);
      expect(box.lastUid, 0);
      rig.server.failSearch = null;
      await rig.service.checkAll(MailCheckTrigger.manual);
      box = await rig.box();
      expect(box.lastError, isNull);
      expect(rig.handler.uids, [1]);
    });

    test('bộ đọc lỗi → không nhớ UID, lần sau đưa lại cả lô', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.server.deliver(_address, FakeMessage(uid: 1, from: _bank));
      rig.handler.fail = true;
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect((await rig.box()).lastUid, 0);
      rig.handler.fail = false;
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, [1]);
    });

    test('bộ đọc báo email không đọc được → cộng dồn bộ đếm (AC-85)', () async {
      final rig = _Rig();
      await rig.addGmail();
      rig.handler.unreadablePerBatch = 1;
      rig.server.deliver(_address, FakeMessage(uid: 1, from: _bank));
      await rig.service.checkAll(MailCheckTrigger.manual);
      rig.server.deliver(_address, FakeMessage(uid: 2, from: _bank));
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect((await rig.box()).unreadable, 2);
    });

    test(
      'UIDVALIDITY đổi → tìm lại từ đầu nhưng chỉ thư từ ngày kết nối',
      () async {
        final rig = _Rig();
        rig.server.deliver(
          _address,
          FakeMessage(uid: 1, from: _bank, date: DateTime(2026, 11, 1)),
        );
        await rig.addGmail();
        rig.server
          ..inbox[_address] = [
            FakeMessage(uid: 1, from: _bank, date: DateTime(2026, 11, 1)),
            FakeMessage(uid: 2, from: _bank, date: DateTime(2026, 11, 6, 10)),
          ]
          ..uidValidity = 99;
        await rig.service.checkAll(MailCheckTrigger.manual);
        expect(rig.handler.uids, [2]);
        expect((await rig.box()).uidValidity, 99);
      },
    );

    test('tối đa 50 thư mỗi lần, phần còn lại lần sau', () async {
      final rig = _Rig();
      await rig.addGmail();
      for (var i = 1; i <= 60; i++) {
        rig.server.deliver(_address, FakeMessage(uid: i, from: _bank));
      }
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids.length, 50);
      await rig.service.checkAll(MailCheckTrigger.manual);
      expect(rig.handler.uids, [for (var i = 1; i <= 60; i++) i]);
    });
  });

  group('xoá (AC-79, AC-123)', () {
    test('xoá một hộp thư xoá mật khẩu của nó', () async {
      final rig = _Rig();
      final box = await rig.addGmail();
      await rig.service.remove(box.id);
      expect(await rig.service.mailboxes(), isEmpty);
      expect(rig.secrets.values.values, isNot(contains(_password)));
    });

    test('removeAll xoá mọi khoá hộp thư khỏi Keystore/Keychain', () async {
      final rig = _Rig();
      await rig.addGmail();
      await rig.service.setIntroSeen();
      await rig.secrets.write('pin_hash', 'giu-nguyen');
      await rig.service.removeAll();
      expect(rig.secrets.values.keys, ['pin_hash']);
      expect(rig.marker.value, isNull);
      expect(await rig.service.introSeen(), isFalse);
    });

    test(
      'cài lại app (dấu cài đặt mất, Keychain còn) → hộp thư cũ bị xoá',
      () async {
        final rig = _Rig();
        await rig.addGmail();
        expect(rig.marker.value, isNotNull);
        rig.marker.value = null; // iOS: gỡ app xoá bộ nhớ riêng, giữ Keychain
        expect(await rig.service.mailboxes(), isEmpty);
        expect(rig.secrets.values.values, isNot(contains(_password)));
      },
    );
  });
}
