# PLAN-001 · Giao diện theo thiết kế và bản iOS — APP-001

Đã duyệt: 2026-11-04
Ngày tạo: 2026-11-04
Trạng thái: đang làm (T1–T4 xong, T5 và T6 xong phần code; còn so ảnh, thử máy, build iOS)
Liên quan SPEC: mục 4 và 5 (iOS vào phạm vi, giao diện theo `design-mobile/screens/`); mọi F-01…F-13 giữ nguyên chức năng. D-010, D-011.

## 1. Mục tiêu và lý do
Bộ thiết kế mobile đã duyệt (`design-mobile/screens/`) dùng chung iPhone và Android. App hiện là Flutter làm xong G1–G6 nhưng theme sinh màu tự động (`fromSeed`), font và icon mặc định, và chỉ có Android. Mục tiêu: mọi màn giống bản vẽ (màu, chữ, icon, khoảng cách, sáng/tối) và chạy được trên iPhone từ cùng codebase, không đổi logic hay dữ liệu.

Người dùng chọn (2026-11-04): giữ Flutter, không viết lại bằng Ionic + Capacitor; build iOS trên cloud vì máy phát triển là Windows.

## 2. Phạm vi
- Làm: theme từ token; font Be Vietnam Pro; icon Material Symbols Rounded; dựng lại thành phần dùng chung và 16 nhóm màn S01–S16 theo bản vẽ; lịch "Khoảng tùy chọn" trong bảng kéo (2.5); thêm nền tảng iOS, cấu hình Info.plist, privacy manifest, CI build iOS không ký.
- KHÔNG làm: đổi chức năng, dữ liệu, định dạng file sao lưu; tab bar (README thiết kế cấm); logo (D-009 đã có); nộp App Store, ký iOS (việc của người dùng); chụp lại ảnh store (ghi BACKLOG).

## 3. Tiêu chí chấp nhận
- UI-01: Khi xem bất kỳ màn nào ở sáng và tối, màu nền, chữ, nút, viền lấy từ token trong `tokens.json` (không còn `ColorScheme.fromSeed`, không mã màu gõ tay trong widget ngoài file sinh). [T: test so màu theme với token]
- UI-02: Chữ giao diện là Be Vietnam Pro đóng trong app, số tiền dùng số đều độ rộng; app vẫn không có quyền INTERNET. [T + aapt2]
- UI-03: Icon chức năng và 31 icon danh mục là Material Symbols Rounded đúng danh sách trong `design-system-guide.md`; khóa icon cũ trong dữ liệu hoặc file sao lưu cũ vẫn hiện icon. [T]
- UI-04: Mỗi khung trong `design-mobile/screens/components/S01…S16` có màn tương ứng khớp bố cục, kích thước (vùng chạm 48/56/64, bo góc, lề 16) và chữ. [M: so ảnh chụp widget test 360×800 với `xem/*.html`]
- UI-05: Mọi test cũ (116) và `g6_accessibility_test` vẫn đạt ở sáng/tối, 100%/200%; tương phản các cặp token đang dùng đạt 4,5:1 cho chữ, 3:1 cho viền và icon. [T]
- UI-06: Chọn "Khoảng tùy chọn" mở lịch trong bảng kéo, chọn ngày đầu và cuối thì kỳ đổi đúng. [T]
- iOS-01: `flutter build ios --release --no-codesign` đạt trên máy macOS của CI. [CI]
- iOS-02: Gỡ app iOS rồi cài lại thì không còn bị khóa bởi PIN cũ. [T + M iPhone]
- iOS-03: Trên iPhone mọi màn con có nút quay lại nhìn thấy được; vuốt mép trái quay lại được. [T + M iPhone]
- Android: thử máy thật Galaxy A13 các luồng chính sau T5, ghi biên bản. [M]

