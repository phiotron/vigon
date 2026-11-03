---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Làm giai đoạn kế tiếp trong BACKLOG của app rồi dừng ở cổng (ví dụ /phase APP-001)
model: sonnet
---
Làm giai đoạn xây dựng kế tiếp cho: $ARGUMENTS

1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). Kiểm tra SPEC có `Đã duyệt: <ngày>`; nếu chưa: dừng, đề xuất /spec.
2. Lấy giai đoạn có trạng thái `doing`, hoặc `todo` đầu tiên trong docs/BACKLOG.md; đổi thành `doing`. Nếu giai đoạn thuộc một PLAN-NNN, kiểm tra PLAN đó có `Đã duyệt: <ngày>`; chưa thì dừng và đề xuất `/feature`. Chỉ làm giai đoạn này, không làm lan sang giai đoạn khác.
3. Điền lệnh trong CLAUDE.md của app nếu còn `{{`: chạy thử từng lệnh để chắc chắn đúng, rồi ghi lại. Không tự bịa lệnh.
4. Với mỗi việc có AC kiểm chứng tự động (logic, dữ liệu, tính toán, sửa lỗi): viết test trước, chạy và thấy nó HỎNG đúng lý do, rồi mới viết code tối thiểu cho test đạt; chạy lại thấy đạt. AC kiểm bằng tay (giao diện, cảm ứng, quyền): ghi bước thử cho người dùng; không thêm tính năng ngoài SPEC (ý tưởng mới → BACKLOG mục "Ý tưởng").
5. Gặp lỗi, test fail hoặc hành vi bất thường: dùng skill `systematic-debugging` (tái hiện, tìm nguyên nhân gốc rồi mới sửa, không đoán). Sửa 3 lần không được thì dừng và báo.
6. Xong việc: chạy `/check-ac`. Chỉ khi đạt mới đánh dấu giai đoạn `done`.
7. Cập nhật CHANGELOG.md, BACKLOG.md, ARCHITECTURE.md (nếu cấu trúc đổi), DECISIONS.md (nếu có quyết định), commit local theo shared/conventions/git-and-commits.md.
8. DỪNG ở cổng: nêu rõ người dùng cần thử gì trên điện thoại thật cho giai đoạn này và hỏi kết quả. Không tự sang giai đoạn kế tiếp trừ khi người dùng đã bảo làm liền.
Nhắc lại: quyền hỏi trước trong docs/PROCESS.md (quyền thiết bị mới, dịch vụ trả phí, đổi stack...).
