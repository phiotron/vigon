# [A002-vigon] D7 · Đổi tiền tệ có quy đổi tỉ giá (D-025) — 2026-11-05

Phiên con của phiên điều phối #2 ("Mockup Hi-Fi A002-vigon"). Commit: `4d89358` (code + test), `adcdd3f` (tài liệu), notes này.
Đã push `origin main` (`143f413..adcdd3f`, gồm cả `4fbcb29` D-025 của phiên chính).

## Đã làm / file đã đổi
**Code**
- `lib/src/data/exchange_rate.dart` (mới): `ExchangeRate` (phân số BigInt, đọc "0.0000385"/"3.85e-5", `inverse`, `toStorage`),
  `convertMinorUnits` (làm tròn half-up đối xứng, BigInt nên không tràn), `RateTable` (bảng gốc USD, tỉ giá chéo, JSON),
  `ExchangeRateSource` trừu tượng → `ErApiRateSource` (GET `https://open.er-api.com/v6/latest/USD`), `ioHttpGetText`
  (`dart:io HttpClient`, chỉ https, `followRedirects=false`, hết giờ 10 s, tối đa 256 KB), `parseErApiResponse`.
- `lib/src/data/currency.dart`: bỏ `changeCurrency` ("chỉ dịch chữ số thập phân"); thêm `convertCurrency(db, code, rate)` — MỘT
  transaction, tính hết rồi mới ghi: `entries.amount` (thu, chi, chuyển tiền), `recurring_rules.amount`, `accounts.initial_balance`
  (âm được, 0 giữ 0), `categories.budget`, settings `monthlyBudget`; số > 0 tối thiểu 1; vượt 10^12 → `CurrencyConversionOverflow`, không
  đổi gì; `conversionExampleAmount`. Đã rà mọi cột int của 5 bảng: không còn cột tiền nào khác.
- `lib/src/data/settings_repository.dart`: `readCurrency`, `setCurrency`, cache `exchangeRates` (bảng tải gần nhất), `exchangeRateManual`
  (tỉ giá tự nhập gần nhất, đọc được chiều ngược).
- `lib/src/features/settings/currency_conversion.dart` (mới): `exchangeRateSourceProvider`, `formatRate` (6 chữ số có nghĩa),
  `changeCurrencyWithConversion`, `CurrencyConversionDialog` (VgDialog: đang tải → xác nhận / nhập tay). `settings_screen.dart` gọi luồng mới.
  Lỗi vượt giới hạn → VgDialog "Số tiền quá lớn"; xong → snackbar "Đã quy đổi mọi số tiền sang X". Widget màn hình chính tự cập nhật vì
  `widgetSyncProvider` theo dõi `currencyProvider` + stream DB (không cần sửa).
- `lib/l10n/app_en.arb`, `app_vi.arb` (+25 key, `currencyNote` viết lại) + mã sinh.
- `android/app/src/main/AndroidManifest.xml`: thêm `INTERNET` (chú thích D-025), sửa chú thích `<queries>`; `ios/Runner/PrivacyInfo.xcprivacy`:
  chỉ sửa chú thích (vẫn không tracking, không tracking domain, không loại dữ liệu thu thập); `Info.plist` KHÔNG đổi (ATS mặc định).
- `about_screen.dart`: sửa chú thích "không cần quyền INTERNET".

**Test** (mới/sửa): `test/data/currency_conversion_test.dart` (16), `test/data/exchange_rate_source_test.dart` (13, HTTP giả),
`test/features/currency_conversion_flow_test.dart` (9 luồng + 8 trợ năng 100/200% sáng/tối), `manifest_test.dart` (cho INTERNET, cấm
cleartext/ATS ngoại lệ, chỉ một file tạo `HttpClient`), sửa `g3_repositories_test`, `review_fixes_test`, `amount_input_test`,
`currency_picker_test`, `f26_widget_test` theo hành vi mới.
- Test trợ năng bắt được 1 lỗi thật: nút "Thử lại" màu `primary` trên nền hộp thoại chỉ 4,06:1 → đổi `onPrimaryContainer`.

**Tài liệu** `docs/legal/privacy-policy.md` (ghi chú nội bộ D-025; VI+EN mục 1 đoạn "Kết nối mạng duy nhất", mục 3, 4, 5, 10),
`store/listing.md` (mô tả, Data safety, quyền, số ký tự), `store/app-store.md` (promo text, mô tả, Age Rating, App Privacy, Export
compliance, App Review notes), `store/closed-test-plan.md`, `docs/COMPLIANCE.md` (D-01, D-02, D-11, P-10, mục 4, mục 5 mới "Mạng"),
`docs/SECURITY.md` (quyền, bản đồ dữ liệu, mục mới "Mạng (S-60 NETWORK)", checklist HTTPS), `docs/SPEC.md` (AC-21 viết lại, AC-43 sửa,
AC-70/71/72 mới, F-19, mục 5, iOS), `docs/ARCHITECTURE.md`.

