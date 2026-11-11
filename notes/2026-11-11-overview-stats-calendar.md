# [A002-vigon] Tổng quan + Thống kê + Lịch (đợt 5, phiên con C2) — 2026-11-11

Nhánh `a002-overview-stats-v5` (từ `dev` 72fb8ee), chưa gộp, chưa push.
Worktree app: `D:/Mobile App/.claude/worktrees/a002-biometric-m5-6e8c61/apps/A002-vigon-ov5`
(KHÔNG phải `.../apps/A002-vigon` như brief — chỗ đó đã có worktree cũ, xem "Rủi ro").

## Đã làm
- **Cherry-pick 97be600** (lớp dữ liệu stats của nhánh cũ) rồi **sửa theo D-042** (commit riêng):
  - `lib/src/data/stats.dart`: `DailyFlow` giữ `MoneyBag` thu/chi theo **tiền tệ gốc**; cột (`flowBuckets`),
    tháng (`monthlyFlows`/`OverviewData.of`), ngày chi nhiều nhất, điểm số dư đều **cộng gốc rồi quy đổi một
    lần** qua `MoneyConvert` (`convertWith(service)`); `BalanceLedger` giữ túi tiền theo ngày. "Thu − chi
    tháng" cộng gốc (thu − chi từng tiền tệ) rồi quy một lần. `topExpenseCategories` nhận `PeriodSummary`
    (đã cộng chính xác sẵn).
  - `lib/src/data/stats_repository.dart`: SQL gom `GROUP BY date, currency` theo `COALESCE(original_amount, amount)`;
    sổ số dư tính chuyển tiền như `balanceBags` (trừ ở tiền gửi, cộng `to_original_amount` ở tiền nhận) — khác
    tiền tệ vẫn khớp số dư từng tài khoản.
- **F-35 Tổng quan** `/overview` — `features/overview/overview_screen.dart`, `overview_providers.dart`:
  ‹ tháng › riêng (theo Ngày bắt đầu tháng, không quá tháng hiện tại, vuốt được); Tổng số dư (mọi tài khoản kể cả
  ẩn, = tổng `accountBalanceBagsProvider` quy một lần, **không gồm nợ**); ô "Thu − chi tháng"; ô "Ngân sách còn
  lại" (âm → "Vượt X" icon + chữ; chưa đặt → nút "Đặt ngân sách" mở `showBudgetDialog`); **thẻ "Nợ"**
  ("Người khác nợ bạn X" / "Bạn nợ Y", chạm → `/debts`); ghi chú hàng đợi (nếu có); cột thu–chi 6 tháng; "So
  với tháng trước" (chi & thu, mũi tên + chữ, "—" khi tháng trước 0) + câu "Chi tăng 25% so với tháng 10".
- **Thẻ Nợ** lấy số qua MỘT provider `debtTotalsProvider` ở `features/overview/debt_totals.dart`
  (`debtBagsOf` cộng số còn lại các khoản chưa xong theo tiền tệ gốc, mỗi chiều quy một lần). **C1 chỉ cần
  sửa file này** để đổi sang gốc + lãi tới hôm nay.
- **F-36 Thống kê** `/stats` — `features/stats/stats_screen.dart`, `stats_providers.dart`: dùng **chung kỳ
  (`periodProvider`) và bộ lọc tài khoản (`accountFilterProvider`) với màn chính** (đổi ở đây là đổi ở màn
  chính); cột theo AC-109; 5 danh mục chi nhiều nhất (số + % + thanh); ngày chi nhiều nhất (ẩn ở kỳ Ngày);
  đường lịch sử tổng số dư (mọi tài khoản, không theo bộ lọc, bỏ cột sau hôm nay). Kỳ trống → trạng thái trống.
