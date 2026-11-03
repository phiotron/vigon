---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Kiểm tra thật bằng lệnh lint/typecheck/test và đối chiếu tiêu chí chấp nhận (ví dụ /check-ac APP-001)
model: sonnet
---
Kiểm chứng giai đoạn hiện tại cho: $ARGUMENTS

1. Xác định app. Đọc mục "Lệnh" trong CLAUDE.md của app.
2. CHẠY THẬT lần lượt lint, typecheck, test (và build nếu giai đoạn yêu cầu). Đọc kết quả thật. Lệnh nào chưa điền hoặc không chạy được: ghi rõ "CHƯA kiểm chứng" và lý do, không bỏ qua im lặng.
3. Đối chiếu từng AC của giai đoạn hiện tại trong docs/SPEC.md: AC nào được test tự động chứng minh (nêu tên test), AC nào cần thử tay (liệt kê bước thử cho người dùng).
4. Kiểm tra: không có TODO/FIXME mới chưa vào BACKLOG; `git diff` không chứa bí mật; BACKLOG/CHANGELOG đã cập nhật.
5. Nếu chạy được app trên máy này, có thể dùng thêm lệnh có sẵn `/verify` (build và chạy app để xem thay đổi hoạt động); không chạy được thì ghi rõ.
6. Trước khi kết luận, áp dụng skill `verification-before-completion`: không có kết luận nào mà chưa có bằng chứng chạy trong phiên này.
7. Báo cáo ngắn theo bảng: mục | kết quả thật | bằng chứng. Kết luận ĐẠT chỉ khi mọi mục tự động đạt và mọi mục chưa kiểm chứng đã được nêu rõ. Có lỗi thì liệt kê và đề xuất sửa; không tuyên bố đạt.
