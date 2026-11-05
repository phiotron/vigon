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
- [x] Đo lưu khoản (đạt, tối đa 169 ms) và cuộn 5.000 khoản (đạt; mở nhóm có 1 khung hình 46,8 ms, vượt 32 ms một lần)
- [x] Đo AC-01 (80–84 ms) và tắt đột ngột ngay sau Lưu (6 lần, không mất khoản)
- [ ] Đo NFR còn thiếu: pin 15 phút (máy đang cắm sạc USB nên không đo được, cần người dùng)
- [x] SBOM (`docs/sbom/vigon.cdx.json`, `tool/make_sbom.py`), tự kiểm MASVS (`docs/security/MASVS-SELF-CHECK.md`), SECURITY.md, cập nhật COMPLIANCE
- [ ] COMPLIANCE còn "chưa": M-01, D-02, D-07, D-09, D-12, S-06, A-01, C-03, P-08, P-09, P-10 (phần lớn cần người dùng hoặc luật sư)
- [ ] Closed test 12 người trong 14 ngày (P-09), rồi `/release`

### PLAN-001 · Giao diện theo thiết kế và bản iOS — nhánh `feature/PLAN-001`, duyệt 2026-11-04
Kế hoạch: `docs/plans/PLAN-001-giao-dien-theo-thiet-ke-va-ban-ios.md`. Mỗi giai đoạn dừng ở cổng chờ người dùng.
- [x] T1 · Nền thiết kế (UI-01, UI-02, UI-05), 2026-11-04: `tool/gen_tokens.py` → `lib/src/ui/tokens.g.dart`; `lib/src/ui/theme.dart` (ColorScheme từ token, `ViGonColors`, 12 kiểu chữ, AppBar căn trái, hộp thoại, bảng kéo, thanh thông báo, chip, ô nhập); font Be Vietnam Pro 400–700 + OFL trong màn giấy phép; gói `material_symbols_icons`; nút −/+ và màu thu/chi lấy từ token. `flutter analyze` sạch, `flutter test` 122 đạt (thêm `test/ui/theme_test.dart`: token khớp, theme, font, tương phản); sửa 2 test chạm dòng nằm dưới mép màn (`ensureVisible`). APK release không có INTERNET (`aapt2`). CHƯA xem bằng mắt trên máy (để T5)
  - Lưu ý dung lượng: gói icon có 3 font 34 MB; CHỈ được cắt gọn khi code có dùng ít nhất một icon `Symbols.*` (đo: không dùng → APK 77,1 MB; dùng 2 icon → 62,2 MB, ba font còn ~12 KB). đã hết từ T2 (2026-11-04)