## Nguồn tỉ giá + điều khoản
- **Chọn: ExchangeRate-API, gói Open Access** (`open.er-api.com`, AYR Tech (Pty) Ltd). Đọc https://www.exchangerate-api.com/docs/free
  ngày 2026-11-05: miễn phí, **không khóa API**, "use it for either personal or commercial currency conversion purposes", được cache,
  **bắt buộc ghi công kèm link** (cho phép làm kín đáo hợp giao diện) → hộp xác nhận có nút "Rates By Exchange Rate API" mở
  exchangerate-api.com; **giới hạn tần suất theo IP** (quá thì HTTP 429 trong 20 phút → app báo dịch vụ không phản hồi, cho nhập tay);
  **cấm phân phối lại** dữ liệu (app chỉ dùng trên máy; cache trong file `.vigon` là bản sao lưu riêng của người dùng — thấy ổn, nêu để
  biết). Có VND và ~166 mã. Cập nhật mỗi ngày.
- **Vì sao gọi bảng gốc USD:** bảng gốc VND làm tròn 6 chữ số thập phân (1 VND = 3.9e-5 USD, lệch ~1%); bảng gốc USD đủ chính xác
  (VND ≈ 25974.x) và URL giống nhau cho mọi người → không lộ tiền tệ người dùng.
- **Phương án đã cân nhắc:** fawazahmed0 currency-api qua jsDelivr + Cloudflare Pages (CC0, không giới hạn, không cần ghi công, 200+ mã kể
  cả crypto) — loại làm nguồn chính vì dự án một người, nguồn dữ liệu không rõ; có thể thêm làm nguồn dự phòng (lớp `ExchangeRateSource`
  sẵn) nhưng sẽ phải khai thêm 2 host trong chính sách. Frankfurter/ECB loại (không có VND).
- **Tỉ giá luôn lấy từ API thật lúc chạy** (`ErApiRateSource.fetch` mỗi lần mở hộp quy đổi); app KHÔNG có tỉ giá viết cứng hay bảng
  đóng gói sẵn. Cache trong `settings` chỉ là bảng đã tải lần trước, dùng để ĐIỀN SẴN ô nhập tay khi mất mạng (có ghi ngày). Số 25974 trong
  test là dữ liệu giả của HTTP giả. Hộp xác nhận hiện nguồn (link ghi công) + "Tỉ giá cập nhật ngày …" lấy từ `time_last_update_unix` của API.
- **Gọi API thật từ máy dev** 2026-11-05 09:38 UTC bằng `dart run tool/fx_probe.dart` (dùng đúng `ErApiRateSource` + `parseErApiResponse`
  của app): URL `https://open.er-api.com/v6/latest/USD`, `base_code` USD, ngày cập nhật 2026-11-05 (`time_last_update_utc` Thu, 05 Nov
  2026 00:02:31 +0000), 166 mã; **1 USD = 25.701,376047 VND**, 1 VND = 0,0000389084 USD, 1 EUR = 28.880,81 VND, 1 JPY = 162,28 VND.
  Mã trong bảng tiền tệ của app không có ở nguồn: **KPW, SVC** (2/155) → đổi sang hai mã này đi đường nhập tay (AC-71). Trước đó kiểm bằng
  `curl` cùng ngày: JSON đúng dạng.
- **Kiểm lại khi API đổi định dạng:** `dart run tool/fx_probe.dart` (chạy tay; nằm ngoài `test/` nên không chạy trong `flutter test`/CI;
  thoát mã 1 nếu lỗi mạng/định dạng hoặc thiếu VND, USD).

## Kiểm tra thế nào
- `flutter analyze`: No issues found.
- `flutter test`: toàn bộ **572 test**: lần chạy đầu 570 đạt, 2 hỏng (f26 khẳng định "không INTERNET"; manifest release đọc bản build
  cũ) → sửa f26, build lại, cả hai đạt. **Chạy lại toàn bộ sau commit `adcdd3f`: 572/572 đạt**, `flutter analyze` sạch (cả `tool/fx_probe.dart`).
- `flutter build apk --release`: OK, `build/app/outputs/flutter-apk/app-release.apk` (66 MB). `test/manifest_test.dart` trên manifest
  release đã gộp: đạt (INTERNET + POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED).
- **CI: CHƯA XANH — không chạy được.** Run `42003756535` (CI Android) và `42003756544` (iOS) cho `adcdd3f` dừng sau 2–4 s: "The job was
  not started because recent account payments have failed or your spending limit needs to be increased" (GitHub Billing của tài khoản
  `phiotron`). Không phải lỗi code. Cần người dùng xử lý Billing & plans rồi chạy lại (`gh run rerun 42003756535`, `gh run rerun 42003756544`).
