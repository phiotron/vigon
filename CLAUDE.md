# CLAUDE.md — APP-001 · Ví Gọn

App mobile CHỈ dành cho điện thoại. Mở Claude ngay trong thư mục này vẫn có đủ lệnh / (đã chép từ gốc); script của bộ khung chạy bằng `bash ../../scripts/<tên>.sh`. Quy tắc gốc: `D:/DemoChung/CLAUDE.md` (`../../CLAUDE.md`) và quy trình `../../docs/PROCESS.md`. File này chỉ chứa phần RIÊNG của app.

- Mã app: APP-001
- Thư mục: apps/APP-001-vi-gon
- Giai đoạn hiện tại: G4
- Nền tảng: Android (v1); iOS để sau (D-001)
- Quy mô: chuẩn
- Stack: Flutter

## Điểm dừng (Claude cập nhật bằng /end; đọc mục này đầu tiên khi quay lại app sau thời gian dài)
- Cập nhật lần cuối: 2026-11-03
- Đang làm dở: (chưa có)
- Bước tiếp theo: (chưa có)
- Đang chờ (ai/cái gì): (chưa có)
- Lưu ý dễ vấp: máy thử Galaxy A13 (SM-A135F) chạy Android 14 chỉ 32-bit; build APK phải có `armeabi-v7a` (BUG-001).

## Mô tả
- Mục đích: Ghi chép thu chi cá nhân nhanh, xem biểu đồ theo danh mục (chức năng tương đương Monefy)
- Người dùng chính: người đi làm, sinh viên, người giữ tiền chi tiêu gia đình; ở Việt Nam và nước khác (vi/en)

## Đọc trước khi làm (theo thứ tự)
Quay lại app sau thời gian dài: mục "Điểm dừng" ở trên → `docs/RUNBOOK.md` (cách chạy lại) → dùng `/revive`. Làm việc thường: `docs/SPEC.md` → `docs/BACKLOG.md` → `docs/DECISIONS.md` → `docs/ARCHITECTURE.md` → `docs/TESTING.md`; khi làm tính năng lớn: `docs/plans/PLAN-*.md` đã duyệt; app nhập từ ngoài: báo cáo mới nhất trong `docs/audits/`

## Lệnh (điền chính xác khi chọn stack; Claude phải chạy đúng các lệnh này, không tự bịa)
Flutter 3.47.8 ở `C:/src/flutter`, CHƯA có trong PATH. Trong Git Bash chạy trước: `export PATH="/c/src/flutter/bin:$PATH"` (D-003). Các lệnh dưới đã chạy thử ngày 2026-11-03.
- Cài đặt: `flutter pub get` (tự sinh file dịch từ `lib/l10n/*.arb`)
- Sinh mã sau khi sửa bảng trong `lib/src/data/database.dart`: `dart run build_runner build` (commit cả `*.g.dart`, D-004)
- Chạy dev: `flutter run` (chọn máy: `flutter devices`, rồi `-d <id>`)
- Lint: `flutter analyze`
- Typecheck: `flutter analyze`
- Định dạng: `dart format lib test`
- Test: `flutter test`
- Build thử trên máy: `flutter build apk --release` (KHÔNG thêm `--target-platform android-arm64`: máy 32-bit sẽ crash, xem BUG-001), cài bằng `adb install -r build/app/outputs/flutter-apk/app-release.apk`. Vẫn ký bằng khóa debug của template, CHƯA dùng để phát hành. Bản phát hành Play: `flutter build appbundle`, CHƯA chạy (cần khóa ký, G6).

## Quy ước riêng của app
- Cấu trúc thư mục code: `lib/src/data/` (drift, kho dữ liệu, tiền), `lib/src/features/<tính năng>/` (màn hình), `lib/src/providers.dart`, `lib/src/app.dart` (router, theme), `lib/l10n/` (file dịch .arb và mã sinh). Test phản chiếu ở `test/`.
- Đặt tên, quản lý state, điều hướng, lưu dữ liệu: Riverpod 3 (provider viết tay, không codegen), go_router, drift/SQLite (D-003, D-004). Tiền là số nguyên đơn vị nhỏ nhất, ngày là chữ `YYYY-MM-DD`, cài đặt ở bảng `settings` (D-005). Mọi chữ giao diện nằm trong `.arb`.

## Bài học áp dụng cho app này
ID bài học liên quan trong `../../lessons/LESSONS.md`: L-001, L-002, L-003, L-004, L-005, L-007, L-009, L-010

## Ghi nhớ riêng (Claude cập nhật khi phát hiện điều lẽ ra phải biết sớm hơn)
- Widget test dùng cơ sở dữ liệu: tạo DB BÊN TRONG thân `testWidgets`, dùng `closeStreamsSynchronously: true`, bọc mọi thao tác DB trong `tester.runAsync` (xem `test/app_test.dart`). Tạo ở `setUp` thì test treo tới khi hết giờ.
