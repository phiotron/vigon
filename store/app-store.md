# Hồ sơ App Store — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào App Store Connect ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Nội dung phải khớp với Play (`store/listing.md`) và với code; không hứa điều code không làm. Viết 2026-11-04; cập nhật 2026-11-05
sau khi gộp bản 1.2 với giao diện/iOS (D-019): thêm tính năng 1.1/1.2 **có trên iPhone** (tìm kiếm, ẩn tài khoản, ngân sách theo
danh mục, đủ tiền tệ ISO, nhắc ghi chép hằng ngày, đặt mật khẩu cho file sao lưu). ~~Widget, sao lưu tự động, che nội dung chỉ có
trên Android~~ → **thay bằng D-022 (2026-11-05): iOS có đủ widget màn hình chính, sao lưu tự động vào thư mục chọn trong app
Tệp, che nội dung ở màn chuyển app** — đã đưa vào mô tả, What's New, Review Notes, App Privacy và quy cách ảnh (phiên con D6).
Chỉ **icon đơn sắc (F-23)** vẫn chỉ Android → không nhắc. Không nhắc nền tảng khác trong metadata (App Review 2.3.1, 2.3.10).
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7).

Project iOS trên `main` sau gộp (đối chiếu lại 2026-11-05, commit `a00bec8`): **chỉ iPhone** (`TARGETED_DEVICE_FAMILY = 1`),
**chỉ màn dọc**, tên hiển thị `Ví Gọn`, min iOS **16.0** (D-024, commit `b0c9fee`; trước là 15.0), `CFBundleLocalizations` en + vi, `FlutterDeepLinkingEnabled = false`,
`LSApplicationQueriesSchemes` chỉ `mailto`, `https`, `ITSAppUsesNonExemptEncryption = true` (**D-020**, commit `8441b6a`; xem mục Export compliance),
DB loại khỏi sao lưu iCloud/máy tính (**D-021**, commit `8441b6a`; CI iOS chưa xác nhận lúc ghi),
`ios/Runner/PrivacyInfo.xcprivacy` (không tracking; `NSPrivacyCollectedDataTypes` đang rỗng — cần thêm Coarse Location cho khớp App Privacy thận trọng, xem mục App Privacy; required-reason API FileTimestamp `C617.1`, DiskSpace `E174.1`,
UserDefaults `CA92.1` + `1C8F.1` — thêm ở D4 cho bookmark thư mục và App Group),
không khoá `NS…UsageDescription`, không `UIFileSharingEnabled`; icon `AppIcon` đủ cỡ, bản 1024×1024 RGB không alpha (PLAN-001).
Widget extension `VigonWidgetExtension` (`com.phiotron.vigon.VigonWidget`, min **iOS 16.0**, App Group `group.com.phiotron.vigon`) có
`PrivacyInfo.xcprivacy` riêng (không tracking, không thu thập; UserDefaults `1C8F.1`) — D4, commit `6ed915c` (kiểm lại 2026-11-05).
Tính năng theo nền tảng (`lib/src/platform_features.dart`, D-022 thay phần iOS của D-019): iOS **có** nhắc ghi chép (thông báo cục bộ,
xin quyền khi bật), mật khẩu file sao lưu, tìm kiếm, ẩn tài khoản, ngân sách theo danh mục, tiền tệ ISO, **widget, sao lưu
tự động, che nội dung ở màn chuyển app**; iOS **không có** icon đơn sắc. Nếu `ios/` hoặc danh sách này đổi, sửa lại "Mô tả", "Ảnh chụp",
"Export compliance", "App Privacy".
Cập nhật 2026-11-05 (phiên con "Tài liệu theo quyết định mã hoá + iCloud"): mô tả, phân phối, App Privacy, Export compliance viết theo
**D-020** (khai có mã hoá chuẩn, vẫn bán ở Pháp, người dùng nộp khai báo cho ANSSI) và **D-021** (DB iOS không vào sao lưu iCloud/máy tính).
Code đã có ở commit `8441b6a` — trước khi dán vẫn **đối chiếu `ios/Runner/Info.plist` và CI iOS xanh** (bước kiểm log `VigonBackupExclusion`).

## Tra trùng tên (2026-11-04)
- Tìm "Ví Gọn" / "Vi Gon" trên web (apps.apple.com, Google Play): **không thấy app nào trùng tên**. Các app gần tên nhất
  là ví điện tử thanh toán (VIMO, Ví OneFin) và "Viet Wallet": khác tên, khác loại. Chưa tra được trực tiếp trong
  App Store trên iPhone (không có máy) và chưa tra cơ sở dữ liệu nhãn hiệu (WIPO, Cục SHTT) — xem `store/brand/README.md`.
