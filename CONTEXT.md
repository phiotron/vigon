# A002-vigon · Ví Gọn — CONTEXT (glossary)

> Chỉ là bảng thuật ngữ nghiệp vụ, không ghi chi tiết cài đặt. Term (code) = tên dùng trong code/tài liệu kỹ thuật
> (tiếng Anh); VI = chữ hiển thị/tài liệu tiếng Việt; "EN UI" = chữ hiển thị tiếng Anh khi khác Term.
> Nguồn: `docs/SPEC.md` (F-01..F-26), `docs/DECISIONS.md` (D-001..D-019), `lib/src/**`, `lib/l10n/*.arb`,
> `design/current/ui-spec.md` — bản sau khi gộp v1.2 + PLAN-001 (2026-11-05). 🤖 = chỉ Android (ẩn trên iOS, D-019).
> ⚠ = code, SPEC hoặc thiết kế đang lệch nhau — xem mục "Chỗ lệch" ở cuối.

## Ghi chép và phân loại

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Entry** ⚠ | Khoản (khoản ghi) — EN UI: *Record* | Một lần ghi tiền: loại, số tiền > 0, ngày, tài khoản, ghi chú ≤ 200 ký tự; Expense/Income có Category. Đơn vị dữ liệu chính. | "transaction", "giao dịch" (giao dịch = DB transaction) |
| **Entry type** | Loại khoản | `expense` · `income` · `transfer`. Không đổi được loại của khoản đã lưu. | |
| **Expense** ⚠ | Chi (khoản chi) — EN UI: *Expenses* | Entry làm giảm tiền, có danh mục chi. Ghi qua nút "−", icon danh mục quanh vòng, ô "Danh mục khác", nút Chi của Widget hoặc chạm Reminder. | "spending" trong nhãn |
| **Income** | Thu (khoản thu) | Entry làm tăng tiền, có danh mục thu. Ghi qua nút "+" hoặc nút Thu của Widget. | "revenue" |
| **Transfer** | Chuyển tiền | Entry loại `transfer` từ Account nguồn sang Account đích. **Không** phải thu/chi: không vào biểu đồ, tổng thu/chi, Period balance, Budget, Category budget; chỉ đổi Account balance. | "chuyển khoản" (dễ nhầm chuyển khoản ngân hàng / chuyển khoản sang danh mục khác) |
| **Amount** | Số tiền | Số nguyên theo Minor unit của Currency, tối đa 10¹² đơn vị nhỏ nhất. Người dùng gõ phải > 0; Entry có thể là 0 chỉ khi Currency conversion làm tròn một số rất nhỏ (D-029). Là số hiện và cộng tổng; phía sau có thể có Exact amount. | số thực, "giá" |
| **Exact amount** | Số tiền chính xác | Số tiền giữ 6 chữ số lẻ trên đơn vị chính (micro, 10⁻⁶), ẩn, không hiện ở đâu; chỉ dùng khi Currency conversion để đổi A→B→A ra đúng số cũ (D-029). Không có (null) = đúng bằng Amount; Amount bị sửa tay thì Exact amount cũ tự bỏ. | "số gốc", "số thật" |
| **Minor unit** | Đơn vị nhỏ nhất | Đơn vị lưu tiền: theo số chữ số thập phân ISO (VND 0, USD 2, KWD 3). | |
| **Amount expression** | Phép tính | Chuỗi gõ trên Keypad (vd `120+35`), tính ra Amount khi lưu hoặc bấm "=". | "công thức" |
| **Keypad** | Bàn phím số | Bàn phím riêng của app ở màn Nhập khoản/Chuyển tiền (số, `000`/`.`, ⌫, `÷ × − +`, `=`, nút lớn Chọn danh mục/Lưu). Khác **PIN pad**. | "bàn phím hệ thống" |
| **Save on category pick** | Chọn danh mục là lưu | Khi nút lớn đang là "Chọn danh mục", chạm một danh mục trong lưới thì khoản được lưu ngay (D-018, giữ AC-02 ≤ 3 chạm). Đóng lưới không chọn thì không lưu. | |
| **Note** | Ghi chú | Chữ tự do ≤ 200 ký tự của Entry/Transfer/Recurring series; là tiêu đề dòng trong Các khoản. | "mô tả" |
| **Category** | Danh mục | Nhóm phân loại Entry thuộc một loại (`expense`/`income`): tên, icon (khóa chữ, 31 icon chọn được), màu (16 màu token), thứ tự, và với danh mục chi có thể có Category budget. Thứ tự quyết định icon quanh vòng và lưới chọn. | "tag", "nhóm" |
| **Default category** ⚠ | Danh mục mặc định | Tạo lần đầu: chi Ăn uống, Đi lại, Nhà cửa, Hóa đơn, Mua sắm, Sức khỏe, Giải trí, Giáo dục, Gia đình, Khác; thu Lương, Thưởng, Thu khác. Có `nameKey` nên tên đổi theo ngôn ngữ tới khi người dùng đổi tên. Màu/icon theo token (D-010). | |
| **More categories** ⚠ | Danh mục khác (ô ⋯) | Ô cuối quanh vòng ở màn chính khi số danh mục chi nhiều hơn số icon xếp vừa; mở lưới đủ danh mục chi (F-17). Không phải một danh mục. | gọi là danh mục "Khác" (đó là danh mục mặc định) |
| **Move entries on delete** | Chuyển khoản sang danh mục khác khi xóa | Xóa Category bắt buộc chọn Category cùng loại nhận mọi Entry và Recurring series; không xóa được danh mục cuối cùng của một loại. | "xóa kèm khoản" |
| **Search** | Tìm (tìm kiếm khoản) | Chế độ của màn Các khoản: lọc khoản theo ghi chú, tên danh mục hoặc chữ số của số tiền, không phân biệt hoa thường và dấu; theo Account filter; kết quả phẳng mới nhất trước + "N khoản · tổng X" (F-15). | "lọc" (dành cho Account filter) |
| **Search scope: All time** ⚠ | Tất cả thời gian | Chip của Search: tìm trên toàn bộ dữ liệu thay vì Period đang xem. | nhầm với Period "Tất cả" |

