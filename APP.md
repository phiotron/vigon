# A002-vigon · Ví Gọn — APP.md

> Brief + trạng thái của app. **Chỉ phiên điều phối sửa file này**; phiên con ghi báo cáo vào `notes/`.
> App **nhập từ DemoChung** (APP-001, đã qua G1–G6 ở đó 2026-11-03..04). Lịch sử quy trình cũ (BACKLOG đầy đủ,
> biên bản thử máy, lỗi đã sửa BUG-001..013, RUNBOOK, retro): `notes/archive-demochung/` — chỉ đọc.

## Brief
- **Mã app / thư mục:** `A002-vigon` → `apps/A002-vigon/` — đã ghi trong `apps/REGISTRY.md`
- **Bundle ID** (không đổi): `com.phiotron.vigon` · **Repo:** https://github.com/phiotron/vigon (private, nhánh `main`)
- **Một câu mô tả:** Ghi chép thu chi cá nhân thật nhanh, xem biểu đồ theo danh mục — offline, không tài khoản, không thu thập dữ liệu.
- **Người dùng mục tiêu:** người đi làm, sinh viên, người giữ tiền chi tiêu gia đình; Việt Nam và quốc tế (vi/en).
- **Kiếm tiền:** miễn phí bản 1 (không quảng cáo, không IAP).
- **Nền tảng:** Android + iOS (iOS thêm 2026-11-04, build + test trên GitHub Actions macOS runner — theo fact xưởng `may-windows-build-ios`) · **Stack:** Flutter 3.47.8, Riverpod 3, go_router, drift/SQLite.
- **Tài liệu tham chiếu:** `docs/SPEC.md` (AC-01..AC-43 — nguồn sự thật về hành vi), `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`,
  `docs/TESTING.md`, `docs/SECURITY.md`, `docs/COMPLIANCE.md`, `docs/RELEASE.md`, `docs/legal/`; thiết kế hiện tại `design/current/`
  (`ui-spec.md` + bộ màn `screens/`); store `store/`; thuật ngữ `CONTEXT.md` (khi có); mô tả gửi Claude Design `product.md` (khi có).

## MVP (đã code xong — 13 nhóm tính năng theo SPEC)
1. **Ghi khoản nhanh** (F-01, F-04): bàn phím số có phép tính, chọn danh mục, sửa/xoá có hoàn tác.
2. **Màn chính** (F-02, F-03): biểu đồ tròn theo danh mục, tổng thu/chi/số dư, icon danh mục quanh biểu đồ; chọn kỳ ngày/tuần/tháng/năm/tuỳ chọn, vuốt đổi kỳ.
3. **Danh mục, tài khoản, chuyển tiền, tiền tệ** (F-05..F-07).
4. **Khoản định kỳ + ngân sách tháng** (F-08, F-09).
5. **Sao lưu/khôi phục `.vigon`, xuất CSV, khoá PIN, giao diện/ngôn ngữ/accessibility, pháp lý trong app** (F-10..F-13).

## Màn hình & luồng chính
Màn chính `/` · Nhập khoản `/entry/new`, `/entry/:id` · Các khoản `/entries` · Cài đặt `/settings` · Danh mục `/categories` ·
Tài khoản `/accounts` · Chuyển tiền `/transfer` · Khoản định kỳ `/recurring` · Giới thiệu `/about` · Màn khoá PIN.
Hộp thoại: chọn kỳ, ngân sách, chọn tiền tệ, thêm/sửa danh mục/tài khoản, sửa chuỗi định kỳ. Chi tiết: `design/current/ui-spec.md`.
Luồng nhanh nhất: Màn chính → chạm icon danh mục (hoặc −/+) → gõ số → Lưu.

## Trạng thái
| Phiên điều phối | Ngày | Phiên con đã mở | Kết quả |
|---|---|---|---|
| #1 Chuyển + product.md | 2026-11-04 | A product.md · B nền iOS + CI GitHub Actions · C store & pháp lý 2 nền tảng | đang chạy |
| #2 Áp UI Hi-Fi + test 2 nền tảng | | D0 theme/arb → D1, D2, D3 song song → D4 thử máy | |
| #3 Phát hành | | E ảnh store · F Android · G iOS | |

Kế hoạch đầy đủ 3 phiên: `notes/2026-11-04-ke-hoach-3-phien.md`.

**Việc dở / bước tiếp:**
- Phiên #1: duyệt `product.md` → người dùng gửi Claude Design, lưu mockup vào `design/hifi/`.
- Người dùng: đăng ký Apple Developer (cá nhân), App ID `com.phiotron.vigon`, API key App Store Connect + chứng chỉ ký → GitHub Secrets của repo `phiotron/vigon`.
- Không có iPhone: iOS được thử trên **iOS Simulator của GitHub Actions** (người dùng đồng ý push để chạy CI); TestFlight khi mượn được máy.
- Người dùng: Play Console cá nhân → **closed test 12 tester × 14 ngày** (bắt đầu sớm, dùng build hiện tại); tạo upload keystore ngoài repo (`docs/RELEASE.md`).
- Người dùng: đăng chính sách lên web → điền `AppInfo.privacyPolicyUrl` (`lib/src/app_info.dart`); TalkBack + cỡ chữ lớn nhất trên máy; mở CSV bằng Excel; đo pin 15 phút.
- Còn mở từ spec-review (nhẹ, ngoài SPEC hoặc chờ quyết): PIN không đếm lần sai; >10 danh mục chi thì danh mục thừa không chạm được từ vòng icon (AC-06); CSV tiêu đề luôn tiếng Anh; danh sách tiền tệ 31 mã (AC-21).
- COMPLIANCE còn "chưa": M-01, D-02, D-07, D-09, D-12, S-06, A-01, C-03, P-08, P-09, P-10.

