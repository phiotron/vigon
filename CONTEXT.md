# A002-vigon · Ví Gọn — CONTEXT (glossary)

> Chỉ là bảng thuật ngữ nghiệp vụ, không ghi chi tiết cài đặt. Term (code) = tên dùng trong code/tài liệu kỹ thuật
> (tiếng Anh); VI = chữ hiển thị/tài liệu tiếng Việt; "EN UI" = chữ hiển thị tiếng Anh khi khác Term.
> Nguồn: `docs/SPEC.md` (F-01..F-26), `docs/DECISIONS.md` (D-001..D-019), `lib/src/**`, `lib/l10n/*.arb`,
> `design/current/ui-spec.md` — bản sau khi gộp v1.2 + PLAN-001 (2026-11-05). 🤖 = chỉ Android (ẩn trên iOS, D-019).
> ⚠ = code, SPEC hoặc thiết kế đang lệch nhau — xem mục "Chỗ lệch" ở cuối.
> **2.0** = thuật ngữ của SPEC 3d (F-27..F-42, D-030..D-035), thêm 2026-11-06 và thu hẹp cùng ngày (chỉ nhập khoản chi từ email MB qua hàng đợi; không đọc thông báo, không quét/ảnh hoá đơn), **SPEC 3d chưa duyệt**: chưa có trong code; chữ UI (VI) là đề xuất, chốt khi viết `.arb`.
> **D-046..D-049** (2026-11-11): Allow negative balance / Top-up sheet / Skipped occurrence (có thu mới có chi); Default account theo lọc; ô số tiền theo Tiền tệ chính; Debt movement + lãi suất — SPEC 3h (F-49..F-52), **chưa có trong code**.
> **D-042..D-044** (2026-11-10): Tiền tệ chính đứng trước + Exact sum; Savings wallet / Withdrawal / Goal completed; Deadline reminder — SPEC 3g.
> **D-037** (2026-11-09): đa tiền tệ — thay hàng **Currency** cũ bằng bộ thuật ngữ Currency / Primary currency / Original amount / Derived amount / Exchange rate; SPEC mục 3e (F-43, AC-127..AC-135), đã có trong code.