## Tài khoản

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Account** | Tài khoản | Nơi giữ tiền (Tiền mặt, Thẻ, Ví điện tử…): tên, Starting balance, trạng thái hiện/ẩn. Mỗi Entry thuộc một Account. | "ví" trong chữ (chỉ là icon), "wallet" |
| **Default account** ⚠ | Tài khoản mặc định | Tài khoản điền sẵn khi ghi khoản mới = tài khoản **hiện** đầu tiên theo thứ tự (lúc cài là "Tiền mặt"). Không có cài đặt riêng. | |
| **Hidden account** (code `archived`) | Tài khoản đã ẩn | Tài khoản bị **Ẩn tài khoản**: không hiện ở bảng chọn tài khoản khi ghi khoản, menu lọc, ô Từ/Đến của Chuyển tiền (trừ lần chuyển cũ của nó). Khoản cũ vẫn trong danh sách và vẫn tính vào tổng; số dư vẫn tính. Liệt kê trong mục thu gọn "Tài khoản đã ẩn", **Hiện lại** được. Trạng thái ẩn đi theo file sao lưu. | "archived", "lưu trữ", "đã xóa" |
| **Delete account** | Xóa tài khoản | Chỉ được khi tài khoản chưa có khoản nào (kể cả chuyển tiền đến) và không Recurring series nào trỏ tới; nếu không thì chỉ ẩn được. Có hộp xác nhận. | |
| **Last visible account** | Tài khoản hiện cuối cùng | Luôn phải còn ≥ 1 tài khoản hiện: không ẩn, không xóa được tài khoản này. | |
| **Starting balance** | Số dư ban đầu | Tiền có sẵn trong Account khi bắt đầu dùng app; có thể âm (thẻ tín dụng); để trống = 0. | "opening balance" trong chữ |
| **Account balance** ⚠ | Số dư tài khoản | Starting balance + thu − chi ± chuyển tiền, mọi thời gian. Hiện ở màn Tài khoản. | gọi trần "Số dư" khi có thể nhầm Period balance |
| **Account filter** | Lọc tài khoản | "Tất cả tài khoản" hoặc một tài khoản hiện (khi ≥ 2 tài khoản hiện); áp cho màn chính và Các khoản (cả Search); Transfer tính nếu tài khoản là nguồn hoặc đích. Chỉ sống trong phiên chạy; tự bỏ khi ẩn tài khoản đang lọc, khôi phục hoặc xóa toàn bộ dữ liệu. | |

