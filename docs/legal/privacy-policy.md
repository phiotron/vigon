# Chính sách quyền riêng tư — Ví Gọn (bản nháp để đăng)

> Ghi chú nội bộ, KHÔNG đăng phần này: bản nháp do Claude viết từ SPEC mục 6, D-002 và cách app chạy thật (không quyền INTERNET, `allowBackup=false`). Không phải tư vấn pháp lý; luật sư nên đọc lại trước khi mở bán (COMPLIANCE D-07, D-09). Khi đăng: chép phần tiếng Việt và tiếng Anh dưới đây lên Google Sites, điền ngày hiệu lực, rồi đưa đường dẫn vào `lib/src/app_info.dart` và Play Console. Khi chốt phát hành dưới tên cá nhân hay công ty, thay "nhà phát triển Ví Gọn" bằng tên đó.

---

## Tiếng Việt

**Chính sách quyền riêng tư của Ví Gọn**
Ngày hiệu lực: [điền ngày đăng]

Ví Gọn là app ghi chép thu chi cá nhân trên điện thoại Android. Chính sách này giải thích dữ liệu nào app lưu, lưu ở đâu và bạn kiểm soát nó ra sao.

**1. Chúng tôi không thu thập dữ liệu của bạn**
Ví Gọn không có máy chủ, không có tài khoản người dùng, không có quảng cáo, không có công cụ phân tích hay báo lỗi của bên thứ ba. App không có quyền truy cập Internet nên không thể gửi dữ liệu đi. Nhà phát triển Ví Gọn không nhận, không xem và không chia sẻ bất kỳ dữ liệu nào bạn nhập vào app.

**2. Dữ liệu nằm trên điện thoại của bạn**
Những gì bạn nhập (khoản thu, khoản chi, danh mục, tài khoản, ghi chú, ngân sách, cài đặt) chỉ được lưu trong bộ nhớ riêng của app trên điện thoại. App tắt tính năng sao lưu tự động của Android, nên dữ liệu không tự được đưa lên đám mây.
Nếu bạn bật khóa bằng mã PIN, app chỉ lưu một giá trị băm có muối của mã PIN trong bộ nhớ an toàn của Android, không lưu mã PIN gốc.

**3. File sao lưu và CSV do bạn tự xuất**
Khi bạn chọn "Xuất bản sao lưu" hoặc "Xuất CSV", app tạo một file và mở bảng chia sẻ của Android để bạn chọn nơi gửi hoặc lưu. Bạn quyết định file đi đâu (ví dụ Google Drive, email). File sao lưu không được mã hóa; hãy cất ở nơi an toàn. Từ lúc đó, file chịu chính sách của dịch vụ bạn chọn.

**4. Quyền trên điện thoại**
Ví Gọn không xin quyền nào. Chọn file khôi phục dùng trình chọn file của Android, chỉ đọc đúng file bạn chọn.

**5. Liên kết ra ngoài**
Màn "Giới thiệu" có thể mở trình duyệt (để xem chính sách này) hoặc app email (để báo lỗi bảo mật). Các app đó hoạt động theo chính sách riêng của chúng.

**6. Dữ liệu Google Play có thể thu thập**
Khi bạn tải app qua Google Play, Google có thể thu thập thông tin về việc cài đặt và sự cố app theo chính sách của Google và cài đặt trên máy bạn. Nhà phát triển chỉ thấy số liệu tổng hợp, ẩn danh trong Play Console và không thể dùng chúng để nhận ra bạn.

**7. Quyền của bạn**
Vì dữ liệu chỉ nằm trên máy bạn, bạn tự thực hiện mọi quyền ngay trong app: xem và sửa từng khoản; xuất toàn bộ dữ liệu ra file (sao lưu hoặc CSV); xóa toàn bộ dữ liệu trong Cài đặt → "Xóa toàn bộ dữ liệu"; hoặc gỡ app. Gỡ app sẽ xóa dữ liệu trên máy, trừ các file bạn đã tự xuất.

**8. Trẻ em**
Ví Gọn không nhắm tới trẻ em và không thu thập dữ liệu của bất kỳ ai, kể cả trẻ em.

**9. Bảo mật**
Dữ liệu được bảo vệ bằng cơ chế cách ly app của Android và khóa PIN tùy chọn. Khóa PIN giúp ngăn người khác mở app trên máy bạn, nhưng không mã hóa dữ liệu. Nếu bạn phát hiện lỗ hổng bảo mật, hãy gửi email tới địa chỉ ở mục 11.

**10. Thay đổi chính sách**
Nếu Ví Gọn thay đổi cách xử lý dữ liệu (ví dụ thêm tính năng cần Internet), chúng tôi sẽ cập nhật chính sách này và ngày hiệu lực trước khi phát hành bản có thay đổi.

**11. Liên hệ**
Nhà phát triển Ví Gọn — email: phamphuongphuong@gmail.com

---

## English

**Ví Gọn Privacy Policy**
Effective date: [fill in on publishing]

Ví Gọn is a personal income and expense tracker for Android phones. This policy explains what data the app stores, where it is stored, and how you control it.

**1. We do not collect your data**
Ví Gọn has no server, no user accounts, no ads, and no third-party analytics or crash reporting tools. The app has no Internet permission, so it cannot send data anywhere. The Ví Gọn developer does not receive, view, or share any data you enter in the app.

**2. Your data stays on your phone**
What you enter (income, expenses, categories, accounts, notes, budget, settings) is stored only in the app's private storage on your phone. The app turns off Android's automatic backup, so your data is not uploaded to the cloud on its own.
If you turn on the PIN lock, the app stores only a salted hash of your PIN in Android's secure storage, never the PIN itself.

**3. Backup and CSV files you export**
When you choose "Export backup" or "Export CSV", the app creates a file and opens Android's share sheet so you can choose where to send or save it. You decide where the file goes (for example Google Drive or email). Backup files are not encrypted; keep them somewhere safe. From then on, the file is subject to the policy of the service you chose.

**4. Phone permissions**
Ví Gọn does not request any permissions. Restoring a backup uses Android's file picker and reads only the file you pick.

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

**11. Contact**
Ví Gọn developer — email: phamphuongphuong@gmail.com
