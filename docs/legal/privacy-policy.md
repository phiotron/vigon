# Chính sách quyền riêng tư — Ví Gọn (bản nháp để đăng)

> **Ghi chú nội bộ, KHÔNG đăng phần này.**
> - Bản nháp do Claude viết từ SPEC mục 6, D-002, D-007 và cách app chạy thật. Cập nhật 2026-11-04 cho **Android + iOS**, đã kiểm code:
>   Android `allowBackup=false` (`android/app/src/main/AndroidManifest.xml`); không quyền INTERNET; không có mã gọi mạng trong `lib/`;
>   DB SQLite qua `driftDatabase(name: 'vigon')` → trên iOS nằm trong thư mục **Documents** của app, **không** đặt cờ loại khỏi sao lưu
>   → **có trong sao lưu iCloud/máy tính** nếu người dùng bật; PIN qua `flutter_secure_storage` 11.2.0 mặc định
>   (Android: khoá của Android Keystore; iOS: Keychain, `accessibility = unlocked`, `synchronizable = false`); file xuất ghi vào
>   thư mục tạm (`getTemporaryDirectory`) rồi mở share sheet (`share_plus`); khôi phục qua `file_picker`.
>   Nếu code đổi (ví dụ loại DB khỏi sao lưu iCloud, xoá PIN khi cài lại) thì sửa mục 2 cho khớp.
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
Ví Gọn không có máy chủ, không có tài khoản người dùng, không có quảng cáo, không có công cụ phân tích, theo dõi hay báo lỗi của bên thứ ba. App không kết nối Internet (trên Android, app không có cả quyền truy cập Internet) nên không gửi dữ liệu đi. Nhà phát triển Ví Gọn không nhận, không xem và không chia sẻ bất kỳ dữ liệu nào bạn nhập vào app.

**2. Dữ liệu nằm trên điện thoại của bạn**
Những gì bạn nhập (khoản thu, khoản chi, danh mục, tài khoản, ghi chú, ngân sách, khoản định kỳ, cài đặt) chỉ được lưu trong vùng lưu trữ riêng của app trên điện thoại. App khác không đọc được vùng này.
- **Android:** app tắt tính năng sao lưu tự động của Android, nên dữ liệu không tự được đưa lên đám mây.
- **iPhone:** như mọi app khác, dữ liệu của Ví Gọn nằm trong bản sao lưu iPhone nếu bạn bật Sao lưu iCloud hoặc sao lưu iPhone bằng máy tính. Bản sao lưu đó do Apple và bạn quản lý theo chính sách của Apple; nhà phát triển không truy cập được.

Nếu bạn bật khóa bằng mã PIN, app chỉ lưu một giá trị băm có muối của mã PIN, không lưu mã PIN gốc. Trên Android, giá trị này nằm trong bộ nhớ an toàn được bảo vệ bằng Android Keystore. Trên iPhone, nó nằm trong Keychain của máy, không đồng bộ qua iCloud Keychain. Lưu ý trên iPhone: iOS có thể giữ mục Keychain này cả sau khi bạn gỡ app; nếu cài lại, app có thể hỏi mã PIN cũ. Khi đó bạn dùng "Quên mã" để xóa dữ liệu trong app và mã PIN.

**3. File sao lưu và CSV do bạn tự xuất**
Khi bạn chọn "Xuất bản sao lưu" hoặc "Xuất CSV", app tạo file trong thư mục tạm của app rồi mở bảng chia sẻ của hệ điều hành (bảng chia sẻ của Android hoặc iOS) để bạn chọn nơi gửi hoặc lưu, ví dụ app Tệp (Files), Google Drive hay email. Bạn quyết định file đi đâu. File sao lưu không được mã hóa; hãy cất ở nơi an toàn. Từ lúc đó, file chịu chính sách của dịch vụ bạn chọn. Hệ điều hành tự dọn thư mục tạm của app.

**4. Quyền trên điện thoại**
Ví Gọn không xin quyền nào (không vị trí, danh bạ, ảnh, camera, micro hay thông báo). Khôi phục bản sao lưu dùng trình chọn file của hệ điều hành và chỉ đọc đúng file bạn chọn.

**5. Liên kết ra ngoài**
Màn "Giới thiệu" có thể mở trình duyệt (để xem chính sách này) hoặc app email (để báo lỗi bảo mật). Các app đó hoạt động theo chính sách riêng của chúng.

**6. Dữ liệu cửa hàng ứng dụng có thể thu thập**
Khi bạn tải app qua Google Play hoặc App Store, Google hoặc Apple có thể thu thập thông tin về việc cài đặt và sự cố app theo chính sách của họ và cài đặt trên máy bạn (ví dụ tùy chọn chia sẻ dữ liệu phân tích với nhà phát triển trên iPhone). Nhà phát triển chỉ thấy số liệu tổng hợp, ẩn danh trong Play Console và App Store Connect và không thể dùng chúng để nhận ra bạn.

