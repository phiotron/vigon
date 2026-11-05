# Hồ sơ App Store — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào App Store Connect ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Nội dung phải khớp với Play (`store/listing.md`) và với code; không hứa điều code không làm. Viết 2026-11-04; cập nhật 2026-11-05
sau khi gộp bản 1.2 với giao diện/iOS (D-019): thêm tính năng 1.1/1.2 **có trên iPhone** (tìm kiếm, ẩn tài khoản, ngân sách theo
danh mục, đủ tiền tệ ISO, nhắc ghi chép hằng ngày, đặt mật khẩu cho file sao lưu). **Widget màn hình chính, sao lưu tự động vào thư
mục, che nội dung ở màn đa nhiệm và icon đơn sắc chỉ có trên Android** (trên iOS mục cài đặt bị ẩn) → KHÔNG đưa vào mô tả, ảnh chụp
hay Review Notes của App Store (App Review 2.3.1, 2.3.10: không mô tả tính năng không có, không nhắc nền tảng khác trong metadata).
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7).

Project iOS trên `main` sau gộp (đối chiếu lại 2026-11-05, commit `a00bec8`): **chỉ iPhone** (`TARGETED_DEVICE_FAMILY = 1`),
**chỉ màn dọc**, tên hiển thị `Ví Gọn`, min iOS 15.0, `CFBundleLocalizations` en + vi, `FlutterDeepLinkingEnabled = false`,
`LSApplicationQueriesSchemes` chỉ `mailto`, `https`, `ITSAppUsesNonExemptEncryption = false` (**phải đổi thành `true` theo D-020**
— phiên code iOS sửa `Info.plist` + test + CI; xem mục Export compliance), DB **chưa** loại khỏi sao lưu iCloud (**phải loại theo D-021**, phiên code iOS),
`ios/Runner/PrivacyInfo.xcprivacy` (không tracking, không thu thập; required-reason API FileTimestamp `C617.1`, DiskSpace `E174.1`),
không khoá `NS…UsageDescription`, không `UIFileSharingEnabled`; icon `AppIcon` đủ cỡ, bản 1024×1024 RGB không alpha (PLAN-001).
Tính năng theo nền tảng (`lib/src/platform_features.dart`, D-019): iOS **có** nhắc ghi chép (thông báo cục bộ, xin quyền khi bật),
mật khẩu file sao lưu, tìm kiếm, ẩn tài khoản, ngân sách theo danh mục, tiền tệ ISO; iOS **không có** widget, sao lưu tự động,
che nội dung đa nhiệm, icon đơn sắc. Nếu `ios/` hoặc danh sách này đổi, sửa lại "Mô tả", "Ảnh chụp", "Export compliance", "App Privacy".
Cập nhật 2026-11-05 (phiên con "Tài liệu theo quyết định mã hoá + iCloud"): mô tả, phân phối, App Privacy, Export compliance viết theo
**D-020** (khai có mã hoá chuẩn, vẫn bán ở Pháp, người dùng nộp khai báo cho ANSSI) và **D-021** (DB iOS không vào sao lưu iCloud/máy tính).
Các câu này chỉ đúng khi code iOS đã làm xong hai quyết định — **đối chiếu `ios/Runner/Info.plist` và code loại DB khỏi sao lưu trước khi dán**.

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
  `money,finance,income,ledger,private,wallet,cash,bills,savings,vigon,vi gon,manager,daily,diary` — 94 ký tự
- **Promotional Text** (≤ 170, đổi được không cần duyệt lại):
  `Log a purchase in three taps. No account, no ads, no internet connection: your income and spending stay on your iPhone, under your control.` — 139 ký tự

**Description** (≤ 4.000):

