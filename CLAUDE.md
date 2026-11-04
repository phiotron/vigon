# CLAUDE.md — APP-001 · Ví Gọn

App mobile CHỈ dành cho điện thoại. Mở Claude ngay trong thư mục này vẫn có đủ lệnh / (đã chép từ gốc); script của bộ khung chạy bằng `bash ../../scripts/<tên>.sh`. Quy tắc gốc: `D:/DemoChung/CLAUDE.md` (`../../CLAUDE.md`) và quy trình `../../docs/PROCESS.md`. File này chỉ chứa phần RIÊNG của app.

- Mã app: APP-001
- Thư mục: apps/APP-001-vi-gon
- Giai đoạn hiện tại: G6 (phần Claude làm được đã xong, chờ người dùng: TalkBack/cỡ chữ trên máy, đăng chính sách, đo nốt NFR)
- Nền tảng: Android (v1); iOS để sau (D-001)
- Quy mô: chuẩn
- Stack: Flutter

## Điểm dừng (Claude cập nhật bằng /end; đọc mục này đầu tiên khi quay lại app sau thời gian dài)
- Cập nhật lần cuối: 2026-11-03
- Đang làm dở: G6. Đã xong: màn Giới thiệu (AC-41), bố cục cỡ chữ 200%, test accessibility tự động, sửa BUG-003, chính sách vi/en (`docs/legal/privacy-policy.md`), SBOM, MASVS, SECURITY, COMPLIANCE, đo mở nguội và dung lượng. 116 test đạt; `/spec-review` độc lập đã chạy, 9 lỗi đã sửa (BUG-005..013), phần chưa xử lý ở BACKLOG. Chưa: đường dẫn chính sách trong `lib/src/app_info.dart`, TalkBack và cỡ chữ lớn nhất trên máy thật, pin 15 phút, khóa ký phát hành
- Điện thoại đang cài bản release sau BUG-010. Mã nguồn đã có thêm BUG-011..013 (chưa build/cài lên máy). Người dùng đã dặn: KHÔNG tự dùng adb trên điện thoại khi chưa hỏi; hỏi trước khi cài hay chạm máy
- Bước tiếp theo: khi người dùng gửi đường dẫn chính sách thì điền `AppInfo.privacyPolicyUrl`, build lại, kiểm trên máy; đo nốt NFR khi máy rảnh; rồi `/release`
- Đang chờ (ai/cái gì): người dùng: đăng chính sách lên Google Sites, thử TalkBack và cỡ chữ lớn nhất, mở CSV bằng Excel, trả lời tên cá nhân hay công ty và Play Age Signals, cài Command-line Tools cho Android SDK, tạo remote git và sao lưu `D:/DemoChung` ra ngoài ổ D
- Lưu ý dễ vấp: (1) Galaxy A13 (SM-A135F, Android 14) chỉ chạy 32-bit, không build APK `arm64` riêng (BUG-001). (2) Dữ liệu Ví Gọn trên máy là dữ liệu MẪU dùng chụp ảnh store (giao diện sáng, tiếng Anh); người dùng muốn dùng thật thì xóa bằng "Xóa toàn bộ dữ liệu". File `vigon-demo.vigon` còn trong thư mục Download của máy. Máy thử là máy người dùng đang dùng, và có phiên Claude khác điều khiển cùng máy (app dailyloop, focusgrove): trước mỗi lần chạm qua adb phải kiểm `mCurrentFocus` là Ví Gọn, không gộp nhiều lần chạm vào một lệnh. (3) PIN 4 số chỉ chặn người tò mò, không phải mã hóa dữ liệu (D-007). (4) Flutter chưa có trong PATH, xem mục "Lệnh". (5) G3 tới G5 đã thử máy thật bằng adb; CSV mở bằng Excel chưa thử.

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