## Ghi chép và phân loại

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Entry** ⚠ | Khoản (khoản ghi) — EN UI: *Record* | Một lần ghi tiền: loại, số tiền > 0, ngày, **Entry time** (2.0, có thể trống), tài khoản, ghi chú ≤ 200 ký tự; Expense/Income có Category. 2.0: có **Import source** (ghi tay hoặc Email MB) và, nếu đến từ email, một **Reference number**. Mục trong Import queue **chưa phải** Entry. Đơn vị dữ liệu chính. | "transaction", "giao dịch" (giao dịch = DB transaction) |
| **Entry time** (2.0) | Giờ | Giờ `HH:mm` của khoản theo giờ máy; khoản mới mặc định lúc mở màn nhập. Khoản có từ trước 2.0 và khoản sinh từ định kỳ không có giờ; khi Match được coi là 12:00. | "timestamp", "thời gian tạo" (`createdAt` là lúc ghi vào máy, khác giờ của khoản) |
| **Entry type** | Loại khoản | `expense` · `income` · `transfer`. Không đổi được loại của khoản đã lưu. | |
| **Expense** ⚠ | Chi (khoản chi) — EN UI: *Expenses* | Entry làm giảm tiền, có danh mục chi. Ghi qua nút "−", icon danh mục quanh vòng, ô "Danh mục khác", nút Chi của Widget hoặc chạm Reminder. | "spending" trong nhãn |
| **Income** | Thu (khoản thu) | Entry làm tăng tiền, có danh mục thu. Ghi qua nút "+" hoặc nút Thu của Widget. | "revenue" |
| **Transfer** | Chuyển tiền | Entry loại `transfer` từ Account nguồn sang Account đích. **Không** phải thu/chi: không vào biểu đồ, tổng thu/chi, Period balance, Budget, Category budget; chỉ đổi Account balance. | "chuyển khoản" (dễ nhầm chuyển khoản ngân hàng / chuyển khoản sang danh mục khác) |
| **Amount** | Số tiền (dẫn xuất) | Số nguyên theo Minor unit của **Primary currency**, tối đa 10¹² đơn vị nhỏ nhất; là số dùng để cộng tổng và hiện ở tổng/biểu đồ. Với bản ghi khác tiền tệ, đây là số quy từ **Original amount** tại **Exchange rate** hiện tại (D-037). Người dùng gõ phải > 0; có thể 0 khi quy đổi một số rất nhỏ. | số thực, "giá" |
| **Original amount** | Số tiền gốc | Số người dùng nhập, lưu `int` theo Minor unit của **Currency** của bản ghi; **không đổi** khi đổi Primary currency hay tỷ giá. Hiện **nhỏ ở dưới** số theo Primary currency khi khác tiền tệ (D-042). Cột `original*` trong cơ sở dữ liệu; Transfer có thêm số nhận gốc và tiền tệ nhận. | "số quy đổi", "số hiển thị" |
| **Derived amount** | Số dẫn xuất | Số quy từ Original amount về Primary currency tại tỷ giá hiện tại; dùng để cộng tổng, biểu đồ, thanh ngân sách (các cột `amount` / `budget` / `targetAmount` / `initialBalance`). Là số **to ở trên** mọi nơi (D-042); tổng không cộng các số này mà cộng Original amount theo từng Currency rồi quy đổi một lần (**Exact sum**). | "số gốc" |
| **Exact sum** | Cộng chính xác | Cách cộng mọi tổng (D-042): gom Original amount theo từng Currency tới Minor unit, quy đổi bằng tỷ giá phân số, làm tròn **một lần**. Số theo tiền gốc (vd số dư ₫ của Account ₫) luôn tính thẳng từ Original amount, không quy ngược từ số dẫn xuất. | "quy ngược", "fromPrimary" |
| **Exact amount** | Số tiền chính xác | Số giữ 6 chữ số lẻ trên đơn vị chính (micro, 10⁻⁶), ẩn; di sản của cách quy đổi toàn bộ cũ (D-029), bị xoá khi số dẫn xuất được tính lại từ số gốc khác tiền tệ. Không có (null) = đúng bằng Amount. | "số gốc", "số thật" |
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
| **Account** | Tài khoản | Nơi giữ tiền (Tiền mặt, Thẻ, Ví điện tử…): tên, Starting balance, trạng thái hiện/ẩn. Mỗi Entry thuộc một Account. 2.0: Account có thể **liên kết** với một tài khoản trích nợ MB (theo 4 số cuối) — do app tự tạo hoặc người dùng gắn vào Account có sẵn; liên kết theo (MB, 4 số cuối), không theo tên. Chỉ giữ 4 số cuối. | "ví" trong chữ (chỉ là icon), "wallet", "số tài khoản" (app không lưu số đầy đủ) |
| **Auto-created account** (2.0) | Tài khoản tự tạo | Account "MB Bank …1234" app tạo khi gặp email thành công đầu tiên của một Debit account chưa liên kết; Starting balance 0; người dùng có thể "Gắn vào tài khoản có sẵn" thay cho nó. Sau đó là Account bình thường. | "tài khoản ngân hàng liên kết", "kết nối ngân hàng" (app không kết nối ngân hàng) |
| **Total balance** (2.0) | Tổng số dư | Tổng Account balance của **mọi** Account, kể cả Hidden account; ô trên màn Overview. Khác Period balance (thu − chi của kỳ). Không gồm mục Import queue, không cộng/trừ khoản nợ (nợ hiện ở thẻ **Nợ** riêng của Overview: "Người khác nợ bạn X · Bạn nợ Y"). | "số dư" trơn, "tài sản ròng" |
| **Default account** | Tài khoản mặc định | Tài khoản điền sẵn khi ghi khoản mới hoặc ô "Từ" của Chuyển tiền: tài khoản đang chọn ở **Account filter** nếu có (D-047); "Tất cả tài khoản" → tài khoản **hiện** đầu tiên theo thứ tự (lúc cài là "Tiền mặt"). Không có cài đặt riêng. | "tài khoản dùng gần nhất" |
| **Allow negative balance** | Cho phép số dư âm | Công tắc của Account (mặc định tắt) cho phép tiền ra làm Account balance < 0 — dùng cho thẻ tín dụng, thấu chi. Tắt thì mọi **Outflow** làm số dư âm bị chặn ("có thu mới có chi", D-046); Starting balance chỉ âm được khi bật. Tài khoản đang âm lúc nâng cấp được tự bật. | "hạn mức tín dụng", "thấu chi" làm tên công tắc |
| **Outflow** | Tiền ra | Mọi thao tác làm giảm Account balance của một Account: Expense, Transfer đi, Contribution (từ tài khoản nguồn), Withdrawal (từ ví), cho vay, trả nợ (gốc và lãi); cả khi sửa tăng số tiền hoặc xoá một khoản tiền vào. Là thứ bị kiểm khi Allow negative balance tắt. | "chi" (Outflow gồm cả thứ không phải Expense) |
| **Negative balance badge** | Nhãn "Âm" | Icon + chữ "Âm" cạnh Account balance < 0 ở màn Tài khoản. | chỉ dùng màu đỏ |
| **Top-up sheet** | Bù tiền (bảng bù tiền) | Bảng hiện khi xác nhận một mục Import queue mà Account liên kết thiếu tiền: "MB …1234 thiếu X" + ba cách: ghi khoản thu vào tài khoản đó · chuyển tiền vào · sửa Starting balance. Bù đủ thì mục tự được xác nhận. | "nạp tiền" (app không nạp tiền thật) |
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
| **Near budget** (2.0) | Sắp vượt | Đã chi ≥ **Near-budget threshold** × hạn mức và chưa vượt: icon + "Đã dùng 82%", màu cảnh báo khác màu Vượt. Áp cho Budget và Category budget. | "gần hết" trong nhãn, "cảnh báo đỏ" |
| **Near-budget threshold** (2.0) | Ngưỡng sắp vượt | Phần trăm hạn mức bắt đầu "Sắp vượt": mặc định 80%, chỉnh 50–95% bước 5%. | |
| **Budget alert** (2.0) | Thông báo ngân sách | Thông báo cục bộ (công tắc, mặc định tắt) khi đã chi tháng hiện tại vượt qua mốc ngưỡng hoặc 100%; mỗi mốc mỗi ngân sách một lần mỗi tháng; **chỉ có phần trăm, không bao giờ có số tiền**. Khác Reminder. | "nhắc nhở", "push" |
| **Remaining budget** (2.0) | Ngân sách còn lại | Hạn mức Budget của tháng − đã chi (mọi tài khoản); âm thì hiện "Vượt X". Ô trên màn Overview. | "số dư ngân sách" |
| **Recurring series** ⚠ | Khoản định kỳ (chuỗi định kỳ) — EN UI: *Repeating records*; code: `RecurringRule` | Quy tắc lặp của một khoản mẫu: loại, số tiền, danh mục, tài khoản, ghi chú, Frequency, ngày bắt đầu, chạy/dừng. Chỉ tạo từ màn Nhập khoản mới (chip Lặp lại). Sửa được số tiền, ghi chú, tần suất, danh mục, tài khoản (F-16). | "subscription", "nhắc nhở" |
| **Frequency** | Chu kỳ lặp (Lặp lại) | Hằng ngày · Hằng tuần · **Repeat days** (Chọn thứ) · Hằng tháng · Hằng năm. Đổi tần suất (hoặc thứ đã chọn) thì chuỗi bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ, không sinh bù. | "period" (đã dùng cho Kỳ) |
| **Repeat days** (F-45) | Chọn thứ (lặp theo thứ) | Recurring series chỉ sinh khoản vào các **thứ trong tuần** người dùng chọn (như báo thức), vd T2 + T3. Chọn đủ 7 thứ chính là Hằng ngày. Ngày của khoản đang ghi không thuộc thứ đã chọn thì khoản đó **không** được ghi; **First occurrence** là thứ đã chọn gần nhất (D-040). | "lặp tùy chỉnh", "lịch tuần", "weekly" trơn (Hằng tuần = cùng một thứ mỗi tuần) |
| **First occurrence** (F-45) | Khoản đầu | Ngày tới hạn đầu tiên của một Recurring series; với Repeat days có thể khác ngày đang nhập. | "ngày bắt đầu" (ngày bắt đầu là mốc tính lịch, có thể không có khoản) |
| **Skipped occurrence** | Lần định kỳ bị bỏ qua | Lần tới hạn của Recurring series không được ghi vì Account thiếu tiền (Allow negative balance tắt, D-046); bỏ hẳn, không sinh bù; màn chính báo một lần. | "khoản chờ", "nợ định kỳ" |
| **Generated entry** | Khoản sinh tự động | Entry do Recurring series tạo khi mở app hoặc quay lại từ nền, bù mọi lần tới hạn tới hết hôm nay, không trùng; sau đó là Entry bình thường. | |
| **Stop / Resume series** | Dừng / Chạy lại | Dừng: không sinh thêm ("Đã dừng"). Chạy lại: tiếp từ **hôm nay**, không sinh bù. | "xóa chuỗi" |
| **Undo** | Hoàn tác | Thanh "Đã xóa · Hoàn tác" 5 giây sau khi xóa một Entry/Transfer. | "khôi phục" (dành cho Restore) |

