/// Thông tin liên hệ và pháp lý hiện trong Cài đặt → Giới thiệu (AC-41, D-039).
/// Đổi ở đây là đủ; `/release` chặn khi URL chính sách hoặc điều khoản còn trống.
abstract final class AppInfo {
  /// Email nhận báo lỗi bảo mật, góp ý và câu hỏi về quyền riêng tư (COMPLIANCE S-05).
  static const contactEmail = 'phamphuongphuongnd@gmail.com';

  /// Mã ứng dụng trên Google Play (hàng "Đánh giá").
  static const androidPackage = 'com.phiotron.vigon';

  /// Mã số App Store; còn `null` thì hàng "Đánh giá" ẩn trên iOS (không có nút chết).
  static const appStoreId = null;

  /// Trang công khai trong repo `phamphuongphuongnd/legal` (nguồn: `store/legal/`).
  /// Mở đúng ngôn ngữ app; không mở được thì đọc bản nhúng trong app.
  static const privacyPolicyUrlVi =
      'https://phamphuongphuongnd.github.io/legal/vigon/privacy-policy.vi.html';
  static const privacyPolicyUrlEn =
      'https://phamphuongphuongnd.github.io/legal/vigon/privacy-policy.en.html';
  static const termsUrlVi =
      'https://phamphuongphuongnd.github.io/legal/vigon/terms-of-use.vi.html';
  static const termsUrlEn =
      'https://phamphuongphuongnd.github.io/legal/vigon/terms-of-use.en.html';

  /// Trang hỗ trợ (Support URL của App Store).
  static const supportUrlVi =
      'https://phamphuongphuongnd.github.io/legal/vigon/support.vi.html';
  static const supportUrlEn =
      'https://phamphuongphuongnd.github.io/legal/vigon/support.en.html';

  /// `vi` (hoặc bắt đầu bằng `vi`) dùng bản tiếng Việt, còn lại dùng bản tiếng Anh.
  static String privacyPolicyUrl(String localeName) =>
      localeName.startsWith('vi') ? privacyPolicyUrlVi : privacyPolicyUrlEn;

  static String termsUrl(String localeName) =>
      localeName.startsWith('vi') ? termsUrlVi : termsUrlEn;
}