## Kỳ, ngân sách, định kỳ

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Period** | Kỳ (kỳ xem) | Khoảng đang xem: `day` Ngày · `week` Tuần · `month` Tháng · `year` Năm · `all` Tất cả · `custom` Khoảng tùy chọn. Mặc định tháng chứa hôm nay; chỉ sống trong phiên chạy. Bảng chọn có tiêu đề "Xem theo". | "range" (chỉ cho Khoảng tùy chọn), "filter" |
| **Period shift** | Kỳ trước / Kỳ sau | Sang Period liền trước/sau cùng loại bằng ‹ › hoặc vuốt ngang. "Tất cả" không có kỳ trước/sau. | |
| **Custom range** | Khoảng tùy chọn | Period do người dùng chọn ngày đầu và ngày cuối trên lịch trong bảng kéo (nút "Áp dụng"). | |
| **Period balance** ⚠ | Số dư (của kỳ) | Tổng thu − tổng chi của Period đang xem (bỏ qua Transfer), theo Account filter. Thanh "Số dư" màn chính và đầu Các khoản. | "số dư tài khoản", "tiết kiệm" |
| **Week start** | Ngày đầu tuần | Thứ Hai (mặc định) hoặc Chủ Nhật; quyết định Period loại Tuần. | |
| **Month start day** | Tháng bắt đầu từ ngày | Ngày 1–28 bắt đầu "tháng" của app; quyết định Period Tháng, tháng của Budget, Category budget và số trên Widget. | "ngày lương" |
| **Budget** | Ngân sách tháng | Một hạn mức chi **tổng** cho tháng hiện tại (theo Month start day), mọi tài khoản, độc lập Period đang xem; thanh ở màn chính. | "hạn mức" trơn khi có thể nhầm Category budget |
| **Category budget** | Ngân sách tháng của danh mục (hạn mức danh mục) | Hạn mức chi tháng hiện tại riêng cho **một danh mục chi** (tùy chọn, đặt trong bảng sửa danh mục); hiện thanh nhỏ trên dòng danh mục ở Các khoản. Độc lập với Budget tổng (F-20). | "budget per account" |
| **Over budget** | Vượt (ngân sách / hạn mức) | Đã chi > hạn mức: chữ "Vượt X" + icon cảnh báo + màu lỗi, không chỉ dựa vào màu. | "cháy túi" |
| **Recurring series** ⚠ | Khoản định kỳ (chuỗi định kỳ) — EN UI: *Repeating records*; code: `RecurringRule` | Quy tắc lặp của một khoản mẫu: loại, số tiền, danh mục, tài khoản, ghi chú, Frequency, ngày bắt đầu, chạy/dừng. Chỉ tạo từ màn Nhập khoản mới (chip Lặp lại). Sửa được số tiền, ghi chú, tần suất, danh mục, tài khoản (F-16). | "subscription", "nhắc nhở" |
| **Frequency** | Chu kỳ lặp (Lặp lại) | `daily` Hằng ngày · `weekly` Hằng tuần · `monthly` Hằng tháng · `yearly` Hằng năm. Đổi tần suất thì chuỗi bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ, không sinh bù. | "period" (đã dùng cho Kỳ) |
| **Generated entry** | Khoản sinh tự động | Entry do Recurring series tạo khi mở app hoặc quay lại từ nền, bù mọi lần tới hạn tới hết hôm nay, không trùng; sau đó là Entry bình thường. | |
| **Stop / Resume series** | Dừng / Chạy lại | Dừng: không sinh thêm ("Đã dừng"). Chạy lại: tiếp từ **hôm nay**, không sinh bù. | "xóa chuỗi" |
| **Undo** | Hoàn tác | Thanh "Đã xóa · Hoàn tác" 5 giây sau khi xóa một Entry/Transfer. | "khôi phục" (dành cho Restore) |

