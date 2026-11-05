# [A002-vigon] D3 · Cài đặt, sao lưu, nhắc, khoá · 2026-11-05 — DỞ (hết hạn mức)

**Trạng thái:** mới đọc xong (APP.md, notes D0, CHANGELOG, frame SCR-12/13/26/27/30/31/33, code `features/settings|lock`,
test). **CHƯA sửa code, CHƯA chạy test.** Phiên sau (D3 tiếp) bắt đầu từ mục "Kế hoạch sửa" dưới đây.

## Đã rút ra từ frame (thay việc đọc lại HTML)

- **SCR-12/33 Cài đặt** (thứ tự thẻ): Giao diện [thẻ: ChoiceSegments] · Ngôn ngữ [thẻ] · (cách 24, không tiêu đề A18)
  thẻ {Danh mục ›, Tài khoản ›} · thẻ (margin-top 12) {Ngân sách tháng + giá trị ›, Khoản định kỳ ›, Tiền tệ "VND · ₫" ›,
  Ngày đầu tuần = `SettingsSegmentRow(icon: view_week, segments: Thứ Hai/Chủ Nhật)`, Tháng bắt đầu từ ngày + ô xổ "1 ▾"}
  · **Bảo mật** {PIN (sub `pinWarning`), Che nội dung (sub `secureWindowNote`; iOS `secureWindowNoteIos`), Hiện số tiền
  trên widget (sub + footer `StatusPill(icon: lock, label: widgetLockedByPin)` khi PIN bật, công tắc vẫn bấm được)}
  · **Nhắc ghi chép** {Công tắc, Giờ nhắc + giá trị "20:00" › (vẫn sửa được khi công tắc tắt)} · **Dữ liệu**: dòng ghi
  chú `backupReminder` (lề 0/32/8, body-sm chữ phụ) · thẻ {Xuất bản sao lưu (sub `backupNote`, không ›), Khôi phục (không ›),
  Xuất CSV (sub `csvFormatVi` nếu `l.localeName == 'vi'`, ngược lại `csvFormatEn`)} · thẻ Sao lưu tự động (icon
  **`backup`**, không phải cloud_upload) · thẻ {Xóa toàn bộ dữ liệu `danger`} · thẻ {Giới thiệu ›}.
  iOS SCR-33 vẽ khi chưa có D-022 (bỏ 3 hàng) → dùng cờ `supportsSecureWindow/HomeWidget/AutoBackup`, không vẽ riêng.
- **SCR-31 khối sao lưu tự động** = `SettingsSwitchRow(footer:)`, footer lề trái 56: dòng "📁 Thư mục: X" (body-sm) →
  `SettingsStatusLine` (idle `autoBackupNever` / ok `autoBackupLast` / error dải đỏ `autoBackupFailedAt`) →
  `ButtonPair`: thường = `FilledButton.tonal(BusyButtonLabel(icon: backup, label: autoBackupNow, busy:))` +
  `OutlinedButton(icon folder_open, autoBackupChooseFolder)`; **lỗi thư mục** = đảo: tonal "Chọn lại thư mục" trước,
  outline "Sao lưu ngay". Đang chạy: nút Sao lưu ngay quay + bỏ chạm, trạng thái cũ giữ nguyên (bỏ `runWithProgress`
  modal). Snackbar kết quả giữ như cũ. iOS: phụ đề `autoBackupNoteIos` + `VgHint(autoBackupRunsOnOpenIos)`;
  `autoBackupLocalFolderWarningIos` cần biết thư mục có phải "Trên iPhone" — `AutoBackupState` không có cờ → **D4 thêm**
  (tạm có thể đoán theo URI không chứa `Mobile Documents`).
- **Hộp mật khẩu (SCR-26/27/31)** cùng khuôn `VgDialog(icon:, tone: neutral, title, body, content: [...])`: dòng cảnh
  báo `VgHint(icon: warning)` màu error **trên** các ô (cần widget riêng vì VgHint không có màu error) → `PasswordField`×2.
  - 26 Xuất: icon `upload_file`, title `backup`, body `backupNote`, công tắc `backupSetPassword`; nút `backupExportAction`
    có icon `ios_share`. **Đang mã hoá nằm TRONG hộp** (A13): ô + Hủy tắt, nút = `BusyButtonLabel(busy, backupWorking)`.
    Đề xuất API: `BackupExportDialog({Future<String> Function(String pw)? encrypt})` — có `encrypt` thì chạy rồi pop
    nội dung đã mã hoá; không có thì pop mật khẩu như cũ (giữ test cũ); tắt mật khẩu pop `''`.
  - 27 Mở khoá: icon `lock`, title `backupEnterPasswordTitle`, body `backupEnterPasswordBody`; sai → lỗi dưới ô và
    **giữ nguyên chữ đã gõ** (code hiện xoá; test `backup_password_test` dòng ~148 phải đổi); đang giải mã: nút quay.
  - 27 Xác nhận: `showConfirmDialog(icon: settings_backup_restore, iconTone: neutral, note: l.restoreSwitchesNote)` — cả iOS (chốt điều phối).
  - 31 Mật khẩu sao lưu tự động: icon `backup`, title `autoBackupPasswordTitle`, cảnh báo `autoBackupPasswordWarning`, nút `autoBackupTurnOn`.
