# [A002-vigon] Mẫu email biên lai MB Bank (đã che) — 2026-11-06

> Nguồn: ảnh chụp màn hình Gmail trên điện thoại của người dùng, lấy qua adb với sự cho phép của họ. Mọi tên người và số
> tài khoản dưới đây **đã che hoặc thay bằng giá trị giả cùng định dạng**. Ảnh gốc không đưa vào repo.
> **Chưa đủ để viết M1:** còn thiếu địa chỉ người gửi đầy đủ và 3 dòng cuối email (xem "Còn thiếu").

## Email "chuyển tiền nhanh ngoài MB" — thành công
- **Người gửi:** hiển thị là `mbebanking@mbb…` (bị cắt). Rất có thể là `mbebanking@mbbank.com.vn` — **phải xác nhận**, đừng
  đoán trong code.
- **Tiêu đề:** `Thong bao giao dich thanh cong` (không dấu).
- **Giờ Gmail nhận thư:** 13:32 — **muộn hơn giờ giao dịch gần 1 giờ 20 phút** (xem ghi chú dưới).
- **Thân thư (bảng hai cột, nhãn có dấu tiếng Việt):**

| Nhãn | Giá trị mẫu (đã che) | Ghi chú cho bộ đọc |
|---|---|---|
| Ngày, giờ giao dịch | `06-11-2026 12:11:42` | định dạng `dd-MM-yyyy HH:mm:ss`; có giây |
| Loại giao dịch | `Chuyển tiền nhanh ngoài MB` | còn các loại khác chưa thấy mẫu (chuyển trong MB, thanh toán QR, …) |
| Số tham chiếu | `26110612115874618` | 17 chữ số; dùng làm khoá chống trùng. Trông giống `yyMMdd` + `HHmmss` + số — **không** dựa vào cấu trúc này |
| Tài khoản trích nợ | `<TÊN CHỦ TK> - ········2004 (VND)` | `TÊN - SỐ TK (TIỀN TỆ)`; số TK đầy đủ **không** lưu, chỉ 4 số cuối `2004` |
| Người thụ hưởng | `<TÊN NGƯỜI NHẬN> - 054100XXX3102` | số TK người nhận đã bị ngân hàng che sẵn bằng `XXX` |
| Số tiền giao dịch | `(VND) 48,000.00` | tiền tệ trong ngoặc ở đầu; dấu `,` ngăn nghìn, dấu `.` thập phân |
| Nội dung chuyển tiền | `<TÊN CHỦ TK> chuyen tien` | không dấu; có thể rỗng hoặc dài |
| Cách thức lệnh | `Thanh toán ngay` | |
| Ngày nhập lệnh | *(chưa thấy)* | |
| Thời gian | *(chưa thấy)* | |
| Tình trạng | *(chưa thấy)* | cần biết đúng chữ của trạng thái thành công / thất bại / đang xử lý |

- Câu mở đầu: "Cảm ơn Quý khách đã sử dụng dịch vụ MB eBanking. MB xin thông báo giao dịch của Quý khách đã được thực hiện như sau:".
- Đầu thư có ảnh banner MB (ảnh nhúng, bộ đọc bỏ qua).

## Điều rút ra cho thiết kế (đưa M1 đọc)
1. **Dùng giờ trong thân thư, không dùng giờ Gmail nhận.** Thư tới trễ ~1 giờ 20 phút; luật ghép ±2 giờ (AC-94) với khoản
   ghi tay phải so với `Ngày, giờ giao dịch` (12:11), không so với lúc tải thư.
2. **Tiền tệ có trong thư** (`(VND)`). Nếu khác tiền tệ của app thì phải xử lý (bỏ qua/hàng đợi có cảnh báo) —
   kiểm với SPEC F-29.
3. **Chỉ có khoản chi** (đúng với phạm vi): đây là biên lai chuyển tiền đi.
4. **Số tiền** dạng `48,000.00` (en-US) → đọc bằng bộ đọc riêng, không dùng `normalizeAmountInput` theo ngôn ngữ app.
5. **Người thụ hưởng** là khoá gợi ý danh mục (AC-97): bỏ dấu, viết thường, gộp khoảng trắng; **cắt phần ` - số TK`** khỏi tên.
6. Trường hợp riêng cần cân nhắc: người thụ hưởng **trùng tên chủ tài khoản** (tự chuyển cho mình) → gợi ý "Chuyển sang tài
   khoản của tôi".

## Còn thiếu (người dùng cần cuộn email xuống và nhắn lại)
- Địa chỉ người gửi **đầy đủ** (chạm "đến tôi ▾" trong Gmail).
- Ba dòng cuối: **Ngày nhập lệnh, Thời gian, Tình trạng** (đúng chữ).
- Nếu có: một email **thất bại** hoặc **đang xử lý**; một email loại khác (chuyển trong MB, QR, thanh toán hoá đơn) để
  biết nhãn có khác không.
