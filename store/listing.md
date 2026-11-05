# Hồ sơ Google Play — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào Google Play Console ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Bản App Store tương ứng: `store/app-store.md` (giữ hai bản thống nhất: sửa một bên thì sửa bên kia).
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7). Rà lại 2026-11-04; gộp nội dung bản 1.2 (`docs/SPEC.md` mục 3c: sao lưu tự động, nhắc ghi chép, widget) 2026-11-04; rà lại và viết lại mô tả 2026-11-05 sau khi gộp nhánh (D-019, phiên store v2): mọi tính năng mô tả ở đây đều có trên Android. Phiên điều phối #3 duyệt lần cuối trước khi nộp.

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
Viết lại 2026-11-05 theo bản đã gộp (F-01..F-26, mọi mục đều có trên Android). Số ký tự: vi 2724, en 2828 (giới hạn 4.000; đếm bằng script, tính cả dấu `**`).

### Tiếng Việt
Ví Gọn giúp bạn ghi chép thu chi hằng ngày thật nhanh và biết tiền của mình đi đâu.

**Ghi nhanh**
• Chạm − hoặc +, nhập số tiền bằng bàn phím có phép tính (cộng, trừ, nhân, chia), chọn danh mục là xong, tối đa 3 lần chạm.
• Sửa hoặc xóa khoản đã ghi; xóa nhầm thì hoàn tác ngay.
• Tìm khoản theo ghi chú, danh mục hoặc số tiền.
• Widget màn hình chính với hai nút lớn "Chi" và "Thu" để mở ngay màn nhập khoản.

**Nhìn rõ chi tiêu**
• Biểu đồ vòng theo danh mục, tổng thu, tổng chi và số dư.
• Xem theo ngày, tuần, tháng, năm hoặc toàn bộ; vuốt ngang để đổi kỳ.
• Danh sách khoản gom theo danh mục kèm phần trăm.

**Quản lý gọn gàng**
• Nhiều tài khoản (tiền mặt, ngân hàng, thẻ) và chuyển tiền giữa các tài khoản; ẩn tài khoản không còn dùng.
• Danh mục tự thêm, sửa, sắp xếp.
• Khoản định kỳ (tiền nhà, tiền điện, đăng ký hằng tháng) tự được ghi khi tới hạn.
• Ngân sách tháng có thanh tiến độ và cảnh báo khi vượt, thêm ngân sách riêng cho từng danh mục nếu muốn.
• Đủ các loại tiền tệ theo chuẩn ISO, có ô tìm.

**Nhắc ghi chép**
• Tùy chọn, mặc định tắt: mỗi ngày một thông báo vào giờ bạn chọn, tạo ngay trên máy và không chứa số liệu. App chỉ xin quyền thông báo khi bạn bật tính năng này.

**Riêng tư**
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Ví Gọn không có quyền Internet nên không thể gửi dữ liệu đi. Dữ liệu chỉ lưu trên điện thoại của bạn và app tắt sao lưu đám mây tự động của Android.
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tùy chọn che nội dung khi chuyển app: chặn chụp màn hình và ẩn ảnh xem trước trong danh sách ứng dụng gần đây.
• Widget mặc định không hiện số tiền. Bạn có thể bật hiện số đã chi trong tháng; khi khóa PIN đang bật, widget luôn ẩn số.

**Sao lưu**
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Excel hoặc Google Sheets. Có thể đặt mật khẩu cho file sao lưu (mã hóa AES-256-GCM); không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn.
• Sao lưu tự động (tùy chọn, mặc định tắt): bạn chọn một thư mục, app tự ghi file sao lưu vào đó tối đa mỗi ngày một lần khi dữ liệu có thay đổi, giữ 7 file gần nhất. File luôn được mã hóa bằng mật khẩu bạn đặt; mật khẩu chỉ nằm trong kho khóa an toàn của điện thoại. Nếu bạn chọn thư mục của Google Drive hay dịch vụ tương tự, việc tải lên do app đó thực hiện; Ví Gọn không kết nối mạng.
• Quên mật khẩu sao lưu thì không ai lấy lại được, kể cả nhà phát triển.

