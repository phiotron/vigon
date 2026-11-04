# RELEASE — Ví Gọn (A002-vigon)

Cập nhật 2026-11-04. Chưa phát hành. Mục nào ghi "CHƯA" là việc còn lại; việc của người dùng ghi rõ.

## Định danh
- Bundle ID / package name: `com.phiotron.vigon` (D-003)
- Phiên bản hiện tại: versionName `1.0.0` / versionCode `1` (`pubspec.yaml`: `version: 1.0.0+1`). Mỗi lần nộp store phải tăng phần sau dấu `+`.
- Store: Google Play [x] · App Store [ ] (v1 chỉ Android, D-001) · phân phối nội bộ [ ]
- minSdk 24 (Android 7.0), targetSdk 36 (kiểm bằng `aapt2 dump badging`, 2026-11-03)
- Quyền: không xin quyền nào; bản release không có INTERNET (`test/manifest_test.dart` và `aapt2 dump permissions`)

## Ký ứng dụng
**Trạng thái: CHƯA có khóa ký phát hành.** Bản `flutter build apk --release` hiện ký bằng khóa debug, chỉ để thử trên máy, KHÔNG nộp store. Cấu hình ký đã sẵn trong `android/app/build.gradle.kts`: có `android/key.properties` thì ký bằng khóa đó; không có thì `flutter build appbundle` bị chặn với thông báo "Thiếu android/key.properties".

Việc của **người dùng** (Claude không tạo, không giữ, không đọc khóa và mật khẩu, quy trình `/release` cấm đụng keystore):

1. Tạo khóa ngoài repo, ví dụ ở `D:\Keys\vigon\` (thư mục này KHÔNG nằm trong `D:\DemoChung`). Trong PowerShell hoặc Git Bash, mở một cửa sổ tại thư mục đó và chạy (keytool có trong thư mục `jbr\bin` của Android Studio):
   ```bash
   keytool -genkeypair -v -keystore vigon-upload.jks -alias vigon -keyalg RSA -keysize 2048 -validity 10000
   ```
   Keytool sẽ hỏi mật khẩu và thông tin; tự đặt và tự nhớ. Cho Play App Signing: khóa này là **khóa tải lên (upload key)**, Google giữ khóa ký thật.
2. **Sao lưu ngay** file `vigon-upload.jks` và mật khẩu sang ít nhất một nơi khác ổ D (USB, kho mật khẩu). Mất khóa tải lên thì phải xin Google đặt lại, mất nhiều ngày (L-005).
3. Tạo file `android/key.properties` (đã nằm trong `.gitignore`, không bao giờ commit) với nội dung, thay bằng giá trị của bạn:
   ```
   storePassword=<mật khẩu kho khóa>
   keyPassword=<mật khẩu khóa>
   keyAlias=vigon
   storeFile=D:/Keys/vigon/vigon-upload.jks
   ```
4. Build bản phát hành: `flutter build appbundle` → file ở `build/app/outputs/bundle/release/app-release.aab`.
5. Kiểm: `flutter build apk --release` rồi `apksigner verify --print-certs` phải hiện tên chủ khóa của bạn, KHÔNG phải "Android Debug".

Nơi cất keystore (NGOÀI repo, có sao lưu): **người dùng điền sau khi tạo:** `____________` · Nơi sao lưu: `____________`
Người giữ mật khẩu: người dùng. KHÔNG ghi mật khẩu vào file này.

Lưu ý: nhánh "có khóa" trong `build.gradle.kts` CHƯA được chạy thử với khóa thật (Claude không tạo khóa). Nếu bước 4 hoặc 5 lỗi, báo lại để sửa cấu hình.

## Hồ sơ store
Nội dung nháp đầy đủ: `store/listing.md`. Ảnh chụp: `store/screenshots/` (6 ảnh 1080×2160, dữ liệu mẫu).
- Tên: **Ví Gọn**. Tên tiếng Anh: CHƯA chốt (gợi ý trong listing.md; phải tra trùng).
- Mô tả ngắn và dài (vi/en): đã viết, chờ người dùng duyệt.
- Ảnh chụp màn hình: đã chụp (6 ảnh). Icon 512×512: đã chốt logo và có file (`store/brand/icon-512.png`, D-009). Ảnh bìa 1024×500: đã vẽ trên canvas Design, CHƯA có PNG (người dùng xuất bằng Share › Export).
- Phân loại: Finance; độ tuổi: từ 13 tuổi, không nhắm trẻ em (chờ quyết Play Age Signals, COMPLIANCE D-12).
- Data safety: không thu thập, không chia sẻ (khớp `docs/SECURITY.md`).
- Đường dẫn chính sách quyền riêng tư: **CHƯA có**. Nội dung ở `docs/legal/privacy-policy.md`; người dùng đăng lên Google Sites rồi gửi đường dẫn, điền vào `lib/src/app_info.dart` (`AppInfo.privacyPolicyUrl`) và Play Console.
- Email liên hệ nhà phát triển: `phamphuongphuong@gmail.com` (đã in trong app và chính sách).

## Điều kiện chặn phát hành (còn lại, 2026-11-04)
- [ ] Khóa ký phát hành (mục trên)
- [ ] Đường dẫn chính sách quyền riêng tư công khai
- [ ] Xuất PNG ảnh bìa 1024×500 từ canvas Design (icon 512×512 đã có); tra trùng nhãn hiệu cho logo và tên
- [ ] Thử TalkBack thật và cỡ chữ lớn nhất (AC-38, AC-39); mở CSV bằng Excel
- [ ] Người dùng quyết: tên cá nhân hay công ty, Play Age Signals; luật sư xác nhận CRA (S-06), DPIA ở Việt Nam (D-07)
- [ ] COMPLIANCE.md còn dòng "chưa" (xem BACKLOG G6) và kiểm lại hạn chót Apple/Google trong ngày nộp
- [ ] Closed test 12 người trong 14 ngày (P-09), sau đó mới nộp bản chính thức
- [ ] Người dùng duyệt rõ ràng trước khi nộp; `/release` chỉ chuẩn bị, KHÔNG nộp store

## Lịch sử phát hành
| Phiên bản | Ngày | Nội dung | Ghi chú |
|-----------|------|----------|---------|
| (chưa có) | | | |

## Sau phát hành
- Theo dõi crash tại: Android vitals trong Google Play Console (app không có SDK báo crash, D-002)
- Nơi nhận phản hồi người dùng: đánh giá trên Google Play và email `phamphuongphuong@gmail.com`
- Mốc rà soát: sau 1 ngày, 1 tuần → ghi kết quả vào BACKLOG; mục tiêu không crash ≥ 99,5%
