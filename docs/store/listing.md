# Hồ sơ store — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào Google Play Console ở `/release`. Cập nhật 2026-11-04 cho bản 1.2 (SPEC-1.2: sao lưu tự động, nhắc ghi chép, widget). Người dùng duyệt tên và nội dung trước khi nộp. Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7).

## Tên
- Tiếng Việt: **Ví Gọn** (≤ 30 ký tự)
- Tiếng Anh: chưa chốt. Gợi ý: Neat Wallet, Tidy Wallet, Pocket Ledger. Phải tra trùng tên trên Google Play trước khi dùng.

## Mô tả ngắn (≤ 80 ký tự)
- vi: Ghi thu chi trong vài giây, nhắc hằng ngày, widget. Dữ liệu chỉ ở trên máy. (75 ký tự)
- en: Log spending in seconds. Daily reminder, widget. Your data stays on your phone. (79 chars)

## Mô tả đầy đủ (≤ 4.000 ký tự)
Số ký tự thực tế (đếm 2026-11-04, tính cả xuống dòng): vi 2.598, en 2.692; cả hai dưới 4.000.

### Tiếng Việt
Ví Gọn giúp bạn ghi chép thu chi hằng ngày thật nhanh và biết tiền của mình đi đâu.

**Ghi nhanh**
• Chạm − hoặc +, nhập số tiền bằng bàn phím có phép tính (cộng, trừ, nhân, chia), chọn danh mục là xong, tối đa 3 lần chạm.
• Sửa hoặc xóa khoản đã ghi; xóa nhầm thì hoàn tác ngay.

**Nhìn rõ chi tiêu**
• Biểu đồ vòng theo danh mục, tổng thu, tổng chi và số dư.
• Xem theo ngày, tuần, tháng, năm hoặc toàn bộ; vuốt ngang để đổi kỳ.
• Danh sách khoản gom theo danh mục kèm phần trăm.

**Quản lý gọn gàng**
• Nhiều tài khoản (tiền mặt, ngân hàng, thẻ) và chuyển tiền giữa các tài khoản.
• Danh mục tự thêm, sửa, sắp xếp.
• Khoản định kỳ (tiền nhà, tiền điện, đăng ký hằng tháng) tự được ghi khi tới hạn.
• Ngân sách tháng có thanh tiến độ và cảnh báo khi vượt.

**Nhắc ghi chép và widget**
• Nhắc ghi chép hằng ngày (tùy chọn, mặc định tắt): một thông báo mỗi ngày vào giờ bạn chọn, nằm trên máy, không chứa số liệu. App chỉ xin quyền thông báo khi bạn bật tính năng này.
• Widget màn hình chính với hai nút lớn "Chi" và "Thu" để mở ngay màn nhập khoản. Mặc định widget không hiện số tiền; bạn có thể bật hiện số đã chi trong tháng, và khi đang bật khóa PIN thì widget luôn ẩn số.

**Riêng tư**
• Mọi dữ liệu chỉ lưu trên điện thoại của bạn. Ví Gọn không có tài khoản, không quảng cáo, không theo dõi và không có quyền Internet nên không thể gửi dữ liệu đi. App chỉ có tối đa hai quyền tùy chọn, dùng cho nhắc ghi chép hằng ngày (thông báo, nhận tín hiệu khởi động lại máy).
• Khóa bằng mã PIN 4 số (lưu ý: PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu).
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Excel hoặc Google Sheets. File sao lưu thủ công có thể đặt mật khẩu (mã hóa AES-256); không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn.
• Sao lưu tự động (tùy chọn, mặc định tắt): bạn chọn một thư mục, app tự ghi file sao lưu vào đó tối đa mỗi ngày một lần khi dữ liệu có thay đổi, giữ 7 file gần nhất. File luôn được mã hóa AES-256-GCM bằng mật khẩu bạn đặt; mật khẩu chỉ nằm trong kho khóa an toàn của điện thoại. Nếu chọn thư mục của Google Drive hay dịch vụ tương tự, việc tải lên do app đó thực hiện; Ví Gọn không kết nối mạng.
• Quên mã PIN hoặc mật khẩu sao lưu thì không lấy lại được.
• Tìm kiếm khoản theo ghi chú, danh mục, số tiền; ẩn tài khoản không dùng; ngân sách riêng cho từng danh mục; đủ tiền tệ theo chuẩn ISO; tùy chọn che nội dung ở màn hình ứng dụng gần đây. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.

