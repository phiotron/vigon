# DECISIONS — Nhật ký quyết định kiến trúc

Mỗi quyết định một mục, mới nhất ở trên cùng.

## D-013 · Bản 1.1: cột hạn mức danh mục (schema 2), tài khoản ẩn, quy tắc lịch khi đổi tần suất · 2026-11-04
- Bối cảnh: SPEC-1.1 F-14, F-16, F-20. Người dùng duyệt thêm chức năng offline; vẫn không mạng, không quyền mới (D-002).
- Quyết định: (1) Cơ sở dữ liệu lên `schemaVersion` 2: bảng danh mục thêm cột `budget` (số nguyên nullable, CHECK > 0), `onUpgrade` dùng `addColumn` giữ dữ liệu cũ; file sao lưu mang cột này, đọc được file cũ (thiếu khóa thì null), từ chối `schemaVersion` > 2; `backupVersion` giữ 1. Đổi tiền tệ nhân hoặc chia cả hạn mức này (tối thiểu 1). (2) Tài khoản: ẩn (cột `archived` có sẵn) và xóa; xóa chỉ khi chưa có khoản nào (kể cả chuyển tiền đến) và không chuỗi định kỳ trỏ tới; luôn còn ≥ 1 tài khoản hiện; file sao lưu phải có ít nhất một tài khoản hiện. (3) Đổi tần suất khoản định kỳ: chuỗi bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ (`startDate` = ngày đó, `lastGeneratedDate` = ngày liền trước), không sinh bù, không trùng; hệ quả: ngày neo đổi (tuần 03/11 sang tháng thành ngày 17), neo ngày 31 mất khi đổi qua lại. (4) Chạy lại chuỗi đã dừng không được lùi `lastGeneratedDate` (tránh sinh trùng trong ngày).
- Lý do / phương án đã loại: Bảng hạn mức riêng (loại: một cột nullable đủ và rẻ hơn). Xóa tài khoản kèm xóa khoản (loại: mất dữ liệu tài chính, chỉ cho ẩn). Sinh bù khi đổi tần suất (loại: tạo hàng loạt khoản ngoài ý).
- Hệ quả cần nhớ: Mọi đổi bảng sau này phải tăng `schemaVersion` và có migration kèm test dựng cơ sở dữ liệu schema cũ. Ẩn tài khoản chưa dừng chuỗi định kỳ đang trỏ tới nó (BACKLOG).

## D-012 · Mã hóa file sao lưu bằng mật khẩu (tùy chọn) · 2026-11-04
- Bối cảnh: SPEC-1.1 F-21 (AC-55). File `.vigon` từng là JSON thường (D-006).
- Quyết định: Tùy chọn khi xuất, mặc định tắt. Có mật khẩu thì bọc nội dung file cũ vào phong bì JSON `{format: "vigon-backup-encrypted", version: 1, kdf: "pbkdf2-hmac-sha256", iterations, salt, nonce, ciphertext}`: khóa 256-bit từ PBKDF2-HMAC-SHA256 (100.000 vòng, muối ngẫu nhiên 16 byte, ghi số vòng trong phong bì để tăng sau này, khi đọc chặn tối đa 1.000.000 vòng), mã hóa AES-256-GCM (nonce 12 byte, dữ liệu gắn thêm là `vigon-backup-encrypted:1`). Chạy ở isolate để vòng quay không đơ. Mật khẩu mã hóa UTF-8, không cắt khoảng trắng, không chuẩn hóa Unicode, không lưu ở đâu cả. Gói `cryptography` 2.9.0 (Apache-2.0, Dart thuần, chạy offline); SBOM 108 gói.
- Lý do / phương án đã loại: Mật khẩu không mã hóa thật (loại: chỉ che mắt). Gói mật mã gốc Android qua plugin (loại: thêm phụ thuộc nền tảng, khó thử). Số vòng cao hơn khuyến nghị OWASP (loại: Dart thuần chậm trên máy yếu; số vòng nằm trong phong bì nên nâng được).
- Hệ quả cần nhớ: Quên mật khẩu thì không mở được file (đã cảnh báo trong app). Thời gian 100.000 vòng chưa đo trên Galaxy A13 (ước tính vài giây). Mật khẩu có dấu gõ dạng NFD khác NFC. File cũ không mã hóa vẫn khôi phục được.