## 4. Thiết kế đề xuất
- `tool/gen_tokens.py` → `lib/src/ui/tokens.g.dart` (`VgColors` sáng/tối, `VgSpace`, `VgRadius`, `VgTap`); `lib/src/ui/theme.dart` dựng `ThemeData` sáng/tối (ColorScheme, TextTheme 12 style, `ViGonColors` ThemeExtension, theme cho AppBar căn trái, SnackBar, Dialog, BottomSheet, Chip, Switch, chuyển trang Cupertino trên iOS).
- Font: `assets/fonts/BeVietnamPro-{Regular,Medium,SemiBold,Bold}.ttf` (OFL), đăng ký giấy phép OFL trong `LicenseRegistry`.
- Icon: gói `material_symbols_icons`.
- Màn: sửa trong `lib/src/features/*` và `lib/src/ui/*`; không đổi provider, repository, schema.
- iOS: `ios/` từ `flutter create`, `Info.plist` (chỉ dọc, `CFBundleLocalizations` vi/en, `LSApplicationQueriesSchemes`, `ITSAppUsesNonExemptEncryption` false), `PrivacyInfo.xcprivacy`; xóa PIN cũ khi cơ sở dữ liệu vừa tạo mới.
- Phương án đã loại: viết lại Ionic + Capacitor; tải font lúc chạy; đổi khóa icon sang số (D-010, D-011).

## 5. Các bước thực hiện
Mỗi giai đoạn xong: `flutter analyze` sạch, `dart format lib test`, `flutter test` đạt, rồi dừng ở cổng chờ người dùng.
1. T1 · Nền thiết kế: sinh token, theme mới, font, gói icon; sửa test phụ thuộc màu cũ; test so token và tương phản.
2. T2 · Thành phần dùng chung (T1_Nut, T2_BanPhim, T3_ChipDong): nút − Chi / + Thu, bàn phím, hiển thị số tiền, chip, `CategoryAvatar`, vòng biểu đồ và icon quanh vòng, thanh ngân sách, thanh Số dư, bàn phím PIN, bảng kéo, hộp thoại; đổi bộ icon và màu danh mục.
3. T3 · Màn S01–S05: khóa PIN, màn chính, chọn kỳ (lịch khoảng tùy chọn mới), ghi khoản.
4. T4 · Màn S06–S12: các khoản, sửa khoản, cài đặt, ngân sách/tiền tệ, danh mục, tài khoản/chuyển tiền, định kỳ.
5. T5 · Màn S13–S16, so ảnh với bản vẽ, build APK release, thử Galaxy A13 (hỏi người dùng trước khi dùng máy).
6. T6 · iOS: thêm nền tảng, cấu hình, xử lý Keychain, job CI macOS. Người dùng: remote git, Apple Developer, TestFlight, thử iPhone.

## 6. Rủi ro, ảnh hưởng và quay lui
- Phần đang chạy bị ảnh hưởng thế nào: chỉ giao diện; test so màu/bố cục có thể phải sửa theo token (không nới guideline accessibility).
- Dữ liệu người dùng hiện có (cần migration không): không. Icon và màu danh mục cũ vẫn hiện; chỉ lần cài mới dùng màu mặc định mới.
- Dung lượng: font và icon làm APK lớn hơn; đo ở T5 so ngưỡng 25 MB/kiến trúc.
- Cách quay lui nếu hỏng: làm trên nhánh `feature/PLAN-001`; bỏ nhánh là về bản G6.

## 7. Kiểm thử và thử máy thật
- Test mới: theme khớp token, tương phản, khóa icon cũ, lịch khoảng tùy chọn, xóa PIN cũ khi DB mới.
- Thử tay: Galaxy A13 (Android 14, 32-bit, không build `--target-platform`) sau T5; iPhone thật qua TestFlight sau T6 (người dùng, VoiceOver và cỡ chữ lớn nhất).
- Cuối: `/check-ac APP-001` → `/spec-review APP-001 PLAN-001` → người dùng chọn gộp nhánh.

## 8. Câu hỏi còn mở
- Dịch vụ build iOS: bước build KHÔNG ký chạy bằng GitHub Actions (job `ios` trong `.github/workflows/ci.yml`, cần đẩy lên remote); Codemagic hay GitHub Actions cho bước ký và TestFlight còn chờ người dùng.
- (Đã quyết 2026-11-04, D-013) Chọn danh mục ở màn ghi khoản: giữ lưu ngay theo AC-02; bản vẽ 3.3 lệch ở điểm này.
