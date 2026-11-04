# Tự kiểm OWASP MASVS v2.1.0 — Ví Gọn (APP-001)

Bản 1.0.0 (1), Android, kiểm ngày 2026-11-03 bởi Claude (COMPLIANCE S-01). Tự kiểm, không phải kiểm thử xâm nhập độc lập. Mức nhắm tới: MASVS-L1 (app không có máy chủ, không tài khoản, dữ liệu chỉ trên máy).
Kết quả: **đạt** / **đạt có lưu ý** / **không áp dụng** / **chưa**.

| Nhóm | Kết quả | Bằng chứng và lưu ý |
|------|---------|---------------------|
| MASVS-STORAGE | đạt có lưu ý | Dữ liệu trong SQLite ở bộ nhớ riêng của app (`lib/src/data/database.dart`); `android:allowBackup="false"` (`android/app/src/main/AndroidManifest.xml:4`) nên không lên sao lưu đám mây của Android. Không có lệnh log nào trong `lib/` (grep `print`, `debugPrint`, `developer.log` rỗng). Lưu ý: cơ sở dữ liệu và file `.vigon` KHÔNG mã hóa (D-006, D-007); app nói rõ "File sao lưu không được mã hóa" ở Cài đặt và trong chính sách. Ảnh xem trước ở màn đa nhiệm: có công tắc "Che nội dung khi chuyển app" (`FLAG_SECURE`, F-22), mặc định tắt. |
| MASVS-CRYPTO | đạt có lưu ý | Chỉ dùng mật mã cho PIN: muối ngẫu nhiên 16 byte từ `Random.secure()`, SHA-256 lặp 20.000 vòng, so sánh thời gian hằng (`lib/src/data/pin_service.dart`); muối và mã băm nằm trong `flutter_secure_storage` (Android Keystore). Lưu ý: PIN 4 số chỉ có 10.000 khả năng, máy đã root dò hết rất nhanh (D-007); không quảng cáo là mã hóa dữ liệu. Từ 2026-11-04 có thêm mã hóa file sao lưu tùy chọn (D-012): AES-256-GCM, khóa từ PBKDF2-HMAC-SHA256 100.000 vòng với muối ngẫu nhiên, gói `cryptography` (Apache-2.0); mật khẩu không lưu; số vòng thấp hơn khuyến nghị OWASP vì Dart thuần trên máy yếu, ghi số vòng trong phong bì để nâng sau; mật khẩu NFD/NFC cho khóa khác nhau. |
| MASVS-AUTH | đạt | Không có tài khoản hay máy chủ. Khóa PIN cục bộ: khóa khi mở app và sau hơn 1 phút ở nền (AC-32, thử máy thật 2026-11-03), mã sai không mở được, quên mã chỉ có cách xóa dữ liệu qua 3 bước xác nhận (AC-34). |
| MASVS-NETWORK | không áp dụng | Bản release không có quyền INTERNET (`aapt2 dump permissions` 2026-11-03 chỉ có quyền nội bộ `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); không có mã gọi mạng trong `lib/`. Màn Giới thiệu chỉ mở trình duyệt hoặc app email bằng intent (`<queries>` trong manifest). |
| MASVS-PLATFORM | đạt | Không xin quyền nào. Chỉ `MainActivity` được exported (bắt buộc cho launcher). Không có WebView, không có deep link, không nhận intent dữ liệu từ app khác. Chia sẻ file qua bảng chia sẻ hệ thống, chọn file qua trình chọn hệ thống (AC-28, AC-29). Trình đọc màn hình đọc được mọi nút (AC-39). |
| MASVS-CODE | đạt có lưu ý | targetSdk 36, minSdk 24 (D-003). File sao lưu được kiểm định dạng, phiên bản, mã băm, khóa ngoại và số tiền trước khi ghi, ghi trong một giao dịch (`lib/src/data/backup.dart`, test `backup_test`). CSV chặn chèn công thức bằng dấu `'` (D-006). Phụ thuộc ghim trong `pubspec.lock`, SBOM ở `docs/sbom/vigon.cdx.json`. Lưu ý: chưa có công cụ quét lỗ hổng phụ thuộc (OSV) trên máy này; `sqlcipher_flutter_libs 0.7.0+eol` là phụ thuộc gián tiếp đã hết bảo trì (không dùng mã hóa SQLCipher, chỉ kéo theo từ `drift_flutter`), theo dõi khi nâng drift. |
| MASVS-RESILIENCE | không áp dụng ở L1 | App không có bí mật phía máy chủ hay nội dung trả phí để bảo vệ. Chưa bật `--obfuscate`; có thể bật khi build bản phát hành (cân nhắc ở `/release`). |
| MASVS-PRIVACY | đạt | Không thu thập dữ liệu, không SDK bên thứ ba, không quảng cáo, không định danh thiết bị (D-002). Người dùng tự xuất (sao lưu, CSV) và xóa toàn bộ dữ liệu trong app (AC-42). Chính sách quyền riêng tư vi/en: `docs/legal/privacy-policy.md` (chờ đăng công khai). |

## Việc còn lại trước khi phát hành
- Đăng chính sách và điền `AppInfo.privacyPolicyUrl` (`lib/src/app_info.dart`).
- Quét lỗ hổng phụ thuộc bằng OSV-Scanner (`osv-scanner --lockfile=pubspec.lock`) khi có công cụ.
- Kiểm `flutter_secure_storage` trên Keystore thật đã chạy được qua thử máy (đặt PIN, mở khóa) 2026-11-03.