- Loại tên tiếng Anh "Neat Wallet": "Neat" là thương hiệu phần mềm chi phí/hoá đơn đã có từ lâu, dễ nhầm. Đề xuất
  **giữ thương hiệu "Ví Gọn" ở mọi ngôn ngữ** và thêm phần mô tả sau dấu hai chấm (không cần đặt tên tiếng Anh riêng).
- App Store Connect kiểm trùng tên khi tạo app: nếu "Ví Gọn: Expense Tracker" đã bị giữ, thử "Ví Gọn – Money Log".

## Thông tin chung (App Information)
| Trường | Giá trị |
|---|---|
| Bundle ID | `com.phiotron.vigon` (người dùng tạo App ID trên developer.apple.com) |
| SKU | `vigon-ios-1` (chỉ nội bộ, không hiện ra ngoài) |
| Ngôn ngữ chính | English (U.S.). Thêm bản địa hoá Vietnamese. App chưa có ngôn ngữ nào khác. |
| Danh mục chính | **Finance** · Danh mục phụ: **Productivity** |
| Giá | Miễn phí. Không In-App Purchase, không thuê bao, không quảng cáo. |
| Phân phối | Mọi quốc gia/vùng trừ **Trung Quốc đại lục** (app cần số đăng ký ICP mới được bán ở đó; COMPLIANCE nhóm C chưa mở) và **Nga** (nhóm C). Nhóm D theo COMPLIANCE M-01 khi chốt. **Có Pháp ngay bản 1** (D-020) → trước khi nộp App Review phải đã tải khai báo mã hoá Pháp lên App Store Connect (mục Export compliance; các bước ở `docs/RELEASE.md`). Apple khuyên đặt Availability và điền Description **trước** khi tải tài liệu mã hoá. |
| Thiết bị | Chỉ iPhone. Không bật "iPhone and iPad Apps on Apple Silicon Macs" và "Apple Vision Pro" (chưa thử). |
| Copyright | `© 2026 <họ tên người đăng ký Apple Developer>` |
| Tên người bán (Seller) | Tài khoản **cá nhân** → App Store hiện **họ tên thật** của người đăng ký. Chính sách quyền riêng tư phải ghi đúng tên này (xem `docs/legal/privacy-policy.md`). |
| Trạng thái trader (EU, DSA) | App Store Connect bắt khai trước khi phát hành ở EU. App miễn phí, không kinh doanh → người dùng cân nhắc khai **không phải trader**; nếu khai là trader thì địa chỉ, số điện thoại, email bị hiện công khai trên trang EU. Người dùng tự quyết (việc pháp lý). |

## URL bắt buộc
| URL | Bắt buộc? | Nội dung | Trạng thái |
|---|---|---|---|
| Privacy Policy URL | Có | Trang chính sách vi/en (`docs/legal/privacy-policy.md`) | CHƯA đăng — người dùng đăng (gợi ý nơi đăng ở file chính sách) |
| Support URL | Có | Trang "Hỗ trợ / Support": email liên hệ, 4–5 câu hỏi thường gặp (quên PIN, chuyển máy bằng file sao lưu, xuất CSV, dữ liệu ở đâu) | CHƯA có — làm cùng site với chính sách |
| Marketing URL | Không | Bỏ trống | — |

Cùng đường dẫn chính sách phải điền vào `lib/src/app_info.dart` (`AppInfo.privacyPolicyUrl`) — việc của phiên code, không phải phiên store.

## English (U.S.) — localization chính
- **Name** (≤ 30): `Ví Gọn: Expense Tracker` — 23 ký tự
- **Subtitle** (≤ 30): `Offline budget & spending log` — 29 ký tự
- **Keywords** (≤ 100, dấu phẩy không cách; không lặp chữ trong Name/Subtitle vì Apple đã đánh chỉ mục các chữ đó):
  `money,finance,income,ledger,private,wallet,cash,bills,savings,vigon,vi gon,manager,daily,widget` — 95 ký tự
  (2026-11-05, D-022: `diary` → `widget` vì iPhone nay có widget)
- **Promotional Text** (≤ 170, đổi được không cần duyệt lại):
  `Log a purchase in three taps. No account, no ads, no tracking: your income and spending stay on your iPhone, under your control.` — 128 ký tự
  (2026-11-05, D-025: bỏ "no internet connection" vì đổi tiền tệ có tải tỉ giá qua mạng)

**Description** (≤ 4.000):

