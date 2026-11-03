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
- [x] Sửa ở G6: nút "Theo hệ thống" trong Cài đặt bị xuống 2 dòng: ở cỡ chữ từ 130% các lựa chọn xếp dọc (D-008); cỡ chữ mặc định vẫn 2 dòng, đọc được

### G2 · Ghi khoản và màn chính — trạng thái: done
- [x] Màn nhập số tiền với bàn phím số có phép tính (AC-01 tới AC-05): test `calculator_test`, `entry_flow_test`; thử máy thật 2026-11-03
- [x] Màn chính: biểu đồ tròn, tổng thu/chi/số dư, icon danh mục quanh biểu đồ, trạng thái trống (AC-06, AC-07, AC-09): test `summary_test`, `entry_flow_test`; thử máy thật
- [x] Danh sách khoản gom theo danh mục, phần trăm (AC-08): test `summary_test`
- [x] Sửa, xóa có hoàn tác (AC-13, AC-14): test `entry_repository_test`, `entry_flow_test`
- [ ] Đo AC-01 (mở màn nhập trong 300 ms) bằng đồng hồ trên máy thật: CHƯA đo

### G3 · Kỳ xem, danh mục, tài khoản, tiền tệ — trạng thái: done
- [x] Chọn kỳ, vuốt chuyển kỳ, cài đặt đầu tuần/đầu tháng (AC-10 tới AC-12): test `period_test`, `g3_repositories_test`; vuốt ngang (AC-11) CHƯA thử tay
- [x] Quản lý danh mục: thêm, sửa, sắp xếp, xóa có chuyển khoản (AC-16, AC-17): test `g3_repositories_test`, `g3_screens_test`
- [x] Tài khoản, chuyển tiền, lọc theo tài khoản (AC-18 tới AC-20): test `g3_repositories_test`, `g3_screens_test`
- [x] Tiền tệ theo vùng và định dạng số (AC-21, AC-22): test `g3_repositories_test`, `money_test`
- [x] Widget test chạy ở màn 360×800 dp; đã sửa tràn 13 px ở màn Chuyển tiền
- [x] Thử tay trên máy thật: vuốt đổi kỳ, kéo sắp xếp danh mục, chuyển tiền (biên bản 2026-11-03, qua adb)

### G4 · Khoản định kỳ và ngân sách — trạng thái: done
- [x] Chuỗi định kỳ, tự tạo khoản khi mở app, không trùng (AC-23 tới AC-25): test `recurring_test`, `g4_screens_test`
- [x] Ngân sách tháng và thanh tiến độ (AC-26, AC-27): test `g4_screens_test`
- [x] Thử tay trên máy thật: đặt ngân sách, ghi khoản lặp, kiểm tạo khoản tới hạn (biên bản 2026-11-03; dùng ngày bắt đầu trong quá khứ thay cho đổi ngày máy)