## Nhập từ email (2.0)

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Import source** | Nguồn (nguồn nhập) | Nơi một khoản đến từ: **Ghi tay** hoặc **Email MB**. Hiện thành biểu tượng/nhãn trên khoản; cột "Nguồn" trong CSV/Excel. | "đồng bộ ngân hàng", "kết nối ngân hàng", "SMS", "thông báo" (app không đọc SMS hay thông báo) |
| **Mailbox** | Hộp thư | Hộp thư Gmail/Yahoo/iCloud người dùng thêm để app đọc email biên lai qua IMAP, chỉ xem, không đánh dấu đã đọc. Cấu hình theo máy, không theo file sao lưu. | "tài khoản email" (dễ nhầm Account) |
| **App password** | Mật khẩu ứng dụng | Mật khẩu riêng nhà cung cấp email cấp cho một app (không phải mật khẩu đăng nhập chính); chỉ lưu trong Keystore/Keychain. Khác Backup password và PIN. | "mật khẩu email", "mật khẩu Gmail" |
| **Supported bank** | Ngân hàng hỗ trợ | Ngân hàng đã có email mẫu thật và test đạt; bản đầu chỉ **MB Bank**. Ngân hàng khác không hiện trong app. | "mọi ngân hàng" |
| **Bank receipt email** | Email biên lai | Email MB (gửi từ `mbebanking@mbbank.com.vn`, chỉ có bản HTML) báo một lần chuyển tiền **đi**: ngày giờ, loại giao dịch, số tham chiếu, tài khoản trích nợ, người thụ hưởng, số tiền, nội dung chuyển tiền, cách thức lệnh, ngày nhập lệnh, thời gian, tình trạng. Không có số dư, không có tiền vào. Chỉ email tình trạng thành công tạo khoản chi. | "giao dịch", "sao kê", "tin nhắn" |
| **Reference number** | Số tham chiếu | Mã của MB trên email biên lai; một số tham chiếu chỉ được nhập **một lần** (kể cả khi đã bỏ qua hay xoá khoản). | "mã giao dịch" (tránh chữ "giao dịch"), "ID" |
| **Debit account** | Tài khoản trích nợ | Tài khoản MB bị trừ tiền ghi trên email; app chỉ giữ 4 số cuối và dùng nó để chọn Account liên kết. | "số tài khoản" (không lưu số đầy đủ) |
| **Payee** | Người thụ hưởng | Người/đơn vị nhận tiền ghi trên email; cùng nội dung chuyển tiền tạo thành ghi chú của khoản ("<người thụ hưởng> · <nội dung>"). | "nơi bán", "merchant" |
| **Import queue** | Hàng đợi (khoản chờ chọn danh mục) | Nơi mọi email thành công **không ghép** được nằm chờ người dùng chọn danh mục, "Chuyển sang tài khoản của tôi" hoặc "Bỏ qua". Mục hàng đợi **chưa là khoản**: không vào tổng, biểu đồ, ngân sách, số dư. Màn chính hiện "N khoản chờ chọn danh mục". | "nháp", "hộp thư đến", "hàng chờ duyệt" |
| **Match** | Ghép | Gắn email vào khoản ghi tay có sẵn thay vì đưa vào hàng đợi: **cùng Account** (liên kết với tài khoản trích nợ), khoản chi hoặc chuyển tiền đi, cùng số tiền, chênh ≤ 2 giờ; mỗi khoản tối đa một email. Khoản giữ nguyên dữ liệu, chỉ thêm nguồn và số tham chiếu. | "gộp", "trùng lặp", "khớp" |
| **Payee suggestion** | Gợi ý (theo người thụ hưởng) | Lựa chọn lần gần nhất cho cùng người thụ hưởng (một danh mục, hoặc chuyển sang tài khoản X) được chọn sẵn cho mục hàng đợi sau; người dùng vẫn phải chạm xác nhận. Đi theo file sao lưu; xem và xoá ở "Gợi ý đã nhớ". | "quy tắc tự động", "AI phân loại" |
| **Move to my account** | Chuyển sang tài khoản của tôi | Lựa chọn trong hàng đợi biến mục thành một **Transfer** từ Account trích nợ sang Account khác của người dùng (vd sang MoMo, sang Account tiết kiệm). Không phải thu/chi. | "chuyển khoản nội bộ" |