**Dễ dùng**
• Tiếng Việt và tiếng Anh, giao diện sáng và tối.
• Tối ưu cho cỡ chữ lớn và trình đọc màn hình TalkBack.

### English
Ví Gọn is a fast personal income and expense tracker that shows where your money goes.

**Quick entry**
• Tap − or +, type the amount on a keypad with built-in math (add, subtract, multiply, divide), pick a category. Three taps at most.
• Edit or delete records; undo a delete right away.

**See your spending**
• Donut chart by category, with income, expenses and balance.
• View by day, week, month, year or all time; swipe sideways to change period.
• Records grouped by category with percentages.

**Stay organized**
• Multiple accounts (cash, bank, card) and transfers between them.
• Add, edit and reorder your own categories.
• Recurring records (rent, bills, subscriptions) are added automatically when due.
• Monthly budget with a progress bar and an over-budget warning.

**Reminder and widget**
• Optional daily reminder (off by default): one notification a day at the time you choose, created on your phone and containing no figures. The app asks for notification permission only when you turn this on.
• Home screen widget with two big buttons for adding an expense or an income. By default it shows no amounts; you can choose to show what you spent this month, and while the PIN lock is on the widget always hides amounts.

**Private by design**
• All data stays on your phone. Ví Gọn has no accounts, no ads, no tracking, and no Internet permission, so it cannot send your data anywhere. It has at most two optional permissions, used only for the daily reminder (notifications, restart signal).
• Optional 4-digit PIN lock (it keeps others out of the app but does not encrypt your data).
• Export a backup file and restore it on a new phone; export CSV for Excel or Google Sheets. Manual backup files can be password-protected (AES-256 encryption); without a password they are not encrypted, so keep them somewhere safe.
• Optional automatic backup (off by default): choose a folder and the app writes a backup there at most once a day when your data has changed, keeping the 7 most recent files. Files are always encrypted (AES-256-GCM) with a password you set, kept only in your phone's secure key store. If you pick a folder of Google Drive or a similar service, that app does the uploading; Ví Gọn does not use the network.
• Search records by note, category or amount; hide accounts you no longer use; set a budget per category; all ISO currencies; optionally hide app contents in the recent-apps screen. If you forget the PIN or a backup password, it cannot be recovered. If you forget the PIN, the only way back in is to delete the app's data.

**Easy to use**
• Vietnamese and English, light and dark themes.
• Built for large text sizes and the TalkBack screen reader.

## Phân loại
- Danh mục Play: Tài chính (Finance) hoặc Năng suất; đề xuất **Finance**.
- Xếp hạng nội dung (IARC): không có nội dung nhạy cảm, không chat, không mua hàng; dự kiến mức thấp nhất.
- Đối tượng: người từ 13 tuổi trở lên, KHÔNG nhắm tới trẻ em (COMPLIANCE P-12). Chờ người dùng quyết Play Age Signals (D-12).
- Giá: miễn phí, không mua trong app, không quảng cáo.

