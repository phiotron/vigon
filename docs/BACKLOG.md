# BACKLOG — Ví Gọn (APP-001)

Nguồn sự thật về việc cần làm. Claude đọc đầu phiên, cập nhật cuối phiên (`/end`). Việc chưa xong ghi dạng "[ ] ..." đầu dòng sau dấu gạch; xong đổi thành "[x]". `scripts/status.sh` đếm các việc chưa xong.

## Giai đoạn xây dựng
Mỗi giai đoạn kết thúc bằng: `flutter analyze` sạch, `flutter test` đạt, thử trên máy Android thật và ghi biên bản (L-003), rồi dừng ở cổng chờ người dùng.

### G1 · Khởi tạo dự án và nền dữ liệu — trạng thái: done
- [x] Flutter 3.47.8 có sẵn ở C:/src/flutter; `flutter doctor` chạy; ghim phiên bản (D-003, không dùng FVM)
- [ ] Người dùng cài Android SDK Command-line Tools trong Android Studio và chạy `flutter doctor --android-licenses` (chấp nhận giấy phép là việc của người dùng)
- [x] `flutter create` (com.phiotron.vigon, chỉ Android), không ghi đè tài liệu; mục "Lệnh" trong CLAUDE.md đã điền bằng lệnh chạy được
- [x] Chọn thư viện và ghi D-003, D-004, D-005 (Riverpod, go_router, drift; lưu trữ an toàn để G5)
- [x] Lớp dữ liệu: bảng khoản ghi, danh mục, tài khoản, chuỗi định kỳ, cài đặt; tiền số nguyên; ràng buộc số tiền > 0 và khóa ngoại (AC-05 mức dữ liệu, AC-22)
- [x] Danh mục và tài khoản mặc định khi mở lần đầu (AC-15, AC-18): test đạt
- [x] Khung đa ngôn ngữ vi/en và giao diện sáng/tối/theo hệ thống (AC-35, AC-36): widget test đạt; CHƯA thử tay trên máy thật
- [x] `allowBackup=false`, chỉ màn hình dọc; APK release không có quyền INTERNET (AC-43): kiểm bằng `aapt2 dump` ngày 2026-11-03
- [ ] CI `.github/workflows/ci.yml` đã ghim Flutter 3.47.8 nhưng CHƯA chạy (repo chưa có remote)
- [x] Thử trên máy Android thật: mở app, đổi giao diện, đổi ngôn ngữ, Back, giữ cài đặt sau khi tắt app (biên bản 2026-11-03)
- [ ] Xoay máy thật khi bật tự xoay: app phải giữ dọc (cần người dùng xoay tay)
- [ ] Sửa ở G6: nút "Theo hệ thống" trong Cài đặt bị xuống 2 dòng ở cỡ chữ mặc định, sẽ tệ hơn ở cỡ chữ 200% (AC-38)

### G2 · Ghi khoản và màn chính — trạng thái: done
- [x] Màn nhập số tiền với bàn phím số có phép tính (AC-01 tới AC-05): test `calculator_test`, `entry_flow_test`; thử máy thật 2026-11-03
- [x] Màn chính: biểu đồ tròn, tổng thu/chi/số dư, icon danh mục quanh biểu đồ, trạng thái trống (AC-06, AC-07, AC-09): test `summary_test`, `entry_flow_test`; thử máy thật
- [x] Danh sách khoản gom theo danh mục, phần trăm (AC-08): test `summary_test`
- [x] Sửa, xóa có hoàn tác (AC-13, AC-14): test `entry_repository_test`, `entry_flow_test`
- [ ] Đo AC-01 (mở màn nhập trong 300 ms) bằng đồng hồ trên máy thật: CHƯA đo

### G3 · Kỳ xem, danh mục, tài khoản, tiền tệ — trạng thái: done (chờ thử máy thật)
- [x] Chọn kỳ, vuốt chuyển kỳ, cài đặt đầu tuần/đầu tháng (AC-10 tới AC-12): test `period_test`, `g3_repositories_test`; vuốt ngang (AC-11) CHƯA thử tay
- [x] Quản lý danh mục: thêm, sửa, sắp xếp, xóa có chuyển khoản (AC-16, AC-17): test `g3_repositories_test`, `g3_screens_test`
- [x] Tài khoản, chuyển tiền, lọc theo tài khoản (AC-18 tới AC-20): test `g3_repositories_test`, `g3_screens_test`
- [x] Tiền tệ theo vùng và định dạng số (AC-21, AC-22): test `g3_repositories_test`, `money_test`
- [x] Widget test chạy ở màn 360×800 dp; đã sửa tràn 13 px ở màn Chuyển tiền
- [ ] Thử tay trên máy thật: vuốt đổi kỳ, kéo sắp xếp danh mục, chuyển tiền

### G4 · Khoản định kỳ và ngân sách — trạng thái: todo
- [ ] Chuỗi định kỳ, tự tạo khoản khi mở app, không trùng (AC-23 tới AC-25)
- [ ] Ngân sách tháng và thanh tiến độ (AC-26, AC-27)

