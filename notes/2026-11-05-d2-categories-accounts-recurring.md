# [A002-vigon] D2 · Danh mục, tài khoản, định kỳ · 2026-11-05 — DỞ (hết hạn mức sử dụng)

## Đã làm
- SCR-16 / 6.2: ô hạn mức chuyển xuống sau Màu, thêm ký hiệu tiền tệ (suffix), lỗi thay dòng gợi ý; footer ghim
  (`SheetFooter`: vạch trên, Xóa danh mục có icon 🗑 + Lưu chia đều, ≥130% xếp dọc), nằm trên bàn phím.
- 6.3: hộp chọn danh mục nhận khi xóa → `VgDialog` (icon xóa, thân cuộn ở 200%). Test `g6_flows_test` đổi
  `find.byType(AlertDialog)` → `VgDialog` (1 dòng + import).
- File mới `lib/src/features/categories/sheet_footer.dart` (`SheetFooter`, `sheetFilledButtonStyle`,
  `sheetOutlinedButtonStyle`) — **nên chuyển vào `lib/src/ui/`** (D2/D3 đều cần footer ghim).

## Kiểm tra
`flutter analyze lib/src/features/categories` sạch. `flutter test f20_category_budget_test g3_screens_test plan001_t4_test
g6_flows_test`: test danh mục/chuyển tiền đạt; 3 test đỏ của g6 (kỳ Tuần/Năm, Khoảng tùy chọn, lọc tài khoản ở
màn chính) thuộc màn chính/bảng kỳ — vùng D1 đang sửa, không do D2.

## Chưa làm (phiên sau làm tiếp — thiết kế đã rà xong, xem chi tiết dưới)
- 6.1: KHÔNG thêm gợi ý hạn mức trên hàng — SPEC AC-54 chỉ nói màn Các khoản; §10.1 #6 là Ideas (D-023 để sau). Điều phối chốt.
- SCR-17 (`account_manage.dart` `ArchivedAccountsSection`): vạch ngăn; tiêu đề 56 dp `l.archivedAccountsCount(n)`
  (icon visibility_off + expand_more/less màu chữ phụ, Semantics button + expanded); thu/mở 200 ms (`VgMotion.medium`,
  tắt khi `VgMotion.reduced`); hàng ẩn 72 dp, tên `onSurfaceVariant` 1 dòng …, số dư body-sm; nút
  `TextButton.icon(visibility, l.unarchiveAccount)` Semantics "Hiện lại: tên"; **chạm hàng mở Sửa** (A10), không hiện lại.
  Danh sách: số dư weight 600; FAB → `FloatingActionButton.extended` "Thêm tài khoản". Frame dùng icon ví cho mọi tài khoản (code: Tiền mặt = payments — giữ, ghi lệch).
  f14 test phải đổi `find.text('Tài khoản đã ẩn')` → `'Tài khoản đã ẩn (1)'`, và "Hiện lại" giờ không còn ở trong bảng sửa nếu chạm hàng.
- SCR-18: vùng quản lý sau vạch: tài khoản ẩn → nút "Hiện lại" thay "Ẩn tài khoản"; đã dùng → Ẩn + `VgHint(accountInUseHint)`;
  chưa dùng → Ẩn (outlined) + Xóa (chữ đỏ); hiện cuối cùng → chỉ `VgHint(accountLastOneHint)` (**sửa lỗi**: điều kiện
  `visible.length <= 1` phải thêm `!account.archived`). Lưu = nút lớn cả hàng ở đáy (`SheetFooter(border: false)`).
  Hộp xóa: `VgDialog(title: deleteAccountConfirm(name), icon: delete, không body, nút Xóa dangerButtonStyle)`.
- 6.6–6.7 Transfer: bọc `Keypad` bằng `SnackBarClearance`.
- SCR-21: thay `rule_dialog.dart` bằng sheet toàn màn (`showModalBottomSheet(isScrollControlled, useSafeArea)`): thanh ✕
  (tooltip Hủy) + "Khoản định kỳ"; đầu chuỗi chỉ đọc (CategoryAvatar 40, tên = ghi chú ?? danh mục, phụ đề "tần suất · ngày"
  hoặc `repeatStopped` + `StatusPill(stop_circle, repeatStopped)`); Số tiền (không autofocus), Ghi chú + `recurringEditNote`;
  "Lặp lại" = 4 chip chọn một (nền secondary-container + ✓, radius-sm, cao 40, Semantics inMutuallyExclusiveGroup);
  đổi tần suất → `VgHint(l.recurringRestartHint(shortDate(RecurringRepository.nextDate(rule))), icon: restart_alt)`;
  ô chọn Danh mục (mở `showCategorySheet`) và Tài khoản (mở `showChoiceSheet`, ẩn khi chỉ 1 tài khoản) dạng
  `InputDecorator`+mũi tên; footer Hủy (outlined) + Lưu. f16 test phải đổi từ Dropdown sang chip/ô chọn.

## Chữ còn thiếu
- Không bắt buộc. Nếu muốn tránh ghép chuỗi cho Semantics "Hiện lại: {name}": `unarchiveAccountNamed` EN "Show again: {name}" / VI "Hiện lại: {name}".

## Rủi ro
- `currencySymbol` import từ `features/settings/budget_dialog.dart` (vùng D3) — D3 đổi tên/chuyển thì vỡ.
