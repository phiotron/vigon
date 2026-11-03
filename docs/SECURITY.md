# SECURITY & PRIVACY — Ví Gọn (APP-001)

Điền trước khi phát hành. Là đầu vào cho chính sách quyền riêng tư (`docs/legal/privacy-policy.md`) và biểu mẫu khai báo của store. Tự kiểm MASVS: `docs/security/MASVS-SELF-CHECK.md`. Cập nhật 2026-11-03 (G6).

## Quyền thiết bị
| Quyền | Dùng để làm gì | Xin khi nào | Nếu bị từ chối thì sao |
|-------|----------------|-------------|------------------------|
| (không có) | App không xin quyền nào; sao lưu dùng bảng chia sẻ, khôi phục dùng trình chọn file của hệ thống | Không | Không áp dụng |

`aapt2 dump permissions` bản release 2026-11-03: chỉ có `com.phiotron.vigon.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (AndroidX tự thêm, nội bộ app, không hiện với người dùng).

## Dữ liệu thu thập và lưu trữ (bản đồ dữ liệu, COMPLIANCE D-01)
Nhà phát triển KHÔNG nhận dữ liệu nào. Mọi xử lý diễn ra trên máy người dùng.
| Dữ liệu | Lưu ở đâu | Mã hóa? | Gửi đi đâu | Giữ bao lâu | Người dùng xóa được không |
|---------|-----------|---------|------------|-------------|---------------------------|
| Khoản thu chi, ghi chú, danh mục, tài khoản, ngân sách, khoản định kỳ, cài đặt | SQLite trong bộ nhớ riêng của app | Không (cách ly app của Android) | Không đi đâu; `allowBackup=false` | Tới khi người dùng xóa hoặc gỡ app | Có: sửa/xóa từng khoản, "Xóa toàn bộ dữ liệu", gỡ app |
| Muối và mã băm PIN | `flutter_secure_storage` (Android Keystore) | Có (Keystore) | Không | Tới khi tắt PIN, quên mã hoặc gỡ app | Có |
| File sao lưu `.vigon`, file CSV | Nơi người dùng tự chọn khi chia sẻ | Không | Do người dùng chọn | Do người dùng quyết | Có (ngoài app) |

Data safety (Play Console): "Không thu thập dữ liệu", "Không chia sẻ dữ liệu".

## Bí mật và khóa
- Khóa ký phát hành: CHƯA tạo (làm ở `/release`); khi tạo phải cất NGOÀI repo và sao lưu ngay (L-005).
- `.env`, `*.jks`, `*.keystore`, `key.properties` đã nằm trong `.gitignore` và `android/.gitignore`: [x] đã kiểm tra 2026-11-03
- Không có bí mật trong lịch sử git: [x] đã kiểm tra 2026-11-03 (`git log -p --all` tìm `storePassword|keyPassword|api_key|secret =|BEGIN PRIVATE`, không có kết quả)

## Tiếp nhận và xử lý lỗ hổng (COMPLIANCE S-05, D-08)
- Kênh: email `phamphuongphuong@gmail.com`, hiện trong app (Cài đặt → Giới thiệu → Báo lỗi bảo mật, mở sẵn email có tiêu đề) và trong chính sách quyền riêng tư mục 9, 11.
- Thủ tục: (1) xác nhận đã nhận trong 3 ngày làm việc; (2) tái hiện và đánh giá mức độ trong 7 ngày; (3) lỗi nghiêm trọng (lộ dữ liệu, vượt khóa PIN) thì phát hành bản sửa sớm nhất có thể và ghi BUG-xxx trong BACKLOG; (4) báo lại người báo khi đã sửa.
- Sự cố dữ liệu: nhà phát triển không giữ dữ liệu người dùng nên không có kho dữ liệu nào để rò rỉ; rủi ro còn lại là lỗi trong app làm lộ dữ liệu trên máy, xử lý theo thủ tục trên. Nếu bán ở EU và thuộc phạm vi CRA thì thêm cảnh báo sớm 24 giờ, thông báo 72 giờ (S-06, chờ luật sư).

## Rà soát trước phát hành
- [x] Mọi kết nối mạng dùng HTTPS: không áp dụng, app không kết nối mạng (không quyền INTERNET)
- [x] Dữ liệu nhạy cảm không nằm trong log: không có lệnh log trong `lib/` (2026-11-03)
- [x] Không lưu mật khẩu/token dạng thô trên máy: PIN chỉ lưu mã băm có muối trong Keystore (D-007)
- [x] Đầu vào người dùng được kiểm tra/làm sạch ở chỗ cần: số tiền > 0 (ràng buộc cơ sở dữ liệu), file khôi phục kiểm đủ trước khi ghi, CSV chặn chèn công thức (D-006)
- [ ] Thư viện bên thứ ba: đã chạy kiểm tra lỗ hổng (`osv-scanner --lockfile=pubspec.lock`) và xử lý mục nghiêm trọng: CHƯA, máy chưa có OSV-Scanner. SBOM đã có (`docs/sbom/vigon.cdx.json`, sinh bằng `python tool/make_sbom.py`)
- [ ] Chính sách quyền riêng tư đã viết và có đường dẫn công khai: đã viết (vi/en), CHƯA đăng; điền đường dẫn vào `lib/src/app_info.dart`
- [x] Khai báo dữ liệu trên store khớp với bảng ở trên: nội dung khai báo đã chốt ("không thu thập, không chia sẻ"); điền vào Play Console ở `/release`
