# [A002-vigon] D4 — iOS F-22/24/26 + widget Android (EXT-01/02)

Phiên con D4 của phiên điều phối #2. Lần 1 hết hạn mức sau khảo sát (`dfce82d`); lần 2 (cùng ngày) làm toàn bộ.

## Đã làm / commit
| Commit | Nội dung |
|---|---|
| `1a1058c` | Widget Android EXT-01: 2×2 nút dọc + chữ 2 dòng (A15), 4×2 nút ngang + 1 dòng, hàng trên mặc định logo + "Ví Gọn" / icon khóa / icon cập nhật; màu `widget-*`, `@dimen` radius 20 (Android 12+ theo góc hệ thống), nút radius-md 12, dấu −/+ kèm chữ; bản xem trước = trạng thái mặc định. Icon thông báo `ic_stat_vigon` chép nguyên path lớp monochrome launcher (A16, EXT-02) |
| `6ed915c` | iOS: `ios/Runner/VigonNative.swift` (4 kênh), widget extension `ios/VigonWidget/`, App Group, URL scheme, PrivacyInfo, pbxproj; Dart: sao lưu iOS khi mở app, `PickedFolder.inICloud`, cờ iOS bật; test |
| `82a55cf` | CI `ios.yml`: plutil extension/entitlements/strings, test cấu hình, kiểm `.appex` trong bản simulator + release, log kênh native, deep link nóng/nguội |
| `7772526` | `docs/SECURITY.md` (hàng iOS F-22/24/26), `docs/COMPLIANCE.md` (privacy manifest) |
| `b16c3f3` | Sửa lỗi biên dịch Swift: dùng đúng tên Swift của giao thức `FlutterSceneLifeCycleDelegate` |
| `0b0c3ef` | `secure_window_test`, `f26_widget_test` dùng `SettingsSwitchRow` (giao diện Cài đặt mới của D3); CI iOS chỉ cảnh báo với `simctl openurl` |

File đổi chính: `android/app/src/main/res/{layout/vigon_widget*.xml, values*/widget_*.xml, drawable/ic_widget_*.xml, drawable/vigon_widget_*.xml, drawable/ic_stat_vigon.xml}`, `WidgetProvider.kt`, `ios/Runner/{VigonNative.swift, AppDelegate.swift, Info.plist, PrivacyInfo.xcprivacy, Runner.entitlements, Assets.xcassets/PrivacyLogo.imageset}`, `ios/VigonWidget/*`, `ios/Runner.xcodeproj/project.pbxproj`, `lib/main.dart`, `lib/src/platform_features.dart`, `lib/src/data/{auto_backup_service,backup_folder_service}.dart`, test `test/hifi_d4_*`, `test/data/hifi_d4_auto_backup_ios_test.dart`, `merge_ios_gating_test.dart`, `plan001_t6_ios_config_test.dart`, `.github/workflows/ios.yml`.

## Cách làm đã chọn + lý do
- **Không đổi Dart của kênh:** iOS hiện thực đúng giao thức Android của `vigon/secure`, `vigon/deeplink`, `vigon/widget`,
  `vigon/backup_folder` → `secure_window.dart`, `widget_sync.dart`, `deep_link.dart`, `AutoBackupService` chạy y nguyên.
