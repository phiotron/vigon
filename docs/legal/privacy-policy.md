# Chính sách quyền riêng tư — Ví Gọn (bản nháp để đăng)

> Ghi chú nội bộ, KHÔNG đăng phần này: bản nháp do Claude viết từ SPEC mục 6, D-002 và cách app chạy thật (không quyền INTERNET, `allowBackup=false`). Không phải tư vấn pháp lý; luật sư nên đọc lại trước khi mở bán (COMPLIANCE D-07, D-09). Bản 1.2 (2026-11-04) đã cập nhật theo SPEC-1.2 (sao lưu tự động, nhắc ghi chép, widget; quyền thông báo và nhận tín hiệu khởi động lại); các tính năng này CHƯA kiểm chứng trên máy thật, nếu ngày đăng khác ngày hiệu lực thì sửa cho khớp. Khi đăng: chép phần tiếng Việt và tiếng Anh dưới đây lên Google Sites, rồi đưa đường dẫn vào `lib/src/app_info.dart` và Play Console. Khi chốt phát hành dưới tên cá nhân hay công ty, thay "nhà phát triển Ví Gọn" bằng tên đó.

---

## Tiếng Việt

**Chính sách quyền riêng tư của Ví Gọn**
Ngày hiệu lực: 2026-11-04

Ví Gọn là app ghi chép thu chi cá nhân trên điện thoại Android. Chính sách này giải thích dữ liệu nào app lưu, lưu ở đâu và bạn kiểm soát nó ra sao.

**1. Chúng tôi không thu thập dữ liệu của bạn**
Ví Gọn không có máy chủ, không có tài khoản người dùng, không có quảng cáo, không có công cụ phân tích hay báo lỗi của bên thứ ba. App không có quyền truy cập Internet nên không thể gửi dữ liệu đi. Nhà phát triển Ví Gọn không nhận, không xem và không chia sẻ bất kỳ dữ liệu nào bạn nhập vào app.

**2. Dữ liệu nằm trên điện thoại của bạn**
Những gì bạn nhập (khoản thu, khoản chi, danh mục, tài khoản, ghi chú, ngân sách, cài đặt) chỉ được lưu trong bộ nhớ riêng của app trên điện thoại. App tắt tính năng sao lưu đám mây tự động của chính Android (`allowBackup=false`), nên dữ liệu không tự được đưa lên đám mây.
Nếu bạn bật khóa bằng mã PIN, app chỉ lưu một giá trị băm có muối của mã PIN trong bộ nhớ an toàn của Android, không lưu mã PIN gốc.
Nếu bạn thêm widget màn hình chính, widget luôn có hai nút "Chi" và "Thu" để mở nhanh màn nhập khoản. Mặc định widget không hiện số tiền nào. Chỉ khi bạn tự bật "Hiện số tiền trên widget" VÀ không dùng khóa PIN thì widget mới hiện số đã chi trong tháng (và hạn mức nếu bạn đã đặt ngân sách tháng). Khi khóa PIN đang bật, widget luôn ẩn số tiền. Số liệu này chỉ nằm trong bộ nhớ riêng của app và trên màn hình chờ của bạn; không gửi đi đâu, và bị xóa khi bạn tắt công tắc hoặc bật PIN. Khi công tắc đang bật, ai cầm máy của bạn cũng có thể thấy số trên màn hình chờ.

**3. File sao lưu và CSV do bạn tự xuất**
Khi bạn chọn "Xuất bản sao lưu" hoặc "Xuất CSV", app tạo một file và mở bảng chia sẻ của Android để bạn chọn nơi gửi hoặc lưu. Bạn quyết định file đi đâu (ví dụ Google Drive, email). Bạn có thể đặt mật khẩu cho file sao lưu; khi đó file được mã hóa trên máy bạn (mật khẩu không được lưu ở đâu cả, quên mật khẩu thì không mở được file). Không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn. Từ lúc đó, file chịu chính sách của dịch vụ bạn chọn.
Ngoài ra, bạn có thể bật "Sao lưu tự động" (mặc định tắt). Khi bật, bạn tự chọn một thư mục bằng bộ chọn thư mục của hệ thống Android và đặt mật khẩu sao lưu. App tự ghi file sao lưu vào thư mục đó tối đa một lần mỗi ngày (khi dữ liệu có thay đổi) và giữ 7 file tự động gần nhất. Mọi file tự động luôn được mã hóa (AES-256-GCM), không bao giờ ghi bản rõ. Mật khẩu chỉ được lưu trong kho khóa an toàn (Keystore) của điện thoại bạn, không ghi vào file, nhật ký hay cơ sở dữ liệu và không gửi đi đâu. Quên mật khẩu thì không mở được các file sao lưu và nhà phát triển không thể khôi phục giúp bạn. Quyền ghi vào thư mục do hệ thống Android quản lý và chỉ áp dụng cho đúng thư mục bạn chọn. Nếu thư mục bạn chọn thuộc một dịch vụ như Google Drive hay OneDrive thì việc tải lên đám mây do app của dịch vụ đó thực hiện theo chính sách của họ; Ví Gọn không kết nối mạng. Khi tắt "Sao lưu tự động", app xóa mật khẩu khỏi kho khóa và bỏ quyền thư mục nhưng không xóa các file đã ghi; bạn tự xóa chúng nếu muốn.

