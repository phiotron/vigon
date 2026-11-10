# Mẫu email MB Bank (đã che)

Dựng lại từ `notes/2026-11-06-mb-email-mau.md` (ảnh chụp màn hình Gmail, chỉ có email THÀNH CÔNG).
Mọi tên, số tài khoản, số tham chiếu ở đây là **giá trị giả** cùng định dạng; không có dữ liệu thật của người dùng.

- `success_table.html` — dạng HTML bảng (ô nhãn / ô giá trị), có banner, chân thư, `&nbsp;`.
- `success_text.txt` — dạng text/plain `Nhãn: giá trị`.

Kết quả mong đợi (cả hai file): ngày `2026-11-08`, giờ `09:30`, tham chiếu `26110809301234567`, 4 số cuối `4821`, `VND`,
48000, người thụ hưởng `LE VAN KHACH`, nội dung `TRAN THI MAU chuyen tien`.
Chưa có mẫu thất bại / đang xử lý / loại giao dịch khác — test dùng thư dựng tay (tình trạng khác).

## Thư thật (2026-11-10)
- `real_outlook_2026-11-09.html` — thân `text/html` **thật** của một thư MB (không có `text/plain`), lấy từ hộp thư người dùng
  qua bản build chẩn đoán tạm (đã gỡ) rồi **che**: tên → `NGUYEN VAN A`, số TK trích nợ → `0000002004` (giữ 4 số cuối),
  số TK người nhận → `999999XXX1234`, số tham chiếu → `26110900000000001`, id ảnh → `cid:banner`.
  Soạn bằng Outlook/Word: mỗi ô bọc `<p class=MsoNormal>`, chữ có dấu viết bằng thực thể `&#7883;`, và **nhãn bị ngắt dòng
  trong mã nguồn** (`Ng&#224;y,⏎  gi&#7901; giao d&#7883;ch`) — nguyên nhân mọi thư thật "không đọc được" trước 2026-11-10.
  Mong đợi: `2026-11-09` `11:23`, VND 87000, 4 số cuối `2004`, người thụ hưởng/nội dung `NGUYEN VAN A…`.
- Địa chỉ gửi đã xác nhận: `mbebanking@mbbank.com.vn`; tiêu đề `Thong bao giao dich thanh cong`.