```
Ví Gọn is a fast personal income and expense tracker that shows where your money goes.

QUICK ENTRY
• Tap − or +, type the amount on a keypad with built-in math (add, subtract, multiply, divide), pick a category. Three taps at most.
• Edit or delete records; undo a delete right away.
• Search records by note, category or amount.

SEE YOUR SPENDING
• Donut chart by category, with income, expenses and balance.
• View by day, week, month, year or all time; swipe sideways to change period.
• Records grouped by category with percentages.

STAY ORGANIZED
• Multiple accounts (cash, bank, card) and transfers between them; hide accounts you no longer use.
• Add, edit and reorder your own categories.
• Recurring records (rent, bills, subscriptions) are added automatically when due.
• Monthly budget with a progress bar and an over-budget warning, plus an optional budget for each category.
• All ISO currencies, with search.

DAILY REMINDER
• Optional, off by default: one notification a day at the time you choose, created on your iPhone and containing no figures. The app asks for notification permission only when you turn it on.

PRIVATE BY DESIGN
• No sign-up, no ads, no tracking, no analytics. Ví Gọn has no server and never connects to the internet, so the developer never receives your data.
• Your records are stored only in the app on your iPhone. They are left out of iCloud and computer backups of your iPhone, so to move to a new phone, export a backup file and restore it there.
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Export a backup file and restore it on a new phone; export CSV for Numbers, Excel or Google Sheets. You can protect a backup file with a password (AES-256 encryption); if you forget the password, the file cannot be opened. Without a password the file is not encrypted, so keep it somewhere safe.

EASY TO USE
• Vietnamese and English, light and dark themes.
• Supports large text sizes; every button has a label for VoiceOver.

Free. No in-app purchases.
```

- **What's New in This Version**: App Store Connect **không cho nhập** ở phiên bản đầu tiên (1.0). Dùng câu dưới cho
  TestFlight "What to Test" và giữ cho bản 1.0.1:
  `First release: quick entry, search, category chart, accounts and transfers, recurring records, monthly and per-category budgets, daily reminder, password-protected backup, CSV export, PIN lock.`

## Vietnamese — localization phụ
- **Name** (≤ 30): `Ví Gọn: Ghi Thu Chi` — 19 ký tự
- **Subtitle** (≤ 30): `Sổ chi tiêu offline, riêng tư` — 29 ký tự
- **Keywords** (≤ 100): `quản lý tiền,ngân sách,tài chính,ví tiền,tiết kiệm,thu nhập,hóa đơn,tiền mặt,vi gon,money,budget` — 96 ký tự
  (121 byte UTF-8). Hiện Apple đếm theo ký tự; nếu App Store Connect báo quá dài thì bỏ `tiền mặt,` rồi `money,`.
- **Promotional Text** (≤ 170):
  `Ghi một khoản chi chỉ trong ba chạm. Không tài khoản, không quảng cáo, không kết nối Internet: thu chi của bạn nằm trên iPhone và do bạn quản lý.` — 145 ký tự

**Description** (≤ 4.000):

```
Ví Gọn giúp bạn ghi chép thu chi hằng ngày thật nhanh và biết tiền của mình đi đâu.

GHI NHANH
• Chạm − hoặc +, nhập số tiền bằng bàn phím có phép tính (cộng, trừ, nhân, chia), chọn danh mục là xong, tối đa 3 lần chạm.
• Sửa hoặc xóa khoản đã ghi; xóa nhầm thì hoàn tác ngay.
• Tìm khoản theo ghi chú, danh mục hoặc số tiền.

NHÌN RÕ CHI TIÊU
• Biểu đồ vòng theo danh mục, tổng thu, tổng chi và số dư.
• Xem theo ngày, tuần, tháng, năm hoặc toàn bộ; vuốt ngang để đổi kỳ.
• Danh sách khoản gom theo danh mục kèm phần trăm.

QUẢN LÝ GỌN GÀNG
• Nhiều tài khoản (tiền mặt, ngân hàng, thẻ) và chuyển tiền giữa các tài khoản; ẩn tài khoản không còn dùng.
• Danh mục tự thêm, sửa, sắp xếp.
• Khoản định kỳ (tiền nhà, tiền điện, đăng ký hằng tháng) tự được ghi khi tới hạn.
• Ngân sách tháng có thanh tiến độ và cảnh báo khi vượt, thêm ngân sách riêng cho từng danh mục nếu muốn.
• Đủ các loại tiền tệ theo chuẩn ISO, có ô tìm.

NHẮC GHI CHÉP
• Tùy chọn, mặc định tắt: mỗi ngày một thông báo vào giờ bạn chọn, tạo ngay trên iPhone và không chứa số liệu. App chỉ xin quyền thông báo khi bạn bật tính năng này.

RIÊNG TƯ
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Ví Gọn không có máy chủ và không bao giờ kết nối Internet, nên nhà phát triển không nhận dữ liệu của bạn.
• Dữ liệu chỉ lưu trong app trên iPhone của bạn và không nằm trong bản sao lưu iCloud hay sao lưu iPhone bằng máy tính; khi đổi máy, hãy tự xuất file sao lưu rồi khôi phục trên máy mới.
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Numbers, Excel hoặc Google Sheets. Có thể đặt mật khẩu cho file sao lưu (mã hóa AES-256); quên mật khẩu thì không mở được file. Không đặt mật khẩu thì file không được mã hóa, hãy cất ở nơi an toàn.

DỄ DÙNG
• Tiếng Việt và tiếng Anh, giao diện sáng và tối.
• Hỗ trợ cỡ chữ lớn; mọi nút đều có nhãn cho VoiceOver.

Miễn phí. Không mua trong app.
```

