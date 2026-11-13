# 2026-11-13 — Duyệt giao diện đợt 5 (Tổng quan, Thống kê, Lịch, Lọc, Xuất, Bảo mật)

Phiên **chỉ trong `apps/A002-vigon`**, không cần điện thoại (người dùng chưa cho adb).
Mockup v5 của Claude Design vẫn chưa có, nên đợt này duyệt bằng ảnh chụp thật của app
(`tool/shots/`) đối chiếu hệ thiết kế sẵn có: token `VgSpace`/`VgType`/`VgRadius`,
`StatsCard`, `ChoiceRow`/`showChoiceSheet`, chip `.vg-fchip` (`ScopeChips`),
`SettingsCard`/`SettingsSwitchRow`.

## Đã sửa (giao diện)

1. **Màn chính — lối vào Tổng quan/Thống kê/Lịch** (`home_screen.dart`)
   - Bỏ `PopupMenuButton` + `ListTile` (kiểu Material, lệch hệ thiết kế) → `IconButton`
     mở `showChoiceSheet` với 3 dòng `ChoiceOption` có icon, cùng kiểu các bảng chọn
     khác (2.4 Xem theo, 3.5 Lặp lại…).
   - Vẫn là lối vào **tạm** chờ mockup v5 / đề xuất điều hướng; hành vi và tooltip
     ("Tổng quan, thống kê, lịch") giữ nguyên nên test cũ không phải đổi.
2. **Tổng quan — thẻ "Nợ"** (`overview_screen.dart`)
   - Trước: icon, tiêu đề "Nợ" và mũi tên nằm giữa dòng chữ → tiêu đề bị thụt vào,
     câu "Không có khoản nợ nào đang mở" xuống dòng ở giữa cụm từ.
   - Sau: một hàng tiêu đề (icon · "Nợ" · ›) rồi các dòng nội dung bên dưới, chữ
     rộng hết thẻ nên câu không còn gãy dòng.
3. **Tổng quan — ô "Ngân sách còn lại" khi vượt**
   - Số tiền vượt bị ngắt giữa nhóm nghìn ("14.78 / 0.000 ₫") trong ô nửa bề rộng.
   - Số tiền giờ ở dòng riêng (tự thu nhỏ nếu quá dài — `_AmountText` dùng
     `FittedBox.scaleDown`, một dòng), nhãn mới **"Đã vượt"** + icon cảnh báo ở dòng
     dưới. Thêm khóa l10n `overviewBudgetOver` (en "Over").
   - Ô "Thu − chi tháng" và số ngân sách thường/sắp vượt dùng cùng `_AmountText`.
4. **Lịch — đầu danh sách ngày đang chọn**
   - Chỉ hiện phần có số: ngày chỉ chi đọc "Chi 45.000 ₫" (trước là
     "Chi 45.000 ₫ · Thu 0 ₫"). Ngày chỉ thu hiện "Thu …"; ngày trống bỏ hẳn dòng
     tổng. Dùng `l.expense`/`l.income` nên không thêm khóa l10n.
5. **Lọc — chip danh mục** (`entry_filter_sheet.dart`, `ui/fields.dart`)
   - `FilterChip` của Material → `ScopeMultiChips` (tách từ `ScopeChips`): chip cao
     32, viền `outline`, bo `radius-sm`, mục đang chọn nền `secondary-container` có ✓,
     vùng chạm 48 — đúng `.vg-fchip` (Chips.html, A21). Chọn nhiều vẫn như cũ.
6. **Biểu đồ cột** (`stats_widgets.dart`)
   - Cột không chọn hết bị bạc: alpha 0,45 → 0,55 (cả sáng và tối).

## Ảnh chụp duyệt

Bộ chụp `tool/shots/shots_test.dart` thêm nhóm P5 (tiếng Việt, sáng + tối):
`P5_1_overview`, `P5_1b_overview_over`, `P5_2_stats`, `P5_3_calendar`, `P5_4_filter`,
`P5_5_export`, `P5_6_security`, `P5_7_insights` (bảng chọn mới).
Sửa thêm dữ liệu mẫu: `_entry`/`_account`/luật định kỳ ghi `currency: 'VND'` +
`originalAmount`/`toAmount`/`toCurrency` — trước thiếu nên bị coi là USD và quy đổi
thành số nghìn tỷ; `_reveal` không còn truyền finder `.first` cho
`scrollUntilVisible` (lỗi "Bad state: No element" ở hàng Cài đặt chưa dựng).

## Kiểm tra

- `flutter analyze` — không lỗi.
- `flutter test` — **1070 test xanh** (f35/f36/f38, f39 lọc, components, toàn bộ).
- Có sửa test theo hành vi mới: f35 đọc "Chi 250.000 ₫" (bỏ "· Thu 0 ₫") và
  "500.000 ₫" + "Đã vượt"; f39 tìm chip qua `EntryFilterSheet` thay `FilterChip`.
- Chưa push (chờ người dùng cho phép); chưa thử máy.

## Còn lại

- Mockup v5 (Claude Design) chưa có → đợt sau áp lại theo mockup, đặc biệt điều hướng
  (product.md §4.2 vẫn ghi "please propose").
- Thử máy khi điện thoại rảnh: 8 kịch bản C1 trong `notes/2026-11-11-ledger-core.md`
  và các màn đợt 5 (Tổng quan/Thống kê/Lịch/Lọc/Xuất/Bảo mật).
- Vẫn còn: PIN không đếm lần sai (D-007); chip "Nhắc ngày" so ngày chứ chưa so giờ.