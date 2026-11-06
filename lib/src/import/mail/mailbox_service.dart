import 'dart:async';

import 'bank_senders.dart';
import 'imap_gateway.dart';
import 'mail_provider.dart';
import 'mailbox_store.dart';
import 'raw_mail.dart';

/// Ai gọi kiểm thư (AC-82).
enum MailCheckTrigger {
  /// Mở hoặc quay lại app: chỉ khi lần trước cách ≥ [MailboxService.minInterval].
  open,

  /// Người dùng kéo để làm mới: kiểm ngay.
  manual,

  /// Lịch nền Android (~mỗi giờ): như [open].
  background,
}

/// Lỗi khi thêm hộp thư mà không phải lỗi máy chủ.
enum MailboxAddError {
  /// Đã có [maxMailboxes] hộp thư.
  limit,

  /// Hộp thư (cùng nhà cung cấp, cùng địa chỉ) đã có.
  duplicate,

  /// Địa chỉ không đúng dạng.
  invalidAddress,
}

class MailboxAddException implements Exception {
  const MailboxAddException(this.error);

  final MailboxAddError error;

  @override
  String toString() => 'MailboxAddException(${error.name})';
}

/// Kết quả một lần kiểm.
class MailCheckOutcome {
  const MailCheckOutcome({
    this.checked = 0,
    this.delivered = 0,
    this.failed = 0,
  });

  /// Số hộp thư đã kết nối được.
  final int checked;

  /// Số thư đã đưa cho bộ đọc.
  final int delivered;

  /// Số hộp thư lỗi.
  final int failed;
}

/// Hộp thư email (F-28) và lớp lấy thư thô (AC-81, AC-82).
///
/// Chỉ đọc: INBOX mở bằng EXAMINE, thư tải bằng `BODY.PEEK[]`; chỉ thư có
/// địa chỉ gửi ĐÚNG NGUYÊN là địa chỉ trong [senders], UID mới hơn UID đã nhớ,
/// cỡ ≤ [maxMailBytes]. Thư được đưa cho [handler] (bộ đọc M1) rồi bỏ.
class MailboxService {
  MailboxService({
    required this._store,
    required this._connector,
    this._senders = defaultSenderAllowlist,
    this._handler = const DiscardingMailHandler(),
    this._clock = DateTime.now,
    this.minInterval = const Duration(minutes: 15),
    this.maxPerCheck = 50,
  });

  final MailboxStore _store;
  final ImapConnector _connector;
  final SenderAllowlist _senders;
  final ReceiptMailHandler _handler;
  final DateTime Function() _clock;

  /// Khoảng tối thiểu giữa hai lần kiểm tự động (AC-82, mặc định S0).
  final Duration minInterval;

  /// Tối đa số thư tải mỗi hộp thư mỗi lần; phần còn lại để lần sau.
  final int maxPerCheck;

  Future<MailCheckOutcome>? _running;

  Future<List<Mailbox>> mailboxes() => _store.load();

  Future<bool> introSeen() => _store.introSeen();

  Future<void> setIntroSeen() => _store.setIntroSeen();

  /// Thêm hộp thư: đăng nhập thử ngay, nhớ UIDNEXT của INBOX để chỉ nhận thư
  /// từ lúc này (AC-81), rồi lưu địa chỉ + mật khẩu vào Keystore/Keychain.
  /// Ném [MailboxAddException] hoặc [MailException]; lỗi thì không lưu gì.
  Future<Mailbox> add({
    required MailProvider provider,
    required String address,
    required String password,
  }) async {
    final email = address.trim().toLowerCase();
    if (!isPlausibleEmail(email)) {
      throw const MailboxAddException(MailboxAddError.invalidAddress);
    }
    final boxes = await _store.load();
    if (boxes.any((b) => b.provider == provider && b.address == email)) {
      throw const MailboxAddException(MailboxAddError.duplicate);
    }
    final slot = _store.freeSlot(boxes);
    if (slot == null) throw const MailboxAddException(MailboxAddError.limit);
    final inbox = await _withSession(
      provider,
      email,
      password,
      (s) => s.examineInbox(),
    );
    final now = _clock();
    final box = Mailbox(
      id: slot,
      provider: provider,
      address: email,
      connectedAt: now,
      uidValidity: inbox.uidValidity,
      lastUid: inbox.uidNext - 1,
      lastCheckAt: now,
    );
    await _store.setPassword(slot, password);
    await _store.save([...await _store.load(), box]);
    return box;
  }

  /// Nhập lại mật khẩu ứng dụng: đăng nhập thử, được thì bỏ trạng thái dừng
  /// (AC-82) và ghi mật khẩu mới. Giữ UID đã nhớ.
  Future<Mailbox> updatePassword(String id, String password) async {
    final box = (await _store.load()).where((b) => b.id == id).firstOrNull;
    if (box == null) throw StateError('no mailbox $id');
    await _withSession(box.provider, box.address, password, (_) async {});
    await _store.setPassword(id, password);
    return await _update(
          id,
          (b) => b.copyWith(
            needsPassword: false,
            clearError: true,
            lastCheckAt: _clock(),
          ),
        ) ??
        box;
  }