## Tiền tệ, dữ liệu, sao lưu

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Currency** | Tiền tệ | **Một** mã ISO 4217 cho toàn app (khoảng 156 mã, chọn có ô tìm), mặc định theo vùng máy. Đổi tiền tệ = **quy đổi** mọi số tiền (Entry, Recurring series, số dư ban đầu, Budget, Category budget) theo tỉ giá tải qua mạng hoặc nhập tay, trong một lần (D-025); quy đổi từ Exact amount, số hiện làm tròn theo số lẻ của tiền mới (D-029). | "Primary currency", "tiền tệ chính", "base currency" (app không có nhiều tiền tệ) |
| **Backup** | Bản sao lưu (file `.vigon`) | File chứa đủ tài khoản, danh mục, khoản, chuỗi định kỳ, cài đặt (trừ Device-only settings, PIN). Xuất tay qua bảng chia sẻ của hệ điều hành. | "đồng bộ", "cloud backup" |
| **Encrypted backup** | Bản sao lưu có mật khẩu | Backup được bọc mã hóa bằng **Backup password** (AES-256-GCM, khóa từ PBKDF2). Tùy chọn khi xuất tay (mặc định tắt); Auto backup luôn mã hóa. Không đặt mật khẩu thì file là JSON không mã hóa và app nói rõ. | "khóa file", "file PIN" |
| **Backup password** | Mật khẩu (file sao lưu) | Mật khẩu ≥ 6 ký tự, nhập hai lần, có cảnh báo "Quên mật khẩu thì không mở được file". Xuất tay: không lưu ở đâu; Auto backup: lưu trong bộ nhớ an toàn của máy. Khác **PIN**. | "mã", "PIN" |
| **Restore** | Khôi phục | Chọn file qua trình chọn file hệ thống; kiểm file trước; file mã hóa thì hỏi mật khẩu; hợp lệ thì hỏi xác nhận rồi **thay toàn bộ** dữ liệu trong một lần; hỏng/sai mật khẩu thì báo lỗi, dữ liệu không đổi. | "nhập", "import" (không gộp) |
| **Auto backup** 🤖 | Sao lưu tự động | Ghi Encrypted backup `vigon-auto-…` vào **Backup folder** tối đa một lần mỗi ngày khi app ra nền và dữ liệu đã đổi; giữ 2 file mới nhất; "Sao lưu ngay"; trạng thái lần gần nhất. Không mạng, không đăng nhập (F-24). | "đồng bộ Drive", "sync" |
| **Backup folder** 🤖 | Thư mục (sao lưu) | Thư mục người dùng chọn bằng bộ chọn thư mục của Android (Drive, Dropbox, thẻ nhớ, bộ nhớ máy). Việc tải lên đám mây do app sở hữu thư mục làm. "Chọn lại thư mục" khi quyền bị thu hồi hoặc thư mục mất. | "tài khoản Google Drive" |
| **Auto backup status** 🤖 | Trạng thái sao lưu | "Chưa sao lưu lần nào" / "Lần cuối: …" / "Lần thử …: <lỗi>". | |
| **CSV export** | Xuất CSV | File bảng tính (ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, đến tài khoản, ghi chú), tiêu đề và tên loại theo ngôn ngữ app (vi: `;` và dấu `,` thập phân; en: `,` và `.`), UTF-8 có BOM. Chỉ xuất. | "báo cáo" |
| **Device-only setting** | Cài đặt theo máy | Cài đặt không đi theo file sao lưu: công tắc Widget amounts, công tắc Reminder (về TẮT sau khôi phục), cấu hình Auto backup. Giờ nhắc thì có đi theo file. | |
| **Delete all data** | Xóa toàn bộ dữ liệu | Xóa mọi khoản, danh mục, tài khoản, cài đặt, tắt PIN và Auto backup (file đã ghi giữ nguyên); tạo lại mặc định như mới cài. Hai hộp xác nhận. | "reset", "đăng xuất" |

