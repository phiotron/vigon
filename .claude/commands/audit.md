---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Đánh giá app (chỉ đọc) và viết báo cáo có bằng chứng (ví dụ /audit APP-001)
effort: high
---
Đánh giá app: $ARGUMENTS

Audit CHỈ ĐỌC code của app; không sửa code, không cài thư viện, không push. Ghi duy nhất vào docs/ của app.
1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). Đọc `CLAUDE.original.md`, README và các file `*.original.md` của app (nếu có) để hiểu ý định của người viết trước.
2. Chạy `bash scripts/audit-app.sh <APP>`; ghi lại đường dẫn báo cáo vừa tạo (docs/audits/AUDIT-<ngày>.md). Mục 2 "Dữ kiện tự động" là số liệu do script đo: giữ nguyên, không sửa tay.
3. Hỏi người dùng MỘT lần (một câu, các lựa chọn gộp) về quyền cho phiên này: được chạy lint/typecheck/test/build không; được cài thư viện/gọi mạng (ví dụ `npm install`, `npm audit`) không; được đọc giá trị trong file `.env` không. Mặc định khi không rõ: CHỈ ĐỌC, không chạy gì, không cài, không đọc giá trị `.env`. Ghi quyền đã cấp vào mục 0 của báo cáo. Nếu phiên không có người (chạy lịch): dùng mặc định và nói rõ.
4. Dùng skill `project-map` (chế độ tổng quan; chi tiết nếu người dùng yêu cầu) để hiểu code ngoài vào trong: README, manifest/phụ thuộc, điểm vào, điều hướng, rồi theo từng tính năng. Kết quả của skill nằm ở docs/project-map/ trong thư mục app. Quy tắc "trích dẫn hoặc đánh dấu" của skill áp dụng cho cả báo cáo: mọi khẳng định có `file:dòng`, hoặc `[suy luận]`, hoặc `[chưa rõ]`.
5. Mục 2.6 (dấu hiệu bí mật): mở từng vị trí `file:dòng` để phân loại dương tính thật hay giả. TUYỆT ĐỐI không chép giá trị bí mật vào báo cáo hay chat; chỉ ghi file:dòng, loại bí mật, và đề xuất thu hồi/xoay khóa nếu là thật. Với mục "File nhạy cảm ĐANG được git theo dõi": nêu rõ rủi ro lịch sử git.
6. Được phép chạy lệnh thì chạy THẬT lint/typecheck/test và ghi lệnh + kết quả; không được phép thì ghi "CHƯA kiểm chứng" ở mục 6.
7. Điền các mục 0, 1, 3–11. Mục 1 tóm tắt nêu rõ mức sẵn sàng, 3 rủi ro lớn nhất, 3 việc nên làm trước. Cuối báo cáo nêu rõ đã đọc gì và KHÔNG đọc gì.
8. Điền phần kiến trúc thực sự đã đọc vào docs/ARCHITECTURE.md của app (đánh dấu phần suy luận). Chép các việc đề xuất vào docs/BACKLOG.md mục "Ý tưởng ngoài SPEC" để người dùng quyết định; không tự làm.
9. Nếu trạng thái là `imported`: đề xuất `/spec <APP>` để viết SPEC dựa trên mục 4 (tính năng hiện có). Sửa code chỉ được sau khi SPEC được duyệt (hook cũng chặn việc này).
10. Báo cáo cho người dùng: đường dẫn báo cáo, 3 điểm chính, và những gì chưa kiểm chứng.
