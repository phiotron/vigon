# [A002-vigon] D1 · Màn chính + nhập + các khoản · 2026-11-05 — DỞ (hết hạn mức dùng)

## Đã làm (chỉ màn chính, commit cùng file này)
- `features/home/home_screen.dart`: vòng icon 17 ô ở bán kính 140 (`_slotArc = 51.5`, A01); ô ⋯ mở
  `showMoreCategoriesSheet` (SCR-07, cao tối đa màn − status − 40) → `/entry/new?type=expense&category=id`;
  `BalanceBar(periodTitle:)`; `BudgetBar` → `LimitBar(thickness: 8)`; A04 (chữ ≥ 130%): vùng giữa cuộn, vòng 328
  `showTotals: false`, `_TotalsList` dưới vòng, nút −/+ thành `_TallAddButton` (icon 32 + chữ dưới, cao ≥ 96);
  empty state `_EmptyRing` (vạch vòng nhạt + lời nhắc + mũi tên ↓); hàng −/+ bọc `SnackBarClearance`.
- `features/home/home_extras.dart` (mới): `showMoreCategoriesSheet`, `ActiveAccountChip` (§10.1 #1, tự thiết kế,
  chưa có frame; dùng key sẵn `account`, `allAccounts`).

## Kiểm tra
- `flutter analyze lib/src/features/home` → No issues. **CHƯA chạy test** — dự kiến đỏ: test tìm tên kỳ bằng
  `find.text` (nay thấy 2 chỗ: đầu kỳ + thanh Số dư), test đếm số ô vòng (15 → 17), test `BudgetBar` chữ đậm 700 (nay 600).

## Việc dở (phiên sau / D1 tiếp)
1. Sửa test màn chính (`plan001_t3_test`, `g6_flows_test`, `app_test`… chỉ case màn chính) + test mới `hifi_d1_home_test.dart`
   (17 ô ở 360 dp, A04 200%, chip tài khoản, empty).
2. Ghi khoản (3.x): bỏ `contentPadding vertical: 14` ở ô ghi chú (để theme 56); bọc `Keypad` bằng `SnackBarClearance`.
3. Các khoản SCR-10 / 4.x: thanh hạn mức tách khỏi subtitle, thụt 72, vượt chỉ "Vượt X"; tiền tố
   `categoryLimitThisMonth` khi kỳ đang xem ≠ tháng này (A05); dòng con gutter 24 thay khoảng ›; dòng Số dư cao 64;
   `ActiveAccountChip` trên đầu danh sách.
4. Tìm SCR-11: `EntriesAppBar` → ← + `VgSearchField`; `ScopeChips([(false, tên kỳ), (true, l.searchAllTime)])`;
   dòng tổng body-sm chữ phụ (ẩn khi truy vấn trống, A06, mới nhất trước); dòng 72 (`VgSize.rowTwoLine`) avatar ·
   ghi chú · "danh mục · ngày" · số tiền có dấu −/+ màu (chuyển tiền không dấu, A07); tô khớp `primaryContainer` + 600
   (map vị trí qua `foldText` — giữ độ dài theo rune; số tiền: khớp chữ số xuyên dấu ngăn cách); không khớp: icon
   `search_off` 40 + `searchNoMatch`.

## Component cần gom về `lib/src/ui/`
- `MainActionButton` thêm biến thể cao (icon 32 + chữ dưới, ≥ 96) — hiện là `_TallAddButton` trong home.
- `showCategorySheet` thêm `maxHeight` (màn − status − 40) — hiện `showMoreCategoriesSheet` riêng.

## Chữ thiếu: không.
