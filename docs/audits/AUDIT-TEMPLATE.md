# AUDIT — APP-001 · Ví Gọn — {{AUDIT_DATE}}

Quy tắc: mọi nhận định có bằng chứng (`file:dòng` hoặc lệnh đã chạy + kết quả) hoặc đánh dấu `[suy luận]` (nói rõ suy từ đâu) / `[chưa rõ]` (đưa vào mục 11). Audit chỉ đọc, không sửa code.

## 0. Phạm vi và quyền đã được cấp
- Đã đọc: (liệt kê thư mục/file đã đọc thật)
- KHÔNG đọc/không chạy: (và lý do; ví dụ chưa cho phép gọi mạng, không có máy thật)
- Người yêu cầu / mục đích đánh giá:

## 1. Tóm tắt (tối đa 8 dòng)
- App làm gì, cho ai:
- Mức độ sẵn sàng: (dùng được ngay / cần sửa vài chỗ / cần làm lại phần lớn)
- 3 rủi ro lớn nhất:
- 3 việc nên làm trước:

## 2. Dữ kiện tự động (đo bằng script, không phải nhận định)
<!-- FACTS -->

## 3. Kiến trúc thực tế
(Cấu trúc thư mục, các khối chính, luồng dữ liệu, điều hướng. Điền ngược vào `../ARCHITECTURE.md`.)

## 4. Tính năng hiện có
(Mỗi tính năng: tên, chạy được hay chưa, nằm ở file nào. Cơ sở để viết SPEC.)

## 5. Chất lượng mã
(Tổ chức, đặt tên, lặp, kiểu dữ liệu, xử lý lỗi, độ phức tạp; kèm ví dụ file:dòng.)

## 6. Kiểm thử
(Có test gì, chạy được không — ghi lệnh đã chạy và kết quả thật; độ phủ ước lượng nếu đo được.)

## 7. Bảo mật và quyền riêng tư
(Đối chiếu mục "dấu hiệu bí mật" ở mục 2: dương tính thật hay giả? Quyền thiết bị có cần thiết? Dữ liệu người dùng lưu/gửi đi đâu? Thư viện có lỗ hổng đã biết — nếu chưa chạy kiểm tra thì ghi rõ chưa chạy.)

## 8. Hiệu năng và đặc thù mobile
(Offline, mạng yếu, pin, bộ nhớ, màn hình nhỏ, xin quyền, vòng đời app.)

## 9. Rủi ro và nợ kỹ thuật
| Mức (chặn/nặng/nhẹ) | Mô tả | Bằng chứng | Đề xuất |
|---------------------|-------|------------|---------|

## 10. Việc nên làm (theo thứ tự ưu tiên)
(Chép các mục được người dùng chọn vào `../BACKLOG.md`. Việc cần thay đổi hành vi app phải qua SPEC/PLAN được duyệt.)

## 11. Điều chưa kiểm chứng / câu hỏi mở
-
