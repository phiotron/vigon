import 'mail_provider.dart';

/// Loại lỗi hộp thư, mỗi loại một câu báo rõ trên màn hộp thư (AC-78, AC-82).
enum MailErrorKind {
  /// "Sai địa chỉ hoặc mật khẩu ứng dụng" → dừng kiểm tự động tới khi nhập lại.
  badCredentials,

  /// "Hộp thư chưa bật IMAP".
  imapDisabled,

  /// "Không có mạng" (không kết nối được, hết giờ chờ).
  noNetwork,

  /// Không lập được kết nối an toàn (chứng chỉ không hợp lệ theo hệ thống).
  secureConnection,

  /// Máy chủ trả lỗi khác.
  server,
}

/// Lỗi đã phân loại. KHÔNG mang chữ máy chủ trả về hay mật khẩu (không vào
/// log, AC-79).
class MailException implements Exception {
  const MailException(this.kind);

  final MailErrorKind kind;

  @override
  String toString() => 'MailException(${kind.name})';
}

/// Trạng thái INBOX khi mở chỉ xem (EXAMINE).
class InboxState {
  const InboxState({required this.uidValidity, required this.uidNext});

  final int uidValidity;

  /// UID mà thư đến kế tiếp sẽ nhận.
  final int uidNext;
}

/// Thông tin đầu thư (không có thân thư).
class MailHeader {
  const MailHeader({required this.uid, required this.size, this.from});

  final int uid;

  /// Cỡ thư (RFC822.SIZE), byte.
  final int size;

  /// Địa chỉ gửi trong phong bì, viết thường.
  final String? from;
}

/// Thư đã tải và giải mã (chỉ trong bộ nhớ).
class ParsedMail {
  const ParsedMail({
    required this.uid,
    this.from,
    this.subject = '',
    this.date,
    this.textPlain,
    this.html,
  });

  final int uid;
  final String? from;
  final String subject;
  final DateTime? date;
  final String? textPlain;
  final String? html;
}

/// Mở phiên IMAP. Bản thật: `EnoughImapConnector` (TLS 993 tới đúng ba máy
/// chủ); test: bản giả trong bộ nhớ.
abstract class ImapConnector {
  /// Kết nối và đăng nhập. Ném [MailException] đã phân loại.
  Future<ImapSession> open(
    MailProvider provider, {
    required String address,
    required String password,
  });
}

/// Một phiên đã đăng nhập. Mọi lệnh đều CHỈ ĐỌC: INBOX mở bằng EXAMINE, thân
/// thư tải bằng `BODY.PEEK[]` (không đánh dấu đã đọc, không xoá, không chuyển,
/// không gửi — AC-81).
abstract class ImapSession {
  Future<InboxState> examineInbox();

  /// UID trong INBOX có địa chỉ gửi là một trong [senders], UID ≥ [minUid],
  /// nhận từ ngày [since] trở đi (máy chủ so theo ngày). Có thể lẫn thư mà
  /// địa chỉ chỉ CHỨA một địa chỉ cho phép (tìm của IMAP là chuỗi con): bên
  /// gọi phải lọc lại đúng nguyên địa chỉ.
  Future<List<int>> searchFrom(
    Set<String> senders, {
    required int minUid,
    required DateTime since,
  });

  Future<List<MailHeader>> headers(List<int> uids);

  /// Tải và giải mã một thư; null nếu máy chủ không trả thư đó.
  Future<ParsedMail?> body(int uid);

  /// Đăng xuất và đóng kết nối; không ném lỗi.
  Future<void> close();
}