**Dễ dùng**
• Tiếng Việt và tiếng Anh, giao diện sáng và tối, icon theo màu hình nền (Android 13 trở lên).
• Hỗ trợ cỡ chữ lớn; mọi nút đều có nhãn cho trình đọc màn hình TalkBack.

Miễn phí. Không mua trong app.

### English
Ví Gọn is a fast personal income and expense tracker that shows where your money goes.

**Quick entry**
• Tap − or +, type the amount on a keypad with built-in math (add, subtract, multiply, divide), pick a category. Three taps at most.
• Edit or delete records; undo a delete right away.
• Search records by note, category or amount.
• Home screen widget with two big buttons to add an expense or an income.

**See your spending**
• Donut chart by category, with income, expenses and balance.
• View by day, week, month, year or all time; swipe sideways to change period.
• Records grouped by category with percentages.

**Stay organized**
• Multiple accounts (cash, bank, card) and transfers between them; hide accounts you no longer use.
• Add, edit and reorder your own categories.
• Recurring records (rent, bills, subscriptions) are added automatically when due.
• Monthly budget with a progress bar and an over-budget warning, plus an optional budget for each category.
• All ISO currencies, with search.

**Daily reminder**
• Optional, off by default: one notification a day at the time you choose, created on your phone and containing no figures. The app asks for notification permission only when you turn it on.

**Private by design**
• No sign-up, no ads, no tracking, no analytics. Ví Gọn has no Internet permission, so it cannot send your data anywhere. Your data stays on your phone, and the app turns off Android's automatic cloud backup.
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Optional "hide content when switching apps": blocks screenshots and hides the preview in the recent apps list.
• The widget shows no amounts by default. You can choose to show what you spent this month; while the PIN lock is on, the widget always hides amounts.

**Backup**
• Export a backup file and restore it on a new phone; export CSV for Excel or Google Sheets. You can protect a backup file with a password (AES-256-GCM encryption); without a password the file is not encrypted, so keep it somewhere safe.
• Optional automatic backup (off by default): choose a folder and the app writes a backup there at most once a day when your data has changed, keeping the 7 most recent files. Files are always encrypted with a password you set, kept only in your phone's secure key store. If you pick a folder of Google Drive or a similar service, that app does the uploading; Ví Gọn does not use the network.
• A forgotten backup password cannot be recovered by anyone, including the developer.

**Easy to use**
• Vietnamese and English, light and dark themes, themed icon (Android 13 and later).
• Supports large text sizes; every button has a label for the TalkBack screen reader.

Free. No in-app purchases.

Khác bản App Store có chủ đích: Android tắt sao lưu hệ thống (`allowBackup=false`) — app không tự sao lưu lên đám mây của Google (sao lưu tự động của app chỉ ghi vào thư mục người dùng chọn);
iOS thì dữ liệu nằm trong sao lưu iPhone nếu người dùng bật (xem `store/app-store.md`). TalkBack ↔ VoiceOver.
Widget, sao lưu tự động, che nội dung ở màn ứng dụng gần đây và icon đơn sắc **chỉ có trên Android** (D-019): có trong bản Play, KHÔNG có trong bản App Store.
Nhắc ghi chép, mật khẩu file sao lưu, tìm kiếm, ẩn tài khoản, ngân sách theo danh mục, đủ tiền tệ ISO có ở cả hai. Mô tả ngắn của Play nhắc "widget" nên không dùng lại cho App Store.

