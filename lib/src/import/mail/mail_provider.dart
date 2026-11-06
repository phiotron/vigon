/// Nhà cung cấp hộp thư được hỗ trợ (AC-78, AC-80, D-031): chỉ ba nhà cung cấp,
/// máy chủ IMAP cố định, cổng 993, TLS ngay từ đầu (không STARTTLS, không bản
/// rõ). Người dùng không nhập được máy chủ nào khác.
enum MailProvider {
  gmail(
    host: 'imap.gmail.com',
    label: 'Gmail',
    appPasswordUrl: 'https://myaccount.google.com/apppasswords',
  ),
  yahoo(
    host: 'imap.mail.yahoo.com',
    label: 'Yahoo',
    appPasswordUrl: 'https://login.yahoo.com/account/security',
  ),
  icloud(
    host: 'imap.mail.me.com',
    label: 'iCloud',
    appPasswordUrl: 'https://account.apple.com/account/manage',
  );

  const MailProvider({
    required this.host,
    required this.label,
    required this.appPasswordUrl,
  });

  /// Máy chủ IMAP duy nhất được kết nối cho nhà cung cấp này.
  final String host;

  /// Tên hiển thị (tên riêng, không dịch).
  final String label;

  /// Trang tạo mật khẩu ứng dụng, mở bằng trình duyệt ngoài app.
  final String appPasswordUrl;

  /// IMAP qua TLS ngay từ đầu (IMAPS).
  static const port = 993;

  static MailProvider? byName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Mọi máy chủ app được phép kết nối IMAP (AC-80). Test canh danh sách này.
final allowedImapHosts = {for (final p in MailProvider.values) p.host};

/// Tối đa số hộp thư (AC-78, mặc định S0).
const maxMailboxes = 3;

/// Địa chỉ email hợp lệ ở mức đủ dùng: một `@`, có tên miền có dấu chấm, không
/// khoảng trắng. Máy chủ mới là nơi kiểm thật (đăng nhập thử).
bool isPlausibleEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
