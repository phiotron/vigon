# A002-vigon · Ví Gọn — CONTEXT (glossary)

> Chỉ là bảng thuật ngữ nghiệp vụ, không ghi chi tiết cài đặt. Term (code) = tên dùng trong code/tài liệu kỹ thuật
> (tiếng Anh); VI = chữ hiển thị/tài liệu tiếng Việt; EN UI = chữ hiển thị tiếng Anh khi khác Term.
> Nguồn: `docs/SPEC.md`, `lib/src/data/*.dart`, `lib/l10n/*.arb`, `design/current/ui-spec.md` (2026-11-04).
> ⚠ = code và SPEC/thiết kế đang lệch nhau — xem mục "Chỗ lệch" ở cuối.

## Thuật ngữ

| Term (code) | VI | Định nghĩa | Tránh dùng |
|---|---|---|---|
| **Entry** ⚠ | Khoản (khoản ghi) — EN UI: *Record* | Một lần ghi tiền: loại (Expense/Income/Transfer), số tiền > 0, ngày, tài khoản, ghi chú ≤ 200 ký tự; Expense/Income có Category. Đơn vị dữ liệu chính của app. | "transaction", "giao dịch" (giao dịch = DB transaction) |
| **Entry type** | Loại khoản | `expense` · `income` · `transfer`. Không đổi được loại của khoản đã lưu. | |
| **Expense** | Chi (khoản chi) — EN UI: *Expenses* (tổng/phần) | Entry làm giảm tiền, có danh mục chi. Ghi qua nút "−" hoặc icon danh mục quanh vòng. | "spending" trong copy |
| **Income** | Thu (khoản thu) | Entry làm tăng tiền, có danh mục thu. Chỉ ghi qua nút "+". | "revenue", "earning" |
| **Transfer** | Chuyển tiền | Entry loại `transfer` chuyển tiền từ Account nguồn sang Account đích. **Không** phải thu hay chi: không vào biểu đồ, tổng thu/chi, Period balance, Budget; chỉ đổi Account balance. Hiện ở phần "Chuyển tiền" của Các khoản. | "chuyển khoản" (dễ hiểu là chuyển khoản ngân hàng / chuyển các khoản sang danh mục khác) |
| **Amount** | Số tiền | Số nguyên theo **Minor unit** của Currency, luôn > 0 với Entry, tối đa 10¹² đơn vị nhỏ nhất. | số thực, "giá" |
| **Minor unit** | Đơn vị nhỏ nhất | Đơn vị lưu tiền: VND = đồng (0 số lẻ), USD = cent (2 số lẻ). | |
| **Amount expression** | Phép tính | Chuỗi người dùng gõ trên Keypad (vd `120+35`), tính ra Amount khi lưu hoặc bấm "=". | "công thức" |
| **Keypad** | Bàn phím số | Bàn phím riêng của app ở màn Nhập khoản/Chuyển tiền: số, `000` hoặc `.`, ⌫, `÷ × − +`, `=`, nút Lưu/Chọn danh mục. Khác **PIN pad**. | "bàn phím hệ thống" |
| **Category** | Danh mục | Nhóm phân loại Entry, thuộc một loại (`expense`/`income`), có tên, icon (1 trong 31 khóa), màu (1 trong 16), thứ tự. Thứ tự quyết định thứ tự icon quanh vòng và trong lưới chọn. | "tag", "nhóm" |
| **Default category** ⚠ | Danh mục mặc định | Danh mục tạo sẵn lần đầu: chi Food, Transport, Home, Bills, Shopping, Health, Entertainment, Education, Family, Other; thu Salary, Bonus, Other income. Có `nameKey` nên tên đổi theo ngôn ngữ cho tới khi người dùng tự đổi tên. | |
| **Move entries on delete** | Chuyển khoản sang danh mục khác khi xóa | Xóa một Category bắt buộc chọn Category cùng loại để nhận mọi Entry và Recurring series của nó; không bao giờ mất khoản. Không xóa được danh mục cuối cùng của một loại. | "xóa kèm khoản" |
| **Account** ⚠ | Tài khoản — SPEC: "tài khoản (ví)" | Nơi giữ tiền (Tiền mặt, Thẻ, Ví điện tử…), có tên và **Starting balance**. Mỗi Entry thuộc một Account. Bản 1 không xóa/ẩn được tài khoản. | "ví" trong copy (chỉ dùng cho icon), "wallet" |
| **Default account** ⚠ | Tài khoản mặc định | Account được điền sẵn khi ghi khoản mới = tài khoản **đầu tiên theo thứ tự** (lúc cài là "Tiền mặt"). Không có cài đặt chọn tài khoản mặc định. | |
| **Starting balance** | Số dư ban đầu | Số tiền có sẵn trong Account khi bắt đầu dùng app; có thể âm (thẻ tín dụng). | "opening balance" trong copy |
| **Account balance** ⚠ | Số dư tài khoản | Starting balance + thu − chi ± chuyển tiền của Account, tính trên mọi thời gian. Hiện ở màn Tài khoản. | gọi trần là "Số dư" khi có thể nhầm với Period balance |
| **Period balance** ⚠ | Số dư (của kỳ) | Tổng thu − tổng chi **của Period đang xem** (bỏ qua Transfer), theo Account filter. Hiện ở thanh "Số dư" màn chính và đầu màn Các khoản. | "số dư tài khoản", "tiết kiệm" |
| **Account filter** | Lọc tài khoản | Lựa chọn "Tất cả tài khoản" hoặc một Account (chỉ khi có ≥ 2 tài khoản); áp cho màn chính và Các khoản; Transfer được tính nếu Account là nguồn hoặc đích. Chỉ sống trong phiên chạy. | |
| **Period** | Kỳ (kỳ xem) | Khoảng thời gian đang xem: `day` Ngày · `week` Tuần · `month` Tháng · `year` Năm · `all` Tất cả · `custom` Khoảng tùy chọn. Mặc định là tháng chứa hôm nay; chỉ sống trong phiên chạy. | "range" (chỉ dùng cho Custom range), "filter" |
| **Period shift** | Kỳ trước / Kỳ sau | Chuyển sang Period liền trước/sau cùng loại bằng ‹ › hoặc vuốt ngang. "Tất cả" không có kỳ trước/sau. | |
| **Week start** | Ngày đầu tuần | Thứ Hai (mặc định) hoặc Chủ Nhật; quyết định Period loại Tuần. | |
| **Month start day** | Tháng bắt đầu từ ngày | Ngày 1–28 bắt đầu một "tháng" của app; quyết định Period loại Tháng và tháng của Budget. | "ngày lương" |
| **Recurring series** ⚠ | Khoản định kỳ (chuỗi định kỳ) — EN UI: *Repeating records*; code: `RecurringRule` | Quy tắc lặp gắn với một khoản mẫu: loại, số tiền, danh mục, tài khoản, ghi chú, **Frequency**, ngày bắt đầu, trạng thái chạy/dừng. Chỉ tạo từ màn Nhập khoản mới (chip Lặp lại). Chỉ sửa được số tiền và ghi chú. | "subscription", "nhắc nhở" |
| **Frequency** | Chu kỳ lặp | `daily` Hằng ngày · `weekly` Hằng tuần · `monthly` Hằng tháng · `yearly` Hằng năm. Mỗi lần lặp tính từ ngày bắt đầu (ngày 31 vẫn về ngày 31 khi tháng có đủ ngày). | "period" (đã dùng cho Kỳ) |
| **Generated entry** | Khoản sinh tự động | Entry do Recurring series tạo khi mở app hoặc quay lại từ nền, bù mọi lần tới hạn tới hết hôm nay, không trùng. Sau khi sinh là Entry bình thường (sửa/xóa riêng). | |
| **Stop / Resume series** | Dừng / Chạy lại | Dừng: không sinh thêm, khoản đã sinh giữ nguyên ("Đã dừng"). Chạy lại: tiếp từ **hôm nay**, không sinh bù các lần đã lỡ. | "xóa chuỗi" |
| **Budget** | Ngân sách tháng | Một hạn mức chi **tổng** cho tháng hiện tại (theo Month start day), mọi tài khoản, độc lập với Period đang xem. Vượt 100% thì hiện "Vượt X". | "hạn mức danh mục" (không có ở bản 1) |
| **Over budget** | Vượt ngân sách | Đã chi ≥ hạn mức: chữ + icon cảnh báo + màu lỗi, không chỉ dựa vào màu. | "cháy túi" |
| **Undo** | Hoàn tác | Thanh "Đã xóa · Hoàn tác" 5 giây sau khi xóa một Entry/Transfer; bấm thì ghi lại đúng bản cũ. | "khôi phục" (dành cho Restore) |
| **Currency** ⚠ | Tiền tệ | **Một** mã ISO 4217 cho toàn app (31 mã chọn được), mặc định theo vùng máy. Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi tỉ giá; khác số lẻ thì số đã lưu được nhân/chia để con số nhìn thấy giữ nguyên. | "Primary currency"/"tiền tệ chính", "base currency" (app không có nhiều tiền tệ) |
| **Backup** | Bản sao lưu (file `.vigon`) | File JSON có số phiên bản định dạng và mã kiểm tra, chứa đủ tài khoản, danh mục, khoản, chuỗi định kỳ, cài đặt (không có PIN). **Không mã hóa.** Xuất qua bảng chia sẻ của hệ điều hành. | "đồng bộ", "cloud backup" |
| **Restore** | Khôi phục | Chọn file `.vigon` qua trình chọn file hệ thống; kiểm file trước; hợp lệ thì hỏi xác nhận rồi **thay toàn bộ** dữ liệu hiện tại trong một lần; hỏng thì báo lỗi, dữ liệu không đổi. | "nhập", "import" (không gộp dữ liệu) |
| **CSV export** | Xuất CSV | File bảng tính (ngày, loại, số tiền, danh mục, tài khoản, ghi chú), UTF-8 có BOM để Excel đọc tiếng Việt. Chỉ xuất, không nhập lại được. | "báo cáo" |
| **PIN lock** | Khóa bằng mã PIN | Khóa tùy chọn bằng mã 4 số, hỏi khi mở app và khi quay lại sau hơn 1 phút ở nền. Chỉ chặn người cầm máy, **không mã hóa** dữ liệu. | "mật khẩu", "mã hóa" |
| **Lock screen** | Màn khóa | Lớp phủ kín app khi đang khóa, có PIN pad và nút "Quên mã". | |
| **PIN pad** | Bàn phím PIN | Bàn phím 3×4 (1–9, 0, ⌫) ở Màn khóa và màn Đặt mã. Khác **Keypad**. | |
| **Forgot PIN** | Quên mã | Không có máy chủ nên không lấy lại được PIN; lối ra duy nhất là **Delete all data** (thêm hai bước xác nhận). | "đặt lại mật khẩu" |
| **Delete all data** | Xóa toàn bộ dữ liệu | Xóa mọi khoản, danh mục, tài khoản, cài đặt, tắt PIN; app tạo lại danh mục + "Tiền mặt" mặc định như mới cài. Luôn qua hai hộp thoại xác nhận. | "reset", "đăng xuất" |
| **Theme** | Giao diện | Theo hệ thống · Sáng · Tối. | "chủ đề" trong copy |
| **Language** | Ngôn ngữ | Theo máy · Tiếng Việt · English. | |
| **Note** | Ghi chú | Chữ tự do ≤ 200 ký tự của Entry/Transfer/Recurring series; là tiêu đề dòng trong Các khoản (không có thì dùng tên danh mục). | "mô tả" |

