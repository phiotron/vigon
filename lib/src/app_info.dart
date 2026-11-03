/// Thông tin liên hệ và pháp lý hiện trong màn Giới thiệu (AC-41, D-008).
/// Đổi ở đây là đủ; `/release` chặn khi [privacyPolicyUrl] còn trống.
abstract final class AppInfo {
  /// Email nhận báo lỗi bảo mật và câu hỏi về quyền riêng tư (COMPLIANCE S-05).
  static const contactEmail = 'phamphuongphuong@gmail.com';

  /// Trang chính sách quyền riêng tư công khai; điền khi người dùng đã đăng
  /// nội dung `docs/legal/privacy-policy.md` lên Google Sites.
  static const privacyPolicyUrl = '';
}
