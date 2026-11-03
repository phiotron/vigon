---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Ghi một bài học vào kho chung (ví dụ /lesson test | Test giả lập không đủ | APP-001)
model: sonnet
effort: low
---
Ghi bài học: $ARGUMENTS

Cần đủ: chủ đề (kiến-trúc | prompt | ui-mobile | hiệu-năng | build-release | dữ-liệu | bảo-mật | quy-trình | test), tiêu đề, nguồn (mã app), tình huống, điều đã xảy ra, quy tắc rút ra (một câu mệnh lệnh, làm theo được). Thiếu thì suy ra từ ngữ cảnh phiên; thật sự thiếu thì hỏi một câu. Kiểm tra lessons/LESSONS.md để tránh trùng bài đã có.
Chạy: `bash scripts/add-lesson.sh "<chủ đề>" "<tiêu đề>" "<APP-NNN>" "<tình huống>" "<điều đã xảy ra>" "<quy tắc rút ra>"`. Đọc kết quả để lấy ID. Nếu là quy tắc luôn phải tuân theo, thêm một dòng vào "Quy tắc vàng" (giữ dưới 15 dòng).
