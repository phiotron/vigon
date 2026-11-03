# audits — Báo cáo đánh giá app

Mỗi lần đánh giá (đặc biệt khi tiếp nhận app người khác viết) tạo một báo cáo `AUDIT-<ngày>.md` ở đây.

- Tạo: `/audit <APP>` hoặc `bash scripts/audit-app.sh <APP>`. Script tự đo các dữ kiện khách quan (số file, dòng code, test, CI, git, quyền, dấu hiệu bí mật) và đưa vào báo cáo; phần nhận định do người/Claude điền dựa trên bằng chứng.
- Quy tắc: mọi nhận định phải có bằng chứng (`file:dòng` hoặc lệnh đã chạy kèm kết quả), hoặc đánh dấu `[suy luận]` / `[chưa rõ]`.
- Audit CHỈ ĐỌC: không sửa code của app. Việc nên làm đưa vào `../BACKLOG.md` mục "Ý tưởng ngoài SPEC" để người dùng quyết định.
- Báo cáo cũ giữ lại làm lịch sử; audit mới tạo file mới.
