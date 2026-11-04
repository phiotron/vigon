# ARCHITECTURE — Ví Gọn (A002-vigon)

Mô tả app HIỆN ĐANG như thế nào (DECISIONS.md ghi VÌ SAO chọn). Cập nhật khi cấu trúc đổi. Giữ ngắn. Cập nhật lần cuối: 2026-11-03 (sau G5).

## Tổng quan
App Flutter chỉ Android, chạy hoàn toàn offline. Giao diện (Riverpod 3 + go_router) đọc dữ liệu qua các "kho" (repository) bọc cơ sở dữ liệu SQLite (drift). Không có máy chủ, không gọi mạng, không SDK bên thứ ba (D-002). Dữ liệu chảy một chiều: màn hình → provider → repository → drift; drift phát luồng (stream) cập nhật ngược lên màn hình. Mã PIN nằm ngoài SQLite, trong bộ nhớ an toàn của hệ điều hành (D-007).

## Màn hình và điều hướng
- `/` Màn chính (biểu đồ tròn, icon danh mục, thanh ngân sách, số dư, nút −/+) → `/settings`, `/entries`, `/entry/new?type=&category=`
- `/entries` danh sách khoản trong kỳ, gom theo danh mục → `/entry/:id` (sửa/xóa), `/transfer/:id`
- `/settings` → `/categories`, `/accounts` (→ `/transfer`), `/recurring`; hộp thoại: ngân sách, tiền tệ, đặt/tắt PIN; thao tác dữ liệu (sao lưu, khôi phục, CSV, xóa hết)
- Lớp phủ màn khóa (`features/lock`) nằm trên toàn bộ router khi bật PIN
- Chưa có: màn Giới thiệu (G6)

## Dữ liệu
- SQLite qua drift, `schemaVersion = 1`, chưa có migration. Bảng: `accounts`, `categories`, `recurring_rules`, `entries`, `settings` (khóa-giá trị). Tiền là số nguyên theo đơn vị nhỏ nhất, ngày là chữ `YYYY-MM-DD` (D-005). Mã sinh `*.g.dart` được commit (D-004).
- Chuyển tiền là một dòng `entries` loại `transfer` có `toAccountId`; số dư tài khoản tính từ số dư ban đầu + các khoản (không lưu số dư).
- Khoản định kỳ: bảng `recurring_rules`; `generateDue` tạo khoản còn thiếu khi mở app và khi quay lại app, tính từ ngày bắt đầu (không trôi ngày 31).
- Sao lưu: JSON `.vigon` có mã băm (D-006). Đổi tiền tệ nhân/chia số đã lưu khi số chữ số thập phân khác nhau (`data/currency.dart`).
- Bí mật: chỉ muối và mã băm PIN, trong `flutter_secure_storage`.

## Tích hợp ngoài
Không có API, không khóa, không biến môi trường. Chỉ dùng thành phần của hệ điều hành: bảng chia sẻ (`share_plus`), trình chọn file (`file_picker`), bộ nhớ an toàn (`flutter_secure_storage`). `package_info_plus` và `url_launcher` đã có trong pubspec cho màn Giới thiệu (G6), chưa dùng.

## Cấu trúc thư mục code
- `lib/src/data/` drift (`database.dart`), kho dữ liệu, tính toán thuần (`calculator`, `period`, `summary`, `money`, `dates`), `backup`, `pin_service`, `currency`, `seed`
- `lib/src/features/<màn>/` giao diện từng tính năng: `home`, `entry`, `entries`, `categories`, `accounts`, `recurring`, `settings`, `lock`
- `lib/src/ui/` thành phần dùng chung (định dạng, avatar danh mục, thanh thông báo)
- `lib/src/providers.dart` mọi provider; `lib/src/app.dart` router, theme, lớp phủ khóa
- `lib/l10n/` file dịch `.arb` (vi, en) và mã sinh
- `test/` phản chiếu cấu trúc trên; `test/helpers.dart` dựng app có cơ sở dữ liệu trong bộ nhớ, đồng hồ cố định, kho bí mật giả

## Điểm cần cẩn thận
- Widget test có cơ sở dữ liệu: tạo DB BÊN TRONG `testWidgets`, `closeStreamsSynchronously: true`, bọc thao tác DB trong `tester.runAsync` (xem `test/helpers.dart`); sai là test treo.
- Sửa bảng trong `database.dart` thì chạy `dart run build_runner build` rồi mới analyze/test.
- `startupProvider` (chọn tiền tệ, tạo khoản định kỳ) phải được `VigonApp` theo dõi, nếu không sẽ không chạy.
- Khóa PIN dùng `Offstage` giữ app bên dưới sống; mọi thứ bên dưới vẫn chạy khi đang khóa.
- Build release: KHÔNG dùng `--target-platform android-arm64` (BUG-001); đang có BUG-002 làm build release thất bại.