## D-009 · Chốt logo "hai thẻ xếp chồng" cho icon app và store · 2026-11-04
- Bối cảnh: SPEC mục 7 cấm sao chép tên, icon, giao diện của Monefy; Design System "Ví Gọn" ghi "app chưa có logo". Người dùng yêu cầu logo độc lạ, hiện đại, không trùng nhãn hàng khác, rồi chốt bản nháp trên canvas Design (2026-11-04).
- Quyết định: Logo là hai chiếc thẻ xếp chồng lệch nhau (thẻ sau bạc hà `#8CD5BF` quay −14°, thẻ trước trắng `#F7FAF8` quay +8° có hai vạch kẻ xanh đậm và một nút tròn cam `#E65100`) trên nền xanh đậm `#0E5244`. Màu và font (Be Vietnam Pro) lấy từ Design System "Ví Gọn". Không dùng đồng xu, dấu $, con heo, chiếc ví có nắp, chiếc lá hay biểu đồ vòng (biểu đồ vòng là bố cục màn chính, tránh để logo giống Monefy). Dùng làm: icon launcher Android (icon thích ứng `res/mipmap-anydpi-v26/ic_launcher.xml` + vector `drawable/ic_launcher_foreground.xml`, nền `#0E5244`; PNG bo góc cho Android dưới 8), icon Play Store 512×512 (`docs/store/brand/icon-512.png`, vuông trọn vì Play tự bo góc), ảnh bìa store.
- Lý do / phương án đã loại: Biểu đồ vòng làm logo (loại: giống bố cục Monefy). Chữ V cách điệu hoặc ví có nắp (loại: quen thuộc, dễ trùng). Bản vẽ gốc là canvas Design "Ví Gọn — Icon và ảnh bìa (nháp)": https://claude.ai/artifact/DBwgVoiivXzru6KwTwaypY
- Hệ quả cần nhớ: Hình nằm ở ba nơi phải giữ trùng nhau: canvas Design, vector Android, và `tool` vẽ PNG (script `render_logo.py` hiện chỉ ở thư mục tạm; nếu cần vẽ lại, hình định nghĩa trong vector Android). Mình CHƯA tra được cơ sở dữ liệu nhãn hiệu: người dùng cần tìm "Ví Gọn" trên Google Play và tìm bằng hình ảnh trước khi nộp (chưa kiểm). Ảnh bìa 1024×500 còn trên canvas, cần xuất PNG bằng Share › Export (Claude không dựng được ảnh có chữ thành PNG). Design System "Ví Gọn" vẫn ghi "chưa có logo", cập nhật ở chat đã tạo nó.

## D-008 · Thông tin liên hệ ở một chỗ; bố cục co giãn theo cỡ chữ; test accessibility tự động · 2026-11-03
- Bối cảnh: G6, SPEC F-12 và F-13 (AC-37 tới AC-41). Người dùng chọn email liên hệ `phamphuongphuong@gmail.com` và đăng chính sách trên Google Sites (đường dẫn có sau).
- Quyết định: (1) Email và đường dẫn chính sách nằm trong `lib/src/app_info.dart`; khi đường dẫn còn trống, dòng "Chính sách quyền riêng tư" ở màn Giới thiệu bị tắt và ghi "Đang chuẩn bị trang web"; `/release` phải chặn nếu còn trống. Mở trang web và email bằng `url_launcher` qua intent (khai báo `<queries>`), không thêm quyền INTERNET. Phiên bản lấy từ `package_info_plus` qua `appVersionProvider` (test ghi đè). (2) Cỡ chữ hệ thống từ 130% (`isLargeText`): số tiền xuống dưới tiêu đề thay vì cuối dòng; lựa chọn Giao diện/Ngôn ngữ xếp dọc; màn nhập khoản và chuyển tiền cho phần trên cuộn, bàn phím ghim dưới. (3) `test/features/g6_accessibility_test.dart` chạy mọi màn chính ở sáng/tối, 100%/200% với các guideline của Flutter (vùng chạm, nhãn, tương phản) và bắt lỗi vẽ.
- Lý do / phương án đã loại: Hiện chính sách ngay trong app (loại: SPEC chỉ yêu cầu liên kết, Play vẫn cần trang web). Giới hạn cỡ chữ của app (loại: trái WCAG 1.4.4). Chỉ thử tay (loại: không lặp lại được, dễ sót màn).
- Hệ quả cần nhớ: Guideline tự động không thay được TalkBack thật và cỡ chữ lớn nhất trên máy (AC-38, AC-39 vẫn cần thử tay). Bọc `Semantics(excludeSemantics: true)` quanh nút thì phải tự gắn `onTap` (BUG-003). Thêm màn mới thì thêm route vào `_routes` của test accessibility.

