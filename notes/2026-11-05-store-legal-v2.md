# [A002-vigon] Store & pháp lý v2 — theo app đã gộp (báo cáo phiên con)

Phiên điều phối #1 · 2026-11-05 · tiếp phiên con C (bản 1: `notes/2026-11-04-store-legal.md`, commit `081fb0f`).
Đầu vào: `main` `a00bec8` (đã gộp `integration/spec-1.1` F-14..F-26 + `feature/PLAN-001` UI mới + iOS), báo cáo gộp
`notes/2026-11-04-gop-nhanh.md`, D-017, D-019. Phiên gộp đã sửa tạm các file store/pháp lý — phiên này kiểm lại theo code và sửa tiếp.
Không sửa code, `ios/`, `android/`, `APP.md`, `product.md`, `CONTEXT.md`. Không push, không đăng/nộp gì.

## Đã làm / file đã đổi
| File | Việc |
|---|---|
| `store/app-store.md` | Ghi lại trạng thái `ios/` sau gộp + bảng tính năng theo nền tảng; **viết lại mục Export compliance** (kết luận + bảng Apple + 3 phương án); Review Notes dùng đúng nhãn "Protect file with a password"; icon 1024 đã có; Availability ghi chú Pháp. Mô tả/keyword/What's New của phiên gộp đã đúng nền tảng — giữ, chỉ kiểm (EN 2.078, VI 2.003 ký tự) |
| `store/listing.md` | **Viết lại mô tả dài vi/en** theo khung giống App Store (Ghi nhanh · Nhìn rõ · Quản lý · Nhắc · Riêng tư · Sao lưu · Dễ dùng; vi 2.724, en 2.828 ký tự); sửa câu sai "2 quyền đều tùy chọn" (`RECEIVE_BOOT_COMPLETED` là quyền thường, tự cấp khi cài); Data safety: lý do "không chia sẻ" với sao lưu tự động/bảng chia sẻ, thông báo cục bộ; thêm ghi chú phát hành Play vi/en |
| `docs/legal/privacy-policy.md` | Mục 4 vi/en sửa đúng bản chất 2 quyền; ngày hiệu lực trả về `[điền ngày đăng]` (chưa đăng); bỏ "Lịch sử thay đổi" (bản đăng đầu tiên); ghi rõ AES-256-GCM cho file có mật khẩu; ghi chú nội bộ: bằng chứng code kiểm 2026-11-05 |
| `docs/COMPLIANCE.md` | P-03 viết lại theo kết luận export compliance; mục 4: Keychain cài lại đã xử lý (D-017), tính năng chỉ-Android ẩn trên iOS, thêm dòng 4.5.4 thông báo; mục 3 ghi ngày kiểm |
| `docs/RELEASE.md` | Định danh iOS: đề xuất đổi khoá mã hoá; icon 1024 → có; điều kiện chặn: quyết export compliance, thử [M] bản 1.2 trên máy Android thật |
| `store/screenshots-spec.md` | Bộ ảnh theo bản gộp: ảnh 3 (Bảo mật + Dữ liệu, khác nhau giữa 2 nền tảng), ảnh 4 có thanh hạn mức danh mục, **ảnh 8 tách: Play = widget, App Store = chữ lớn**; dữ liệu mẫu thêm hạn mức danh mục; quy tắc không nhắc nền tảng kia |
| `store/closed-test-plan.md` | Build từ `main` đã gộp; kiểm quyền bằng `aapt2` trước khi tải lên; thêm mục **"Nhờ tester thử"** các AC [M] bản 1.2 (nhắc, widget, sao lưu tự động, che nội dung, mật khẩu file); câu trả lời mẫu form production cập nhật |
| `store/brand/README.md` | Icon App Store 1024 đã có (`tool/render_ios_icon.py`) |

## Kiểm tra thế nào (kiểm code trước khi viết)
- `android/app/src/main/AndroidManifest.xml` + manifest đã gộp bản release (`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`, build 2026-11-05 08:27): đúng `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` + quyền nội bộ AndroidX; `VIBRATE` đã gỡ; không `INTERNET`. `allowBackup="false"` còn nguyên.
- `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption=false`, `FlutterDeepLinkingEnabled=false`, `LSApplicationQueriesSchemes` mailto/https, chỉ Portrait, không `NS…UsageDescription`. `PrivacyInfo.xcprivacy`: không tracking, không thu thập, C617.1 + E174.1. Icon 1024: header PNG 1024×1024, color type 2 (RGB, không alpha).
- `lib/src/platform_features.dart`: iOS ẩn sao lưu tự động, widget, che nội dung. `reminder_scheduler.dart`: iOS `requestAlertPermission: false` lúc khởi tạo, chỉ `requestPermissions` khi bật. Nội dung thông báo cố định trong `.arb` ("Have you recorded your spending today?").
- `lib/src/data/backup_crypto.dart`: `AesGcm.with256bits()` + `Pbkdf2` của gói `cryptography`; `pubspec.lock` không có `cryptography_flutter` → Dart thuần, không dùng mã hoá của iOS.
- `pin_service.dart` `clearIfReinstalled` được gọi ở `app_lock.dart:44` (D-017). DB iOS vẫn qua `driftDatabase` → Documents, không cờ loại khỏi sao lưu.
- Grep `lib/`: không `HttpClient`/`http`/`dio`/WebView. Nhãn trong tài liệu khớp `.arb` (Daily reminder, Protect file with a password, Hiện số tiền trên widget…).
- Đếm ký tự mô tả bằng script. Web: App Store Connect Help "Export compliance documentation for encryption" (bảng: mã hoá chuẩn không lấy từ OS → khai báo Pháp; tự chế → CCATS + Pháp).
- Không chạy `flutter analyze/test` (không đổi code).

