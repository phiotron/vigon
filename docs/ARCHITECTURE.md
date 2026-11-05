# ARCHITECTURE — Ví Gọn (A002-vigon)

Mô tả app HIỆN ĐANG như thế nào (DECISIONS.md ghi VÌ SAO chọn). Cập nhật khi cấu trúc đổi. Giữ ngắn. Cập nhật lần cuối: 2026-11-05 (sau khi gộp bản 1.2 với giao diện/iOS của PLAN-001, D-019); phần chi tiết gốc viết 2026-11-03.

## Tổng quan
App Flutter cho Android và iOS (iOS thêm 2026-11-04, D-011; build trên GitHub Actions macOS), chạy hoàn toàn offline. Giao diện (Riverpod 3 + go_router) đọc dữ liệu qua các "kho" (repository) bọc cơ sở dữ liệu SQLite (drift). Không có máy chủ, không gọi mạng, không SDK bên thứ ba (D-002). Dữ liệu chảy một chiều: màn hình → provider → repository → drift; drift phát luồng (stream) cập nhật ngược lên màn hình. Mã PIN nằm ngoài SQLite, trong bộ nhớ an toàn của hệ điều hành (D-007; Android Keystore, iOS Keychain; mã cài đặt phát hiện cài lại, D-017). Giao diện sinh từ token của bộ thiết kế `design/current/screens/` (`tool/gen_tokens.py` → `lib/src/ui/tokens.g.dart`, `theme.dart`; D-010).

## Màn hình và điều hướng
- `/` Màn chính (biểu đồ tròn, icon danh mục, thanh ngân sách, số dư, nút −/+) → `/settings`, `/entries`, `/entry/new?type=&category=`
- `/entries` danh sách khoản trong kỳ, gom theo danh mục → `/entry/:id` (sửa/xóa), `/transfer/:id`
- `/settings` → `/categories`, `/accounts` (→ `/transfer`), `/recurring`; hộp thoại: ngân sách, tiền tệ, đặt/tắt PIN; thao tác dữ liệu (sao lưu, khôi phục, CSV, xóa hết)
- `/about` màn Giới thiệu. Lớp phủ màn khóa (`features/lock`) nằm trên toàn bộ router khi bật PIN
- Đường vào ngoài app (bản 1.2): nút Chi/Thu của widget (Android, kênh `vigon/deeplink`) và chạm thông báo nhắc (Android + iOS) chỉ mở được `/entry/new?type=expense|income` (D-015, D-016)

## Dữ liệu
- SQLite qua drift, `schemaVersion = 2` (bản 1.1 thêm cột `budget` ở `categories`, migration `addColumn`; D-013). Bảng: `accounts`, `categories`, `recurring_rules`, `entries`, `settings` (khóa-giá trị). Tiền là số nguyên theo đơn vị nhỏ nhất, ngày là chữ `YYYY-MM-DD` (D-005). Mã sinh `*.g.dart` được commit (D-004).
- Chuyển tiền là một dòng `entries` loại `transfer` có `toAccountId`; số dư tài khoản tính từ số dư ban đầu + các khoản (không lưu số dư).
- Khoản định kỳ: bảng `recurring_rules`; `generateDue` tạo khoản còn thiếu khi mở app và khi quay lại app, tính từ ngày bắt đầu (không trôi ngày 31).
- Sao lưu: JSON `.vigon` có mã băm (D-006), tùy chọn bọc mã hóa AES-256-GCM bằng mật khẩu (`backup_crypto.dart`, D-012). Sao lưu tự động vào thư mục SAF (`auto_backup_service.dart`, `backup_folder_service.dart`, `BackupFolderChannel.kt`; chỉ Android, D-014). Đổi tiền tệ nhân/chia số đã lưu khi số chữ số thập phân khác nhau (`data/currency.dart`).
- Bí mật trong `flutter_secure_storage`: muối và mã băm PIN, mã cài đặt PIN (D-017), cấu hình và mật khẩu sao lưu tự động (D-014).

## Tích hợp ngoài
Không có API, không khóa, không biến môi trường. Chỉ dùng thành phần của hệ điều hành: bảng chia sẻ (`share_plus`), trình chọn file (`file_picker`), bộ nhớ an toàn (`flutter_secure_storage`), thông báo cục bộ (`flutter_local_notifications` + `timezone`, `flutter_timezone`; D-015), `package_info_plus` và `url_launcher` cho màn Giới thiệu. Mã gốc Android: `MainActivity.kt` (kênh `vigon/secure` bật `FLAG_SECURE`, F-22), `BackupFolderChannel.kt` (SAF), `DeepLinkChannel.kt` và `WidgetProvider.kt` (widget). Tính năng chỉ Android được bật/tắt theo nền tảng ở `lib/src/platform_features.dart` (D-019).

## Cấu trúc thư mục code
- `lib/src/data/` drift (`database.dart`), kho dữ liệu, tính toán thuần (`calculator`, `period`, `summary`, `money`, `dates`, `text_fold`, `entry_search`), `backup`, `backup_crypto`, `auto_backup_service`, `backup_folder_service`, `pin_service`, `currency`, `currency_table`, `seed`
- `lib/src/features/<màn>/` giao diện từng tính năng: `home`, `entry`, `entries`, `categories`, `accounts`, `recurring`, `settings`, `lock`, `about`, `reminder`, `widget`
- `lib/src/ui/` thành phần dùng chung (token `tokens.g.dart` sinh tự động, `theme.dart`, định dạng, avatar và lưới danh mục, nút chính, hiển thị số tiền, bảng chọn, hộp xác nhận, thanh thông báo)
- `lib/src/providers.dart` mọi provider; `lib/src/app.dart` router, theme, lớp phủ khóa
- `lib/l10n/` file dịch `.arb` (vi, en) và mã sinh
- `test/` phản chiếu cấu trúc trên; `test/helpers.dart` dựng app có cơ sở dữ liệu trong bộ nhớ, đồng hồ cố định, kho bí mật giả

## Điểm cần cẩn thận
- Widget test có cơ sở dữ liệu: tạo DB BÊN TRONG `testWidgets`, `closeStreamsSynchronously: true`, bọc thao tác DB trong `tester.runAsync` (xem `test/helpers.dart`); sai là test treo.
- Sửa bảng trong `database.dart` thì chạy `dart run build_runner build` rồi mới analyze/test.
- `startupProvider` (chọn tiền tệ, tạo khoản định kỳ) phải được `VigonApp` theo dõi, nếu không sẽ không chạy.
- Khóa PIN dùng `Offstage` giữ app bên dưới sống; mọi thứ bên dưới vẫn chạy khi đang khóa.
- Build release: KHÔNG dùng `--target-platform android-arm64` (BUG-001); `kotlin.incremental=false` trong `android/gradle.properties` là cố ý (BUG-002: dự án ổ D, pub cache ổ C).
- Thêm tính năng gốc nền tảng: nếu chỉ có một nền tảng thì ẩn mục cài đặt ở nền tảng kia qua `platform_features.dart` và thêm ca vào `test/features/merge_ios_gating_test.dart` (D-019).
