# RUNBOOK — Ví Gọn (APP-001)

Hồ sơ để CHẠY LẠI app từ đầu sau nhiều tháng/năm, khi không ai còn nhớ gì. Điền khi app chạy được lần đầu và cập nhật mỗi lần phát hành hoặc build thành công. KHÔNG ghi mật khẩu, khóa hay token vào file này: chỉ ghi tên và nơi lấy.

## 1. Chạy lại từ đầu (các bước đã từng chạy thành công)
1. Mở Git Bash, vào thư mục app. Chạy: `export PATH="/c/src/flutter/bin:$PATH"` (Flutter 3.47.8 ở `C:/src/flutter`, chưa có trong PATH của Windows)
2. `flutter pub get`
3. `flutter analyze` rồi `flutter test` (91 test, vài chục giây)
4. Chạy thử trên máy: nối điện thoại Android bật gỡ lỗi USB, `flutter run`
5. Build APK thử: `flutter build apk --release` (đủ kiến trúc; lần gần nhất thành công là bản G2, xem mục 9; bản G5 đang lỗi, xem mục 10)
6. Cài lên máy: `adb install -r build/app/outputs/flutter-apk/app-release.apk` (adb ở `%LOCALAPPDATA%/Android/Sdk/platform-tools`; trong Git Bash đặt `export MSYS_NO_PATHCONV=1` khi dùng đường dẫn `/sdcard/...`)

## 2. Công cụ và phiên bản đã dùng
(Ghi tay các công cụ cần cài ngoài máy dev thông thường; phiên bản tự động ghi bằng `bash scripts/snapshot-env.sh APP-001` ở mục 9.)
- Node / trình quản lý gói: không dùng
- Java / Android SDK / Build Tools: JDK Temurin 17; Android SDK ở `%LOCALAPPDATA%/Android/Sdk` (platforms 34 tới 37, build-tools 36 và 37); chưa có cmdline-tools nên chưa chấp nhận được giấy phép SDK bằng `flutter doctor --android-licenses`
- Xcode / CocoaPods (nếu có iOS): không dùng (v1 chỉ Android)
- Công cụ dòng lệnh khác: Flutter 3.47.8 (Dart 3.13.7), Gradle do Flutter tải, `dart run build_runner build` khi sửa bảng drift; không dùng FVM (D-003)

## 3. Tài khoản và dịch vụ (chỉ tên, chủ tài khoản, nơi lấy; không ghi mật khẩu)
| Dịch vụ | Dùng để | Tài khoản/chủ | Nơi lấy thông tin đăng nhập/khóa | Ghi chú (hạn, gói phí) |
|---------|---------|---------------|-----------------------------------|------------------------|
| (chưa có) | Chưa dùng dịch vụ nào. Sau này: tài khoản Google Play Console | | | Closed test 12 người trong 14 ngày (P-09) |

## 4. Biến môi trường (tên và nơi lấy giá trị)
| Biến | Dùng để | Nơi lấy giá trị |
|------|---------|-----------------|
| (không có) | App không dùng biến môi trường hay khóa API | |

## 5. Khóa ký ứng dụng và chứng chỉ
- Nơi cất (NGOÀI repo, có sao lưu): CHƯA tạo khóa ký. APK hiện ký bằng khóa debug của Flutter, KHÔNG dùng để phát hành. Người dùng tự tạo khóa upload ở G6 (L-005)
- Người giữ:
- Hạn của chứng chỉ/hồ sơ cấp phép (nếu có):

## 6. Hạ tầng ngoài phải còn sống để app chạy
(API, máy chủ, cơ sở dữ liệu, tên miền, chứng chỉ SSL, dịch vụ thông báo đẩy.) Mỗi mục: địa chỉ, ai quản lý, hạn gia hạn.

## 7. Dữ liệu và sao lưu
- Dữ liệu người dùng nằm ở đâu: SQLite trong bộ nhớ riêng của app trên điện thoại (tên `vigon`); PIN trong Android Keystore qua `flutter_secure_storage`
- Sao lưu thế nào, khôi phục thế nào: người dùng tự xuất file `.vigon` (Cài đặt → Dữ liệu) và khôi phục bằng trình chọn file; `allowBackup=false` nên Android không tự sao lưu. Chưa thử trên máy thật
- Migration dữ liệu giữa các phiên bản: `schemaVersion = 1`, chưa có migration; đổi bảng thì tăng `schemaVersion` và viết migration kèm test (D-005)

## 8. Kho mã nguồn từ xa
- Địa chỉ kho (nếu có): chưa có remote
- Nếu chưa có kho từ xa: thư mục này là bản duy nhất (git local trong `.git`, các commit G1 tới G5). Sao lưu: `bash scripts/backup.sh <thư mục ngoài ổ D>` từ `D:/DemoChung`; CHƯA từng chạy

## 9. Lần build thành công gần nhất và snapshot công cụ (tự động; mới nhất ở cuối)
- 2026-11-03 · `flutter build apk --release` (bản G2) · thành công, 59,4 MB (đủ kiến trúc), cài và chạy được trên Galaxy A13
- 2026-11-03 · `flutter analyze` và `flutter test` bản G5 · không lỗi, 91 test đạt
- 2026-11-03 · `flutter build apk --release` (bản G5) · THẤT BẠI ở `:android_file_picker:compileReleaseKotlin` (BUG-002), chưa build lại sau khi thêm `kotlin.incremental=false`

## 10. Sự cố đã gặp khi dựng lại / nâng cấp (để lần sau khỏi mất công)
- `flutter` không nhận trong PowerShell: dùng `C:/src/flutter/bin/flutter.bat` hoặc thêm vào PATH người dùng
- App crash ngay khi mở trên Galaxy A13: APK build với `--target-platform android-arm64` mà máy chỉ chạy 32-bit (BUG-001, L-011)
- Build release thất bại ở Kotlin của `android_file_picker` (BUG-002): xem BACKLOG
- Widget test treo hơn 10 phút nếu tạo cơ sở dữ liệu ở `setUp` (xem ARCHITECTURE "Điểm cần cẩn thận")
- `adb shell` trong Git Bash đổi `/sdcard/...` thành đường dẫn Windows: đặt `MSYS_NO_PATHCONV=1`
- `flutter doctor` báo thiếu cmdline-tools và giấy phép SDK: cài trong Android Studio (không chặn build)

### Snapshot công cụ 2026-11-03 13:39 (tự động, máy: DESKTOP-0MOJSAU, hệ điều hành: MINGW64_NT-10.0-19045 3.6.6-1cdd4371.x86_64)
- stack nhận diện: flutter
- flutter: (không có)
- dart: (không có)
- git: git version 2.53.0.windows.1
- java: openjdk version "17.0.20.1" 2026-08-18
- pubspec.yaml (bản khai báo, không phải bản đã cài): sdk dart ^3.13.7 · sdk flutter -
- Android (gradle): compileSdk do Flutter quản lý · targetSdk do Flutter quản lý · minSdk do Flutter quản lý
- Lockfile: pubspec.lock