## Kết luận chính cho phiên điều phối
1. **Export compliance (cần quyết, việc code):** `ITSAppUsesNonExemptEncryption = false` có khả năng **không còn đúng** vì F-21 chạy trên iOS với AES-256-GCM Dart thuần. Đề xuất: đổi thành `true` (sửa `ios/Runner/Info.plist`, `test/plan001_t6_ios_config_test.dart:37`, `.github/workflows/ios.yml:64`), bảng hỏi chọn "Standard encryption algorithms instead of, or in addition to…", bản 1 bỏ Pháp khỏi Availability (hoặc nộp khai báo Pháp). Phương án khác: chuyển AES sang CryptoKit để giữ `false` (tốn việc), hoặc ẩn mật khẩu file trên iOS (không khuyên).
2. **Hai điểm lệch iOS báo lần trước:** (b) Keychain giữ PIN sau khi gỡ → **đã giải** bằng D-017 (chưa kiểm chứng trên máy thật). (a) DB iOS vào sao lưu iCloud → **chưa đổi code**; tài liệu mô tả đúng thực tế ("có trong sao lưu iPhone nếu bạn bật"). Vẫn là quyết định của phiên điều phối; giữ như hiện tại là chấp nhận được (Apple Data Storage Guidelines cho phép dữ liệu người dùng tạo nằm trong Documents).
3. **App Privacy / Data safety vẫn "không thu thập, không chia sẻ"**: thông báo cục bộ, sao lưu tự động chỉ ghi file mã hoá vào thư mục người dùng chọn (Android), widget chỉ giữ chuỗi trong bộ nhớ riêng (Android).

## Việc người dùng phải làm (thêm so với bản 1)
- Quyết phương án export compliance (mục trên) và có bán ở Pháp ngay bản 1 không.
- Đăng chính sách: điền ngày hiệu lực đúng ngày đăng, tên thật thay `[Tên nhà phát triển]`.
- Khi closed test chạy: gửi tester danh sách "Nhờ tester thử" trong `store/closed-test-plan.md`.
- Các việc cũ vẫn còn: tài khoản Play/Apple, keystore, GitHub Secrets, ảnh bìa 1024×500, trader status EU, D-12.

## Rủi ro App Review / store
- Khoá mã hoá sai (`false` khi thực tế có mã hoá chuẩn ngoài OS) → khai báo không đúng với Apple; sửa trước lần tải build đầu.
- Liên kết chính sách trong app vẫn rỗng (`AppInfo.privacyPolicyUrl`) → 2.1/5.1.1 (như bản 1).
- Mô tả App Store không có widget/sao lưu tự động/che nội dung; nếu sau này bật lại trên iOS mà quên sửa mô tả (hoặc ngược lại) → 2.3.1. Ràng buộc nằm ở `platform_features.dart` + `merge_ios_gating_test`.
- Thông báo nhắc iOS, widget, sao lưu tự động, hộp thoại quyền Android 13+ **chưa thử trên máy thật** — Data safety/chính sách mô tả theo code và test, chưa theo máy.
- Play có thể hỏi về `RECEIVE_BOOT_COMPLETED`? Không phải quyền nhạy cảm cần khai riêng; mô tả và chính sách đã giải thích.

## Đề xuất cải tiến xưởng
1. **Bảng "tính năng × nền tảng" là nguồn sự thật cho store:** khi SPEC có tính năng chỉ một nền tảng, sinh luôn một bảng (có/ẩn/thay thế) và cho phiên store đọc bảng đó thay vì dò code; thêm vào mẫu SPEC.
2. **Checklist `release-ios.md`:** thêm "app có tự cài mã hoá (gói Dart/JS/C) không? → `ITSAppUsesNonExemptEncryption`, khai báo Pháp" — dễ bị bỏ sót khi thêm tính năng mã hoá sau khi đã cấu hình iOS. Có thể thêm test CI cảnh báo khi `pubspec.lock` có gói mã hoá (`cryptography`, `pointycastle`, `encrypt`) mà khoá vẫn `false`.
3. **Checklist `release-android.md`:** phân biệt quyền runtime và quyền thường khi viết mô tả/chính sách ("tùy chọn" chỉ đúng với quyền runtime).
4. Khi một nhánh tính năng lớn được gộp, mở lại phiên store/pháp lý **sau** gộp (như lần này) thay vì để phiên gộp sửa tài liệu pháp lý — phiên gộp chỉ nên đánh dấu "cần rà".
