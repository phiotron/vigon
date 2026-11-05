# Hồ sơ Google Play — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào Google Play Console ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Bản App Store tương ứng: `store/app-store.md` (giữ hai bản thống nhất: sửa một bên thì sửa bên kia).
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7). Rà lại 2026-11-04; gộp nội dung bản 1.2 (SPEC-1.2: sao lưu tự động, nhắc ghi chép, widget) 2026-11-04 — phiên điều phối sẽ viết lại toàn bộ sau khi gộp nhánh.

## Tên (≤ 30 ký tự)
- Tiếng Việt: **Ví Gọn: Ghi Thu Chi** (19)
- Tiếng Anh: **Ví Gọn: Expense Tracker** (23)
- Tên dưới icon trên máy vẫn là **Ví Gọn** (Android `android:label`, iOS `CFBundleDisplayName`).
- Đã loại các gợi ý tiếng Anh cũ (Neat Wallet, Tidy Wallet, Pocket Ledger): "Neat" là thương hiệu phần mềm chi phí có sẵn;
  giữ một thương hiệu "Ví Gọn" cho mọi ngôn ngữ thì không phải tra trùng nhiều tên. Tra trùng 2026-11-04: xem `store/app-store.md`.
- Nếu người dùng muốn tên ngắn đúng "Ví Gọn" thì vẫn hợp lệ; chỉ mất từ khoá mô tả trong tên.

## Mô tả ngắn (≤ 80 ký tự)
- vi: Ghi thu chi trong vài giây, nhắc hằng ngày, widget. Dữ liệu chỉ ở trên máy. (75 ký tự)
- en: Log spending in seconds. Daily reminder, widget. Your data stays on your phone. (79 chars)

## Mô tả đầy đủ (≤ 4.000 ký tự)
Số ký tự: đếm lại sau khi viết lại bản cuối (bản 1.2 trước khi gộp: vi 2.598, en 2.692; giới hạn 4.000).

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
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Mọi dữ liệu chỉ lưu trên điện thoại của bạn. Ví Gọn không xin quyền Internet nên không thể gửi dữ liệu đi. App chỉ có tối đa hai quyền tùy chọn, dùng cho nhắc ghi chép hằng ngày (thông báo, nhận tín hiệu khởi động lại máy).
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Excel hoặc Google Sheets. File sao lưu thủ công có thể đặt mật khẩu (mã hóa AES-256); không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn.
• Sao lưu tự động (tùy chọn, mặc định tắt): bạn chọn một thư mục, app tự ghi file sao lưu vào đó tối đa mỗi ngày một lần khi dữ liệu có thay đổi, giữ 7 file gần nhất. File luôn được mã hóa AES-256-GCM bằng mật khẩu bạn đặt; mật khẩu chỉ nằm trong kho khóa an toàn của điện thoại. Nếu chọn thư mục của Google Drive hay dịch vụ tương tự, việc tải lên do app đó thực hiện; Ví Gọn không kết nối mạng.
• Quên mật khẩu sao lưu thì không lấy lại được.
• Tìm kiếm khoản theo ghi chú, danh mục, số tiền; ẩn tài khoản không dùng; ngân sách riêng cho từng danh mục; đủ tiền tệ theo chuẩn ISO; tùy chọn che nội dung ở màn hình ứng dụng gần đây.

**Dễ dùng**
• Tiếng Việt và tiếng Anh, giao diện sáng và tối.
• Hỗ trợ cỡ chữ lớn; mọi nút đều có nhãn cho trình đọc màn hình TalkBack.

Miễn phí. Không mua trong app.

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
• No sign-up, no ads, no tracking, no analytics. All data stays on your phone. Ví Gọn has no Internet permission, so it cannot send your data anywhere. It has at most two optional permissions, used only for the daily reminder (notifications, restart signal).
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Export a backup file and restore it on a new phone; export CSV for Excel or Google Sheets. Manual backup files can be password-protected (AES-256 encryption); without a password they are not encrypted, so keep them somewhere safe.
• Optional automatic backup (off by default): choose a folder and the app writes a backup there at most once a day when your data has changed, keeping the 7 most recent files. Files are always encrypted (AES-256-GCM) with a password you set, kept only in your phone's secure key store. If you pick a folder of Google Drive or a similar service, that app does the uploading; Ví Gọn does not use the network.
• If you forget a backup password, it cannot be recovered.
• Search records by note, category or amount; hide accounts you no longer use; set a budget per category; all ISO currencies; optionally hide app contents in the recent-apps screen.