**4. Quyền trên điện thoại**
Ví Gọn có tối đa hai quyền, cả hai đều tùy chọn, và không có quyền truy cập Internet:
• Thông báo: chỉ khi bạn bật "Nhắc ghi chép hằng ngày" (mặc định tắt). App giải thích trước rồi mới xin quyền này (Android 13 trở lên). Thông báo nhắc được tạo và nằm trên máy bạn, nội dung chung chung ("Hôm nay bạn đã ghi chi tiêu chưa?"), không chứa số liệu và không đi qua máy chủ nào. Từ chối thì app vẫn dùng bình thường.
• Nhận tín hiệu khởi động lại máy: để đặt lại lịch nhắc sau khi bạn khởi động lại điện thoại. Quyền này không cho app đọc dữ liệu nào.
Chọn file khôi phục và chọn thư mục sao lưu dùng bộ chọn của Android, chỉ truy cập đúng file hoặc thư mục bạn chọn.

**5. Liên kết ra ngoài**
Màn "Giới thiệu" có thể mở trình duyệt (để xem chính sách này) hoặc app email (để báo lỗi bảo mật). Các app đó hoạt động theo chính sách riêng của chúng.

**6. Dữ liệu Google Play có thể thu thập**
Khi bạn tải app qua Google Play, Google có thể thu thập thông tin về việc cài đặt và sự cố app theo chính sách của Google và cài đặt trên máy bạn. Nhà phát triển chỉ thấy số liệu tổng hợp, ẩn danh trong Play Console và không thể dùng chúng để nhận ra bạn.

**7. Quyền của bạn**
Vì dữ liệu chỉ nằm trên máy bạn, bạn tự thực hiện mọi quyền ngay trong app: xem và sửa từng khoản; xuất toàn bộ dữ liệu ra file (sao lưu hoặc CSV); xóa toàn bộ dữ liệu trong Cài đặt → "Xóa toàn bộ dữ liệu"; hoặc gỡ app. Gỡ app sẽ xóa dữ liệu trên máy, trừ các file bạn đã tự xuất.

**8. Trẻ em**
Ví Gọn không nhắm tới trẻ em và không thu thập dữ liệu của bất kỳ ai, kể cả trẻ em.

**9. Bảo mật**
Dữ liệu được bảo vệ bằng cơ chế cách ly app của Android, khóa PIN tùy chọn và tùy chọn che nội dung ở màn hình ứng dụng gần đây (chặn chụp màn hình). Khóa PIN giúp ngăn người khác mở app trên máy bạn, nhưng không mã hóa dữ liệu. Nếu bạn phát hiện lỗ hổng bảo mật, hãy gửi email tới địa chỉ ở mục 11.

**10. Thay đổi chính sách**
Nếu Ví Gọn thay đổi cách xử lý dữ liệu (ví dụ thêm tính năng cần Internet), chúng tôi sẽ cập nhật chính sách này và ngày hiệu lực trước khi phát hành bản có thay đổi.
Lịch sử thay đổi: 2026-11-04 (bản 1.2) thay mục "không xin quyền nào" bằng hai quyền tùy chọn (thông báo, nhận tín hiệu khởi động lại), thêm sao lưu tự động vào thư mục bạn chọn và widget màn hình chính. Các cam kết khác không đổi: không tài khoản, không quảng cáo, không phân tích, không quyền Internet.

**11. Liên hệ**
Nhà phát triển Ví Gọn — email: phamphuongphuong@gmail.com

---

## English

**Ví Gọn Privacy Policy**
Effective date: 2026-11-04