- [x] T2 · Thành phần dùng chung, bộ icon và màu danh mục mới (UI-03), 2026-11-04: 31 icon danh mục Material Symbols Rounded theo `design-system-guide.md` (5 khóa cũ vẫn hiện icon), 16 màu cat-xx, danh mục mặc định theo README thiết kế; mọi icon chức năng sang Symbols Rounded; `CategoryAvatar` tô đầy, màu on-cat, cỡ 24/22/16; `MainActionButton` "− Chi"/"+ Thu" cao 64; `Keypad` lưới 4 cột phím 56 cách 8, nút Lưu đúng 3 cột, màu chữ theo loại khoản; `AmountDisplay` (vùng thông báo trực tiếp); vòng biểu đồ 77–107 và icon trên vòng 140 (co theo khung, icon luôn nằm trong khung); thanh Số dư bo 12 có ›; thanh ngân sách có icon cảnh báo khi vượt; bàn phím PIN 88×64; theme nút hộp thoại, chip 40, mũi tên quay lại giống nhau hai nền tảng, `dangerButtonStyle`. `flutter analyze` sạch, `flutter test` 130 đạt (thêm `test/ui/components_test.dart`); APK release 62,3 MB đủ 3 kiến trúc, font icon Rounded còn 204 KB, không có INTERNET. Sửa test: thanh Số dư tìm theo nhãn đọc, phím xóa lùi là icon. CHƯA xem bằng mắt trên máy (T5); chip trong màn ghi khoản, bảng kéo, hộp thoại nguy hiểm mới có kiểu chung, bố cục từng màn làm ở T3–T5
- [x] T3 · Màn S01–S05, lịch khoảng tùy chọn (UI-04, UI-06), 2026-11-04 (agent song song, nhánh `plan001-t3`): màn khóa PIN và Quên mã (hộp thoại `showConfirmDialog`, rung nhẹ khi sai), đầu kỳ, bảng "Xem theo", lịch Khoảng tùy chọn trong bảng kéo (`range_calendar.dart`, ô chạm 48, có Hủy/Áp dụng), menu lọc tài khoản, màn ghi/sửa khoản với lưới danh mục. 15 test mới. Khác bản vẽ: chọn danh mục vẫn LƯU luôn (giữ AC-02; người dùng đã chọn giữ, D-013; bản vẽ 3.3 ghi chưa lưu, cần sửa chú thích khi xuất lại thiết kế); nút Hủy dùng màu chữ chính (primary chỉ 4,34:1)
- [x] T4 · Màn S06–S12 (UI-04), 2026-11-04 (nhánh `plan001-t4`): Các khoản (vẫn dựng lười), Cài đặt (`ChoiceSegments` thay `SegmentedButton`, xếp dọc ≥ 130%), ngân sách, tiền tệ, danh mục (lưới 31 icon và 16 màu, ô chạm 48 nên 7 cột ở 360 dp), tài khoản, Chuyển tiền (ô Từ/Đến xếp dọc), khoản định kỳ. 7 test mới. Khác bản vẽ: icon tài khoản (dữ liệu không có trường icon), lưới màu 7/7/2 ở 360 dp. Còn: menu ngày bắt đầu tháng không tự cuộn tới ngày đã chọn; ký tự → trong "A → B" không có trong font Be Vietnam Pro (rơi về font hệ thống), xem trên máy
- [~] T5 · Màn S13–S16 (nhánh `plan001-t5`) XONG: đặt/tắt PIN (mũi tên quay lại, bàn phím dồn đáy), sao lưu/khôi phục, xóa dữ liệu qua 2 hộp thoại nút đỏ, Giới thiệu. 5 test mới. APK release 62,2 MB, không INTERNET. SO ẢNH VỚI BẢN VẼ (UI-04, 2026-11-04) làm một phần: `flutter test tool/shots/shots_test.dart` chụp 23 màn × sáng/tối (font và icon thật, 720×1600) ra `tool/shots/out/`; đã xem ~17 ảnh và đối chiếu số đo từ `xem/S02`, `S03`, `S04` (tọa độ phần tử trong khung điện thoại). Sửa các lệch tìm thấy: hàng chip và vùng số tiền ở màn ghi khoản bị căn giữa (phải căn trái/phải), tiêu đề thanh trên có nút quay lại lệch 12 (72 → 60), menu lọc tài khoản rộng 285 thay vì 224 và sai vị trí, chữ "Tất cả tài khoản" xuống dòng. CHƯA so: các ảnh còn lại (đặc biệt giao diện tối ngoài 2.6/3.2/6.1, 4.2 vuốt xóa, 6.6 chuyển tiền, 7.1, 8.x) và độ chính xác từng pixel; ảnh chụp bằng test không thay được máy thật. CÒN (cần máy/người dùng): thử Galaxy A13 (phải hỏi trước khi dùng adb), rung khi sai mã, bảng chia sẻ, trình chọn file
- [~] T6 · iOS (nhánh `plan001-t6`): `ios/` (chỉ iPhone, chỉ dọc, `com.phiotron.vigon`, iOS tối thiểu 15.0), `PrivacyInfo.xcprivacy`, icon iOS vẽ bằng `tool/render_ios_icon.py` từ vector logo D-009, job CI `ios` (macos-26, không ký), sửa PIN cũ trong Keychain sau cài lại (D-012, 9 test), test cấu hình iOS. CHƯA kiểm chứng: build iOS thật (iOS-01, runner `macos-26` chưa chắc tồn tại), iOS-02 và iOS-03 trên iPhone. `sqlite3` và `objective_c` thiếu privacy manifest (nếu Apple báo ITMS-91053 thì thêm FileTimestamp C617.1). Màn khởi động còn trắng ở giao diện tối
- [ ] Người dùng: cho phép đẩy nhánh lên remote `origin` (repo đã có `origin` → github.com/phiotron/vigon; chưa biết ai thêm, chưa push) để CI iOS chạy; tài khoản Apple Developer (99 USD/năm), đăng ký bundle id, tạo app App Store Connect; chứng chỉ Distribution và provisioning (hoặc API key) làm secret; khai App Privacy "Data Not Collected", xếp hạng tuổi (P-05), URL chính sách; thử iPhone với VoiceOver, cỡ chữ lớn nhất, cài lại khi bật PIN, vuốt mép trái
- [ ] Chụp lại ảnh store theo giao diện mới (`docs/store`)

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
- BUG-005 · Kẹt màn trắng khi bộ nhớ an toàn (Keystore) đọc lỗi lúc mở app: `LockNotifier._init` không bắt lỗi nên trạng thái ở `checking` mãi. Sửa: lỗi thì coi như đang khóa (có nút "Quên mã"), nhập mã khi lỗi thì không mở khóa. Test chặn: `g5_lock_test`. Phát hiện bởi `/spec-review` độc lập.
- BUG-006 · Phần trăm hiển thị theo danh mục có thể cộng 100,2 hoặc 99,6 (6 hoặc 12 danh mục bằng nhau) trái AC-08. Sửa: chia phần trăm theo phần dư lớn nhất ở độ chính xác 0,1. Test chặn: `summary_test`. Test cũ chỉ thử ca 3 danh mục nên không bắt được.
- BUG-007 · Đổi "Ngày đầu tuần" hoặc "Tháng bắt đầu từ ngày" trong Cài đặt làm kỳ đang xem bị đặt lại về Tháng (do `PeriodNotifier.build` dùng `ref.watch`). Sửa: nghe thay đổi và tính lại kỳ cùng loại. Test chặn: `g6_accessibility_test`.
- BUG-008 · Nút chọn icon danh mục có tooltip là mã tiếng Anh ("local_cafe"), TalkBack đọc mã này, trái AC-36 và AC-39. Sửa: tên "Biểu tượng N" lấy từ file dịch.
- BUG-009 · Màn nhập khoản và chuyển tiền: nếu ghi lỗi thì nút Lưu kẹt (cờ `_saving` không được đặt lại); khoản có ngày trước năm 2000 (từ file khôi phục) làm hộp chọn ngày lỗi. Sửa cả hai.
- BUG-010 · Sau khôi phục sao lưu, bộ lọc tài khoản cũ còn nguyên; nếu tài khoản đó không còn thì màn chính trống. Sửa: khôi phục xong thì đặt lọc về "Tất cả tài khoản".
- BUG-011 · Gõ số quá lớn (hơn 15 chữ số) làm số tiền bị chặn ở mức tối đa của số nguyên 64-bit (9,22 tỷ tỷ); cộng hai khoản như vậy sẽ tràn khi tính tổng. Ngoài ra 1.005 USD ra 100 cent thay vì 101 (nhiễu số thực). Sửa: số tiền một khoản tối đa 1.000.000.000.000 đơn vị nhỏ nhất (VND: 1.000 tỷ đồng; USD: 10 tỷ đô), vượt thì báo "Phép tính không hợp lệ"; bỏ nhiễu số thực trước khi làm tròn nửa lên. Test: `calculator_test`. Phát hiện bởi `/spec-review`.
- BUG-012 · App sống qua nửa đêm hoặc qua ngày đầu tháng thì thanh ngân sách vẫn tính tháng cũ tới khi app bị tắt. Sửa: `todayProvider` làm mới khi app quay lại từ nền. Test: `g6_flows_test`.
- BUG-013 · Hộp thoại Ngân sách và hộp thoại sửa khoản định kỳ giải phóng ô nhập (`TextEditingController`) ngay khi đóng, trong lúc hiệu ứng đóng còn vẽ: bản debug ném lỗi "used after being disposed" (bản release không hiện lỗi). Sửa: mỗi hộp thoại là một `StatefulWidget` tự giữ và giải phóng ô nhập. Phát hiện khi viết test AC-26; test: `g6_flows_test`.
- LƯU Ý (thư viện, không sửa được): hộp chọn khoảng ngày của Material tràn vài px ở phần tiêu đề khi màn rộng 360 dp và tiếng Việt ("5 thg 11 – 9 thg 11"); bản release chỉ cắt bớt chữ, không crash. Chưa thấy trên máy thật (Galaxy A13 rộng hơn 360 dp); theo dõi khi thử thêm máy nhỏ.
- BUG-004 · Mở một nhóm vài nghìn khoản ở màn Các khoản làm máy đứng hình (khung hình dựng 13,4 giây với 5.000 khoản). Nguyên nhân gốc: `ExpansionTile` dựng toàn bộ dòng con ngay khi mở, và cả màn là `ListView(children: [...])` không dựng lười. Cách sửa: `ListView.builder` với danh sách hàm dựng dòng, nhóm mở lưu trong state; còn 1 khung hình 46,8 ms lúc mở. Tránh lần sau: danh sách có thể dài thì luôn dùng `ListView.builder`; test dữ liệu lớn bằng `integration_test/perf_test.dart`, vì test 5 khoản không thấy lỗi này.
- BUG-003 · TalkBack đọc được tên 10 icon danh mục quanh biểu đồ nhưng không bấm được (uiautomator báo không clickable). Nguyên nhân gốc: `CategoryAvatar` bọc `Semantics(excludeSemantics: true)` làm mất cả hành động chạm của `InkWell` bên trong; guideline nhãn của Flutter không bắt được vì nút không còn hành động chạm. Cách sửa: gắn `onTap` vào chính `Semantics` (`lib/src/ui/category_avatar.dart`), test chặn trong `g6_accessibility_test`. Tránh lần sau: dùng `excludeSemantics` trên nút thì luôn kiểm `hasTapAction` (D-008).
- BUG-001 · App crash ngay khi mở trên Galaxy A13: "Could not find libflutter.so, looked for armeabi-v7a". Nguyên nhân gốc: APK build với `--target-platform android-arm64`, nhưng máy có chip 64-bit lại chạy hệ điều hành chỉ 32-bit (`ro.product.cpu.abilist64` rỗng). Cách sửa: build APK đủ kiến trúc (`flutter build apk --release`); bản phát hành dùng AAB thì Play tự chia theo kiến trúc. Tránh lần sau: không build APK một kiến trúc để thử; kiểm `adb shell getprop ro.product.cpu.abilist` của máy thử. Test trên máy tính và giả lập không bắt được lỗi này (L-003).
- BUG-002 · `flutter build apk --release` thất bại ở `:android_file_picker:compileReleaseKotlin` với "Could not close incremental caches", xuất hiện sau khi G5 thêm các gói plugin. Nguyên nhân nghi: dự án ở ổ D:, pub cache ở ổ C:, Kotlin không đóng được bộ đệm biên dịch tăng dần (CHƯA kiểm chứng bằng cách bỏ dòng sửa rồi build lại). Cách sửa: `kotlin.incremental=false` trong `android/gradle.properties`; build release đạt ngày 2026-11-03. Tránh lần sau: dự án Flutter trên Windows mà pub cache khác ổ thì tắt Kotlin incremental ngay từ đầu (build chậm hơn chút, không ảnh hưởng app).