- **What's New** (dùng cho TestFlight / bản sau): `Bản đầu tiên: ghi khoản nhanh, tìm kiếm, biểu đồ theo danh mục, tài khoản và chuyển tiền, khoản định kỳ, ngân sách tháng và theo danh mục, nhắc ghi chép hằng ngày, sao lưu có mật khẩu, xuất CSV, khóa PIN.`

Điểm khác bản Play có chủ đích: "VoiceOver" thay "TalkBack"; iOS không có khái niệm "quyền Internet" nên viết "không kết nối Internet";
nêu rõ dữ liệu không nằm trong sao lưu iPhone và đổi máy phải tự xuất file (D-021: DB iOS loại khỏi sao lưu, giống Android
`allowBackup=false` — xem `docs/legal/privacy-policy.md` mục 2).
Bản App Store KHÔNG có các mục chỉ-Android (D-019): widget, sao lưu tự động vào thư mục, che nội dung ở màn ứng dụng gần đây, icon
đơn sắc. Mô tả ngắn của Play nhắc "widget" nên không dùng lại cho App Store. Khi có bản iOS của các tính năng này (việc riêng, SPEC
mục 4) thì mới thêm vào đây.

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
| Khả năng (capabilities) khác hỏi trong bảng | No | Không tài khoản, không mạng, không vị trí, không camera |
Kết quả dự kiến: **4+** ở mọi vùng (Việt Nam theo thang riêng của Apple cho VN — dự kiến mức thấp nhất). Không chọn "Made for Kids".
Kiểm lại câu chữ thật của bảng hỏi trong App Store Connect khi điền; ghi kết quả vào COMPLIANCE P-05.

## App Privacy (nhãn quyền riêng tư)
- Câu hỏi "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app.**
  Nhãn hiện ra: **Data Not Collected**.
- Lý do (định nghĩa của Apple: "thu thập" = dữ liệu được truyền ra khỏi máy để nhà phát triển hoặc đối tác truy cập lâu hơn
  thời gian phục vụ yêu cầu tức thời):
  - Không có máy chủ, không có mã gọi mạng trong `lib/` (không gói `http`, `dio`, `HttpClient`, WebView — kiểm 2026-11-04).
  - Không SDK bên thứ ba thu dữ liệu: các gói dùng (`drift`/SQLite, `flutter_secure_storage`, `share_plus`, `file_picker`,
    `path_provider`, `package_info_plus`, `url_launcher`, `fl_chart`, `crypto`, `cryptography`, `flutter_local_notifications`,
    `timezone`, `flutter_timezone`, `material_symbols_icons`) chỉ chạy trên máy (SBOM `docs/sbom/vigon.cdx.json`).
  - Nhắc ghi chép (bản 1.2) là thông báo cục bộ do iOS lên lịch trên máy, không qua máy chủ, không push (APNs), không chứa số liệu.
  - File sao lưu/CSV chỉ rời máy khi người dùng tự chọn đích trong share sheet; nhà phát triển không nhận.
  - DB của app được loại khỏi sao lưu iCloud/máy tính (D-021), nên dữ liệu không rời máy qua đường sao lưu của iOS. (Kể cả khi có,
    sao lưu iCloud do Apple và người dùng kiểm soát, nhà phát triển không truy cập → cũng không tính là "thu thập".)
  - Mã hoá file sao lưu (AES-256-GCM, D-020) chạy trên máy, khoá suy ra từ mật khẩu người dùng nhập, không gửi đi → không ảnh hưởng nhãn.
  - Không theo dõi (tracking) → không cần App Tracking Transparency.
