import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/import_repositories.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/import/mail/bank_senders.dart';
import 'package:vigon/src/import/mail/mail_background.dart';
import 'package:vigon/src/import/mail/mail_provider.dart';
import 'package:vigon/src/import/mail/mailbox_service.dart';
import 'package:vigon/src/import/mail/mailbox_store.dart';
import 'package:vigon/src/import/mail/raw_mail.dart';
import 'package:vigon/src/import/mb/mb_receipt_handler.dart';

import '../mail/fake_imap.dart';

const _address = 'me@gmail.com';
const _password = 'abcd efgh ijkl mnop';
const _mb = mbSenderAddress;

/// Thân thư text như biên lai MB (giá trị giả).
String receiptBody({
  String ref = 'REF0000000000001',
  String when = '06-11-2026 12:11:42',
  String last4 = '4821',
  String amount = '(VND) 48,000.00',
  String status = 'Giao dịch thành công',
  String payee = 'LE VAN KHACH - 012300XXX7788',
  String content = 'tra tien an trua',
  bool withRef = true,
}) => [
  'MB xin thông báo giao dịch của Quý khách đã được thực hiện như sau:',
  'Ngày, giờ giao dịch: $when',
  'Loại giao dịch: Chuyển tiền nhanh ngoài MB',
  if (withRef) 'Số tham chiếu: $ref',
  'Tài khoản trích nợ: TRAN THI MAU - ········$last4 (VND)',
  'Người thụ hưởng: $payee',
  'Số tiền giao dịch: $amount',
  'Nội dung chuyển tiền: $content',
  'Cách thức lệnh: Thanh toán ngay',
  'Ngày nhập lệnh: ${when.length >= 10 ? when.substring(0, 10) : when}',
  'Thời gian: $when',
  'Tình trạng: $status',
  'Xin chân thành cảm ơn.',
].join('\n');

/// Cùng thư dạng HTML bảng (chỉ có phần html).
String receiptHtml({
  String ref = 'REF0000000000001',
  String when = '06-11-2026 12:11:42',
}) {
  final rows = <String, String>{
    'Ngày, giờ giao dịch': when,
    'Số tham chiếu': ref,
    'Tài khoản trích nợ': 'TRAN THI MAU - ········4821&nbsp;(VND)',
    'Người thụ hưởng': 'LE VAN KHACH - 012300XXX7788',
    'Số tiền giao dịch': '(VND)&nbsp;48,000.00',
    'Nội dung chuyển tiền': 'tra tien an trua',
    'Tình trạng': 'Giao dịch thành công',
  };
  return '<html><body><table>'
      '${rows.entries.map((e) => '<tr><td>${e.key}</td><td>${e.value}</td></tr>').join()}'
      '</table></body></html>';
}

class _Rig {
  _Rig() {
    db = AppDatabase(NativeDatabase.memory());
    handler = MbReceiptHandler(db);
    service = MailboxService(
      store: MailboxStore(secrets, marker: marker),
      connector: server,
      senders: defaultSenderAllowlist,
      handler: handler,
      clock: () => now,
    );
  }

  late final AppDatabase db;
  late final MbReceiptHandler handler;
  late final MailboxService service;
  final secrets = MemorySecretStore();
  final marker = MemoryInstallMarker();
  final server = FakeImapServer(passwords: {_address: _password});
  DateTime now = DateTime(2026, 11, 6, 9);
  int _uid = 100;

  late final accounts = AccountRepository(db);
  late final entries = EntryRepository(db);
  late final queue = ImportQueueRepository(db);
  late final seen = SeenReferenceRepository(db);

  Future<void> connect() async {
    await accounts.watchAll().first; // seedDefaults
    await service.add(
      provider: MailProvider.gmail,
      address: _address,
      password: _password,
    );
  }