- **Vòng đời scene:** lớp `VigonSceneHandler` (`FlutterSceneLifeCycleDelegate`, đăng ký `registrar.addSceneDelegate`) thay
  vì override `SceneDelegate`. Bài học: đặt tên Swift riêng + `@objc(selector)` bị trình biên dịch từ chối ("conflicts with
  optional requirement") → phải dùng đúng tên Swift: `scene(_:willConnectTo:options:)`, `scene(_:openURLContexts:)`,
  `sceneWillResignActive(_:)`, `sceneDidEnterBackground(_:)`, `sceneDidBecomeActive(_:)`.
- **F-22:** khi `sceneWillResignActive`/`DidEnterBackground` và công tắc bật → phủ `PrivacyCoverView` (màu `surface`
  sáng/tối + logo `PrivacyLogo`); gỡ ở `sceneDidBecomeActive`. Hệ quả: lớp phủ cũng hiện khi kéo Trung tâm điều khiển hay
  khi có hộp thoại hệ thống (vd xin quyền thông báo) — bình thường với app tài chính. Không chặn được chụp màn hình.
- **F-24:** `UIDocumentPickerViewController(forOpeningContentTypes: [.folder])`; bookmark lưu UserDefaults của app (khóa
  `vigon.backupFolder.ios-bookmark:<uuid>`), Dart chỉ giữ mã đó trong SecretStore như URI Android; bookmark cũ tạo lại
  tại chỗ; ghi/xóa qua `NSFileCoordinator`; file iCloud chưa tải (`.<tên>.icloud`) được đếm/dọn theo tên thật. Lỗi map vào
  `permission_denied`/`folder_missing` sẵn có. **Lịch:** iOS chạy khi mở app (3 s sau khung đầu) và mỗi lần quay lại
  (`lib/main.dart`, `UncontrolledProviderScope` + `AppLifecycleListener`), KHÔNG chạy lúc ra nền (iOS có thể treo app giữa
  chừng); giữ luật cũ "tối đa một lần mỗi ngày lịch + chỉ khi dữ liệu đổi" (khớp chữ `autoBackupRunsOnOpenIos`; brief ghi
  "> 24 h" nhưng chữ nói "mỗi ngày tối đa một lần" → chọn theo chữ và theo Android). Không làm BGTask (cần engine
  headless, không thử được; chữ đã nói không chạy theo giờ).
- **`inICloud`:** `pickFolder` iOS trả thêm `inICloud` (= `isUbiquitousItem`) → `PickedFolder.inICloud` →
  `AutoBackupState.folderInICloud` (khóa SecretStore `auto_backup_icloud`). iOS KHÔNG phân biệt được "Trên iPhone" với
  Google Drive/Dropbox → cả hai đều `false`. Đã nhắn D3 đổi `iosFolderMayBeLocal(uri)` (dò "Mobile Documents" trong uri —
  uri iOS nay là mã bookmark nên luôn true) thành `state.folderInICloud != true`. **Phiên điều phối cần chốt** có chấp nhận
  cảnh báo hiện cả với Google Drive/Dropbox không (hoặc đổi chữ cảnh báo thành "có thể không…").
- **F-26:** extension SwiftUI `VigonWidgetExtension` (`com.phiotron.vigon.VigonWidget`, iOS 16+ vì AppIntents), nhỏ +
  vừa; dữ liệu App Group `group.com.phiotron.vigon` (khóa `widget.line`, `widget.validUntil`, `widget.stale`); dòng không có
  hạn dùng = khóa PIN (Dart không bao giờ gửi số thiếu hạn) → icon khóa; hết kỳ → extension XÓA số, hiện "Mở app để cập
  nhật". Nút: cỡ vừa dùng `Link(vigon://open/entry/new?type=…)`; cỡ nhỏ (iOS không nhận `Link` ở widget nhỏ) dùng
  `Button(intent: OpenEntryIntent)` iOS 17+ (mở app, để route trong App Group, app lấy trong 60 s); iOS 16 cỡ nhỏ chạm cả
  widget → màn khoản chi. Chữ `Localizable.strings` EN/VI chép từ `.arb` (test so khớp). Màu = Android (test so khớp).
- **pbxproj:** sửa tay (id `A0020004BBBB0001…`), phase "Embed Foundation Extensions" đặt trước "Thin Binary", version
  extension lấy từ `Flutter/Generated.xcconfig` qua `VigonWidget.xcconfig`.

## Kiểm tra
- `flutter test test/hifi_d4_ios_config_test.dart test/hifi_d4_android_widget_test.dart test/data/hifi_d4_auto_backup_ios_test.dart test/plan001_t6_ios_config_test.dart test/data/auto_backup_test.dart test/data/auto_backup_review_test.dart test/data/device_backup_exclusion_test.dart` → **68 đạt**.
- `flutter analyze` các file Dart của D4 → 0 lỗi.
- `flutter test test/features/secure_window_test.dart test/features/f26_widget_test.dart test/features/widget_review_test.dart test/features/merge_ios_gating_test.dart test/hifi_d4_ios_config_test.dart` → **48 đạt** (sau khi D3 xong Cài đặt).
- `flutter build apk --release` → **đạt** (65.1 MB). Lần đầu lỗi `GeneratedPluginRegistrant.java` có `integration_test` do
  phiên khác sinh lại file cùng lúc; chạy lại thì qua.

## Kết quả CI (commit `0b0c3ef`)
- **iOS** run `41984106691`: **xanh** — plutil/test cấu hình, build simulator debug + release `--no-codesign` (cả
  `VigonWidgetExtension.appex` có PrivacyInfo + `en/vi.lproj`, cùng version với app), mở app trên simulator; log
  `VigonBackupExclusion: excluded=2 failed=0`, `VigonSecure: enabled=0`, `VigonWidget: clear`; extension được hệ thống nạp
  và render placeholder small + medium thành công (log `chronod`… `Request ended … success`).
- **Android** run `41984106703` (ci.yml: analyze + toàn bộ test): **xanh** — 453 đạt, 1 bỏ qua.
- Lần trước: `41982792619` lỗi biên dịch Swift (đã sửa `b16c3f3`); `41983149218` build xanh nhưng bước deep link lỗi:
  `simctl openurl vigon://…` làm iOS hiện hộp "Open in "Ví Gọn"?" mà CI không bấm được → nay chỉ cảnh báo. **Deep link
  iOS vì vậy CHƯA kiểm chứng tự động** (log không có `VigonDeepLink`).

## CHƯA kiểm chứng + cần gì
- App Group thật (widget đọc số do app ghi; nút widget nhỏ iOS 17) — cần Apple Developer + profile có App Groups → TestFlight.
- Lớp phủ F-22 trong app switcher, bộ chọn thư mục + iCloud Drive/Google Drive thật, bookmark sau khi khởi động lại máy,
  thu hồi quyền — cần iPhone (TestFlight).
- Widget trên màn hình chờ iOS và VoiceOver nút widget; widget Android trên launcher thật (2×2 rất thấp ~110 dp có thể
  chật vì hai nút 48 dp xếp dọc), TalkBack, icon thông báo trên thanh trạng thái — cần máy.
- Deep link iOS (nút widget vừa `Link`, nút widget nhỏ qua AppIntent, cả nóng lẫn nguội): CI không kiểm được vì hộp
  xác nhận của `simctl openurl`. Cần máy thật, hoặc thêm XCUITest bấm "Open" (tốn thêm phút macOS) — đề xuất.

## Hướng dẫn cho người dùng (khi có Apple Developer) — tự làm, Claude không tạo khóa
1. developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → **App Groups** → "+" → ID
   `group.com.phiotron.vigon`, mô tả "Ví Gọn widget".
2. Identifiers → App ID `com.phiotron.vigon` → bật capability **App Groups** → Configure → chọn `group.com.phiotron.vigon` → Save.
3. Tạo App ID mới `com.phiotron.vigon.VigonWidget` (App IDs → App) → bật **App Groups** → chọn cùng nhóm.
4. Profiles: tạo App Store profile cho CẢ HAI App ID (app + widget); nếu ký tự động trên CI thì API key App Store Connect đủ quyền tạo profile.
5. `release-ios.yml` hiện ký một target → khi làm phiên #3 phải ký thêm extension (export options có 2 bundle id).

## Câu "chỉ Android" cần sửa (D-022) — phiên khác/điều phối
- `store/app-store.md:7, 199, 247`; `store/listing.md:106`; `store/screenshots-spec.md:30` (ảnh 8 iOS có thể có widget).
- `docs/legal/privacy-policy.md:17-18, 71, 126, 151` (widget, sao lưu tự động, che nội dung nay có cả iOS; iOS: lớp phủ, không chặn chụp màn hình; thư mục app Tệp; App Group). Dòng 80/135 (khởi động lại máy) vẫn đúng "chỉ Android".
- `docs/SPEC.md:130, 140, 154, 161-163, 192-194, 211, 220, 228` (mục 5 "iOS": F-22/24/26 nay có iOS; F-23 vẫn chỉ Android; AC-56..60, 63, 64 thêm cách kiểm iOS).

## Chữ còn thiếu (không thêm key, theo brief)
- Không thiếu bắt buộc. Gợi ý: chữ cảnh báo thư mục iOS nên mềm hơn ("có thể chỉ nằm trên iPhone") vì không phân biệt được Google Drive/Dropbox.
- Widget iOS dùng `appTitle`, `addExpense`, `addIncome` có sẵn cho tên/VoiceOver.

## Việc dở / rủi ro
- `merge_ios_gating_test.dart` đổi sang tìm theo chữ (iOS nay CÓ đủ mục) + test cờ nền tảng; đã chạy đạt.
- D3 đã đổi cảnh báo thư mục iOS sang `state.folderInICloud != true` (`c157556`).
- Extension tối thiểu iOS 16 (app 15): iPhone iOS 15 không có widget.
- `release-ios.yml` chưa ký extension (xem hướng dẫn bước 5).

## Đề xuất cải tiến xưởng
- Mẫu "kênh native dùng chung giao thức Android/iOS" (tên kênh + mã lỗi giống nhau, Dart không phân nhánh) đáng đưa vào playbook: phần iOS thêm sau mà không đụng UI.
- Với dự án không có Mac: viết test Dart đọc file cấu hình (pbxproj, plist, strings so với .arb, màu so với Android) bắt được lỗi trước khi tốn phút macOS.
- Phiên native nặng nên commit theo từng phần (Android → Swift → extension → CI) để hết hạn mức vẫn giữ được kết quả.
