---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Khôi phục và nâng cấp app đã ngủ lâu (ví dụ /revive APP-014)
effort: high
---
Khôi phục app: $ARGUMENTS

Mục tiêu: người dùng đã quên app này; đưa nó về trạng thái hiểu được, dựng lại được và có kế hoạch nâng cấp được duyệt. KHÔNG sửa code ở lệnh này. KHÔNG tự nâng cấp.
1. Xác định app (CLAUDE.md gốc, mục "Bắt đầu mỗi phiên"). Đọc mục "Điểm dừng" trong CLAUDE.md của app TRƯỚC, rồi SPEC, ARCHITECTURE, RUNBOOK, DECISIONS, BACKLOG, CHANGELOG, các báo cáo audit/revive cũ. Nói lại cho người dùng bằng 5 dòng: app làm gì, lần cuối làm gì, đang dở gì, ngủ bao lâu.
2. Chạy `bash scripts/revive-app.sh <APP>`; ghi lại đường dẫn báo cáo. Mục 2 "Dữ kiện tự động" giữ nguyên.
3. Hỏi người dùng MỘT lần (một câu, gộp lựa chọn): có được cài thư viện/gọi mạng, chạy lint/typecheck/test/build, đọc giá trị `.env` không. Mặc định khi không rõ hoặc không có người: CHỈ ĐỌC. Ghi quyền vào mục 0.
4. Được phép: làm baseline mục 3 theo đúng RUNBOOK mục 1 (nếu thiếu thì theo lệnh trong CLAUDE.md), cài sạch rồi lint, typecheck, test, build; ghi lệnh, thời gian, kết quả THẬT từng bước. Lỗi thì dùng skill `systematic-debugging` để tìm nguyên nhân gốc, chỉ để GHI NHẬN nguyên nhân, chưa sửa. Không được phép thì ghi "CHƯA kiểm chứng".
5. Mục 4: đối chiếu tài liệu với code (dùng `/audit` hoặc skill `project-map` nếu cần); liệt kê chỗ lệch kèm bằng chứng; sửa tài liệu cho đúng thực tế (chỉ tài liệu).
6. Mục 5: nền tảng và store thay đổi theo thời gian nên PHẢI tra lại bằng WebSearch/WebFetch trang chính thức (Google Play, App Store, tài liệu của framework đang dùng): mức API/SDK tối thiểu hiện hành, tình trạng hỗ trợ phiên bản framework hiện dùng, chính sách ảnh hưởng tới app. Ghi ngày tra cứu và URL cho từng khẳng định; không dùng trí nhớ. Nếu được phép chạy: `npm outdated` và `npm audit`, ghi kết quả thật.
7. Mục 6: đưa danh sách hạ tầng cần người dùng xác nhận (khóa ký, tài khoản store, dịch vụ ngoài, tên miền, kho từ xa). Claude không tự kiểm tra được; hỏi và ghi câu trả lời.
8. Điền mục 1, 7, 8, 9. Kết luận mức nâng cấp (nhỏ/vừa/lớn) CHỈ dựa trên bằng chứng ở mục 3–5. Đề xuất: nâng cấp / giữ nguyên / `paused` / `abandoned`.
9. Nếu người dùng chọn nâng cấp: `bash scripts/new-plan.sh <APP> "Nâng cấp ..."`, điền PLAN (nâng từng bậc nếu framework khuyến cáo, mỗi bước kiểm chứng được), DỪNG chờ duyệt. Chỉ khi PLAN được duyệt mới đổi trạng thái bằng `bash scripts/set-status.sh <APP> maintenance "Nâng cấp theo PLAN-NNN"` và làm bằng `/phase`.
10. Cập nhật RUNBOOK (các bước chạy lại đã kiểm chứng, sự cố đã gặp, `bash scripts/snapshot-env.sh <APP>`) và mục "Điểm dừng". Kết thúc bằng `/end`.
