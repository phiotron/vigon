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
| AC-01 | tự động + đo | `entry_flow_test`; `integration_test/perf_test.dart`: từ chạm "−" tới khung hình đầu có bàn phím, 5 lần | 2026-11-03 Galaxy A13 bản profile: 84/80/82/80/81 ms; đạt |
| AC-04 | tự động | `g6_flows_test` (ghi chú cắt ở 200 ký tự, chọn tài khoản thứ hai, chọn ngày trong hộp chọn ngày) | 2026-11-04 flutter test 116/116 đạt |
| AC-10 | tự động | `g6_flows_test` (kỳ Tuần bắt đầu Thứ Hai, kỳ sau, kỳ Năm); `period_test`; "Khoảng tùy chọn" chưa có test giao diện | 2026-11-04 đạt (trừ khoảng tùy chọn) |
| AC-16, AC-17 | tự động | `g3_screens_test` (thêm danh mục), `g6_flows_test` (đổi tên, màu, icon; xóa danh mục và chuyển khoản sang danh mục khác) | 2026-11-04 đạt |
| AC-20 | tự động | `g6_flows_test` (lọc theo Thẻ rồi bỏ lọc, số dư đổi đúng) | 2026-11-04 đạt |
| AC-26 | tự động | `g6_flows_test` (số 0 bị từ chối, đặt 1.000.000, chạm thanh để bỏ), `g4_screens_test` | 2026-11-04 đạt |
| AC-08 | tự động | `summary_test` (6, 7, 12, 13 danh mục bằng nhau và ca khoản rất nhỏ/lớn: phần trăm hiển thị cộng đúng 100,0) | 2026-11-03 flutter test 107/107 đạt |
| AC-12 | tự động | `g6_accessibility_test` "đổi ngày đầu tuần khi đang xem Tuần" | 2026-11-03 đạt |
| AC-32 | tự động + tay | `g5_lock_test` (kể cả bộ nhớ an toàn lỗi vẫn hiện màn khóa); biên bản G5 | 2026-11-03 đạt |
| AC-37 | tự động + tay | `g6_accessibility_test` (androidTapTargetGuideline, mọi màn, sáng/tối, 100%/200%); bàn phím và nút −/+ ở nửa dưới: biên bản máy thật G2 | 2026-11-03 flutter test 98/98 đạt |
| AC-38 | tự động + tay | `g6_accessibility_test` (không lỗi vẽ hay tràn ở cỡ chữ 200%, màn 360×800 dp); máy thật ở cỡ chữ lớn nhất: CHƯA (cần người dùng đổi cỡ chữ hệ thống) | 2026-11-03 flutter test đạt |
| AC-39 | tự động + tay | `g6_accessibility_test` (labeledTapTargetGuideline; icon danh mục có hành động chạm cho TalkBack); máy thật: uiautomator mọi nút bấm được có nhãn (biên bản G6); bật TalkBack thật: CHƯA | 2026-11-03 đạt (trừ TalkBack thật) |
| AC-40 | tự động | `g6_accessibility_test` (textContrastGuideline, sáng và tối); icon trắng trên màu danh mục đã chỉnh ở G3 | 2026-11-03 đạt |
| AC-41 | tự động + tay | `g6_accessibility_test` "màn Giới thiệu…"; máy thật: phiên bản, email mở Gmail có tiêu đề, trang giấy phép (biên bản G6); đường dẫn chính sách: CHƯA có | 2026-11-03 đạt (trừ đường dẫn) |
| AC-42 | tự động + tay | `backup_test`, `g5_lock_test`; máy thật biên bản G5 | 2026-11-03 đạt |
| AC-43 | tự động + tay | `test/manifest_test.dart` (manifest nguồn không có `uses-permission`, `allowBackup=false`, chỉ dọc; pubspec không có SDK mạng/quảng cáo); `aapt2 dump permissions` trên APK release | 2026-11-03 đạt (bản sau BUG-005..BUG-010) |

## Yêu cầu phi chức năng (SPEC mục 5b): đo bằng gì
| Yêu cầu | Cách đo | Kết quả lần cuối |
|---------|---------|------------------|
| Mở nguội ≤ 2 s (trung vị 5 lần, release) | `adb shell am start -W` 5 lần (tới khung hình Android đầu) + `flutter run --profile --trace-startup` (tới khung hình Flutter đầu) | 2026-11-03 Galaxy A13: TotalTime 1098/633/648/633/606 ms, trung vị 633 ms; khung hình Flutter đầu 1,09 s sau khi engine chạy (1 lần đo). Đạt, nhưng mốc Flutter mới đo 1 lần |
| Lưu một khoản ≤ 200 ms | `integration_test/perf_test.dart` (bản profile, SQLite file thật): thời gian từ chạm Lưu tới khi khoản nằm trong cơ sở dữ liệu, 5 lần | 2026-11-03 Galaxy A13, bản profile: 169/160/147/146/148 ms; đạt |
| Cuộn 5.000 khoản không khung hình > 32 ms | `integration_test/perf_test.dart`: `watchPerformance` khi mở nhóm 5.000 khoản và cuộn | 2026-11-03 Galaxy A13, bản profile: cuộn 15 lần, khung hình dựng tệ nhất 25,4 ms, raster tệ nhất 12,3 ms; đạt. Mở nhóm 5.000 khoản: 1 khung hình dựng 46,8 ms (vượt 32 ms một lần lúc mở). Trước khi sửa (`ExpansionTile` dựng hết 5.000 dòng) khung hình đó là 13.398 ms; đã đổi sang danh sách dựng lười |
| Không tác vụ nền | `dumpsys activity services`, `dumpsys jobscheduler` | 2026-11-03: 0 service, không job; đạt |
| 15 phút dùng ≤ 3% pin | `dumpsys batterystats` | CHƯA |
| Bộ nhớ ≤ 200 MB với 10.000 khoản | `dumpsys meminfo` sau khi khôi phục file 10.000 khoản | 2026-11-03 Galaxy A13, bản release, kỳ "Tất cả" với 10.000 khoản: màn chính 73 MB PSS; màn Các khoản mở nhóm 1.000 khoản và cuộn 20 lần: 151 MB PSS. Đạt |
| APK một kiến trúc (arm64) ≤ 25 MB | `flutter build apk --release --split-per-abi` | 2026-11-03: arm64 21,3 MB; đạt |
| Toàn vẹn dữ liệu khi tắt đột ngột | Ghi trong giao dịch (D-004); `adb shell "input tap <Lưu>; am force-stop"` trong một lệnh | 2026-11-03 Galaxy A13 bản release: 6 lần Lưu rồi tắt ngay, mở lại cả 6 khoản đều còn (12.345 + 5 × 1), không hỏng dữ liệu; đạt |
| Không crash ≥ 99,5% | Android vitals, sau phát hành | CHƯA (sau phát hành) |

## Lệnh
Xem mục "Lệnh" trong `CLAUDE.md` của app (một nơi duy nhất).