```
Ví Gọn is a fast personal income and expense tracker that shows where your money goes.

QUICK ENTRY
• Tap − or +, type the amount on a keypad with built-in math (add, subtract, multiply, divide), pick a category. Three taps at most.
• Edit or delete records; undo a delete right away.
• Search records by note, category or amount.
• Home screen widget with two big buttons to add an expense or an income.

SEE YOUR SPENDING
• Donut chart by category, with income, expenses and balance.
• View by day, week, month, year or all time; swipe sideways to change period.
• Records grouped by category with percentages.

STAY ORGANIZED
• Multiple accounts (cash, bank, card) and transfers between them; hide accounts you no longer use.
• Add, edit and reorder your own categories.
• Recurring records (rent, bills, subscriptions) are added automatically when due.
• Monthly budget with a progress bar and an over-budget warning, plus an optional budget for each category.
• All ISO currencies, with search. Changing currency converts every amount using a downloaded exchange rate (or one you enter).

DAILY REMINDER
• Optional, off by default: one notification a day at the time you choose, created on your iPhone and containing no figures. The app asks for notification permission only when you turn it on.

PRIVATE BY DESIGN
• No sign-up, no ads, no tracking, no analytics. Ví Gọn has no server and never sends your data anywhere: it goes online only to download a public exchange rate table when you change currency. The developer never receives your data.
• Your records are stored only in the app on your iPhone. They are left out of iCloud and computer backups of your iPhone, so to move to a new phone, export a backup file and restore it there.
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Optional "hide content when switching apps": covers your figures in the app switcher. (iPhone does not let apps block screenshots.)
• The widget shows no amounts by default. You can choose to show what you spent this month; while the PIN lock is on, the widget always hides amounts.

BACKUP
• Export a backup file and restore it on a new phone; export CSV for Numbers, Excel or Google Sheets. You can protect a backup file with a password (AES-256 encryption); if you forget the password, the file cannot be opened. Without a password the file is not encrypted, so keep it somewhere safe.
• Optional automatic backup (off by default): choose a folder in the Files app, for example in iCloud Drive. When you open Ví Gọn, it writes an encrypted backup there at most once a day if your data has changed, keeping the 7 most recent files. The password stays in your iPhone's Keychain; if you forget it, nobody can recover the files, including the developer.

EASY TO USE
• Vietnamese and English, light and dark themes.
• Supports large text sizes; every button has a label for VoiceOver.

Free. No in-app purchases.
```

- **What's New in This Version**: App Store Connect **không cho nhập** ở phiên bản đầu tiên (1.0). Dùng câu dưới cho
  TestFlight "What to Test" và giữ cho bản 1.0.1:
  `First release: quick entry, search, category chart, accounts and transfers, recurring records, monthly and per-category budgets, daily reminder, home screen widget, password-protected and automatic backup, CSV export, PIN lock.`

## Vietnamese — localization phụ
- **Name** (≤ 30): `Ví Gọn: Ghi Thu Chi` — 19 ký tự
- **Subtitle** (≤ 30): `Sổ chi tiêu offline, riêng tư` — 29 ký tự
- **Keywords** (≤ 100): `quản lý tiền,ngân sách,tài chính,ví tiền,tiết kiệm,thu nhập,hóa đơn,tiền mặt,vi gon,money,budget` — 96 ký tự
  (121 byte UTF-8). Hiện Apple đếm theo ký tự; nếu App Store Connect báo quá dài thì bỏ `tiền mặt,` rồi `money,`.
- **Promotional Text** (≤ 170):
  `Ghi một khoản chi chỉ trong ba chạm. Không tài khoản, không quảng cáo, không theo dõi: thu chi của bạn nằm trên iPhone và do bạn quản lý.` — 137 ký tự
  (2026-11-05, D-025: bỏ "không kết nối Internet")

**Description** (≤ 4.000):

