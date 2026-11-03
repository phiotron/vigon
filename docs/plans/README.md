# plans — Kế hoạch cho từng tính năng/thay đổi lớn

SPEC.md mô tả cả app; mỗi tính năng lớn hoặc thay đổi rủi ro cao (đổi lưu trữ dữ liệu, thêm quyền, tích hợp dịch vụ, tái cấu trúc) có MỘT kế hoạch riêng ở đây trước khi làm.

- Tạo: `/feature <APP> <tên>` hoặc `bash scripts/new-plan.sh <APP> "<tên>"` (tự cấp PLAN-001, PLAN-002...).
- Mỗi kế hoạch có dòng `Đã duyệt: chưa` → đổi thành `Đã duyệt: <ngày>` khi người dùng duyệt. Chưa duyệt thì không viết code cho thay đổi đó.
- Kế hoạch đã duyệt được chia thành giai đoạn trong `../BACKLOG.md` (ghi rõ PLAN-xxx).
- Kế hoạch làm xong không xóa; ghi `Trạng thái: xong <ngày>` ở đầu file để làm lịch sử.
- Tính năng nhỏ nằm trong F-xx của SPEC thì không cần kế hoạch riêng.
