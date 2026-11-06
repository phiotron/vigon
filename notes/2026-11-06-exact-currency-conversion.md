# [A002-vigon] Quy đổi tiền tệ giữ số chính xác 6 lẻ (D-029) — 2026-11-06

Phiên con của phiên điều phối A002-vigon. Nhánh `dev`, **chưa push**.

## Đã làm
Sửa hai lỗi người dùng báo khi đổi tiền tệ (D-025): (1) VND→USD→VND không về số cũ (50.000 ₫ → 1,93 $ → 50.130 ₫);
(2) số nhỏ bị đội lên (100 ₫ ≈ 0,00385 $ thành 0,01 $). Theo đúng thiết kế đã duyệt:

1. **Schema 3** (`lib/src/data/database.dart` + `database.g.dart`): cột int nullable `amountMicro` (Entries, RecurringRules),
   `initialBalanceMicro` (Accounts), `budgetMicro` (Categories); khoá settings `budgetMicro` (ngân sách tháng).
   CHECK `amount > 0` → `amount >= 0` cho Entries/RecurringRules, dựng lại bảng bằng `TableMigration` (drift tự tắt/bật
   khoá ngoại; sau migration chạy `PRAGMA foreign_key_check`, lỗi thì ném).
2. **Tự kiểm** (`exactMicro` trong `lib/src/data/currency.dart`): micro chỉ dùng khi half-up(micro → số lẻ hiện tại) == `amount`;
   không thì dùng `amount × 10^(6−d)`. Không trigger, mọi đường ghi cũ giữ nguyên.
3. **`convertCurrency`**: exactMicro × tỉ giá (BigInt, phân số) → half-up về micro → half-up về đơn vị nhỏ nhất (`convertExact`).
   Khoản + khoản định kỳ được 0; ngân sách tháng + hạn mức danh mục tối thiểu 1 (khi nâng lên 1 thì micro = null); số dư ban đầu có dấu
   (tài khoản số dư 0 nhưng có micro vẫn được đổi). Micro = null khi bằng đúng số làm tròn. Vẫn kiểm 10^12, một giao dịch, tính hết rồi mới ghi.
4. **Tỉ giá chéo phân số** (`lib/src/data/exchange_rate.dart`): `ExchangeRate operator /` (rút gọn gcd); `RateTable.rate` =
   `fromDouble(b) / fromDouble(a)` → A→B và B→A cùng bảng là nghịch đảo đúng. `toStorage` ghi `"tử/mẫu"` khi mẫu không phải luỹ thừa 10
   (trước đây rơi về số thực 12 chữ số → tỉ giá tự nhập đảo chiều đọc lại bị lệch); thêm `ExchangeRate.fromStorage` đọc cả hai dạng,
   `readManualRate` dùng nó (giá trị cũ dạng thập phân vẫn đọc được).
5. **Màn sửa**: `entry_editor_screen.dart`, `transfer_screen.dart`, và cả `recurring/rule_sheet.dart` (khoản định kỳ cũng có thể 0):
   số đang 0 mở ra giữ nguyên (gõ ra 0) thì lưu được; khoản mới/số khác gõ 0 vẫn báo "Số tiền phải lớn hơn 0" (AC-05).
6. **Sao lưu `.vigon`**: drift `toJson/fromJson` tự mang cột micro, khoá `budgetMicro` đi theo bảng settings → không phải đổi định dạng;
   file schema 1/2 thiếu cột thì null. Chỉ sửa chú thích trong `backup.dart`. CSV giữ số đã làm tròn.
7. `summary.dart` không đổi (cộng `amount`).

Thêm ngoài brief (nhỏ, cùng mục đích — phiên điều phối xem lại):
- `recurring_repository.dart`: khoản định kỳ sinh ra (và khoản đầu khi tạo chuỗi) chép `amountMicro` của chuỗi → khoản sinh sau khi đổi
  tiền tệ đổi lại vẫn đúng (vd chuỗi 3.000.000 ₫ → 115,50 $ → sinh khoản → đổi lại ra 3.000.000 ₫, không phải 2.999.997 ₫).
- `features/settings/currency_conversion.dart`: ví dụ "trước → sau" trong hộp xác nhận tính từ số chính xác như khi đổi thật, bỏ `max(1, …)`;
  `conversionExampleAmount` trả `({minor, exact})`.

Tài liệu (trong repo app): `docs/DECISIONS.md` **D-029**; `docs/SPEC.md` AC-21 viết lại câu làm tròn, AC-05 thêm ngoại lệ khoản 0 do quy đổi,
**AC-73** mới; `CONTEXT.md` sửa định nghĩa Currency (bỏ câu sai "chỉ đổi ký hiệu"), Amount, thêm **Exact amount**; `docs/TESTING.md`
dòng truy vết AC-21/AC-73 + sửa kỳ vọng thử máy Q-2/Q-3 (số rất nhỏ hiện 0,00; Q-3 cùng bảng tỉ giá phải về ĐÚNG số cũ).
Không sửa `APP.md` hay file cấp xưởng.

