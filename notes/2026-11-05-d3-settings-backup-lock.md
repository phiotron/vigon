# [A002-vigon] D3 · Cài đặt, sao lưu, nhắc, khoá · 2026-11-05

Phiên con D3 của phiên điều phối #2. Lần 1 hết hạn mức sau khi đọc frame (`3a52704`, chỉ notes); lần 2 code xong.
**Commit:** `937a4b5` (màn + hộp thoại + test) · commit notes + test 200% hộp quên PIN (ngay sau).

## Đã làm / file đã đổi (theo frame)

| Frame | Đổi gì | File |
|---|---|---|
| SCR-12 / SCR-33, P2 5.1–5.2 | Cài đặt dạng thẻ: `SettingsGroupTitle` (Giao diện, Ngôn ngữ, Bảo mật, Nhắc ghi chép, Dữ liệu), 2 nhóm không tiêu đề (A18) cách 24, thẻ cùng nhóm cách 12; giá trị là phụ đề (Ngân sách, Tiền tệ "VND · ₫", Giờ nhắc); **Ngày đầu tuần = `SettingsSegmentRow` + `ChoiceSegments`** (trước: chạm để đổi); Tháng bắt đầu = hàng riêng có ô xổ "1 ▾"; Xuất/Khôi phục không ›; Xuất CSV có phụ đề `csvFormatVi`/`csvFormatEn` theo `l.localeName`; dòng `backupReminder` lề 32; Xóa toàn bộ = `danger`; icon sao lưu tự động `backup` | `settings_screen.dart` |
| SCR-12 A08 | "Hiện số tiền trên widget" có `StatusPill(lock, widgetLockedByPin)` ở footer khi PIN bật (công tắc vẫn bấm được) | `widget_section.dart` (`WidgetAmountsSwitch(pinEnabled:)`) |
| SCR-33 / D-022 | Mục iOS hiện theo cờ `supportsSecureWindow/HomeWidget/AutoBackup`; chữ riêng iOS khi `useIosCopy` (`defaultTargetPlatform == iOS`, đọc mỗi lần): phụ đề `secureWindowNoteIos`, `autoBackupNoteIos`, `VgHint(autoBackupRunsOnOpenIos)` ở footer sao lưu tự động, `VgHint(warning, autoBackupLocalFolderWarningIos)` dưới dòng thư mục | `settings_lead.dart` (giờ chỉ còn getter `useIosCopy`; lớp `SettingsLead` đã bỏ), `auto_backup_section.dart` |
| SCR-13, P2 5.5 | Tiền tệ là **sheet toàn màn** (`showModalBottomSheet` isScrollControlled): tay nắm, ✕ (tooltip Hủy) + tiêu đề, `VgSearchField` (nền `surface-container-high` qua `Theme` override), ghi chú ⓘ thu 2 dòng + `showMore/showLess` (Semantics expanded), nhãn `currencyCurrent` + thẻ ghim có ✓ (ẩn khi tìm, A09), dòng 72 "{MÃ} · {ký hiệu}" + tên, tô phần khớp `primary-container` 600, không khớp = icon `search_off` + `currencyNoMatch`. Lớp mới `CurrencyPickerSheet`, `CurrencyRow` (bỏ `CurrencyPickerDialog`) | `currency_picker.dart` |
| SCR-26, P2 8.5 | Hộp xuất: `VgDialog(icon upload_file, neutral, body backupNote)`, công tắc, `PasswordWarning` **trên** 2 `PasswordField`, nút Xuất có icon `ios_share`. **Mã hóa chạy trong hộp** (`BackupExportDialog(encrypt:)`): ô + Hủy tắt, nút = `BusyButtonLabel(busy, backupWorking)` (A13). Không truyền `encrypt` thì trả mật khẩu như cũ | `backup_password_dialogs.dart`, `data_actions.dart` (`exportBackupFile` dựng JSON trước rồi mở hộp; bỏ `runWithProgress`) |
| SCR-27, P2 8.6–8.7 | Hộp mật khẩu khôi phục: icon `lock` neutral, `PasswordField`, sai → lỗi dưới ô và **giữ chữ đã gõ**, đang giải mã → nút quay, Hủy tắt. Xác nhận: `showConfirmDialog(icon settings_backup_restore, iconTone neutral, note: restoreSwitchesNote)` — **cả iOS** (chốt điều phối, không dùng `restoreSwitchesNoteIos`) | `backup_password_dialogs.dart`, `data_actions.dart` |
| SCR-30, P2 8.11/9.2 | Hộp giải thích = `showConfirmDialog(icon notifications, neutral)` trước khi xin quyền (S-40); bị từ chối = `showVgSnackBar(reminderDenied, actionLabel: reminderOpenSettings, long: true)` (10 s, có vạch); giờ = `showTimePicker` (A14), sửa được cả khi tắt. `ReminderSection` tự dựng tiêu đề nhóm + thẻ (bỏ tham số `header`) | `reminder_section.dart` |
| SCR-31 | Thẻ sao lưu tự động: `SettingsSwitchRow(footer:)` — 📁 "Thư mục: X" → `SettingsStatusLine` (idle `autoBackupNever` / ok `autoBackupLast` / error dải đỏ `autoBackupFailedAt`) → `ButtonPair`: thường tonal "Sao lưu ngay" + viền "Chọn lại thư mục"; **lỗi thư mục đảo thứ tự** (tonal "Chọn lại thư mục" trước). Đang chạy: nút quay, cả hai nút tắt (`autoBackupRunningProvider`), bỏ hộp quay modal. Hộp mật khẩu sao lưu tự động: `VgDialog(icon backup)` + `PasswordWarning` + 2 ô (chuyển `AutoBackupPasswordDialog` sang `backup_password_dialogs.dart`, `auto_backup_section.dart` export lại) | `auto_backup_section.dart`, `auto_backup_providers.dart`, `backup_password_dialogs.dart` |
| P2 5.3–5.4 | Hộp ngân sách tháng → `VgDialog` (thân cuộn, nút ghim ≥ 130%, ô 56 theo theme), Enter = Lưu | `budget_dialog.dart` |
| P2 1.3–1.5 | Hộp quên PIN đã qua `showConfirmDialog` → `VgDialog` từ D0; chỉ thêm test 200% (thân cuộn, nút ghim) | không đổi code `lock/` |
| Không đổi | 1.1–1.2 Lock, 8.1–8.4 đặt PIN, About 9.1 | — |

