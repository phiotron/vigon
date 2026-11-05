# [A002-vigon] D0 · Token v2 + component + chữ · 2026-11-05

Phiên con D0 của phiên điều phối #2 (chạy một mình, trước D1–D4). Nguồn: `design/hifi/` (token v2, design-system,
`_frames.json`, ghi chú "NEW copy" trong từng frame HTML), D-022, D-023.

## Đã làm / file đã đổi

**Commit:** `67f2cf8` token + theme · `f3688cf` chữ `.arb` · `a71bebd` component + test · commit notes này.

1. **Token v2** — `tool/gen_tokens.py` đọc `design/hifi/tokens/tokens.json` (schema giữ nguyên, `design/current/` để làm
   lịch sử) → `lib/src/ui/tokens.g.dart`: 38 màu (+12), 16 màu danh mục, 2 bóng, `VgRadius.widget = 20`,
   `VgSize.rowTwoLine = 72`.
   - Map theo cột "Maps to": `ColorScheme.surfaceContainerLow / errorContainer / onErrorContainer` = token v2;
     `ViGonColors.brandDeep/brandMint/brandPaper/brandDot` (getter) — cũng có ở `context.vg.brandDeep`.
     `widget-*` chỉ có trong `VgPalette` (`context.vg.widgetSurface`…), D4 đưa vào resource native.
   - **Lệch tên:** CHANGELOG ghi `VgTap.rowTwoLine`; generator sinh lớp `VgSize` cho nhóm `size` (cùng `tapMin`,
     `tapKey`…) nên tên thật là **`VgSize.rowTwoLine`**.
   - **Đổi hành vi:** trước đây theme đặt `errorContainer = swipe-delete`, `onErrorContainer = error`. Nay theo v2
     (`error-container` tối là `#93000A`, khác `swipe-delete`) → nền vuốt xóa ở
     `lib/src/features/entries/entries_screen.dart` đổi sang `context.vg.swipeDelete` + icon `context.vg.error`
     (**file ngoài phạm vi, 3 dòng + 1 import**).
2. **Theme** (`lib/src/ui/theme.dart`): ô nhập cao tối thiểu 56 (v1: 52), viền đang gõ 2 `primary`, lỗi 2 `error`,
   nhãn nổi label-sm; `outlinedButtonTheme` (viền `outline`, chữ `ink`, cao 40, vùng chạm 48); snackbar lề 12;
   `VgMotion` (150/200/250 ms, `standard`, `enter`, `VgMotion.reduced(context)`); `tonalButtonStyle(context)`.
   `FilledButton.tonal` đã đúng màu `secondary-container` qua theme.
3. **Component** trong `lib/src/ui/` — bảng API ở dưới. File mới: `messenger.dart` (viết lại), `dialog.dart`,
   `hint.dart`, `fields.dart`, `settings_rows.dart`, `spending_ring.dart`, `balance_bar.dart`, `limit_bar.dart`;
   sửa `confirm_dialog.dart`, `category_avatar.dart`, `category_grid.dart`; **chuyển**
   `features/settings/choice_segments.dart` → `ui/choice_segments.dart`.
4. **Chỗ gọi đã đụng (ngoài `lib/src/ui/`, tối thiểu):**
   - `features/home/home_screen.dart`: bỏ lớp `SpendingRing` (chuyển sang `ui/spending_ring.dart`, thêm nhãn Thu/Chi
     giữa vòng — **đã thấy ngay trên màn chính**); `_BalanceBar` dùng `BalanceBar` nhưng **chưa truyền `periodTitle`**
     (xem Việc dở D1); bỏ 2 import thừa.
   - `features/entries/category_budget.dart`: `CategoryBudgetBar` vẽ bằng `LimitBar` (chữ đậm 600 + ⚠ khi vượt,
     thanh đầy màu error; trước là bold không icon).
   - `features/entries/entries_screen.dart`: nền vuốt xóa (mục 1).
   - `features/settings/settings_screen.dart`: đổi 1 dòng import `choice_segments.dart`.
   - Tự động đổi ở mọi màn (qua component chung): snackbar mới (mọi `showUndoSnackBar`/`showMessage`), hộp thoại
     `showConfirmDialog` (thân cuộn, nút ghim, tiêu đề căn giữa khi có icon), ô ⋯ nét đứt, vòng chọn ở lưới danh mục,
     ô nhập 56 dp, `ChoiceSegments` xếp dọc bo `radius-lg`.