```
Ví Gọn giúp bạn ghi chép thu chi hằng ngày thật nhanh và biết tiền của mình đi đâu.

GHI NHANH
• Chạm − hoặc +, nhập số tiền bằng bàn phím có phép tính (cộng, trừ, nhân, chia), chọn danh mục là xong, tối đa 3 lần chạm.
• Sửa hoặc xóa khoản đã ghi; xóa nhầm thì hoàn tác ngay.
• Tìm khoản theo ghi chú, danh mục hoặc số tiền.
• Widget màn hình chính với hai nút lớn "Chi" và "Thu" để mở ngay màn nhập khoản.

NHÌN RÕ CHI TIÊU
• Biểu đồ vòng theo danh mục, tổng thu, tổng chi và số dư.
• Xem theo ngày, tuần, tháng, năm hoặc toàn bộ; vuốt ngang để đổi kỳ.
• Danh sách khoản gom theo danh mục kèm phần trăm.

QUẢN LÝ GỌN GÀNG
• Nhiều tài khoản (tiền mặt, ngân hàng, thẻ) và chuyển tiền giữa các tài khoản; ẩn tài khoản không còn dùng.
• Danh mục tự thêm, sửa, sắp xếp.
• Khoản định kỳ (tiền nhà, tiền điện, đăng ký hằng tháng) tự được ghi khi tới hạn.
• Ngân sách tháng có thanh tiến độ và cảnh báo khi vượt, thêm ngân sách riêng cho từng danh mục nếu muốn.
• Đủ các loại tiền tệ theo chuẩn ISO, có ô tìm. Đổi tiền tệ thì mọi số tiền được quy đổi theo tỉ giá tải về (hoặc tỉ giá bạn tự nhập).

NHẮC GHI CHÉP
• Tùy chọn, mặc định tắt: mỗi ngày một thông báo vào giờ bạn chọn, tạo ngay trên iPhone và không chứa số liệu. App chỉ xin quyền thông báo khi bạn bật tính năng này.

RIÊNG TƯ
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Ví Gọn không có máy chủ và không gửi dữ liệu của bạn đi đâu: app chỉ dùng mạng để tải bảng tỉ giá công khai khi bạn đổi tiền tệ. Nhà phát triển không nhận dữ liệu của bạn.
• Dữ liệu chỉ lưu trong app trên iPhone của bạn và không nằm trong bản sao lưu iCloud hay sao lưu iPhone bằng máy tính; khi đổi máy, hãy tự xuất file sao lưu rồi khôi phục trên máy mới.
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tùy chọn che nội dung khi chuyển app: che số liệu trong màn chuyển app. (iPhone không cho app chặn chụp màn hình.)
• Widget mặc định không hiện số tiền. Bạn có thể bật hiện số đã chi trong tháng; khi khóa PIN đang bật, widget luôn ẩn số.

SAO LƯU
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Numbers, Excel hoặc Google Sheets. Có thể đặt mật khẩu cho file sao lưu (mã hóa AES-256); quên mật khẩu thì không mở được file. Không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn.
• Sao lưu tự động (tùy chọn, mặc định tắt): chọn một thư mục trong app Tệp, ví dụ trong iCloud Drive. Khi bạn mở Ví Gọn, app ghi một file sao lưu đã mã hóa vào đó, mỗi ngày tối đa một lần nếu dữ liệu có thay đổi, giữ 7 file gần nhất. Mật khẩu nằm trong Keychain của iPhone; quên mật khẩu thì không ai lấy lại được file, kể cả nhà phát triển.

DỄ DÙNG
• Tiếng Việt và tiếng Anh, giao diện sáng và tối.
• Hỗ trợ cỡ chữ lớn; mọi nút đều có nhãn cho VoiceOver.

Miễn phí. Không mua trong app.
```

- **What's New** (dùng cho TestFlight / bản sau): `Bản đầu tiên: ghi khoản nhanh, tìm kiếm, biểu đồ theo danh mục, tài khoản và chuyển tiền, khoản định kỳ, ngân sách tháng và theo danh mục, nhắc ghi chép hằng ngày, widget, sao lưu có mật khẩu và sao lưu tự động, xuất CSV, khóa PIN.`

Điểm khác bản Play có chủ đích: "VoiceOver" thay "TalkBack"; ~~iOS không có khái niệm "quyền Internet" nên viết "không kết nối Internet"~~
(D-025: cả hai bản nay cùng viết "chỉ dùng mạng để tải bảng tỉ giá công khai khi đổi tiền tệ");
nêu rõ dữ liệu không nằm trong sao lưu iPhone và đổi máy phải tự xuất file (D-021: DB iOS loại khỏi sao lưu, giống Android
`allowBackup=false` — xem `docs/legal/privacy-policy.md` mục 2).
Theo D-022 (2026-11-05) bản App Store CÓ widget, sao lưu tự động, che nội dung; chỉ **icon đơn sắc** (F-23) là của riêng Android nên
không nhắc. Khác bản Play có chủ đích ở ba tính năng này, theo đúng chữ trong app (`*Ios` trong `.arb`):
che nội dung — iPhone chỉ che ở màn chuyển app, **không** viết "chặn chụp màn hình" (`secureWindowNoteIos`);
sao lưu tự động — chọn thư mục trong app Tệp, chạy **khi mở app**, mỗi ngày tối đa một lần (`autoBackupNoteIos`, `autoBackupRunsOnOpenIos`),
không hứa chạy nền theo giờ. Không ghi "widget cần iOS 16" vì cả app cần iOS 16.0 trở lên (D-024) — App Store tự hiện yêu
cầu hệ thống. Mật khẩu sao lưu tự động: "Keychain" (Play: "kho khóa an toàn").

