# TESTING — Ví Gọn (APP-001)

## Nguyên tắc
- Mỗi AC trong SPEC phải được kiểm chứng bằng ĐÚNG MỘT trong hai cách: test tự động, hoặc kiểm tra tay có ghi biên bản trong BACKLOG. Ghi rõ ở cột "Cách kiểm chứng" của SPEC.
- Logic nghiệp vụ, xử lý dữ liệu, định dạng, tính toán: BẮT BUỘC có test tự động.
- Lỗi đã sửa: nếu khả thi, thêm test chặn lỗi quay lại trước khi coi là xong.
- Không báo "test đạt" khi chưa chạy lệnh test trong phiên và đọc kết quả.

## Các tầng
| Tầng | Kiểm cái gì | Công cụ | Khi nào chạy |
|------|-------------|---------|--------------|
| Lint + typecheck | Lỗi cú pháp, kiểu | `flutter analyze` | Mỗi giai đoạn, mỗi commit (CI) |
| Unit | Hàm, logic | `flutter test` (`test/data/`) | Mỗi giai đoạn |
| Component/màn hình | Giao diện chính hoạt động đúng, accessibility | `flutter test` (`test/features/`, gồm `g6_accessibility_test`) | Mỗi giai đoạn có UI |
| Tay trên máy thật | Cảm ứng, quyền, offline, hiệu năng, bàn phím, xoay màn hình | Người dùng | Cuối mỗi giai đoạn (Cổng 3) và trước phát hành |

## Ma trận thử máy thật (tối thiểu trước phát hành)
- [ ] Ít nhất 1 máy Android thật (ghi đời máy, phiên bản)
- [ ] Ít nhất 1 máy iOS thật nếu SPEC có iOS
- [ ] Màn hình nhỏ nhất theo SPEC
- [ ] Mất mạng giữa chừng; mạng yếu
- [ ] Từ chối từng quyền thiết bị; thu hồi quyền khi đang dùng
- [ ] Thoát app và mở lại (trạng thái, dữ liệu còn đúng)
- [ ] Có cuộc gọi/thông báo chen ngang
- [ ] Chạy lâu 10–15 phút: không giật, không nóng máy bất thường

## Bảng truy vết: mỗi AC phải có bằng chứng kiểm chứng
Cập nhật khi viết test hoặc khi thử tay. Một AC chưa có dòng ở đây hoặc cột "Kết quả lần cuối" trống nghĩa là CHƯA được kiểm chứng.
| AC (SPEC) | Cách | Test hoặc biên bản (tên test / mục trong BACKLOG) | Kết quả lần cuối (ngày, lệnh hoặc máy, đạt/hỏng) |
|-----------|------|----------------------------------------------------|-----------------------------------------------------|
| AC-01 | tự động / tay | `entry_flow_test`; đo 300 ms trên máy: CHƯA | 2026-11-03 flutter test đạt |
| AC-37 | tự động + tay | `g6_accessibility_test` (androidTapTargetGuideline, mọi màn, sáng/tối, 100%/200%); bàn phím và nút −/+ ở nửa dưới: biên bản máy thật G2 | 2026-11-03 flutter test 98/98 đạt |
| AC-38 | tự động + tay | `g6_accessibility_test` (không lỗi vẽ hay tràn ở cỡ chữ 200%, màn 360×800 dp); máy thật ở cỡ chữ lớn nhất: CHƯA (cần người dùng đổi cỡ chữ hệ thống) | 2026-11-03 flutter test đạt |
| AC-39 | tự động + tay | `g6_accessibility_test` (labeledTapTargetGuideline; icon danh mục có hành động chạm cho TalkBack); máy thật: uiautomator mọi nút bấm được có nhãn (biên bản G6); bật TalkBack thật: CHƯA | 2026-11-03 đạt (trừ TalkBack thật) |
| AC-40 | tự động | `g6_accessibility_test` (textContrastGuideline, sáng và tối); icon trắng trên màu danh mục đã chỉnh ở G3 | 2026-11-03 đạt |
| AC-41 | tự động + tay | `g6_accessibility_test` "màn Giới thiệu…"; máy thật: phiên bản, email mở Gmail có tiêu đề, trang giấy phép (biên bản G6); đường dẫn chính sách: CHƯA có | 2026-11-03 đạt (trừ đường dẫn) |
| AC-42 | tự động + tay | `backup_test`, `g5_lock_test`; máy thật biên bản G5 | 2026-11-03 đạt |
| AC-43 | tay (kiểm APK) | `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` | 2026-11-03 đạt (bản G6) |

## Yêu cầu phi chức năng (SPEC mục 5b): đo bằng gì
| Yêu cầu | Cách đo | Kết quả lần cuối |
|---------|---------|------------------|
| Mở nguội ≤ 2 s (trung vị 5 lần, release) | `adb shell am start -W` 5 lần (tới khung hình Android đầu) + `flutter run --profile --trace-startup` (tới khung hình Flutter đầu) | 2026-11-03 Galaxy A13: TotalTime 1098/633/648/633/606 ms, trung vị 633 ms; khung hình Flutter đầu 1,09 s sau khi engine chạy (1 lần đo). Đạt, nhưng mốc Flutter mới đo 1 lần |
| Lưu một khoản ≤ 200 ms | Chưa có cách đo; đề xuất: đo trong bản profile bằng Timeline | CHƯA |
| Cuộn 5.000 khoản không khung hình > 32 ms | Flutter DevTools, bản profile | CHƯA |
| Không tác vụ nền | `dumpsys activity services`, `dumpsys jobscheduler` | 2026-11-03: 0 service, không job; đạt |
| 15 phút dùng ≤ 3% pin | `dumpsys batterystats` | CHƯA |
| Bộ nhớ ≤ 200 MB với 10.000 khoản | `dumpsys meminfo` sau khi khôi phục file 10.000 khoản | 2026-11-03: 65 MB PSS khi app ở nền, CHƯA xác nhận đã nạp 10.000 khoản (máy đang có app khác dùng) |
| APK một kiến trúc (arm64) ≤ 25 MB | `flutter build apk --release --split-per-abi` | 2026-11-03: arm64 21,3 MB; đạt |
| Toàn vẹn dữ liệu khi tắt đột ngột | Ghi trong giao dịch (D-004); `force-stop` ngay sau Lưu | Một phần: mở nguội lại nhiều lần trong biên bản G4 không mất khoản; chưa thử tắt ngay sau Lưu |
| Không crash ≥ 99,5% | Android vitals, sau phát hành | CHƯA (sau phát hành) |

## Lệnh
Xem mục "Lệnh" trong `CLAUDE.md` của app (một nơi duy nhất).
