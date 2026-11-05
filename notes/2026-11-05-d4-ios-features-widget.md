# [A002-vigon] D4 — iOS F-22/24/26 + widget Android — BÁO CÁO DỞ (hết hạn mức sử dụng)

Phiên con D4 của phiên điều phối #2. **Chưa sửa dòng code nào**: phiên hết hạn mức khi vừa khảo sát xong.
File này là bàn giao để phiên D4 kế tiếp không phải đọc lại từ đầu.

## Đã làm
- Đọc: APP.md, DECISIONS D-011..D-023, SPEC F-22/24/26, notes D0, assumptions A15–A19, frame EXT-01 (HTML + PNG),
  `design-system/HomeWidget.html`, mã `lib/src/features/widget/*`, `auto_backup_service.dart`,
  `backup_folder_service.dart`, `device_backup_exclusion.dart`, `settings/secure_window.dart`, `lock/app_lock.dart`,
  Kotlin (`MainActivity`, `WidgetProvider`, `DeepLinkChannel`), res widget, `ios/Runner/*`, `project.pbxproj`,
  header Flutter `FlutterSceneDelegate.h`, `FlutterSceneLifeCycle.h`, `FlutterPlugin.h` (ở `C:/src/flutter/engine/...`).
- Chưa commit, chưa push, chưa chạy test/CI.

## Phát hiện quan trọng (dùng ngay khi làm tiếp)
- **Dart đã độc lập nền tảng**: kênh `vigon/secure`, `vigon/widget` (`show {line, validUntil}` / `clear`),
  `vigon/deeplink` (`takePending`, gọi ngược `routeAvailable`), `vigon/backup_folder` (`pickFolder`, `writeFile`,
  `listFiles`, `deleteFile`, `releaseFolder`; mã lỗi `permission_denied`/`folder_missing`/khác) → iOS chủ yếu chỉ cần
  viết phía Swift cho đúng 4 kênh này, gần như không đổi Dart.
- iOS dùng **scene + implicit engine + Swift Package Manager** (không Podfile). Đừng override hàm trong `SceneDelegate`
  (dễ sai chữ ký): viết lớp Swift `NSObject` + `FlutterSceneLifeCycleDelegate`, đăng ký trong
  `didInitializeImplicitFlutterEngine` qua `registrar.addSceneDelegate(...)`; dùng `@objc(sceneWillResignActive:)`,
  `@objc(sceneDidBecomeActive:)`, `@objc(scene:openURLContexts:)`, `@objc(scene:willConnectToSession:options:)` để
  khớp selector. Khởi động nguội có thể không nhận URL nếu engine đăng ký muộn → kiểm bằng `simctl openurl` trên CI.
- `test/fake_backup_folder.dart` **implements** `BackupFolderService` → thêm method vào lớp đó sẽ làm vỡ test (file
  không thuộc phạm vi D4). Chỉ thêm field tuỳ chọn (vd `PickedFolder.inICloud`).
- Hook sao lưu tự động nằm ở `lib/src/features/lock/app_lock.dart` `onHide` (ngoài phạm vi D4).
- Locked vs số tiền trên widget: dòng số luôn có `validUntil`, dòng "Đã khóa bằng PIN" không có → native suy ra
  được trạng thái khoá để hiện icon khoá mà không đổi API `HomeWidgetBridge`.
- Widget Android hiện tại: nút cạnh nhau, bo 14, không có hàng logo/"Ví Gọn", không icon khoá/cập nhật, chỉ 1 dòng.

## Cách làm đã chọn (chưa thực hiện)
- **F-22 iOS:** khi `sceneWillResignActive` và công tắc bật → phủ `UIView` màu nền app + logo (imageset mới chép từ
  launcher) lên window; gỡ ở `sceneDidBecomeActive`. Kênh `vigon/secure` `setSecure` chỉ lưu cờ trong bộ nhớ.