## Age Rating (bảng câu hỏi mới của Apple, từ 2025: 4+, 9+, 13+, 16+, 18+)
Trả lời đề xuất (mọi câu theo tần suất chọn **None**, mọi câu có/không chọn **No**):
| Nhóm câu hỏi | Trả lời | Lý do |
|---|---|---|
| Nội dung: bạo lực (hoạt hình, thực tế, kéo dài), chủ đề bạo lực, kinh dị, tình dục/khoả thân, ngôn từ thô tục, ma tuý/rượu/thuốc lá, chủ đề người lớn | None | App chỉ có số liệu thu chi do người dùng nhập |
| Chủ đề y tế / sức khoẻ, thông tin y khoa | None / No | Không có |
| Cờ bạc mô phỏng, cờ bạc thật, cuộc thi, loot box | None / No | Không có |
| Nội dung do người dùng tạo được chia sẻ / nhắn tin / chat | No | Ghi chú chỉ nằm trên máy, không ai khác thấy |
| Truy cập web không giới hạn (trình duyệt trong app) | No | Không có WebView; nút chính sách mở Safari bên ngoài |
| Quảng cáo | No | Không có |
| Kiểm soát trong app (parental controls, xác minh tuổi) | No | Không có; không cần cho nội dung 4+ |
| Khả năng (capabilities) khác hỏi trong bảng | No | Không tài khoản, không vị trí, không camera; mạng chỉ để tải bảng tỉ giá công khai (D-025), không có nội dung web |
Kết quả dự kiến: **4+** ở mọi vùng (Việt Nam theo thang riêng của Apple cho VN — dự kiến mức thấp nhất). Không chọn "Made for Kids".
Kiểm lại câu chữ thật của bảng hỏi trong App Store Connect khi điền; ghi kết quả vào COMPLIANCE P-05.

## App Privacy (nhãn quyền riêng tư)
**Hướng khai: THẬN TRỌNG** — người dùng chọn 2026-11-05 (sau D-025), thay bản cũ "Data Not Collected" (bản cũ: phiên con D7). Soạn ở phiên
con D8 (`notes/2026-11-05-d8-privacy-declarations.md`). Cùng lý do với Data safety ở `store/listing.md`: yêu cầu tải tỉ giá duy nhất
(`GET https://open.er-api.com/v6/latest/USD`, khi người dùng đổi tiền tệ) để lộ **địa chỉ IP** cho ExchangeRate-API, IP có thể suy ra
**vị trí gần đúng**. App không đọc vị trí (không Core Location, không `NSLocation…UsageDescription`), nhà phát triển không nhận IP.

### Từng màn trong App Store Connect → App Privacy → Get Started / Edit
| Màn / câu hỏi | Trả lời | Lý do |
|---|---|---|
| Do you or your third-party partners collect data from this app? | **Yes, we collect data from this app** | Apple: "thu thập" = truyền ra khỏi máy để nhà phát triển hoặc **đối tác bên thứ ba** truy cập lâu hơn thời gian phục vụ yêu cầu tức thời. ExchangeRate-API giới hạn tần suất theo IP (chặn 20 phút) → giữ IP lâu hơn một yêu cầu. Thận trọng: coi họ là "đối tác bên thứ ba" (nhà cung cấp bên ngoài mà app gọi) |
| Chọn loại dữ liệu | Chỉ **Location › Coarse Location** | Coarse Location = vị trí độ phân giải thấp hơn toạ độ 3 chữ số thập phân — vị trí suy từ IP thuộc nhóm này. KHÔNG chọn Precise Location, Contact Info, Financial Info (số tiền chỉ ở trên máy), User Content (file sao lưu/CSV do người dùng tự chọn đích), Identifiers (không gửi User ID/Device ID/IDFA), Usage Data, Diagnostics (crash qua Apple, không phải app gửi), Other Data |
| Coarse Location — Indicate how … is being used by you or your third-party partners | Chỉ **App Functionality** | Để lấy tỉ giá quy đổi số tiền. KHÔNG Third-Party Advertising, Developer's Advertising or Marketing, Analytics, Product Personalization, Other Purposes |
| Is the coarse location collected from this app linked to the user's identity? | **No** | App không có tài khoản, không gửi ID nào (không User ID, Device ID, IDFA), URL giống nhau cho mọi người dùng; nhà phát triển không có gì để nối IP với một người. Nêu để người dùng biết: Apple coi dữ liệu là "linked" trừ khi đã bỏ định danh trước khi thu; IP tự nó không phải định danh tài khoản ở đây |
| Do you or your third-party partners use coarse location for tracking purposes? | **No** | Không quảng cáo, không chia sẻ cho data broker, không ATT/IDFA; `NSPrivacyTracking = false` |

