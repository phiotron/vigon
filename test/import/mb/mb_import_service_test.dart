import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/import_repositories.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/import/mb/mb_import_service.dart';
import 'package:vigon/src/import/mb/mb_receipt_parser.dart';

MbReceipt receipt({
  String ref = 'REF0001',
  String last4 = '4821',
  int amount = 50000,
  String date = '2026-11-06',
  String time = '12:02',
  String currency = 'VND',
  String? payee = 'LE VAN KHACH',
  String? content = 'tra tien',
}) => MbReceipt(
  dateKey: date,
  time: time,
  reference: ref,
  debitLast4: last4,
  currency: currency,
  amount: amount,
  payee: payee,
  transferContent: content,
);

void main() {
  late AppDatabase db;
  late MbImportService service;
  late AccountRepository accounts;
  late EntryRepository entries;
  late ImportQueueRepository queue;
  late SeenReferenceRepository seen;
  late int mb; // tài khoản liên kết (MB, 4821)
  const cash = 1; // tài khoản mặc định của seedDefaults

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Email MB bằng VND; app mới mặc định USD (D-036) nên đặt VND cho các ca ghép.
    await SettingsRepository(db).setCurrency('VND');
    service = MbImportService(db);
    accounts = AccountRepository(db);
    entries = EntryRepository(db);
    queue = ImportQueueRepository(db);
    seen = SeenReferenceRepository(db);
    // Kích hoạt seedDefaults trước khi thêm dữ liệu.
    await accounts.watchAll().first;
    mb = await accounts.add(name: 'Thẻ MB của tôi');
    await accounts.setBankLink(mb, Bank.mb, '4821');
  });
  tearDown(() => db.close());

  Future<int> manual({
    int account = -1,
    int amount = 50000,
    String date = '2026-11-06',
    String? time = '12:00',
    EntryType type = EntryType.expense,
    String? note = 'Cà phê',
    int? toAccount,
  }) => entries.add(
    EntriesCompanion.insert(
      type: type,
      amount: amount,
      accountId: account == -1 ? mb : account,
      toAccountId: Value(toAccount),
      date: date,
      time: Value(time),
      note: Value(note),
      categoryId: type == EntryType.transfer
          ? const Value.absent()
          : const Value(1),
    ),
  );

  group('tạo mục hàng đợi và tài khoản (F-30)', () {
    test('email thành công, tài khoản đã liên kết → mục hàng đợi, không '
        'markSeen, không tạo Account', () async {
      final before = (await accounts.watchAll().first).length;
      expect(await service.importReceipt(receipt()), MbImportOutcome.queued);
      expect((await accounts.watchAll().first).length, before);
      final item = (await queue.all()).single;
      expect(item.accountId, mb);
      expect(
        (
          item.bank,
          item.referenceNumber,
          item.debitLast4,
          item.currency,
          item.amount,
          item.date,
          item.time,
          item.payee,
          item.transferContent,
        ),
        (
          Bank.mb,
          'REF0001',
          '4821',
          'VND',
          50000,
          '2026-11-06',
          '12:02',
          'LE VAN KHACH',
          'tra tien',
        ),
      );
      // Mục chờ chưa "đã thấy" (hàng đợi không vào sao lưu).
      expect(await seen.isSeen(Bank.mb, 'REF0001'), isFalse);
      expect(await seen.isKnown(Bank.mb, 'REF0001'), isTrue);
    });

    test('tài khoản trích nợ chưa gắn → tạo "MB Bank …xxxx", số dư 0, ghi thẻ '
        'nhắc; lần sau dùng lại, không tạo thêm', () async {
      expect(
        await service.importReceipt(receipt(ref: 'A', last4: '9999')),
        MbImportOutcome.queued,
      );
      final created = (await accounts.findByBankLink(Bank.mb, '9999'))!;
      expect(created.name, 'MB Bank …9999');
      expect(created.initialBalance, 0);
      expect(created.archived, isFalse);
      expect((await queue.all()).single.accountId, created.id);
      expect(await service.watchAutoAccountNotices().first, [created.id]);

      await service.importReceipt(receipt(ref: 'B', last4: '9999'));
      final all = await accounts.watchAll().first;
      expect(all.where((a) => a.bankLast4 == '9999'), hasLength(1));
      expect(await service.watchAutoAccountNotices().first, [created.id]);
    });

    test('đóng thẻ giữ Account; Account bị xoá thì thẻ biến mất', () async {
      await service.importReceipt(receipt(ref: 'A', last4: '9999'));
      await service.importReceipt(receipt(ref: 'B', last4: '8888'));
      final a = (await accounts.findByBankLink(Bank.mb, '9999'))!;
      final b = (await accounts.findByBankLink(Bank.mb, '8888'))!;
      expect(await service.watchAutoAccountNotices().first, [b.id, a.id]);
      await service.dismissAutoAccountNotice(a.id);
      expect(await service.watchAutoAccountNotices().first, [b.id]);
      expect(await accounts.findByBankLink(Bank.mb, '9999'), isNotNull);
      await queue.remove((await queue.findByReference(Bank.mb, 'B'))!.id);
      await accounts.delete(b.id);
      expect(await service.watchAutoAccountNotices().first, isEmpty);
      // Xoá rồi email sau tạo lại và hỏi lại (AC-90).
      await service.importReceipt(receipt(ref: 'C', last4: '8888'));
      expect(await service.watchAutoAccountNotices().first, hasLength(1));
    });

    test('Account đã ẩn vẫn nhận mục (AC-90)', () async {
      await db.customStatement(
        'UPDATE accounts SET archived = 1 WHERE id = $mb',
      );
      await service.importReceipt(receipt());
      expect((await queue.all()).single.accountId, mb);
      expect(
        (await accounts.watchAll().first).where((a) => a.bankLast4 == '4821'),
        hasLength(1),
      );
    });

    test('số tài khoản đầy đủ không bao giờ vào dữ liệu: nội dung có dãy số '
        'dài bị che (AC-88)', () async {
      await service.importReceipt(
        receipt(
          payee: 'NGUYEN VAN A 0123456789',
          content: 'chuyen cho 9704221234567890',
        ),
      );
      final item = (await queue.all()).single;
      expect(item.payee, 'NGUYEN VAN A …6789');
      expect(item.transferContent, 'chuyen cho …7890');
    });
  });

  group('chống trùng số tham chiếu (AC-86)', () {
    test('cùng số tham chiếu nhập lại → bỏ', () async {
      await service.importReceipt(receipt());
      expect(await service.importReceipt(receipt()), MbImportOutcome.duplicate);
      expect(await queue.all(), hasLength(1));
    });

    test('hai email cùng số tiền, khác số tham chiếu → hai mục', () async {
      await service.importReceipt(receipt(ref: 'A'));
      await service.importReceipt(receipt(ref: 'B'));
      expect(await queue.all(), hasLength(2));
    });

    test('sau "Bỏ qua" hoặc khi đã xác nhận, email lặp không nhập lại', () async {
      await service.importReceipt(receipt(ref: 'SKIP'));
      await service.importReceipt(receipt(ref: 'SAVED'));
      // Bỏ qua (M5): remove + markSeen(skipped).
      await queue.remove((await queue.findByReference(Bank.mb, 'SKIP'))!.id);
      await seen.markSeen(Bank.mb, 'SKIP', ReferenceOutcome.skipped);
      // Lưu từ hàng đợi: khoản có số tham chiếu + remove + markSeen(confirmed).
      final item = (await queue.findByReference(Bank.mb, 'SAVED'))!;
      await entries.add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 50000,
          accountId: mb,
          date: '2026-11-06',
          source: const Value(EntrySource.emailMb),
          referenceNumber: const Value('SAVED'),
          categoryId: const Value(1),
        ),
      );
      await queue.remove(item.id);
      await seen.markSeen(Bank.mb, 'SAVED', ReferenceOutcome.confirmed);
      // Xoá khoản đã lưu rồi cũng không nhập lại (seen nhớ).
      for (final ref in ['SKIP', 'SAVED']) {
        expect(
          await service.importReceipt(receipt(ref: ref)),
          MbImportOutcome.duplicate,
        );
      }
      expect(await queue.all(), isEmpty);
    });

    test('số tham chiếu đã gắn vào một khoản (không có trong seen) vẫn là '
        '"đã biết"', () async {
      await entries.add(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: 50000,
          accountId: mb,
          date: '2026-11-06',
          source: const Value(EntrySource.emailMb),
          referenceNumber: const Value('ONLY-IN-ENTRY'),
          categoryId: const Value(1),
        ),
      );
      expect(
        await service.importReceipt(receipt(ref: 'ONLY-IN-ENTRY')),
        MbImportOutcome.duplicate,
      );
    });
  });

  group('ghép với khoản ghi tay (F-31)', () {
    test(
      'ghi tay 12:00, email 12:02 cùng Account/số tiền → ghép: khoản giữ '
      'nguyên dữ liệu, thêm nguồn + số tham chiếu, không vào hàng đợi',
      () async {
        final id = await manual();
        final before = (await entries.find(id))!;
        expect(await service.importReceipt(receipt()), MbImportOutcome.matched);
        final after = (await entries.find(id))!;
        expect(after.source, EntrySource.emailMb);
        expect(after.referenceNumber, 'REF0001');
        expect(
          after.copyWith(
            source: before.source,
            referenceNumber: const Value(null),
          ),
          before,
        );
        expect(await queue.all(), isEmpty);
        expect(await seen.isSeen(Bank.mb, 'REF0001'), isTrue);
        // Email lặp: không tạo gì.
        expect(
          await service.importReceipt(receipt()),
          MbImportOutcome.duplicate,
        );
      },
    );

    test('biên 2 giờ tính cả hai đầu (AC-92)', () async {
      await manual(time: '12:00');
      expect(
        await service.importReceipt(receipt(ref: 'IN', time: '14:00')),
        MbImportOutcome.matched,
      );
      await manual(time: '12:00');
      expect(
        await service.importReceipt(receipt(ref: 'OUT', time: '14:01')),
        MbImportOutcome.queued,
      );
      await manual(date: '2026-11-07', time: '12:00');
      expect(
        await service.importReceipt(
          receipt(ref: 'BEFORE', date: '2026-11-07', time: '10:00'),
        ),
        MbImportOutcome.matched,
      );
    });

    test('qua nửa đêm: ghi tay 23:30 ngày 05, email 00:40 ngày 06 → ghép; '
        'và chiều ngược', () async {
      await manual(date: '2026-11-05', time: '23:30');
      expect(
        await service.importReceipt(
          receipt(ref: 'A', date: '2026-11-06', time: '00:40'),
        ),
        MbImportOutcome.matched,
      );
      await manual(date: '2026-11-06', time: '00:10');
      expect(
        await service.importReceipt(
          receipt(ref: 'B', date: '2026-11-05', time: '23:00'),
        ),
        MbImportOutcome.matched,
      );
    });

    test(
      'khoản không giờ coi là 12:00: 13:30 ghép, 15:00 không (AC-92)',
      () async {
        await manual(time: null);
        expect(
          await service.importReceipt(receipt(ref: 'A', time: '15:00')),
          MbImportOutcome.queued,
        );
        expect(
          await service.importReceipt(receipt(ref: 'B', time: '13:30')),
          MbImportOutcome.matched,
        );
      },
    );

    test('khác Account (Tiền mặt), khác số tiền → hàng đợi (AC-91)', () async {
      await manual(account: cash);
      await manual(amount: 51000);
      expect(await service.importReceipt(receipt()), MbImportOutcome.queued);
      expect(await queue.all(), hasLength(1));
    });

    test('khoản thu không ghép; chuyển tiền đi từ Account ghép, chuyển tiền '
        'đến thì không (AC-91)', () async {
      await manual(type: EntryType.income);
      await manual(type: EntryType.transfer, account: cash, toAccount: mb);
      expect(
        await service.importReceipt(receipt(ref: 'A')),
        MbImportOutcome.queued,
      );
      final out = await manual(
        type: EntryType.transfer,
        account: mb,
        toAccount: cash,
      );
      expect(
        await service.importReceipt(receipt(ref: 'B')),
        MbImportOutcome.matched,
      );
      expect((await entries.find(out))!.referenceNumber, 'B');
    });

    test('mỗi khoản chỉ ghép một email: hai email 12:00 và 12:30 cho một '
        'khoản → email sau vào hàng đợi (AC-93)', () async {
      final id = await manual(time: '12:00');
      expect(
        await service.importReceipt(receipt(ref: 'FIRST', time: '12:00')),
        MbImportOutcome.matched,
      );
      expect(
        await service.importReceipt(receipt(ref: 'SECOND', time: '12:30')),
        MbImportOutcome.queued,
      );
      expect((await entries.find(id))!.referenceNumber, 'FIRST');
      expect((await queue.all()).single.referenceNumber, 'SECOND');
    });

    test('nhiều khoản đủ điều kiện → gần nhất; bằng nhau → khoản tạo trước '
        '(AC-93)', () async {
      final far = await manual(time: '11:00');
      final near = await manual(time: '12:10');
      final tieA = await manual(time: '12:50');
      final tieB = await manual(time: '13:10');
      await service.importReceipt(receipt(ref: 'A', time: '12:00'));
      expect((await entries.find(near))!.referenceNumber, 'A');
      expect((await entries.find(far))!.referenceNumber, isNull);
      await service.importReceipt(receipt(ref: 'B', time: '13:00'));
      expect(
        (await entries.find(tieA))!.referenceNumber,
        'B',
      ); // cách 10, tạo trước
      expect((await entries.find(tieB))!.referenceNumber, isNull);
    });

    test('khoản ghi tay đã có số tham chiếu (từ email khác) không bị ghép '
        'thêm', () async {
      final id = await manual();
      await entries.attachReference(id, EntrySource.emailMb, 'OTHER');
      expect(await service.importReceipt(receipt()), MbImportOutcome.queued);
    });
  });

  group('tiền tệ khác tiền tệ app (AC-87)', () {
    test('email VND khi app dùng USD → vào hàng đợi với currency VND, không '
        'ghép dù trùng số', () async {
      await SettingsRepository(db).setCurrency('USD');
      await manual(amount: 50000);
      expect(await service.importReceipt(receipt()), MbImportOutcome.queued);
      final item = (await queue.all()).single;
      expect((item.currency, item.amount), ('VND', 50000));
      expect((await entries.find(1))?.referenceNumber, isNull);
    });
  });

  group('gắn vào tài khoản có sẵn (AC-89) và chiều ngược (AC-94)', () {
    test('liên kết + mục chuyển sang Account có sẵn, Account tự tạo bị xoá, '
        'mục được thử ghép lại', () async {
      await service.importReceipt(
        receipt(ref: 'A', last4: '9999', time: '12:02'),
      );
      await service.importReceipt(
        receipt(ref: 'B', last4: '9999', amount: 70000, time: '09:00'),
      );
      final auto = (await accounts.findByBankLink(Bank.mb, '9999'))!;
      final target = await accounts.add(name: 'Thẻ cũ');
      final match = await manual(account: target, amount: 70000, time: '09:30');

      final matched = await service.attachToExistingAccount(
        autoAccountId: auto.id,
        targetAccountId: target,
      );
      expect(matched, 1);
      expect((await accounts.findByBankLink(Bank.mb, '9999'))!.id, target);
      expect(
        (await accounts.watchAll().first).where((a) => a.id == auto.id),
        isEmpty,
      );
      final left = (await queue.all()).single;
      expect((left.referenceNumber, left.accountId), ('A', target));
      expect((await entries.find(match))!.referenceNumber, 'B');
      expect(await service.watchAutoAccountNotices().first, isEmpty);
    });

    test('lưu khoản ghi tay khớp mục đang chờ → tìm thấy, ghép, Hoàn tác trả '
        'về hàng đợi', () async {
      await service.importReceipt(receipt(ref: 'A', time: '12:02'));
      await service.importReceipt(receipt(ref: 'B', time: '12:50'));
      final id = await manual(time: '12:40');
      final entry = (await entries.find(id))!;
      final item = (await service.findQueueMatchFor(entry))!;
      expect(item.referenceNumber, 'B'); // gần 12:40 hơn 12:02
      final removed = await service.attachQueueItem(item, id);
      expect(removed, isNotNull);
      expect((await entries.find(id))!.referenceNumber, 'B');
      expect(await queue.findByReference(Bank.mb, 'B'), isNull);
      expect(await seen.isSeen(Bank.mb, 'B'), isTrue);

      await service.undoAttach(item, id);
      final back = (await entries.find(id))!;
      expect((back.source, back.referenceNumber), (EntrySource.manual, null));
      expect(await queue.findByReference(Bank.mb, 'B'), isNotNull);
      expect(await seen.isSeen(Bank.mb, 'B'), isFalse);
    });

    test('khoản không khớp (thu, khác số tiền, quá 2 giờ, Account khác) → '
        'không tìm thấy', () async {
      await service.importReceipt(receipt(ref: 'A', time: '12:00'));
      for (final e in [
        await manual(type: EntryType.income),
        await manual(amount: 1),
        await manual(time: '14:30'),
        await manual(account: cash),
      ]) {
        expect(
          await service.findQueueMatchFor((await entries.find(e))!),
          isNull,
        );
      }
    });
  });
}
