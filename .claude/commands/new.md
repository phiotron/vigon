---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Tạo app mới và lập kế hoạch (ví dụ /new Quản lý chi tiêu | theo dõi chi tiêu cá nhân)
---
Người dùng muốn tạo app mới: $ARGUMENTS

1. Tách tên và mục đích từ yêu cầu (nếu thiếu mục đích, hỏi một câu gọn).
2. Quy mô: nếu người dùng nói app nhỏ/đơn giản/thử nghiệm, hoặc dùng từ "nhẹ", tạo quy mô nhẹ; nếu mơ hồ, hỏi MỘT câu (nhẹ: SPEC một trang, ít tài liệu; chuẩn: đủ bộ, bắt buộc cho app có dữ liệu nhạy cảm hoặc sắp phát hành). Chạy `bash scripts/new-app.sh "<tên>" "<mục đích>" "<stack>" "<nhãn>" [nhẹ]` từ D:/DemoChung và đọc kết quả (mã app, thư mục).
3. Chạy `bash scripts/check.sh --app <mã vừa tạo>`; phải không có LỖI.
4. Chuyển sang quy trình `/spec` cho app vừa tạo (giai đoạn 1). KHÔNG viết code.
Báo lại mã app và thư mục vừa tạo.
