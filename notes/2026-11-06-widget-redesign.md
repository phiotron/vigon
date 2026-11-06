# [A002-vigon] Thiết kế lại widget màn hình chính — 2026-11-06

Phiên con (brief từ phiên điều phối). Commit trên `dev`: `76a6583` (mã + token + test), commit ghi chú này ngay sau.

## Bối cảnh
Người dùng xem widget 2×2 thật trên Galaxy A13: "như này nhìn xấu quá" (nền xanh đậm `#0E5244`, hai khối đặc đỏ/xanh lá).
Đưa 3 hướng mô phỏng (A Tonal Material You · **B Ngọc lục bảo & vàng** · C Tối giản nút tròn) → người dùng **chọn B**.

## Đã làm
- **Kiểu B (Android 2×2 + 4×2):** nền ngà `#FBF8F1` (sáng) / ngọc lục bảo sâu `#0A2F27` (tối), dải chuyển màu rất nhẹ góc trên
  trái → dưới phải, viền vàng mảnh 1dp. Hàng trên: logo bo góc (`drawable/ic_widget_logo.xml`, thay mipmap vuông) + "Ví Gọn" chữ
  medium giãn nhẹ. Dòng trạng thái (chi tháng / khóa PIN / mở app để cập nhật) màu **vàng** `widget-gold`, icon khóa/cập nhật cũng vàng.
  Hai nút: khối trong mờ `widget-action` bo 16, huy hiệu tròn đỏ `#C0463A` dấu − / xanh `#1F7A5C` dấu + (vector trắng), chữ `widget-ink`.
- **Sáng/tối:** theo chế độ máy (`values/` + `values-night/widget_colors.xml`). **Không dùng màu động Android 12+**: màu thương hiệu
  vàng/ngọc là điểm chính của hướng B, ăn theo hình nền sẽ mất.
- **Giữ nguyên chức năng:** cùng id (`widget_header/icon/brand/status/expense/income`), route `/entry/new?type=expense|income` và `/`,
  `contentDescription` "Thêm khoản chi/thu", nút minHeight 48dp, cỡ tối thiểu 110dp, status maxLines 2 (2×2) / 1 (4×2), chữ nút
  `ellipsize=end`. Chỉ class RemoteViews cho phép (LinearLayout, FrameLayout, ImageView, TextView). Kotlin chỉ đổi icon logo.
- **Token v3 widget-\*** (`design/hifi/tokens/tokens.json` + `.css` + CHANGELOG, sinh lại `tokens.g.dart`): 5 token đổi giá trị,
  thêm `widget-surface-end`, `widget-gold`, `widget-outline`, `widget-action`. Bỏ chuỗi `widget_glyph_*` (thay bằng icon).
- **iOS widget** (`ios/VigonWidget/VigonWidget.swift`) đồng bộ cùng kiểu, sáng/tối theo `colorScheme` (test buộc màu iOS = Android).
- **Test:** `hifi_d4_android_widget_test` (màu từng chủ đề khớp token, nền gradient/viền, huy hiệu oval, icon −/+), `theme_test` (token
  mới + cặp tương phản ≥ 4.5: ink/gold trên hai đầu nền, ink trên nút, trắng trên huy hiệu), `hifi_d4_ios_config_test` (màu tối iOS =
  values-night).

## Kiểm
- `flutter analyze`: sạch. `flutter test`: 620/620 xanh.
- Build `flutter build apk --release` (không arm64-only) từ worktree tách `D:/vigon-wt-widget` ở `76a6583`; `adb install -r` lên A13:
  Success. Chụp màn hình (không chạm): widget 2×2 trên trang 2 tự cập nhật sang kiểu mới, **bản sáng hiển thị đúng** (nền ngà, viền vàng,
  logo, huy hiệu −/+, chữ Chi/Thu không cắt). Ảnh chụp đã xoá (có hình nền cá nhân).

## Chưa kiểm / để ý
- **Bản tối chưa xem trên máy**: máy đang chế độ sáng; không tự đổi cài đặt hệ thống của người dùng. Người dùng bật Chế độ tối để xem.
- Chưa chạm thử nút trên widget sau khi cài (focus là launcher → không chạm theo luật). Id/route không đổi, test canh.
- 4×2 chưa xem trên máy (widget đang đặt cỡ 2×2).
- iOS chỉ sửa mã SwiftUI, **chưa build** (Windows); chờ CI macOS. Dùng `ContainerRelativeShape().stroke`, `.kerning`, `Circle` — API iOS 14+.
- Ở cỡ 2×2 cao (A13: 168×229 dp) hai nút khá cao, chữ nằm trái — nếu người dùng muốn "đầy" hơn có thể tăng cỡ huy hiệu/chữ.
