# [A002-vigon] D1 · Màn chính + nhập + các khoản · 2026-11-05

Phiên con D1 của phiên điều phối #2 (chạy song song D2/D3/D4). Phiên chạy 2 lượt: lượt đầu hết hạn mức sau phần màn
chính (`10c8921`); lượt 2 làm nốt phần còn lại.

## Đã làm / file đã đổi (theo frame)

**Commit:** `10c8921` màn chính · `255edda` sửa test màn chính · `91bb203` New entry · `2ac6259` Các khoản SCR-10 ·
`d2b2ce6` Tìm kiếm SCR-11 + test `hifi_d1` · commit notes này.

| Frame | Đã làm | File |
|---|---|---|
| SCR-01 more-categories / vi (A01) | Ô trên vòng icon chiếm 51,5 dọc theo vòng → bán kính 140 (360 dp và 393 pt) xếp đúng **17 ô** (16 danh mục + ⋯); trước là 15 | `features/home/home_screen.dart` |
| SCR-01 text-200 (A04) | Chữ ≥ 130%: vùng giữa đầu kỳ và − / + cuộn; vòng giữ khung 328, `SpendingRing(showTotals: false)`; `_TotalsList` (nhãn body-md chữ phụ ↔ số amount-md màu thu/chi, không vừa thì xuống dòng); nút − / + = `_TallAddButton` (icon `remove`/`add` 32 + chữ dưới, cao ≥ 96, hai nút cao bằng nhau) | `home_screen.dart` |
| SCR-07 | Ô ⋯ mở `showMoreCategoriesSheet`: lưới đủ mọi danh mục chi, cao tối đa = màn − thanh trạng thái − 40, tiêu đề cố định; chọn → `/entry/new?type=expense&category=id` (chọn sẵn, chưa lưu) | `features/home/home_extras.dart` (mới) |
| 2.1–2.3 (P2) | Nhãn Thu/Chi giữa vòng (D0); `BalanceBar(periodTitle:)` → đọc "Số dư: X, tên kỳ"; `BudgetBar` vẽ bằng `LimitBar(thickness: 8)` (vượt: chữ 600 thay 700); empty state: vạch vòng nhạt + "Bấm − để ghi khoản chi đầu tiên" + mũi tên ↓ (§10.1 #16, **tự thiết kế**, không có frame) | `home_screen.dart` |
| 2.6 + Home + Entries header (§10.1 #1) | `ActiveAccountChip`: chip `secondary-container` "Tài khoản: Thẻ" + ✕ (tooltip "Tất cả tài khoản") dưới đầu kỳ màn chính và đầu danh sách Các khoản, chỉ khi đang lọc (**tự thiết kế**, CHANGELOG ghi "Designed in P2" nhưng chưa có frame) | `home_extras.dart`, `entries_screen.dart` |
| Màn chính | Hàng − / + bọc `SnackBarClearance` | `home_screen.dart` |
| 3.1–3.8, 4.5–4.7 (P2) | Ô ghi chú bỏ lề trong 14 riêng → dùng theme (56 dp); bàn phím số + Lưu bọc `SnackBarClearance`; lưới 3.3 có vòng chọn (D0, qua `selectedId` có sẵn); giữ D-018 (chọn danh mục = lưu) | `features/entry/entry_editor_screen.dart` |
| SCR-10 category-budget / vi / long-text (A05) | Thanh hạn mức tách khỏi phụ đề, thành khối riêng ngay dưới dòng danh mục, thụt 72, lề dưới 12; chưa vượt "Đã chi X / Y", vượt chỉ "⚠ Vượt Z" (trước "Đã chi … · Vượt …"); tiền tố `categoryLimitThisMonth` khi kỳ đang xem không phải tháng hiện tại | `features/entries/category_budget.dart`, `entries_screen.dart` |
| SCR-10 / 4.1–4.2 (§10.1 #12) | Dòng khoản con: số tiền + rãnh 4 + 24 thay chỗ mũi tên → thẳng mép với tổng danh mục; dòng danh mục và dòng Số dư lề phải 16 như `.vg-row` (M3 mặc định 24) | `entries_screen.dart` |
| SCR-11 empty / searching / all-time / amount / no-match / text-200 (A06, A07, A21) | App bar tìm: ← "Đóng tìm kiếm" + `VgSearchField` (✕ `searchClear`); `ScopeChips<bool>` "{tên kỳ}" \| "Tất cả thời gian" (chọn một); dòng tổng body-sm chữ phụ, liveRegion, ẩn khi truy vấn trống; danh sách mới nhất trước; `SearchResultTile` cao ≥ 72: avatar 40 (chuyển tiền ⇄) · ghi chú/tên danh mục · "danh mục · ngày" · số tiền có dấu −/+ màu chi/thu (chuyển tiền không dấu); tô chữ khớp `primaryContainer` + 600 ở tiêu đề, tên danh mục và số tiền (khớp không dấu nhờ ánh xạ `foldText` từng rune; số tiền vắt qua dấu ngăn cách, "155" tô "1.55" trong 1.550.000); 200%: chữ xuống dòng, số tiền xuống dưới; cuộn thì ẩn bàn phím; không khớp: icon `search_off` 40 + "Không có khoản nào khớp" | `features/entries/entry_search.dart` |

`EntrySearchResults` không còn tham số `tileBuilder` (dòng tìm có bố cục riêng, tự xử lý chạm sửa / vuốt xóa + hoàn tác).

## Kiểm tra thế nào

```
export PATH="/c/src/flutter/bin:$PATH"
flutter analyze lib/src/features/home lib/src/features/entry lib/src/features/entries test/features/hifi_d1_test.dart
# → No issues found
flutter test test/features/entry_flow_test.dart test/features/entry_search_test.dart \
  test/features/f20_category_budget_test.dart test/features/plan001_t3_test.dart test/app_test.dart \
  test/features/g3_screens_test.dart test/features/g4_screens_test.dart test/features/g6_flows_test.dart \
  test/features/g6_accessibility_test.dart test/features/review_fixes_test.dart \
  test/features/plan001_t4_test.dart test/features/plan001_t5_test.dart test/features/hifi_d1_test.dart test/ui
# → 118 test đạt
```

- **Chạy ở đâu:** lượt 2 lúc chạy test thì `lib/src/features/settings/` của D3 đang sửa dở (lỗi biên dịch
  `changeCurrency`, `runWithProgress`, `const SettingsLead`) nên cả app không biên dịch được trong thư mục chung. Tôi
  chạy test trong **git worktree tách rời tạm** (`--detach`, ở scratchpad, đã xóa) ở HEAD lúc đó + chép file của D1
  vào. Vậy 118 test đạt là trên code D1 + code D2/D3/D4 ở commit `1a1058c`, **chưa** với bản settings mới nhất của D3 → D5
  chạy lại toàn bộ.
- Test mới `test/features/hifi_d1_test.dart` (11 test): 25 danh mục → 16 ô + ⋯; ô ⋯ mở lưới, cao ≤ màn − 40, chọn
  "Mục 25" → Khoản chi mới đã chọn sẵn, DB trống; thanh Số dư có tên kỳ + nhãn đọc; empty state; A04 200%
  (`showTotals: false`, nút ≥ 96, không tràn); chip tài khoản + ✕; rãnh 24 thẳng mép; tìm: truy vấn trống (chip, mới
  nhất trước, không dòng tổng, dòng ≥ 72, −/+), tô chữ không dấu + số tiền "155"/"1.55", không khớp; hàm `textMatches`,
  `amountMatches`.
- Test cũ đã sửa (chỉ case màn D1): tên kỳ nay có 2 chỗ → `.first` / `findsNWidgets(2)` (`plan001_t3`, `g6_flows`);
  nhãn đọc Số dư thêm ", Tháng 11 năm 2026" (`entry_flow`, `g6_flows`); `f20` thêm tiền tố "Tháng này: "; `entry_search`
  về kỳ bằng chip tên kỳ (cặp chip chọn một, A21) thay vì bấm lại "Tất cả thời gian".
- **AC-02 (≤ 3 chạm) vẫn đạt:** `entry_flow_test` "bấm −, nhập 120+35, chọn danh mục…" xanh (− · Chọn danh mục · Ăn
  uống = lưu).
- **Chưa so ảnh PNG** với màn thật (không có công cụ chụp màn hình ở phiên này) → so ở mức bố cục/màu/chữ theo HTML
  frame + CSS; D5 so ảnh.

## Chữ còn thiếu

Không. Mọi chữ dùng key sẵn có (`account`, `allAccounts`, `emptyPeriod`, `searchClose`, `searchClear`, `searchHint`,
`searchAllTime`, `searchTotal`, `searchNoMatch`, `categoryLimitThisMonth`, `budgetProgress`, `budgetOver`, `transfer`).

## Component cần sửa trong `lib/src/ui/` (để gom về sau)

1. `MainActionButton`: thêm biến thể chữ lớn (icon 32 + chữ dưới, cao ≥ 96, A04) — hiện là `_TallAddButton` trong
   `home_screen.dart`.
2. `showCategorySheet`: thêm `maxHeight` (màn − thanh trạng thái − 40, SCR-07) — hiện là `showMoreCategoriesSheet`
   trong `home_extras.dart`. Màn ghi khoản vẫn dùng `showCategorySheet` cũ (cao theo nội dung).
3. Dòng tìm (`SearchResultTile`) + hàm tô chữ `textMatches` / `amountMatches` / `highlightSpans` nằm trong
   `entry_search.dart`; D3 tìm tiền tệ (SCR-13) cần tô chữ thì nên chuyển 3 hàm này sang `lib/src/ui/` hoặc `data/`.
4. `ActiveAccountChip` (home_extras) dùng chung cho màn chính + Các khoản; nếu Claude Design vẽ chip này thì đưa vào
   `lib/src/ui/`.
5. Không có lỗi component nào chặn.

## Chỗ còn lệch mockup

- Chip tài khoản đang lọc và empty state màn chính: **tự thiết kế** (không có frame) — cần điều phối/Claude Design duyệt.
- Vòng 17 ô: ở máy rộng hơn mà vòng vẫn 140 thì vẫn 17 (đúng A01). Màn thấp (vòng co) thì ít ô hơn, ⋯ xuất hiện sớm hơn.
- SCR-11: dòng tổng chưa "cập nhật sau khi ngừng gõ" (debounce) — cập nhật mỗi lần gõ, vẫn là liveRegion.
- SCR-11: ngày dùng `shortDate` như danh sách Các khoản (frame ghi "Today" cho hôm nay — app hiện không có "Hôm nay"
  ở danh sách; giữ nhất quán với 4.x).
- Chip tài khoản không hiện trong chế độ tìm (kết quả tìm vẫn lọc theo tài khoản).
- 3.x/4.5–4.7: P2 không có frame Hi-Fi riêng; chỉ đổi đúng các điểm CHANGELOG nêu.

## Việc dở / rủi ro

- `test/features/f14_accounts_test.dart` (file D2) có 1 case đọc nhãn Số dư (AC-44): đã nhắn D2, **D2 đã sửa**
  (nhãn kèm ", Tháng 11 năm 2026"). Rà `test/`: không còn file nào tìm nhãn "Số dư: X" cũ hay tên kỳ màn chính bằng
  `find.text` ngoài các file đã sửa (`components_v2_test` dựng `BalanceBar` riêng, đã xanh).
- `SnackBarClearance` đo lúc hiện thanh; ở màn ghi khoản khi bàn phím hệ thống mở (gõ ghi chú) thanh nằm trên bàn
  phím hệ thống, không phải bàn phím số (đúng ý: bàn phím số bị che bởi bàn phím hệ thống).

## Đề xuất cải tiến xưởng

1. **Phiên con song song cùng thư mục làm vỡ biên dịch của nhau:** một phiên sửa dở `settings/` là mọi phiên khác
   không chạy được test (Dart biên dịch cả app). Cách gỡ dùng được ngay: chạy test trong `git worktree add --detach
   <scratchpad>` + chép file của mình vào (không đổi nhánh thư mục chung, `pub get` ~10 s, không đụng khoá
   `sqlite3.dll` vì `build/` riêng). Nên ghi vào WORKFLOW/brief phiên con như cách mặc định khi chạy song song, hoặc mỗi
   phiên con một worktree riêng ngay từ đầu rồi điều phối gộp.
2. **Thay đổi component đổi nhãn đọc (Semantics) làm vỡ test ở file của phiên khác** (`BalanceBar` thêm tên kỳ →
   `f14` của D2). Phiên D0 (component) nên rà và sửa luôn mọi test bị ảnh hưởng khi đổi nhãn đọc, hoặc helper
   `findSemanticsLabel` có biến thể "bắt đầu bằng".
3. Brief phiên con nên nêu rõ phần nào **không có frame** (chip tài khoản, empty state) để phiên con biết là tự thiết
   kế và ghi lại cho Claude Design vẽ bổ sung.