- **F-24 iOS:** `UIDocumentPickerViewController(forOpeningContentTypes: [.folder])`; lưu bookmark trong UserDefaults
  theo id, `uri` trả về Dart = `ios-bookmark:<uuid>` (bookmark cũ → tạo lại tại chỗ); ghi qua `NSFileCoordinator` +
  security-scoped; giữ tên file `vigon-auto-AAAAMMDD-GGPP.vigon`, giữ 7 file (logic Dart sẵn có). Trả thêm
  `inICloud` (= `isUbiquitousItem`) để D3 quyết hiện `autoBackupLocalFolderWarningIos` (không phân biệt chắc được
  "Trên iPhone" với Google Drive/Dropbox → cần phiên điều phối chốt). Trên iOS: `maybeRunDaily` (lúc ra nền) bỏ qua,
  thêm `maybeRunOnOpen()` gọi từ `lib/main.dart` (UncontrolledProviderScope + AppLifecycleListener onResume + sau
  khởi động vài giây); giữ luật "mỗi ngày lịch tối đa một lần" (khớp chữ `autoBackupRunsOnOpenIos`). Không BGTask.
- **F-26 iOS:** extension WidgetKit SwiftUI `VigonWidget` (systemSmall nút dọc, systemMedium nút ngang), màu widget-*,
  nút bo 12, `Link` tới `vigon://open/entry/new?type=expense|income` (thêm `CFBundleURLTypes` scheme `vigon`, Dart vẫn lọc
  `allowedDeepLinkRoute`, giữ `FlutterDeepLinkingEnabled=false`); dữ liệu UserDefaults suite `group.com.phiotron.vigon`;
  timeline thêm mục "cũ" tại `validUntil` (hiện `widgetStale`); `Localizable.strings` en/vi; entitlements App Group cho
  Runner + extension; `PrivacyInfo.xcprivacy` extension (UserDefaults 1C8F.1); Info.plist extension lấy version từ
  xcconfig `#include "../Flutter/Generated.xcconfig"`; pbxproj sửa tay (id kiểu `A0020004…`), phase "Embed Foundation
  Extensions" đặt TRƯỚC "Thin Binary" (tránh lỗi vòng phụ thuộc).
- **Android EXT-01:** layout tall (2×2: hàng logo+"Ví Gọn" mặc định / icon khoá / icon cập nhật + chữ 2 dòng, 2 nút dọc)
  và wide (4×2: 1 dòng, nút ngang) qua `RemoteViews(Map<SizeF,…>)` (API 31+) hoặc `OPTION_APPWIDGET_MIN_WIDTH`;
  nút = dấu −/+ 24sp + chữ 18sp đậm, bo `radius-md` 12; `@dimen` radius 20 (`values-v31` dùng
  `system_app_widget_background_radius`); previewLayout = trạng thái mặc định. Màu cố định → không cần `values-night`.
- **EXT-02 (A16):** `ic_stat_vigon.xml` vẽ lại từ path của `ic_launcher_monochrome.xml` (fill trắng, crop viewport
  ~64 quanh logo bằng group translate −22).

## CHƯA kiểm chứng / việc còn lại
Toàn bộ mục 1–6 của brief: mã Swift + extension, widget Android, icon thông báo, bật cờ `platform_features.dart`,
cập nhật test, CI `ios.yml` (build extension, `plutil`), push + đọc CI, `flutter build apk --release`.

## Hướng dẫn cho người dùng (khi có Apple Developer)
Tạo App Group `group.com.phiotron.vigon`, bật capability App Groups cho App ID `com.phiotron.vigon` và App ID mới
`com.phiotron.vigon.VigonWidget`, tạo provisioning profile cho cả hai (chi tiết viết khi làm xong phần iOS).

## Đề xuất cải tiến xưởng
- Phiên native iOS lớn (Swift + extension + pbxproj + CI) không vừa một phiên con cùng lúc với 3 phiên khác; nên tách
  "widget iOS" thành phiên riêng hoặc chạy trước khi hạn mức bị chia.