## Bảo mật, quyền riêng tư, ngoài app

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **PIN lock** | Khóa bằng mã PIN | Khóa tùy chọn bằng mã 4 số, hỏi khi mở app và khi quay lại sau > 1 phút ở nền; cả khi vào từ Widget hoặc Reminder. Chỉ chặn người cầm máy, **không mã hóa** dữ liệu. | "mật khẩu", "mã hóa" |
| **Lock screen** | Màn khóa | Lớp phủ kín app khi đang khóa: PIN pad, "Quên mã". | |
| **PIN pad** | Bàn phím PIN | Bàn phím 3×4 ở Màn khóa và màn Đặt mã. Khác Keypad. | |
| **Forgot PIN** | Quên mã | Không có máy chủ nên không lấy lại được PIN; lối ra duy nhất là Delete all data (thêm hai bước xác nhận). | "đặt lại mật khẩu" |
| **Privacy screen** 🤖 (code `secureWindow`) ⚠ | Che nội dung khi chuyển app | Công tắc: Android chặn chụp màn hình và hiện thẻ trống trong danh sách app gần đây (F-22). | "chế độ riêng tư", "ẩn app" |
| **Reminder** | Nhắc ghi chép (nhắc ghi chép hằng ngày) | Thông báo cục bộ mỗi ngày vào **Reminder time** (mặc định 20:00), nội dung chung chung, **không chứa số liệu**; chạm mở Nhập khoản chi (qua Lock screen nếu bật). Android + iOS (F-25). | "push", "nhắc nhở thanh toán", "alert" |
| **Reminder time** | Giờ nhắc | Giờ của Reminder, chọn bằng bộ chọn giờ hệ thống; Android là giờ xấp xỉ. | |
| **Notification permission** | Quyền gửi thông báo | Quyền của hệ điều hành, chỉ xin khi bật Reminder và sau hộp giải thích "Bật nhắc ghi chép?". | |
| **Widget** 🤖 | Widget (màn hình chính) | Widget Android 2×2 "Ví Gọn" có nút **Chi** / **Thu** mở Nhập khoản; dòng trạng thái tùy Widget amounts (F-26). | "tiện ích" trong chữ (UI giữ "widget") |
| **Widget amounts** 🤖 | Hiện số tiền trên widget | Công tắc (mặc định tắt): khi bật VÀ PIN tắt, widget hiện "Tháng này đã chi X (/ hạn mức)"; PIN bật → "Đã khóa bằng PIN"; qua tháng mà app chưa mở → "Mở app để cập nhật". | |
| **Deep link** | Mở thẳng màn nhập khoản | Đường vào từ Widget hoặc Reminder; app chỉ nhận đúng `/entry/new?type=expense|income`, luôn qua Lock screen. | "liên kết" chung chung |
| **Monochrome icon** 🤖 | Biểu tượng đơn sắc | Lớp `monochrome` của icon thích ứng để Android 13+ tô màu theo hình nền; cùng logo "hai thẻ xếp chồng" (F-23, D-009). | |
| **Theme** | Giao diện | Theo hệ thống · Sáng · Tối. | "chủ đề" trong chữ |
| **Language** | Ngôn ngữ | Theo máy · Tiếng Việt · English. Chữ trên nút Widget theo ngôn ngữ **máy**, còn lại theo ngôn ngữ app. | |

## Chỗ lệch giữa code, SPEC và thiết kế

Trạng thái so với bản CONTEXT 2026-11-04: ✔ = đã hết lệch, ⚠ = còn lệch / mới.

