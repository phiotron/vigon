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
- **Tài liệu tham chiếu:** `docs/SPEC.md` (F-01..F-26 đã hợp nhất — nguồn sự thật về hành vi), `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`,
  `docs/TESTING.md`, `docs/SECURITY.md`, `docs/COMPLIANCE.md`, `docs/RELEASE.md`, `docs/legal/`; thiết kế hiện tại `design/current/`
  (`ui-spec.md` + bộ màn `screens/`); store `store/`; thuật ngữ `CONTEXT.md` (khi có); mô tả gửi Claude Design `product.md` (khi có).

## Tính năng (đã code xong — F-01..F-26, sau khi gộp 2026-11-05)
1. **Bản 1.0 (F-01..F-13):** ghi khoản nhanh (bàn phím có phép tính, sửa/xoá có hoàn tác); màn chính biểu đồ tròn + vòng icon danh mục, chọn/vuốt kỳ; danh mục, tài khoản, chuyển tiền, tiền tệ; khoản định kỳ; ngân sách tháng; sao lưu `.vigon`/CSV; khoá PIN; giao diện/ngôn ngữ/a11y; pháp lý trong app.
2. **Bản 1.1 (F-14..F-23):** ẩn/hiện/xoá tài khoản · tìm kiếm khoản · sửa đủ chuỗi định kỳ · ô "Danh mục khác" ở màn chính · CSV theo ngôn ngữ · đủ tiền tệ ISO 4217 có tìm · ngân sách theo danh mục · mã hoá file sao lưu bằng mật khẩu · che nội dung đa nhiệm · icon đơn sắc.
3. **Bản 1.2 (F-24..F-26):** sao lưu tự động hằng ngày (mã hoá, giữ 7 file) · nhắc ghi chép hằng ngày · widget màn hình chính Chi/Thu.
4. **Giao diện:** theo bộ thiết kế đã duyệt `design/current/screens/` (S01–S16, token, Be Vietnam Pro, Material Symbols) — PLAN-001.
5. **Chỉ Android, iOS ẩn mục (D-019):** sao lưu tự động (F-24), widget (F-26), che đa nhiệm (F-22), icon đơn sắc (F-23). Nhắc ghi chép có trên iOS nhưng CHƯA thử thông báo thật.

## Màn hình & luồng chính
Màn chính `/` (+ khoá PIN phủ) · Ghi/sửa khoản `/entry/new?type=&category=`, `/entry/:id` · Các khoản `/entries` (tìm kiếm, hạn mức danh mục) ·
Cài đặt `/settings` (che nội dung, widget, nhắc, sao lưu có mật khẩu, sao lưu tự động, tiền tệ có tìm) · Danh mục `/categories` (hạn mức) ·
Tài khoản `/accounts` (ẩn/hiện/xoá) · Chuyển tiền `/transfer` · Khoản định kỳ `/recurring` · Giới thiệu `/about`.
Ngoài app: widget Android 2×2, thông báo nhắc. Danh sách đầy đủ + hộp thoại: `notes/2026-11-04-gop-nhanh.md` mục "Tính năng + màn sau gộp".
Màn 1.2 dựng lại bằng thành phần mới nhưng **chưa có bản vẽ** (ô hạn mức danh mục, ẩn/xoá tài khoản, nhóm cài đặt 1.2, hộp sửa chuỗi mở rộng) → cần Claude Design vẽ ở #2.
Luồng nhanh nhất: Màn chính → chạm icon danh mục (hoặc −/+) → gõ số → Lưu (giữ chọn danh mục = lưu luôn, D-018).

## Trạng thái
| Phiên điều phối | Ngày | Phiên con đã mở | Kết quả |
|---|---|---|---|
| #1 Chuyển + gộp + product.md | 2026-11-04..05 | A product.md · B nền iOS + CI · C store & pháp lý · D gộp 2 nhánh (+2 phiên con phụ của D) · A/C làm lại theo bản gộp | Đã chuyển; đã gộp `integration/spec-1.1` + `feature/PLAN-001` vào main (a987ac1, 5227555, 06453cf), 352/352 test, APK build, CI Android + iOS xanh; product.md/store đang viết lại |
| #2 Áp UI Hi-Fi + test 2 nền tảng | | D0 theme/arb → D1, D2, D3 song song → D4 thử máy | |
| #3 Phát hành | | E ảnh store · F Android · G iOS | |

Kế hoạch đầy đủ 3 phiên: `notes/2026-11-04-ke-hoach-3-phien.md`.

**Việc dở / bước tiếp:**
- Phiên #1: viết lại `product.md` + `CONTEXT.md` + store theo bản gộp → người dùng duyệt → gửi Claude Design, lưu mockup vào `design/hifi/`.
- iOS chưa có F-22/F-24/F-26 (D-019): quyết ở #2 làm tương đương (WidgetKit, chọn thư mục, che màn) hay để bản sau. Export compliance phải xem lại vì có AES-256-GCM (COMPLIANCE P-03).
- Mọi tính năng 1.1/1.2 CHƯA thử trên máy Android thật (`docs/TESTING.md` M-1..M-7).
- Người dùng: đăng ký Apple Developer (cá nhân), App ID `com.phiotron.vigon`, API key App Store Connect + chứng chỉ ký → GitHub Secrets của repo `phiotron/vigon`.
- Không có iPhone: iOS được thử trên **iOS Simulator của GitHub Actions** (người dùng đồng ý push để chạy CI); TestFlight khi mượn được máy.
- Người dùng: Play Console cá nhân → **closed test 12 tester × 14 ngày** (bắt đầu sớm, dùng build hiện tại); tạo upload keystore ngoài repo (`docs/RELEASE.md`).
- Người dùng: đăng chính sách lên web → điền `AppInfo.privacyPolicyUrl` (`lib/src/app_info.dart`); TalkBack + cỡ chữ lớn nhất trên máy; mở CSV bằng Excel; đo pin 15 phút.
- Còn mở từ spec-review: PIN không đếm lần sai (D-007). (Đã giải ở 1.1: >10 danh mục → ô "Danh mục khác"; CSV theo ngôn ngữ; đủ ISO 4217.)
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
- **D-010..D-019** (sau gộp): D-010 UI từ token · D-011 iOS build cloud (CI dùng `ios.yml`) · D-012..D-016 của bản 1.1/1.2 · D-017 mã cài đặt PIN/phát hiện cài lại iOS · D-018 giữ chọn danh mục = lưu luôn · D-019 gộp nhánh, tính năng 1.2 chỉ Android trên iOS ẩn.
- **2026-11-05** Gộp cả hai nhánh song song vào main; gỡ hook pre-commit DemoChung (bản sao ở `D:/Mobile App/work/`). Nhánh/worktree cũ giữ nguyên.
- **2026-11-04** Chuyển từ DemoChung sang xưởng, mã `A002-vigon`; giữ repo `phiotron/vigon`; giữ worktree cũ trong `.claude/worktrees/` (bị gitignore).
- **2026-11-04** UI bản 1 = **nâng cấp** từ thiết kế hiện tại qua Claude Design (không thiết kế lại từ đầu), phạm vi đúng SPEC.
- **2026-11-04** Tài khoản Google Play và Apple đứng tên **cá nhân**.

## Retro (điền khi phát hành)
- Tổng phiên điều phối / phiên con:
- Chậm nhất ở đâu, vì sao:
- Thứ tái dùng được cho app sau:
- Cải tiến đề xuất cho Playbook:
