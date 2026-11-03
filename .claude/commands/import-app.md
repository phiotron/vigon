---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Nhập app có sẵn (do người khác viết) vào D:/DemoChung (ví dụ /import-app D:/Downloads/app-cu | Giao hàng | app giao hàng)
model: haiku
effort: low
---
Nhập app có sẵn: $ARGUMENTS

1. Tách: đường dẫn thư mục nguồn, tên app, mục đích (nếu có). Thiếu đường dẫn hoặc tên thì hỏi một câu gọn. Dùng đường dẫn đúng như shell của bạn nhìn thấy (nếu shell không hiểu `D:\x`, thử `D:/x` hoặc `/d/x`).
2. Chạy `bash scripts/import-app.sh "<nguồn>" "<tên>" "<mục đích>"` từ D:/DemoChung và ĐỌC kết quả. Script SAO CHÉP (không sửa bản gốc), bỏ file nghi là bí mật, không ghi đè file của app.
3. Báo người dùng: mã app và thư mục mới; danh sách file bí mật bị bỏ qua; file gốc được giữ với đuôi `.original.md`; remote git (đã che mật khẩu) và lưu ý KHÔNG push; lịch sử git đã sao chép nguyên vẹn nên có thể chứa bí mật cũ.
4. Chạy `bash scripts/check.sh --app <mã vừa tạo>`; phải không có LỖI.
5. KHÔNG sửa code của app, KHÔNG cài thư viện, KHÔNG chạy app ở bước này. Đề xuất bước tiếp: `/audit <APP>`.