## Commit (`dev`, chưa push)
- `26ce32d` schema v3 with exact *Micro amount columns, allow amount 0
- `3776b72` convert currency from exact 6-decimal amounts, exact cross rates
- `d500d65` unchanged zero amount can be saved in editors
- `132515d` tests for v3 migration and backup with exact amounts
- commit tài liệu + báo cáo này (`docs: D-029 …`, ngay sau `132515d`)

## Kiểm tra thế nào
- `flutter analyze`: không lỗi.
- Test mới/sửa: `test/data/currency_conversion_test.dart` (50.000 ₫→USD→₫ = 50.000 và trung gian 1,93 $; 100 ₫→USD = 0 cent, micro 3850, về ₫ = 100;
  chuỗi VND→USD→KWD→JPY→VND gồm khoản, khoản định kỳ, số dư âm, hạn mức, ngân sách; ngẫu nhiên seed 20261106: 4 tiền gốc × 250 số = 1.000 số,
  mỗi lần một bảng tỉ giá ngẫu nhiên thực tế, đổi qua lại 10 lần ra đúng gốc; sửa tay sau khi đổi bỏ micro; khoản định kỳ mang micro;
  vượt giới hạn không đổi gì; ngân sách/hạn mức tối thiểu 1; `RateTable.rate` hai chiều nghịch đảo đúng + vòng tỉ giá chéo = 1; cache phân số),
  `test/data/exact_amount_storage_test.dart` (migration v2→v3 dữ liệu còn nguyên + khoá ngoại; CHECK cho phép 0, chặn âm; sao lưu/khôi phục có micro
  rồi đổi lại ra gốc; đọc file schema 2; khoản 0 trong file), `test/features/zero_amount_edit_test.dart` (3 widget test).
  Sửa kỳ vọng cũ: `database_test` (0 nay được), `category_budget_test` (schemaVersion 2 → `currentSchemaVersion`), test "số > 0 thành 1" → "khoản thành 0, ngân sách tối thiểu 1".
- `flutter test` toàn bộ: **645/645 đạt** (trước phiên: 625; +20 test), 2026-11-06, `flutter test`.

## Lưu ý cho người dùng / phiên điều phối
- **Đổi đi rồi đổi lại vào NGÀY KHÁC (bảng tỉ giá khác) thì số khác — đó là biến động tỉ giá thật, không phải sai số.** Bảo đảm "về đúng số cũ"
  chỉ khi hai lần đổi dùng cùng một bảng tỉ giá (cùng ngày cập nhật của nguồn, hoặc tỉ giá tự nhập đảo chiều).
- Giới hạn của 6 lẻ (người dùng đã chọn micro = 10⁻⁶): đúng khi 1 đơn vị nhỏ nhất của tiền cũ đáng ≳ 1 micro của tiền mới — mọi cặp phổ biến
  (VND, USD, EUR, GBP, JPY, KWD… đã thử ngẫu nhiên). Cặp cực lệch giá như IDR/IRR (2 lẻ, giá rất thấp) ↔ KWD/BHD (3 lẻ) có thể lệch 0,01 khi
  đổi lại. Nếu cần tuyệt đối mọi cặp: phải lưu số chính xác theo thang khác (vd micro của đơn vị nhỏ nhất) — quyết định mới, chưa làm.
- Khoản 0 giờ có thể xuất hiện (Các khoản hiện "0,00 US$"); biểu đồ/tổng cộng số đã làm tròn như cũ. Chưa kiểm giao diện trên máy (không dùng adb theo brief).
- Dữ liệu DB cũ trên máy người dùng sẽ chạy migration 2→3 khi mở bản mới (đã test trên bản sao schema 2 trong bộ nhớ, chưa chạy trên máy thật).
- File `.vigon` xuất từ bản này có `schemaVersion: 3` → bản app cũ (schema 2) sẽ từ chối khôi phục (như luật hiện có).

## Việc dở
- Thử máy Q-2/Q-3 (`docs/TESTING.md`) với bản mới: VND→USD→VND cùng ngày phải về đúng số cũ.
- Phiên điều phối: cập nhật `APP.md` (D-029, số test), push `dev` khi người dùng bảo.

## Đề xuất cải tiến xưởng
- Tiền tệ/quy đổi: lưu thêm số chính xác ẩn + tự kiểm (không trigger) là mẫu tái dùng được cho app khác có quy đổi đơn vị.
- Trong Git Bash, heredoc dài có dấu `'`/`$` lồng trong chuỗi Python dễ hỏng → ghi script ra scratchpad rồi chạy.
