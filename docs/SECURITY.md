# SECURITY & PRIVACY — Ví Gọn (APP-001)

Điền trước khi phát hành. Là đầu vào cho chính sách quyền riêng tư và biểu mẫu khai báo của store.

## Quyền thiết bị
| Quyền | Dùng để làm gì | Xin khi nào | Nếu bị từ chối thì sao |
|-------|----------------|-------------|------------------------|

## Dữ liệu thu thập và lưu trữ
| Dữ liệu | Lưu ở đâu | Mã hóa? | Gửi đi đâu | Giữ bao lâu | Người dùng xóa được không |
|---------|-----------|---------|------------|-------------|---------------------------|

## Bí mật và khóa
- Khóa API, keystore, chứng chỉ: nơi cất NGOÀI repo là: {{...}}
- `.env` đã nằm trong `.gitignore`: [ ] đã kiểm tra
- Không có bí mật trong lịch sử git: [ ] đã kiểm tra (`git log -p` tìm thử)

## Rà soát trước phát hành
- [ ] Mọi kết nối mạng dùng HTTPS
- [ ] Dữ liệu nhạy cảm không nằm trong log
- [ ] Không lưu mật khẩu/token dạng thô trên máy (dùng kho an toàn của hệ điều hành)
- [ ] Đầu vào người dùng được kiểm tra/làm sạch ở chỗ cần
- [ ] Thư viện bên thứ ba: đã chạy kiểm tra lỗ hổng ({{lệnh theo stack}}) và xử lý mục nghiêm trọng
- [ ] Chính sách quyền riêng tư đã viết và có đường dẫn công khai (nếu thu thập dữ liệu)
- [ ] Khai báo dữ liệu trên store khớp với bảng ở trên
