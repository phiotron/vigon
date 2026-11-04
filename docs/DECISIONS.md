# DECISIONS — Nhật ký quyết định kiến trúc

Mỗi quyết định một mục, mới nhất ở trên cùng.

## D-012 · Mã cài đặt đi kèm PIN để phát hiện cài lại trên iOS · 2026-11-04
- Bối cảnh: PLAN-001 T6 (iOS-02). Keychain iOS giữ mã PIN băm sau khi gỡ app, trong khi cơ sở dữ liệu SQLite bị xóa theo app; cài lại sẽ bị khóa bằng PIN cũ mà người dùng không còn dữ liệu để bảo vệ (D-007).
- Quyết định: Khi đặt PIN, `PinService` ghi một mã cài đặt ngẫu nhiên 16 byte vào bộ nhớ an toàn (`pin_install_id`) và vào bảng settings (`pinInstallId`); đổi PIN dùng lại mã đã có. Lúc mở app, nếu bộ nhớ an toàn có PIN kèm mã mà settings không có đúng mã đó (cơ sở dữ liệu mới) thì xóa PIN cũ. PIN đặt trước bản này (không có mã) giữ nguyên để không mất khóa của người đang dùng. Lỗi đọc thì không xóa gì. Mã KHÔNG đi vào file `.vigon` (xuất bỏ khóa này, khôi phục bỏ qua nó, `Xóa toàn bộ dữ liệu` giữ nó), nên định dạng sao lưu không đổi (D-006).
- Lý do / phương án đã loại: Cờ "đã chạy lần đầu" trong SharedPreferences (loại: cũng bị xóa theo app trên Android nhưng không phát hiện được lệch Keychain/DB). Luôn xóa PIN khi cơ sở dữ liệu trống (loại: xóa nhầm PIN của người vừa xóa dữ liệu rồi đặt lại).
- Hệ quả cần nhớ: Chưa kiểm chứng trên Keychain iOS và Keystore Android thật. Trên iOS, cơ sở dữ liệu và Keychain mặc định vào bản sao lưu iCloud/máy tính và khớp nhau, nên PIN vẫn giữ khi chuyển máy; chính sách quyền riêng tư có thể cần nói thêm điều này.

## D-011 · Thêm bản iOS từ cùng codebase, build trên cloud · 2026-11-04
- Bối cảnh: Người dùng muốn app chạy iPhone và Android theo bộ thiết kế mới (PLAN-001). D-001 để iOS sau vì cần máy Mac; máy phát triển vẫn là Windows.
- Quyết định: Thêm nền tảng iOS bằng `flutter create --platforms ios --org com.phiotron .` (bundle id `com.phiotron.vigon`, trùng package Android). Build iOS trên cloud có máy macOS (người dùng chọn): CI chạy `flutter build ios --release --no-codesign` để chắc biên dịch được; bản ký và TestFlight qua Codemagic hoặc GitHub Actions khi người dùng có remote git và tài khoản Apple Developer. Làm ở giai đoạn T6 của PLAN-001, sau khi giao diện Android xong.
- Lý do / phương án đã loại: Viết lại bằng Ionic + Capacitor (loại: phải làm lại dữ liệu, PIN, sao lưu, biểu đồ, test và thử máy G1–G6; Flutter đã chạy iOS từ cùng code). Mượn Mac (loại: người dùng không có). Chỉ Android (loại: người dùng muốn iPhone).
- Hệ quả cần nhớ: Claude không tự build hay thử được iOS trên máy này; mọi lỗi riêng iOS chỉ lộ khi CI hoặc TestFlight chạy. Keychain giữ PIN sau khi gỡ app trong khi cơ sở dữ liệu mất: lần chạy đầu với cơ sở dữ liệu mới phải xóa PIN cũ. Mục P-01 tới P-05 của COMPLIANCE thành "chưa".

## D-010 · Giao diện sinh từ token của bộ thiết kế, giữ Flutter · 2026-11-04
- Bối cảnh: Bộ thiết kế đã duyệt ở `design-mobile/screens/` (nguồn sự thật là `tokens.json`), dùng chung iPhone và Android. Theme hiện tại sinh màu bằng `ColorScheme.fromSeed`, nên khác bản vẽ.
- Quyết định: `tool/gen_tokens.py` đọc `design-mobile/screens/tokens.json` và sinh `lib/src/ui/tokens.g.dart` (màu sáng/tối, khoảng cách, bo góc, vùng chạm); file sinh được commit như `*.g.dart` của drift. Theme dựng `ColorScheme` từ token, màu ngoài `ColorScheme` (thu, chi, vuốt xóa, focus, 16 màu danh mục) nằm trong `ThemeExtension` `ViGonColors`. Chữ Be Vietnam Pro đóng vào app (không tải lúc chạy, app không có quyền INTERNET). Icon Material Symbols Rounded qua gói `material_symbols_icons`. Icon danh mục vẫn lưu bằng khóa chữ trong cơ sở dữ liệu (không phải chỉ số 1…31 như README thiết kế ghi); khóa cũ không còn trong bộ 31 icon mới vẫn hiện được để file sao lưu cũ khôi phục không lỗi. Màu danh mục mặc định đổi theo token cho lần cài mới; dữ liệu đã có giữ màu đã lưu (app chưa phát hành, không viết migration).
- Lý do / phương án đã loại: Gõ tay mã màu trong widget (loại: lệch thiết kế khi token đổi). Tải font Google Fonts lúc chạy (loại: cần mạng, trái D-002). Đổi khóa icon sang số (loại: phải migration và đổi định dạng file sao lưu, không có lợi gì).
- Hệ quả cần nhớ: Thiết kế đổi thì sửa `tokens.json` rồi chạy lại `python tool/gen_tokens.py`, không sửa tay `tokens.g.dart`. Ảnh store chụp trước đổi giao diện phải chụp lại.

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
