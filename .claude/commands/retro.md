---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Viết retrospective cho app và chắt lọc bài học (ví dụ /retro APP-001)
model: sonnet
effort: low
---
Rút kinh nghiệm cho: $ARGUMENTS

1. Đọc CHANGELOG.md, BACKLOG.md (kể cả "Lỗi đã sửa đáng nhớ" và biên bản thử máy thật), DECISIONS.md, PROMPTS.md của app.
2. Điền RETROSPECTIVE.md theo đúng 7 mục, dựa trên dữ kiện thật trong các file trên. Phần chỉ người dùng biết (thời gian thực tế, điều bất ngờ, cảm nhận khi dùng) thì hỏi người dùng tối đa 3 câu gọn; không bịa.
3. Từ mục 7 "Ứng viên bài học": với mỗi ứng viên, kiểm tra lessons/LESSONS.md xem đã có bài tương tự chưa. Trùng thì cập nhật bài cũ hoặc ghi nhận thêm nguồn; mới thì đề xuất cho người dùng duyệt rồi thêm bằng `/lesson`. Xem lại các bài nguồn "khởi tạo": đối chiếu với trải nghiệm của app này và đề xuất giữ/sửa/retired.
4. Nếu bài học đủ quan trọng để luôn tuân theo, đề xuất thêm vào "Quy tắc vàng" (giữ dưới 15 dòng).
5. Chép RETROSPECTIVE.md vào lessons/retrospectives/<APP-NNN>.md.
6. Nếu app đã phát hành và mọi thứ xong: đề xuất `bash scripts/set-status.sh <APP> maintenance`.