### G5 · Sao lưu, khóa PIN, dữ liệu — trạng thái: done (còn mở file CSV bằng Excel/Sheets)
- [x] Xuất/khôi phục file `.vigon`, xuất CSV (AC-28 tới AC-30): test `backup_test` (xuất rồi khôi phục ra đúng dữ liệu, file sửa/hỏng/sai khóa ngoại/số tiền âm bị từ chối và giữ dữ liệu cũ, CSV có BOM). AC-28 (bảng chia sẻ, không xin quyền bộ nhớ) và AC-29 (trình chọn file) CHƯA thử tay: chỉ chạy được trên máy thật
- [x] Khóa PIN, khóa lại sau 1 phút ở nền, quên mã (AC-31 tới AC-34): test `pin_test`, `g5_lock_test` (mã băm có muối, khóa/mở, quá 1 phút thì khóa, quên mã xóa dữ liệu qua hai bước). AC-32 trên máy thật và AC-33 trên Android Keystore thật CHƯA kiểm chứng
- [x] Xóa toàn bộ dữ liệu (AC-42): test `backup_test`, `g5_lock_test`
- [x] Build APK release lại được (BUG-002), rồi kiểm AC-43: build đạt 2026-11-03 (61,4 MB, đủ kiến trúc); `aapt2 dump permissions` chỉ có `com.phiotron.vigon.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (AndroidX tự thêm), không có INTERNET, không có quyền bộ nhớ
- [x] Thử tay trên máy thật: xuất sao lưu, khôi phục, xuất CSV, đặt PIN, ra nền hơn 1 phút rồi mở lại, quên mã (biên bản 2026-11-03)
- [ ] Người dùng: xuất CSV, gửi file sang máy tính và mở bằng Excel/Sheets, xem tiếng Việt đúng (Claude không gửi file ra ngoài thay người dùng)
- [ ] Khôi phục một file `.vigon` xuất từ chính điện thoại (lần thử dùng file tạo bằng `exportBackup` trên máy tính vì bảng chia sẻ không có mục lưu vào máy)

### G6 · Khả năng tiếp cận, pháp lý, chuẩn bị phát hành — trạng thái: phần Claude làm được đã xong; chờ người dùng
- [x] Rà accessibility tự động: vùng chạm, nhãn, tương phản, lỗi vẽ ở mọi màn chính, sáng/tối, cỡ chữ 100%/200% (`g6_accessibility_test`); sửa 4 chỗ vỡ ở 200% và BUG-003 (AC-37 tới AC-40)
- [x] Máy thật: mọi nút bấm được trên các màn chính có nhãn (uiautomator, biên bản G6)
- [ ] Người dùng: bật TalkBack, đi qua ghi khoản, màn chính, Cài đặt; đặt cỡ chữ lớn nhất rồi xem các màn chính (Claude không đổi cài đặt hệ thống của máy) (AC-38, AC-39)
- [x] Màn Giới thiệu: phiên bản, chính sách, email báo lỗi bảo mật, giấy phép nguồn mở (AC-41): test và thử máy thật
- [x] Viết chính sách quyền riêng tư vi/en: `docs/legal/privacy-policy.md`
- [ ] Người dùng: đăng chính sách lên Google Sites, gửi đường dẫn; Claude điền `lib/src/app_info.dart`
- [ ] Đo NFR còn thiếu: lưu ≤ 200 ms và cuộn 5.000 khoản (test `integration_test/perf_test.dart` đã viết, cần máy không ai dùng khoảng 5 phút), pin 15 phút (máy đang cắm sạc USB nên không đo được, cần người dùng), tắt đột ngột ngay sau Lưu (đã đo: mở nguội, dung lượng, tác vụ nền, bộ nhớ 10.000 khoản 151 MB; xem `docs/TESTING.md`)
- [x] SBOM (`docs/sbom/vigon.cdx.json`, `tool/make_sbom.py`), tự kiểm MASVS (`docs/security/MASVS-SELF-CHECK.md`), SECURITY.md, cập nhật COMPLIANCE
- [ ] COMPLIANCE còn "chưa": M-01, D-02, D-07, D-09, D-12, S-06, A-01, C-03, P-08, P-09, P-10 (phần lớn cần người dùng hoặc luật sư)
- [ ] Closed test 12 người trong 14 ngày (P-09), rồi `/release`

## Việc kế tiếp (tối đa 5, theo thứ tự)
1. Người dùng: thử TalkBack và cỡ chữ lớn nhất; đăng chính sách và gửi đường dẫn; mở CSV bằng Excel
2. Đo nốt NFR khi máy rảnh hẳn (không phiên nào khác dùng máy); khôi phục file xuất từ chính máy
3. /release: tạo khóa ký (cất ngoài repo, L-005), `flutter build appbundle`, cân nhắc `--obfuscate`, Data safety, closed test P-09
4. Câu còn mở của người dùng: phát hành dưới tên cá nhân hay công ty (EAA); Play Age Signals (D-12); luật sư xác nhận CRA (S-06) và DPIA VN (D-07)
5. Người dùng: cài Android SDK Command-line Tools và chấp nhận giấy phép SDK; tạo remote git và chạy `bash scripts/backup.sh <thư mục ngoài ổ D>`

## Lỗi đã biết (đang mở)
Mỗi lỗi: BUG-xxx · mô tả · cách tái hiện · mức độ (chặn / nặng / nhẹ) · cách tạm tránh.
(không có)

## Lỗi đã sửa đáng nhớ (nguồn cho bài học)
Mỗi lỗi: BUG-xxx · nguyên nhân gốc · cách sửa · làm sao tránh lần sau.
- BUG-003 · TalkBack đọc được tên 10 icon danh mục quanh biểu đồ nhưng không bấm được (uiautomator báo không clickable). Nguyên nhân gốc: `CategoryAvatar` bọc `Semantics(excludeSemantics: true)` làm mất cả hành động chạm của `InkWell` bên trong; guideline nhãn của Flutter không bắt được vì nút không còn hành động chạm. Cách sửa: gắn `onTap` vào chính `Semantics` (`lib/src/ui/category_avatar.dart`), test chặn trong `g6_accessibility_test`. Tránh lần sau: dùng `excludeSemantics` trên nút thì luôn kiểm `hasTapAction` (D-008).
- BUG-001 · App crash ngay khi mở trên Galaxy A13: "Could not find libflutter.so, looked for armeabi-v7a". Nguyên nhân gốc: APK build với `--target-platform android-arm64`, nhưng máy có chip 64-bit lại chạy hệ điều hành chỉ 32-bit (`ro.product.cpu.abilist64` rỗng). Cách sửa: build APK đủ kiến trúc (`flutter build apk --release`); bản phát hành dùng AAB thì Play tự chia theo kiến trúc. Tránh lần sau: không build APK một kiến trúc để thử; kiểm `adb shell getprop ro.product.cpu.abilist` của máy thử. Test trên máy tính và giả lập không bắt được lỗi này (L-003).
- BUG-002 · `flutter build apk --release` thất bại ở `:android_file_picker:compileReleaseKotlin` với "Could not close incremental caches", xuất hiện sau khi G5 thêm các gói plugin. Nguyên nhân nghi: dự án ở ổ D:, pub cache ở ổ C:, Kotlin không đóng được bộ đệm biên dịch tăng dần (CHƯA kiểm chứng bằng cách bỏ dòng sửa rồi build lại). Cách sửa: `kotlin.incremental=false` trong `android/gradle.properties`; build release đạt ngày 2026-11-03. Tránh lần sau: dự án Flutter trên Windows mà pub cache khác ổ thì tắt Kotlin incremental ngay từ đầu (build chậm hơn chút, không ảnh hưởng app).

## Ý tưởng ngoài SPEC (chưa được duyệt, KHÔNG tự làm)
- Bản iOS
- Đồng bộ/sao lưu lên Google Drive, Dropbox
- Nhiều tiền tệ và quy đổi tỉ giá
- Ngân sách theo danh mục; nhắc ghi chép bằng thông báo
- Widget màn hình chính; mở khóa bằng vân tay
- Mã hóa file sao lưu bằng mật khẩu (file `.vigon` hiện là JSON thường, D-006)
- Gói Pro hoặc nguồn thu khác
- Che nội dung ở màn đa nhiệm (`FLAG_SECURE`) để ảnh xem trước không lộ số liệu (MASVS-STORAGE)
- Nút lọc tài khoản ở màn chính hiện tên tài khoản đang lọc (đang chỉ ghi "Tài khoản")
- Tên tiếng Anh riêng cho store (gợi ý: Neat Wallet, Tidy Wallet, Pocket Ledger), cần tra trùng

## Biên bản thử máy thật
Mỗi lần thử: ngày · máy và phiên bản hệ điều hành · bản app · đã thử gì · kết quả · lỗi phát hiện.
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G6, APK release (sau commit ecbb7a6 và sửa BUG-003) · Claude qua adb. Mở nguội 5 lần TotalTime trung vị 633 ms; bản profile `--trace-startup` khung hình Flutter đầu 1,09 s. Rà cây accessibility (uiautomator, chỉ nút của Ví Gọn): màn chính 18 nút, khoản chi mới 22, Cài đặt 15 + 10, Giới thiệu 3, Giấy phép 10, Danh mục 14, Tài khoản 3, Khoản định kỳ 1, Các khoản 2; không nút nào thiếu nhãn. Trước khi sửa BUG-003, icon danh mục không clickable; sau sửa thì clickable. Màn Giới thiệu: "Phiên bản 1.0.0 (1)", dòng chính sách tắt kèm "Đang chuẩn bị trang web", "Báo lỗi bảo mật" mở Gmail soạn thư tới đúng email với tiêu đề "Báo lỗi bảo mật Ví Gọn" (do Claude chạm nhầm; đã chọn Loại bỏ, không gửi), trang giấy phép mở được. Không có service, không có job nền. Đã khôi phục file thử 10.000 khoản để đo bộ nhớ, nhưng app FocusGrove rồi dailyloop lên trên (phiên khác dùng máy) nên chưa xác nhận kết quả; dữ liệu Ví Gọn trên máy có thể đang là 10.000 khoản thử. CHƯA: TalkBack thật, cỡ chữ lớn nhất trên máy.
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G5, APK release commit aefb38e · Claude điều khiển qua adb (chạm, vuốt, đọc màn hình bằng uiautomator). Mở nguội 582 tới 999 ms (`am start -W`). G3: vuốt ngang đổi tháng và tuần (tuần bắt đầu thứ Hai), "Toàn thời gian"; kéo tay nắm đưa Đi lại xuống dưới Hóa đơn, giữ sau khi thoát ra, vòng icon màn chính đổi theo; thêm tài khoản TestBank 500.000, chuyển 100.000 từ Tiền mặt, số dư hai bên đúng, màn chính không tính chuyển tiền là chi; lọc theo TestBank cho số dư 0. G4: ngân sách 150.000, thanh tiến độ khoảng 55%, chi thêm 100.000 thì thanh đỏ và báo vượt 32.403; khoản 60.000 lặp hằng ngày từ 01/11 tạo đúng 3 khoản 01, 02, 03/11, mở nguội lại 2 lần không trùng. G5: xuất sao lưu và CSV mở bảng chia sẻ, không xin quyền bộ nhớ (AC-28); khôi phục qua trình chọn file hệ thống, không xin quyền (AC-29), có hỏi xác nhận, dữ liệu được thay đúng, khoản định kỳ hằng tháng không trùng; đặt PIN, ra nền 20 giây không khóa, 70 giây thì khóa (AC-32), mở nguội thì khóa ngay; mã sai báo "Sai mã PIN", mã đúng mở được; quên mã qua 3 hộp thoại rồi xóa, mở lại không còn PIN, dữ liệu về mặc định (AC-34). Kết quả: đạt. Ghi chú: (1) sau khôi phục giao diện và ngôn ngữ về "theo hệ thống": do file thử tạo trên máy tính không có hai cài đặt này; file xuất từ app có mang cài đặt (D-006), không phải lỗi; (2) nút lọc tài khoản ở màn chính chỉ ghi "Tài khoản", không hiện tên tài khoản đang lọc (xét ở G6); (3) ba hiện tượng lạ (mở lại vào thẳng màn "Thu mới" và Back thoát app, bảng thêm tài khoản tự đóng, màn khóa có sẵn 1 chấm rồi biến mất) chỉ xảy ra khi có người khác đang dùng máy cùng lúc, thử lại riêng đều không tái hiện; (4) chưa mở CSV bằng Excel, chưa khôi phục file xuất từ chính máy (xem G5).
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G2, APK release · màn chính có 10 icon danh mục quanh vòng tròn, nút −/+ ở nửa dưới; bấm − nhập 120+35, Choose category, Food → lưu ₫155, biểu đồ 100% Food, số dư -₫155 (đọc bằng uiautomator). Lần chạm − đầu tiên mở nhầm "New income", chạm lại 2 lần đều đúng; lúc đó người dùng cũng đang cầm máy (bảng thông báo bị kéo xuống), CHƯA tái hiện được, theo dõi tiếp.
- 2026-11-03 · Samsung Galaxy A13 SM-A135F, Android 14 (API 34), chỉ 32-bit, Exynos 850 · G1, APK release (khóa debug) · mở app; Cài đặt → Tối, → English; Back về màn chính; tắt hẳn rồi mở lại 5 lần · Lần đầu crash (BUG-001, đã sửa). Sau khi sửa: chữ tiếng Việt và tiếng Anh đúng, giao diện tối đổi ngay, Back đúng, cài đặt còn sau khi mở lại, không crash. `WaitTime` của `am start -W` 5 lần: 835, 1050, 1676, 2081, 2641 ms (trung vị 1676 ms; số này tính tới khung hình Android đầu tiên, chưa phải khung hình Flutter, đo NFR chuẩn ở G6). APK đủ kiến trúc 53,7 MB; ngưỡng ≤ 25 MB trong SPEC là cho một kiến trúc, sẽ đo bằng AAB ở G6. Chưa thử xoay máy.