`AlertDialog` không còn trong `features/settings|lock|about|reminder`.

## Kiểm tra thế nào

```
export PATH="/c/src/flutter/bin:$PATH"
dart analyze lib/src/features/settings lib/src/features/lock lib/src/features/about lib/src/features/reminder test/features/hifi_d3_settings_test.dart   # No issues found
flutter test test/features/hifi_d3_settings_test.dart test/features/currency_picker_test.dart test/features/f25_reminder_test.dart test/features/auto_backup_ui_test.dart test/data/auto_backup_review_test.dart   # 37 đạt
flutter test test/features/backup_password_test.dart test/features/plan001_t5_test.dart test/features/g5_lock_test.dart test/app_test.dart test/features/g3_screens_test.dart test/features/g4_screens_test.dart test/features/g6_flows_test.dart test/features/g6_accessibility_test.dart test/features/plan001_t4_test.dart   # 49 đạt
flutter test test/features/hifi_d3_settings_test.dart test/data/review_fixes_test.dart   # 18 đạt (sau khi thêm test quên PIN)
```
- Test mới `test/features/hifi_d3_settings_test.dart` (11): thẻ/tiêu đề nhóm, giá trị phụ đề, CSV vi, chọn Chủ Nhật lưu
  DB, icon `backup`, Xóa = danger; pill A08 khi PIN bật; iOS không còn chữ Android; 200% sáng/tối không tràn; sheet tiền
  tệ (xem thêm/thu gọn, ghim ẩn khi tìm, không khớp, ✕ đóng); hộp xuất đang mã hóa (Hủy/ô tắt, nút quay) + trả nội dung
  mã hóa; lỗi thư mục đảo cặp nút + dải lỗi; hộp quên PIN 200%.
- Sửa test cũ (chỉ đúng case màn D3): `f25_reminder_test` + `auto_backup_ui_test` + `plan001_t5_test` dòng 61–62
  (`SwitchListTile`/`ListTile` → `SettingsSwitchRow`/`SettingsNavRow`); `currency_picker_test` (`CurrencyPickerSheet`,
  `CurrencyRow`, cuộn hàng Tiền tệ vào màn trước khi chạm); `backup_password_test` (sai mật khẩu giữ chữ; nút Mở đổi
  thành "Đang xử lý" khi bận).