## Tiết kiệm, nợ, xem (2.0)

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Savings goal** | Mục tiêu tiết kiệm | Tên, số tiền mục tiêu (Currency riêng, mặc định Primary currency), hạn (tuỳ chọn) và **một Savings wallet** riêng. Tiến độ = Account balance của ví; lần đầu ví ≥ mục tiêu thì thành **Goal completed** (D-043). | "hũ", "sổ tiết kiệm" (không phải sổ ngân hàng), "tài khoản gắn" (chữ cũ) |
| **Savings wallet** | Tài khoản (ví tiết kiệm) | Account **luôn tạo mới** cùng Savings goal: tên người dùng nhập, số dư ban đầu = "Đã có sẵn", Currency của mục tiêu. Là Account bình thường: chi, thu, chuyển ra/vào bất cứ lúc nào. Mục tiêu cũ (trước D-043) có thể dùng Account có sẵn. | "ví" trong code (code là Account), "tài khoản gắn" |
| **Contribution** | Góp tiền | Một **Transfer** từ Account bất kỳ **vào** Savings wallet, qua bảng Góp: không vượt số còn thiếu. Không phải thu/chi; không đổi tổng thu/chi, ngân sách, Total balance. | "nạp", "gửi tiết kiệm", "thu" |
| **Withdrawal** | Rút tiền | Một **Transfer** từ Savings wallet ra Account khác, không vượt số dư ví; làm tiến độ giảm nhưng không bỏ Goal completed. | "huỷ tiết kiệm", "chi" |
| **Savings history** | Lịch sử (của mục tiêu) | Mọi Entry làm đổi số dư Savings wallet (Góp, Rút, chi/thu ghi thẳng) + số dư ban đầu; cộng lại bằng số dư ví. | "lịch sử góp" khi chỉ nói về Contribution |
| **Goal completed** | Đã xong (tiết kiệm thành công) | Trạng thái **vĩnh viễn** từ lần đầu số dư ví ≥ mục tiêu: hộp "Tiết kiệm thành công", mục tiêu xuống nhóm "Đã xong"; chỉ "Mở lại" mới bỏ. Khác "Đã xong" của Debt record (theo số còn lại). | "Đã đạt" (chữ cũ, đổi theo số dư từng lúc) |
| **Debt record** | Khoản nợ | Người, chiều **Cho vay** (người khác nợ bạn) / **Đi vay** (bạn nợ), số tiền gốc, Currency, ngày, hạn, ghi chú, tuỳ chọn **Interest rate**, các **Debt payment** (Lần trả). Từ D-049 thường gắn một **Account**: số tiền vay và mỗi lần trả thành **Debt movement** trên Account. Không gắn Account ("Không qua tài khoản", hoặc khoản nợ có từ trước D-049) = chỉ ghi nhớ. Còn lại = **gốc còn lại + Accrued interest**; cả hai về 0 là "Đã xong". Bản thân Debt record không phải Entry. | "khoản vay" (dễ nhầm Entry), "tài khoản nợ" |
| **Debt movement** | Cho vay · Đi vay · Thu nợ · Trả nợ | Entry sinh từ Debt record trên một Account: Cho vay (tiền ra), Đi vay (tiền vào), Thu nợ (tiền vào), Trả nợ (tiền ra) — phần **gốc**. Đổi Account balance nhưng **không** là thu/chi: không vào tổng thu/chi, biểu đồ, Budget, Statistics (như Transfer). Hiện trong Các khoản có nhãn "Cho vay · An"; chạm mở Chi tiết khoản nợ. | "chi cho vay", "thu nợ" như Income |
| **Orphan debt movement** | Khoản nợ đã xoá | Debt movement còn lại sau khi xoá Debt record của nó (D-049 giữ các khoản trong sổ); vẫn không là thu/chi; xoá từng khoản ở màn sửa khoản. | |
| **Debt payment** | Lần trả | Một lần trả của Debt record: ngày, **Account** (hoặc không, với khoản nợ chỉ ghi nhớ), phần **gốc** (≤ gốc còn lại) và phần **lãi** (≤ Accrued interest tới ngày trả); mặc định lãi trả trước, dư trừ gốc (**Interest-first split**). So bằng Original amount, không qua số dẫn xuất. | "thanh toán" |
| **Interest rate** | Lãi suất | Tuỳ chọn của Debt record: % kèm kỳ **%/tháng** hoặc **%/năm** (tháng × 12 = năm), áp từ **Interest start date**; có thể **đổi giữa chừng** (Rate change, áp từ một ngày). | "phí", "lãi phạt" (không làm) |
| **Interest start date** | Ngày bắt đầu tính lãi | Ngày bắt đầu cộng lãi; mặc định = ngày vay; đặt muộn hơn để có thời gian ân hạn. | |
| **Accrued interest** | Lãi tới hôm nay | Lãi chưa trả tính tới một ngày theo TT 14/2017/TT-NHNN: Σ (gốc còn lại cuối ngày × lãi suất năm ÷ 365) mỗi ngày; lãi đơn, không nhập gốc; làm tròn một lần. | "lãi kép", "lãi dự kiến" (dự kiến tới hạn là số khác) |
| **Interest entry** | Khoản lãi | Phần lãi của một Debt payment, ghi thành **Expense** danh mục "Lãi vay" (đi vay) hoặc **Income** danh mục "Tiền lãi" (cho vay) — **có** tính vào thu/chi, khác phần gốc. | |
| **Overview** (Dashboard) | Tổng quan | **Màn riêng** (màn chính giữ nguyên), có chọn tháng riêng: Total balance, "Thu − chi tháng", Remaining budget, cột thu–chi 6 tháng, "So với tháng trước". | "màn chính", "trang chủ" (màn chính là màn ghi nhanh hiện có) |
| **Statistics** | Thống kê | Màn phân tích theo Period: cột thu/chi theo kỳ con, 5 danh mục chi nhiều nhất, ngày chi nhiều nhất, đường lịch sử Total balance. | "báo cáo" (dành cho PDF) |
| **Spending calendar** | Lịch (lịch chi tiêu) | Lưới tháng, mỗi ngày hiện tổng chi rút gọn và chấm nếu có thu; chạm ngày mở các khoản của ngày đó. | "lịch hẹn", "Custom range" |
| **Advanced filter** | Lọc nâng cao (Lọc) | Lọc Các khoản theo khoảng số tiền, nhiều danh mục, khoảng ngày; kết hợp VÀ với Search và Account filter; chỉ sống trong phiên chạy. | "tìm kiếm" (dành cho Search) |
| **Biometric unlock** | Mở khoá bằng vân tay / Face ID | Cách mở Lock screen bằng sinh trắc của hệ điều hành; chỉ bật được khi đã có PIN; PIN luôn là đường dự phòng. App không thấy dữ liệu sinh trắc. | "đăng nhập bằng vân tay", "khoá sinh trắc" thay PIN |
| **Excel / PDF export** | Xuất Excel / Xuất PDF | File `.xlsx` (khoản, theo danh mục, khoản nợ) và báo cáo PDF của một kỳ, mở bằng bảng chia sẻ. Chỉ xuất. | "sao lưu" (dành cho Backup) |