**Nhãn dự kiến trên trang App Store:** *Data Not Linked to You: Location* · *Data Used to Track You*: không có. Đối chiếu bản xem trước
(Preview) trong App Store Connect trước khi Publish.

**Vì sao không dùng ngoại lệ "optional disclosure" của Apple:** ngoại lệ đòi đủ bốn điều, trong đó dữ liệu phải do **người dùng tự nhập trong
giao diện app** kèm tên rõ ràng — IP không do người dùng nhập → không áp dụng. Vì vậy phải khai (khớp hướng thận trọng).

### Lý do các phần khác vẫn KHÔNG phải "thu thập" (giữ nguyên đánh giá cũ)
  - Không SDK bên thứ ba thu dữ liệu: các gói dùng (`drift`/SQLite, `flutter_secure_storage`, `share_plus`, `file_picker`,
    `path_provider`, `package_info_plus`, `url_launcher`, `fl_chart`, `crypto`, `cryptography`, `flutter_local_notifications`,
    `timezone`, `flutter_timezone`, `material_symbols_icons`) chỉ chạy trên máy (SBOM `docs/sbom/vigon.cdx.json`).
  - Nhắc ghi chép (bản 1.2) là thông báo cục bộ do iOS lên lịch trên máy, không qua máy chủ, không push (APNs), không chứa số liệu.
  - File sao lưu/CSV chỉ rời máy khi người dùng tự chọn đích trong share sheet; nhà phát triển không nhận.
  - DB của app được loại khỏi sao lưu iCloud/máy tính (D-021), nên dữ liệu không rời máy qua đường sao lưu của iOS. (Kể cả khi có,
    sao lưu iCloud do Apple và người dùng kiểm soát, nhà phát triển không truy cập → cũng không tính là "thu thập".)
  - Mã hoá file sao lưu (AES-256-GCM, D-020) chạy trên máy, khoá suy ra từ mật khẩu người dùng nhập, không gửi đi → không ảnh hưởng nhãn.
  - Sao lưu tự động (D-022): app chỉ ghi file **đã mã hoá** vào thư mục **người dùng tự chọn** trong app Tệp. Nếu thư mục nằm trên
    iCloud Drive/Google Drive…, việc tải lên do Apple/nhà cung cấp đó làm theo lựa chọn của người dùng; app không tự tải file lên, nhà phát
    triển không truy cập được → không tính là "thu thập". Mật khẩu ở Keychain, không rời máy.
  - Widget (D-022, D-016): extension đọc **một chuỗi đã định dạng** trong App Group `group.com.phiotron.vigon` (UserDefaults dùng chung
    giữa app và extension, chỉ trên máy); mặc định không có số, PIN bật thì không bao giờ có số. Không truyền đi → không ảnh hưởng nhãn.
  - Che nội dung (F-22): lớp phủ native, không lưu hay gửi gì.
  - Không theo dõi (tracking) → không cần App Tracking Transparency.
- Privacy manifest: `ios/Runner/PrivacyInfo.xcprivacy` và `ios/VigonWidget/PrivacyInfo.xcprivacy` đang có `NSPrivacyTracking = false`,
  `NSPrivacyTrackingDomains` rỗng, `NSPrivacyCollectedDataTypes` rỗng (kiểm 2026-11-04; widget kiểm 2026-11-05); các plugin tự kèm manifest riêng.
  **Chưa khớp nhãn thận trọng (D8, 2026-11-05):** để báo cáo privacy của Xcode khớp App Privacy, manifest của **app** (`ios/Runner`) nên
  thêm một mục `NSPrivacyCollectedDataTypes`: `NSPrivacyCollectedDataType` = `NSPrivacyCollectedDataTypeCoarseLocation`,
  `NSPrivacyCollectedDataTypeLinked` = false, `NSPrivacyCollectedDataTypeTracking` = false, `NSPrivacyCollectedDataTypePurposes` =
  [`NSPrivacyCollectedDataTypePurposeAppFunctionality`]. Việc của phiên code (ngoài phạm vi phiên store; `test/` có thể cần sửa theo).
  Widget extension không gọi mạng → manifest widget giữ nguyên rỗng.
