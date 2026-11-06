import 'bank_senders.dart';

/// Một email thô vừa tải từ hộp thư, CHỈ của địa chỉ gửi được phép (AC-81).
///
/// Chỉ sống trong bộ nhớ: lớp lấy thư đưa cho [ReceiptMailHandler] rồi bỏ;
/// không ghi vào cơ sở dữ liệu, file hay log. Không có file đính kèm, không có
/// ảnh; thư lớn hơn [maxMailBytes] bị bỏ trước khi tải thân thư.
class RawMail {
  const RawMail({
    required this.mailboxId,
    required this.uid,
    required this.from,
    required this.bank,
    required this.subject,
    required this.date,
    this.textPlain,
    this.html,
  });

  /// Hộp thư nguồn (id nội bộ, không phải địa chỉ).
  final String mailboxId;

  /// UID IMAP trong INBOX của hộp thư đó.
  final int uid;

  /// Địa chỉ gửi, viết thường, đã kiểm nằm trong danh sách cho phép.
  final String from;

  /// Ngân hàng nguồn ứng với [from].
  final BankSource bank;

  /// Tiêu đề đã giải mã (có thể rỗng).
  final String subject;

  /// Trường `Date:` của thư (giờ máy), null nếu thiếu/không đọc được.
  final DateTime? date;

  /// Phần `text/plain` đã giải mã, nếu có.
  final String? textPlain;

  /// Phần `text/html` đã giải mã, nếu có. Không được hiển thị hay tải gì từ
  /// đây; dùng [bodyText] để đọc như chữ (AC-81).
  final String? html;

  /// Thân thư dạng chữ: ưu tiên `text/plain`, không có thì bỏ thẻ HTML.
  String get bodyText {
    final plain = textPlain;
    if (plain != null && plain.trim().isNotEmpty) return plain;
    final h = html;
    return h == null ? '' : htmlToText(h);
  }

  @override
  String toString() => 'RawMail(uid: $uid)'; // không in nội dung
}

/// Thư lớn hơn mức này bị bỏ, không tải (AC-81).
const maxMailBytes = 256 * 1024;

/// Kết quả xử lý một lô thư của bộ đọc (M1).
class MailHandleResult {
  const MailHandleResult({this.unreadable = 0});

  /// Số email của ngân hàng nhưng không đọc được đủ trường (AC-85); lớp lấy
  /// thư cộng vào bộ đếm "N email MB không đọc được" của hộp thư.
  final int unreadable;
}

/// Điểm cắm bộ đọc email biên lai (M1, F-29).
///
/// Lớp lấy thư gọi [handle] với các thư MỚI (UID lớn hơn UID đã đọc, theo thứ
/// tự UID tăng dần) của một hộp thư. Trả về bình thường thì UID lớn nhất của
/// lô được ghi nhớ và các thư này không bao giờ được đưa lại; ném lỗi thì UID
/// không đổi và lần kiểm sau đưa lại cả lô (chống trùng bằng số tham chiếu,
/// AC-86, là việc của bộ đọc).
abstract class ReceiptMailHandler {
  Future<MailHandleResult> handle(List<RawMail> mails);
}

/// Chưa có bộ đọc (trước M1): bỏ thư, không lưu gì.
class DiscardingMailHandler implements ReceiptMailHandler {
  const DiscardingMailHandler();

  @override
  Future<MailHandleResult> handle(List<RawMail> mails) async =>
      const MailHandleResult();
}

/// Đọc HTML như chữ (AC-81): bỏ `<style>`, `<script>`, `<head>`, mọi thẻ; đổi
/// `<br>`, `</p>`, `</div>`, `</tr>`, `</li>` thành xuống dòng và `</td>`,
/// `</th>` thành tab; giải mã thực thể thường gặp; gộp khoảng trắng mỗi dòng.
/// Không tải ảnh hay link nào.
String htmlToText(String html) {
  var s = html.replaceAll(
    RegExp(
      r'<(style|script|head|title)\b[^>]*>.*?</\1\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    ' ',
  );
  s = s.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');
  s = s.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(
    RegExp(r'</\s*(p|div|tr|li|h[1-6]|table)\s*>', caseSensitive: false),
    '\n',
  );
  s = s.replaceAll(RegExp(r'</\s*(td|th)\s*>', caseSensitive: false), '\t');
  s = s.replaceAll(RegExp(r'<[^>]*>'), '');
  s = _decodeEntities(s);
  final lines = [
    for (final line in s.split(RegExp(r'\r?\n')))
      line
          .split('\t')
          .map((c) => c.replaceAll(RegExp(r'[  \f\v]+'), ' ').trim())
          .where((c) => c.isNotEmpty)
          .join('\t'),
  ].where((l) => l.isNotEmpty);
  return lines.join('\n');
}

String _decodeEntities(String s) =>
    s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'), (m) {
      final e = m[1]!;
      if (e.startsWith('#x') || e.startsWith('#X')) {
        final code = int.tryParse(e.substring(2), radix: 16);
        return code == null ? m[0]! : String.fromCharCode(code);
      }
      if (e.startsWith('#')) {
        final code = int.tryParse(e.substring(1));
        return code == null ? m[0]! : String.fromCharCode(code);
      }
      return switch (e.toLowerCase()) {
        'nbsp' => ' ',
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        _ => m[0]!,
      };
    });