- **F-38 Lịch** `/calendar` — `features/calendar/calendar_screen.dart`, `calendar_grid.dart`,
  `calendar_providers.dart`: lưới tháng lịch theo Ngày đầu tuần + bộ lọc tài khoản; ô: số ngày, chi rút gọn
  (`compactAmount`: "250k", "1,2tr"), chấm xanh nếu có thu; đọc "6 tháng 11, chi 1.200.000 ₫, có thu";
  ‹ › / vuốt đổi tháng; chạm ngày → "Chi X · Thu Y" + danh sách khoản (chạm sửa, vuốt xoá, Hoàn tác).
- Widget chung `features/stats/stats_widgets.dart`: thẻ, đầu tháng, đầu kỳ (bản sao của `_PeriodHeader` màn
  chính), nút lọc tài khoản, `FlowBarChart`/`BalanceLineChart` (fl_chart — đã có sẵn trong pubspec, không thêm
  dependency) với **bảng thay thế**: nhãn ngữ nghĩa đọc từng mục + nút "Xem dạng bảng" hiện bảng chữ thật.
- Lối vào tạm: nút `insights` trên thanh màn chính → menu Tổng quan / Thống kê / Lịch (`home_screen.dart`, chỉ
  thêm vào `actions`). Route mới trong `app.dart`.
- `.arb`: 44 khoá mới, một khối liền cuối file, tiền tố `overview*`/`stats*`/`calendar*`; file sinh cập nhật.
- `test/features/g6_accessibility_test.dart`: thêm `/overview`, `/stats`, `/calendar` vào `_routes`.

## Kiểm thế nào
- `flutter analyze`: sạch.
- `test/data/stats_test.dart`: 38 test xanh — gồm 6 test D-042 mới (3 × 10.000 ₫ → 116 cent không phải 117;
  nhiều tiền tệ trong một ngày; thiếu tỷ giá bỏ khỏi tổng; Tổng quan net quy một lần; **AC-108** 4.000.000 →
  5.000.000 ₫ = tăng 25%, thu "—"; sổ số dư với chuyển tiền VND→USD + tài khoản ẩn khớp `balanceBags`).
- `test/features/f35_f36_f38_overview_stats_calendar_test.dart`: 7 widget test xanh (câu "Chi tăng 25% so
  với tháng 10", Vượt, Tổng số dư 0 ₫, nhãn bảng thay thế, nút Xem dạng bảng, "—"; tháng trống + "Đặt ngân
  sách" + không quá tháng hiện tại; thẻ Nợ 2.000.000/500.000, bỏ khoản đã xong, chạm mở Khoản nợ; menu màn
  chính; Thống kê đủ 4 thẻ + đúng 5 danh mục; kỳ trống; Lịch "250k"/"1,2tr", nhãn đọc, chạm ngày, vuốt xoá +
  Hoàn tác, đổi tháng).
- `test/features/g6_accessibility_test.dart`: xanh cả 4 tổ hợp sáng/tối × chữ 100/200 % với 3 màn mới (đã sửa
  một chỗ tràn 4,5 px ở dòng danh mục: giờ là "tên · số tiền" / "thanh · %").
- Toàn bộ `flutter test`: 924 xanh, 1 bỏ qua (có sẵn), 1 đỏ — test Thống kê của tôi (thẻ bị đẩy khỏi màn sau
  khi sửa chỗ tràn); đã sắp lại dòng danh mục + cho test cuộn, chạy lại file đó + g6: 15/15 xanh. Không còn
  test cũ nào bị ảnh hưởng bởi nút mới trên thanh màn chính.
- Không chạy trên máy thật (brief cấm adb). AC-110 "≤ 1 giây với 10.000 khoản" là [M], chưa đo.