- Nếu sau này thêm SDK báo crash, analytics, đồng bộ đám mây, hay bất kỳ yêu cầu mạng nào khác ngoài tải bảng tỉ giá (hoặc gửi kèm dữ
  liệu người dùng/tiền tệ đang dùng) → nhãn này SAI, phải khai lại trước khi nộp bản đó.

## Export compliance (mã hoá) — D-020 (người dùng quyết 2026-11-05): khai "có mã hoá chuẩn ngoài iOS", vẫn bán ở Pháp
**Sự thật trong code (kiểm 2026-11-05):**
- `lib/src/data/backup_crypto.dart`: file sao lưu có mật khẩu (F-21, D-012) dùng **AES-256-GCM** (nonce 12 byte) + khoá từ
  **PBKDF2-HMAC-SHA256** (100.000 vòng, muối 16 byte) qua gói Dart `cryptography` 2.9.0 — bản **Dart thuần** (không có
  `cryptography_flutter` trong `pubspec.lock`), tức **không** gọi mã hoá của iOS (CryptoKit/CommonCrypto). Trên iPhone người dùng bật
  được tính năng này (Cài đặt → Xuất bản sao lưu → "Protect file with a password"). Sao lưu tự động (D-022, có cả trên iOS) dùng cùng
  `backup_crypto.dart` (AES-GCM, luôn có mật khẩu) → cùng loại mã hoá, **không đổi** câu trả lời bảng hỏi hay khai báo ANSSI.