  /// Thư mới tới lúc [arrivedAt] (giờ Gmail nhận, có thể trễ hơn giờ giao dịch).
  void deliver(
    String body, {
    String from = _mb,
    DateTime? arrivedAt,
    bool html = false,
    String? plainStub,
  }) {
    server.deliver(
      _address,
      FakeMessage(
        uid: ++_uid,
        from: from,
        text: html ? plainStub : body,
        html: html ? body : null,
        date: arrivedAt ?? now,
      ),
    );
  }

  Future<MailCheckOutcome> check() {
    now = now.add(const Duration(hours: 1));
    return service.checkAll(MailCheckTrigger.manual);
  }

  Future<int> linkedAccount() async {
    final id = await accounts.add(name: 'MB thật');
    await accounts.setBankLink(id, Bank.mb, '4821');
    return id;
  }

  Future<int> manual(
    int account, {
    int amount = 48000,
    String date = '2026-11-06',
    String? time = '12:00',
  }) => entries.add(
    EntriesCompanion.insert(
      type: EntryType.expense,
      amount: amount,
      accountId: account,
      date: date,
      time: Value(time),
      note: const Value('Cơm trưa'),
      categoryId: const Value(1),
    ),
  );

  Future<int> unreadable() async =>
      (await service.mailboxes()).single.unreadable;

  /// Mọi chữ trong các bảng có thể chứa dữ liệu từ thư.
  Future<String> dump() async {
    final parts = <String>[
      for (final t in [
        'accounts',
        'entries',
        'import_queue_items',
        'seen_references',
        'settings',
        'payee_suggestions',
      ])
        for (final r in await db.customSelect('SELECT * FROM $t').get())
          '${r.data}',
    ];
    return parts.join('\n');
  }
}

