# [A002-vigon] C1 lõi sổ — SPEC 3h (F-49..F-52) · 2026-11-11

Nhánh `a002-ledger-core-v5` (từ `dev` `1b1b4ea`). Không merge `dev`, không push.

## Đã làm
| Mục | AC | Chỗ làm chính |
|---|---|---|
| Schema v8 + migration 7→8 (và 1→8) | 177, 163 | `database.dart` |
| `BalanceGuard` + `InsufficientFundsException` | 160, 161 | `data/balance_guard.dart` |
| Tính lãi thuần | 172, 173, 174 | `data/interest.dart` (`DebtInterest`) |
| Debt movement (khoản kiểu `debt`) loại khỏi thu/chi | 169, 170 | `summary.dart`, `entry_search.dart`, `money_sum.dart`, `account_repository.dart` |
| Khoản nợ qua tài khoản + lãi + lần trả tách lãi/gốc | 169–176 | `debt_repository.dart`, `debt_editor.dart`, `debt_detail.dart`, `debt_movement.dart` |
| Công tắc "Cho phép số dư âm", nhãn "Âm", hộp nâng cấp | 162, 163 | `accounts_screen.dart`, `home/ledger_notices.dart`, `applyNegativeUpgrade` |
| Áp BalanceGuard: Nhập khoản (mới/sửa/xoá+Hoàn tác), Chuyển tiền, Góp/Rút, cho vay, lần trả, xoá lần trả | 160, 161 | `entry/ledger_guard.dart` + các màn |
| Khoản định kỳ thiếu tiền → bỏ, thanh "Bỏ qua N…" | 164 | `recurring_repository.generateDue(service:, skipped:)`, `providers.dart` (`skippedOccurrencesProvider`), `ledger_notices.dart` |
| Bù tiền (3 cách, tự xác nhận + Hoàn tác) | 165 | `import_queue/top_up_sheet.dart`, `import_queue_actions.dart` (`shortfallFor`, `undoConfirm`) |
| TK mặc định theo lọc (Nhập khoản, "Từ" của Chuyển tiền, TK khoản nợ) | 166 | `entry_editor_screen.dart`, `transfer_screen.dart`, `debt_editor.dart` |
| Chip tiền tệ Góp/Rút, số nợ, Lần trả; "Điền đủ"/"Trả hết" làm tròn xuống | 167 | `entry/typed_amount.dart` (`TypedAmount`, `convertDown`), `goal_money_sheet.dart`, `debt_detail.dart` |
| Nhắc hạn nợ có lãi: "phải trả khoảng …" | 174 | `deadline_reminders.dart` (`DeadlineItem.estimate`) |
| Sửa lệch 37 ₫ (mục 7) | — | `savings_screen.dart` (`goalWalletPrimary`), `goal_detail.dart` |

## Cách lưu lãi suất
- `debts.interest_rate` = **phần trăm × 100** (12 % → 1200; 1,5 % → 150), `debts.interest_period` = `month|year`, `debts.interest_start` = ngày bắt đầu tính lãi (null = ngày vay). Trống `interest_rate` = không lãi.
- `debt_rate_changes(debt_id, date, rate, period)`: mốc đổi, áp từ `date` (gồm); cùng ngày thì thay mốc cũ. Xoá khoản nợ xoá theo (cascade).
- Lãi suất năm = rate (năm) hoặc rate × 12 (tháng). Tính `DebtInterest.accrued(until)` = Σ gốc còn lại cuối ngày × lãi năm ÷ 365 (phân số BigInt, làm tròn nửa lên một lần). Gốc đổi **từ chính ngày trả** (lần trả 01/12 làm lãi ngày 01/12 tính trên gốc mới) còn "lãi tới ngày trả" không gồm ngày trả.
- Lần trả: `debt_payments.amount/original_amount` = phần **gốc**, `interest` = phần lãi (tiền tệ khoản nợ), `account_id`.

## Debt movement
- `EntryType.debt` (chỉ số 3, thêm cuối enum), `entries.debt_kind` (`lend|borrow|collect|repay`), `entries.debt_id`, `entries.debt_payment_id` (đều `ON DELETE SET NULL` → Orphan debt movement khi xoá khoản nợ).
- Khoản **lãi** của lần trả là `income`/`expense` thường (danh mục `interestIncome`/`loanInterest`) có `debt_id` + `debt_payment_id` → vẫn tính thu/chi; chạm trong Các khoản mở Chi tiết khoản nợ, không vuốt xoá (xoá ở Chi tiết).
- Khoản ghi theo **tiền tệ tài khoản** (số quy đổi lúc lưu); khoản nợ/lần trả giữ số gốc theo tiền tệ khoản nợ.
- Hai danh mục mặc định mới: `loanInterest` (chi), `interestIncome` (thu) — `seed.dart`, `addInterestCategories` (cho DB cũ qua migration và khôi phục file < v8); `interestCategoryId()` tạo lại nếu người dùng xoá.

