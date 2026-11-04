# Hồ sơ App Store — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào App Store Connect ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Nội dung phải khớp với Play (`store/listing.md`) và với code; không hứa điều code không làm. Viết 2026-11-04.
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7).

Project iOS (commit `9438ddd`, đã đối chiếu 2026-11-04): **chỉ iPhone** (`TARGETED_DEVICE_FAMILY = 1`), **chỉ màn dọc**,
tên hiển thị `Ví Gọn`, min iOS 15.0, `ITSAppUsesNonExemptEncryption = false`, `ios/Runner/PrivacyInfo.xcprivacy` (không tracking,
không thu thập; required-reason API FileTimestamp `C617.1`, DiskSpace `E174.1`), không khoá `NS…UsageDescription`, không bật
`UIFileSharingEnabled`. Nếu `ios/` đổi các điểm này, sửa lại mục "Ảnh chụp", "Export compliance" và "App Privacy".

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
| Phân phối | Mọi quốc gia/vùng trừ **Trung Quốc đại lục** (app cần số đăng ký ICP mới được bán ở đó; COMPLIANCE nhóm C chưa mở) và **Nga** (nhóm C). Nhóm D theo COMPLIANCE M-01 khi chốt. |
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

SEE YOUR SPENDING
• Donut chart by category, with income, expenses and balance.
• View by day, week, month, year or all time; swipe sideways to change period.
• Records grouped by category with percentages.

STAY ORGANIZED
• Multiple accounts (cash, bank, card) and transfers between them.
• Add, edit and reorder your own categories.
• Recurring records (rent, bills, subscriptions) are added automatically when due.
• Monthly budget with a progress bar and an over-budget warning.

PRIVATE BY DESIGN
• No sign-up, no ads, no tracking, no analytics. Ví Gọn has no server and never connects to the internet, so the developer never receives your data.
• Your records are stored only in the app on your iPhone. If you use iPhone backup (iCloud or a computer), it includes the app's data like any other app.
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Export a backup file and restore it on a new phone; export CSV for Numbers, Excel or Google Sheets. Backup files are not encrypted, so keep them somewhere safe.

EASY TO USE
• Vietnamese and English, light and dark themes.
• Supports large text sizes; every button has a label for VoiceOver.

Free. No in-app purchases.
```

- **What's New in This Version**: App Store Connect **không cho nhập** ở phiên bản đầu tiên (1.0). Dùng câu dưới cho
  TestFlight "What to Test" và giữ cho bản 1.0.1:
  `First release: quick entry, category chart, accounts and transfers, recurring records, monthly budget, backup and CSV export, PIN lock.`

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

NHÌN RÕ CHI TIÊU
• Biểu đồ vòng theo danh mục, tổng thu, tổng chi và số dư.
• Xem theo ngày, tuần, tháng, năm hoặc toàn bộ; vuốt ngang để đổi kỳ.
• Danh sách khoản gom theo danh mục kèm phần trăm.

QUẢN LÝ GỌN GÀNG
• Nhiều tài khoản (tiền mặt, ngân hàng, thẻ) và chuyển tiền giữa các tài khoản.
• Danh mục tự thêm, sửa, sắp xếp.
• Khoản định kỳ (tiền nhà, tiền điện, đăng ký hằng tháng) tự được ghi khi tới hạn.
• Ngân sách tháng có thanh tiến độ và cảnh báo khi vượt.

RIÊNG TƯ
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Ví Gọn không có máy chủ và không bao giờ kết nối Internet, nên nhà phát triển không nhận dữ liệu của bạn.
• Dữ liệu chỉ lưu trong app trên iPhone của bạn. Nếu bạn dùng sao lưu iPhone (iCloud hoặc máy tính), bản sao lưu đó chứa dữ liệu của app như mọi app khác.
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Numbers, Excel hoặc Google Sheets. File sao lưu không được mã hóa, hãy cất ở nơi an toàn.

DỄ DÙNG
• Tiếng Việt và tiếng Anh, giao diện sáng và tối.
• Hỗ trợ cỡ chữ lớn; mọi nút đều có nhãn cho VoiceOver.

Miễn phí. Không mua trong app.
```