- `ios/Runner/PrivacyInfo.xcprivacy` khớp: `NSPrivacyTracking = false`, `NSPrivacyTrackingDomains` rỗng,
  `NSPrivacyCollectedDataTypes` rỗng (đã kiểm 2026-11-04); các plugin tự kèm manifest riêng.
- Nếu sau này thêm SDK báo crash, analytics, đồng bộ đám mây → nhãn này SAI, phải khai lại trước khi nộp bản đó.

## Export compliance (mã hoá) — D-020 (người dùng quyết 2026-11-05): khai "có mã hoá chuẩn ngoài iOS", vẫn bán ở Pháp
**Sự thật trong code (kiểm 2026-11-05):**
- `lib/src/data/backup_crypto.dart`: file sao lưu có mật khẩu (F-21, D-012) dùng **AES-256-GCM** (nonce 12 byte) + khoá từ
  **PBKDF2-HMAC-SHA256** (100.000 vòng, muối 16 byte) qua gói Dart `cryptography` 2.9.0 — bản **Dart thuần** (không có
  `cryptography_flutter` trong `pubspec.lock`), tức **không** gọi mã hoá của iOS (CryptoKit/CommonCrypto). Trên iPhone người dùng bật
  được tính năng này (Cài đặt → Xuất bản sao lưu → "Protect file with a password"). Sao lưu tự động (cũng AES-GCM) chỉ có trên Android.
- Không có mã gọi mạng; không TLS do app tự làm. Băm PIN SHA-256 (gói `crypto`) chỉ để xác thực. Keychain là của iOS.

**Bảng của Apple** ([Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/), đọc 2026-11-05):
| Loại mã hoá | Tài liệu Apple yêu cầu | Ví Gọn |
|---|---|---|
| Chỉ mã hoá có sẵn trong hệ điều hành Apple | Không cần | Không đúng (AES-GCM tự cài bằng Dart) |
| Thuật toán chuẩn quốc tế, **không** lấy từ iOS | **Khai báo mã hoá của Pháp** (chỉ khi phân phối ở Pháp); không cần CCATS của Mỹ | **Đúng trường hợp này** |
| Thuật toán tự chế / không chuẩn | CCATS + khai báo Pháp | Không |

**Đã quyết (D-020):**
1. `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption` = **`true`** (phiên code iOS đổi, kèm test `plan001_t6_ios_config_test`
   và bước plutil của `.github/workflows/ios.yml` đang kiểm `false`). Đối chiếu file thật trước khi nộp.
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
- Liên hệ: họ tên + email `phamphuongphuong@gmail.com` + số điện thoại của người dùng (chỉ Apple thấy).
- Notes (dán nguyên, tiếng Anh):
  ```
  Ví Gọn is a fully offline personal expense tracker. There is no account, no server and no network access; all data stays on the device.
  To try it: tap − or + on the home screen, type an amount, choose a category, Save.
  PIN lock: Settings > Lock with PIN (4 digits, entered twice). The PIN only hides the app UI; data is not encrypted, and the app says so.
  Backup: Settings > Export backup opens the iOS share sheet (Save to Files); you can optionally turn on "Protect file with a password", which encrypts the file on the device (AES-256-GCM). Settings > Restore from backup opens the Files picker for a .vigon file.
  Daily reminder (off by default): Settings > Daily reminder shows a short explanation, then the iOS notification permission prompt. The notification is scheduled locally on the device and contains no figures.
  The app is free, has no in-app purchases and no ads.
  ```

## Ảnh chụp và icon
- Kích thước, số lượng, kịch bản dữ liệu mẫu: `store/screenshots-spec.md`. Chụp ở phiên điều phối #3 với UI mới.
  Ảnh iPhone KHÔNG được có widget, mục Sao lưu tự động hay công tắc che nội dung (chỉ Android, D-019).
- Icon App Store 1024×1024: **đã có** sau gộp PLAN-001 — `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
  vẽ từ vector logo D-009 (`tool/render_ios_icon.py`), 1024×1024, RGB 8-bit **không alpha** (kiểm header PNG 2026-11-05), không bo góc.
  Xcode lấy icon này khi archive; App Store Connect không cần tải riêng.
- App Preview (video): không làm ở bản 1.