## Migration
- `from < 8`: chỉ **thêm cột/bảng còn thiếu** (kiểm `PRAGMA table_info`) — chạy lại an toàn, và đúng cho chuỗi 1→8 (bước `from < 3` dựng lại `entries` theo định nghĩa hiện tại nên `newColumns` đã thêm `debtKind/debtId/debtPaymentId`; `debts`/`debt_payments` tạo ở bước 4 đã đủ cột).
- Tài khoản đang âm → cờ `negativeCheckPending`; `startupProvider` gọi `applyNegativeUpgrade` (cần tỷ giá để tính số dư theo tiền tệ tài khoản) → bật `allow_negative` + ghi `negativeAllowedNotice` (danh sách id) → `LedgerNotices` ở màn chính hiện hộp một lần rồi xoá. Cả hai khoá là cài đặt theo máy (`deviceOnlySettingKeys`).
- Sao lưu: thêm bảng `debtRateChanges` (`since: 8`), mặc định `allowNegative=false`, `interest=0`; khôi phục file schema ≤ 7 thêm danh mục lãi + cờ nâng cấp. `entries` được chèn **sau** `debts`/`debtPayments` (khoá ngoại). Test: `test/data/ledger_core_test.dart`.

## Kiểm thế nào
- `test/data/interest_test.dart` (98.630 / 49.315 / 10.295.890 ₫, đổi lãi suất, ân hạn, năm nhuận /365) · `test/data/ledger_core_test.dart` (guard, nợ qua tài khoản, lãi → thu/chi, xoá nợ giữ khoản, định kỳ bỏ, migration 7→8, sao lưu v8/v7) · `test/features/f49_ledger_test.dart` (màn: AC-160/161/162/163/164/165/166/167/169/174/175) · `g6_accessibility_test.dart` (nhóm "đợt 5").
- Test cũ đổi: `helpers.dart` `pumpApp(allowNegative: true)` mặc định (test cũ ghi chi vào Tiền mặt 0 ₫); test của luật truyền `allowNegative: false`. `f34_debts_test`, `f32_import_queue_test`, test migration cũ (đếm danh mục +2) sửa theo luật mới.
- Ba test **đã đỏ sẵn trên `dev`** (kiểm trên `1b1b4ea`): `app_test` "đổi giao diện tối", `auto_backup_schedule_test` (SCHEDULE_EXACT_ALARM), `widget_review_test` lỗi 1 (SCHEDULE_EXACT_ALARM) — không phải do C1.

## Lệch 37 ₫ (mục 7)
Nguyên nhân thật: dòng chính "Đã có …" của thẻ mục tiêu quy `balance` đã **làm tròn theo tiền tệ mục tiêu** (cent) sang Tiền tệ chính; hero cộng bag gốc rồi quy **một lần** → ví có khoản lẫn tiền tệ (hoặc tiền tệ ví ≠ tiền tệ mục tiêu) lệch tới nửa cent×tỷ giá ≈ vài chục ₫. Sửa: thẻ và Chi tiết dùng `goalWalletPrimary` (quy một lần từ bag) làm `primaryAmount`. Hero **có** cộng cả ví mục tiêu "Đã xong" (ví vẫn giữ tiền, thẻ Đã xong thu gọn) — đúng thiết kế (AC-148), không đổi; nếu lệch còn do mục này thì là thiết kế, không phải lỗi.

## Tên provider cho phiên gộp (C2)
`debtRemainingByDirectionProvider` (`features/debts/debts_providers.dart`): `Map<DebtDirection, MoneyBag>` "Còn lại" (gốc + lãi tới hôm nay) theo tiền tệ khoản nợ. C2 có `debtTotalsProvider` riêng — khi gộp nối thẻ Nợ của Tổng quan sang provider này (hoặc bảo đảm cùng dùng `DebtView.remaining()`).
Helper khác C2/C3 có thể dùng: `DebtView.principalLeft / unpaidInterest / remaining() / dueEstimate() / hasInterest`, `interestRateLabel(context, rate, period)` (`debt_editor.dart`), `isDebtInflow(entry)` + `EntryType.debt` (mọi chỗ `switch (EntryType)` phải xử lý `debt`).

