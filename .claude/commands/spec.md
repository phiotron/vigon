---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Lập kế hoạch cho app (SPEC + BACKLOG) rồi DỪNG chờ người dùng duyệt (ví dụ /spec APP-001)
effort: high
---
Lập kế hoạch cho: $ARGUMENTS (nếu không có mã, hỏi hoặc dùng app người dùng đang nói tới).

Làm đúng giai đoạn 1 trong docs/PROCESS.md:
1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). Đọc lessons/LESSONS.md và shared/stacks/. Nếu app đang ở trạng thái `imported`: đọc báo cáo audit mới nhất (docs/audits/) và dùng mục 4 "Tính năng hiện có" làm căn cứ; SPEC mô tả cả phần đã có (đánh dấu "có sẵn", AC viết theo hành vi quan sát được) lẫn thay đổi người dùng muốn làm; chưa có audit thì đề xuất `/audit` trước.
2. Nếu ý tưởng còn mơ hồ: hỏi tối đa 3 câu gọn, kèm lựa chọn đề xuất cho mỗi câu. Không hỏi những gì có thể đề xuất mặc định hợp lý.
3. Điền docs/SPEC.md đầy đủ: vấn đề, người dùng, tính năng F-xx với tiêu chí chấp nhận AC-xx kiểm chứng được và cách kiểm chứng, ngoài phạm vi, ràng buộc mobile (offline, quyền, màn hình, hiệu năng), dữ liệu, rủi ro. Giữ dòng `Đã duyệt: chưa`.
4. Đề xuất stack từ shared/stacks/ (hiện có Expo/React Native và Flutter; nếu người dùng đã nói rõ stack thì dùng đúng stack đó, không tự đổi; nếu chưa nói, nêu ưu nhược của cả hai đối chiếu với SPEC, đề xuất một và hỏi) và ghi D-001 trong docs/DECISIONS.md (nêu phương án đã loại). Khi người dùng chốt stack, chạy `bash scripts/set-stack.sh <APP-NNN> "<stack>"` (cập nhật REGISTRY, mục "Stack" trong CLAUDE.md của app, và chép CI mẫu Flutter nếu là Flutter). Điền các dòng "Lệnh" trong CLAUDE.md của app từ hồ sơ stack, nhưng chỉ ghi lệnh đã chạy thử được.
5. Chia công việc thành các giai đoạn xây dựng nhỏ (G1, G2...) trong docs/BACKLOG.md, mỗi việc gắn AC; điền "Việc kế tiếp".
6. Cập nhật giai đoạn: `bash scripts/set-status.sh <APP> <trạng thái hiện tại> "Chờ duyệt SPEC"` (giữ nguyên `idea` hoặc `imported`; không hạ trạng thái).
7. DỪNG. Tóm tắt SPEC trong vài dòng và hỏi người dùng duyệt hay chỉnh. Chỉ khi người dùng duyệt rõ ràng mới đổi dòng thành `Đã duyệt: <YYYY-MM-DD hôm nay>` và chạy `bash scripts/set-status.sh <APP> building "G1"`. Tuyệt đối không viết code ở bước này.
Bắt buộc thêm: điền mục 1 của `docs/COMPLIANCE.md` (hỏi người dùng thị trường định bán nếu chưa rõ), đánh "không áp dụng" cho dòng không thuộc phạm vi, và đưa các dòng áp dụng cần xây tính năng vào SPEC (F-xx/AC-xx) và BACKLOG. Căn cứ duy nhất là `shared/standards/tieu-chuan-ban-app-toan-cau.md`; không tự thêm quy định không có trong đó.