## Phát hiện của `/spec-review` chưa xử lý (đã kiểm với code, xếp theo mức độ)
Nguồn: agent `reviewer` chỉ đọc, 2026-11-03. Các lỗi đã sửa nằm ở BUG-005 tới BUG-010. Còn lại, chưa sửa vì ngoài SPEC hoặc cần người dùng quyết:
- [x] (nhẹ) "Hôm nay" chỉ đọc một lần: đã sửa phần thanh ngân sách (BUG-012); kỳ mặc định ở màn chính vẫn là tháng lúc mở app, người dùng tự đổi kỳ được
- [ ] (nhẹ) PIN không đếm lần nhập sai, không làm chậm; giờ ra nền dùng đồng hồ tường nên đổi giờ máy qua được AC-32 (SPEC không đòi; D-007 đã nói PIN chỉ chặn người tò mò)
- [x] (nhẹ) Khôi phục: nay kiểm file TRƯỚC rồi mới hỏi xác nhận (`validateBackup`), đúng AC-29; file hỏng báo lỗi ngay, không hỏi
- [x] (nhẹ) Đổi tiền tệ làm tròn phần lẻ: hành vi giữ nguyên (đúng D-005), nhưng chữ cảnh báo trong hộp chọn tiền tệ nay nói rõ nhân/chia và có thể mất phần lẻ khi đổi ngược
- [x] (nhẹ) Không giới hạn số tiền tối đa, 1.005 USD ra 100 cent: đã sửa (BUG-011)
- [ ] (nhẹ) Nếu có hơn 10 danh mục chi, danh mục thừa không chạm được từ vòng icon quanh biểu đồ (AC-06)
- [ ] (nhẹ) CSV: tiêu đề cột và loại luôn tiếng Anh, số lẻ dùng dấu chấm; chưa thử Excel
- [ ] (nhẹ) Danh sách tiền tệ chỉ 31 mã, chưa phải toàn bộ ISO 4217 (AC-21)
- [x] Đã thêm test giao diện cho AC-04, AC-10 (kỳ Tuần/Năm), AC-16, AC-17, AC-20, AC-26 (`g6_flows_test`). Đã thêm cả test "Khoảng tùy chọn". Còn thiếu: biên bản máy thật cho AC-14, AC-09, AC-37 tới AC-40 (cần người dùng cho dùng máy)
- [ ] Ký bản release: cấu hình ký đã sẵn (`android/app/build.gradle.kts` đọc `android/key.properties`; `appbundle` bị chặn khi thiếu khóa), nhánh có khóa CHƯA chạy thử. Việc của người dùng: tạo khóa, cất và sao lưu ngoài repo theo `docs/RELEASE.md`

