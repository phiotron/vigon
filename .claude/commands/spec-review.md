---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Kiểm chứng độc lập theo SPEC/PLAN bằng agent chỉ được đọc, trước khi gộp tính năng hoặc phát hành (ví dụ /spec-review APP-001 PLAN-002)
effort: high
---
Kiểm chứng độc lập cho: $ARGUMENTS

Mục đích: người kiểm tra không thấy lập luận của người viết code, chỉ thấy tiêu chí và code.

1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). Phạm vi: PLAN người dùng nêu (nhánh `feature/PLAN-NNN` so với nhánh chính), hoặc mọi thay đổi từ tag/phát hành gần nhất. Lấy danh sách file đổi bằng `git diff --stat <mốc>...HEAD` trong thư mục app.
2. Tự chạy trước Lint/Typecheck/Test theo mục "Lệnh" trong CLAUDE.md của app và ghi kết quả thật (agent kiểm tra không chạy lệnh được).
3. Giao cho agent `reviewer` (chỉ có Read, Grep, Glob; ở `.claude/agents/reviewer.md`, có cả trong thư mục app): đường dẫn app, file SPEC hoặc PLAN, danh sách file đổi. Không đưa lời giải thích của người viết. Nếu không có agent `reviewer`, dùng agent mới bất kỳ với cùng yêu cầu và dặn không sửa file. Không có công cụ Agent: nói rõ là không kiểm chứng độc lập được trong phiên này, gợi ý mở phiên mới; không tự đóng vai người kiểm tra.
4. Có thể chạy thêm lệnh có sẵn `/code-review` để tìm lỗi chung trong diff.
5. Nhận góp ý có kiểm chứng: với từng phát hiện, đọc lại code thật để xác nhận đúng hay sai; phát hiện sai thì ghi lý do bác bỏ; bỏ góp ý về văn phong hoặc thêm thứ SPEC không yêu cầu. Không sửa gì khi người dùng chưa đồng ý.
6. Ghi vào docs/BACKLOG.md mục "Biên bản review độc lập": ngày, phạm vi, kết quả lệnh ở bước 2, từng phát hiện (mức chặn/nặng/nhẹ, file:dòng, đúng/sai sau khi kiểm). Phát hiện chặn/nặng đã xác nhận vào danh sách lỗi mở.
7. Báo người dùng: số phát hiện theo mức, 3 điều quan trọng nhất, điều chưa kiểm được. Sửa xong phải chạy lại `/check-ac`.
