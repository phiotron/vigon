# 2026-11-16 · Hoàn thiện các chức năng còn mở (A002-vigon)

Phiên làm trực tiếp, **chỉ trong `apps/A002-vigon`**, không đụng điện thoại của người dùng
(đang bận) và không push GitHub. Mục tiêu: đóng bốn việc còn để mở trong `APP.md` / `docs/DECISIONS.md`.

## 1. PIN: đếm lần sai + khoá tạm (`D-050`, `AC-178`)

- `lib/src/data/pin_service.dart`
  - `PinAttemptResult`: `ok`, `failures`, `lockedUntil`, `remaining(now)`, `isLockedAt(now)`.
  - Bộ đếm ở **bộ nhớ an toàn** (khoá `pin_failures`, `pin_locked_until`), không ở SQLite nên
    file sao lưu không mang theo. `verifyAttempt(pin, now)`:
    - đang khoá → **không băm mã**, trả kết quả khoá (kể cả mã đúng);
    - đúng mã → xoá bộ đếm;
    - sai → tăng; lần 5 → 30 giây, 6 → 1 phút, 7 → 5 phút, 8+ → 15 phút.
  - `currentAttempt(now)` đọc trạng thái lúc mở màn khoá.
  - `setPin` / `disable` / `clearIfReinstalled` xoá bộ đếm.
- `lib/src/features/lock/app_lock.dart`: `LockNotifier.attemptUnlock` dùng `verifyAttempt`;
  `unlock` vẫn trả `bool` cho test cũ. `pinAttemptProvider` giữ kết quả cho màn khoá.
- `lib/src/features/lock/lock_screen.dart`: khi khoá, hiện "Thử lại sau m:ss", tắt bàn phím,
  đồng hồ 1 giây tự mở lại; mở app lại khi đang khoá vẫn phải chờ (`restore`).
- `lib/src/features/lock/pin_pad.dart`: thêm `enabled` (mặc định true).
- l10n: `pinLockedRetry` (vi/en).

**Vì sao `verify` vẫn giữ:** các chỗ xác nhận lại PIN trong app (đổi PIN, tắt PIN, xuất file…)
không nên bị bộ đếm của màn khoá chặn; chỉ màn khoá dùng `verifyAttempt`.

## 2. Hàng "Đánh giá" không còn nút chết (`D-051`, `AC-179`)

- `lib/src/app_info.dart`: thêm `playStorePublished = false` (đổi thành `true` khi bản đầu lên Play).
- `lib/src/features/settings/legal_actions.dart`: `canRate` trên Android phụ thuộc hằng này;
  `rateApp` khi chưa có trang thì báo `rateUnavailable` (l10n vi/en).
- `test/features/plan001_t5_test.dart`: hàng Đánh giá so theo `LegalActions.canRate`;
  `test/features/rate_row_test.dart`: canh ánh xạ Android/iOS/máy tính.

## 3. Android 12+: chặn chuyển máy trực tiếp (nối `D-020`)

- `android/app/src/main/res/xml/data_extraction_rules.xml`: loại toàn bộ vùng dữ liệu ở cả
  `cloud-backup` và `device-transfer`.
- `android/app/src/main/AndroidManifest.xml`: `android:dataExtractionRules="@xml/data_extraction_rules"`
  (giữ `allowBackup="false"`).
- `test/android_backup_rules_test.dart`: đọc mã nguồn, canh manifest + đủ vùng bị loại ở cả hai phần.
- Chưa kiểm trên máy thật; `dumpsys backup`/chuyển máy là bước thử tay sau.

## 4. Chip nhắc hạn của Tiết kiệm theo đúng ngày + giờ (`D-044`)

- `nextDeadlineReminder` chuyển từ `features/debts/debts_screen.dart` sang
  `features/reminder/deadline_reminders.dart` (dùng chung, tránh Tiết kiệm import màn Nợ).
- `features/savings/savings_screen.dart`: thẻ mục tiêu hiện "Nhắc ngày …" theo **mốc kế tiếp**
  (`remindNext`) thay vì luôn "Trước N ngày"; hết giờ nhắc của mốc trước N ngày thì chuyển sang
  đúng ngày hạn (giống Khoản nợ).
- `features/savings/goal_detail.dart`: thêm cùng dòng nhắc trong Chi tiết mục tiêu.
- `test/features/debt_next_reminder_test.dart` đổi import sang vị trí mới.

## Kiểm

- `flutter analyze`: sạch.
- `flutter test` toàn bộ: **1082 test xanh** (thêm 12 test: 6 ca đếm PIN ở `pin_test.dart`,
  1 widget test màn khoá ở `g5_lock_test.dart`, 2 test quy tắc sao lưu Android,
  3 test hàng Đánh giá; ngoài ra test cũ đổi kỳ vọng theo `canRate`).
- Chưa thử trên điện thoại (người dùng đang bận, đã dặn không đụng máy). Chưa push.

## Thử tay khi điện thoại rảnh

1. Nhập sai PIN 4 lần: vẫn "Sai mã PIN"; lần 5: "Thử lại sau 0:30", bàn phím xám/tắt.
2. Tắt app, mở lại: vẫn đang đếm ngược, không nhập được.
3. Hết 30 giây: bàn phím mở lại; nhập đúng thì vào app, bộ đếm về 0.
4. Cài đặt → Giới thiệu: không có hàng "Đánh giá Ví Gọn" (bản chưa lên Play).
5. Máy Android 12+: cài bản mới, kiểm chuyển máy/sao lưu không mang dữ liệu Ví Gọn.
6. Mục tiêu tiết kiệm có hạn, bật nhắc trước hạn 7 ngày lúc 09:00; sau 09:00 của ngày
   "trước 7 ngày", thẻ hiện "Nhắc ngày <ngày hạn>" thay vì "Trước 7 ngày".