| # | Thuật ngữ | Code | SPEC / thiết kế / tài liệu | Trạng thái / đề xuất |
|---|---|---|---|---|
| 1 | Entry | Bảng `Entries`, `EntryType`; EN UI "Record(s)" | SPEC: "khoản", "khoản ghi" | ⚠ giữ nguyên ba tên theo ba tầng (code/EN/VI); không đổi. |
| 2 | Recurring series | `RecurringRules` | SPEC/ui-spec "chuỗi định kỳ"; EN UI "Repeating records" | ⚠ dùng "Recurring series" trong tài liệu, code giữ `RecurringRule`. |
| 3 | Danh mục mặc định "Education" | `.arb` vi "Giáo dục" | SPEC AC-15 "Giáo dục"; `design/current/screens/README.md` và `design-system-guide.md` vẫn ghi **"Học tập"** | ⚠ theo code + SPEC; sửa thiết kế khi xuất lại (đã yêu cầu ở `product.md`). |
| 4 | Danh mục thu "Khác" | `.arb` "Thu khác" / "Other income" | SPEC AC-15 ghi thu "Khác" | ⚠ giữ "Thu khác" (phân biệt chi "Khác"). |
| 5 | Màu + icon danh mục | Seed và bảng màu theo token (D-010); 31 icon + 5 khóa cũ vẫn hiện | Thiết kế ghi "lưu bằng chỉ số 1…31" | ✔ màu/icon đã khớp; ⚠ câu "chỉ số 1…31" trong README thiết kế vẫn sai (code lưu khóa chữ, D-010). |
| 6 | Default account | Tài khoản **hiện** đầu tiên | SPEC AC-04 "tài khoản mặc định" | ⚠ hiểu "mặc định" = đầu danh sách; chọn được là tính năng mới (Future). |
| 7 | Hidden account | Cột `archived`, có giao diện Ẩn/Hiện lại (F-14) | — | ✔ (bản cũ: "có cột, không có giao diện"). Còn lệch hành vi: ẩn tài khoản chưa dừng chuỗi định kỳ trỏ tới nó (ui-spec 9). |
| 8 | "Số dư" / "Balance" | Cùng chữ cho Period balance và Account balance | SPEC AC-07/08 dùng "số dư" cho kỳ | ⚠ tách nghĩa trong tài liệu; thiết kế làm rõ nhãn (product §10.1 #2). |
| 9 | Currency | Một khóa `currency`, ~156 mã | SPEC AC-53 "khoảng 150 mã" | ✔ không dùng "Primary currency". |
| 10 | Nhãn nút Chi (EN) | Nút màn chính dùng `expense` = **"Expenses"**; nút Widget dùng "Expense" | Thiết kế: "Chi"/"Thu" | ⚠ EN lệch số ít/số nhiều giữa app và widget; phiên #2 chốt (vd thêm khóa "Expense"). |
| 11 | More categories | `otherCategories` = "Danh mục khác" / "More categories" | SPEC AC-51: ô **"Thêm"** (dấu ⋯), nhãn "Danh mục khác" | ⚠ SPEC gọi ô là "Thêm" nhưng nhãn hiển thị là "Danh mục khác"; dễ nhầm với danh mục "Khác". Dùng "More categories / ô ⋯". |
| 12 | All time | Period `all` = "Tất cả" / "All time"; Search chip = "Tất cả thời gian" / "All time" | SPEC AC-10, AC-49 | ⚠ EN cùng chữ "All time" cho hai thứ khác nhau; VI khác chữ. Thiết kế nên phân biệt. |
| 13 | Privacy screen | Code `secureWindow`; UI "Che nội dung khi chuyển app" | SPEC F-22 "Che nội dung ở màn đa nhiệm" | ⚠ ba tên; dùng "Privacy screen" trong tài liệu tiếng Anh, chữ UI giữ như `.arb`. |
| 14 | Widget cập nhật định kỳ | ui-spec, TESTING, test: `updatePeriodMillis=1800000` (30 phút) | DECISIONS D-016 ghi `updatePeriodMillis="0"` | ⚠ DECISIONS cũ; phiên điều phối thêm dòng cập nhật vào D-016 (đã nêu ở `notes/2026-11-05-gop-tai-lieu.md`). |
| 15 | Widget cỡ | 2×2 | SPEC AC-63 2×2 (đổi từ 2×1) | ✔ |
| 16 | ui-spec so với giao diện mới | ui-spec mô tả bố cục/màu theo code **trước** khi gộp PLAN-001 | ui-spec tự ghi "chưa rà lại theo giao diện mới" | ⚠ khi lệch thì `design/current/screens/` + code đúng; `product.md` v2 đã mô tả theo code hiện tại. |
| 17 | Tính năng trên iOS | `platform_features.dart` ẩn F-22, F-24, F-26 trên iOS; F-23 chỉ Android | SPEC mục 5 "iOS", D-019 | ✔ khớp; bản iOS tương đương là Future (product §9.2 chỉ là đề xuất). |