**Easy to use**
• Vietnamese and English, light and dark themes.
• Supports large text sizes; every button has a label for the TalkBack screen reader.

Free. No in-app purchases.

Khác bản App Store có chủ đích: Android tắt sao lưu hệ thống (`allowBackup=false`) — app không tự sao lưu lên đám mây của Google (sao lưu tự động của app chỉ ghi vào thư mục người dùng chọn);
iOS thì dữ liệu nằm trong sao lưu iPhone nếu người dùng bật (xem `store/app-store.md`). TalkBack ↔ VoiceOver.

## Phân loại và giá
- Danh mục: **Finance** (Tài chính). Thẻ (tags) gợi ý khi Play hỏi: Budget, Expense tracker, Money manager (chọn từ danh sách của Play).
- Giá: miễn phí, không mua trong app, không quảng cáo.
- Quốc gia: theo COMPLIANCE M-01 (nhóm A và B, gồm Việt Nam); không mở Trung Quốc đại lục (Play không có ở đó), Nga (nhóm C).

## Nội dung app (Play Console → Policy → App content) — trả lời đề xuất
| Mục | Trả lời | Ghi chú |
|---|---|---|
| Privacy policy | Đường dẫn công khai của `docs/legal/privacy-policy.md` | CHƯA đăng — người dùng đăng |
| Ads | **No**, app không chứa quảng cáo | |
| App access | **All functionality is available without special access** | Không đăng nhập; PIN do người dùng tự bật, mặc định tắt |
| Content rating (IARC) | Danh mục bảng hỏi: **Utility, Productivity, Communication, or Other** (không phải game). Mọi câu bạo lực, tình dục, ngôn từ, ma tuý, cờ bạc: **No**. "Người dùng tương tác/chia sẻ nội dung với nhau": **No**. "Chia sẻ vị trí": **No**. "Mua hàng số": **No**. "Trình duyệt web không giới hạn": **No** | Kết quả dự kiến: mức thấp nhất (Everyone / PEGI 3 / IARC 3+) |
| Target audience and content | Nhóm tuổi: **13–15, 16–17, 18+**. Không chọn nhóm dưới 13 → không vào chương trình Families. "App có hấp dẫn trẻ em không": **No** | COMPLIANCE P-12; Play Age Signals chờ người dùng quyết (D-12) |
| News app | No | |
| Government app | No | |
| Financial features | Khai đúng thực tế: app **chỉ ghi chép chi tiêu cá nhân**, không cho vay, không thanh toán, không đầu tư, không tiền mã hoá, không ngân hàng. Chọn lựa chọn gần nhất trong danh sách hiện hành (thường có mục kiểu "My app doesn't provide any of these financial features" hoặc mục quản lý/ghi chép ngân sách) | Câu chữ danh sách đổi theo thời gian — đọc kỹ khi điền, không chọn mục dịch vụ tài chính |
| Health apps | No / không có tính năng sức khoẻ | |
| Data safety | Xem mục dưới | |

## Data safety (khai trong Play Console)
Đi theo đúng thứ tự form:
1. "Does your app collect or share any of the required user data types?" → **No**.
   (Play định nghĩa "collect" = truyền dữ liệu ra khỏi máy. App không có quyền INTERNET, không SDK → không truyền gì.
   Bản 1.2: sao lưu tự động chỉ ghi file mã hóa vào thư mục người dùng chọn — do người dùng và hệ thống Android quản lý, nhà phát triển không nhận được.)
2. Vì trả lời No, Play bỏ qua các câu về loại dữ liệu, mã hoá khi truyền, yêu cầu xoá. Trang store sẽ hiện
   "No data collected" và "No data shared with third parties".
3. Nếu bản Play Console đang dùng vẫn hỏi thêm: mã hoá khi truyền → không áp dụng (không truyền); xoá dữ liệu → người dùng tự xoá
   trong app (Cài đặt → Xóa toàn bộ dữ liệu) hoặc gỡ app.