## Chỗ lệch giữa code, SPEC và thiết kế (cần chốt)

| # | Thuật ngữ | Code | SPEC / thiết kế | Đề xuất |
|---|---|---|---|---|
| 1 | Entry | Bảng `Entries`, `EntryType`; EN UI gọi **"Record(s)"** (`entries`="Records", `editEntry`="Edit record") | SPEC: "khoản", "khoản ghi" | Giữ `Entry` trong code, "Record" trong chữ EN, "khoản" trong chữ VI — đã ghi ở bảng trên; không đổi tên. |
| 2 | Recurring series | Bảng `RecurringRules` (rule) | SPEC/ui-spec: "chuỗi định kỳ"; EN UI: "Repeating records" | Dùng "Recurring series" trong tài liệu; code giữ `RecurringRule`. |
| 3 | Default category "Education" | `.arb` vi = **"Giáo dục"** | SPEC AC-15: "Giáo dục"; `design/current` (README, design-system-guide): **"Học tập"** | Theo code + SPEC ("Giáo dục"); thiết kế Hi-Fi sửa lại. |
| 4 | Danh mục thu "Khác" | `.arb`: **"Thu khác" / "Other income"** | SPEC AC-15: thu "Khác" | Giữ "Thu khác" (phân biệt với chi "Khác"); SPEC chỉ là ví dụ. |
| 5 | Màu + icon danh mục mặc định | Seed: Ăn uống `#C62828` đỏ/`restaurant`, Nhà cửa `#5D4037`, Sức khỏe `#00695C`/`medical_services`…; bảng 16 màu có `#5D4037 #455A64 #616161` | `design/current`: Ăn uống cat-13 cam, Nhà cửa cat-09…; bảng có `#827717 #6D4C41 #546E7A`; bộ 31 icon khác tên (`health_and_safety`, `medication`, `water_drop`…) và nói "lưu bằng chỉ số 1…31" (code lưu **khóa chữ**) | Phiên #2 chốt một bảng + bảng ánh xạ cũ → mới (màu/icon nằm trong dữ liệu và file sao lưu). |
| 6 | Default account | Tài khoản đầu tiên theo thứ tự; không có cờ "mặc định" | SPEC AC-04: "tài khoản mặc định" | Hiểu "mặc định" = đầu danh sách; nếu muốn chọn được thì là tính năng mới (Future). |
| 7 | Account (ẩn) | Cột `archived` có trong bảng, danh sách lọc bỏ tài khoản đã ẩn, nhưng **không có giao diện** ẩn/xóa | SPEC không nhắc | Xem là chưa có; ghi Future. |
| 8 | "Số dư" / "Balance" | Cùng một chữ cho Period balance (màn chính, Các khoản) và Account balance (màn Tài khoản) | SPEC AC-07/08 dùng "số dư" cho kỳ | Tách nghĩa trong tài liệu (bảng trên); thiết kế làm rõ nhãn. |
| 9 | Currency | Một khóa cài đặt `currency` | SPEC: "MỘT tiền tệ cho toàn app" | Không dùng "Primary currency" (ngụ ý có nhiều tiền tệ). |
| 10 | Chi (EN) | `expense` = **"Expenses"** (số nhiều, dùng cho tổng/phần); nút dùng "Add expense" | Thiết kế muốn chữ "Chi"/"Thu" trên nút −/+ | EN cho nút cần khóa mới ("Expense") hoặc dùng lại "Expenses" — phiên #2 chốt khi sửa `.arb`. |
