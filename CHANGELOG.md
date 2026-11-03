# CHANGELOG — Ví Gọn (APP-001)

## [Chưa phát hành]
- Khởi tạo từ template (2026-11-03)
- SPEC, BACKLOG, COMPLIANCE lập xong; SPEC duyệt (2026-11-03)
- G1: dự án Flutter 3.47.8 (com.phiotron.vigon, chỉ Android); SQLite qua drift với tài khoản và danh mục mặc định; cài đặt giao diện sáng/tối/hệ thống và ngôn ngữ vi/en; định dạng tiền theo ngôn ngữ; allowBackup=false, chỉ màn hình dọc (2026-11-03)
- G2: bàn phím số có phép tính, ghi khoản chi/thu tối đa 3 chạm, màn chính biểu đồ tròn và icon danh mục quanh vòng, số dư, danh sách gom theo danh mục, sửa và xóa có hoàn tác (2026-11-03)
- G3: chọn kỳ xem và vuốt đổi kỳ, ngày đầu tuần/tháng, quản lý danh mục (thêm, sửa, sắp xếp, xóa có chuyển khoản), nhiều tài khoản, chuyển tiền, chọn tiền tệ; màu danh mục đậm hơn cho đủ tương phản (2026-11-03)
- G4: khoản định kỳ (ngày, tuần, tháng, năm) tự tạo khi mở app, dừng, sửa, chạy lại; ngân sách tháng có thanh tiến độ và cảnh báo vượt (2026-11-03)
- G5: xuất và khôi phục bản sao lưu `.vigon` (có mã băm, khôi phục trong một giao dịch), xuất CSV, khóa PIN 4 số (băm có muối trong bộ nhớ an toàn, khóa lại sau 1 phút ở nền, quên mã thì xóa dữ liệu), xóa toàn bộ dữ liệu. Test tự động đạt (91). APK release chưa build được (BUG-002), chưa thử máy thật (2026-11-03)
- Sửa build APK release hỏng sau G5 (BUG-002): tắt Kotlin incremental; kiểm lại APK không có quyền INTERNET (2026-11-03)
- Thử G3, G4, G5 trên Galaxy A13 (Android 14): đạt; còn mở CSV bằng Excel (2026-11-03)
- Tài liệu: ARCHITECTURE, RUNBOOK, PROMPTS điền lần đầu; D-006, D-007; RETROSPECTIVE nháp (2026-11-03)
