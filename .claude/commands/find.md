---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Tìm app theo mô tả mơ hồ (ví dụ /find app quét mã vạch kho)
model: haiku
effort: low
---
Tìm app: $ARGUMENTS

1. Rút ra 2–4 từ khóa chính từ mô tả (bỏ từ chung chung như "app", "ứng dụng", "cái"). Chạy `bash scripts/find-app.sh "<từ khóa>"` từ D:/DemoChung và ĐỌC kết quả.
2. Ít hoặc không có kết quả: thử lại với từ đồng nghĩa hoặc tiếng Anh tương ứng (ví dụ "kho" → "warehouse inventory", "mã vạch" → "barcode"); mỗi lần chạy một lệnh riêng, tối đa 3 lần.
3. Trình bày tối đa 5 ứng viên: mã, tên, trạng thái, ngày cập nhật, vì sao khớp (registry hay tài liệu), mục đích. Với ứng viên khớp tốt nhất, đọc `docs/SPEC.md` của nó rồi nói ngắn app làm gì để người dùng xác nhận đúng app.
4. KHÔNG mở sâu hoặc sửa app nào trừ khi người dùng chọn. Chọn xong: nếu app ngủ lâu (cột Cập nhật cũ hơn khoảng 6 tháng) và người dùng muốn sửa/nâng cấp, đề xuất `/revive <APP>`; ngược lại làm theo CLAUDE.md gốc, mục "Bắt đầu mỗi phiên".
5. Không tìm thấy: nói rõ không thấy, đề xuất các hướng (app chưa nhập vào D:/DemoChung → `/import-app`; thử nhãn khác; xem `bash scripts/status.sh --status paused`).