- Quyền khai trong app (đúng `AndroidManifest.xml`, tối đa 2, đều tùy chọn): `POST_NOTIFICATIONS` (chỉ xin sau lời giải thích khi người dùng bật Nhắc ghi chép hằng ngày; thông báo cục bộ, không chứa số liệu) và `RECEIVE_BOOT_COMPLETED` (đặt lại lịch nhắc sau khi khởi động lại máy). Không `INTERNET`, không `SCHEDULE_EXACT_ALARM`, không quyền bộ nhớ (thư mục sao lưu chọn qua Storage Access Framework). Plugin thông báo tự thêm `VIBRATE`, manifest đã gỡ (`tools:node="remove"`).
- Widget: số tiền trên widget chỉ nằm trong bộ nhớ riêng của app và màn hình chờ, mặc định không hiện, luôn ẩn khi khóa PIN bật.
- Trạng thái kiểm chứng (2026-11-04): sao lưu tự động, thông báo thật, widget và quyền khi chạy thật **CHƯA kiểm chứng** trên máy thật (biên bản `[M]` trong `docs/SPEC.md`). Phải kiểm bản APK/AAB phát hành (danh sách quyền sau khi gộp manifest) trước khi khai Data safety và nộp.
- Đối chiếu nguồn: `docs/SECURITY.md` (bản đồ dữ liệu), SBOM `docs/sbom/vigon.cdx.json`, `aapt2 dump permissions` (không có INTERNET).
- Hành động do người dùng chủ động (chọn đích trong bảng chia sẻ để gửi file sao lưu/CSV, chọn thư mục sao lưu tự động) không tính là app thu thập/chia sẻ.
- Sai lệch phải sửa ngay: thêm SDK crash/analytics, đồng bộ đám mây, quyền INTERNET → khai lại trước khi phát hành bản đó.

## Tài khoản nhà phát triển cá nhân — điều cần biết
- **Tên hiển thị trên Play** = tên nhà phát triển người dùng đặt khi tạo tài khoản (đã xác minh danh tính). Chính sách quyền riêng tư
  và màn Giới thiệu nên dùng cùng tên đó (thay "nhà phát triển Ví Gọn").
- **Email liên hệ hiện công khai** trên trang store: `phamphuongphuong@gmail.com` (đã in trong app). Tài khoản cá nhân không bán gì
  thì Play không hiện địa chỉ nhà; nếu sau này bán hàng/IAP thì Play có thể yêu cầu hiện địa chỉ (khai "trader" theo EU DSA).
- **Bắt buộc closed test ≥ 12 tester trong 14 ngày liên tục** trước khi xin quyền production — kế hoạch: `store/closed-test-plan.md`.
- **Xác minh nhà phát triển (developer verification)**: Google mở rộng dần theo nước (COMPLIANCE P-08); làm theo thông báo trong Play Console.
- Tài khoản cá nhân mới thường phải xác nhận có thiết bị Android thật qua app Play Console — dùng máy Galaxy A13 của người dùng.
- Muốn đổi sang tài khoản tổ chức sau này: kiểm cách làm hiện hành trong Play Console Help (đổi loại tài khoản hoặc chuyển app); chưa kiểm chi tiết.

## Đồ hoạ store
- Icon 512×512: `store/brand/icon-512.png` (D-009).
- Ảnh bìa (feature graphic) 1024×500: CHƯA có PNG trong repo — người dùng xuất từ canvas Design (xem `store/brand/README.md`).
- Ảnh chụp màn hình: quy cách và kịch bản ở `store/screenshots-spec.md`; **chụp lại ở phiên điều phối #3 với UI mới**, thêm ảnh widget và màn Cài đặt → Sao lưu tự động (bản 1.2).
  Ảnh hiện có trong `store/screenshots/` (6 ảnh 1080×2160, chụp 2026-11-03 trên Galaxy A13, bản release, dữ liệu MẪU) là
  ảnh UI cũ, chỉ giữ làm tham khảo bố cục; có thể dùng tạm cho trang closed test (closed test không bắt ảnh đẹp).
