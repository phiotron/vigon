# 2026-11-18 · Chọn tài khoản ngay trên màn "Các khoản"

Người dùng: "các khoản í nó chưa chọn được theo tài khoản nào… tôi muốn nó chọn được cơ,
và tất nhiên trang chủ chọn [tài] khoản nào thì đầu tiên vào cũng là khoản đó nhưng có thể
thay đổi lại."

## Hiện trạng trước khi sửa

- Bộ lọc tài khoản `accountFilterProvider` (AC-20) đã có ở **Màn chính** (nút ví + chip),
  **Thống kê** và **Lịch** (`AccountFilterButton` nằm trong `stats_widgets.dart`).
- Màn **Các khoản** chỉ *hiện* chip `ActiveAccountChip` (tên tài khoản đang lọc + nút ✕) khi
  bộ lọc đang bật — **không có nút chọn tài khoản** trên thanh tiêu đề, nên muốn đổi phải
  quay về Màn chính.

## Đã sửa

- Tách `AccountFilterButton` khỏi `lib/src/features/stats/stats_widgets.dart` sang
  `lib/src/ui/account_filter_button.dart` (dùng chung cho Các khoản / Thống kê / Lịch).
- `lib/src/features/entries/entry_search.dart`: thanh tiêu đề màn Các khoản (trạng thái
  không tìm kiếm) thêm `const AccountFilterButton()` **trước** nút 🔍 và nút Lọc.
- Hành vi: cùng `accountFilterProvider` với Màn chính → vào Các khoản là đang đúng tài khoản
  đã chọn ở nhà; đổi ngay tại Các khoản (menu "Tất cả tài khoản" + từng tài khoản, dòng đang
  chọn có ✓); đổi xong Màn chính/Thống kê/Lịch cũng theo. Nút chỉ hiện khi có **từ hai** tài
  khoản (một tài khoản thì không cần chọn).
- Tìm kiếm và bảng Lọc nâng cao vẫn áp cùng tài khoản đang chọn (đã đúng từ trước).

## Test

- `test/features/f39_filter_test.dart` — "chọn tài khoản ngay trên màn Các khoản, mặc định
  theo màn chính (AC-20)": thêm tài khoản `Thẻ` + một khoản chi của Thẻ; mở Các khoản thấy
  nút "Tài khoản: Tất cả tài khoản"; chọn `Thẻ` → danh mục chi của tiền mặt (`Mua sắm`) mất,
  mở `Ăn uống` chỉ còn khoản của Thẻ, chip "Tài khoản: Thẻ" hiện; sang Trang chủ provider vẫn
  là Thẻ, về Các khoản vẫn lọc Thẻ; đổi lại "Tất cả tài khoản" → `Mua sắm` trở lại.
- `docs/SPEC.md` AC-20 ghi rõ bộ lọc dùng chung cho Các khoản/Thống kê/Lịch + đổi được tại
  mỗi màn; `docs/TESTING.md` thêm tên test vào dòng AC-20.

## Kiểm

- `flutter analyze`: sạch.
- `flutter test test/features/f39_filter_test.dart`: 11/11 xanh.
- `flutter test` toàn bộ: **1085 xanh** (1084 + 1 test mới).

## Ghi chú thiết kế

Bộ lọc **dùng chung** (giống Thống kê/Lịch) chứ không tách riêng: đúng câu "trang chủ chọn
tài khoản nào thì vào là tài khoản đó". Nếu sau này người dùng muốn Các khoản giữ lựa chọn
**riêng** (đổi ở Các khoản không ảnh hưởng Màn chính) thì thêm một provider riêng, khởi tạo
từ `accountFilterProvider` — chưa làm vì chưa được yêu cầu.
