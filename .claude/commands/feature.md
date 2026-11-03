---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Lập kế hoạch cho một tính năng/thay đổi lớn trên app đã có rồi DỪNG chờ duyệt (ví dụ /feature APP-001 Đăng nhập bằng Google)
effort: high
---
Lập kế hoạch tính năng: $ARGUMENTS

1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). SPEC của app phải đã duyệt; chưa thì dừng, đề xuất `/spec`.
2. Đọc SPEC, BACKLOG, DECISIONS và phần code liên quan (tìm rộng thì để agent Explore làm) để biết thay đổi chạm vào đâu.
3. Phỏng vấn người dùng cho tới khi viết được tiêu chí: mỗi lần tối đa 3 câu, dạng lựa chọn có đề xuất; chỉ hỏi điều không suy ra được từ code.
4. Đưa 2–3 hướng làm, mỗi hướng một dòng ưu/nhược (công sức, rủi ro, ảnh hưởng dữ liệu/quyền thiết bị/chi phí), nêu hướng đề xuất. Chờ người dùng chọn.
5. Chạy `bash scripts/new-plan.sh <APP> "<tên tính năng>"` rồi điền PLAN theo hướng đã chọn. Mục "Các bước" chia nhỏ: mỗi bước một kết quả kiểm chứng được, ghi file sẽ đụng, AC liên quan và lệnh/test chứng minh. Tính năng chưa có trong SPEC: đề xuất F-xx mới để duyệt cùng PLAN. Quyền thiết bị mới, dịch vụ trả phí, gửi dữ liệu ra ngoài: nêu rõ để người dùng quyết.
6. Tự soát PLAN trước khi đưa: AC nào chưa có bước làm hoặc cách kiểm chứng; chỗ còn để trống; chỗ mâu thuẫn với SPEC/DECISIONS; bước nào quá lớn để làm trong một giai đoạn. Sửa rồi mới đưa.
7. DỪNG: tóm tắt PLAN vài dòng, hỏi duyệt hay chỉnh. Chỉ khi người dùng duyệt rõ ràng: đổi `Đã duyệt: chưa` thành `Đã duyệt: <YYYY-MM-DD>`; tạo nhánh riêng trong repo của app `git switch -c feature/PLAN-NNN` (nếu repo có commit; không push); chép các bước vào docs/BACKLOG.md thành giai đoạn mới ghi rõ PLAN-NNN và AC; đề xuất `/phase <APP>`.
8. Khi mọi giai đoạn của PLAN đã xong: chạy `/check-ac`, rồi `/spec-review <APP> PLAN-NNN`. Sau đó hỏi người dùng chọn: gộp nhánh vào nhánh chính (local), giữ nhánh lại, hay bỏ. Chỉ push khi người dùng cho phép rõ ràng. Cập nhật CHANGELOG và "Điểm dừng".