- ~~Không có mã gọi mạng; không TLS do app tự làm.~~ Từ D-025 (2026-11-05): app gọi HTTPS (một GET bảng tỉ giá) bằng `dart:io HttpClient`.
  Lưu ý: TLS của `dart:io` là **BoringSSL đóng trong engine Flutter**, KHÔNG phải mã hoá của iOS (khác câu "HTTPS do hệ điều hành" trong
  D-025). Vẫn là thuật toán chuẩn → câu trả lời bảng hỏi Apple **không đổi** (đã chọn "standard encryption … instead of, or in addition
  to … Apple's operating system"); nhưng **bản khai ANSSI nên nêu thêm chức năng TLS (HTTPS client, chỉ tải dữ liệu công khai)** bên cạnh
  AES-256-GCM — phiên điều phối báo người dùng trước khi nộp. Băm PIN SHA-256 (gói `crypto`) chỉ để xác thực. Keychain là của iOS.

**Bảng của Apple** ([Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/), đọc 2026-11-05):
| Loại mã hoá | Tài liệu Apple yêu cầu | Ví Gọn |
|---|---|---|
| Chỉ mã hoá có sẵn trong hệ điều hành Apple | Không cần | Không đúng (AES-GCM tự cài bằng Dart) |
| Thuật toán chuẩn quốc tế, **không** lấy từ iOS | **Khai báo mã hoá của Pháp** (chỉ khi phân phối ở Pháp); không cần CCATS của Mỹ | **Đúng trường hợp này** |
| Thuật toán tự chế / không chuẩn | CCATS + khai báo Pháp | Không |

**Đã quyết (D-020):**
1. `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption` = **`true`** — đã đổi ở commit `8441b6a` (kèm test `plan001_t6_ios_config_test`
   và bước plutil của `.github/workflows/ios.yml`). Đối chiếu file thật trước khi nộp.
2. Bảng hỏi App Store Connect (App Information → App Encryption Documentation → "+", hoặc nút Manage cạnh build thiếu thông tin):
   - Loại thuật toán: **"Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within
     Apple's operating system"** (KHÔNG chọn "proprietary / not accepted as standard", KHÔNG chọn "only Apple's operating system").
   - Có phân phối ở Pháp không: **Có** → tải lên **khai báo mã hoá của Pháp** (bản khai đã nộp ANSSI + biên nhận/xác nhận của ANSSI,
     gộp một PDF) khi được hỏi "Choose File".
   - Câu chữ bảng hỏi đổi theo thời gian: đọc lại ngày nộp; nếu xuất hiện câu khác (ví dụ về miễn trừ của Mỹ) thì dừng, ghi câu hỏi
     nguyên văn vào `notes/` và hỏi phiên điều phối, không đoán.
3. **Availability có Pháp ngay bản 1.** Người dùng tự nộp khai báo cho ANSSI — từng bước ở `docs/RELEASE.md` mục "Khai báo mã hoá
   cho Pháp". ANSSI xử lý khoảng **1 tháng** từ khi hồ sơ đủ → **nộp sớm**, không đợi build iOS.
4. Apple duyệt tài liệu "khoảng 2 ngày làm việc" nếu đủ thông tin, rồi cấp một **giá trị khoá** (hiện cạnh tài liệu đã duyệt) → phiên
   code thêm `ITSEncryptionExportComplianceCode` = giá trị đó vào `Info.plist` để các build sau không bị hỏi lại
   ([Determine and upload app encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation)).
   Phải xong **trước** khi gửi App Review hoặc TestFlight App Review (tester ngoài); tester nội bộ TestFlight không cần Beta Review.
5. Mỹ: phần mềm đại chúng dùng mã hoá chuẩn thường thuộc diện mass market (ECCN 5D992.c), không cần CCATS theo bảng trên —
   người dùng/luật sư xác nhận, Claude không khẳng định thay. Apple nhắc người nộp chịu trách nhiệm nếu khai sai.

Phương án đã loại (chi tiết D-020): chuyển AES sang CryptoKit để giữ `false`; ẩn mật khẩu file sao lưu trên iOS; bỏ Pháp ở bản 1.
**Dự phòng** nếu tới ngày nộp iOS mà ANSSI chưa xong: phiên điều phối hỏi người dùng có tạm bỏ Pháp khỏi Availability rồi thêm lại
sau không — KHÔNG tự bỏ (trái D-020).

## Thông tin cho App Review (App Review Information)
- Sign-in required: **No** (không có tài khoản).
- Liên hệ: họ tên + email `phamphuongphuongnd@gmail.com` + số điện thoại của người dùng (chỉ Apple thấy).
- Notes (dán nguyên, tiếng Anh):
  ```
  Ví Gọn is an offline-first personal expense tracker. There is no account and no server; all data stays on the device. The only network request is an HTTPS GET of a public exchange rate table (open.er-api.com) made when the user changes currency in Settings > Currency, so the amounts can be converted; no user data is sent. Because the rate provider sees the device's IP address, which can reveal an approximate location, App Privacy declares Coarse Location (App Functionality, not linked, no tracking). Without a connection the user can type the rate manually.
  To try it: tap − or + on the home screen, type an amount, choose a category, Save.
  PIN lock: Settings > Lock with PIN (4 digits, entered twice). The PIN only hides the app UI; data is not encrypted, and the app says so.
  Backup: Settings > Export backup opens the iOS share sheet (Save to Files); you can optionally turn on "Protect file with a password", which encrypts the file on the device (AES-256-GCM). Settings > Restore from backup opens the Files picker for a .vigon file.
  Daily reminder (off by default): Settings > Daily reminder shows a short explanation, then the iOS notification permission prompt. The notification is scheduled locally on the device and contains no figures.
  Automatic backup (off by default): Settings > Automatic backup asks you to pick a folder in the Files app (for example iCloud Drive) and set a password. Because iOS does not run apps on a schedule, the encrypted backup is written when the app is opened, at most once a day and only if data changed; "Back up now" writes one immediately. The app itself makes no network connection for this.
  Home screen widget: add "Ví Gọn" from the widget gallery. Its Expense and Income buttons open the entry screen. Amounts appear only if Settings > "Show amounts on widget" is on and the PIN lock is off.
  Hide content when switching apps: Settings > Hide content when switching apps covers the app's content in the app switcher. It does not block screenshots.
  The app is free, has no in-app purchases and no ads.
  ```
  (Chữ "Settings > …" khớp nhãn tiếng Anh trong app: `autoBackup`, `autoBackupNow`, `widgetShowAmounts`, `secureWindow` trong `app_en.arb`;
  tên widget trong thư viện widget là `widgetPickerName` = "Ví Gọn". Đối chiếu lại đường đi menu trên bản TestFlight trước khi dán.)

## Ảnh chụp và icon
- Kích thước, số lượng, kịch bản dữ liệu mẫu: `store/screenshots-spec.md`. Chụp ở phiên điều phối #3 với UI mới.
  Theo D-022 ảnh iPhone **được** có widget, mục Sao lưu tự động, công tắc che nội dung (UI thật của bản iOS); không có icon đơn sắc
  hay chữ "Android"/"Google Play".
- Icon App Store 1024×1024: **đã có** sau gộp PLAN-001 — `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
  vẽ từ vector logo D-009 (`tool/render_ios_icon.py`), 1024×1024, RGB 8-bit **không alpha** (kiểm header PNG 2026-11-05), không bo góc.
  Xcode lấy icon này khi archive; App Store Connect không cần tải riêng.
- App Preview (video): không làm ở bản 1.
