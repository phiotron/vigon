import 'package:vigon/src/import/mail/imap_gateway.dart';
import 'package:vigon/src/import/mail/mail_provider.dart';

/// Một thư trong INBOX giả.
class FakeMessage {
  FakeMessage({
    required this.uid,
    required this.from,
    this.subject = 'Biên lai',
    this.text = 'noi dung',
    this.html,
    this.size = 2000,
    DateTime? date,
  }) : date = date ?? DateTime(2026, 11, 6, 12);

  final int uid;
  final String from;
  final String subject;
  final String? text;
  final String? html;
  final int size;
  final DateTime date;
}

/// Máy chủ IMAP giả trong bộ nhớ: một hộp thư cho mỗi địa chỉ, ghi lại mọi
/// lệnh để test kiểm "chỉ đọc" và "chỉ tải thư được phép".
class FakeImapServer implements ImapConnector {
  FakeImapServer({this.passwords = const {}});

  /// Địa chỉ → mật khẩu ứng dụng đúng.
  final Map<String, String> passwords;

  /// Địa chỉ → thư trong INBOX.
  final inbox = <String, List<FakeMessage>>{};

  int uidValidity = 7;

  /// Lỗi ném ra khi mở phiên (mô phỏng mạng/IMAP tắt).
  MailException? failOpen;

  /// Lỗi ném ra khi tìm thư (mất mạng giữa chừng).
  MailException? failSearch;

  final log = <String>[];
  final hostsUsed = <String>[];
  int opens = 0;

  /// Thư đã tải thân (UID).
  final bodiesFetched = <int>[];

  @override
  Future<ImapSession> open(
    MailProvider provider, {
    required String address,
    required String password,
  }) async {
    opens++;
    hostsUsed.add(provider.host);
    log.add('LOGIN $address');
    if (failOpen != null) throw failOpen!;
    if (passwords[address] != password) {
      throw const MailException(MailErrorKind.badCredentials);
    }
    return _FakeSession(this, address);
  }

  void deliver(String address, FakeMessage m) => (inbox[address] ??= []).add(m);
}

class _FakeSession implements ImapSession {
  _FakeSession(this.server, this.address);

  final FakeImapServer server;
  final String address;

  List<FakeMessage> get _box => server.inbox[address] ?? const [];

  @override
  Future<InboxState> examineInbox() async {
    server.log.add('EXAMINE INBOX');
    final maxUid = _box.fold(0, (m, x) => x.uid > m ? x.uid : m);
    return InboxState(uidValidity: server.uidValidity, uidNext: maxUid + 1);
  }

  @override
  Future<List<int>> searchFrom(
    Set<String> senders, {
    required int minUid,
    required DateTime since,
  }) async {
    server.log.add('UID SEARCH');
    if (server.failSearch != null) throw server.failSearch!;
    final sinceDay = DateTime(since.year, since.month, since.day);
    final hits = [
      for (final m in _box)
        // Như IMAP thật: FROM là chuỗi con; `n:*` luôn gồm thư lớn nhất.
        if (senders.any((s) => m.from.toLowerCase().contains(s)) &&
            !m.date.isBefore(sinceDay))
          m.uid,
    ];
    final maxUid = _box.fold(0, (m, x) => x.uid > m ? x.uid : m);
    return [
      for (final u in hits)
        if (u >= minUid || u == maxUid) u,
    ];
  }

  @override
  Future<List<MailHeader>> headers(List<int> uids) async {
    server.log.add('UID FETCH HEADERS');
    return [
      for (final m in _box)
        if (uids.contains(m.uid))
          MailHeader(uid: m.uid, size: m.size, from: m.from.toLowerCase()),
    ];
  }

  @override
  Future<ParsedMail?> body(int uid) async {
    server.log.add('UID FETCH BODY.PEEK[]');
    server.bodiesFetched.add(uid);
    final m = _box.where((m) => m.uid == uid).firstOrNull;
    if (m == null) return null;
    return ParsedMail(
      uid: m.uid,
      from: m.from.toLowerCase(),
      subject: m.subject,
      date: m.date,
      textPlain: m.text,
      html: m.html,
    );
  }

  @override
  Future<void> close() async => server.log.add('LOGOUT');
}