## Data safety (khai trong Play Console)
- Thu thập dữ liệu: **Không**. Chia sẻ dữ liệu: **Không**. Bản 1.2 vẫn không có quyền INTERNET, không SDK bên thứ ba; dữ liệu chỉ ở trên máy, sao lưu tự động chỉ ghi file mã hóa vào thư mục người dùng chọn (do người dùng và hệ thống Android quản lý, nhà phát triển không nhận được).
- Quyền khai trong app (đúng `AndroidManifest.xml`, tối đa 2, đều tùy chọn): `POST_NOTIFICATIONS` (chỉ xin sau lời giải thích khi người dùng bật Nhắc ghi chép hằng ngày; thông báo cục bộ, không chứa số liệu) và `RECEIVE_BOOT_COMPLETED` (đặt lại lịch nhắc sau khi khởi động lại máy). Không `INTERNET`, không `SCHEDULE_EXACT_ALARM`, không quyền bộ nhớ (thư mục sao lưu chọn qua Storage Access Framework). Plugin thông báo tự thêm `VIBRATE`, manifest đã gỡ (`tools:node="remove"`).
- Widget: số tiền trên widget chỉ nằm trong bộ nhớ riêng của app và màn hình chờ, mặc định không hiện, luôn ẩn khi khóa PIN bật.
- Trạng thái kiểm chứng (2026-11-04): các mục trên khớp SPEC-1.2 và manifest hiện tại. Sao lưu tự động, thông báo thật, widget và quyền khi chạy thật: **CHƯA kiểm chứng** trên máy thật (xem biên bản `[M]` trong SPEC-1.2). Phải kiểm bản APK/AAB phát hành (danh sách quyền sau khi gộp manifest) trước khi khai Data safety và nộp.
- Dữ liệu được mã hóa khi truyền: không áp dụng (không truyền dữ liệu).
- Người dùng có thể yêu cầu xóa dữ liệu: có, trong app (Cài đặt → Xóa toàn bộ dữ liệu) hoặc gỡ app.
- Chính sách quyền riêng tư: đường dẫn Google Sites (chờ người dùng đăng).
- Liên hệ nhà phát triển: `phamphuongphuong@gmail.com`.

## Ảnh chụp màn hình
Đã chụp 2026-11-03 (bản 1.1, trước khi có widget và Sao lưu tự động; chưa có ảnh mới cho bản 1.2, nên chụp thêm ảnh widget và màn Cài đặt → Sao lưu tự động khi đã kiểm trên máy) trên Galaxy A13 (bản release, dữ liệu MẪU do `exportBackup` sinh ra, không có dữ liệu thật), nằm ở `docs/store/screenshots/`. Mỗi ảnh 1080×2160 px (đã cắt thanh trạng thái và thanh điều hướng để tỉ lệ đúng 2:1, mức tối đa Play cho phép).
| Ảnh | Nội dung | Gợi ý dòng chữ phụ |
|-----|----------|--------------------|
| `01-man-chinh.png` | Màn chính: biểu đồ vòng, ngân sách tháng, số dư (sáng, tiếng Việt) | "Biết tiền đi đâu" |
| `02-nhap-khoan.png` | Nhập số tiền bằng bàn phím có phép tính | "Ghi nhanh trong 3 chạm" |
| `03-danh-sach-khoan.png` | Danh sách khoản gom theo danh mục, có phần trăm | "Xem chi tiết từng khoản" |
| `04-tai-khoan.png` | Nhiều tài khoản (tiền mặt, ngân hàng) | "Quản lý nhiều ví" |
| `05-giao-dien-toi.png` | Màn chính giao diện tối | "Giao diện sáng và tối" |
| `06-english-main.png` | Màn chính tiếng Anh, dùng cho trang store tiếng Anh | "Your data stays on your phone" |
Lưu ý: ảnh 04 khá trống (chỉ hai tài khoản), có thể thay bằng màn Chuyển tiền; ảnh 02 bị cắt nhẹ phần đáy nút Lưu vì giới hạn tỉ lệ. Chưa có ảnh cho máy tính bảng (v1 chỉ nhắm điện thoại). Icon 512×512: đã chốt logo (D-009), file `docs/store/brand/icon-512.png`. Ảnh bìa 1024×500: đã vẽ trên canvas Design, CHƯA có PNG trong repo (người dùng xuất bằng Share › Export, xem `docs/store/brand/README.md`).