### G5 · Sao lưu, khóa PIN, dữ liệu — trạng thái: todo
- [ ] Xuất/khôi phục file `.vigon`, xuất CSV (AC-28 tới AC-30)
- [ ] Khóa PIN, khóa lại sau 1 phút ở nền, quên mã (AC-31 tới AC-34)
- [ ] Xóa toàn bộ dữ liệu (AC-42)

### G6 · Khả năng tiếp cận, pháp lý, chuẩn bị phát hành — trạng thái: todo
- [ ] Rà accessibility: vùng chạm, cỡ chữ 200%, TalkBack, tương phản (AC-37 tới AC-40)
- [ ] Màn Giới thiệu: chính sách quyền riêng tư, email báo lỗi bảo mật, giấy phép nguồn mở (AC-41)
- [ ] Viết chính sách quyền riêng tư (vi/en) và đăng ở một trang công khai
- [ ] Đo NFR (mục 5b SPEC) và ghi vào `docs/TESTING.md`
- [ ] SBOM, tự kiểm MASVS, hoàn tất các dòng áp dụng trong `docs/COMPLIANCE.md`
- [ ] Closed test 12 người trong 14 ngày (P-09), rồi `/release`

## Việc kế tiếp (tối đa 5, theo thứ tự)
1. Câu còn mở (SPEC đã duyệt 2026-11-03, chưa trả lời): phát hành dưới tên cá nhân hay công ty (miễn EAA); Play Age Signals (D-12); luật sư xác nhận CRA (S-06) và DPIA VN (D-07) trước khi mở bán
2. Thử G1 trên máy Android thật và ghi biên bản (L-003)
3. Cài Command-line Tools và chấp nhận giấy phép SDK (người dùng)
4. G2: màn nhập số tiền và màn chính

## Lỗi đã biết (đang mở)
Mỗi lỗi: BUG-xxx · mô tả · cách tái hiện · mức độ (chặn / nặng / nhẹ) · cách tạm tránh.
(Chưa có)

## Lỗi đã sửa đáng nhớ (nguồn cho bài học)
Mỗi lỗi: BUG-xxx · nguyên nhân gốc · cách sửa · làm sao tránh lần sau.
- BUG-001 · App crash ngay khi mở trên Galaxy A13: "Could not find libflutter.so, looked for armeabi-v7a". Nguyên nhân gốc: APK build với `--target-platform android-arm64`, nhưng máy có chip 64-bit lại chạy hệ điều hành chỉ 32-bit (`ro.product.cpu.abilist64` rỗng). Cách sửa: build APK đủ kiến trúc (`flutter build apk --release`); bản phát hành dùng AAB thì Play tự chia theo kiến trúc. Tránh lần sau: không build APK một kiến trúc để thử; kiểm `adb shell getprop ro.product.cpu.abilist` của máy thử. Test trên máy tính và giả lập không bắt được lỗi này (L-003).

## Ý tưởng ngoài SPEC (chưa được duyệt, KHÔNG tự làm)
- Bản iOS
- Đồng bộ/sao lưu lên Google Drive, Dropbox
- Nhiều tiền tệ và quy đổi tỉ giá
- Ngân sách theo danh mục; nhắc ghi chép bằng thông báo
- Widget màn hình chính; mở khóa bằng vân tay
- Mã hóa file sao lưu bằng mật khẩu
- Gói Pro hoặc nguồn thu khác

## Biên bản thử máy thật
Mỗi lần thử: ngày · máy và phiên bản hệ điều hành · bản app · đã thử gì · kết quả · lỗi phát hiện.
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G2, APK release · màn chính có 10 icon danh mục quanh vòng tròn, nút −/+ ở nửa dưới; bấm − nhập 120+35, Choose category, Food → lưu ₫155, biểu đồ 100% Food, số dư -₫155 (đọc bằng uiautomator). Lần chạm − đầu tiên mở nhầm "New income", chạm lại 2 lần đều đúng; lúc đó người dùng cũng đang cầm máy (bảng thông báo bị kéo xuống), CHƯA tái hiện được, theo dõi tiếp.
- 2026-11-03 · Samsung Galaxy A13 SM-A135F, Android 14 (API 34), chỉ 32-bit, Exynos 850 · G1, APK release (khóa debug) · mở app; Cài đặt → Tối, → English; Back về màn chính; tắt hẳn rồi mở lại 5 lần · Lần đầu crash (BUG-001, đã sửa). Sau khi sửa: chữ tiếng Việt và tiếng Anh đúng, giao diện tối đổi ngay, Back đúng, cài đặt còn sau khi mở lại, không crash. `WaitTime` của `am start -W` 5 lần: 835, 1050, 1676, 2081, 2641 ms (trung vị 1676 ms; số này tính tới khung hình Android đầu tiên, chưa phải khung hình Flutter, đo NFR chuẩn ở G6). APK đủ kiến trúc 53,7 MB; ngưỡng ≤ 25 MB trong SPEC là cho một kiến trúc, sẽ đo bằng AAB ở G6. Chưa thử xoay máy.
