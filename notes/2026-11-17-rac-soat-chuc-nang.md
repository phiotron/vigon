# 2026-11-17 · Rà soát xem còn sót chức năng nào (A002-vigon)

Người dùng hỏi "kiểm tra kỹ xem còn sót chức năng nào không". Làm trực tiếp, **chỉ trong
`apps/A002-vigon`**, không đụng điện thoại (đang bận), không push.

## Cách rà

- Quét mã nguồn: `TODO`, `FIXME`, `XXX`, `UnimplementedError`, `throw Unimplemented`,
  chỗ trả rỗng/`SizedBox.shrink` có ghi chú "chưa làm", route khai báo nhưng không có màn,
  hàng Cài đặt không có `onTap`.
- Đối chiếu từng mục F-01..F-52 trong `docs/SPEC.md` với màn/hàm tương ứng; đối chiếu
  `docs/DECISIONS.md` (D-001..D-051) xem quyết định nào chưa có mã.
- Kiểm các việc đã ghi ở "Việc dở" trong `APP.md` (hộp thư/số đếm màn chính, kéo-làm-mới
  kiểm mail, nhãn "Từ email MB", biểu tượng email, hàng Cài đặt, route, màn chào, file
  widget iOS, "Sắp vượt", xuất CSV/Excel/PDF, lãi + chọn tài khoản cho nợ): **đều đã có**.
- Rà chỗ hiển thị số tiền theo **D-042** (Tiền tệ chính trên, số gốc dưới) và chỗ lọc theo
  danh mục/tài khoản đã bị xoá.

## Hai chỗ sót đã sửa

### 1. Dòng kết quả Tìm kiếm chưa theo D-042 (AC-146)

- `lib/src/features/entries/entry_search.dart`
  - `EntrySearchResults` thôi truyền `amount` đã định dạng sẵn vào `SearchResultTile`.
  - `SearchResultTile` dựng số bằng `moneyLinesText` như các màn khác: **dòng Tiền tệ chính
    ở trên**, dòng số gốc nhỏ ở dưới (chỉ khi khác tiền tệ / thiếu tỉ giá); dấu +/− chỉ ở
    dòng chính; dòng gốc thiếu tỉ giá tô màu lỗi.
  - Tìm theo số tiền khớp **số gốc** (như `amountTextOf`), nên chỉ tô sáng dòng số gốc;
    dòng Tiền tệ chính đã quy đổi thì không tô (tránh tô sai vị trí).
- Test: `test/features/entry_search_test.dart` — "dòng tìm hiện Tiền tệ chính trên, số gốc
  dưới (AC-146)": Tiền tệ chính USD, 1 USD = 25.000 ₫, khoản 155.000 ₫ → thấy `−6,20 $`
  nằm **trên** `155.000 ₫` trong cùng một dòng kết quả. Ghi dữ liệu trước `pumpApp` để
  không phải sửa cài đặt khi app đang theo dõi bảng `settings` (xem lưu ý ở `APP.md`).

### 2. Bộ lọc còn id danh mục đã xoá (AC-115)

- Xoá danh mục đang được lọc (chuyển khoản sang danh mục khác) trước đây để lại id trong
  `entryFilterProvider`: danh sách trống mà **không còn chip nào để gỡ** → kẹt.
- `lib/src/features/categories/categories_screen.dart`: sau `repo.delete(...)` gọi
  `entryFilterProvider.notifier.remove(category: c.id)`.
- `lib/src/features/settings/data_actions.dart`: khôi phục file và "Xoá toàn bộ dữ liệu"
  cũng `clear()` bộ lọc khoản (id danh mục/tài khoản trong file cũ không còn nghĩa).
- Bộ lọc **tài khoản** đã tự lành từ trước (`AccountFilterNotifier` nghe `accountsProvider`,
  bỏ id không còn) nên không cần sửa thêm.
- Test: `test/features/g6_flows_test.dart` — "xóa danh mục đang lọc thì bỏ id khỏi bộ lọc
  (AC-115)": lọc theo `Ăn uống`, xoá và chuyển khoản sang `Đi lại`, chip biến mất, danh
  sách nhóm hiện lại, không còn trạng thái "không có kết quả".

## Kiểm

- `flutter analyze`: sạch.
- `flutter test` toàn bộ: **1084 test xanh** (thêm 2 test hồi quy ở trên).
- Không thấy chỗ nào khác còn thiếu chức năng: không TODO/FIXME/stub, không test bị bỏ qua,
  mọi route đều có màn, mọi hàng Cài đặt đều có tác dụng.

## Còn chờ (không phải sót chức năng)

- **Máy thật:** PIN khoá tạm (D-050), hàng "Đánh giá" ẩn (D-051), chuyển máy Android 12+,
  chip nhắc hạn Tiết kiệm theo giờ, và hai chỗ vừa sửa (dòng tìm 2 tầng, bộ lọc sau khi xoá
  danh mục) — chờ điện thoại rảnh, hỏi trước khi dùng adb.
- **iOS:** App Group `group.com.phiotron.vigon`, build/CI trên macOS runner, khai báo mã hoá.
- **Phát hành:** đăng lại trang pháp lý sau khi duyệt (cần người dùng đồng ý), upload
  keystore, Play Console closed test, mockup v5 (chưa có) để áp lại điều hướng.