## Việc dở / rủi ro
- **Worktree cũ chiếm chỗ:** `D:/Mobile App/.claude/worktrees/a002-biometric-m5-6e8c61/apps/A002-vigon` là
  worktree app nhánh `a002-biometric-m5` với **việc vân tay CHƯA COMMIT từ 2026-11-06** (biometric_service.dart,
  biometric_section.dart, f41_biometric_test.dart, sửa lock/*, Info.plist, MainActivity.kt…). Tôi không đụng.
  Có thể có ích cho C4 (vân tay) — phiên điều phối quyết giữ/bỏ.
- Worktree cũ `a002-overview-stats-4eb9ea` cũng có UI Tổng quan/Thống kê chưa commit (bản nháp trước D-042);
  tôi chỉ đọc để tham khảo, bản mới thay thế nó → có thể dọn.
- "Dùng lại lưới `range_calendar.dart`": `_MonthGrid` là private và `home/range_calendar.dart` ngoài phạm vi
  sửa, nên `calendar_grid.dart` **dựng lại cùng thuật toán** (hàng thứ hẹp, ô trống đầu/cuối). Đề xuất sau:
  tách lưới dùng chung có `cellBuilder` (một việc nhỏ, đụng `range_calendar.dart`).
- Thống kê dùng chung kỳ/bộ lọc với màn chính (đúng chữ AC-109 "cùng chọn kỳ và bộ lọc tài khoản"); nếu
  mockup v5 muốn kỳ riêng thì đổi `statsFlowProvider`/`StatsPeriodHeader`.
- Ô "Ngân sách còn lại" chỉ có "Vượt X"; **"Sắp vượt" (AC-111) là việc của C4** — C4 cần sửa `_Body` trong
  `overview_screen.dart` (chỗ `budgetTile`).
- Hạn mức tháng lấy `budgetProvider` (số đã quy về Tiền tệ chính) như thanh ngân sách màn chính.
- Nhãn tháng ngắn tiếng Việt "T6" và "so với tháng 10" (viết thường) xử lý trong code theo `languageCode`
  (intl vi cho "Tháng 6"/"Tháng 10").
- Top danh mục lấy từ `periodSummaryProvider` (nạp mọi khoản của kỳ như màn chính); kỳ "Tất cả" 10.000 khoản
  cần đo trên máy.

## Chỗ có thể xung đột khi gộp
- `lib/l10n/app_en.arb`, `app_vi.arb` + 3 file `app_localizations*.dart`: khối mới ở **cuối file** — các nhánh
  khác cũng thêm cuối file → xung đột chắc chắn nhưng dễ gỡ (giữ cả hai khối, chạy lại `flutter gen-l10n`).
  File sinh còn đổi một dòng định dạng `homeEmptyBody` (do trình sinh).
- `lib/src/app.dart`: thêm 3 import + 3 `GoRoute` sau route `savings`.
- `lib/src/features/home/home_screen.dart`: thêm `PopupMenuButton` trong `AppBar.actions` trước nút Các khoản.
- `test/features/g6_accessibility_test.dart`: thêm 3 dòng cuối `_routes`.
- `lib/src/data/stats.dart`, `stats_repository.dart`, `test/data/stats_test.dart`: nhánh cũ
  `feature/overview-stats-calendar` có bản trước — đừng gộp nhánh cũ đó nữa.

## Đề xuất cải tiến xưởng
- Brief bảo "tạo worktree vào `$(pwd)/apps/<app>`" nhưng worktree xưởng được **dùng lại tên cũ**
  (`a002-biometric-m5-6e8c61`) nên chỗ đó đã có worktree app cũ có việc chưa commit. Mẫu brief nên dặn: "nếu
  `apps/<app>` đã có → tạo `apps/<app>-<việc>` và báo", và phiên điều phối nên dọn/kiểm worktree app mồ côi
  trước đợt mới (`git worktree list` + `git status` từng cái).
- Nên có helper test `scrollableOf(Screen)` trong `test/helpers.dart` (ListView lười + `goTo` giữ màn chính bên
  dưới làm `find.byType(Scrollable).last` sai).
- Quy ước "khoá .arb một khối liền cuối file theo tiền tố" giúp gộp nhanh — nên ghi vào PLAYBOOK cho mọi đợt
  song song.
