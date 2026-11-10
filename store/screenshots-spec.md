# Quy cách ảnh chụp store — Ví Gọn (Google Play + App Store)

Viết 2026-11-04. **Chụp thật ở phiên điều phối #3 (phiên con E) với UI mới** của phiên #2. Ảnh hiện có trong
`store/screenshots/` (UI cũ, 2026-11-03) chỉ giữ làm tham khảo bố cục và dùng tạm cho trang closed test — không xoá.
Kiểm lại bảng kích thước của Google/Apple ngày chụp (đổi theo năm); ghi ngày kiểm vào cuối file.

## 1. Kích thước và số lượng bắt buộc
### Google Play (điện thoại)
| Thành phần | Bắt buộc | Quy cách |
|---|---|---|
| Ảnh chụp điện thoại | **2–8 ảnh** mỗi ngôn ngữ | PNG hoặc JPEG 24-bit, **không kênh alpha**, ≤ 8 MB; cạnh 320–3840 px; cạnh dài ≤ 2 × cạnh ngắn. Muốn đủ điều kiện được Play gợi ý/quảng bá: **≥ 4 ảnh, ≥ 1080 px** cạnh ngắn |
| Kích thước chọn | | **1080 × 2160** (2:1, đúng mức tối đa Play cho phép) hoặc 1080 × 1920 (9:16) nếu thêm dải chữ chú thích |
| Icon | Có | 512 × 512 PNG 32-bit, ≤ 1 MB — đã có `store/brand/icon-512.png` |
| Ảnh bìa (feature graphic) | Có | 1024 × 500 PNG/JPEG không alpha — CHƯA có PNG (`store/brand/README.md`) |
| Máy tính bảng 7"/10", Chromebook, Wear | Không | Bản 1 chỉ nhắm điện thoại → bỏ |
| Video | Không | Bỏ |

### App Store (iPhone)
| Thành phần | Bắt buộc | Quy cách |
|---|---|---|
| iPhone **6.9"** | **Có — 1 đến 10 ảnh** mỗi localization | Dọc **1320 × 2868** (chọn cỡ này), hoặc 1290 × 2796 / 1260 × 2736. PNG/JPEG, không alpha, RGB |
| iPhone 6.5" | Chỉ khi không có bộ 6.9" | 1284 × 2778 hoặc 1242 × 2688 — **bỏ**, có 6.9" là đủ; App Store Connect tự thu nhỏ cho máy nhỏ hơn |
| iPad 13" | Chỉ khi app hỗ trợ iPad | **Không cần**: bản 1 chỉ iPhone (`TARGETED_DEVICE_FAMILY = 1`, chỉ dọc — `ios/` commit `9438ddd`). Nếu sau này bật iPad thì bắt buộc thêm 2064 × 2752 |
| Icon App Store | Có | 1024 × 1024 PNG, không alpha, không bo góc (lấy từ `AppIcon` của `ios/`) |
| App Preview (video) | Không | Bỏ |

Thứ tự ảnh: 3 ảnh đầu hiện ngay trong kết quả tìm kiếm → đặt 3 ảnh mạnh nhất (màn chính, nhập nhanh, riêng tư) lên đầu.