- **Chưa chạy** toàn bộ `flutter test` (theo brief, D5 chạy) và **chưa so ảnh** với PNG frame (D5).

## Điều cần D4 làm
1. **Test của D4 sẽ đỏ** vì Cài đặt không còn `SwitchListTile`: `secure_window_test.dart` (~78–101), `f26_widget_test.dart`
   (~364–384), `merge_ios_gating_test.dart` (`_switch()` dòng 63). Đổi cơ học `SwitchListTile` → `SettingsSwitchRow`
   (`import 'package:vigon/src/ui/settings_rows.dart'`), `.value` giữ nguyên. Chi tiết: ghi chú chung
   `…/side-session-notes/local_405e294e-…/d3-to-d4-settings-finders.md`. D3 không sửa (file của D4).
2. ~~Cảnh báo thư mục iOS~~ — **đã xong** sau tin của D4: điều kiện là `ios && state.folderInICloud != true` (cờ D4 thêm
   ở `6ed915c`; URI iOS là `ios-bookmark:<uuid>` nên không đoán theo đường dẫn được). Giới hạn: iOS không phân biệt
   "Trên iPhone" với Google Drive/Dropbox → hai loại này cũng hiện cảnh báo (D4 đã ghi cho điều phối).
3. D4 đã bật cờ iOS; test iOS của D3 kiểm có chữ `secureWindowNoteIos`, `autoBackupRunsOnOpenIos` và không còn chữ Android.

## Chỗ còn lệch mockup
- SCR-13: ghi chú và thẻ ghim nằm trong danh sách cuộn (frame: cố định trên danh sách) — để chữ 200% + bàn phím không tràn.
  Nút "Xem thêm" là dòng riêng dưới ghi chú (frame: nối cuối dòng 2).
- SCR-26/31: dòng cảnh báo dựng riêng (`PasswordWarning`) vì `VgHint` chưa có tông `error`.
- `SettingsNavRow` không có cách tắt mũi tên ›: Xuất/Khôi phục/CSV dùng `trailing: SizedBox.shrink()` (thừa 4 dp lề phải).
- Tháng bắt đầu dùng hàng tự dựng (không phải `SettingsNavRow`) để giữ Semantics "Tháng bắt đầu từ ngày: N" của ô xổ.

## Chữ còn thiếu
Không thiếu key.

## Component cần sửa trong `lib/src/ui/`
- `VgHint`: thêm `tone: error` (chữ + icon `error`) cho cảnh báo mật khẩu → bỏ `PasswordWarning`.
- `SettingsNavRow`: tham số `chevron: false` thay mẹo `trailing: SizedBox.shrink()`.
- `VgSearchField`: tham số màu nền (trên sheet `surface-container` cần `surface-container-high`).
- `VgDialog.cancelButton(onPressed: null)` vẫn bật (rơi về `Navigator.pop`) → cần tham số `enabled` cho A13; D3 tự dựng nút Hủy tắt.

## Việc dở / rủi ro
- Xuất sao lưu nay dựng JSON **trước** khi mở hộp (để mã hóa trong hộp): Hủy thì phí một lần đọc DB (nhanh, offline).
- `autoBackupRunningProvider` chỉ chặn bấm lặp từ Cài đặt; lần chạy nền vẫn báo `autoBackupBusy` như cũ.
- Đổi chạm "Ngày đầu tuần" sang nút chọn một: test/tài liệu khác mô tả "chạm để đổi" (nếu có) cần cập nhật.

## Đề xuất cải tiến xưởng
1. Script trích frame (bỏ `<style>/<svg>/<script>`, đổi `<span class="ms">x</span>` → `[x]`, chỉ lấy khối quanh
   `vg-dialog`/`vg-sheet`/id đích + phần `.anno`) giúp đọc 40 frame trong vài lệnh; **cẩn thận** regex
   `vg-status` ăn mất `vg-statusline`. Nên đưa vào `playbook/` cùng script rà chữ của D0.
2. Trong Git Bash, đừng mở lệnh bằng `cat > file` không có heredoc trước một `python - <<EOF` — `cat` chờ stdin làm treo
   lệnh tới hết thời gian (mất ~10 phút lần này). Viết script bằng công cụ Write rồi chạy.
3. Brief phiên song song nên liệt kê **test của phiên khác sẽ vỡ vì component đổi** (ở đây D4 tìm `SwitchListTile` trên
   màn của D3) để phiên điều phối giao trước cho một bên sửa.
