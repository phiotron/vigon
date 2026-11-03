---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Kết thúc phiên làm việc, lưu lại mọi thứ (ví dụ /end APP-001)
model: sonnet
effort: low
---
Kết thúc phiên cho: $ARGUMENTS

1. Cập nhật CHANGELOG.md của app với những gì đã làm trong phiên (chỉ việc thật đã xảy ra).
2. Cập nhật docs/BACKLOG.md: đánh dấu việc xong, cập nhật "Việc kế tiếp" (tối đa 5), lỗi mới phát hiện, ý tưởng ngoài SPEC, biên bản thử máy thật nếu có.
3. Ghi quyết định mới vào docs/DECISIONS.md; cập nhật docs/ARCHITECTURE.md nếu cấu trúc đổi; ghi vào docs/PROMPTS.md nếu phát hiện cách giao việc hiệu quả hoặc chỗ Claude hay sai.
4. Cập nhật mục "Điểm dừng" trong CLAUDE.md của app (ngày hôm nay, đang làm dở, bước tiếp theo, đang chờ ai/cái gì, lưu ý dễ vấp): đây là thứ người dùng đọc đầu tiên khi quay lại sau nhiều tháng, viết cho người đã quên hết. Có điều đáng nhớ lẽ ra phải biết sớm hơn thì thêm vào "Ghi nhớ riêng". Nếu phiên này đã chạy build thành công hoặc phát hành: cập nhật docs/RUNBOOK.md (các bước chạy lại, tài khoản/dịch vụ, biến môi trường; không ghi mật khẩu) và chạy `bash scripts/snapshot-env.sh <APP>`.
5. Cập nhật "Giai đoạn hiện tại" và trạng thái bằng `bash scripts/set-status.sh <APP> <trạng thái> "<giai đoạn>"` nếu đổi.
6. Chạy `bash scripts/refresh-registry.sh <APP>` (làm mới ngày cập nhật của app này). Commit local (không push). Chạy `bash scripts/check.sh --app <APP>` (nhanh) và báo kết quả.
7. Nếu phiên này vừa qua một mốc (xong một giai đoạn, thử máy thật, đổi sang testing/released/paused/abandoned) và RETROSPECTIVE.md còn trống (`{{`): KHÔNG chỉ đề xuất. Tự soạn NHÁP RETROSPECTIVE.md từ dữ kiện thật trong CHANGELOG, BACKLOG, DECISIONS, PROMPTS, rồi hỏi người dùng tối đa 3 câu gọn về phần chỉ họ biết (thời gian thực tế, điều bất ngờ). Người dùng chỉ cần sửa nháp, không phải viết từ đầu; nếu họ bận thì để nháp đó trong file và ghi rõ "(nháp, chưa được người dùng xác nhận)". Sau đó gợi ý `/lesson` cho các ứng viên bài học.
Cuối cùng nói một dòng việc đầu tiên của phiên sau.