## 2. Bộ ảnh (mỗi ngôn ngữ một bộ; cập nhật 2026-11-05 theo bản đã gộp F-01..F-26)
Ảnh 1–8 chung hai store (chụp riêng trên từng nền tảng). Cập nhật 2026-11-05 theo D-022: iPhone nay có widget, sao lưu tự động,
che nội dung → ảnh 8 widget dùng cho cả hai; ảnh "chữ cỡ lớn" trước đây dành riêng cho App Store thành ảnh tuỳ chọn.
| # | Màn | Trạng thái cần dựng | Chú thích vi | Chú thích en |
|---|---|---|---|---|
| 1 | Màn chính, giao diện sáng | Kỳ "Tháng 11/2026", biểu đồ vòng đủ 8 danh mục, thanh ngân sách ~87% | Biết tiền đi đâu | See where your money goes |
| 2 | Nhập khoản | Loại Chi, bàn phím đang có phép tính `45.000+30.000`, danh mục Ăn uống đang chọn, nút Lưu thấy rõ | Ghi một khoản trong 3 chạm | Log it in three taps |
| 3 | Cài đặt, các nhóm Bảo mật → Nhắc ghi sổ → Dữ liệu | Thấy "Khóa bằng mã PIN", "Nhắc ghi sổ hằng ngày" (Android: bật, 20:00; iPhone trên simulator CI có thể để tắt vì không chạm được hộp thoại quyền), "Xuất bản sao lưu", "Xuất CSV", "Che nội dung khi chuyển app", "Sao lưu tự động" (cả hai nền tảng, D-022; dòng chú thích dưới công tắc khác nhau theo nền tảng — chụp đúng chữ thật) | Dữ liệu chỉ ở trên máy bạn | Your data stays on your phone |
| 4 | Các khoản | Gom theo danh mục, có phần trăm, ≥ 6 dòng; dòng Ăn uống có thanh hạn mức danh mục và chữ "Vượt 420.000" (F-20) | Ngân sách cho từng danh mục | A budget for every category |
| 5 | Khoản định kỳ | 3 chuỗi: Tiền nhà (tháng), Internet (tháng), Học phí (tháng) | Khoản định kỳ tự ghi | Recurring bills, added for you |
| 6 | Tài khoản + chuyển tiền | 3 tài khoản: Tiền mặt, Ngân hàng, Thẻ tín dụng; có 1 khoản chuyển | Nhiều ví, chuyển qua lại | Cash, bank and card in one place |
| 7 | Màn chính, giao diện tối | Như ảnh 1 | Giao diện sáng và tối | Light and dark themes |
| 8 | Màn hình chính của máy có widget Ví Gọn (Android 2×2; iPhone widget nhỏ hoặc vừa) | Nút "Chi"/"Thu"; bật "Hiện số tiền trên widget", PIN tắt → dòng "Tháng này đã chi 12.980.000 / 15.000.000". Hình nền trơn, **không có icon app khác** trên màn hình (nhãn hiệu người khác). iPhone: widget đọc số qua App Group — trên simulator CI chưa ký App Group thì widget có thể không có số → chụp qua TestFlight hoặc chụp trạng thái mặc định (chỉ hai nút) | Ghi khoản ngay từ màn hình chính | Add a record from your home screen |

Tuỳ chọn thêm (chỉ khi bỏ bớt ảnh khác, Play tối đa 8): Cài đặt → Sao lưu tự động (cả hai); màn tìm kiếm khoản (cả hai); màn chính cỡ chữ lớn
("Dễ đọc với chữ cỡ lớn" / "Built for large text", App Store cho tới 10 ảnh nên có thể thêm làm ảnh 9).
Không chụp thông báo nhắc trên màn khoá (simulator CI không chạm được hộp thoại quyền; Android cần adb — hỏi trước).
Bộ ảnh iPhone **không được** có icon đơn sắc (chỉ Android) hay chữ "Android"/"Google Play" (App Review 2.3.3, 2.3.10);
bộ Play không có chữ "iPhone"/"App Store".
Chú thích (nếu dùng) đặt trong dải màu nền thương hiệu `#0E5244`, chữ
Be Vietnam Pro 700 trắng, phía trên ảnh màn hình; không thêm khung máy của hãng (tránh dùng hình iPhone/Android có thương hiệu),
không thêm chữ "Số 1", "Tốt nhất", giá, hay so sánh với app khác. Ảnh phải là **UI thật của app** (App Review 2.3.3).

## 3. Kịch bản dữ liệu mẫu (không dùng dữ liệu thật của ai)
Tạo một file sao lưu mẫu `.vigon` cho mỗi ngôn ngữ rồi khôi phục vào máy chụp (cách đã dùng 2026-11-03: sinh bằng `exportBackup`).
Ngày trên máy chụp: **2026-11-24**. Tên tài khoản dùng chữ chung, **không dùng tên ngân hàng thật** (nhãn hiệu của người khác).

