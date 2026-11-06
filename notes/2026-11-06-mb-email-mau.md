# [A002-vigon] Mẫu email biên lai MB Bank (đã che) — 2026-11-06

> Nguồn: ảnh chụp màn hình Gmail trên điện thoại của người dùng, lấy qua adb với sự cho phép của họ. Mọi tên người và số
> tài khoản dưới đây **đã che hoặc thay bằng giá trị giả cùng định dạng**. Ảnh gốc không đưa vào repo.
> **Gần đủ để viết M1:** đã có đủ các dòng của thân thư; còn thiếu **địa chỉ người gửi đầy đủ** (xem "Còn thiếu").

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
| Ngày nhập lệnh | `06-11-2026` | chỉ có ngày, định dạng `dd-MM-yyyy` |
| Thời gian | `06-11-2026 12:11:42` | **trùng** với "Ngày, giờ giao dịch" ở đầu bảng (cùng giá trị trong mẫu này) |
| Tình trạng | `Giao dịch thành công` | chữ của trạng thái thành công; chưa có mẫu thất bại/đang xử lý → **chỉ nhận đúng chữ này**, mọi chữ khác bỏ qua (an toàn) |

- Câu mở đầu: "Cảm ơn Quý khách đã sử dụng dịch vụ MB eBanking. MB xin thông báo giao dịch của Quý khách đã được thực hiện như sau:".
- Kết thư: "Xin chân thành cảm ơn." + ảnh banner chân thư (Ngân hàng TMCP Quân đội, hotline MB247, `mb247@mbbank.com.vn`, `www.mbbank.com.vn`) và đoạn địa chỉ trụ sở — bộ đọc bỏ qua. Địa chỉ `mb247@mbbank.com.vn` là **hộp liên hệ trong chân thư, không phải người gửi**; chỉ gợi ý tên miền của ngân hàng là `mbbank.com.vn`.
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

## Còn thiếu
- Địa chỉ người gửi **đầy đủ** (người dùng chạm "đến tôi ▾" trong Gmail rồi nhắn lại). Không thay bằng suy đoán trong code (AC-81 lọc đúng nguyên địa chỉ).
- Nếu có: một email **thất bại** hoặc **đang xử lý**; một email loại khác (chuyển trong MB, QR, thanh toán hoá đơn) để
  biết nhãn có khác không.