## Tiền tệ, dữ liệu, sao lưu

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Currency** | Tiền tệ (của bản ghi) | Mã ISO 4217 gắn với Account, Entry, Recurring series, Savings goal, Debt, Debt payment, Budget tháng và Category budget. Mặc định khi tạo = **Primary currency** (D-042; khoản mới có chip đổi tiền tệ); Account vẫn có Currency riêng cho số dư. Đổi Currency của bản ghi không đổi Original amount (D-037). | "tiền tệ chính" (dành cho Primary currency) |
| **Primary currency** | Tiền tệ chính | Mã ISO 4217 người dùng chọn trong Cài đặt; mọi tổng, biểu đồ, ngân sách và dòng `≈` quy về mã này. Đổi Primary currency chỉ đổi cách cộng/hiển thị, **không** sửa số gốc; đổi qua lại không mất dữ liệu (D-037). | "tiền tệ mặc định", "base currency" |
| **Exchange rate** | Tỷ giá | Hệ số quy đổi giữa hai Currency tại một ngày; lấy từ **Rate table**, **Fallback rates** hoặc **Rate override**. Mọi quy đổi dùng tỷ giá hiện tại, **không** lưu tỷ giá lịch sử (D-037). | "tỉ giá" (thống nhất "tỷ giá" trong chữ UI) |
| **Rate table** | Bảng tỷ giá | Bảng tỷ giá công khai tải qua HTTPS (`open.er-api.com`), lưu trong máy kèm ngày; tự kiểm tra khi mở app/quay lại, tải tối đa 1 lần/ngày, có "Cập nhật ngay". | "tỷ giá trực tuyến" |
| **Fallback rates** | Bảng tỷ giá dự phòng | Bảng đóng gói sẵn trong app, dùng khi chưa từng tải được bảng thật; có ghi ngày và nguồn. | "tỷ giá mặc định" |
| **Rate override** | Tỷ giá ghi đè | Tỷ giá người dùng nhập tay cho một cặp trong màn Tỷ giá; xem trước số dư Account đầu tiên dùng Currency đó; áp dụng ngay cho số dẫn xuất. | "tỷ giá thủ công" |
| **Pair in use** | Cặp đang dùng | Cặp Currency ↔ Primary currency đang có ít nhất một bản ghi dùng; màn Tỷ giá chỉ hiện các cặp này. | "mọi cặp tiền tệ" |
| **Missing rate** | Thiếu tỷ giá | Không có tỷ giá cho cặp đang dùng: bản ghi không được cộng vào tổng (khi recompute thì giữ số dẫn xuất cũ) và UI hiện ghi chú, không quy đổi ngầm. | "tỷ giá 0" |
| **Backup** | Bản sao lưu (file `.vigon`) | File chứa đủ tài khoản, danh mục, khoản, chuỗi định kỳ, cài đặt (trừ Device-only settings, PIN). Xuất tay qua bảng chia sẻ của hệ điều hành. | "đồng bộ", "cloud backup" |
| **Encrypted backup** | Bản sao lưu có mật khẩu | Backup được bọc mã hóa bằng **Backup password** (AES-256-GCM, khóa từ PBKDF2). Tùy chọn khi xuất tay (mặc định tắt); Auto backup luôn mã hóa. Không đặt mật khẩu thì file là JSON không mã hóa và app nói rõ. | "khóa file", "file PIN" |
| **Backup password** | Mật khẩu (file sao lưu) | Mật khẩu ≥ 6 ký tự, nhập hai lần, có cảnh báo "Quên mật khẩu thì không mở được file". Xuất tay: không lưu ở đâu; Auto backup: lưu trong bộ nhớ an toàn của máy. Khác **PIN**. | "mã", "PIN" |
| **Restore** | Khôi phục | Chọn file qua trình chọn file hệ thống; kiểm file trước; file mã hóa thì hỏi mật khẩu; hợp lệ thì hỏi xác nhận rồi **thay toàn bộ** dữ liệu trong một lần; hỏng/sai mật khẩu thì báo lỗi, dữ liệu không đổi. | "nhập", "import" (không gộp) |
| **Auto backup** 🤖 | Sao lưu tự động | Ghi Encrypted backup `vigon-auto-…` vào **Backup folder** tối đa một lần mỗi ngày khi app ra nền và dữ liệu đã đổi; giữ 2 file mới nhất; "Sao lưu ngay"; trạng thái lần gần nhất. Không mạng, không đăng nhập (F-24). | "đồng bộ Drive", "sync" |
| **Backup folder** 🤖 | Thư mục (sao lưu) | Thư mục người dùng chọn bằng bộ chọn thư mục của Android (Drive, Dropbox, thẻ nhớ, bộ nhớ máy). Việc tải lên đám mây do app sở hữu thư mục làm. "Chọn lại thư mục" khi quyền bị thu hồi hoặc thư mục mất. | "tài khoản Google Drive" |
| **Auto backup status** 🤖 | Trạng thái sao lưu | "Chưa sao lưu lần nào" / "Lần cuối: …" / "Lần thử …: <lỗi>". | |
| **CSV export** | Xuất CSV | File bảng tính (ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, đến tài khoản, ghi chú), tiêu đề và tên loại theo ngôn ngữ app (vi: `;` và dấu `,` thập phân; en: `,` và `.`), UTF-8 có BOM. Chỉ xuất. | "báo cáo" |
| **Device-only setting** | Cài đặt theo máy | Cài đặt không đi theo file sao lưu: công tắc Widget amounts, công tắc Reminder (về TẮT sau khôi phục), cấu hình Auto backup. Giờ nhắc thì có đi theo file. Dấu "còn phải hiện Onboarding" cũng theo máy. 2.0 thêm: Mailbox + App password, thư đã đọc; Import queue cũng không theo file (số tham chiếu đã gặp thì có). | |
| **Delete all data** | Xóa toàn bộ dữ liệu | Xóa mọi khoản, danh mục, tài khoản, cài đặt, tắt PIN và Auto backup (file đã ghi giữ nguyên); tạo lại mặc định như mới cài. Hai hộp xác nhận. 2.0: xoá thêm mục tiêu, nợ, gợi ý, hàng đợi, số tham chiếu đã gặp, hộp thư + mật khẩu ứng dụng; tắt sinh trắc. | "reset", "đăng xuất" |