- CHƯA thử trên máy thật (gọi mạng thật trên Android/iPhone, nút link ghi công, bàn phím số khi nhập tỉ giá).

## Việc dở / rủi ro
- **CI Android + iOS** chờ Billing (trên). iOS chưa build được với mã mới → chưa chắc chắn 100% (mã chỉ là Dart + `dart:io`, không plugin mới).
- **Làm tròn / quy đổi ngược:** VND→USD→VND không về đúng số cũ (vd 155.000 ₫ → 5,97 US$ → 155.065 ₫ ở tỉ giá 25.974); số nhỏ thành 1
  đơn vị tối thiểu (1 ₫ → 0,01 US$). Hộp xác nhận cảnh báo + gợi ý sao lưu; không có hoàn tác tự động (đúng D-025).
- **File sao lưu cũ khôi phục với tiền tệ khác:** file `.vigon` chứa cả khóa `currency` trong settings nên khôi phục đưa về đúng tiền tệ của
  file cùng số tiền của nó → nhất quán, không cần quy đổi. Nhưng cache tỉ giá trong file cũ ghi đè cache mới (chỉ ảnh hưởng gợi ý điền sẵn).
- **TLS không phải của iOS:** `dart:io` dùng BoringSSL trong engine Flutter. D-025 viết "D-020 không đổi vì HTTPS do hệ điều hành" — câu lý do
  sai, kết luận gần như đúng (vẫn "thuật toán chuẩn" → câu trả lời Apple không đổi) nhưng **bản khai ANSSI nên nêu thêm TLS client**.
- **Data safety / App Privacy:** đề xuất giữ "không thu thập" — cần người dùng duyệt (lý do trong `store/listing.md`, `store/app-store.md`).
- **Giới hạn tần suất theo IP:** nhiều người sau cùng CGNAT nhà mạng có thể gặp 429 → có đường nhập tay; chưa có nguồn dự phòng.
- Tài liệu NGOÀI phạm vi được sửa, còn câu "không INTERNET / offline hoàn toàn" (phiên chính sửa): `APP.md` dòng 20–21 (S-30 "không quyền mạng")
  và 94 (D-002), `docs/RELEASE.md:13` ("bản release không có INTERNET") và `:98-99` (bản khai ANSSI "không truyền dữ liệu qua mạng"),
  `docs/security/MASVS-SELF-CHECK.md:11` (MASVS-NETWORK "không áp dụng"), `docs/RISKS.md:15`, `docs/plans/PLAN-001…md:19` (lịch sử,
  có thể để nguyên), `docs/DECISIONS.md` D-025 (câu "HTTPS do hệ điều hành"). `docs/TESTING.md` (của D5) nên thêm bước thử máy thật:
  đổi VND→USD có mạng, bật chế độ máy bay → nhập tay, chạm link ghi công.

## Đề xuất cải tiến xưởng
1. **Widget test có vòng xoay "đang tải" (CircularProgressIndicator vô hạn) làm `pumpAndSettle` treo tới hết giờ** (mặc định 10 phút,
   `--timeout` của test cũng không cứu vì `pumpAndSettle` tự có hạn riêng). Dùng helper pump theo bước (`flow()` trong
   `currency_conversion_flow_test.dart`) và luôn chạy `flutter test` kèm `timeout 600` + `--timeout 90s` khi thử test mới.
2. `find.text`/`find.textContaining` **khớp cả `EditableText`**: gõ "USD" vào ô tìm rồi `textContaining('USD').first` sẽ chạm ô tìm. Tìm
   trong widget dòng (`CurrencyRow`) thay vì cả sheet.
3. Hai lần ghi drift liên tiếp trong cùng MỘT `tester.runAsync` (đổi theme rồi ghi khóa khác) có thể treo vĩnh viễn → mỗi lần ghi một `runAsync`.
   `debugPrint` bị trễ qua timer nên không in ra khi test treo; dùng `File.writeAsStringSync(flush: true)` để dò.
4. `dart format lib test` sửa luôn file của người khác → chỉ format file mình đổi (tôi đã hoàn lại `backup.dart`, `hifi_d4_ios_config_test.dart`).
5. Python heredoc trong Git Bash hỏng khi chuỗi có `\n`, `\U...` hay nhiều dấu nháy → viết script ra scratchpad rồi chạy.
6. Mẫu "nguồn dữ liệu mạng công khai": lớp trừu tượng + hàm GET tiêm vào + test "chỉ một file tạo HttpClient" + test cấm cleartext/ATS —
   có thể đưa vào `shared/` cho app sau cần gọi API công khai.
7. Trước khi push để chạy CI nên kiểm Billing GitHub Actions (repo private, macOS ×10 phút) — lần này CI không chạy vì thanh toán.
