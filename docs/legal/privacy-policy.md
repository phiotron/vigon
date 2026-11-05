# Chính sách quyền riêng tư — Ví Gọn (bản nháp để đăng)

> **Ghi chú nội bộ, KHÔNG đăng phần này.**
> - Bản nháp do Claude viết từ SPEC mục 6, D-002, D-007 và cách app chạy thật. Cập nhật 2026-11-04 cho **Android + iOS**, đã kiểm code:
>   Android `allowBackup=false` (`android/app/src/main/AndroidManifest.xml`); ~~không quyền INTERNET; không có mã gọi mạng trong `lib/`~~
>   (đã đổi theo D-025, xem ghi chú "Cập nhật 2026-11-05 theo D-025" bên dưới);
>   DB SQLite qua `driftDatabase(name: 'vigon')` → trên iOS nằm trong thư mục **Documents** của app, **không** đặt cờ loại khỏi sao lưu
>   → **có trong sao lưu iCloud/máy tính** nếu người dùng bật; PIN qua `flutter_secure_storage` 11.2.0 mặc định
>   (Android: khoá của Android Keystore; iOS: Keychain, `accessibility = unlocked`, `synchronizable = false`); file xuất ghi vào
>   thư mục tạm (`getTemporaryDirectory`) rồi mở share sheet (`share_plus`); khôi phục qua `file_picker`.
>   (Câu "không đặt cờ loại khỏi sao lưu" là trạng thái 2026-11-04; đã đổi theo D-021 — xem ghi chú 2026-11-05 cuối danh sách.)
> - Cập nhật 2026-11-05 (gộp bản 1.2 với giao diện/iOS của PLAN-001): **app tự xoá PIN cũ khi cài lại với dữ liệu mới** (D-017:
>   mã cài đặt `pin_install_id` trong bộ nhớ an toàn phải khớp `pinInstallId` trong bảng settings, lệch thì xoá PIN; `lib/src/data/pin_service.dart`,
>   `clearIfReinstalled`) → đã sửa mục 2 và mục 7 (bỏ câu "app có thể hỏi PIN cũ"). PIN đặt trước bản có mã này thì giữ nguyên, nhưng bản
>   iOS chưa phát hành nên người dùng iPhone không gặp trường hợp đó. Khôi phục iPhone từ sao lưu: DB và Keychain có thể về cùng nhau nên
>   PIN vẫn còn — viết là "có thể" vì CHƯA kiểm chứng trên Keychain thật (D-017 "Hệ quả").
> - Bản 1.2 (gộp vào `main` 2026-11-04, áp cho iOS theo D-019 ngày 2026-11-05): thêm nhắc ghi chép (thông báo cục bộ, **cả Android và iPhone**),
>   sao lưu tự động vào thư mục chọn, widget, mật khẩu file sao lưu, che nội dung đa nhiệm. ~~Sao lưu tự động, widget, che nội dung chỉ
>   Android~~ — **đã thay bằng D-022** (ghi chú cuối danh sách): nay cả ba có trên iPhone. Các tính năng này CHƯA kiểm chứng trên máy
>   thật; nếu ngày đăng khác ngày hiệu lực thì sửa cho khớp.
> - Rà lại 2026-11-05 (phiên store v2, `main` `a00bec8`): đối chiếu `AndroidManifest.xml` + manifest đã gộp bản release (đúng 2 quyền
>   `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`; `RECEIVE_BOOT_COMPLETED` là quyền thường, Android tự cấp khi cài → sửa mục 4, bỏ chữ
>   "tùy chọn" cho quyền này); `lib/src/platform_features.dart` (iOS ẩn sao lưu tự động, widget, che nội dung); `reminder_scheduler.dart`
>   (iOS không xin quyền lúc khởi tạo, chỉ khi bật công tắc; nội dung thông báo cố định trong `.arb`); `backup_crypto.dart` (AES-256-GCM +
>   PBKDF2, Dart thuần); `pin_service.dart` `clearIfReinstalled` được gọi ở `app_lock.dart`; DB iOS vẫn trong Documents, chưa loại khỏi
>   sao lưu iCloud → mục 2 giữ nguyên. Ngày hiệu lực để trống tới khi đăng; bỏ "Lịch sử thay đổi" vì đây là bản đăng đầu tiên.
> - **Cập nhật 2026-11-05 theo D-021** (người dùng quyết: DB iOS loại khỏi sao lưu hệ thống, giống Android `allowBackup=false`): mục 2
>   (bỏ ý "dữ liệu có trong sao lưu iPhone nếu bạn bật" → cả hai nền tảng không vào sao lưu Google/iCloud/máy tính, đổi máy thì tự xuất
>   file `.vigon`; viết lại câu khôi phục iPhone từ sao lưu: app bắt đầu trống, PIN cũ bị xoá theo D-017) và mục 7 (bỏ "bản sao lưu
>   iPhone/iCloud"). Code: commit `8441b6a` (phiên iOS, 2026-11-05) — mỗi lần mở DB đặt cờ `isExcludedFromBackup` cho thư mục Documents + `vigon.sqlite`
>   (`-wal`, `-shm`, `-journal`) qua kênh `vigon/backup_exclusion`; `ios.yml` bắt buộc log simulator `VigonBackupExclusion: excluded=≥2 failed=0`.
>   **Trước khi đăng: kiểm CI iOS xanh với bước đó**; chưa kiểm trên iPhone thật.
>   Mục PIN: Keychain mặc định `accessibility = unlocked` (không ThisDeviceOnly) nên mục PIN có thể vẫn đi theo bản sao lưu mã hoá
>   của iPhone — vì vậy câu viết "nếu mục mã PIN được khôi phục theo, app cũng xoá nó" (dựa trên D-017, chưa thử trên máy thật).
>   Cố ý KHÔNG hứa "chuyển máy trực tiếp không mang dữ liệu theo": Android 12+ ở máy một số hãng vẫn chuyển dữ liệu máy-sang-máy (D2D) dù
>   `allowBackup=false` (developer.android.com, Behavior changes Android 12 → Backup and restore); app chưa có `dataExtractionRules`.
>   Với iOS chưa kiểm cờ loại sao lưu có áp cho Quick Start. Câu chính sách chỉ nói về bản sao lưu (đám mây / máy tính).
>   D-020 (mã hoá, khai Pháp) không đổi chính sách: mục 3 đã nói AES-256-GCM.
> - **Cập nhật 2026-11-05 theo D-022** (người dùng quyết: iOS có đủ F-22, F-24, F-26 ngay bản 1; thay phần iOS của D-019 — câu
>   "iOS ẩn sao lưu tự động, widget, che nội dung" ở ghi chú rà lại phía trên không còn đúng). Đối chiếu code D4 (`ios/Runner/VigonNative.swift`,
>   `ios/VigonWidget/`, `lib/src/data/auto_backup_service.dart`) và chữ trong app (`autoBackupNoteIos`, `autoBackupRunsOnOpenIos`,
>   `autoBackupLocalFolderWarningIos`, `secureWindowNoteIos`):
>   mục 2 widget: có cả iPhone, số liệu nằm trong App Group `group.com.phiotron.vigon` (UserDefaults dùng chung chỉ giữa app và
>   extension widget, trên máy), luật PIN D-016 giữ nguyên, tắt công tắc/bật PIN thì lệnh `clear` xoá khoá; mục 3 sao lưu tự động: iPhone
>   chọn thư mục trong app Tệp (`UIDocumentPicker`, bookmark trong UserDefaults của app), chạy khi mở app, tối đa 1 lần/ngày, mật khẩu
>   trong Keychain (SecretStore), giữ 7 file, tắt thì xoá bookmark (`releaseFolder`); file trên iCloud Drive/Google Drive do Apple/nhà cung
>   cấp đó lưu — app không gửi đi, nhà phát triển không nhận; "nếu thư mục chỉ nằm trên điện thoại" khớp cảnh báo trong app (iOS không phân
>   biệt được "Trên iPhone" với Google Drive). File tự động nằm ngoài Documents của app nên không đụng D-021. Mục 7 bỏ "(Android)". Mục 9:
>   iPhone che bằng lớp phủ khi rời app/mở màn chuyển app, KHÔNG chặn chụp màn hình. Mục 4 không đổi (iOS không cần quyền cho các tính năng
>   này; "Nhận tín hiệu khởi động lại máy" vẫn chỉ Android). CHƯA kiểm trên iPhone thật (App Group, bộ chọn thư mục, lớp phủ — TestFlight).
> - **Cập nhật 2026-11-05 theo D-025** (người dùng quyết: đổi tiền tệ thì quy đổi mọi số tiền theo tỉ giá lấy qua mạng): app có quyền
>   `INTERNET` (Android, bản release) và một chỗ gọi mạng duy nhất: `lib/src/data/exchange_rate.dart` (`ErApiRateSource`,
>   `ioHttpGetText`, `dart:io HttpClient`) — chỉ `GET https://open.er-api.com/v6/latest/USD`, không query, không body, không cookie, không
>   theo chuyển hướng, chỉ khi người dùng chọn tiền tệ khác trong Cài đặt (hộp quy đổi). URL giống nhau cho mọi người dùng (bảng gốc USD)
>   nên không lộ tiền tệ đang dùng. Nhà cung cấp: ExchangeRate-API (AYR Tech (Pty) Ltd), gói Open Access: miễn phí, không khóa API, cho
>   dùng thương mại, bắt buộc ghi công kèm link (app hiện "Rates By Exchange Rate API" mở exchangerate-api.com), giới hạn tần suất theo IP.
>   Họ nhận IP + giờ + header kỹ thuật (User-Agent mặc định của Dart `Dart/x.y (dart:io)`, `Accept: application/json`) như mọi yêu cầu web.
>   Bảng tỉ giá và tỉ giá tự nhập lần trước lưu trong bảng `settings` (khóa `exchangeRates`, `exchangeRateManual`) nên cũng nằm trong file
>   sao lưu `.vigon` — không phải dữ liệu cá nhân. Sửa: mục 1 (thêm đoạn "Kết nối mạng duy nhất"), mục 3 (bỏ "Ví Gọn không kết nối mạng"),
>   mục 4 (quyền Internet), mục 5 (link ghi công), mục 10. **Người dùng cần duyệt câu chữ mục 1 và 4 trước khi đăng.** Nên đọc điều khoản
>   và chính sách quyền riêng tư của ExchangeRate-API (https://www.exchangerate-api.com/terms) trước khi đăng.
> - **Cập nhật 2026-11-05 (D8):** store khai **"không thu thập"** giống A001 (người dùng chốt): Data safety "No data collected / No data
>   shared", App Privacy "Data Not Collected" (`store/listing.md`, `store/app-store.md`). Lý do: yêu cầu tỉ giá không chứa dữ liệu người dùng;
>   IP đi kèm mọi kết nối Internet, nhà phát triển không nhận. Chính sách KHÔNG đổi: mục 1 (đã duyệt) đã nói nhà cung cấp tỉ giá nhận IP
>   như mọi yêu cầu web, theo chính sách của họ; tiêu đề mục 1 và mục 8 "không thu thập" khớp khai báo.
> - Không phải tư vấn pháp lý; luật sư nên đọc lại trước khi mở bán (COMPLIANCE D-07, D-09).
> - Thay `[Tên nhà phát triển]` bằng **đúng tên hiển thị trên Google Play và App Store** (tài khoản cá nhân → họ tên thật), điền ngày hiệu lực.
> - **Nơi đăng (gợi ý, người dùng tự đăng):**
>   1. **Google Sites** (khuyên dùng): miễn phí, không cần repo, sửa nhanh. Tạo site "Ví Gọn" với 2 trang: `privacy` (chép phần
>      Tiếng Việt + English bên dưới) và `support` (email + câu hỏi thường gặp, dùng cho Support URL của App Store). Bấm Publish,
>      chọn ai cũng xem được (không bắt đăng nhập).
>   2. **GitHub Pages**: repo `phiotron/vigon` đang private → Pages cho repo private cần gói trả phí; nếu muốn dùng thì tạo một
>      repo **public** riêng chỉ chứa 2 trang này (không đưa code app lên).
>   Sau khi đăng: điền URL vào `lib/src/app_info.dart` (`AppInfo.privacyPolicyUrl`, việc của phiên code), Play Console
>   (App content → Privacy policy) và App Store Connect (App Privacy → Privacy Policy URL; Support URL).
>   URL phải mở được không cần đăng nhập, không phải file PDF tải về, và ổn định lâu dài (đổi URL phải sửa cả app và hai store).

---

## Tiếng Việt

**Chính sách quyền riêng tư của Ví Gọn**
Ngày hiệu lực: [điền ngày đăng]

Ví Gọn là app ghi chép thu chi cá nhân cho điện thoại Android và iPhone. Chính sách này giải thích dữ liệu nào app lưu, lưu ở đâu và bạn kiểm soát nó ra sao.

**1. Chúng tôi không thu thập dữ liệu của bạn**
Ví Gọn không có máy chủ, không có tài khoản người dùng, không có quảng cáo, không có công cụ phân tích, theo dõi hay báo lỗi của bên thứ ba. App không gửi dữ liệu bạn nhập đi đâu. Nhà phát triển Ví Gọn không nhận, không xem và không chia sẻ bất kỳ dữ liệu nào bạn nhập vào app.

**Kết nối mạng duy nhất: tải tỉ giá khi bạn đổi tiền tệ.** App chỉ dùng Internet vào đúng một lúc: khi bạn chọn tiền tệ khác trong Cài đặt, app tải một bảng tỉ giá công khai (tính theo đô la Mỹ, giống nhau cho mọi người dùng) từ ExchangeRate-API (open.er-api.com) qua kết nối mã hóa HTTPS để quy đổi các số tiền. Yêu cầu này không chứa dữ liệu thu chi, tiền tệ bạn đang dùng hay bất kỳ thông tin nào bạn nhập; việc quy đổi diễn ra ngay trên điện thoại. Như mọi yêu cầu web, nhà cung cấp tỉ giá nhận được địa chỉ IP của bạn, thời điểm yêu cầu và thông tin kỹ thuật cơ bản của kết nối, và xử lý chúng theo chính sách của họ (exchangerate-api.com). Bảng tỉ giá tải về được lưu trên máy để lần sau không có mạng vẫn gợi ý được tỉ giá gần nhất. Không có mạng thì bạn có thể tự nhập tỉ giá. Ngoài lúc đổi tiền tệ, app không kết nối Internet.

**2. Dữ liệu nằm trên điện thoại của bạn**
Những gì bạn nhập (khoản thu, khoản chi, danh mục, tài khoản, ghi chú, ngân sách, khoản định kỳ, cài đặt) chỉ được lưu trong vùng lưu trữ riêng của app trên điện thoại. App khác không đọc được vùng này.
- **Android:** app tắt tính năng sao lưu tự động của chính Android (`allowBackup=false`), nên dữ liệu không tự được đưa lên đám mây.
- **iPhone:** app loại dữ liệu của mình khỏi bản sao lưu iCloud và sao lưu iPhone bằng máy tính, nên dữ liệu không được đưa lên đám mây hay vào bản sao lưu của máy.

Vì vậy trên cả hai nền tảng, đừng trông vào bản sao lưu của điện thoại để giữ dữ liệu Ví Gọn: khi bạn cài lại app hoặc khôi phục điện thoại từ bản sao lưu, dữ liệu của app không được khôi phục theo. Muốn mang dữ liệu sang máy khác, hãy tự xuất file sao lưu `.vigon` (mục 3) rồi chọn "Khôi phục từ bản sao lưu" trên máy mới.

Nếu bạn bật khóa bằng mã PIN, app chỉ lưu một giá trị băm có muối của mã PIN, không lưu mã PIN gốc. Trên Android, giá trị này nằm trong bộ nhớ an toàn được bảo vệ bằng Android Keystore. Trên iPhone, nó nằm trong Keychain của máy, không đồng bộ qua iCloud Keychain. iOS có thể giữ mục Keychain này cả sau khi bạn gỡ app; khi bạn cài lại và app bắt đầu với dữ liệu trống, app tự nhận ra điều đó và xóa mã PIN cũ, nên bạn không bị khóa bằng mã PIN của lần cài trước. Khi bạn khôi phục iPhone từ bản sao lưu iCloud hoặc máy tính, Ví Gọn bắt đầu với dữ liệu trống (vì dữ liệu không nằm trong bản sao lưu); nếu mục mã PIN trong Keychain được khôi phục theo, app cũng tự xóa nó như trên.

**Widget màn hình chính (Android và iPhone).** Nếu bạn thêm widget, widget luôn có hai nút "Chi" và "Thu" để mở nhanh màn nhập khoản. Mặc định widget không hiện số tiền nào. Chỉ khi bạn tự bật "Hiện số tiền trên widget" VÀ không dùng khóa PIN thì widget mới hiện số đã chi trong tháng (và hạn mức nếu bạn đã đặt ngân sách tháng). Khi khóa PIN đang bật, widget luôn ẩn số tiền. Số liệu này chỉ nằm trong bộ nhớ riêng của app trên máy (trên iPhone là vùng lưu trữ dùng chung chỉ giữa Ví Gọn và widget của chính nó) và trên màn hình chờ của bạn; không gửi đi đâu, và bị xóa khi bạn tắt công tắc hoặc bật PIN. Khi công tắc đang bật, ai cầm máy của bạn cũng có thể thấy số trên màn hình chờ.

**3. File sao lưu và CSV do bạn tự xuất**
Khi bạn chọn "Xuất bản sao lưu" hoặc "Xuất CSV", app tạo file trong thư mục tạm của app rồi mở bảng chia sẻ của hệ điều hành (bảng chia sẻ của Android hoặc iOS) để bạn chọn nơi gửi hoặc lưu, ví dụ app Tệp (Files), Google Drive hay email. Bạn quyết định file đi đâu. Bạn có thể đặt mật khẩu cho file sao lưu; khi đó file được mã hóa trên máy bạn bằng AES-256-GCM (mật khẩu không được lưu ở đâu cả, quên mật khẩu thì không mở được file). Không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn. Từ lúc đó, file chịu chính sách của dịch vụ bạn chọn. Hệ điều hành tự dọn thư mục tạm của app.
Bạn có thể bật thêm "Sao lưu tự động" (mặc định tắt). Khi bật, bạn tự chọn một thư mục và đặt mật khẩu sao lưu. Trên Android, bạn chọn thư mục bằng bộ chọn thư mục của hệ thống Android, và app tự ghi file sao lưu vào đó tối đa một lần mỗi ngày (khi dữ liệu có thay đổi). Trên iPhone, bạn chọn thư mục trong app Tệp (Files), ví dụ trong iCloud Drive; vì iPhone không cho app chạy theo giờ, app ghi file sao lưu khi bạn mở Ví Gọn, tối đa một lần mỗi ngày (khi dữ liệu có thay đổi). App giữ 7 file tự động gần nhất. Mọi file tự động luôn được mã hóa (AES-256-GCM), không bao giờ ghi bản rõ. Mật khẩu chỉ được lưu trong kho khóa an toàn của điện thoại bạn (Keystore trên Android, Keychain trên iPhone), không ghi vào file, nhật ký hay cơ sở dữ liệu và không gửi đi đâu. Quên mật khẩu thì không mở được các file sao lưu và nhà phát triển không thể khôi phục giúp bạn. Quyền ghi vào thư mục do hệ điều hành quản lý và chỉ áp dụng cho đúng thư mục bạn chọn. Nếu thư mục bạn chọn thuộc một dịch vụ lưu trữ như iCloud Drive, Google Drive hay OneDrive thì việc tải file lên đám mây do Apple hoặc app của dịch vụ đó thực hiện theo chính sách của họ; Ví Gọn không tự tải file lên đâu và nhà phát triển không nhận được file. Nếu thư mục chỉ nằm trên điện thoại, mất máy là mất luôn các file này. Khi tắt "Sao lưu tự động", app xóa mật khẩu khỏi kho khóa và bỏ quyền truy cập thư mục nhưng không xóa các file đã ghi; bạn tự xóa chúng nếu muốn.

**4. Quyền trên điện thoại**
Trên Android, Ví Gọn có quyền truy cập Internet chỉ để tải bảng tỉ giá khi bạn đổi tiền tệ (mục 1); Android cấp sẵn quyền này khi cài app, không hỏi bạn. Ngoài ra app chỉ có hai quyền, cả hai chỉ phục vụ "Nhắc ghi chép hằng ngày" (tính năng mặc định tắt):
• Thông báo: app chỉ xin khi bạn bật Nhắc ghi chép, sau một lời giải thích (Android 13 trở lên; trên iPhone là hộp thoại cho phép thông báo của iOS). Thông báo nhắc được tạo và nằm trên máy bạn, nội dung chung chung ("Hôm nay bạn đã ghi chi tiêu chưa?"), không chứa số liệu và không đi qua máy chủ nào. Từ chối thì app vẫn dùng bình thường.
• Nhận tín hiệu khởi động lại máy (chỉ Android): Android cấp sẵn quyền này khi cài app, không hỏi bạn. App chỉ dùng nó để đặt lại lịch nhắc sau khi bạn khởi động lại điện thoại (nếu bạn đã bật nhắc); quyền này không cho app đọc dữ liệu nào.
App không xin quyền vị trí, danh bạ, ảnh, camera hay micro. Chọn file khôi phục và chọn thư mục sao lưu dùng bộ chọn của hệ điều hành, chỉ truy cập đúng file hoặc thư mục bạn chọn.

**5. Liên kết ra ngoài**
Màn "Giới thiệu" có thể mở trình duyệt (để xem chính sách này) hoặc app email (để báo lỗi bảo mật). Hộp quy đổi tiền tệ có link ghi công nguồn tỉ giá, mở trang exchangerate-api.com trong trình duyệt. Các app và trang đó hoạt động theo chính sách riêng của chúng.

**6. Dữ liệu cửa hàng ứng dụng có thể thu thập**
Khi bạn tải app qua Google Play hoặc App Store, Google hoặc Apple có thể thu thập thông tin về việc cài đặt và sự cố app theo chính sách của họ và cài đặt trên máy bạn (ví dụ tùy chọn chia sẻ dữ liệu phân tích với nhà phát triển trên iPhone). Nhà phát triển chỉ thấy số liệu tổng hợp, ẩn danh trong Play Console và App Store Connect và không thể dùng chúng để nhận ra bạn.

**7. Quyền của bạn**
Vì dữ liệu chỉ nằm trên máy bạn, bạn tự thực hiện mọi quyền ngay trong app: xem và sửa từng khoản; xuất toàn bộ dữ liệu ra file (sao lưu hoặc CSV); xóa toàn bộ dữ liệu (cả mã PIN) trong Cài đặt → "Xóa toàn bộ dữ liệu"; hoặc gỡ app. Gỡ app sẽ xóa dữ liệu trên máy, trừ các file bạn đã tự xuất và các file sao lưu tự động trong thư mục bạn chọn. Trên iPhone, iOS có thể giữ lại mục mã PIN trong Keychain sau khi gỡ app; app tự xóa mục này khi được cài lại với dữ liệu mới (mục 2).

**8. Trẻ em**
Ví Gọn không nhắm tới trẻ em và không thu thập dữ liệu của bất kỳ ai, kể cả trẻ em.

**9. Bảo mật**
Dữ liệu được bảo vệ bằng cơ chế cách ly app của Android và iOS, khóa PIN tùy chọn và tùy chọn "Che nội dung khi chuyển app". Khóa PIN giúp ngăn người khác mở app trên máy bạn, nhưng không mã hóa dữ liệu. Khi bật tùy chọn che nội dung: trên Android, app chặn chụp màn hình và ẩn ảnh xem trước trong danh sách ứng dụng gần đây; trên iPhone, app phủ một lớp che lên nội dung khi bạn rời app hoặc mở màn chuyển app, nhưng iPhone không cho app chặn chụp màn hình. Khi chưa bật tùy chọn này, ảnh xem trước của app trong màn đa nhiệm có thể hiện số liệu đang mở. Nếu bạn phát hiện lỗ hổng bảo mật, hãy gửi email tới địa chỉ ở mục 11.

**10. Thay đổi chính sách**
Nếu Ví Gọn thay đổi cách xử lý dữ liệu (ví dụ thêm tính năng gửi dữ liệu qua Internet), chúng tôi sẽ cập nhật chính sách này và ngày hiệu lực trước khi phát hành bản có thay đổi.
Đây là bản đầu tiên của chính sách.

**11. Liên hệ**
[Tên nhà phát triển], nhà phát triển Ví Gọn — email: phamphuongphuongnd@gmail.com

---

## English

**Ví Gọn Privacy Policy**
Effective date: [fill in on publishing]

Ví Gọn is a personal income and expense tracker for Android phones and iPhone. This policy explains what data the app stores, where it is stored, and how you control it.

**1. We do not collect your data**
Ví Gọn has no server, no user accounts, no ads, and no third-party analytics, tracking or crash reporting tools. The app does not send the data you enter anywhere. The Ví Gọn developer does not receive, view, or share any data you enter in the app.

**The only network connection: downloading exchange rates when you change currency.** The app uses the Internet at exactly one moment: when you pick a different currency in Settings, it downloads a public exchange rate table (based on the US dollar, the same for every user) from ExchangeRate-API (open.er-api.com) over an encrypted HTTPS connection, in order to convert your amounts. The request contains no income or expense data, not the currency you use, and nothing you have entered; the conversion happens on your phone. As with any web request, the rate provider receives your IP address, the time of the request and basic technical details of the connection, and handles them under its own policy (exchangerate-api.com). The downloaded rate table is kept on your phone so the latest rate can be suggested next time you are offline. Without a connection, you can enter the rate yourself. Apart from changing currency, the app does not connect to the Internet.

**2. Your data stays on your phone**
What you enter (income, expenses, categories, accounts, notes, budget, recurring records, settings) is stored only in the app's private storage on your phone. Other apps cannot read it.
- **Android:** the app turns off Android's own automatic backup (`allowBackup=false`), so your data is not uploaded to the cloud on its own.
- **iPhone:** the app excludes its data from iCloud Backup and from iPhone backups made on a computer, so your data is not uploaded to the cloud or included in your phone's backups.

So on both platforms, do not rely on your phone's backups to keep your Ví Gọn data: when you reinstall the app or restore your phone from a backup, the app's data is not restored with it. To move your data to another phone, export a `.vigon` backup file yourself (section 3) and choose "Restore from backup" on the new phone.

If you turn on the PIN lock, the app stores only a salted hash of your PIN, never the PIN itself. On Android it is kept in secure storage protected by the Android Keystore. On iPhone it is kept in the device Keychain and is not synced through iCloud Keychain. iOS may keep this Keychain item even after you delete the app; when you reinstall and the app starts with empty data, it detects this and deletes the old PIN, so you are not locked out by the PIN from a previous install. When you restore your iPhone from an iCloud or computer backup, Ví Gọn starts with empty data (because its data is not in the backup); if the PIN Keychain item is restored as well, the app deletes it in the same way.

**Home screen widget (Android and iPhone).** If you add the widget, it always offers two buttons for quick entry of an expense or an income. By default the widget shows no amounts. Only if you turn on "Show amounts on widget" AND do not use the PIN lock does the widget show how much you spent this month (and your limit, if you set a monthly budget). While the PIN lock is on, the widget always hides amounts. These figures live only in the app's private storage on your phone (on iPhone, a storage area shared only between Ví Gọn and its own widget) and on your home screen; they are not sent anywhere and are erased when you turn the switch off or turn the PIN on. While the switch is on, anyone holding your phone can see the figures on the home screen.

**3. Backup and CSV files you export**
When you choose "Export backup" or "Export CSV", the app creates the file in its temporary folder and opens your phone's share sheet (Android or iOS) so you can choose where to send or save it, for example the Files app, Google Drive or email. You decide where the file goes. You can protect a backup file with a password, in which case it is encrypted on your phone with AES-256-GCM (the password is stored nowhere; if you forget it the file cannot be opened). Without a password the file is not encrypted, so keep it somewhere safe. From then on, the file is subject to the policy of the service you chose. The operating system clears the app's temporary folder on its own.
You can also turn on "Automatic backup" (off by default). When on, you choose a folder and set a backup password. On Android you choose the folder with Android's system folder picker, and the app writes a backup file there at most once a day (when the data has changed). On iPhone you choose a folder in the Files app, for example in iCloud Drive; because iPhone does not run apps on a schedule, the app writes the backup file when you open Ví Gọn, at most once a day (when the data has changed). The app keeps the 7 most recent automatic files. Automatic files are always encrypted (AES-256-GCM), never written in plain form. The password is kept only in your phone's secure key store (Keystore on Android, Keychain on iPhone); it is not written to any file, log or database and is not sent anywhere. If you forget the password, the backup files cannot be opened and the developer cannot recover them for you. Write access to the folder is managed by the operating system and covers only the folder you chose. If the folder you choose belongs to a storage service such as iCloud Drive, Google Drive or OneDrive, Apple or that service's own app uploads the files under its own policy; Ví Gọn does not upload them itself and the developer never receives the files. If the folder is stored only on your phone, losing the phone means losing these files. When you turn "Automatic backup" off, the app deletes the password from the key store and releases its access to the folder, but does not delete files already written; delete them yourself if you wish.

**4. Phone permissions**
On Android, Ví Gọn has the Internet permission only to download the exchange rate table when you change currency (section 1); Android grants it when the app is installed, without asking you. Apart from that the app has only two permissions, both used only for the "Daily reminder" (a feature that is off by default):
• Notifications: the app asks only when you turn on the reminder, after a short explanation (Android 13 and later; on iPhone, iOS's own notification prompt). The reminder is created and stays on your phone, its text is generic ("Have you recorded your spending today?"), it contains no figures and does not pass through any server. If you decline, the app works normally.
• Receive restart signal (Android only): Android grants this permission when the app is installed, without asking you. The app uses it only to restore the reminder schedule after you restart your phone (if you turned the reminder on); it does not let the app read any data.
The app does not ask for location, contacts, photos, camera or microphone. Restoring a backup and choosing the backup folder use the system pickers and access only the file or folder you pick.

**5. Links to other apps**
The "About" screen can open your browser (to show this policy) or your email app (to report a security issue). The currency conversion dialog has an attribution link to the exchange rate source, which opens exchangerate-api.com in your browser. Those apps and sites follow their own policies.

**6. Data the app stores may collect**
When you install the app from Google Play or the App Store, Google or Apple may collect information about installs and app crashes under their own policies and your device settings (for example, the option on iPhone to share analytics with app developers). The developer sees only aggregated, anonymous figures in Play Console and App Store Connect and cannot use them to identify you.

**7. Your rights**
Because your data is only on your phone, you exercise every right directly in the app: view and edit each record; export all data to a file (backup or CSV); delete all data (including the PIN) in Settings → "Delete all data"; or uninstall the app. Uninstalling removes the data on the phone, except files you have exported yourself and automatic backup files in the folder you chose. On iPhone, iOS may keep the PIN Keychain item after you delete the app; the app deletes it when it is reinstalled with fresh data (section 2).

**8. Children**
Ví Gọn is not directed at children and does not collect data from anyone, including children.

**9. Security**
Your data is protected by the Android and iOS app sandbox, the optional PIN lock and the option "Hide content when switching apps". The PIN lock stops other people from opening the app on your phone, but it does not encrypt the data. When the hide-content option is on: on Android, the app blocks screenshots and hides its preview in the recent apps list; on iPhone, the app covers its content when you leave the app or open the app switcher, but iPhone does not let apps block screenshots. While the option is off, the app preview in the multitasking screen may show the figures that were open. If you find a security vulnerability, please email the address in section 11.

**10. Changes to this policy**
If Ví Gọn changes how it handles data (for example by adding a feature that sends data over the Internet), we will update this policy and its effective date before releasing that version.
This is the first version of this policy.

**11. Contact**
[Developer name], developer of Ví Gọn — email: phamphuongphuongnd@gmail.com
