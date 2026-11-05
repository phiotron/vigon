# Closed testing trên Google Play — Ví Gọn (tài khoản cá nhân)

Viết 2026-11-04. Mục đích: đủ điều kiện xin quyền **production** cho tài khoản Play **cá nhân** mới (COMPLIANCE P-09).
Bắt đầu **càng sớm càng tốt với build hiện tại của `main`** — từ 2026-11-05 đã gộp bản 1.2 (F-01..F-26: nhắc ghi chép, widget, sao lưu tự động…) và giao diện mới PLAN-001; các build sửa lỗi/chỉnh UI sau đó đẩy tiếp vào cùng track mà không làm mất ngày đã đếm.
Closed test cũng là dịp **thử tay các AC [M] của bản 1.2 trên nhiều máy Android thật** (mục "Nhờ tester thử") — việc này đang chặn production (`docs/RELEASE.md`).

## Luật cần đạt (kiểm lại trong Play Console Help ngày bắt đầu — luật có thể đổi)
- Có một **closed test** đang chạy; khi bấm xin production phải có **ít nhất 12 tester đang opt-in**, và họ đã opt-in
  **liên tục 14 ngày gần nhất** (nguồn: Play Console Help "App testing requirements for new personal developer accounts").
- Đồng hồ 14 ngày chỉ chạy khi bản closed test **đã được Google duyệt** và **đủ 12 người đã opt-in**. Tester rời chương trình làm
  số người tụt dưới 12 → các ngày đó không tính. **Tạm dừng (pause/halt) track closed test có thể làm mất chuỗi ngày** → không pause.
- Áp dụng **cho từng app** của tài khoản cá nhân. Tester phải dùng tài khoản Google thật trên máy Android thật (máy ảo/tài khoản trùng không tính).
- Google xem cả mức **tương tác thật**: tester mở app vài lần trong tuần, có phản hồi. Không mua "dịch vụ tester ảo".
- Vì vậy mục tiêu: **15–20 tester** (dư 3–8 người phòng có người rời), giữ đủ **14 ngày + 2 ngày đệm**.

## Điều kiện trước khi đẩy bản closed test (đường găng)
| # | Việc | Ai | Ghi chú |
|---|---|---|---|
| 1 | Tạo tài khoản Play Console **cá nhân** (phí một lần 25 USD), xác minh danh tính, xác minh có thiết bị Android | Người dùng | Xác minh danh tính có thể mất vài ngày → làm đầu tiên |
| 2 | Đăng chính sách quyền riêng tư lên web, lấy URL | Người dùng | Play bắt khai Privacy policy + Data safety trước khi gửi duyệt bất kỳ track nào. Nội dung: `docs/legal/privacy-policy.md` |
| 3 | Tạo upload keystore ngoài repo, `android/key.properties` | Người dùng | `docs/RELEASE.md` mục "Ký ứng dụng" |
| 4 | Build `flutter build appbundle` từ `main` đã gộp (bản hiện tại `1.0.0+1`); trước khi tải lên chạy `aapt2 dump permissions` trên APK/AAB: đúng `INTERNET` (D-025, chỉ tải tỉ giá) + `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` | Người dùng hoặc phiên điều phối (sau khi có khoá) | Mỗi lần đẩy build mới tăng số sau `+` |
| 5 | Tạo app trong Play Console: tên `Ví Gọn: Ghi Thu Chi`, ngôn ngữ mặc định vi-VN (thêm en-US), App, Free | Người dùng | Nội dung: `store/listing.md` |
| 6 | Điền đủ App content (privacy policy, ads, app access, content rating, target audience, data safety, financial features…) | Người dùng | Trả lời sẵn ở `store/listing.md` |
| 7 | Store listing tối thiểu: mô tả ngắn/dài, icon 512, ảnh bìa 1024×500, ≥ 2 ảnh điện thoại | Người dùng | Ảnh cũ trong `store/screenshots/` là UI trước PLAN-001 — dùng tạm được cho closed test, hoặc chụp nhanh 2–4 ảnh UI mới; bộ ảnh chính thức chụp ở phiên #3 |
| 8 | Có danh sách ≥ 15 tester đồng ý tham gia | Người dùng | Mục "Mời tester" |

