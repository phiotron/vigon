import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart' as em;
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/import/mail/bank_senders.dart';
import 'package:vigon/src/import/mail/enough_imap.dart';
import 'package:vigon/src/import/mail/imap_gateway.dart';
import 'package:vigon/src/import/mail/mail_provider.dart';
import 'package:vigon/src/import/mail/raw_mail.dart';

void main() {
  test('chỉ ba máy chủ IMAP, cổng 993 (AC-80)', () {
    expect(allowedImapHosts, {
      'imap.gmail.com',
      'imap.mail.yahoo.com',
      'imap.mail.me.com',
    });
    expect(MailProvider.port, 993);
    for (final p in MailProvider.values) {
      expect(p.appPasswordUrl, startsWith('https://'));
    }
  });

  test('mã IMAP: chỉ TLS ngay từ đầu, kiểm chứng chỉ theo hệ thống, chỉ đọc, '
      'không log (AC-80, AC-81)', () {
    final src = File('lib/src/import/mail/enough_imap.dart').readAsStringSync();
    expect(src, contains('isSecure: true'));
    expect(src, contains('isLogEnabled: false'));
    expect(src, contains('examineMailbox'));
    expect(src, contains('BODY.PEEK[]'));
    for (final banned in [
      'isSecure: false',
      'onBadCertificate',
      'startTls',
      'STARTTLS',
      'selectMailbox',
      'selectInbox',
      'store(',
      'Store(',
      'expunge',
      'move(',
      'copy(',
      'append',
      'markSeen',
      'markDeleted',
      'BODY[]',
      'print(',
      'debugPrint',
    ]) {
      expect(
        src.replaceAll('BODY.PEEK[]', '').contains(banned),
        isFalse,
        reason: 'có $banned',
      );
    }
  });

  test('điều kiện tìm: UID mới, từ ngày kết nối, các địa chỉ nối OR', () {
    expect(
      buildSearchCriteria(
        {'a@mb.vn'},
        minUid: 41,
        since: DateTime(2026, 11, 6, 9),
      ),
      'UID 41:* SINCE 6-Nov-2026 FROM "a@mb.vn"',
    );
    expect(
      buildSearchCriteria(
        {'c@mb.vn', 'A@mb.vn', 'b"@mb.vn'},
        minUid: 0,
        since: DateTime(2026, 1, 31),
      ),
      'UID 1:* SINCE 31-Jan-2026 '
      'OR FROM "a@mb.vn" (OR FROM "b@mb.vn" (FROM "c@mb.vn"))',
    );
  });

  group('phân loại lỗi (AC-78)', () {
    MailErrorKind kind(Object e, {bool login = true}) =>
        classifyImapError(e, duringLogin: login).kind;
    final client = em.ImapClient();

    test('mạng', () {
      expect(
        kind(const SocketException('Failed host lookup')),
        MailErrorKind.noNetwork,
      );
      expect(kind(TimeoutException('t')), MailErrorKind.noNetwork);
      expect(
        kind(
          em.ImapException(client, 'x', details: const SocketException('y')),
        ),
        MailErrorKind.noNetwork,
      );
    });

    test('chứng chỉ không hợp lệ', () {
      expect(
        kind(const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
        MailErrorKind.secureConnection,
      );
    });

    test('IMAP chưa bật', () {
      expect(
        kind(
          em.ImapException(
            client,
            '[ALERT] Your account is not enabled for IMAP use.',
          ),
        ),
        MailErrorKind.imapDisabled,
      );
    });

    test('sai thông tin đăng nhập', () {
      expect(
        kind(
          em.ImapException(
            client,
            '[AUTHENTICATIONFAILED] Invalid credentials (Failure)',
          ),
        ),
        MailErrorKind.badCredentials,
      );
      expect(
        kind(
          em.ImapException(
            client,
            '[ALERT] Application-specific password required',
          ),
        ),
        MailErrorKind.badCredentials,
      );
      // Lỗi lệnh khác sau khi đã đăng nhập là lỗi máy chủ, không phải mật khẩu.
      expect(
        kind(em.ImapException(client, 'BAD command'), login: false),
        MailErrorKind.server,
      );
    });

    test('lỗi không lộ chữ của máy chủ', () {
      final e = classifyImapError(
        em.ImapException(client, 'NO secret-detail me@gmail.com'),
        duringLogin: true,
      );
      expect('$e', isNot(contains('gmail')));
    });
  });

  test('giải mã thư MIME: tiếng Việt UTF-8 quoted-printable, HTML, bỏ đính '
      'kèm', () {
    const raw =
        'From: "MB Bank" <ThongBao@MB.vn>\r\n'
        'To: me@gmail.com\r\n'
        'Subject: =?UTF-8?B?QmnDqm4gbGFp?=\r\n'
        'Date: Thu, 06 Nov 2026 12:02:00 +0700\r\n'
        'MIME-Version: 1.0\r\n'
        'Content-Type: multipart/mixed; boundary="b1"\r\n'
        '\r\n'
        '--b1\r\n'
        'Content-Type: multipart/alternative; boundary="b2"\r\n'
        '\r\n'
        '--b2\r\n'
        'Content-Type: text/plain; charset=UTF-8\r\n'
        'Content-Transfer-Encoding: quoted-printable\r\n'
        '\r\n'
        'S=E1=BB=91 ti=E1=BB=81n: 50.000 VND\r\n'
        '--b2\r\n'
        'Content-Type: text/html; charset=UTF-8\r\n'
        '\r\n'
        '<p>Số tiền: <b>50.000</b> VND<img src="https://x.test/t.png"></p>\r\n'
        '--b2--\r\n'
        '--b1\r\n'
        'Content-Type: application/pdf; name="a.pdf"\r\n'
        'Content-Disposition: attachment; filename="a.pdf"\r\n'
        'Content-Transfer-Encoding: base64\r\n'
        '\r\n'
        'JVBERi0xLjQ=\r\n'
        '--b1--\r\n';
    final m = parseMime(em.MimeMessage.parseFromText(raw), 12);
    expect(m.uid, 12);
    expect(m.from, 'thongbao@mb.vn');
    expect(m.subject, 'Biên lai');
    expect(m.date, DateTime.utc(2026, 11, 6, 5, 2).toLocal());
    expect(m.textPlain?.trim(), 'Số tiền: 50.000 VND');
    expect(m.html, contains('<b>50.000</b>'));
  });

  test('đọc HTML như chữ: bỏ thẻ, style, script, ảnh; giữ dòng và ô bảng', () {
    final text = htmlToText(
      '<html><head><style>p{color:red}</style><title>T</title></head><body>'
      '<script>alert(1)</script>'
      '<table><tr><td>Số tiền</td><td>50.000&nbsp;VND</td></tr>'
      '<tr><td>Người thụ hưởng</td><td>CONG TY &amp; CO</td></tr></table>'
      'Dòng 1<br/>Dòng&#32;2 &#x1EA1;<img src="https://x.test/a.png">'
      '</body></html>',
    );
    expect(
      text,
      'Số tiền\t50.000 VND\nNgười thụ hưởng\tCONG TY & CO\nDòng 1\nDòng 2 ạ',
    );
    const mail = RawMail(
      mailboxId: 'm0',
      uid: 1,
      from: 'a@mb.vn',
      bank: mbBank,
      subject: '',
      date: null,
      html: '<p>Xin chào</p>',
    );
    expect(mail.bodyText, 'Xin chào');
    expect('$mail', 'RawMail(uid: 1)');
  });
}