  /// Xoá hộp thư: cấu hình và mật khẩu khỏi Keystore/Keychain (AC-79).
  Future<void> remove(String id) async {
    final boxes = await _store.load();
    await _store.deletePassword(id);
    await _store.save([
      for (final b in boxes)
        if (b.id != id) b,
    ]);
  }

  /// Xoá mọi hộp thư, mật khẩu, UID đã nhớ, dấu đã xem giải thích (AC-123).
  Future<void> removeAll() => _store.clear();

  /// Kiểm mọi hộp thư (AC-82). Đang kiểm thì trả về lần đang chạy. Không ném
  /// lỗi: lỗi của từng hộp thư ghi vào [Mailbox.lastError].
  Future<MailCheckOutcome> checkAll(MailCheckTrigger trigger) =>
      _running ??= _checkAll(trigger).whenComplete(() => _running = null);

  Future<MailCheckOutcome> _checkAll(MailCheckTrigger trigger) async {
    // Chưa có ngân hàng nào hỗ trợ: không có thư nào được phép tải, không mở
    // kết nối (AC-83).
    if (_senders.isEmpty) return const MailCheckOutcome();
    var checked = 0, delivered = 0, failed = 0;
    for (final box in await _store.load()) {
      if (box.needsPassword) continue;
      final last = box.lastCheckAt;
      if (trigger != MailCheckTrigger.manual &&
          last != null &&
          _clock().difference(last) < minInterval) {
        continue;
      }
      try {
        delivered += await _checkOne(box);
        checked++;
      } on MailException catch (e) {
        failed++;
        await _update(
          box.id,
          (b) => b.copyWith(
            lastCheckAt: _clock(),
            lastError: e.kind,
            needsPassword: e.kind == MailErrorKind.badCredentials,
          ),
        );
      } catch (_) {
        // Bộ đọc lỗi: không nhớ UID, lần sau đưa lại cả lô.
        failed++;
      }
    }
    return MailCheckOutcome(
      checked: checked,
      delivered: delivered,
      failed: failed,
    );
  }

  Future<int> _checkOne(Mailbox box) async {
    final password = await _store.password(box.id);
    if (password == null) {
      throw const MailException(MailErrorKind.badCredentials);
    }
    final allowed = _senders.addresses;
    return _withSession(box.provider, box.address, password, (s) async {
      final inbox = await s.examineInbox();
      // UIDVALIDITY đổi: UID cũ mất nghĩa, tìm lại từ đầu nhưng vẫn chỉ thư
      // từ ngày kết nối (bộ đọc chống trùng bằng số tham chiếu, AC-86).
      final lastUid = inbox.uidValidity == box.uidValidity ? box.lastUid : 0;
      final found = await s.searchFrom(
        allowed,
        minUid: lastUid + 1,
        since: box.connectedAt,
      );
      // `UID n:*` luôn trả thư lớn nhất kể cả khi nó < n: lọc lại.
      final uids = (found.where((u) => u > lastUid).toSet().toList()..sort())
          .take(maxPerCheck)
          .toList();
      final mails = <RawMail>[];
      if (uids.isNotEmpty) {
        final headers = [...await s.headers(uids)]
          ..sort((a, b) => a.uid.compareTo(b.uid));
        for (final h in headers) {
          if (h.size > maxMailBytes || !_senders.allows(h.from)) continue;
          final m = await s.body(h.uid);
          if (m == null || !_senders.allows(m.from)) continue;
          mails.add(
            RawMail(
              mailboxId: box.id,
              uid: m.uid,
              from: m.from!,
              bank: _senders.sourceOf(m.from)!,
              subject: m.subject,
              date: m.date,
              textPlain: m.textPlain,
              html: m.html,
            ),
          );
        }
      }
      mails.sort((a, b) => a.uid.compareTo(b.uid));
      final result = mails.isEmpty
          ? const MailHandleResult()
          : await _handler.handle(mails);
      await _update(
        box.id,
        (b) => b.copyWith(
          uidValidity: inbox.uidValidity,
          lastUid: uids.isEmpty ? lastUid : uids.last,
          lastCheckAt: _clock(),
          clearError: true,
          unreadable: b.unreadable + result.unreadable,
        ),
      );
      return mails.length;
    });
  }

  Future<T> _withSession<T>(
    MailProvider provider,
    String address,
    String password,
    Future<T> Function(ImapSession s) run,
  ) async {
    final session = await _connector.open(
      provider,
      address: address,
      password: password,
    );
    try {
      return await run(session);
    } finally {
      await session.close();
    }
  }

  /// Đọc lại danh sách, sửa đúng hộp thư [id] (nếu vẫn còn) rồi ghi.
  Future<Mailbox?> _update(String id, Mailbox Function(Mailbox) change) async {
    final boxes = await _store.load();
    Mailbox? updated;
    final next = [
      for (final b in boxes)
        if (b.id == id) updated = change(b) else b,
    ];
    if (updated != null) await _store.save(next);
    return updated;
  }
}