**7. Quyền của bạn**
Vì dữ liệu chỉ nằm trên máy bạn, bạn tự thực hiện mọi quyền ngay trong app: xem và sửa từng khoản; xuất toàn bộ dữ liệu ra file (sao lưu hoặc CSV); xóa toàn bộ dữ liệu (cả mã PIN) trong Cài đặt → "Xóa toàn bộ dữ liệu"; hoặc gỡ app. Gỡ app sẽ xóa dữ liệu trên máy, trừ các file bạn đã tự xuất, bản sao lưu iPhone/iCloud bạn đã tạo trước đó, và mục mã PIN trong Keychain mà iOS có thể giữ lại (mục 2).

**8. Trẻ em**
Ví Gọn không nhắm tới trẻ em và không thu thập dữ liệu của bất kỳ ai, kể cả trẻ em.

**9. Bảo mật**
Dữ liệu được bảo vệ bằng cơ chế cách ly app của Android và iOS, cùng khóa PIN tùy chọn. Khóa PIN giúp ngăn người khác mở app trên máy bạn, nhưng không mã hóa dữ liệu. Ảnh xem trước của app trong màn đa nhiệm có thể hiện số liệu đang mở. Nếu bạn phát hiện lỗ hổng bảo mật, hãy gửi email tới địa chỉ ở mục 11.

**10. Thay đổi chính sách**
Nếu Ví Gọn thay đổi cách xử lý dữ liệu (ví dụ thêm tính năng cần Internet), chúng tôi sẽ cập nhật chính sách này và ngày hiệu lực trước khi phát hành bản có thay đổi.

**11. Liên hệ**
[Tên nhà phát triển], nhà phát triển Ví Gọn — email: phamphuongphuong@gmail.com

---

## English

**Ví Gọn Privacy Policy**
Effective date: [fill in on publishing]

Ví Gọn is a personal income and expense tracker for Android phones and iPhone. This policy explains what data the app stores, where it is stored, and how you control it.

**1. We do not collect your data**
Ví Gọn has no server, no user accounts, no ads, and no third-party analytics, tracking or crash reporting tools. The app does not connect to the Internet (on Android it does not even have the Internet permission), so it does not send data anywhere. The Ví Gọn developer does not receive, view, or share any data you enter in the app.

**2. Your data stays on your phone**
What you enter (income, expenses, categories, accounts, notes, budget, recurring records, settings) is stored only in the app's private storage on your phone. Other apps cannot read it.
- **Android:** the app turns off Android's automatic backup, so your data is not uploaded to the cloud on its own.
- **iPhone:** like any other app, Ví Gọn's data is included in your iPhone backup if you turn on iCloud Backup or back up your iPhone to a computer. Those backups are managed by Apple and you under Apple's policies; the developer cannot access them.

If you turn on the PIN lock, the app stores only a salted hash of your PIN, never the PIN itself. On Android it is kept in secure storage protected by the Android Keystore. On iPhone it is kept in the device Keychain and is not synced through iCloud Keychain. Note for iPhone: iOS may keep this Keychain item even after you delete the app; if you reinstall, the app may ask for your old PIN. In that case, use "Forgot PIN" to delete the app's data and the PIN.

**3. Backup and CSV files you export**
When you choose "Export backup" or "Export CSV", the app creates the file in its temporary folder and opens your phone's share sheet (Android or iOS) so you can choose where to send or save it, for example the Files app, Google Drive or email. You decide where the file goes. Backup files are not encrypted; keep them somewhere safe. From then on, the file is subject to the policy of the service you chose. The operating system clears the app's temporary folder on its own.

**4. Phone permissions**
Ví Gọn does not request any permissions (no location, contacts, photos, camera, microphone or notifications). Restoring a backup uses the system file picker and reads only the file you pick.

**5. Links to other apps**
The "About" screen can open your browser (to show this policy) or your email app (to report a security issue). Those apps follow their own policies.

**6. Data the app stores may collect**
When you install the app from Google Play or the App Store, Google or Apple may collect information about installs and app crashes under their own policies and your device settings (for example, the option on iPhone to share analytics with app developers). The developer sees only aggregated, anonymous figures in Play Console and App Store Connect and cannot use them to identify you.

**7. Your rights**
Because your data is only on your phone, you exercise every right directly in the app: view and edit each record; export all data to a file (backup or CSV); delete all data (including the PIN) in Settings → "Delete all data"; or uninstall the app. Uninstalling removes the data on the phone, except files you have exported yourself, iPhone/iCloud backups you made earlier, and the PIN Keychain item that iOS may keep (section 2).

**8. Children**
Ví Gọn is not directed at children and does not collect data from anyone, including children.

**9. Security**
Your data is protected by the Android and iOS app sandbox and the optional PIN lock. The PIN lock stops other people from opening the app on your phone, but it does not encrypt the data. The app preview in the multitasking screen may show the figures that were open. If you find a security vulnerability, please email the address in section 11.

**10. Changes to this policy**
If Ví Gọn changes how it handles data (for example by adding a feature that needs the Internet), we will update this policy and its effective date before releasing that version.

**11. Contact**
[Developer name], developer of Ví Gọn — email: phamphuongphuong@gmail.com