## Lệnh (đã chạy thật 2026-11-03; phải dùng đúng, không đoán)
Flutter 3.47.8 ở `C:/src/flutter`, **chưa có trong PATH**. Git Bash: `export PATH="/c/src/flutter/bin:$PATH"` trước mọi lệnh.
- Cài: `flutter pub get` (tự sinh file dịch từ `lib/l10n/*.arb`)
- Sinh mã sau khi sửa bảng `lib/src/data/database.dart`: `dart run build_runner build` (commit cả `*.g.dart`)
- Lint/typecheck: `flutter analyze` · Định dạng: `dart format lib test` · Test: `flutter test`
- Chạy: `flutter run -d <id>` (`flutter devices`)
- Build thử Android: `flutter build apk --release` (**không** thêm `--target-platform android-arm64`, BUG-001); cài `adb install -r build/app/outputs/flutter-apk/app-release.apk`
- Bản phát hành Play: `flutter build appbundle` (cần `android/key.properties` + keystore ngoài repo; thiếu thì build bị chặn)
- Đo hiệu năng: `flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart -d <id>`
- SBOM: `python tool/make_sbom.py` → `docs/sbom/vigon.cdx.json`
- iOS: build + test trên GitHub Actions macOS runner (`.github/workflows/`, khi phiên con B xong) — Windows không build iOS cục bộ. Repo private → phút macOS ×10 quota.

## Quy ước code
- `lib/src/data/` (drift, kho dữ liệu, tiền) · `lib/src/features/<tính năng>/` (màn hình) · `lib/src/ui/` (widget dùng chung) ·
  `lib/src/providers.dart` · `lib/src/app.dart` (router, theme) · `lib/l10n/` (.arb + mã sinh). Test phản chiếu ở `test/`.
- Tiền = số nguyên đơn vị nhỏ nhất (tối đa 10^12), ngày = chữ `YYYY-MM-DD`, cài đặt ở bảng `settings`. Mọi chữ giao diện nằm trong `.arb`.
- Danh sách có thể dài → luôn `ListView.builder`. Dùng `excludeSemantics` trên nút thì kiểm `hasTapAction`.

## Lưu ý dễ vấp
- **Widget test có DB:** tạo DB **bên trong** thân `testWidgets`, `closeStreamsSynchronously: true`, bọc thao tác DB trong `tester.runAsync` (xem `test/app_test.dart`). Tạo ở `setUp` thì test treo.
- **Máy thử Galaxy A13 (SM-A135F, Android 14) chỉ chạy 32-bit** → không build APK chỉ arm64.
- **Không tự dùng adb trên điện thoại khi chưa hỏi.** Máy thử là máy người dùng đang dùng, có phiên khác (app khác) điều khiển cùng máy: trước mỗi lần chạm kiểm `mCurrentFocus` là Ví Gọn, không gộp nhiều lần chạm vào một lệnh. Dữ liệu Ví Gọn trên máy là dữ liệu MẪU chụp store.
- `kotlin.incremental=false` trong `android/gradle.properties` là cố ý (BUG-002: dự án ổ D, pub cache ổ C).
- PIN 4 số chỉ chặn người tò mò, không mã hoá dữ liệu (D-007). File `.vigon` là JSON thường (D-006).
- Chỉ push lên GitHub khi người dùng bảo.

## Quyết định riêng của app (chi tiết: `docs/DECISIONS.md`)
- **D-001** Flutter; ~~Android trước~~ → **2026-11-04: thêm iOS vào bản 1**, build/ký/test trên GitHub Actions macOS runner (đồng bộ với xưởng); không có iPhone → thử trên simulator CI.
- **D-002** Chỉ lưu trên máy, không máy chủ, không SDK bên thứ ba, không quyền INTERNET.
- **D-003** Flutter 3.47.8 (không FVM), Riverpod 3 viết tay, go_router, l10n `.arb`. · **D-004** drift/SQLite, commit file sinh.
- **D-005** Tiền số nguyên, ngày dạng chữ, cài đặt trong DB. · **D-006** Sao lưu `.vigon` JSON có mã băm, khôi phục thay toàn bộ trong 1 giao dịch.
- **D-007** PIN băm có muối trong bộ nhớ an toàn, màn khoá phủ lên app. · **D-008** Liên hệ ở `app_info.dart`; bố cục co theo cỡ chữ; test a11y tự động.
- **D-009** Logo "hai thẻ xếp chồng".
- **2026-11-04** Chuyển từ DemoChung sang xưởng, mã `A002-vigon`; giữ repo `phiotron/vigon`; giữ worktree cũ trong `.claude/worktrees/` (bị gitignore).
- **2026-11-04** UI bản 1 = **nâng cấp** từ thiết kế hiện tại qua Claude Design (không thiết kế lại từ đầu), phạm vi đúng SPEC.
- **2026-11-04** Tài khoản Google Play và Apple đứng tên **cá nhân**.

## Retro (điền khi phát hành)
- Tổng phiên điều phối / phiên con:
- Chậm nhất ở đâu, vì sao:
- Thứ tái dùng được cho app sau:
- Cải tiến đề xuất cho Playbook:
