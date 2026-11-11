# [A002-vigon] Cảnh báo ngân sách + vân tay (F-37, F-41) — phiên con C4, 2026-11-11

Nhánh `a002-budget-bio-v5` (từ `dev` 72fb8ee), worktree
`D:/Mobile App/.claude/worktrees/a002-f37-budget-warn-67fc0a/apps/A002-vigon`. Chưa merge, chưa push.

Ghi chú khởi động: thư mục worktree đã có sẵn (nhánh cũ `a002-f37-budget-warning`, nền cũ 446641b) với
**bản nháp F-37 chưa commit** của một phiên trước. Tôi lưu bản nháp ra scratchpad, chuyển worktree sang nhánh
mới từ `dev`, rồi dùng lại phần logic tốt của nháp (trạng thái/mốc/monitor/test) — chuyển vào
`features/budget_alert/`, đổi theo D-042 và tách khỏi `SettingsRepository`. Nhánh cũ không bị đổi.

## Đã làm

### F-37 Cảnh báo sắp vượt ngân sách (AC-111..AC-113)
- `lib/src/features/budget_alert/` (mới):
  - `budget_status.dart` — hàm thuần: ngưỡng (mặc định 80, 50–95 bước 5), `BudgetState`
    normal/almostOver/over bằng số nguyên (ví dụ AC-111 đúng ở biên), % đã dùng làm tròn xuống, mốc thông báo.
  - `budget_alerts.dart` — lập kế hoạch thông báo: mỗi mốc (ngưỡng, 100%) mỗi ngân sách 1 lần/tháng; giảm rồi
    lên lại không báo; sang tháng (khoá = ngày đầu kỳ theo Ngày bắt đầu tháng) đặt lại; nhảy qua cả hai mốc → 1
    thông báo ở 100%; **mới bật / đổi hạn mức / đổi ngưỡng → chỉ ghi nhận, không báo** (không phải "một khoản
    làm vượt"). `BudgetAlertMonitor` chạy tuần tự, lưu trạng thái.
  - `budget_alert_settings.dart` — đọc/ghi thẳng bảng `settings` (KHÔNG đổi schema, không chạm
    `SettingsRepository`): `budgetAlertThreshold` (đi theo sao lưu), `budgetAlertEnabled` + `budgetAlertState`
    (theo máy).
  - `budget_alert_providers.dart` — ảnh chụp đã chi **tháng hiện tại** (tổng + theo danh mục, cùng một lần đọc,
    `PeriodSummary.of(rows, service:)` → cộng chính xác D-042, cùng cách `budgetSpentProvider`); hạn mức so theo
    Tiền tệ chính (`budget` / `Category.budget` là số dẫn xuất). `budgetAlertSyncProvider` theo dõi bảng `entries`
    nên mọi đường ghi khoản (ghi tay, sinh định kỳ, xác nhận hàng đợi) đều được thấy mà **không sửa entry editor**;
    khoản lùi tháng cũ không đổi đã chi tháng này → không báo. `listenBudgetAlertTaps` mở `/overview` khi chạm
    (router chưa có route này thì `/`).
  - `budget_alert_text.dart` — nội dung **chỉ %**: "Ngân sách tháng 11: đã dùng 80%", "Ăn uống: đã dùng 100%
    hạn mức tháng 11" / "November budget: 80% used", "Food: 100% of the November limit used".
  - `budget_notifier.dart` — kênh riêng `budget_alerts` ("Cảnh báo ngân sách"), mã thông báo trong
    [40000, 50000) (không đụng 1001 Nhắc ghi sổ, [20000, 30000) Nhắc hạn), không rung.
  - `budget_alert_rows.dart` — hai hàng ở Cài đặt → Kế hoạch: "Ngưỡng "Sắp vượt"" (bảng chọn 50–95%) và công tắc
    "Thông báo ngân sách" (mặc định tắt; giải thích → "Tiếp tục" → xin quyền như AC-61; từ chối → vẫn tắt + snackbar
    mở cài đặt hệ thống).
- `lib/src/ui/limit_bar.dart` — thêm `near`: icon ⓘ (`error_rounded`) + chữ đậm + thanh màu token `warning`
  (đã có trong `tokens.g.dart`, hổ phách, khác đỏ của Vượt). Vượt giữ ⚠ + `error`.
- `lib/src/features/home/home_screen.dart` (chỉ `BudgetBar`) và `entries/category_budget.dart` (chỉ thanh hạn mức):
  Sắp vượt → "Ngân sách tháng: Đã dùng 82% · Đã chi X / Y"; danh mục "Đã dùng 82% · Đã chi X / Y".
- `settings_screen.dart` — 2 hàng F-37 sau "Ngân sách tháng" (nhóm Kế hoạch); hàng sinh trắc sau "Khóa bằng mã PIN".

### F-41 Mở khoá bằng vân tay / Face ID (AC-119, AC-120, AC-125 phần quyền)
- `pubspec.yaml`: `local_auth ^3.0.2`, `local_auth_android ^2.3.0`, `local_auth_darwin ^2.0.5` (hai gói nền tảng
  cần import trực tiếp để dịch chữ hộp thoại). `docs/sbom/vigon.cdx.json` sinh lại (+6 gói local_auth*, BSD-3).
- `lib/src/features/lock/biometric.dart` (mới): `BiometricAuth` (lớp ngăn, test dùng giả), `LocalBiometricAuth`
  (`biometricOnly: true`, iOS ẩn nút "Nhập mật mã" bằng `localizedFallbackTitle: ''`; mọi lỗi/huỷ/khoá tạm →
  false), `biometricAvailabilityOf` (Android **chỉ tính khi có `BiometricType.strong`**, luôn gọi "vân tay"; iOS
  Face ID/Touch ID theo máy), `BiometricSettings` (cờ trong bộ nhớ an toàn cạnh PIN; chỉ bật khi PIN đang bật).
- `lib/src/features/lock/biometric_switch.dart` (mới): công tắc ở Bảo mật, chỉ hiện khi đã bật PIN; máy không có
  sinh trắc mạnh → tắt, không chạm được, kèm lý do; bật phải xác thực một lần.
- `lock_screen.dart`: màn khoá tự mở hộp sinh trắc một lần khi hiện (mở app, quay lại > 1 phút, từ widget/thông
  báo vì đều qua màn khoá); đúng → vào app; huỷ/sai/khoá tạm → ở lại màn PIN, PIN vẫn dùng được, nút "Mở bằng sinh
  trắc học" để thử lại. `app_lock.dart`: `unlockWithBiometric()`.
- `lib/src/data/pin_service.dart`: `PinService.biometricKey` + `disable()` xoá luôn cờ sinh trắc → **tắt PIN, "Xoá
  toàn bộ dữ liệu" (`deleteEverything` gọi `disable()`), cài lại iOS** đều tắt sinh trắc; bật lại PIN không tự bật
  lại sinh trắc.
- Android: `AndroidManifest.xml` thêm `USE_BIOMETRIC`, **gỡ `USE_FINGERPRINT`** (androidx.biometric tự gộp vào; gỡ
  để giữ đúng danh sách AC-125). `MainActivity.kt`: `FlutterActivity` → `FlutterFragmentActivity` (local_auth bắt
  buộc).
- iOS: `Info.plist` thêm `NSFaceIDUsageDescription` (en); `ios/Runner/{en,vi}.lproj/InfoPlist.strings` (mới) +
  thêm vào `project.pbxproj` (variant group `InfoPlist.strings`, id `A0020041CCCC…`, vào Resources của Runner).

### Dùng chung
- `.arb` vi/en: khối cuối file `budgetAlert*` (11 khoá) + `biometric*` (10 khoá); file sinh `app_localizations*.dart`.
- `lib/src/app.dart`: 3 dòng (import, `ref.watch(budgetAlertSyncProvider)`, `listenBudgetAlertTaps(ref, appRouter)`).
- `lib/src/data/backup.dart`: `BudgetAlertSettings.enabledKey`, `.stateKey` vào `deviceOnlySettingKeys`.

## Kiểm thế nào
- `flutter analyze`: sạch.
- Test mới / sửa (đều qua):
  - `test/features/f37_budget_alert_test.dart` (25): biên AC-111 (3.999.999 / 4.000.000 / 5.000.000 / 5.000.001),
    ngưỡng 50/95, mốc, kế hoạch thông báo (1 lần/mốc/tháng, giảm–lên lại, sang tháng, đổi cài đặt im lặng, danh mục
    độc lập), monitor lưu trạng thái, cài đặt + sao lưu (ngưỡng theo file, công tắc/trạng thái không), **nội dung
    vi + en không chứa số tiền hay ký hiệu tiền tệ** (VND/USD/EUR/JPY), mã thông báo.
  - `test/features/f37_budget_alert_ui_test.dart` (4): thanh màn chính đúng ví dụ AC-111 (chữ + icon), ngưỡng 90% +
    thanh danh mục ở Các khoản, Cài đặt (bảng ngưỡng 50–95, giải thích trước khi xin quyền, từ chối vẫn tắt), luồng
    thật: khoản lùi tháng 10 không báo, khoản tháng 11 báo đúng 1 lần ở 80% rồi 100%, chạm thông báo về app.
  - `test/features/f41_biometric_test.dart` (10, sinh trắc giả `test/fake_biometric.dart`): loại/khả dụng
    Android/iOS, cờ gắn PIN (tắt PIN tắt sinh trắc), công tắc ẩn khi chưa PIN, bật phải xác thực/huỷ vẫn tắt, máy
    không có sinh trắc → tắt kèm lý do, màn khoá tự hỏi + đúng thì vào, huỷ → ở lại PIN + nút thử lại, huỷ rồi nhập
    PIN vẫn vào, máy mất sinh trắc → không hỏi.
  - `test/features/g6_accessibility_test.dart`: thêm 4 test (sáng/tối × 100/200%): màn khoá có nút sinh trắc,
    thanh Sắp vượt ở màn chính + Các khoản, hàng mới ở Cài đặt, hộp "Bật thông báo ngân sách?".
  - `test/manifest_test.dart`: danh sách cho phép thêm `USE_BIOMETRIC`, danh sách cấm thêm các quyền AC-125.
  - `test/plan001_t6_ios_config_test.dart`: đúng một khoá `NS…UsageDescription` = `NSFaceIDUsageDescription`, không
    camera/ảnh; InfoPlist.strings vi + en có chuỗi và nằm trong project.
- Test cũ phải sửa vì thay đổi của tôi: `f26_widget_test` (danh sách quyền thêm `USE_BIOMETRIC`),
  `rates_screen_test` + `currency_picker_test` (nhóm Kế hoạch dài thêm 2 hàng → cuộn tới "Tiền tệ & kỳ" trước khi
  tìm/chạm).
- Toàn bộ `flutter test` (trước khi build): **924 qua, 1 bỏ qua** (test manifest release, lúc đó chưa build).
- **Build release:** `flutter build apk --release` thành công (ký khoá debug vì không có `key.properties`; Gradle
  210 s; `app-release.apk` 71,9 MB bản nhiều kiến trúc). Không cài máy, không adb.
  - Manifest hợp nhất `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
    chỉ có `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `USE_BIOMETRIC` (+ quyền chữ ký nội bộ
    `com.phiotron.vigon.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); **không có `USE_FINGERPRINT`**.
  - Sau build, chạy lại cụm native theo điều phối: `manifest_test` (test manifest release lần này CHẠY, không bỏ
    qua), `f26_widget_test`, `hifi_d4_android_widget_test`, `g5_lock_test`, `secure_window_test`,
    `manifest_deeplink_test`, `kotlin_channel_unit_test`: **48/48 qua**.
- `MainActivity.kt`: chỉ đổi lớp cha + import (mọi kênh `vigon/*`, FLAG_SECURE, intent widget/thông báo, deep link
  giữ nguyên). `styles.xml` không đổi.
- KHÔNG chạy adb (theo brief). Chưa build APK/iOS.

## Việc dở / rủi ro
- **iOS chưa build**: pbxproj + InfoPlist.strings chỉ kiểm bằng test đọc file; cần CI `ios.yml`. Android đã build
  release (xem trên). [M] vân tay trên A13, Face ID trên iPhone qua TestFlight còn chờ.
- **"Chỉ sinh trắc mạnh" trên Android chưa tuyệt đối**: local_auth_android 2.3.0 với `biometricOnly` cho phép
  `BIOMETRIC_WEAK | BIOMETRIC_STRONG`. App chỉ bật khi máy CÓ sinh trắc mạnh, nhưng máy có cả vân tay (mạnh) và
  khuôn mặt 2D (yếu) thì hộp hệ thống vẫn có thể nhận khuôn mặt yếu. Muốn chặn hẳn phải gọi BiometricPrompt với
  `BIOMETRIC_STRONG` qua kênh native riêng (việc sau nếu cần).
- **Android 7–8 (API 24–27) — quyết định của điều phối 2026-11-11 (duyệt qua tin nhắn):** gỡ `USE_FINGERPRINT`
  (androidx.biometric 1.1.0 tự gộp vào manifest) bằng `tools:node="remove"`, KHÔNG đổi `styles.xml`.
  1. Lý do: giữ đúng danh sách quyền AC-125 (chỉ thêm `USE_BIOMETRIC`), và tránh đổi theme khởi động — README
     local_auth: theme không phải AppCompat có thể crash ở Android ≤ 8, nhưng chỉ khi hộp vân tay cũ (API < 28) mở
     được; không có quyền thì hộp đó không bao giờ mở. Android 9+ dùng BiometricPrompt của hệ thống, không cần
     AppCompat.
  2. Trên Android 7–8 công tắc hiện tắt, không chạm được, với lý do "Máy không có hoặc chưa đăng ký sinh trắc học
     mạnh" / "No strong biometrics set up on this device" (`biometricUnavailable`) — đúng nhánh "máy không có sinh
     trắc" của AC-119.
  3. Chứng minh: `test/manifest_test.dart` "manifest hợp nhất bản release … không có quyền ngoài danh sách cho
     phép" đọc `build/app/intermediates/merged_manifests/release/**/AndroidManifest.xml` sau `flutter build apk
     --release` — xem mục "Build release" dưới.
  Muốn hỗ trợ vân tay Android 7–8 thì phải giữ `USE_FINGERPRINT` (sửa AC-125) + đổi `LaunchTheme`/`NormalTheme`
  sang `Theme.AppCompat.*`.
- Đổi tỷ giá (làm mới bảng) có thể làm đã chi theo Tiền tệ chính nhích qua mốc mà không có khoản mới → có thể báo.
  Hiếm; chấp nhận. Đổi Tiền tệ chính thì hạn mức đổi theo → coi là đổi cài đặt, không báo.
- **Ô "Ngân sách còn lại" ở Tổng quan** (AC-111 cũng áp; file `overview_screen.dart` của nhánh C2, KHÔNG làm ở
  nhánh này — điều phối nối khi gộp). Hàm/khối public để dùng lại:
  - `budgetStateFor(WidgetRef ref, {required int spent, required int limit}) → BudgetState` —
    `lib/src/features/budget_alert/budget_alert_providers.dart` (theo ngưỡng người dùng chọn).
  - `budgetStateOf({spent, limit, warnPercent})`, `budgetUsedPercent({spent, limit})`, `enum BudgetState {normal,
    almostOver, over}` — `lib/src/features/budget_alert/budget_status.dart` (hàm thuần).
  - `LimitBar(text:, progress:, over:, near:)` — `lib/src/ui/limit_bar.dart`; màu `context.vg.warning`; chữ
    `l.budgetAlertUsed(percent)` ("Đã dùng 82%"). Mẫu ghép chữ: `BudgetBar` ở `home_screen.dart`.
- Chính sách quyền riêng tư (`store/legal/privacy-policy.*`) còn mục Face ID/vân tay "để lại tới khi F-41 làm" —
  phiên điều phối cập nhật (ngoài phạm vi).
- Lỗi cũ phát hiện khi audit Cài đặt đã cuộn: hàng **"Tháng bắt đầu từ ngày"** (`_MonthStartRow`) có nút chạm thiếu
  nhãn (labeledTapTargetGuideline). Test g6 mới chỉ kiểm nhãn cho hàng F-37/F-41 ở vị trí đó; nên sửa riêng.

## Tham khảo worktree cũ `a002-biometric-m5` (chỉ đọc, theo yêu cầu điều phối)
Đã so `git diff` của `.claude/worktrees/a002-biometric-m5-6e8c61/apps/A002-vigon` (chưa commit, nền 446641b): phía
iOS (Info.plist, InfoPlist.strings vi/en, pbxproj — kể cả id `A0020041CCCC…`) và `unlockWithBiometric` trùng
bản này; nó đổi `LaunchTheme` sang AppCompat (bản này không, xem trên). Không lấy code nào. Ý có thể làm sau:
tách lý do "không có phần cứng" / "chưa đăng ký sinh trắc" thay cho một câu chung.

## Cần thử trên máy
- Màn khởi động sáng/tối không đổi sau khi đổi `FlutterFragmentActivity` (theme giữ nguyên).
- Galaxy A13 (Android 14): bật công tắc (hộp vân tay, huỷ → vẫn tắt), mở app/quay lại > 1 phút → hộp vân tay tự
  hiện, huỷ/sai → ở lại PIN + nút thử lại, mở từ widget và từ thông báo; che nội dung (FLAG_SECURE) vẫn chạy.
- Thông báo ngân sách: bật công tắc (hộp quyền Android 13+), ghi khoản qua ngưỡng → 1 thông báo kênh "Cảnh báo
  ngân sách", chỉ %; chạm khi bật PIN → qua màn khoá rồi tới Tổng quan (sau khi gộp C2).
- Android 7–8 nếu có emulator: công tắc sinh trắc tắt kèm lý do, app không crash.
- iPhone (TestFlight): hộp xin Face ID hiện chuỗi vi/en đúng ngôn ngữ máy; Touch ID trên máy có nút Home.

## Chỗ có thể xung đột khi gộp vào `dev`
- `android/app/src/main/AndroidManifest.xml` — **phiên người dùng đang sửa file này ở thư mục chính** (nhắc giờ,
  deadline reminders). Phần của tôi: 2 dòng `USE_BIOMETRIC` + chú thích + dòng gỡ `USE_FINGERPRINT`, ngay sau
  `RECEIVE_BOOT_COMPLETED`. Gộp thủ công giữ cả hai.
- `MainActivity.kt` — đổi lớp cha; nếu phiên kia sửa file này (kênh deep link…) thì giữ `FlutterFragmentActivity`.
- `test/manifest_test.dart` — nếu phiên kia thêm quyền, hợp danh sách cho phép.
- `lib/src/app.dart` (3 dòng), `settings_screen.dart` (Kế hoạch + Bảo mật, C3 cũng có thể thêm hàng), `.arb` + file
  sinh (khối cuối file — xung đột chắc chắn với C2/C3 nếu họ cũng nối cuối: giữ cả hai khối rồi `flutter pub get`
  sinh lại), `pubspec.yaml/.lock` + `docs/sbom` (C3 thêm excel/pdf: hợp rồi `flutter pub get` + `python
  tool/make_sbom.py` lại), `ios/Runner.xcodeproj/project.pbxproj`, `backup.dart` (`deviceOnlySettingKeys` —
  **phiên C1 nâng schema v8 cũng sửa file này**),
  `pin_service.dart`, `ui/limit_bar.dart`, `home_screen.dart` (`BudgetBar`) — C2 có thể đụng màn chính.
- Route `/overview`: khi C2 thêm, chạm thông báo ngân sách tự mở Tổng quan (không cần sửa gì).

## Đề xuất cải tiến xưởng
- Brief nên nêu trước "phụ thuộc native" của gói mới (local_auth cần FragmentActivity, tự gộp USE_FINGERPRINT,
  theme AppCompat): một bước "đọc README gói + manifest .aar trước khi hứa phạm vi" tiết kiệm một vòng hỏi.
- `dart format lib test` định dạng lại cả file ngoài phạm vi (5 file test + transfer/debts/savings của dev chưa
  format) → phiên con chỉ nên format file mình sửa; hoặc xưởng chạy `dart format` một lần trên `dev`.
- Worktree tái dùng còn nháp chưa commit của phiên trước: thêm bước "kiểm `git status` của worktree cũ, lưu nháp ra
  ngoài" vào mẫu BƯỚC 0.