## Bản 1.1 (SPEC-1.1, người dùng duyệt 2026-11-04): đã làm trên nhánh `integration/spec-1.1`, chưa gộp vào nhánh chính
- [x] F-14 ẩn, hiện, xóa tài khoản · F-15 tìm kiếm khoản · F-16 sửa đầy đủ khoản định kỳ · F-17 ô "Danh mục khác" · F-18 CSV theo ngôn ngữ · F-19 đủ tiền tệ ISO 4217 · F-20 ngân sách theo danh mục (cơ sở dữ liệu schema 2) · F-21 mã hóa file sao lưu bằng mật khẩu · F-22 che nội dung ở màn đa nhiệm · F-23 icon đơn sắc. 221 test đạt.
- [ ] Gộp nhánh `integration/spec-1.1` với nhánh `feature/PLAN-001` (chat khác: iOS, giao diện token mới); sẽ xung đột ở các màn chung (tài khoản, màn chính, các khoản, cài đặt, danh mục)
- [ ] Thử tay trên máy: che đa nhiệm (chụp màn hình bị chặn, màn đa nhiệm trống), icon đơn sắc trên Android 13+, mở CSV tiếng Việt bằng Excel, thời gian mã hóa sao lưu 100.000 vòng trên Galaxy A13
- Lỗi đã sửa sau kiểm chứng độc lập (test chặn trong `test/data/review_fixes_test.dart`, `test/features/review_fixes_test.dart`): hạn mức danh mục không nhân chia khi đổi tiền tệ; bật lại chuỗi định kỳ cùng ngày sinh trùng khoản; tìm kiếm thiếu tên tài khoản ẩn của khoản chuyển tiền; khoản chuyển tiền cũ mở ra màn trống khi chỉ còn một tài khoản hiện; CSV chưa chặn ô bắt đầu bằng tab/CR; file sao lưu mà mọi tài khoản đều ẩn.
- [ ] (nhẹ) Ẩn tài khoản chưa dừng hoặc cảnh báo các chuỗi định kỳ đang trỏ tới nó
- [ ] (nhẹ) Tìm kiếm với 10.000 khoản ở "Tất cả thời gian" chưa đo hiệu năng (lọc chạy lại mỗi lần gõ, chuỗi toàn số gọi định dạng tiền cho từng khoản)
- [ ] (nhẹ) Ô nhập hạn mức danh mục báo "Số tiền phải lớn hơn 0" khi gõ "1.500.000" có dấu chấm ngăn nghìn (cùng cách nhập với hộp thoại ngân sách tổng)
- [ ] (nhẹ) Mật khẩu sao lưu gõ dạng dấu rời (NFD) và dấu gộp (NFC) cho khóa khác nhau (không có thư viện chuẩn hóa Unicode); bàn phím Android thường cho NFC
- [ ] (nhẹ) Nút "Hiện lại" ở mục tài khoản đã ẩn đọc cùng một nhãn cho mọi tài khoản (TalkBack không biết tài khoản nào); chưa có test accessibility cho bảng sửa tài khoản và mục này