## Ghi chú phát hành (Play "Release notes", ≤ 500 ký tự mỗi ngôn ngữ)
- vi (231): `Bản đầu tiên: ghi khoản nhanh, tìm kiếm, biểu đồ theo danh mục, tài khoản và chuyển tiền, khoản định kỳ, ngân sách tháng và theo danh mục, nhắc ghi chép hằng ngày, widget, sao lưu có mật khẩu và sao lưu tự động, xuất CSV, khóa PIN.`
- en (227): `First release: quick entry, search, category chart, accounts and transfers, recurring records, monthly and per-category budgets, daily reminder, home screen widget, password-protected and automatic backup, CSV export, PIN lock.`
- Bản closed test: dùng cùng câu, thêm dòng "Bản thử — góp ý giúp mình qua nút Gửi phản hồi trên trang Play." (`store/closed-test-plan.md`).

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
   Bản 1.2: sao lưu tự động chỉ ghi file mã hóa vào thư mục người dùng chọn — do người dùng và hệ thống Android quản lý, nhà phát triển không nhận được.
   Về "chia sẻ" (Play tính cả chuyển dữ liệu cho app khác trên máy): file sao lưu/CSV qua bảng chia sẻ và sao lưu tự động vào thư mục
   Drive/Dropbox đều do **người dùng chủ động bật và chọn đích**, app giải thích trước ("Ví Gọn chỉ ghi file vào thư mục bạn chọn…") —
   thuộc ngoại lệ "chuyển theo hành động người dùng chủ động, người dùng biết rõ", nên vẫn "không chia sẻ". File tự động luôn mã hóa,
   khoá không rời máy. Đây là đánh giá theo định nghĩa của Play; đọc lại hướng dẫn Data safety ngày điền.)
2. Vì trả lời No, Play bỏ qua các câu về loại dữ liệu, mã hoá khi truyền, yêu cầu xoá. Trang store sẽ hiện
   "No data collected" và "No data shared with third parties".
3. Nếu bản Play Console đang dùng vẫn hỏi thêm: mã hoá khi truyền → không áp dụng (không truyền); xoá dữ liệu → người dùng tự xoá
   trong app (Cài đặt → Xóa toàn bộ dữ liệu) hoặc gỡ app.
- Quyền của app (đúng `AndroidManifest.xml` và manifest đã gộp của bản release trong `build/app/intermediates/merged_manifests/release/`, kiểm 2026-11-05): đúng **2 quyền**, cả hai chỉ phục vụ Nhắc ghi chép:
  `POST_NOTIFICATIONS` — quyền chạy (runtime) trên Android 13+, **chỉ xin sau lời giải thích khi người dùng bật** Nhắc ghi chép; từ chối thì app vẫn dùng bình thường.
  `RECEIVE_BOOT_COMPLETED` — quyền thường, **Android tự cấp khi cài, không hộp thoại**; chỉ để đặt lại lịch nhắc sau khi khởi động lại máy, không đọc dữ liệu nào. (Bản nháp trước ghi "đều tùy chọn" là sai với quyền này.)
  Ngoài ra chỉ có quyền nội bộ `com.phiotron.vigon.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (AndroidX tự thêm). Không `INTERNET`, không `SCHEDULE_EXACT_ALARM`, không quyền bộ nhớ (thư mục sao lưu chọn qua Storage Access Framework). Plugin thông báo tự thêm `VIBRATE`, manifest đã gỡ (`tools:node="remove"`). Trang Play sẽ liệt kê 2 quyền này — khớp mô tả.
- Widget: số tiền trên widget chỉ nằm trong bộ nhớ riêng của app và màn hình chờ, mặc định không hiện, luôn ẩn khi khóa PIN bật.
- Thông báo nhắc: cục bộ (`flutter_local_notifications`), không Firebase/FCM, không push từ máy chủ, nội dung cố định "Hôm nay bạn đã ghi chi tiêu chưa?" — không phải dữ liệu thu thập.
- Trạng thái kiểm chứng (2026-11-04, vẫn đúng 2026-11-05): sao lưu tự động, thông báo thật, widget và quyền khi chạy thật **CHƯA kiểm chứng** trên máy thật (AC `[M]` trong `docs/SPEC.md` mục 3c; bước thử M-1..M-7 trong `docs/TESTING.md`). Phải kiểm bản APK/AAB phát hành (danh sách quyền sau khi gộp manifest) trước khi khai Data safety và nộp.
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
- Ảnh chụp màn hình: quy cách và kịch bản ở `store/screenshots-spec.md`; **chụp lại ở phiên điều phối #3 với UI mới** (bộ Play có thêm ảnh widget và Cài đặt → Sao lưu tự động).
  Ảnh hiện có trong `store/screenshots/` (6 ảnh 1080×2160, chụp 2026-11-03 trên Galaxy A13, bản release, dữ liệu MẪU) là
  ảnh UI cũ, chỉ giữ làm tham khảo bố cục; có thể dùng tạm cho trang closed test (closed test không bắt ảnh đẹp).
