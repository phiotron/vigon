# [A002-vigon] D2 · Danh mục, tài khoản, định kỳ · 2026-11-05

Phiên con D2 của phiên điều phối #2 (chạy song song D1/D3/D4). Lượt 1 hết hạn mức sau phần danh mục; lượt 2 làm tiếp
tài khoản, chuyển tiền, định kỳ.

## Đã làm / file đã đổi (theo frame)

**Commit:** `121e500` danh mục · `289e667` tài khoản + chuyển tiền · `de59dae` định kỳ · commit notes này.

| Frame | Đã làm | File |
|---|---|---|
| SCR-16 `16_categories~edit__budget-set/-error`, P2 6.2 | Ô hạn mức chuyển xuống **sau Màu**, có ký hiệu tiền tệ (suffix), lỗi thay dòng gợi ý (`errorMaxLines: 3`); footer ghim ngoài vùng cuộn, trên bàn phím: vạch trên + "Xóa danh mục" (🗑, chữ `error`) + Lưu chia đều; ≥ 130% xếp dọc | `features/categories/categories_screen.dart` |
| P2 6.3 | Hộp chọn danh mục nhận khi xóa: `AlertDialog` → `VgDialog` (icon 🗑, thân cuộn ở 200%, nút Hủy chuẩn); xóa danh mục chưa dùng vẫn qua `showConfirmDialog` | như trên |
| SCR-17 `17_accounts__hidden/-open`, P2 6.4 | Vạch ngăn; tiêu đề mục 56 dp `archivedAccountsCount(n)` (icon 👁‍🗨 + ▾/▴ màu chữ phụ, Semantics `button` + `expanded`); mặc định thu; thu/mở 200 ms `VgMotion.standard` (tắt khi giảm chuyển động); hàng ẩn ≥ 72 dp, tên màu chữ phụ 1 dòng …, số dư body-sm; nút "Hiện lại" (👁) đọc "Hiện lại: tên"; **chạm hàng mở Sửa** (A10). Danh sách: số dư đậm 600, tên 1 dòng … (200%: số dư xuống phụ đề như cũ); FAB có chữ "Thêm tài khoản" | `features/accounts/account_manage.dart`, `accounts_screen.dart` |
| SCR-18 `18_accounts~edit__used/unused/last-visible/text-200`, P2 6.5 | Bảng sửa: ô Tên, Số dư ban đầu (suffix ₫, gợi ý); vùng quản lý sau vạch: đang ẩn → "Hiện lại" thay "Ẩn"; chưa dùng → Ẩn (viền) + Xóa (chữ đỏ); đã dùng → Ẩn + `VgHint(accountInUseHint)`; hiện cuối cùng → chỉ `VgHint(accountLastOneHint)` (A11). Lưu = nút lớn cả hàng ghim đáy (không vạch). **Sửa lỗi:** trước đây mở tài khoản ĐANG ẨN khi chỉ còn 1 tài khoản hiện thì hiện nhầm "Phải còn ít nhất một tài khoản" | như trên |
| `18_accounts~delete__default` | Hộp xóa tài khoản: `VgDialog` chỉ tiêu đề `deleteAccountConfirm(name)`, icon 🗑 `error`, Hủy + Xóa nền `error` | `account_manage.dart` |
| P2 6.6–6.7 Transfer | Bàn phím số + Lưu bọc `SnackBarClearance` (snackbar Hoàn tác nằm trên bàn phím); ô 56 đã có từ theme D0 | `transfer_screen.dart` |
| SCR-21 `21_recurring~edit__running/frequency-changed/one-account/error/text-200`, P2 7.2 | Hộp thoại 7.2 → **bảng toàn màn** `showRuleSheet` (`rule_dialog.dart` xóa, thay bằng `rule_sheet.dart`): thanh ✕ (tooltip "Hủy") + "Khoản định kỳ"; đầu chuỗi chỉ đọc (avatar danh mục 40, tên = ghi chú hoặc tên danh mục, phụ đề "tần suất · ngày tới hạn" / "Đã dừng" + `StatusPill(stop_circle)` khi dừng); Số tiền (suffix, lỗi dưới ô, Lưu vẫn bấm được); Ghi chú + `recurringEditNote`; "Lặp lại" = 4 chip chọn một (nền `secondary-container` + ✓, bo `radius-sm`, vùng chạm 48, Semantics nhóm loại trừ); đổi tần suất → `VgHint(recurringRestartHint(ngày tới hạn kế tiếp theo lịch cũ), icon: restart_alt)` (A12, khớp `RecurringRepository.edit`); ô chọn Danh mục (mở `showCategorySheet`) và Tài khoản (mở `showChoiceSheet`, ẩn khi chỉ 1 tài khoản hiện); footer Hủy (viền) + Lưu, ≥ 130% xếp dọc. Không tự focus ô Số tiền nữa (frame không có bàn phím) | `features/recurring/rule_sheet.dart`, `recurring_screen.dart` |
| P2 7.1 | Không đổi (theo CHANGELOG) | — |

Widget dựng riêng trong feature (vì không được sửa `lib/src/ui/`): `features/categories/sheet_footer.dart`
(`SheetFooter`, `sheetFilledButtonStyle()`, `sheetOutlinedButtonStyle()`); trong `rule_sheet.dart`: `_FrequencyChip`,
`_PickerField`.

Test đã sửa: `f14_accounts_test.dart` (tiêu đề có đếm; thêm bước chạm hàng ẩn mở Sửa có "Hiện lại"), `f16_f17_test.dart`
(F-16 dùng chip `rule-frequency-weekly` + kiểm gợi ý A12; ô chọn giữ key `rule-category`/`rule-account`),
`g6_flows_test.dart` (1 dòng `AlertDialog` → `VgDialog` + import). Test mới `hifi_d2_rule_sheet_test.dart` (7 test:
sáng/tối + tap target + tương phản, gợi ý A12 hiện/ẩn, lỗi số tiền + trả kết quả, đã dừng + 1 tài khoản, ✕, 200%).