5. **Chữ** — `lib/l10n/app_en.arb`, `app_vi.arb` (+22 key mỗi file), `flutter pub get` sinh lại `app_localizations*.dart`.
6. **Test** — `test/ui/components_v2_test.dart` (mới, 29 test), `test/ui/theme_test.dart` (đọc token v2, thêm kiểm 14
   token, map vào theme, tương phản cặp mới).

## Component + API cho D1–D4

Mọi thành phần lấy màu từ `Theme.of(context).colorScheme` / `context.vg`, chữ từ `VgType`, cao lên theo cỡ chữ, vùng
chạm ≥ 48. Tên design-system = file `design/hifi/design-system/<Tên>.html`.

| Widget / hàm (file) | Tham số chính | Bản vẽ | Ai dùng |
|---|---|---|---|
| `showVgSnackBar(message, {actionLabel, onAction, duration, long})` (`messenger.dart`) | không nút 4 s, có nút 5 s, `long: true` 10 s; có nút → vạch thời gian; chữ + nút không vừa 1 dòng → xếp chồng (nút dưới chữ) | Feedback | mọi màn |
| `showUndoSnackBar(...)`, `showMessage(msg)` | giữ API cũ | Feedback | giữ nguyên |
| `buildVgSnackBar(...)` | trả `SnackBar` để dùng với `ScaffoldMessenger.of(context)` | Feedback | D3 (`reminder_section.dart` đang tự dựng `SnackBar` 10 s "Mở cài đặt" → nên đổi sang `showVgSnackBar(l.reminderDenied, actionLabel: l.reminderOpenSettings, onAction: …, long: true)`) |
| `SnackBarClearance(child:)` | bọc vùng đáy mà thanh thông báo không được che; chỉ tính route đang hiện | CHANGELOG "inverse-surface" | **D1: bọc hàng − / + (màn chính) và bàn phím số + Lưu (màn ghi khoản, chuyển tiền)** — chưa bọc |
| `VgDialog({title, body, icon, tone, note, content, actions})` (`dialog.dart`) | `tone`: `danger` (icon `error`) / `neutral` (icon chữ phụ); `note` = dòng ⓘ; `content` = ô nhập/công tắc; thân cuộn, nút ghim, ≥ 130% có vạch ngăn; `VgDialog.cancelButton(context)` | Dialogs | D2/D3: chuyển `AlertDialog` còn lại (budget_dialog, backup_password_dialogs, auto_backup_section, rule_dialog, account/category dialogs) |
| `showConfirmDialog(..., iconTone, note)` (`confirm_dialog.dart`) | thêm `iconTone` (mặc định `danger`), `note` | Dialogs, SCR-27 | D3: khôi phục = `icon: settings_backup_restore, iconTone: neutral, note: l.restoreSwitchesNote` |
| `VgHint(text, {icon})` (`hint.dart`) | icon ⓘ chữ phụ; icon khác màu `primary` | `.vg-hint` (SCR-21, 27) | D2 `recurringRestartHint`; D3/D4 cảnh báo thư mục iOS |
| `PasswordField({controller, label, errorText, helperText, enabled, autofocus, onChanged, onSubmitted, textInputAction, autofillHints})` (`fields.dart`) | nút 👁 `showPassword`/`hidePassword`; tắt gợi ý/tự sửa | TextFields, Dialogs "Form" | D3 (SCR-26/27/31) |
| `VgSearchField({controller, hintText, onChanged, onSubmitted, autofocus, focusNode})` | viên thuốc 48, nút ✕ `searchClear` khi có chữ | SearchField | D1 (SCR-11 trong `EntriesAppBar`, nút ← trước ô do màn đặt), D3 (SCR-13 tiền tệ) |
| `ScopeChips<T>({options: [(T, String)], selected, onChanged})` | chip 32, vùng chạm 48, chọn = `secondary-container` + ✓ | Chips "Filter chip pair" | D1 SCR-11 (`[(false, tên kỳ), (true, l.searchAllTime)]`) |
| `SettingsGroupTitle(text, {first})` (`settings_rows.dart`) | title-sm `primary` | SettingsRows | D3 |
| `SettingsCard({children, dividers, margin})`, `SettingsCard.gap` | nền `surface-container-low`, bo 16, vạch thụt 56 | SettingsRows | D3 |
| `SettingsNavRow({icon, title, value, onTap, danger, trailing})` | có `value` → cao ≥ 72 (`row-two-line`), giá trị là phụ đề; `danger` chữ đỏ không › | SettingsRows | D3 (Ngân sách, Tiền tệ "VND · ₫", Xuất CSV + `csvFormatEn/Vi`…) |
| `SettingsSwitchRow({icon, title, subtitle, value, onChanged, footer})` | chạm cả hàng; phụ đề dài không cắt; `footer` cho pill / dòng trạng thái / cặp nút | SettingsRows | D3 |
| `SettingsSegmentRow({icon, title, segments})` | segments thụt thẳng cột chữ | `.vg-weekseg` | D3 (Ngày đầu tuần; Giao diện/Ngôn ngữ không `title`) |
| `ChoiceSegments<T>` (`choice_segments.dart`, chuyển chỗ) | API giữ nguyên | SettingsRows "Segmented" | D3 |
| `SettingsStatusLine({status: idle/running/ok/error, text})` | lỗi = dải `error-container`; liveRegion | SettingsRows "Status row" | D3 SCR-31 |
| `StatusPill({icon, label, tone: lock/ok/error})` | | `.vg-pill` | D3 (A08 `widgetLockedByPin`) |
| `ButtonPair({children})`, `BusyButtonLabel({label, icon, busy})` | cặp nút xuống dòng; vòng quay 18 khi bận | ActionButtons, Feedback | D3 (Sao lưu ngay = `FilledButton.tonal`, Chọn lại thư mục = `OutlinedButton`) |
| `tonalButtonStyle(context)`, `VgMotion` (`theme.dart`) | | ActionButtons, motion.md | mọi màn |
| `SpendingRing({summary, currency, scale, showTotals})` (`spending_ring.dart`) | nhãn Thu/Chi giữa vòng; `showTotals: false` cho A04 | ChartRing | D1 (đã nối) |
| `BalanceBar({amount, periodTitle, onTap})` (`balance_bar.dart`) | tên kỳ dưới "Số dư", đọc "Số dư: X, tên kỳ" | ChartRing `.vg-balance` | D1 (đã nối, **chưa truyền `periodTitle`**) |
| `MoreCategoriesAvatar({size, onTap})` (`category_grid.dart`) | nền `surface`, viền nét đứt 2 `outline` | CategoryAvatar "⋯ slot" | D1 (đã tự áp) |
| `CategoryAvatar({category, size, onTap, semanticLabel, selected})` | `selected` → vòng chọn (không đổi bố cục), Semantics selected | CategoryAvatar "Grid cell selected" | đã áp ở `CategoryGrid` |
| `SelectedRingPainter`, `DashedCirclePainter` (`category_avatar.dart`) | | | dùng lại nếu cần |
| `LimitBar({text, progress, over, thickness = 4})` (`limit_bar.dart`) | vượt → ⚠ + chữ `error` 600 + thanh đầy; `thickness: 8` cho ngân sách tháng | ListRows `.vg-catbudget`, `.vg-budget` | D1 (`CategoryBudgetBar` đã dùng; `BudgetBar` màn chính chưa) |