## D-007 · Khóa PIN: mã băm có muối trong bộ nhớ an toàn, màn khóa phủ lên app · 2026-11-03
- Bối cảnh: SPEC F-11 (AC-31 tới AC-34): PIN 4 số, lưu băm có muối trong bộ nhớ an toàn của hệ điều hành, khóa lại sau hơn 1 phút ở nền, quên mã thì chỉ xóa dữ liệu.
- Quyết định: `flutter_secure_storage` (Android Keystore) giữ muối ngẫu nhiên 16 byte và mã băm SHA-256 lặp 20.000 vòng (gói `crypto`); không lưu mã. Màn khóa là lớp phủ trong `MaterialApp.builder`, phần app bên dưới chỉ bị ẩn (`Offstage`) nên không mất trạng thái. Thời điểm ra nền lấy từ `AppLifecycleListener`, so với `clockProvider` để test được.
- Lý do / phương án đã loại: Vân tay/sinh trắc học (ngoài phạm vi v1). PBKDF2/Argon2 (loại: cần thêm gói; với PIN 4 số chỉ có 10.000 khả năng thì thuật toán băm không đổi được độ an toàn). Lưu PIN trong SQLite (loại: file sao lưu và cơ sở dữ liệu sẽ chứa mã).
- Hệ quả cần nhớ: PIN 4 số chỉ chặn người cầm máy tò mò, KHÔNG chống được kẻ lấy được dữ liệu bộ nhớ an toàn của máy đã root (dò hết 10.000 mã rất nhanh). Phải nói đúng điều này trong chính sách quyền riêng tư và MASVS (G6), không quảng cáo là "mã hóa dữ liệu". Cơ sở dữ liệu và file sao lưu KHÔNG được mã hóa. Chưa kiểm chứng trên Keystore thật.

## D-006 · Sao lưu: file `.vigon` là JSON có mã băm, khôi phục thay toàn bộ trong một giao dịch · 2026-11-03
- Bối cảnh: SPEC F-10 (AC-28 tới AC-30): xuất bằng bảng chia sẻ, khôi phục qua trình chọn file, không xin quyền bộ nhớ, file hỏng thì không đụng dữ liệu hiện có.
- Quyết định: File là JSON `{format: "vigon-backup", version: 1, schemaVersion, checksum, tables}` chứa 5 bảng (kèm cài đặt, không có PIN). `checksum` là SHA-256 của phần `tables`. Khôi phục đọc và kiểm hết (định dạng, phiên bản, mã băm, từng dòng) trước khi xóa, rồi xóa và ghi trong MỘT giao dịch; lỗi ràng buộc (khóa ngoại sai, số tiền ≤ 0) thì quay lui. Ghi file tạm rồi `share_plus` mở bảng chia sẻ; chọn file bằng `file_picker` (trình chọn của hệ điều hành). CSV: UTF-8 có BOM, ghi chú bắt đầu bằng `= + - @` được thêm dấu `'` để Excel không coi là công thức.
- Lý do / phương án đã loại: Sao chép nguyên file SQLite (loại: gắn với phiên bản schema và drift, khó kiểm tra tính toàn vẹn). Xin quyền bộ nhớ (loại: trái SPEC mục 5, thêm khai báo Data safety).
- Hệ quả cần nhớ: Mã băm chỉ phát hiện file hỏng hoặc bị sửa vô ý, KHÔNG chống người cố ý sửa (họ tính lại được mã băm). File không mã hóa (ghi rõ trong app). Đổi cấu trúc bảng thì phải tăng `version` của file và viết đường nâng cấp khi đọc file cũ.

## D-005 · Mô hình dữ liệu: tiền số nguyên, ngày dạng chữ, cài đặt trong cơ sở dữ liệu · 2026-11-03
- Bối cảnh: SPEC AC-07, AC-22 đòi tổng đúng tới đơn vị nhỏ nhất; AC-29 khôi phục cả cài đặt; AC-15 tên danh mục mặc định theo ngôn ngữ máy.
- Quyết định: Số tiền lưu `int` theo đơn vị nhỏ nhất của tiền tệ (VND: đồng, USD: cent), luôn > 0, chiều thu/chi nằm ở cột `type`. Ngày của khoản lưu chữ `YYYY-MM-DD` (giờ địa phương, so sánh được bằng chuỗi, không lệch múi giờ). Cài đặt lưu bảng khóa-giá trị trong cùng SQLite (không dùng SharedPreferences) để một file sao lưu chứa đủ. Danh mục và tài khoản mặc định có `nameKey` để hiện theo ngôn ngữ; người dùng đổi tên thì ghi `name` và bỏ qua `nameKey`.
- Lý do / phương án đã loại: Số thực `double` (loại: sai số làm tròn khi cộng dồn). Lưu ngày bằng timestamp (loại: đổi múi giờ làm khoản nhảy sang ngày khác). SharedPreferences cho cài đặt (loại: phải sao lưu hai nơi).
- Hệ quả cần nhớ: Đổi tiền tệ ở G3 phải xử lý số chữ số thập phân khác nhau (VND 0, USD 2). Mọi đổi schema phải tăng `schemaVersion` và viết migration kèm test.