## Bản 1.2 (SPEC-1.2, người dùng yêu cầu 2026-11-04): đã làm trên nhánh `integration/spec-1.1`, chưa gộp vào nhánh chính, chưa phát hành
- [x] F-24 sao lưu tự động vào thư mục người dùng chọn (Storage Access Framework, mã hóa AES-256-GCM, tối đa một lần mỗi ngày khi ra nền, giữ 7 file, nút "Sao lưu ngay" và "Chọn lại thư mục") · AC-58, AC-59, AC-60
- [x] F-25 nhắc ghi chép hằng ngày (thông báo cục bộ, giờ chọn được, mặc định 20:00, lịch không chính xác theo phút, chạm mở màn Nhập khoản chi qua khóa PIN) · AC-61, AC-62; manifest thêm đúng `POST_NOTIFICATIONS` và `RECEIVE_BOOT_COMPLETED`
- [x] F-26 widget màn hình chính (nút Chi/Thu, liên kết sâu qua khóa PIN, công tắc "Hiện số tiền trên widget", khi PIN bật chỉ hiện "Đã khóa bằng PIN") · AC-63, AC-64
- 294 test tự động đạt (2026-11-04, `flutter test`); test từng AC ở `docs/TESTING.md` (AC-58 tới AC-64). Tài liệu: `ui-spec.md` (3.13, 4.8, 4.9, F-16 tới F-18), `CHANGELOG.md` mục 1.2.
- [ ] Thử tay trên máy thật theo `docs/TESTING.md` mục "Kiểm tay bản 1.2" (M-1 tới M-7): chọn thư mục Google Drive và file được tải lên, sao lưu lúc ra nền và dọn còn 7 file, lỗi khi thu hồi quyền, hộp xin quyền thông báo, thông báo đúng giờ và chạm mở app (cả khi PIN bật), khởi động lại máy, giao diện và nút widget, widget khi bật PIN. CHƯA kiểm chứng trên máy nào
- [ ] Chưa chạy lại `aapt2 dump permissions` trên APK release bản 1.2 (phải chỉ có `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` và quyền nội bộ AndroidX) trước `/release`; `docs/COMPLIANCE.md` (D-02, D-11, P-10, S-04), `docs/SECURITY.md` và chính sách quyền riêng tư đã được cập nhật cho bản 1.2 trong cây làm việc (chưa commit), còn cần luật sư đọc lại, đăng chính sách và điền Data safety: CHƯA làm
- [ ] (SPEC-1.2 AC-63 đã sửa thành 2×2, chờ người dùng xác nhận) AC-63 từng ghi widget cỡ tối thiểu 2×1, nhưng code đặt 2×2 (110 dp; một hàng 40 dp cắt mất nút khi có dòng trạng thái): người dùng chấp nhận 2×2 (rồi sửa SPEC) hoặc yêu cầu 2×1
- [ ] (nhẹ) Widget không tự tính số của tháng mới khi app chưa mở: nay số cũ tự bị bỏ khi hết kỳ tháng (báo thức không chính xác và cập nhật 30 phút của hệ thống) và widget hiện "Mở app để cập nhật" tới lần mở app kế tiếp; phần tự tính số mới nằm ở mục "Ý tưởng". Chưa thử trên launcher thật
- [x] Công tắc "Hiện số tiền trên widget" và công tắc nhắc ghi chép là cài đặt theo máy: không ghi vào file sao lưu, khôi phục không áp (file cũ có chứa chúng cũng vậy) và cả hai về tắt (test `restore_settings_test`; thay đổi chưa commit, chưa chạy lại cả bộ test)
- [ ] (nhẹ) Mã hóa PBKDF2 (100.000 vòng) của sao lưu tự động bắt đầu lúc app ra nền; Android có thể đóng băng app ẩn nên một lần sao lưu có thể dang dở tới lần sau. Thời gian trên Galaxy A13 chưa đo
- [ ] (nhẹ) Đổi múi giờ lúc app đóng thì lịch nhắc lệch tới lần mở app kế tiếp (lúc đó app đặt lại lịch theo múi giờ mới)

