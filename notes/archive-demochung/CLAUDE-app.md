# CLAUDE.md — APP-001 · Ví Gọn

App mobile CHỈ dành cho điện thoại. Mở Claude ngay trong thư mục này vẫn có đủ lệnh / (đã chép từ gốc); script của bộ khung chạy bằng `bash ../../scripts/<tên>.sh`. Quy tắc gốc: `D:/DemoChung/CLAUDE.md` (`../../CLAUDE.md`) và quy trình `../../docs/PROCESS.md`. File này chỉ chứa phần RIÊNG của app.

- Mã app: APP-001
- Thư mục: apps/APP-001-vi-gon
- Giai đoạn hiện tại: G6 (phần Claude làm được đã xong, chờ người dùng: TalkBack/cỡ chữ trên máy, đăng chính sách, đo nốt NFR)
- Nền tảng: Android (v1); iOS để sau (D-001)
- Quy mô: chuẩn
- Stack: Flutter

## Điểm dừng (Claude cập nhật bằng /end; đọc mục này đầu tiên khi quay lại app sau thời gian dài)
- Cập nhật lần cuối: 2026-11-04 (phiên 1, nhật ký `memory/sessions/2026-11-04-p1.md`). Bản 1.1 + 1.2 (F-14..F-26) xong code trên nhánh `integration/spec-1.1` (worktree `.claude/worktrees/integration`): 294 test đạt, APK release 1.2 đã build; CHƯA gộp với `feature/PLAN-001` của chat khác; CHƯA cài và CHƯA thử máy thật
- Đang làm dở: thử máy thật bản 1.2 (M-1..M-7 ở `docs/TESTING.md`; rủi ro nhất: chọn thư mục Drive/Dropbox cho F-24); release: khóa ký, URL chính sách vào `AppInfo.privacyPolicyUrl`, ảnh store có widget, nhãn hiệu, tên tiếng Anh, TalkBack/cỡ chữ lớn nhất, CSV bằng Excel
- Bước tiếp theo: HỎI người dùng rồi cài APK 1.2 (người dùng vừa trả lời "Chưa cài"; KHÔNG tự dùng adb khi chưa hỏi); xin xác nhận widget 2×2 và dòng trạng thái widget khi công tắc tắt + PIN bật; hỏi có gộp hai nhánh không
- Đang chờ (ai/cái gì): người dùng: cho phép cài máy, đăng chính sách lên Google Sites, trả lời tên cá nhân hay công ty và Play Age Signals, sao lưu `D:/DemoChung` ra ngoài ổ D; remote https://github.com/phiotron/vigon (nhánh `main`, chỉ đẩy khi người dùng bảo)
- Lưu ý dễ vấp: Galaxy A13 (SM-A135F, Android 14) chỉ 32-bit, không build `arm64` riêng (BUG-001); dữ liệu Ví Gọn trên máy là dữ liệu MẪU; phiên Claude khác dùng chung máy (kiểm `mCurrentFocus` trước mỗi lần chạm, mỗi lần một lệnh); PIN 4 số không phải mã hóa (D-007); Flutter chưa trong PATH; nhiều agent chạy test chung một worktree khóa sqlite3.dll (`memory/facts/`); hook chặn chữ "password" là dương tính giả, chỉ người dùng được bỏ qua

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
- Đo hiệu năng trên máy (bản profile, thay tạm bản release; xong phải cài lại release): `flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart -d <id máy>`; kết quả ở `build/perf_summary.json` và dòng `PERF` trong log
- SBOM: `python tool/make_sbom.py` (ghi `docs/sbom/vigon.cdx.json`)
- Build thử trên máy: `flutter build apk --release` (KHÔNG thêm `--target-platform android-arm64`: máy 32-bit sẽ crash, xem BUG-001), cài bằng `adb install -r build/app/outputs/flutter-apk/app-release.apk`. Vẫn ký bằng khóa debug của template, CHƯA dùng để phát hành. Bản phát hành Play: `flutter build appbundle`, CHƯA chạy (cần khóa ký, G6).

## Quy ước riêng của app
- Cấu trúc thư mục code: `lib/src/data/` (drift, kho dữ liệu, tiền), `lib/src/features/<tính năng>/` (màn hình), `lib/src/providers.dart`, `lib/src/app.dart` (router, theme), `lib/l10n/` (file dịch .arb và mã sinh). Test phản chiếu ở `test/`.
- Đặt tên, quản lý state, điều hướng, lưu dữ liệu: Riverpod 3 (provider viết tay, không codegen), go_router, drift/SQLite (D-003, D-004). Tiền là số nguyên đơn vị nhỏ nhất, ngày là chữ `YYYY-MM-DD`, cài đặt ở bảng `settings` (D-005). Mọi chữ giao diện nằm trong `.arb`.

## Bài học áp dụng cho app này
ID bài học liên quan trong `../../lessons/LESSONS.md`: L-001, L-002, L-003, L-004, L-005, L-007, L-009, L-010

## Ghi nhớ riêng (Claude cập nhật khi phát hiện điều lẽ ra phải biết sớm hơn)
- Widget test dùng cơ sở dữ liệu: tạo DB BÊN TRONG thân `testWidgets`, dùng `closeStreamsSynchronously: true`, bọc mọi thao tác DB trong `tester.runAsync` (xem `test/app_test.dart`). Tạo ở `setUp` thì test treo tới khi hết giờ.