void main() {
  late _Rig rig;
  setUp(() async {
    rig = _Rig();
    await rig.connect();
  });
  tearDown(() => rig.db.close());

  test('email thành công → mục hàng đợi + tài khoản tự tạo; thời điểm lấy '
      'từ thân thư, không phải giờ thư tới', () async {
    rig.deliver(
      receiptBody(),
      arrivedAt: DateTime(2026, 11, 6, 13, 32), // trễ ~1 giờ 20
    );
    final out = await rig.check();
    expect(out.delivered, 1);

    final item = (await rig.queue.all()).single;
    expect(
      (item.date, item.time, item.amount, item.currency, item.debitLast4),
      ('2026-11-06', '12:11', 48000, 'VND', '4821'),
    );
    expect(item.referenceNumber, 'REF0000000000001');
    expect(item.payee, 'LE VAN KHACH');
    expect(item.transferContent, 'tra tien an trua');
    final account = (await rig.accounts.findByBankLink(Bank.mb, '4821'))!;
    expect((account.name, account.initialBalance), ('MB Bank …4821', 0));
    expect(item.accountId, account.id);
    expect(await rig.unreadable(), 0);
    // Mục chờ chưa "đã thấy".
    expect(await rig.seen.isSeen(Bank.mb, item.referenceNumber), isFalse);
  });

  test('thân thư chỉ có HTML (bảng) cũng đọc được; text/plain chỉ là dòng '
      '"xem bản HTML" thì dùng HTML', () async {
    rig.deliver(receiptHtml(ref: 'HTML00000001'), html: true);
    rig.deliver(
      receiptHtml(ref: 'HTML00000002'),
      html: true,
      plainStub: 'Vui lòng xem email ở dạng HTML',
    );
    await rig.check();
    expect([for (final i in await rig.queue.all()) i.referenceNumber]..sort(), [
      'HTML00000001',
      'HTML00000002',
    ]);
    expect(await rig.unreadable(), 0);
  });

  test(
    'email lặp (cùng số tham chiếu, thư mới UID khác) → không tạo thêm',
    () async {
      rig.deliver(receiptBody());
      await rig.check();
      rig.deliver(receiptBody()); // chuyển tiếp / tải lại
      await rig.check();
      expect(await rig.queue.all(), hasLength(1));
      expect(
        (await rig.accounts.watchAll().first).where(
          (a) => a.bankLast4 == '4821',
        ),
        hasLength(1),
      );
    },
  );

  test('cả lô được đưa lại cho bộ đọc (sau lần lỗi) không tạo trùng', () async {
    final mails = [
      for (final (i, ref) in ['REF000000000AAA', 'REF000000000BBB'].indexed)
        RawMail(
          mailboxId: 'm0',
          uid: i + 1,
          from: _mb,
          bank: mbBank,
          subject: 'Thong bao giao dich thanh cong',
          date: DateTime(2026, 11, 6, 13),
          textPlain: receiptBody(ref: ref),
        ),
    ];
    expect((await rig.handler.handle(mails)).unreadable, 0);
    expect((await rig.handler.handle(mails)).unreadable, 0);
    expect(await rig.queue.all(), hasLength(2));
  });

  test('hai email cùng số tiền nhưng khác số tham chiếu → hai mục', () async {
    rig.deliver(receiptBody(ref: 'REF000000000AAA'));
    rig.deliver(receiptBody(ref: 'REF000000000BBB'));
    await rig.check();
    expect(await rig.queue.all(), hasLength(2));
  });

  test('ghép: khoản ghi tay 12:00, email giao dịch 12:11 tới trễ 1 giờ 20 → '
      'ghép, không vào hàng đợi', () async {
    final mb = await rig.linkedAccount();
    final id = await rig.manual(mb, time: '12:00');
    rig.deliver(receiptBody(), arrivedAt: DateTime(2026, 11, 6, 13, 32));
    await rig.check();
    expect(await rig.queue.all(), isEmpty);
    final e = (await rig.entries.find(id))!;
    expect(
      (e.source, e.referenceNumber),
      (EntrySource.emailMb, 'REF0000000000001'),
    );
    expect(
      (e.note, e.amount, e.time, e.categoryId),
      ('Cơm trưa', 48000, '12:00', 1),
    );
    expect(await rig.seen.isSeen(Bank.mb, 'REF0000000000001'), isTrue);
    // Không tạo Account mới.
    expect(
      (await rig.accounts.watchAll().first).where((a) => a.bankLast4 != null),
      hasLength(1),
    );
  });

  test(
    'không ghép: ngoài 2 giờ, khác tài khoản, khác số tiền → hàng đợi',
    () async {
      final mb = await rig.linkedAccount();
      await rig.manual(mb, time: '09:00'); // 3 giờ trước 12:11
      await rig.manual(1, time: '12:00'); // Tiền mặt, cùng số tiền
      await rig.manual(mb, amount: 47000, time: '12:00');
      rig.deliver(receiptBody());
      await rig.check();
      expect(await rig.queue.all(), hasLength(1));
      expect(
        (await rig.entries.findByReference(
          EntrySource.emailMb,
          'REF0000000000001',
        )),
        isNull,
      );
    },
  );

  test(
    'khoản không giờ coi là 12:00; một khoản không bị ghép hai lần',
    () async {
      final mb = await rig.linkedAccount();
      final id = await rig.manual(mb, time: null);
      rig.deliver(
        receiptBody(ref: 'REF000000000AAA', when: '06-11-2026 13:30:00'),
      );
      rig.deliver(
        receiptBody(ref: 'REF000000000BBB', when: '06-11-2026 13:45:00'),
      );
      await rig.check();
      expect((await rig.entries.find(id))!.referenceNumber, 'REF000000000AAA');
      expect((await rig.queue.all()).single.referenceNumber, 'REF000000000BBB');
    },
  );

  test('thư không đọc được → chỉ đếm, KHÔNG lưu nội dung', () async {
    rig.deliver(
      receiptBody(
        ref: 'REF000000000CCC',
        payee: 'SECRETPAYEE2',
        withRef: false,
      ),
    );
    rig.deliver(
      receiptBody(
        ref: 'REF000000000DDD',
        payee: 'SECRETPAYEE3',
        amount: '48,000.00',
      ),
    );
    rig.deliver('MB tặng bạn ưu đãi SECRETPAYEE4 phí chuyển tiền');
    rig.deliver(
      receiptBody(
        ref: 'REF000000000EEE',
        when: 'hôm qua',
        payee: 'SECRETPAYEE5',
      ),
    );
    final out = await rig.check();
    expect(out.delivered, 4);
    expect(await rig.unreadable(), 4);
    expect(await rig.queue.all(), isEmpty);
    final dump = await rig.dump();
    expect(dump, isNot(contains('SECRETPAYEE')));
    expect(dump, isNot(contains('4821'))); // không cả tài khoản được tạo
    expect(await rig.seen.isSeen(Bank.mb, 'REF000000000DDD'), isFalse);
  });

  test('tình trạng đọc được nhưng không phải thành công (thất bại, đang xử '
      'lý, chữ khác) → chỉ bỏ: không lưu, KHÔNG tăng bộ đếm (AC-85)', () async {
    for (final (i, s) in [
      'Giao dịch thất bại',
      'Giao dịch đang xử lý',
      'Giao dịch không thành công',
    ].indexed) {
      rig.deliver(
        receiptBody(ref: 'REF00000000FAIL$i', status: s, payee: 'SECRETFAIL'),
      );
    }
    // Thiếu số tiền nhưng tình trạng thất bại: vẫn chỉ là thư thất bại.
    rig.deliver(receiptBody(status: 'Giao dịch thất bại', amount: ''));
    final out = await rig.check();
    expect(out.delivered, 4);
    expect(await rig.unreadable(), 0);
    expect(await rig.queue.all(), isEmpty);
    final dump = await rig.dump();
    expect(dump, isNot(contains('SECRETFAIL')));
    expect(dump, isNot(contains('4821')));
    // Thiếu số tiền khi tình trạng thành công → đếm +1.
    rig.deliver(receiptBody(ref: 'REF00000000NOAMT', amount: ''));
    await rig.check();
    expect(await rig.unreadable(), 1);
  });

  test(
    'thư không phải địa chỉ MB không tới bộ đọc (lớp lấy thư lọc)',
    () async {
      rig.deliver(receiptBody(), from: 'khac@bank.vn');
      final out = await rig.check();
      expect(out.delivered, 0);
      expect(await rig.queue.all(), isEmpty);
      expect(await rig.unreadable(), 0);
    },
  );

  test('bộ đếm cộng dồn qua các lần kiểm', () async {
    rig.deliver('thư lạ');
    await rig.check();
    rig.deliver('thư lạ nữa');
    rig.deliver(receiptBody());
    await rig.check();
    expect(await rig.unreadable(), 2);
    expect(await rig.queue.all(), hasLength(1));
  });

  test(
    'tiền tệ app USD, email VND → vào hàng đợi (không ghép, không quy đổi)',
    () async {
      await SettingsRepository(rig.db).setCurrency('USD');
      final mb = await rig.linkedAccount();
      await rig.manual(mb, amount: 48000);
      rig.deliver(receiptBody());
      await rig.check();
      final item = (await rig.queue.all()).single;
      expect((item.currency, item.amount), ('VND', 48000));
    },
  );

  test('đường nền Android dùng cùng bộ đọc (runScheduledMailCheck)', () async {
    // Thêm thư rồi chạy đúng hàm mà MailCheckJob gọi, với cùng bộ đọc.
    rig.deliver(receiptBody(ref: 'REF00000BACKGND'));
    rig.now = rig.now.add(const Duration(hours: 1));
    final outcome = await runScheduledMailCheck(
      handler: rig.handler,
      secrets: rig.secrets,
      connector: rig.server,
      marker: rig.marker,
      clock: () => rig.now,
    );
    expect(outcome!.delivered, 1);
    expect((await rig.queue.all()).single.referenceNumber, 'REF00000BACKGND');
  });
}