## Key `.arb` mới (EN + VI, 22 key)

| Màn | Key | Nguồn |
|---|---|---|
| SCR-10 Các khoản | `categoryLimitThisMonth` "This month: {status}" | frame NEW copy |
| SCR-11 Tìm | `searchClear` | frame |
| SCR-12/33 Cài đặt, 26, 27, 30, 31 | `csvFormatEn`, `csvFormatVi` | frame |
| SCR-13 Tiền tệ | `currencyCurrent`, `showMore`, `showLess` | frame |
| SCR-17/18 Tài khoản | `archivedAccountsCount` "Hidden accounts ({count})" / "Tài khoản đã ẩn ({count})" | chữ trong frame (A10), chưa có key |
| SCR-21 Định kỳ | `recurringRestartHint` "… {date}" | frame |
| SCR-26/27/31 mật khẩu | `showPassword`, `hidePassword` | frame |
| SCR-27 Khôi phục | `restoreSwitchesNote`, `restoreSwitchesNoteIos` | frame |
| iOS D-022 sao lưu tự động | `autoBackupNoteIos`, `autoBackupRunsOnOpenIos`, `autoBackupLocalFolderWarningIos` | **đoán** |
| iOS D-022 che đa nhiệm | `secureWindowNoteIos` | **đoán** |
| iOS D-022 widget | `widgetPickerName` "Quick add"/"Ghi nhanh" (**đoán**), `widgetPickerDescription`, `widgetExpenseButton`, `widgetIncomeButton`, `widgetStale` | 4 key sau chép từ `android/.../widget_strings.xml` (EN/VI) |

Chữ đoán cần người dùng/điều phối duyệt:
- `autoBackupNoteIos` — "Ví Gọn only writes files to the folder you choose in the Files app, for example in iCloud Drive." /
  "Ví Gọn chỉ ghi file vào thư mục bạn chọn trong app Tệp, ví dụ trong iCloud Drive."