**Bộ tiếng Việt — tiền tệ VND, tháng 11/2026**
| Loại | Danh mục | Tổng tháng | Gợi ý các khoản |
|---|---|---|---|
| Thu | Lương | 18.000.000 | 1 khoản ngày 05 |
| Chi | Nhà cửa | 5.000.000 | Tiền nhà (định kỳ, ngày 01) |
| Chi | Ăn uống | 3.420.000 | 15–20 khoản nhỏ 35.000–250.000; ghi chú "Cơm trưa", "Cà phê"; **hạn mức danh mục 3.000.000** (vượt 420.000, cho ảnh 4) |
| Chi | Mua sắm | 1.250.000 | 3 khoản; hạn mức danh mục 1.500.000 (~83%) |
| Chi | Hóa đơn | 1.180.000 | Điện 620.000, Internet 220.000 (định kỳ), Nước 340.000 |
| Chi | Đi lại | 760.000 | Xăng, gửi xe |
| Chi | Giáo dục | 600.000 | Học phí tiếng Anh (định kỳ) |
| Chi | Giải trí | 450.000 | Xem phim, đăng ký nhạc |
| Chi | Sức khỏe | 320.000 | Thuốc |
Tổng chi 12.980.000 · số dư tháng 5.020.000 · ngân sách tháng **15.000.000** (đã dùng ~87%, chưa vượt).
Tài khoản: Tiền mặt 2.150.000 · Ngân hàng 14.870.000 · Thẻ tín dụng −1.250.000; 1 khoản chuyển Ngân hàng → Tiền mặt 2.000.000.

**Bộ tiếng Anh — tiền tệ USD, November 2026**
| Type | Category | Month total |
|---|---|---|
| Income | Salary | 4,200.00 |
| Expense | Home | 1,450.00 (rent, recurring) |
| Expense | Food | 612.40 (category budget 550.00 → over by 62.40, shot 4) |
| Expense | Bills | 186.75 (internet recurring) |
| Expense | Shopping | 158.90 |
| Expense | Transport | 94.20 |
| Expense | Entertainment | 64.00 |
| Expense | Health | 38.50 |
Total spent 2,604.75 · balance 1,595.25 · monthly budget **3,000.00** (~87%). Accounts: Cash, Bank, Credit card; one transfer.
Nhập khoản ảnh 2 (en): `12.50+8.75`, category Food.

Cài đặt cho ảnh: Nhắc ghi sổ bật lúc 20:00 trên Android (trên iPhone chỉ bật nếu cấp được quyền thông báo, không thì để tắt); khoá PIN **tắt** khi chụp ảnh 8 (để widget hiện số), bật lại cũng được cho ảnh 3.
Kiểm trước khi chụp: không thông báo, không tên người thật, không email, giờ trên thanh trạng thái 9:41, pin đầy, sóng đầy.

## 4. Cách chụp (vì máy làm việc là Windows, không có iPhone)
- **Android:** máy thật Galaxy A13 (1080 × 2408) bản release, hoặc emulator Pixel cỡ 1080 × 2400; bật Demo mode cho thanh trạng thái
  (`adb shell settings put global sysui_demo_allowed 1` + lệnh demo) **chỉ khi người dùng cho phép dùng adb**; cắt về 1080 × 2160
  hoặc ghép vào khung 1080 × 1920 có dải chú thích. Lần trước bị cắt mất đáy nút Lưu → lần này ghép khung thay vì cắt.
- **iOS:** iOS Simulator trên GitHub Actions macOS runner, máy **iPhone 6.9"** (ví dụ "iPhone 17 Pro Max", 1320 × 2868):
  `xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`,
  khôi phục file mẫu (hoặc chạy test tích hợp nạp dữ liệu mẫu), chụp `xcrun simctl io booted screenshot <file>.png`, tải về bằng
  artifact của workflow. Việc viết workflow chụp ảnh thuộc phiên nền iOS/CI hoặc phiên E — ghi rõ khi giao việc.
- Ảnh đặt tên: `store/screenshots/<platform>-<lang>/<nn>-<man>.png`, ví dụ `store/screenshots/ios-en/01-home.png`.
  Chuyển 6 ảnh cũ vào `store/screenshots/old-2026-11-03/` ở phiên #3 (giữ làm tham khảo).

## 5. Kiểm sau khi chụp
- Kích thước đúng bảng mục 1 (`python -c "from PIL import Image; ..."` hoặc xem thuộc tính file); không kênh alpha.
- Chữ trong ảnh khớp ngôn ngữ của trang store; số tiền định dạng đúng ngôn ngữ (AC-22).
- Không lộ nội dung không có trong app thật; không chú thích hứa điều app không làm (ví dụ "mã hoá", "đồng bộ đám mây").

Ngày kiểm bảng kích thước lần cuối: 2026-11-04 (qua tài liệu bên thứ ba tổng hợp; kiểm lại trang chính thức của Apple
"Screenshot specifications" và Play Console Help "Add preview assets" khi chụp).
