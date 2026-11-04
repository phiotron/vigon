# Hồ sơ Google Play — Ví Gọn (bản nháp, chưa nộp)

Bản nháp để dán vào Google Play Console ở phiên điều phối #3. Người dùng duyệt tên và nội dung trước khi nộp.
Bản App Store tương ứng: `store/app-store.md` (giữ hai bản thống nhất: sửa một bên thì sửa bên kia).
Không sao chép tên, icon, mô tả hay ảnh của app khác (SPEC mục 7). Rà lại 2026-11-04.

## Tên (≤ 30 ký tự)
- Tiếng Việt: **Ví Gọn: Ghi Thu Chi** (19)
- Tiếng Anh: **Ví Gọn: Expense Tracker** (23)
- Tên dưới icon trên máy vẫn là **Ví Gọn** (Android `android:label`, iOS `CFBundleDisplayName`).
- Đã loại các gợi ý tiếng Anh cũ (Neat Wallet, Tidy Wallet, Pocket Ledger): "Neat" là thương hiệu phần mềm chi phí có sẵn;
  giữ một thương hiệu "Ví Gọn" cho mọi ngôn ngữ thì không phải tra trùng nhiều tên. Tra trùng 2026-11-04: xem `store/app-store.md`.
- Nếu người dùng muốn tên ngắn đúng "Ví Gọn" thì vẫn hợp lệ; chỉ mất từ khoá mô tả trong tên.

## Mô tả ngắn (≤ 80 ký tự)
- vi: Ghi thu chi trong vài giây. Dữ liệu chỉ nằm trên máy bạn, không cần mạng. (73)
- en: Log income and spending in seconds. Your data stays on your phone, no internet. (79)

## Mô tả đầy đủ (≤ 4.000 ký tự)

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

**Riêng tư**
• Không đăng ký, không quảng cáo, không theo dõi, không công cụ phân tích. Mọi dữ liệu chỉ lưu trên điện thoại của bạn. Ví Gọn không xin quyền Internet nên không thể gửi dữ liệu đi, và không tự sao lưu lên đám mây.
• Khóa bằng mã PIN 4 số (tùy chọn). PIN chỉ ngăn người khác mở app, không mã hóa dữ liệu. Quên mã PIN thì chỉ có cách xóa dữ liệu trong app.
• Tự xuất file sao lưu và khôi phục khi đổi máy; xuất CSV để mở bằng Excel hoặc Google Sheets. File sao lưu không được mã hóa, hãy cất ở nơi an toàn.

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

**Private by design**
• No sign-up, no ads, no tracking, no analytics. All data stays on your phone. Ví Gọn has no Internet permission, so it cannot send your data anywhere, and it does not back itself up to the cloud.
• Optional 4-digit PIN lock. It keeps others out of the app but does not encrypt your data. If you forget the PIN, the only way back in is to delete the app's data.
• Export a backup file and restore it on a new phone; export CSV for Excel or Google Sheets. Backup files are not encrypted, so keep them somewhere safe.

**Easy to use**
• Vietnamese and English, light and dark themes.
• Supports large text sizes; every button has a label for the TalkBack screen reader.

Free. No in-app purchases.

Khác bản App Store có chủ đích: Android tắt sao lưu tự động (`allowBackup=false`) nên được viết "không tự sao lưu lên đám mây";
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
   (Play định nghĩa "collect" = truyền dữ liệu ra khỏi máy. App không có quyền INTERNET, không SDK → không truyền gì.)
2. Vì trả lời No, Play bỏ qua các câu về loại dữ liệu, mã hoá khi truyền, yêu cầu xoá. Trang store sẽ hiện
   "No data collected" và "No data shared with third parties".
3. Nếu bản Play Console đang dùng vẫn hỏi thêm: mã hoá khi truyền → không áp dụng (không truyền); xoá dữ liệu → người dùng tự xoá
   trong app (Cài đặt → Xóa toàn bộ dữ liệu) hoặc gỡ app.
- Đối chiếu nguồn: `docs/SECURITY.md` (bản đồ dữ liệu), SBOM `docs/sbom/vigon.cdx.json`, `aapt2 dump permissions` (không có INTERNET).
- Hành động do người dùng chủ động (chọn đích trong bảng chia sẻ để gửi file sao lưu/CSV) không tính là app thu thập/chia sẻ.
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
- Ảnh chụp màn hình: quy cách và kịch bản ở `store/screenshots-spec.md`; **chụp lại ở phiên điều phối #3 với UI mới**.
  Ảnh hiện có trong `store/screenshots/` (6 ảnh 1080×2160, chụp 2026-11-03 trên Galaxy A13, bản release, dữ liệu MẪU) là
  ảnh UI cũ, chỉ giữ làm tham khảo bố cục; có thể dùng tạm cho trang closed test (closed test không bắt ảnh đẹp).