## D-004 · SQLite qua drift, file sinh tự động được commit · 2026-11-03
- Bối cảnh: Cần lưu offline, có giao dịch (SPEC 5b: tắt app đột ngột không mất khoản), migration và test không cần máy thật.
- Quyết định: `drift` + `drift_flutter` (SQLite). Sinh mã bằng `dart run build_runner build`; file `*.g.dart` được COMMIT để clone về là `flutter analyze` và `flutter test` chạy được ngay.
- Lý do / phương án đã loại: `sqflite` (loại: SQL viết tay, không kiểm kiểu, test trên máy tính cần thêm gói ffi). Hive/Isar (loại: không phải SQL, truy vấn tổng theo kỳ và danh mục khó hơn; Isar ít được bảo trì).
- Hệ quả cần nhớ: Sửa bảng xong phải chạy lại build_runner rồi mới analyze/test. Test dùng cơ sở dữ liệu trong bộ nhớ (`NativeDatabase.memory()`).

## D-003 · Phiên bản Flutter, quản lý trạng thái, điều hướng, đa ngôn ngữ · 2026-11-03
- Bối cảnh: G1 khởi tạo dự án. Máy đã có Flutter tại `C:\src\flutter`, checkout tag `3.47.8` (Dart 3.13.7), chưa có trong PATH; chưa cài FVM.
- Quyết định: Ghim Flutter 3.47.8 (ghi trong CI và mục "Lệnh"; không cài FVM khi chỉ có một app Flutter). Trạng thái: `flutter_riverpod` 3. Điều hướng: `go_router`. Đa ngôn ngữ: `flutter_localizations` + `gen-l10n` chính thức với file `.arb` (vi, en). Chỉ tạo nền tảng Android (`--platforms android`); thêm iOS sau bằng `flutter create --platforms ios .`. Package: `com.phiotron.vigon` (người dùng chọn).
- Lý do / phương án đã loại: Provider (loại: Riverpod test được không cần widget, ít phụ thuộc BuildContext). Bloc (loại: nhiều mã mẫu cho app nhỏ). Navigator 1.0 (loại: go_router xử lý nút Back và khóa PIN ở G5 gọn hơn bằng redirect).
- Mức SDK thực tế của bản build 2026-11-03: minSdk 24 (Android 7.0), targetSdk 36, do Flutter 3.47.8 quản lý.
- Hệ quả cần nhớ: Khi có app Flutter thứ hai cần phiên bản khác thì cài FVM và thêm `.fvmrc`. Không trộn cách quản lý trạng thái khác.

## D-002 · Chỉ lưu trên máy, không máy chủ, không SDK bên thứ ba · 2026-11-03
- Bối cảnh: App miễn phí, bán ở Việt Nam và toàn cầu, dữ liệu là tài chính cá nhân.
- Quyết định: Dữ liệu chỉ nằm trong SQLite trên máy; không tài khoản, không máy chủ, không analytics, quảng cáo hay SDK báo crash; bản release không có quyền INTERNET. Sao lưu bằng file người dùng tự xuất. Theo dõi crash qua Android vitals của Play Console.
- Lý do / phương án đã loại: Đồng bộ đám mây (loại ở v1: cần máy chủ hoặc đăng nhập Google, kéo theo rất nhiều mục tuân thủ dữ liệu, hợp đồng xử lý, chuyển dữ liệu xuyên biên giới). SDK báo crash như Firebase Crashlytics (loại: gửi dữ liệu ra ngoài, phải xin đồng ý ở EU và khai Data safety).
- Hệ quả cần nhớ: Mất máy mà chưa xuất file là mất dữ liệu; quên PIN là không vào lại được. Thêm bất kỳ tính năng gọi mạng nào sau này phải mở lại COMPLIANCE mục D-xx.

## D-001 · Stack Flutter, Android trước · 2026-11-03
- Bối cảnh: Người dùng chọn Flutter khi tạo app; phát hành Android trước, iOS để sau.
- Quyết định: Flutter (Dart), một codebase; v1 chỉ build và phát hành Android.
- Lý do / phương án đã loại: Expo/React Native (loại: người dùng đã chọn Flutter; Flutter vẽ biểu đồ và giao diện tùy biến mượt, có CI mẫu trong `shared/stacks/flutter.ci.yml`). iOS ở v1 (loại: cần máy Mac và tài khoản Apple Developer).
- Hệ quả cần nhớ: Code không dùng thứ chỉ có trên Android khi có lựa chọn đa nền tảng, để thêm iOS sau không phải viết lại.