## Lịch đề xuất (bắt đầu từ 2026-11-04)
| Ngày (dự kiến) | Mốc |
|---|---|
| 04–07/11 | Bước 1–3, 8 song song: mở tài khoản Play, đăng chính sách, tạo keystore, gom tester |
| 08–10/11 | Bước 4–7: build AAB, tạo app, điền App content, tạo track **Closed testing**, thêm Google Group, gửi duyệt |
| 10–12/11 | Google duyệt bản closed test (thường vài giờ tới vài ngày). Ngay khi duyệt: gửi link opt-in cho tester, nhắc cài trong ngày |
| **Ngày 0** (≈ 12/11) | Đủ ≥ 12 người opt-in → bắt đầu đếm. Ghi ngày này vào bảng "Nhật ký" bên dưới |
| Ngày 3, 7, 11 | Gửi tin nhắc (mẫu bên dưới). Kiểm số opt-in trong Play Console (Testing → Closed testing → Testers) |
| Giữa kỳ (phiên #2) | Đẩy build sửa lỗi / chỉnh UI vào **cùng track** (tăng versionCode) — không tạo track mới, không pause track cũ |
| **Ngày 14** (≈ 26/11) | Kiểm: ≥ 12 người opt-in suốt 14 ngày. Đợi thêm 1–2 ngày đệm |
| ≈ 27–28/11 | Dashboard → "Apply for production" → điền form (câu trả lời mẫu bên dưới) |
| ≈ 28/11–05/12 | Google xét đơn (thường tới khoảng 7 ngày). Được duyệt → phiên #3 đẩy bản production |
Nếu đơn bị từ chối: đọc lý do, kéo dài test thêm 14 ngày với tương tác nhiều hơn, rồi xin lại.

## Mời tester
**Cách khuyên dùng: Google Group** (thêm/bớt người không phải sửa Play Console).
1. Vào groups.google.com → Create group, ví dụ tên `vigon-testers` (email nhóm `vigon-testers@googlegroups.com` nếu còn trống).
   Ai có thể tham gia: "Anyone on the web can ask" hoặc "Only invited users"; ai xem thành viên: chỉ quản lý (để giữ riêng tư email tester).
2. Mời tester vào nhóm (Members → Add members, hoặc gửi link nhóm để họ bấm Join).
3. Play Console → Testing → Closed testing → track → Testers → chọn **Google Groups** → nhập email nhóm → Save.
4. Copy **link opt-in** ("Join on the web") trong tab Testers, gửi cho tester.
5. Tester: mở link **bằng đúng tài khoản Google đang dùng trên điện thoại Android** → "Become a tester" → bấm link tải trên Google Play → cài.

**Cách thay thế: danh sách email** (Testers → Email lists → Create list, dán email Gmail từng người). Hợp khi < 20 người và ổn định.
Lưu danh sách tester (tên + email) ở chỗ riêng của người dùng, **không commit vào repo** (dữ liệu cá nhân của người khác).

Nguồn tester gợi ý: người thân, đồng nghiệp, bạn bè dùng Android; nhóm cộng đồng dev Việt Nam hỗ trợ test chéo
(chỉ nhận người thật dùng thật). Mỗi người cần: máy Android, tài khoản Google, đồng ý ở lại ≥ 16 ngày.

## Mẫu tin nhắn (người dùng tự gửi; Claude không gửi)
**Lời mời (vi):**
> Chào bạn, mình đang làm app ghi chép thu chi "Ví Gọn" (miễn phí, không quảng cáo, ghi chép không cần mạng). Google bắt app mới
> phải có ít nhất 12 người thử trong 14 ngày liền mới được phát hành. Bạn giúp mình nhé:
> 1) Vào link [link nhóm] bấm tham gia; 2) mở [link opt-in] bằng đúng Gmail trên điện thoại Android, bấm "Become a tester";
> 3) cài app từ Google Play. Bạn chỉ cần **giữ tham gia và giữ app trên máy ít nhất 16 ngày (tới [ngày])**, mở app ghi vài khoản
> mỗi tuần. App không gửi dữ liệu thu chi của bạn đi đâu (chỉ dùng mạng để tải tỉ giá khi bạn đổi tiền tệ). Góp ý gửi mình qua [email/Zalo] hoặc nút "Gửi phản hồi" trên trang Play. Cảm ơn bạn!

**Invite (en):**
> Hi! I'm building "Ví Gọn", a free, ad-free expense tracker that works offline. Google requires new apps to be tested by at least
> 12 people for 14 days in a row before release. Could you help? 1) Join [group link]; 2) open [opt-in link] with the Google
> account on your Android phone and tap "Become a tester"; 3) install from Google Play. Please **stay in the test and keep the
> app installed for at least 16 days (until [date])** and log a few records each week. The app never sends your records anywhere (it only goes online to download exchange rates when you change currency).
> Feedback: [email] or "Send feedback" on the Play page. Thank you!

**Nhắc ngày 3 / 7 / 11 (vi):**
> Nhắc nhẹ: Ví Gọn đang ở ngày [n]/14 của đợt thử. Bạn đừng bấm "Leave the program" và đừng gỡ app tới [ngày] nhé.
> Mở app ghi 1–2 khoản giúp mình. Có lỗi gì cứ nhắn mình. Cảm ơn!

**Khi có build mới (vi):**
> Ví Gọn vừa có bản mới [mô tả ngắn]. Vào Google Play → Ví Gọn → Cập nhật. Bạn thử [màn/tính năng] rồi góp ý giúp mình nhé.