## Kiểm tra thế nào

```
export PATH="/c/src/flutter/bin:$PATH"
flutter analyze lib/src/features/{categories,accounts,recurring} <các file test trên>   # No issues found
flutter test test/features/f20_category_budget_test.dart test/features/g3_screens_test.dart \
  test/features/plan001_t4_test.dart test/features/g6_flows_test.dart                  # (lượt 1) danh mục/chuyển tiền đạt
flutter test test/features/f14_accounts_test.dart test/features/f16_f17_test.dart \
  test/features/hifi_d2_rule_sheet_test.dart                                           # xem mục "Kết quả test" dưới
```

**Kết quả test (lượt 2, sau khi D3 biên dịch lại được):** 12 file — `f14_accounts`, `f16_f17`, `f20_category_budget`,
`hifi_d2_rule_sheet` (mới), `g3_screens`, `g4_screens`, `g6_flows`, `g6_accessibility`, `app_test`, `review_fixes`,
`plan001_t4`, `plan001_t5` → **58 test đạt**, 0 đỏ. `flutter analyze` 3 thư mục feature + 4 file test: No issues found.
Sửa thêm trong lượt 2: F-16 phải `ensureVisible` ô Tài khoản (bảng toàn màn, ô nằm dưới mép 800 dp); f14 đổi 2 nhãn
`Số dư: -20.000 ₫` → `Số dư: -20.000 ₫, Tháng 11 năm 2026` theo yêu cầu D1 (`BalanceBar` có `periodTitle`).
Chưa chạy toàn bộ `flutter test` (D5 làm).

## Chữ còn thiếu
- Không có key bắt buộc. Semantics nút trên hàng ẩn đang ghép `'${l.unarchiveAccount}: $name'`; nếu muốn chuẩn i18n:
  `unarchiveAccountNamed` — EN "Show again: {name}" · VI "Hiện lại: {name}".

## Component cần sửa / thêm trong `lib/src/ui/`
- **`SheetFooter` + kiểu nút lớn** (`features/categories/sheet_footer.dart`) → nên chuyển vào `ui/` (D3 SCR-13/26/27 và
  D1 có thể cần footer ghim cùng kiểu). Khi chuyển, đổi import ở 3 file của D2.
- **Chip chọn một** (`_FrequencyChip`) và **ô chọn** (`_PickerField`, `.vg-pickrow`) cũng là mẫu chung trong design-system
  (Chips "Choice", TextFields "Picker") — đưa vào `ui/` nếu màn khác dùng.
- `currencySymbol` đang nằm ở `features/settings/budget_dialog.dart` (vùng D3), D2 import 2 chỗ → nên chuyển vào
  `ui/format.dart`.

## Chỗ còn lệch mockup
- **6.1 gợi ý hạn mức trên hàng danh mục: KHÔNG làm** — SPEC AC-54 chỉ đặt thanh hạn mức ở màn Các khoản; §10.1 #6 là mục
  Ideas (D-023 để sau); không có frame/chữ. Điều phối chốt nếu muốn.
- Icon tài khoản: frame dùng ví cho mọi hàng; code giữ Tiền mặt = 💵 `payments` (từ thiết kế cũ, giúp phân biệt).
- SCR-21 tên ở đầu chuỗi: frame "Rent" (ghi chú) — code dùng ghi chú, không có thì tên danh mục; chuỗi chuyển tiền
  hiện "Chuyển tiền" + icon lặp.
- Chưa so ảnh từng pixel (D5 làm); kiểm bố cục/màu bằng test + đọc frame HTML.

## Việc dở / rủi ro
- `289e667` và `de59dae` commit khi `flutter analyze` sạch nhưng lúc đó test không biên dịch được vì D3 đang sửa dở
  `features/settings/`; đã chạy lại sau khi D3 sửa xong — đạt (mục trên).
- `RuleSheet` dùng `showModalBottomSheet(useSafeArea: true)` + chiều cao đầy: trên iPad/landscape sheet rộng tối đa theo
  mặc định Material 3 (640) — chưa thử.
- Thu/mở mục ẩn dùng `AnimatedSize` với con bị bỏ khi thu (để TalkBack/test không thấy hàng ẩn khi đang thu): lúc thu,
  hàng biến mất ngay rồi khung co 200 ms.

## Đề xuất cải tiến xưởng
1. **Phiên component (D0) nên dựng luôn "footer ghim bảng kéo", "chip chọn một", "ô chọn"** khi design-system có — ba phiên
   màn đều cần, cấm sửa `ui/` khiến mỗi phiên dựng bản riêng.
2. **Brief phiên con song song: thêm câu "lỗi biên dịch do phiên khác → commit theo `flutter analyze <thư mục mình>`, chạy
   test sau"** và một cách chạy test không phụ thuộc file phiên khác (test widget độc lập dựng `MaterialApp` + theme như
   `hifi_d2_rule_sheet_test.dart` — vẫn vỡ nếu import chuỗi tới `providers.dart`). Tốt hơn: mỗi phiên chạy trong
   worktree riêng rồi gộp, tránh cả khoá `sqlite3.dll` lẫn lỗi biên dịch chéo.
3. Hạn mức sử dụng hết giữa phiên: commit sau từng phần + notes bàn giao có thiết kế chi tiết giúp lượt sau làm tiếp ngay
   — nên ghi thành quy tắc trong `BRIEF-phien-con.md`.