Ví Gọn is a personal income and expense tracker for Android phones. This policy explains what data the app stores, where it is stored, and how you control it.

**1. We do not collect your data**
Ví Gọn has no server, no user accounts, no ads, and no third-party analytics or crash reporting tools. The app has no Internet permission, so it cannot send data anywhere. The Ví Gọn developer does not receive, view, or share any data you enter in the app.

**2. Your data stays on your phone**
What you enter (income, expenses, categories, accounts, notes, budget, settings) is stored only in the app's private storage on your phone. The app turns off Android's own automatic cloud backup (`allowBackup=false`), so your data is not uploaded to the cloud on its own.
If you turn on the PIN lock, the app stores only a salted hash of your PIN in Android's secure storage, never the PIN itself.
If you add the home screen widget, it always offers two buttons for quick entry of an expense or an income. By default the widget shows no amounts. Only if you turn on "Show amounts on widget" AND do not use the PIN lock does the widget show how much you spent this month (and your limit, if you set a monthly budget). While the PIN lock is on, the widget always hides amounts. These figures live only in the app's private storage and on your home screen; they are not sent anywhere and are erased when you turn the switch off or turn the PIN on. While the switch is on, anyone holding your phone can see the figures on the home screen.

**3. Backup and CSV files you export**
When you choose "Export backup" or "Export CSV", the app creates a file and opens Android's share sheet so you can choose where to send or save it. You decide where the file goes (for example Google Drive or email). You can protect a backup file with a password, in which case it is encrypted on your phone (the password is stored nowhere; if you forget it the file cannot be opened). Without a password the file is not encrypted, so keep it somewhere safe. From then on, the file is subject to the policy of the service you chose.
You can also turn on "Automatic backup" (off by default). When on, you choose a folder with Android's system folder picker and set a backup password. The app then writes a backup file to that folder at most once a day (when the data has changed) and keeps the 7 most recent automatic files. Automatic files are always encrypted (AES-256-GCM), never written in plain form. The password is kept only in your phone's secure key store (Keystore); it is not written to any file, log or database and is not sent anywhere. If you forget the password, the backup files cannot be opened and the developer cannot recover them for you. Write access to the folder is managed by the Android system and covers only the folder you chose. If the folder you choose belongs to a service such as Google Drive or OneDrive, that service's own app uploads the files under its own policy; Ví Gọn does not connect to the network. When you turn "Automatic backup" off, the app deletes the password from the key store and releases the folder permission, but does not delete files already written; delete them yourself if you wish.

**4. Phone permissions**
Ví Gọn has at most two permissions, both optional, and has no Internet permission:
• Notifications: only when you turn on the "Daily reminder" (off by default). The app explains first, then asks for this permission (Android 13 and later). The reminder is created and stays on your phone, its text is generic ("Have you recorded your spending today?"), it contains no figures and does not pass through any server. If you decline, the app works normally.
• Receive restart signal: so the reminder schedule can be restored after you restart your phone. This permission does not let the app read any data.
Restoring a backup and choosing the backup folder use Android's pickers and access only the file or folder you pick.

**5. Links to other apps**
The "About" screen can open your browser (to show this policy) or your email app (to report a security issue). Those apps follow their own policies.

**6. Data Google Play may collect**
When you install the app from Google Play, Google may collect information about installs and app crashes under Google's policies and your device settings. The developer sees only aggregated, anonymous figures in Play Console and cannot use them to identify you.

**7. Your rights**
Because your data is only on your phone, you exercise every right directly in the app: view and edit each record; export all data to a file (backup or CSV); delete all data in Settings → "Delete all data"; or uninstall the app. Uninstalling removes the data on the phone, except files you have exported yourself.

**8. Children**
Ví Gọn is not directed at children and does not collect data from anyone, including children.

**9. Security**
Your data is protected by Android's app sandbox and the optional PIN lock. The PIN lock stops other people from opening the app on your phone, but it does not encrypt the data. If you find a security vulnerability, please email the address in section 11.

**10. Changes to this policy**
If Ví Gọn changes how it handles data (for example by adding a feature that needs the Internet), we will update this policy and its effective date before releasing that version.
Change history: 2026-11-04 (version 1.2) replaced "does not request any permissions" with two optional permissions (notifications, receive restart signal), and added automatic backup to a folder you choose and the home screen widget. Other commitments are unchanged: no accounts, no ads, no analytics, no Internet permission.

**11. Contact**
Ví Gọn developer — email: phamphuongphuong@gmail.com