## Nhờ tester thử (tính năng cần máy thật, `docs/SPEC.md` mục 3c, `docs/TESTING.md` M-1..M-7)
Gửi kèm tin mời hoặc tin nhắc ngày 3. Mỗi tester chọn 1–2 mục, báo lại "được / không được + đời máy + Android mấy":
- **Nhắc ghi chép:** Cài đặt → Nhắc ghi chép → bật, chọn giờ gần (ví dụ sau 5 phút). Hộp giải thích hiện trước hộp thoại quyền? Thông báo có tới đúng giờ (sai vài phút là bình thường)? Chạm thông báo có mở màn Nhập khoản chi? Khởi động lại máy rồi hôm sau còn nhắc không?
- **Widget:** thêm widget Ví Gọn ra màn hình chính; chạm "Chi"/"Thu" mở đúng màn? Bật "Hiện số tiền trên widget" thì số hiện; bật khoá PIN thì số biến mất?
- **Sao lưu tự động:** bật, chọn một thư mục trong Google Drive hoặc bộ nhớ máy, đặt mật khẩu, bấm "Sao lưu ngay" → file `vigon-auto-…` có trong thư mục? Khôi phục file đó trên máy khác bằng mật khẩu?
- **Che nội dung khi chuyển app:** bật rồi mở danh sách app gần đây — Ví Gọn có hiện màn trống, chụp màn hình bị chặn?
- **Sao lưu có mật khẩu:** Xuất bản sao lưu với mật khẩu, khôi phục; thử sai mật khẩu.
Ghi kết quả vào `notes/<ngày>-closed-test-feedback.md` (không ghi tên/email tester) để phiên điều phối cập nhật `docs/TESTING.md`.

## Theo dõi trong 14 ngày
- Mỗi lần nhắc: xem số tester opt-in; < 14 người thì mời thêm ngay.
- Gom góp ý vào `notes/<ngày>-closed-test-feedback.md` (tóm tắt, không chép email/tên tester). Lỗi thật → mở việc sửa ở phiên #2.
- Xem Play Console → Quality → Android vitals (crash/ANR) và mục Pre-launch report (Google tự chạy app trên máy thật).
- Ghi lại số liệu cho form production: số tester, số build đã đẩy, số góp ý, thay đổi đã làm.

### Nhật ký (điền khi chạy)
| Ngày | Số opt-in | Build (versionCode) | Việc / góp ý chính |
|---|---|---|---|
| | | | |

## Câu trả lời mẫu cho form "Apply for production"
Form bằng tiếng Anh; câu hỏi có thể đổi. **Thay mọi `[...]` bằng số liệu thật** — không bịa số, Google đối chiếu với dữ liệu track.

- **How did you recruit users for your closed test?**
  `I invited friends, family and colleagues who use Android phones and manage personal or household spending, through a Google Group. [N] testers joined; all used their own phones and Google accounts.`
- **How easy was it to recruit testers?** → chọn mức đúng thực tế (ví dụ "Neither easy nor difficult").
- **Describe the engagement you received from testers during your closed test.**
  `Testers logged daily expenses, tried budgets, recurring records, backup/restore and the PIN lock over [14+] days. I sent reminders on days 3, 7 and 11 and released [K] updated builds that testers installed through Play.`
- **Provide a summary of the feedback you received and how you collected it.**
  `Feedback came through Play private feedback and direct messages. Main points: [ví dụ: chữ nhỏ ở màn X, muốn thêm danh mục Y, lỗi Z khi khôi phục]. `
- **Who is the intended audience of your app?**
  `Adults and teenagers (13+) in Vietnam and worldwide who want a quick, private way to track personal or family spending, in Vietnamese or English.`
- **Describe how your app provides value to users.**
  `Ví Gọn records an expense in three taps and shows spending by category with a chart, budgets and recurring records. It works offline with no account, no ads, no analytics and no data collection, so financial data never leaves the phone (the only network use is downloading a public exchange rate table when the user changes currency; the rate provider sees only the device IP address).`
- **How many installs do you expect in your first year?** → chọn mức thấp, thực tế (ví dụ "0–10K").
- **What changes did you make to your app based on what you learned during closed testing?**
  `[liệt kê thay đổi thật, ví dụ: redesigned the home screen and entry keypad (build [k]); fixed [lỗi] reported by testers; clarified the PIN warning text].`
- **How did you decide that your app is ready for production?**
  `All planned features passed [352+] automated tests and manual checks on real devices (including reminders, widget and automatic backup on testers' phones); no crashes or ANRs in Android vitals during the test; tester issues were fixed and verified in build [k].`

## iOS (để so sánh)
App Store **không** có luật 12 tester/14 ngày. TestFlight: tester nội bộ (tối đa 100, thành viên App Store Connect) không cần duyệt;
tester ngoài (tối đa 10.000, qua email hoặc link công khai) cần **Beta App Review** cho build đầu. Người dùng không có iPhone →
thử iOS bằng simulator trên GitHub Actions; TestFlight khi mượn được máy (`docs/RELEASE.md` mục iOS).
