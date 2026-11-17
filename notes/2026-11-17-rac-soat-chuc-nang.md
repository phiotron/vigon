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

## Kiểm trên máy ảo Android (cùng ngày, người dùng cho phép)

Máy ảo `Medium_Phone_API_37.0` (Android 17/API 37, x86_64, 1080×2400, `emulator-5554`), chạy
không cửa sổ (`-no-window -gpu swiftshader_indirect`), cài APK debug `--target-platform
android-x64`, **không đụng điện thoại thật**. Ảnh chụp: `%TEMP%\opencode\emu-shots\01..71.png`.

- **Cài mới, mặc định:** màn chào 5 bước tiếng Anh, Tiền tệ chính **USD** — đúng **D-036**.
- **PIN (D-050):** đặt 1234; tắt/mở app ra màn khoá. Sai 4 lần → "Wrong PIN"; lần 5 →
  "Try again in 0:27", bàn phím mờ + không bấm được; hết hạn sai tiếp → "Try again in 0:57"
  (mức 1 phút). Đang khoá mà force-stop + mở lại → **vẫn khoá** ("Try again in 0:21"), bàn
  phím tắt. Hết giờ nhập 1234 → mở được; sai lại 1 lần chỉ báo "Wrong PIN" (bộ đếm **đã
  reset** sau lần đúng).
- **Hàng "Đánh giá" (D-051):** Cài đặt → Giới thiệu chỉ còn Version, Privacy policy, Terms of
  use, Open-source licences, Send feedback, Report a security issue — **không có hàng Rate**.
- **AC-146 trên máy:** thêm khoản chi 155.000 ₫ (≈ $6.02) vào danh mục Food; Records → Tìm
  kiếm `155000`: "1 record · total $6.02", dòng kết quả hiện **−$6.02 ở trên** và **₫155,000
  ở dưới**, chỉ dòng số gốc được tô sáng.
- **AC-115 trên máy:** lọc Records theo Food (chip "Food ×", 1 record) → Cài đặt → Danh mục →
  xoá Food (chuyển 1 khoản sang Other) → quay lại Records: **chip lọc biến mất**, danh sách
  hiện lại với khoản ở nhóm Other; không còn trạng thái trống kẹt.
- **Ghi chú khi điều khiển máy ảo:** toạ độ `adb shell input tap` phải đo trên PNG
  (1080×2400) — ước lượng theo màn hình bị lệch ~85 px dọc; bàn phím số có "5" ở hàng 2
  (không phải hàng 3).

## Còn chờ (không phải sót chức năng)

- **Máy thật / môi trường thật:** chuyển máy Android 12+ (không kiểm được trên máy ảo), chip
  nhắc hạn Tiết kiệm theo giờ (cần mục tiêu có hạn + nhắc), iOS (App Group, CI macOS). PIN
  khoá tạm và hàng "Đánh giá" **đã kiểm xong trên máy ảo**.
- **iOS:** App Group `group.com.phiotron.vigon`, build/CI trên macOS runner, khai báo mã hoá.
- **Phát hành:** đăng lại trang pháp lý sau khi duyệt (cần người dùng đồng ý), upload
  keystore, Play Console closed test, mockup v5 (chưa có) để áp lại điều hướng.