- **SCR-13 Tiền tệ**: sheet toàn màn (`showModalBottomSheet(isScrollControlled, useSafeArea)`), tay nắm, thanh {✕ đóng,
  title-md `currency`}, `VgSearchField` (nền surface-container-high), ghi chú ⓘ `currencyNote` thu 2 dòng + nút
  `showMore/showLess` (primary 600, có Semantics expanded), nhãn `currencyCurrent` + thẻ ghim (surface-container-high,
  bo md) dòng hiện tại có ✓ — ẩn khi đang tìm; danh sách A–Z dòng 72 "{CODE} · {sym}" + tên (A09); chữ khớp tô
  primary-container 600; không khớp: icon `search_off` + `currencyNoMatch` ở giữa. Chọn = áp ngay, đóng.
- **SCR-30 Nhắc**: hộp giải thích = `showConfirmDialog(icon: notifications, iconTone: neutral, title: reminderExplainTitle,
  body: reminderExplainBody, action: reminderContinue)`; bị từ chối = `showVgSnackBar(l.reminderDenied, actionLabel:
  l.reminderOpenSettings, onAction: scheduler.openSystemSettings, long: true)`; giờ = `showTimePicker` (A14), không snackbar.
- **Lock 1.3–1.5** đã đi qua `showConfirmDialog` → `VgDialog` (thân cuộn ở 200%) — chỉ cần thêm test 200%.

## Kế hoạch sửa (chưa làm)

1. `settings_screen.dart` dựng lại bằng `SettingsGroupTitle/Card/NavRow/SwitchRow/SegmentRow`; `_MonthStartRow` →
   `SettingsNavRow(trailing: MenuAnchor…)`; `widget_section.dart`, `reminder_section.dart`, `auto_backup_section.dart`
   đổi sang `SettingsSwitchRow` (giữ `AutoBackupSection()` const không tham số — `test/data/auto_backup_review_test.dart` dùng).
2. `budget_dialog.dart`, `backup_password_dialogs.dart`, `auto_backup_section.dart` (AutoBackupPasswordDialog),
   `runWithProgress` → `VgDialog`; `data_actions.dart` truyền `encrypt` vào hộp xuất.
3. `currency_picker.dart` → sheet; giữ tên lớp `CurrencyPickerDialog` hoặc sửa `currency_picker_test.dart` (đang tìm `ListTile`).
4. Test: sửa `auto_backup_ui_test` (`SwitchListTile` → `SettingsSwitchRow`), `backup_password_test` (SwitchListTile
   trong hộp xuất có thể giữ; ô sai mật khẩu không xoá), `currency_picker_test`, `f25_reminder_test`,
   `plan001_t5_test` dòng 61–62 (công tắc PIN); thêm `test/features/hifi_d3_*_test.dart` (200%, sáng/tối, iOS override).

## Điều cần D4 / D5 làm
- Test của D4 tìm `SwitchListTile` trên màn Cài đặt sẽ vỡ khi D3 đổi component — ghi chú chi tiết đã để ở thư mục ghi
  chú chung `…/side-session-notes/local_405e294e-…/d3-to-d4-settings-finders.md` (`secure_window_test`, `f26_widget_test`,
  `merge_ios_gating_test`: đổi sang `SettingsSwitchRow`).
- Thêm cờ "thư mục chỉ trên máy" vào `AutoBackupState` cho `autoBackupLocalFolderWarningIos`.

## Chữ còn thiếu / component cần sửa
- Chưa thấy thiếu key. `VgHint` không có tông error cho dòng cảnh báo mật khẩu → dựng widget riêng trong feature (hoặc D0 thêm `tone`).

## Đề xuất cải tiến xưởng
- Phiên con nên có script trích frame (bỏ CSS/SVG, chỉ lấy khối thay đổi + ghi chú) sẵn trong playbook: đọc thô 31 frame
  tốn phần lớn hạn mức của phiên này trước khi kịp sửa code.