## Bảo mật, quyền riêng tư, ngoài app

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **PIN lock** | Khóa bằng mã PIN | Khóa tùy chọn bằng mã 4 số, hỏi khi mở app và khi quay lại sau > 1 phút ở nền; cả khi vào từ Widget hoặc Reminder. Chỉ chặn người cầm máy, **không mã hóa** dữ liệu. | "mật khẩu", "mã hóa" |
| **Lock screen** | Màn khóa | Lớp phủ kín app khi đang khóa: PIN pad, "Quên mã". | |
| **PIN pad** | Bàn phím PIN | Bàn phím 3×4 ở Màn khóa và màn Đặt mã. Khác Keypad. | |
| **Forgot PIN** | Quên mã | Không có máy chủ nên không lấy lại được PIN; lối ra duy nhất là Delete all data (thêm hai bước xác nhận). | "đặt lại mật khẩu" |
| **Privacy screen** 🤖 (code `secureWindow`) ⚠ | Che nội dung khi chuyển app | Công tắc: Android chặn chụp màn hình và hiện thẻ trống trong danh sách app gần đây (F-22). | "chế độ riêng tư", "ẩn app" |
| **Reminder** | Nhắc ghi sổ (nhắc ghi sổ hằng ngày) | Thông báo cục bộ mỗi ngày vào **Reminder time** (mặc định 20:00), nội dung chung chung, **không chứa số liệu**; chạm mở Nhập khoản chi (qua Lock screen nếu bật). Android + iOS (F-25). Tên cũ "nhắc ghi chép" (đổi 2026-11-10). | "push", "nhắc nhở thanh toán", "alert", "nhắc ghi chép" |
| **Deadline reminder** | Nhắc trước hạn | Thông báo cục bộ cho mỗi Savings goal / Debt record có hạn và chưa xong: N ngày trước hạn (mặc định 7, 1–30) và đúng ngày hạn, vào giờ đặt riêng (mặc định 09:00); một cài đặt chung. **Có số tiền còn lại**, kể cả khi bật PIN (D-044). Khác Reminder và Budget alert. | "nhắc nhở thanh toán", "nhắc nợ" |
| **Reminder time** | Giờ nhắc | Giờ của Reminder, chọn bằng bộ chọn giờ hệ thống (chỉ mặt đồng hồ). Android: đúng phút khi người dùng đã bật **Exact timing**, không thì xấp xỉ (D-045). | |
| **Exact timing** | Báo đúng giờ | Quyền "Báo thức và lời nhắc" của Android 12+ (SCHEDULE_EXACT_ALARM) người dùng tự bật để Reminder và Deadline reminder đến đúng phút; không bật vẫn nhắc, có thể trễ vài phút (D-045). | "báo thức" (app không làm đồng hồ báo thức) |
| **Notification permission** | Quyền gửi thông báo | Quyền của hệ điều hành, chỉ xin khi bật Reminder và sau hộp giải thích "Bật nhắc ghi sổ?". | |
| **Widget** 🤖 | Widget (màn hình chính) | Widget Android 2×2 "Ví Gọn" có nút **Chi** / **Thu** mở Nhập khoản; dòng trạng thái tùy Widget amounts (F-26). | "tiện ích" trong chữ (UI giữ "widget") |
| **Widget amounts** 🤖 | Hiện số tiền trên widget | Công tắc (mặc định tắt): khi bật VÀ PIN tắt, widget hiện "Tháng này đã chi X (/ hạn mức)"; PIN bật → "Đã khóa bằng PIN"; qua tháng mà app chưa mở → "Mở app để cập nhật". | |
| **Deep link** | Mở thẳng màn nhập khoản | Đường vào từ Widget hoặc Reminder; app chỉ nhận đúng `/entry/new?type=expense|income`, luôn qua Lock screen. | "liên kết" chung chung |
| **Monochrome icon** 🤖 | Biểu tượng đơn sắc | Lớp `monochrome` của icon thích ứng để Android 13+ tô màu theo hình nền; cùng logo "hai thẻ xếp chồng" (F-23, D-009). | |
| **Onboarding** (F-44) | Màn chào | Chuỗi 5 bước chỉ hiện ở **lần mở đầu sau khi cài mới**: Ngôn ngữ → Chào mừng → Tiền tệ chính → Nhắc ghi sổ → Khoá PIN. Không hiện lại sau khi nâng cấp, Delete all data hay Restore (D-041). | "hướng dẫn", "tour", "đăng ký" (app không có tài khoản) |
| **Skip onboarding** | Bỏ qua | Thoát Onboarding ở bước 2–5 để vào app ngay: lựa chọn đã chạm được giữ, phần còn lại là mặc định (English, USD, Reminder tắt, không PIN lock). | "để sau" (là nút của riêng bước Nhắc/PIN, chỉ bỏ bước đó) |
| **Theme** | Giao diện | Theo hệ thống · Sáng · Tối. | "chủ đề" trong chữ |
| **Language** | Ngôn ngữ | English (mặc định) · Tiếng Việt. Chữ trên nút Widget theo ngôn ngữ **máy**, còn lại theo ngôn ngữ app. | |

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
| 9 | Currency | Nhiều cột `currency` theo bản ghi + `primaryCurrency` trong Settings | SPEC 3e (D-037) | ✔ đã chốt đa tiền tệ; "Primary currency" là thuật ngữ chính thức (không còn cấm). |
| 10 | Nhãn nút Chi (EN) | Nút màn chính dùng `expense` = **"Expenses"**; nút Widget dùng "Expense" | Thiết kế: "Chi"/"Thu" | ⚠ EN lệch số ít/số nhiều giữa app và widget; phiên #2 chốt (vd thêm khóa "Expense"). |
| 11 | More categories | `otherCategories` = "Danh mục khác" / "More categories" | SPEC AC-51: ô **"Thêm"** (dấu ⋯), nhãn "Danh mục khác" | ⚠ SPEC gọi ô là "Thêm" nhưng nhãn hiển thị là "Danh mục khác"; dễ nhầm với danh mục "Khác". Dùng "More categories / ô ⋯". |
| 12 | All time | Period `all` = "Tất cả" / "All time"; Search chip = "Tất cả thời gian" / "All time" | SPEC AC-10, AC-49 | ⚠ EN cùng chữ "All time" cho hai thứ khác nhau; VI khác chữ. Thiết kế nên phân biệt. |
| 13 | Privacy screen | Code `secureWindow`; UI "Che nội dung khi chuyển app" | SPEC F-22 "Che nội dung ở màn đa nhiệm" | ⚠ ba tên; dùng "Privacy screen" trong tài liệu tiếng Anh, chữ UI giữ như `.arb`. |
| 14 | Widget cập nhật định kỳ | ui-spec, TESTING, test: `updatePeriodMillis=1800000` (30 phút) | DECISIONS D-016 ghi `updatePeriodMillis="0"` | ⚠ DECISIONS cũ; phiên điều phối thêm dòng cập nhật vào D-016 (đã nêu ở `notes/2026-11-05-gop-tai-lieu.md`). |
| 15 | Widget cỡ | 2×2 | SPEC AC-63 2×2 (đổi từ 2×1) | ✔ |
| 16 | ui-spec so với giao diện mới | ui-spec mô tả bố cục/màu theo code **trước** khi gộp PLAN-001 | ui-spec tự ghi "chưa rà lại theo giao diện mới" | ⚠ khi lệch thì `design/current/screens/` + code đúng; `product.md` v2 đã mô tả theo code hiện tại. |
| 17 | Tính năng trên iOS | `platform_features.dart` ẩn F-22, F-24, F-26 trên iOS; F-23 chỉ Android | SPEC mục 5 "iOS", D-019 | ✔ khớp; bản iOS tương đương là Future (product §9.2 chỉ là đề xuất). |
| 18 | "Lọc" (2.0) | — (chưa có code) | Hàng Search ghi "lọc" dành cho Account filter; SPEC 3d F-41 đặt nút "Lọc" cho Advanced filter | ⚠ tài liệu: "Lọc tài khoản" (Account filter) và "Lọc nâng cao" (Advanced filter), không dùng "lọc" trơn. |
| 19 | "Khoản nợ" (2.0) | — | Chữ "khoản" vốn là Entry; Debt record không phải Entry (nhưng sinh Debt movement là Entry, D-049) | ⚠ giữ chữ UI "Khoản nợ"; tài liệu kỹ thuật phân biệt "Debt record" (khoản nợ) và "Debt movement" (khoản trong sổ). |
| 20 | Debt record ↔ Account | Code hiện tại: khoản nợ không đụng Account (AC-106) | SPEC 3h F-52 (D-049): khoản nợ mới đi qua Account, có lãi | ⚠ code chưa làm (phiên C1 đợt 5). |
| 21 | Số dư âm | Code hiện tại: không chặn chi vượt | SPEC 3h F-49 (D-046) | ⚠ code chưa làm (phiên C1 đợt 5). |