- **What's New** (dùng cho TestFlight / bản sau): `Bản đầu tiên: ghi khoản nhanh, biểu đồ theo danh mục, tài khoản và chuyển tiền, khoản định kỳ, ngân sách tháng, sao lưu và xuất CSV, khóa PIN.`

Điểm khác bản Play có chủ đích: "VoiceOver" thay "TalkBack"; iOS không có khái niệm "quyền Internet" nên viết "không kết nối Internet";
nêu rõ sao lưu iPhone có chứa dữ liệu (Android tắt `allowBackup`, iOS thì không — xem `docs/legal/privacy-policy.md` mục 2).

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
    `path_provider`, `package_info_plus`, `url_launcher`, `fl_chart`) chỉ chạy trên máy (SBOM `docs/sbom/vigon.cdx.json`).
  - File sao lưu/CSV chỉ rời máy khi người dùng tự chọn đích trong share sheet; nhà phát triển không nhận.
  - Sao lưu iCloud của iPhone do Apple và người dùng kiểm soát, nhà phát triển không truy cập → không tính là "thu thập".
  - Không theo dõi (tracking) → không cần App Tracking Transparency.
- `ios/Runner/PrivacyInfo.xcprivacy` khớp: `NSPrivacyTracking = false`, `NSPrivacyTrackingDomains` rỗng,
  `NSPrivacyCollectedDataTypes` rỗng (đã kiểm 2026-11-04); các plugin tự kèm manifest riêng.
- Nếu sau này thêm SDK báo crash, analytics, đồng bộ đám mây → nhãn này SAI, phải khai lại trước khi nộp bản đó.

## Export compliance (mã hoá)
- `ITSAppUsesNonExemptEncryption = NO` trong `Info.plist` (khi có khoá này, App Store Connect không hỏi lại mỗi build).
- Lý do: app không tự mã hoá dữ liệu và không kết nối mạng. Băm PIN SHA-256 có muối (gói `crypto`) là hàm băm để xác thực,
  thuộc diện miễn trừ; Keychain là mã hoá của hệ điều hành. Không cần tài liệu ERN/CCATS, không cần nộp báo cáo năm.
- Pháp: không phải nộp khai báo mã hoá cho Pháp (không dùng mã hoá ngoài hệ điều hành).

## Thông tin cho App Review (App Review Information)
- Sign-in required: **No** (không có tài khoản).
- Liên hệ: họ tên + email `phamphuongphuong@gmail.com` + số điện thoại của người dùng (chỉ Apple thấy).
- Notes (dán nguyên, tiếng Anh):
  ```
  Ví Gọn is a fully offline personal expense tracker. There is no account, no server and no network access; all data stays on the device.
  To try it: tap − or + on the home screen, type an amount, choose a category, Save.
  PIN lock: Settings > Lock with PIN (4 digits, entered twice). The PIN only hides the app UI; data is not encrypted, and the app says so.
  Backup: Settings > Export backup opens the iOS share sheet (Save to Files). Settings > Restore from backup opens the Files picker for a .vigon file.
  The app is free, has no in-app purchases and no ads.
  ```

## Ảnh chụp và icon
- Kích thước, số lượng, kịch bản dữ liệu mẫu: `store/screenshots-spec.md`. Chụp ở phiên điều phối #3 với UI mới.
- Icon App Store 1024×1024: `AppIcon` hiện là `icon-512.png` phóng lên 1024 (**hơi mờ**, theo phiên nền iOS). Trước khi nộp,
  xuất bản 1024×1024 gốc từ canvas Design (logo D-009, `store/brand/README.md`) — PNG vuông, **không trong suốt, không bo góc**.
- App Preview (video): không làm ở bản 1.