- `autoBackupRunsOnOpenIos` — "iPhone does not run apps on a schedule, so the backup runs when you open Ví Gọn, at most once a
  day." / "iPhone không cho app chạy theo giờ, nên bản sao lưu được tạo khi bạn mở Ví Gọn, mỗi ngày tối đa một lần."
  (**D4 phải làm đúng hành vi này** hoặc sửa chữ.)
- `autoBackupLocalFolderWarningIos` — cảnh báo thư mục "Trên iPhone" không vào sao lưu iCloud (D-021), khuyên chọn iCloud Drive.
- `secureWindowNoteIos` — "Hides content in the app switcher. iPhone does not let apps block screenshots." (iOS không chặn
  chụp màn hình như `FLAG_SECURE`; nếu D4 làm được thì sửa chữ).
- `widgetPickerName` — "Quick add" / "Ghi nhanh" (tên widget trong bộ chọn iOS; Android dùng "Ví Gọn").

Rà frame P1 (script so chữ hiển thị trong 231 frame EN/VI với `.arb`): ngoài các key trên, chữ còn lại là dữ liệu mẫu
(tên khoản, ngày), chữ hệ điều hành (bàn phím, hộp xin quyền, bộ chọn thư mục SAF, launcher), tên ngôn ngữ ("Tiếng Việt",
"English" — app viết cứng có chủ đích) hoặc chữ ghép từ key sẵn có ("VND · ₫", "Ngân sách tháng: Đã chi …", "Tiền nhà ·
Hằng tháng · 1 thg 12, 2026").

## Kiểm tra thế nào

```
export PATH="/c/src/flutter/bin:$PATH"
python tool/gen_tokens.py       # 38 màu, 16 màu danh mục, 2 bóng
flutter pub get
flutter analyze                 # No issues found
flutter test                    # 394 test đạt (364 cũ + 30 mới), ~25 s
flutter build apk --release     # √ app-release.apk 65.0 MB (Gradle ~102 s)
```
- `test/ui/` 43 test (13 cũ + 1 mới ở `theme_test` + 29 mới ở `components_v2_test`): snackbar 1 dòng / xếp chồng / nằm trên `SnackBarClearance` / 200% / sáng-tối;
  hộp thoại 200% thân cuộn + nút ghim + vạch ngăn, loại form có `androidTapTargetGuideline` + `labeledTapTargetGuideline`;
  ô mật khẩu (che/hiện, tooltip, ≥ 56), ô tìm (✕, ≥ 48, 200%), chip phạm vi (vùng chạm, tương phản sáng/tối, selected);
  Cài đặt (màu thẻ/dải lỗi, tap target + `textContrastGuideline` sáng/tối, Semantics công tắc, liveRegion, 200% xếp dọc);
  vòng Thu/Chi, thanh Số dư (Semantics, 200%), ô ⋯, vòng chọn, thanh hạn mức.
- Rà chữ frame: script `d0-audit-frames-vs-arb.py` để ở thư mục ghi chú chung của nhóm phiên
  (`…/side-session-notes/local_405e294e-…/`, ngoài repo); chạy `python <script> en|vi`.
- Mọi key `new` trong `_frames.json` có ở cả 2 `.arb` (kiểm bằng script, 249 key mỗi file).

## Việc dở / rủi ro (thuộc D1–D4)

- **D1 (màn chính / nhập / các khoản):**
  - Truyền `periodTitle: periodTitle(context, ref.watch(periodProvider))` vào `BalanceBar` ở `home_screen.dart` (đã
    để chú thích). Chưa bật vì test màn (`plan001_t3_test`, `g6_flows_test`…) tìm tên kỳ bằng `find.text` sẽ thấy 2 chỗ
    → sửa test cùng lúc.
  - Bọc hàng − / + và bàn phím số bằng `SnackBarClearance` (chưa bọc → snackbar Hoàn tác vẫn có thể che − / +).
  - A04 (≥ 130%): − / + thành icon 32 + chữ xuống dòng, nút cao 96; tổng thu/chi ra danh sách dưới vòng
    (`SpendingRing(showTotals: false)`).
  - `BudgetBar` màn chính → `LimitBar(thickness: 8)`; chip tài khoản đang lọc (§10.1 #1); empty state.
  - SCR-11: `EntriesAppBar` dùng `VgSearchField` + `ScopeChips`; tô `primary-container` + 600 cho chữ khớp; dòng 72;
    A07 dấu −/+.
  - SCR-10: tiền tố `categoryLimitThisMonth` khi kỳ đang xem không phải tháng này (A05); gutter 24 thay › ở dòng con.
- **D2 (danh mục / tài khoản / định kỳ):** `archivedAccountsCount`, nút "Hiện lại" trên hàng ẩn (A10), thu/mở 200 ms;
  sheet sửa danh mục có ô hạn mức + footer ghim (SCR-16); sheet định kỳ toàn màn + `VgHint(l.recurringRestartHint(...))`
  (SCR-21); chuyển `AlertDialog` sang `VgDialog`.
- **D3 (cài đặt / sao lưu / nhắc / khoá):** dựng lại Cài đặt bằng `SettingsGroupTitle/Card/NavRow/SwitchRow/SegmentRow`
  (A18: nhóm không tiêu đề giữ không tiêu đề); `csvFormatEn/Vi` dưới "Xuất CSV"; SCR-13 tiền tệ thành sheet toàn màn có
  `VgSearchField`, `currencyCurrent`, `showMore/showLess`; SCR-26/27/31 dùng `PasswordField`, `VgDialog(content:)`,
  `SettingsStatusLine`, `ButtonPair`, `BusyButtonLabel`; A13 tắt Hủy khi đang mã hoá. **Lưu ý:** frame iOS SCR-27 dùng
  `restoreSwitchesNoteIos` (không có widget) vì lúc vẽ iOS chưa có widget — theo D-022 iOS **có** widget → iOS cũng
  nên dùng `restoreSwitchesNote` (cần điều phối chốt).
- **D4 (iOS native + widget Android):** màu `widget-*` → `android/app/src/main/res/values/widget_colors.xml` (đã có
  file) + `@dimen` `radius-widget` 20; iOS widget lấy chữ từ các key `widget*` (chép sang `Localizable.strings` /
  `.xcstrings` của extension — Flutter `.arb` không đọc được trong WidgetKit); hành vi sao lưu tự động iOS phải khớp
  `autoBackupRunsOnOpenIos`; `secureWindowNoteIos` cho F-22 iOS.
- **Rủi ro:**
  - Snackbar: không cắt chữ (ưu tiên đọc được ở 200%), nên chữ rất dài có thể > 3 dòng.
  - Vạch thời gian co theo bước 50 ms bằng `Timer` (không AnimationController) để `pumpAndSettle` của test màn không
    chạy hết 5 s làm thanh tự đóng. Nhìn hơi "bậc thang" nếu soi kỹ.
  - `SnackBarClearance.current()` tính lúc hiện thanh; nếu bố cục đổi trong lúc thanh đang hiện (xoay máy, bàn phím
    mở) thì không tự cập nhật.
  - Ô nhập 56 dp áp cho **mọi** `TextField` có viền (cả ô cũ) — đúng P2 nhưng màn chật có thể cao thêm 4 dp/ô.
  - Hộp thoại có icon: tiêu đề nay căn giữa (theo frame SCR-27), trước căn trái.

## Đề xuất cải tiến xưởng

1. **Script rà chữ frame ↔ `.arb`** (`audit.py`: bóc chữ trong `.vg-phone` của từng frame HTML, bỏ phần `.anno` và
   thanh trạng thái, so với giá trị `.arb` có thay placeholder bằng `.+`) + **bóc "NEW copy" từ ghi chú frame**
   (regex `key — EN “…” · VI “…”`). Hai việc này thay cho đọc tay 231 frame; nên đưa vào `playbook/` làm công cụ dùng
   chung cho mọi app làm qua Claude Design (chỉ cần Claude Design giữ quy ước ghi "NEW copy" như lần này).
2. **Map token Claude Design → Flutter:** `gen_tokens.py` của A002 đã tổng quát (màu sáng/tối, cat-xx, spacing,
   radius, size, type, shadow) — tách thành công cụ xưởng `tools/gen_flutter_tokens.py <tokens.json> <out.dart>`.
   Thêm vào brief gửi Claude Design: "cột Maps to dùng tên lớp Dart thật (`VgSize`, không `VgTap`)".
3. **Bẫy test:** animation chạy liên tục trong snackbar/indicator làm `pumpAndSettle` trôi hết thời gian → thanh biến
   mất. Ghi vào "Lưu ý dễ vấp" của template APP.md: hiệu ứng trang trí trong snackbar dùng Timer từng bước hoặc tắt
   khi `disableAnimations`.
4. Phiên component chạy trước các phiên màn (D0 → D1..D4) là đúng: thay đổi component làm vỡ test màn hàng loạt
   (lần đầu 25 test đỏ vì snackbar), sửa một chỗ thay vì bốn phiên cùng vấp.