## Ý tưởng ngoài SPEC (chưa được duyệt, KHÔNG tự làm)
- Bản iOS
- Đồng bộ/sao lưu lên Google Drive, Dropbox (sao lưu một chiều vào thư mục đã chọn đã làm ở 1.2, F-24)
- **Đồng bộ hai chiều giữa nhiều máy qua Drive/Dropbox** (ghi 2026-11-04): ngoài phạm vi, cần khóa OAuth/ID khách do người dùng tự tạo (Google Cloud, Dropbox App Console), kéo theo quyền INTERNET, Data safety và chính sách quyền riêng tư viết lại
- **Widget hiện số tiền khi đang bật khóa PIN** (ghi 2026-11-04): ngoài phạm vi, làm lộ số liệu ngoài màn khóa và vô hiệu khóa PIN (SPEC-1.2)
- **Widget tự sang tháng mới** khi app chưa mở (ghi 2026-11-04): hiện chỉ Dart tính được số nên widget chỉ bỏ số cũ khi hết tháng và ghi "Mở app để cập nhật"; muốn tự hiện số tháng mới cần tính ở phía Android hoặc chạy nền theo ngày, cân nhắc quyền, pin và việc đọc dữ liệu ngoài app
- Nhiều tiền tệ và quy đổi tỉ giá
- Ngân sách theo danh mục; nhắc ghi chép bằng thông báo (cả hai đã làm: 1.1 F-20, 1.2 F-25)
- Widget màn hình chính (đã làm ở 1.2, F-26); mở khóa bằng vân tay
- Mã hóa file sao lưu bằng mật khẩu (file `.vigon` hiện là JSON thường, D-006)
- Gói Pro hoặc nguồn thu khác
- Che nội dung ở màn đa nhiệm (`FLAG_SECURE`) để ảnh xem trước không lộ số liệu (MASVS-STORAGE)
- Nút lọc tài khoản ở màn chính hiện tên tài khoản đang lọc (đang chỉ ghi "Tài khoản")
- Bản icon đơn sắc (`<monochrome>`) cho biểu tượng chủ đề của Android 13+
- Tên tiếng Anh riêng cho store (gợi ý: Neat Wallet, Tidy Wallet, Pocket Ledger), cần tra trùng

