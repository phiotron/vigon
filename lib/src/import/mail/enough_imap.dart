import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as em;

import 'imap_gateway.dart';
import 'mail_provider.dart';

/// Nơi gọi mạng IMAP DUY NHẤT của app (AC-80, AC-125; nơi còn lại là tải tỉ
/// giá `lib/src/data/exchange_rate.dart`).
///
/// - Chỉ ba máy chủ của [MailProvider], cổng 993, TLS ngay từ đầu
///   (`isSecure: true`): không nâng cấp TLS giữa chừng, không bản rõ.
/// - Chứng chỉ kiểm theo hệ thống: không truyền hàm chấp nhận chứng chỉ xấu, nên chứng
///   chỉ không hợp lệ làm kết nối thất bại.
/// - Không bật log của thư viện (lệnh LOGIN có mật khẩu).
class EnoughImapConnector implements ImapConnector {
  const EnoughImapConnector({
    this.connectTimeout = const Duration(seconds: 20),
    this.responseTimeout = const Duration(seconds: 30),
  });

  final Duration connectTimeout;
  final Duration responseTimeout;

  @override
  Future<ImapSession> open(
    MailProvider provider, {
    required String address,
    required String password,
  }) async {
    final host = provider.host;
    if (!allowedImapHosts.contains(host)) {
      throw const MailException(MailErrorKind.server);
    }
    final client = em.ImapClient(
      isLogEnabled: false,
      defaultResponseTimeout: responseTimeout,
    );
    try {
      await client.connectToServer(
        host,
        MailProvider.port,
        isSecure: true,
        timeout: connectTimeout,
      );
      await client.login(address, password);
      return _EnoughSession(client);
    } catch (e) {
      await _quietDisconnect(client);
      throw classifyImapError(e, duringLogin: true);
    }
  }
}

class _EnoughSession implements ImapSession {
  _EnoughSession(this._client);

  final em.ImapClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw classifyImapError(e, duringLogin: false);
    }
  }

  @override
  Future<InboxState> examineInbox() => _guard(() async {
    final box = await _client.examineMailbox(
      em.Mailbox(
        encodedName: 'INBOX',
        encodedPath: 'INBOX',
        flags: [em.MailboxFlag.inbox],
        pathSeparator: '/',
      ),
    );
    var uidNext = box.uidNext;
    if (uidNext == null) {
      // Máy chủ không báo UIDNEXT: lấy UID lớn nhất hiện có.
      final all = await _client.uidSearchMessages(searchCriteria: 'ALL');
      final ids = all.matchingSequence?.toList() ?? const <int>[];
      uidNext = ids.isEmpty ? 1 : ids.reduce((a, b) => a > b ? a : b) + 1;
    }
    return InboxState(uidValidity: box.uidValidity ?? 0, uidNext: uidNext);
  });

  @override
  Future<List<int>> searchFrom(
    Set<String> senders, {
    required int minUid,
    required DateTime since,
  }) => _guard(() async {
    if (senders.isEmpty) return const [];
    final result = await _client.uidSearchMessages(
      searchCriteria: buildSearchCriteria(
        senders,
        minUid: minUid,
        since: since,
      ),
    );
    return result.matchingSequence?.toList() ?? const [];
  });

  @override
  Future<List<MailHeader>> headers(List<int> uids) => _guard(() async {
    if (uids.isEmpty) return const [];
    final result = await _client.uidFetchMessages(
      em.MessageSequence.fromIds(uids, isUid: true),
      '(UID RFC822.SIZE ENVELOPE)',
    );
    return [
      for (final m in result.messages)
        if (m.uid != null)
          MailHeader(
            uid: m.uid!,
            size: m.size ?? 0,
            from: m.from?.firstOrNull?.email.trim().toLowerCase(),
          ),
    ];
  });

  @override
  Future<ParsedMail?> body(int uid) => _guard(() async {
    final result = await _client.uidFetchMessages(
      em.MessageSequence.fromIds([uid], isUid: true),
      '(UID BODY.PEEK[])',
    );
    if (result.messages.isEmpty) return null;
    return parseMime(result.messages.first, uid);
  });

  @override
  Future<void> close() async {
    try {
      await _client.logout().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await _quietDisconnect(_client);
  }
}

/// Giải mã một thư MIME đã tải: địa chỉ gửi, tiêu đề, ngày, phần chữ và HTML
/// (đã giải quoted-printable/base64 và bảng mã). Bỏ qua file đính kèm.
ParsedMail parseMime(em.MimeMessage m, int uid) => ParsedMail(
  uid: m.uid ?? uid,
  from: m.from?.firstOrNull?.email.trim().toLowerCase(),
  subject: m.decodeSubject() ?? '',
  date: m.decodeDate()?.toLocal(),
  textPlain: m.decodeTextPlainPart(),
  html: m.decodeTextHtmlPart(),
);

Future<void> _quietDisconnect(em.ImapClient client) async {
  try {
    await client.disconnect();
  } catch (_) {}
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Điều kiện `UID SEARCH`: `UID <minUid>:* SINCE d-Mon-yyyy` và các `FROM`
/// nối bằng `OR`. Địa chỉ bị bỏ ký tự có thể phá câu lệnh (`"`, `\`, xuống
/// dòng).
String buildSearchCriteria(
  Set<String> senders, {
  required int minUid,
  required DateTime since,
}) {
  final list = [
    for (final s in senders)
      s.replaceAll(RegExp(r'["\\\r\n]'), '').trim().toLowerCase(),
  ]..removeWhere((s) => s.isEmpty);
  list.sort();
  String from(List<String> s) => s.length == 1
      ? 'FROM "${s.first}"'
      : 'OR FROM "${s.first}" (${from(s.sublist(1))})';
  final date = '${since.day}-${_months[since.month - 1]}-${since.year}';
  final start = minUid < 1 ? 1 : minUid;
  return 'UID $start:* SINCE $date ${from(list)}';
}

/// Phân loại lỗi của thư viện/mạng thành [MailException] (không giữ chữ của
/// máy chủ). [duringLogin]: lỗi lệnh lúc đăng nhập là sai thông tin, trừ khi
/// máy chủ nói IMAP chưa bật.
MailException classifyImapError(Object e, {required bool duringLogin}) {
  if (e is MailException) return e;
  if (e is HandshakeException || e is TlsException) {
    return const MailException(MailErrorKind.secureConnection);
  }
  if (e is SocketException || e is TimeoutException) {
    return const MailException(MailErrorKind.noNetwork);
  }
  if (e is em.ImapException) {
    final details = e.details;
    if (details is Exception && details is! em.ImapException) {
      return classifyImapError(details, duringLogin: duringLogin);
    }
    final text = '${e.message ?? ''} $details'.toLowerCase();
    if (_imapDisabled.any(text.contains)) {
      return const MailException(MailErrorKind.imapDisabled);
    }
    if (duringLogin || _authFailed.any(text.contains)) {
      return const MailException(MailErrorKind.badCredentials);
    }
    return const MailException(MailErrorKind.server);
  }
  return const MailException(MailErrorKind.server);
}

/// Chữ máy chủ dùng khi IMAP chưa bật (Gmail: "Your account is not enabled for
/// IMAP use", "IMAP access is disabled").
const _imapDisabled = [
  'not enabled for imap',
  'imap access is disabled',
  'imap is disabled',
  'enable imap',
];

const _authFailed = [
  'authenticationfailed',
  'authentication failed',
  'invalid credentials',
  'application-specific password',
  'login failed',
];
