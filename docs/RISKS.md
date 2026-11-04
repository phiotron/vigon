# RISKS — Ví Gọn (A002-vigon)

Sổ rủi ro sống: xem lại mỗi khi chuyển giai đoạn và trước phát hành. Mức: Xác suất (thấp/vừa/cao) × Ảnh hưởng (nhẹ/nặng/chặn). Rủi ro đã xảy ra thì đổi trạng thái thành "đã xảy ra" và ghi bài học vào RETROSPECTIVE.

| Mã | Rủi ro | Xác suất | Ảnh hưởng | Cách giảm hoặc kế hoạch dự phòng | Người theo dõi | Trạng thái | Xem lại lần cuối |
|----|--------|----------|-----------|-----------------------------------|----------------|------------|------------------|
| R-01 | (ví dụ) Store từ chối bản nộp | | | | | mở | 2026-11-03 |

## Câu hỏi gợi ý (xóa câu không liên quan)
- Mất khóa ký hoặc tài khoản store thì sao? Bản sao lưu nằm ở đâu?
- Dịch vụ hoặc API bên thứ ba ngừng, đổi giá, đổi cách xác thực thì app còn chạy không?
- Nâng phiên bản framework hoặc SDK có làm hỏng thư viện native đang dùng không?
- Yêu cầu của store (mức API tối thiểu, chính sách dữ liệu) đổi thì ai phát hiện?
- Mất dữ liệu người dùng (xóa app, đổi máy, lỗi đồng bộ): có cách khôi phục không?
- Mạng yếu hoặc mất mạng ở chỗ người dùng thật sự dùng app: app xử lý ra sao?
- Có dữ liệu nhạy cảm hoặc quyền riêng tư cần khai báo mà chưa khai báo?