## Biên bản thử máy thật
Mỗi lần thử: ngày · máy và phiên bản hệ điều hành · bản app · đã thử gì · kết quả · lỗi phát hiện.
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G6, APK release (sau commit ecbb7a6 và sửa BUG-003) · Claude qua adb. Mở nguội 5 lần TotalTime trung vị 633 ms; bản profile `--trace-startup` khung hình Flutter đầu 1,09 s. Rà cây accessibility (uiautomator, chỉ nút của Ví Gọn): màn chính 18 nút, khoản chi mới 22, Cài đặt 15 + 10, Giới thiệu 3, Giấy phép 10, Danh mục 14, Tài khoản 3, Khoản định kỳ 1, Các khoản 2; không nút nào thiếu nhãn. Trước khi sửa BUG-003, icon danh mục không clickable; sau sửa thì clickable. Màn Giới thiệu: "Phiên bản 1.0.0 (1)", dòng chính sách tắt kèm "Đang chuẩn bị trang web", "Báo lỗi bảo mật" mở Gmail soạn thư tới đúng email với tiêu đề "Báo lỗi bảo mật Ví Gọn" (do Claude chạm nhầm; đã chọn Loại bỏ, không gửi), trang giấy phép mở được. Không có service, không có job nền. Đã khôi phục file thử 10.000 khoản để đo bộ nhớ, nhưng app FocusGrove rồi dailyloop lên trên (phiên khác dùng máy) nên chưa xác nhận kết quả; dữ liệu Ví Gọn trên máy có thể đang là 10.000 khoản thử. CHƯA: TalkBack thật, cỡ chữ lớn nhất trên máy.
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G5, APK release commit aefb38e · Claude điều khiển qua adb (chạm, vuốt, đọc màn hình bằng uiautomator). Mở nguội 582 tới 999 ms (`am start -W`). G3: vuốt ngang đổi tháng và tuần (tuần bắt đầu thứ Hai), "Toàn thời gian"; kéo tay nắm đưa Đi lại xuống dưới Hóa đơn, giữ sau khi thoát ra, vòng icon màn chính đổi theo; thêm tài khoản TestBank 500.000, chuyển 100.000 từ Tiền mặt, số dư hai bên đúng, màn chính không tính chuyển tiền là chi; lọc theo TestBank cho số dư 0. G4: ngân sách 150.000, thanh tiến độ khoảng 55%, chi thêm 100.000 thì thanh đỏ và báo vượt 32.403; khoản 60.000 lặp hằng ngày từ 01/11 tạo đúng 3 khoản 01, 02, 03/11, mở nguội lại 2 lần không trùng. G5: xuất sao lưu và CSV mở bảng chia sẻ, không xin quyền bộ nhớ (AC-28); khôi phục qua trình chọn file hệ thống, không xin quyền (AC-29), có hỏi xác nhận, dữ liệu được thay đúng, khoản định kỳ hằng tháng không trùng; đặt PIN, ra nền 20 giây không khóa, 70 giây thì khóa (AC-32), mở nguội thì khóa ngay; mã sai báo "Sai mã PIN", mã đúng mở được; quên mã qua 3 hộp thoại rồi xóa, mở lại không còn PIN, dữ liệu về mặc định (AC-34). Kết quả: đạt. Ghi chú: (1) sau khôi phục giao diện và ngôn ngữ về "theo hệ thống": do file thử tạo trên máy tính không có hai cài đặt này; file xuất từ app có mang cài đặt (D-006), không phải lỗi; (2) nút lọc tài khoản ở màn chính chỉ ghi "Tài khoản", không hiện tên tài khoản đang lọc (xét ở G6); (3) ba hiện tượng lạ (mở lại vào thẳng màn "Thu mới" và Back thoát app, bảng thêm tài khoản tự đóng, màn khóa có sẵn 1 chấm rồi biến mất) chỉ xảy ra khi có người khác đang dùng máy cùng lúc, thử lại riêng đều không tái hiện; (4) chưa mở CSV bằng Excel, chưa khôi phục file xuất từ chính máy (xem G5).
- 2026-11-03 · Galaxy A13 SM-A135F, Android 14 · G2, APK release · màn chính có 10 icon danh mục quanh vòng tròn, nút −/+ ở nửa dưới; bấm − nhập 120+35, Choose category, Food → lưu ₫155, biểu đồ 100% Food, số dư -₫155 (đọc bằng uiautomator). Lần chạm − đầu tiên mở nhầm "New income", chạm lại 2 lần đều đúng; lúc đó người dùng cũng đang cầm máy (bảng thông báo bị kéo xuống), CHƯA tái hiện được, theo dõi tiếp.
- 2026-11-03 · Samsung Galaxy A13 SM-A135F, Android 14 (API 34), chỉ 32-bit, Exynos 850 · G1, APK release (khóa debug) · mở app; Cài đặt → Tối, → English; Back về màn chính; tắt hẳn rồi mở lại 5 lần · Lần đầu crash (BUG-001, đã sửa). Sau khi sửa: chữ tiếng Việt và tiếng Anh đúng, giao diện tối đổi ngay, Back đúng, cài đặt còn sau khi mở lại, không crash. `WaitTime` của `am start -W` 5 lần: 835, 1050, 1676, 2081, 2641 ms (trung vị 1676 ms; số này tính tới khung hình Android đầu tiên, chưa phải khung hình Flutter, đo NFR chuẩn ở G6). APK đủ kiến trúc 53,7 MB; ngưỡng ≤ 25 MB trong SPEC là cho một kiến trúc, sẽ đo bằng AAB ở G6. Chưa thử xoay máy.