## Việc dở / rủi ro
- **AC-176 Excel** (cột Lãi suất / Gốc còn lại / Lãi tới hôm nay ở sheet "Khoản nợ") thuộc phiên Excel/PDF (C3): C1 chỉ thêm `CsvFormat.debt` + `csvTypeDebt` ("Khoản nợ") cho CSV cũ. Khi C3 xuất Excel/PDF phải xử lý `EntryType.debt` (không phải thu/chi) và lấy lãi từ `DebtView`.
- Thống kê/Lịch (C2) và Cảnh báo ngân sách (C4): mọi tổng đi qua `PeriodSummary.of` đã loại `debt`; chỗ nào tự `select(entries)` rồi lọc `type != transfer` phải thêm `debt` (đã kiểm `summary.dart`, `entry_search.dart`, `money_sum.dart`, `rates_screen`, `goal_detail`).
- "Bù tiền" mới có cho Lưu vào danh mục / Chuyển sang TK / Sửa trước khi lưu. Cách 1–2 mở màn Nhập khoản/Chuyển tiền (`/entry/new?type=income&account=&amount=&currency=`, `/transfer?to=`) rồi quay lại bảng kiểm lại; cách 3 mở bảng sửa tài khoản. Chỉ test cách 3 bằng widget test.
- Số thiếu của "Bù tiền" và thông báo "… chỉ còn …" theo tiền tệ **tài khoản** (hiện Tiền tệ chính trên, số gốc dưới khi khác).
- Khoản nợ ghi nhớ cũ: lần trả mới cho chọn tài khoản ("Không qua tài khoản" còn); tài khoản của khoản nợ cũ không gán lại được.
- Chưa có mockup v5: dùng thành phần v3 (chip, `VgDialog`, `SheetHeader`). Đổi màu tiêu đề/nút "Sửa khoản nợ", "Đổi lãi suất", "Các lần trả" sang `onSurface` vì `primary` trên nền bảng chỉ 4,34:1 (test trợ năng).
- Lãi suất bị chặn 0 < r ≤ 100 theo SPEC; chưa có cảnh báo lãi suất vượt trần pháp lý (ngoài phạm vi).

## Chỗ dễ xung đột khi gộp
- `lib/l10n/app_*.arb` + `app_localizations*.dart` (sinh): C1 thêm **một khối liền cuối file** (`ledger…`, `topUp…`, `debt…`, `category…`, `csvTypeDebt`). Gộp: giữ khối của mọi bên rồi `flutter gen-l10n`.
- `lib/src/app.dart`: chỉ thêm query `account/amount/currency` cho `/entry/new`.
- `lib/src/data/backup.dart`: thêm bảng `debtRateChanges`, `fileSchema`, mặc định, `negative*` vào `deviceOnlySettingKeys`, `CsvFormat.debt`; `entries` chèn sau nợ. C3 (Excel) và C4 (cài đặt sinh trắc/ngưỡng) cũng có thể chạm đây.
- `lib/src/features/entries/entries_screen.dart` + `entry_search.dart` (màn): nhóm "Khoản nợ" mới, `confirmDismiss`, `openEntry`; C3 (Lọc) sửa cùng chỗ.
- `lib/src/features/settings/settings_screen.dart`: **không sửa**. `lib/src/providers.dart`: `startupProvider` (+`applyNegativeUpgrade`, `generateRecurring*`), `skippedOccurrencesProvider`.
- `database.dart`/`database.g.dart`: nếu phiên khác cũng đổi schema thì **phải** gộp thành một v8 (không v9 song song); `database.g.dart` sinh lại bằng `dart run build_runner build --delete-conflicting-outputs`.
- `test/helpers.dart`: `pumpApp(allowNegative: …)`.

## Kịch bản thử máy đề xuất (Galaxy A13, bản có dữ liệu thật sau nâng cấp)
1. Mở app sau nâng cấp: hiện hộp "Đã cho phép số dư âm cho: …" đúng tài khoản đang âm, chỉ một lần; màn Tài khoản có nhãn "Âm".
2. Tài khoản Trip 500.000 ₫ (công tắc tắt): chi 700.000 → "Trip chỉ còn 500.000 ₫"; chi 500.000 lưu được. Xoá khoản thu đã chi hết → "Không xoá được".
3. Lọc Trip ở màn chính → bấm −, +, icon danh mục, "Chuyển tiền": tài khoản Trip/"Từ" = Trip.
4. Tiết kiệm: ví USD, Tiền tệ chính VND, góp 500.000 ₫ từ Tiền mặt → lưu, hai dòng "Vào ví · Trừ từ"; "Điền đủ" không vượt.
5. Khoản nợ: cho vay An 5.000.000 từ Techcombank, lãi 12 %/năm → số dư Techcombank giảm, Các khoản có "Cho vay · An", Tổng chi không đổi; Chi tiết: "Gốc … · Lãi tới hôm nay …"; thu nợ có lãi → lãi thành khoản thu "Tiền lãi"; Đổi lãi suất; xoá khoản nợ → "Khoản nợ đã xoá" còn trong sổ.
6. Định kỳ tới hạn với tài khoản hết tiền → thanh "Bỏ qua 1 khoản định kỳ…" đóng được.
7. Email MB thiếu tiền → "Bù tiền", bù bằng cách 1/2/3 → mục tự lưu + Hoàn tác.
8. Sao lưu → khôi phục (cả file cũ ≤ v7): nợ/lãi/mốc lãi/công tắc âm còn nguyên.
