---
# demochung-sync (chép từ D:/DemoChung/.claude/commands; sửa ở gốc rồi chạy scripts/sync-app-commands.sh)
description: Chuẩn bị phát hành app (checklist + rà bảo mật, ví dụ /release APP-001)
effort: high
---
Chuẩn bị phát hành: $ARGUMENTS

1. Xác định app. Kiểm tra trạng thái là `testing` (đã thử máy thật, Cổng 3). Nếu chưa: dừng và nêu cần làm gì.
2. Chạy `/check-ac` và đọc kết quả thật.
3. Đi từng mục checklists/release.md và docs/SECURITY.md của app: điền đủ SECURITY.md (quyền, dữ liệu, bí mật), RELEASE.md (định danh, nơi cất khóa ký, hồ sơ store). Với mỗi mục đánh dấu đạt/không đạt kèm bằng chứng (lệnh đã chạy hoặc file đã kiểm tra). Mục cần người dùng làm (thử máy thật, nộp store, cung cấp thông tin tài khoản) thì liệt kê rõ.
4. Kiểm tra bí mật: `git status`, `.gitignore`, và tìm thử khóa trong lịch sử git; báo kết quả thật.
5. KHÔNG nộp store, KHÔNG push, KHÔNG đụng keystore. Chỉ chuẩn bị và báo cáo.
6. Khi mọi mục đạt và người dùng duyệt rõ ràng: `bash scripts/set-status.sh <APP> released`. Sau đó đề xuất /retro.
Bắt buộc thêm (tiêu chuẩn bán app): mở `docs/COMPLIANCE.md`; mọi dòng áp dụng phải "đạt" kèm bằng chứng kiểm được (file:dòng, lệnh đã chạy, ảnh chụp, đường dẫn) và ngày. Dòng còn "chưa" là lý do KHÔNG phát hành: liệt kê cho người dùng. Kiểm lại trang Apple "Upcoming requirements" và bảng hạn chót của Google (WebFetch, ghi ngày) vì đổi theo quý; tài liệu `shared/standards/` cũ hơn 3 tháng thì kiểm lại các mốc ở bảng đầu. Nhắc người dùng: đây không phải tư vấn pháp lý, cần luật sư địa phương trước khi mở bán ở từng nước.
