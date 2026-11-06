# SPEC — Ví Gọn (A002-vigon)

Đã duyệt: 2026-11-03
<!-- Khi người dùng duyệt, đổi thành: "Đã duyệt: YYYY-MM-DD". Chưa có dòng này thì Claude không viết code. -->

Phiên bản của tài liệu này:
- **1.0** (duyệt 2026-11-03): F-01..F-13, AC-01..AC-43 (mục 3).
- **1.1** (duyệt 2026-11-04): F-14..F-23, AC-44..AC-57 (mục 3b). Trước đây là file riêng `docs/SPEC-1.1.md`.
- **1.2** (duyệt 2026-11-04): F-24..F-26, AC-58..AC-64 (mục 3c). Trước đây là file riêng `docs/SPEC-1.2.md`.
- **iOS + giao diện theo thiết kế** (duyệt 2026-11-04, PLAN-001, D-010, D-011): mục 5.
- **Gộp** (2026-11-05, D-019): hai file bổ sung trên gộp vào đây (đã xóa), số F/AC giữ nguyên; tính năng 1.1/1.2 trên iOS theo mục 5 "iOS".
- **D-022** (người dùng quyết 2026-11-05): F-22, F-24, F-26 có bản iOS ngay bản 1 (thay phần iOS của D-019) → thêm gạch "iOS (D-022)" dưới mỗi F, AC Android giữ nguyên chữ; F-23 vẫn chỉ Android. Mục 5 "iOS" đoạn "Tính năng gốc nền tảng".

## 1. Vấn đề cần giải quyết
Người muốn biết tiền đi đâu mỗi tháng thường bỏ ghi chép vì app quá nhiều bước, đòi tài khoản hoặc gửi dữ liệu lên mạng. Họ đang ghi vào sổ, ghi chú điện thoại hoặc bảng tính, rồi không tổng hợp được. Ví Gọn ghi một khoản chi trong vài giây và cho xem ngay chi tiêu theo danh mục. Chức năng tương đương Monefy, nhưng tên, biểu tượng, icon danh mục và giao diện do mình tự thiết kế.

## 2. Người dùng và tình huống sử dụng trên điện thoại
- Người đi làm, sinh viên, người giữ tiền chợ trong gia đình. Dùng ở Việt Nam và nước khác (tiếng Việt, tiếng Anh).
- Ghi ngay sau khi trả tiền: đứng ở quầy, trên xe, cầm điện thoại MỘT tay, thường không có mạng hoặc mạng yếu.
- Cuối ngày hoặc cuối tháng: ngồi xem biểu đồ, lọc theo kỳ, sửa khoản ghi sai.

## 3. Tính năng bản đầu (MVP) và tiêu chí chấp nhận
Quy ước kiểm chứng (áp dụng cho mọi mục 3, 3b, 3c): **[T]** = test tự động (`flutter test`), **[M]** = thử tay trên máy thật (Android; iPhone theo mục 5 "iOS"), ghi biên bản vào `notes/` và cập nhật bảng truy vết trong `docs/TESTING.md`.

### F-01 · Ghi khoản chi / thu nhanh
- AC-01: Khi bấm nút "−" (chi) hoặc "+" (thu) trên màn chính thì mở màn nhập số tiền với bàn phím số riêng của app trong vòng 300 ms. [M]
- AC-02: Khi nhập số tiền, chọn danh mục thì khoản được lưu và người dùng quay về màn chính; từ lúc mở màn chính tới lúc lưu xong tối đa 3 lần chạm, không tính các lần chạm nhập số. [M]
- AC-03: Bàn phím số có các phép + − × ÷ và "="; khi nhập "120+35" rồi lưu thì số tiền lưu là 155. [T]
- AC-04: Có thể đặt ngày khác hôm nay (mặc định hôm nay), tài khoản (mặc định tài khoản mặc định) và ghi chú tối đa 200 ký tự. [T]
- AC-05: Số tiền bằng 0 hoặc âm thì không lưu được và hiện thông báo lỗi bên cạnh ô số. [T]

### F-02 · Màn chính: biểu đồ theo danh mục và số dư
- AC-06: Màn chính hiện biểu đồ tròn chi tiêu theo danh mục của kỳ đang chọn, ở giữa là tổng thu và tổng chi; xung quanh là icon các danh mục, chạm icon nào thì mở màn nhập khoản chi với danh mục đó chọn sẵn. [M]
- AC-07: Tổng chi, tổng thu và số dư của kỳ khớp với tổng các khoản trong kỳ, đúng tới đơn vị tiền nhỏ nhất (VND: đồng; USD: cent). [T]
- AC-08: Chạm vào số dư thì mở danh sách khoản trong kỳ, gom theo danh mục, có tổng và phần trăm từng danh mục; tổng phần trăm bằng 100 (sai số làm tròn ±0,1). [T]
- AC-09: Kỳ không có khoản nào thì hiện trạng thái trống có hướng dẫn "Bấm − để ghi khoản chi đầu tiên", không hiện biểu đồ rỗng. [M]

### F-03 · Chọn kỳ xem
- AC-10: Chọn được kỳ Ngày, Tuần, Tháng, Năm, Tất cả, hoặc Khoảng tùy chọn (ngày bắt đầu, ngày kết thúc). [T]
- AC-11: Vuốt ngang trên màn chính thì chuyển sang kỳ trước hoặc kỳ sau cùng loại; tiêu đề hiện kỳ đang xem (ví dụ "Tháng 11/2026"). [M]
- AC-12: Ngày đầu tuần (Thứ Hai hoặc Chủ Nhật) và ngày bắt đầu tháng (1 tới 28) chỉnh được trong Cài đặt, và kỳ Tuần/Tháng tính theo cài đặt đó. [T]

### F-04 · Sửa, xóa khoản ghi
- AC-13: Chạm một khoản trong danh sách thì mở màn sửa; lưu thì các tổng ở màn chính cập nhật ngay. [T]
- AC-14: Xóa một khoản thì hiện thanh "Đã xóa · Hoàn tác" trong 5 giây; bấm Hoàn tác thì khoản trở lại đúng như cũ. [M]

### F-05 · Danh mục
- AC-15: Lần mở đầu có sẵn danh mục chi (ví dụ: Ăn uống, Đi lại, Nhà cửa, Hóa đơn, Mua sắm, Sức khỏe, Giải trí, Giáo dục, Gia đình, Khác) và thu (Lương, Thưởng, Khác), tên theo ngôn ngữ máy. [T]
- AC-16: Thêm, đổi tên, đổi icon và màu, sắp xếp lại danh mục được. [T]
- AC-17: Xóa danh mục đang có khoản thì phải chọn danh mục khác để chuyển các khoản sang; không có khoản nào bị mất. [T]

### F-06 · Tài khoản (ví) và chuyển tiền
- AC-18: Có sẵn tài khoản "Tiền mặt"; thêm được tài khoản khác (ví dụ "Thẻ", "Ví điện tử") với số dư ban đầu. [T]
- AC-19: Chuyển tiền giữa hai tài khoản tạo một bản ghi chuyển, không tính là thu hay chi, số dư hai tài khoản đổi đúng bằng số tiền chuyển. [T]
- AC-20: Màn chính lọc được theo một tài khoản hoặc tất cả tài khoản. [T]

### F-07 · Tiền tệ và định dạng
- AC-21: Lần mở đầu tự chọn tiền tệ theo vùng của máy (Việt Nam → VND); đổi được trong Cài đặt từ danh sách mã ISO 4217. App dùng MỘT tiền tệ cho toàn bộ dữ liệu. ~~Không quy đổi~~ — viết lại 2026-11-05 theo D-025: đổi sang tiền tệ khác thì **luôn quy đổi mọi số tiền** (khoản thu chi và chuyển tiền, khoản định kỳ, số dư ban đầu tài khoản, hạn mức danh mục, ngân sách tháng) theo tỉ giá "1 tiền cũ = X tiền mới", trong MỘT giao dịch: làm tròn half-up tới đơn vị nhỏ nhất của tiền mới, số phải > 0 thì tối thiểu 1 đơn vị, có số nào vượt 10^12 thì báo lỗi và không đổi gì; lỗi giữa chừng thì không đổi gì. Chọn lại đúng tiền tệ đang dùng thì không làm gì. [T: `test/data/currency_conversion_test.dart`]
- AC-70 (D-025): Chọn tiền tệ khác → hộp "Quy đổi sang X?" hiện "Đang tải tỉ giá…" rồi: tỉ giá hai chiều ("1 VND = 0,0000385 USD", "1 USD = 25.974 VND"), ngày cập nhật và dòng ghi công nguồn "Rates By Exchange Rate API" (chạm mở exchangerate-api.com), ví dụ một số tiền trước → sau (khoản mới nhất, không có thì ngân sách), cảnh báo làm tròn, không hoàn tác tự động, gợi ý xuất sao lưu trước; nút "Hủy" (không đổi gì, kể cả khi đang tải) và "Quy đổi"; "Dùng tỉ giá khác" chuyển sang ô nhập tay. Xong thì báo "Đã quy đổi mọi số tiền sang X"; màn, widget cập nhật theo. [T: `test/features/currency_conversion_flow_test.dart`]
- AC-71 (D-025): Mất mạng, hết giờ chờ, dịch vụ lỗi hoặc nguồn không có tỉ giá cho cặp đó → hộp báo rõ lý do ("Không tải được tỉ giá" / "Không có tỉ giá từ A sang B") và ô "1 A = ? B" để nhập tay (đổi chiều được; điền sẵn tỉ giá gần nhất đã tải hoặc đã nhập, kèm ngày, nếu có); "Thử lại" (khi lỗi mạng/dịch vụ), "Tiếp tục" sang hộp xác nhận, hoặc "Hủy". Tỉ giá ≤ 0 hoặc sai → báo lỗi dưới ô. [T]
- AC-72 (D-025): Mạng chỉ dùng cho việc tải bảng tỉ giá công khai qua HTTPS (`GET https://open.er-api.com/v6/latest/USD`, URL cố định, không gửi dữ liệu người dùng hay tiền tệ đang dùng), chỉ khi người dùng đổi tiền tệ; không SDK, không analytics; nguồn miễn phí, không khóa API, ghi công đúng điều khoản. [T: `test/manifest_test.dart`, `test/data/exchange_rate_source_test.dart`]
- Hộp xác nhận, ô nhập tay đạt S-50 ở chữ 200%, sáng/tối (test trợ năng trong `currency_conversion_flow_test.dart`); gọi mạng thật trên máy thật: [M] CHƯA kiểm.
- AC-22: Số tiền hiển thị theo định dạng của ngôn ngữ đang dùng (vi: `1.250.000 ₫`; en: `$1,250.00`); tiền lưu dạng số nguyên theo đơn vị nhỏ nhất, không dùng số thực. [T]

### F-08 · Khoản định kỳ
- AC-23: Khi ghi khoản, bật "Lặp lại" với chu kỳ hằng ngày, hằng tuần, hằng tháng, hằng năm. [T]
- AC-24: Mở app sau khi tới hạn thì app tự tạo các khoản còn thiếu cho tới hôm nay, không tạo trùng khi mở app nhiều lần; không cần chạy nền. [T]
- AC-25: Dừng hoặc sửa một chuỗi định kỳ thì không đụng tới các khoản đã tạo trước đó. [T]

### F-09 · Ngân sách tháng
- AC-26: Đặt được một hạn mức chi cho mỗi tháng (tổng, không theo danh mục). [T]
- AC-27: Màn chính hiện thanh tiến độ "đã chi / hạn mức"; vượt 100% thì thanh đổi màu cảnh báo và có chữ "Vượt X" (không chỉ dựa vào màu). [M]

### F-10 · Sao lưu và khôi phục bằng file
- AC-28: "Xuất bản sao lưu" tạo một file `.vigon` (JSON có phiên bản định dạng) và mở bảng chia sẻ của hệ điều hành để người dùng tự lưu hoặc gửi; app không xin quyền bộ nhớ. [M]
- AC-29: "Khôi phục" chọn file qua trình chọn file của hệ điều hành; app kiểm tra phiên bản định dạng và tính toàn vẹn, hỏi xác nhận "Dữ liệu hiện tại sẽ bị thay thế", rồi khôi phục đủ khoản, danh mục, tài khoản, cài đặt. File hỏng hoặc sai định dạng thì báo lỗi và không đụng dữ liệu hiện có. [T]
- AC-30: Xuất dữ liệu ra CSV (ngày, loại, số tiền, danh mục, tài khoản, ghi chú) mở được bằng Excel/Google Sheets, chữ tiếng Việt không lỗi phông (UTF-8 có BOM). [T]

### F-11 · Khóa bằng mã PIN
- AC-31: Bật khóa trong Cài đặt bằng mã PIN 4 số (nhập hai lần để xác nhận). [T]
- AC-32: Khi bật, mở app hoặc quay lại app sau hơn 1 phút ở nền thì phải nhập PIN. [M]
- AC-33: PIN không lưu dạng chữ thường: lưu dạng băm có muối trong bộ nhớ an toàn của hệ điều hành (Android Keystore qua thư viện lưu trữ an toàn). [T]
- AC-34: Quên PIN: app không có máy chủ nên không khôi phục được; màn khóa có nút "Quên mã" giải thích rằng chỉ có thể xóa toàn bộ dữ liệu trong app để dùng lại, kèm xác nhận hai bước. [M]

### F-12 · Giao diện, ngôn ngữ, khả năng tiếp cận
- AC-35: Có giao diện sáng, tối và theo hệ thống. [M]
- AC-36: Có tiếng Việt và tiếng Anh, mặc định theo ngôn ngữ máy, đổi được trong Cài đặt; mọi chuỗi giao diện nằm trong file dịch, không viết thẳng trong code. [T]
- AC-37: Mọi nút chạm tối thiểu 48×48 dp; nút "−", "+" và bàn phím số nằm ở nửa dưới màn hình. [M]
- AC-38: Với cỡ chữ hệ thống 200%, các màn chính không bị cắt chữ hoặc chồng lên nhau. [M]
- AC-39: Bật TalkBack thì đọc được tên mọi nút, tên và số tiền từng danh mục trên biểu đồ (biểu đồ có bảng thay thế cho trình đọc màn hình). [M]
- AC-40: Tương phản chữ đạt tối thiểu 4,5:1 (chữ thường) và 3:1 (chữ lớn, icon) ở cả hai giao diện sáng và tối. [M]

### F-13 · Quyền riêng tư và thông tin pháp lý trong app
- AC-41: Màn "Giới thiệu" có: phiên bản, liên kết chính sách quyền riêng tư, kênh báo lỗi bảo mật (email), danh sách giấy phép nguồn mở (màn license của Flutter). [M]
- AC-42: Mục "Xóa toàn bộ dữ liệu" trong Cài đặt xóa hết dữ liệu trong app sau xác nhận hai bước; mở lại app thì như mới cài. [T]
- AC-43: ~~App không có quyền INTERNET trong manifest của bản phát hành~~ (sửa 2026-11-05 theo D-025): manifest bản phát hành chỉ có `INTERNET` (để tải tỉ giá, AC-72) và hai quyền nhắc ghi chép; app không gửi dữ liệu người dùng đi đâu. [T: kiểm manifest nguồn và manifest release đã gộp]

## 3b. Bản 1.1: bổ sung chức năng (F-14..F-23)
Người dùng duyệt làm ngày 2026-11-04. Bổ sung cho mục 3, không thay thế. Ràng buộc giữ nguyên: không mạng (từ D-025 ngày 2026-11-05: trừ việc tải tỉ giá khi đổi tiền tệ), không xin thêm quyền thiết bị (mục 5, D-002), chỉ màn dọc, mọi chữ trong `.arb` (vi và en). Quyết định kỹ thuật: D-012 (mã hóa file sao lưu), D-013 (schema 2, tài khoản ẩn, lịch khi đổi tần suất).

### F-14 · Quản lý tài khoản: ẩn, hiện, xóa
Trước bản 1.1 chỉ thêm và sửa được tài khoản. Cột `archived` đã có sẵn trong bảng `accounts` (và trong file sao lưu).
- AC-44: Trong bảng sửa tài khoản có nút **"Ẩn tài khoản"**. Tài khoản đã ẩn không hiện trong: bảng chọn tài khoản khi ghi khoản, menu lọc ở màn chính, ô "Từ/Đến" của Chuyển tiền. Khoản và chuyển tiền cũ của nó vẫn nằm trong danh sách khoản và vẫn tính vào thu/chi của kỳ. [T]
- AC-45: **"Xóa tài khoản"** chỉ cho phép khi tài khoản chưa có khoản nào (kể cả chuyển tiền) và không có chuỗi định kỳ nào trỏ tới; nếu có thì nút xóa không hiện và giải thích "Tài khoản đã có khoản, chỉ ẩn được". Xóa có hộp thoại xác nhận. [T]
- AC-46: Luôn còn ít nhất một tài khoản hiện: không ẩn, không xóa tài khoản hiện cuối cùng. [T]
- AC-47: Màn Tài khoản có mục "Tài khoản đã ẩn" (thu gọn, mặc định đóng) liệt kê tài khoản đã ẩn kèm số dư; chạm vào để **"Hiện lại"**. [T]
- Sao lưu và khôi phục giữ nguyên trạng thái ẩn. [T]

### F-15 · Tìm kiếm khoản
- AC-48: Màn "Các khoản" có nút tìm kiếm (icon kính lúp) trên thanh tiêu đề; chạm mở ô nhập. Gõ chữ thì lọc các khoản có **ghi chú, tên danh mục hoặc số tiền** chứa chuỗi đó (không phân biệt hoa thường và dấu tiếng Việt; số tiền khớp theo chữ số, bỏ dấu ngăn cách). [T]
- AC-49: Mặc định tìm trong kỳ đang xem; có chip **"Tất cả thời gian"** để tìm trên toàn bộ dữ liệu. Kết quả là danh sách phẳng theo ngày mới nhất trước, kèm dòng tổng số khoản và tổng tiền khớp; chạm một khoản mở sửa như thường lệ; vuốt xóa và Hoàn tác vẫn dùng được. Không có kết quả thì hiện "Không có khoản nào khớp". [T]
- Tuân theo bộ lọc tài khoản đang chọn ở màn chính. [T]

### F-16 · Sửa đầy đủ khoản định kỳ
Trước bản 1.1 chỉ sửa được số tiền và ghi chú.
- AC-50: Hộp thoại sửa chuỗi định kỳ cho đổi thêm **tần suất** (ngày/tuần/tháng/năm), **danh mục**, **tài khoản**. Khoản đã sinh không đổi; các lần sinh sau theo cài đặt mới. Quy tắc lịch (đã chốt): đổi tần suất thì chuỗi **bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ** (`startDate` = ngày tới hạn kế tiếp cũ, `lastGeneratedDate` = ngày liền trước), nên lần sinh đầu theo tần suất mới chính là ngày đó; không sinh bù các ngày trước và không trùng khoản đã có. Hệ quả cần biết: ngày neo đổi theo lịch mới (ví dụ tuần bắt đầu 03/11 đổi sang tháng thì thành ngày 17 hằng tháng) và neo ngày 31 mất khi đổi qua lại. Không đổi tần suất thì giữ nguyên `startDate`, `lastGeneratedDate`. [T]

### F-17 · Mọi danh mục chi đều chạm được từ màn chính
- AC-51: Khi số danh mục chi nhiều hơn số icon xếp vừa quanh biểu đồ, icon thứ cuối thành ô **"Thêm"** (dấu ⋯, nhãn "Danh mục khác") mở lưới chọn danh mục chi đầy đủ; chọn một danh mục thì mở màn Nhập khoản chi với danh mục đó. Khi đủ chỗ thì giữ như cũ. [T]

### F-18 · CSV theo ngôn ngữ
- AC-52: Tiêu đề cột và tên loại khoản (chi/thu/chuyển tiền) trong file CSV theo ngôn ngữ đang dùng của app (vi hoặc en). Tiếng Việt: dùng dấu `;` ngăn cột và dấu `,` thập phân (Excel vùng Việt đọc đúng); tiếng Anh: dấu `,` ngăn cột và `.` thập phân. Vẫn UTF-8 có BOM và vẫn chặn chèn công thức. [T]

### F-19 · Đủ tiền tệ ISO 4217
- AC-53: Danh sách tiền tệ trong Cài đặt có đủ các mã ISO 4217 đang dùng (khoảng 150 mã), có **ô tìm** theo mã hoặc tên; số chữ số thập phân theo đúng ISO (0, 2 hoặc 3 chữ số, ví dụ JPY 0, USD 2, KWD 3). ~~Đổi giữa các tiền tệ có số chữ số khác nhau vẫn giữ đúng con số hiển thị (D-005).~~ Từ D-025: đổi tiền tệ là quy đổi theo tỉ giá (AC-21), làm tròn theo số chữ số của tiền mới. [T]

### F-20 · Ngân sách theo danh mục
- AC-54: Mỗi danh mục chi có thể đặt **hạn mức tháng riêng** (trong bảng sửa danh mục, ô "Ngân sách tháng của danh mục", để trống là không đặt). Ở màn "Các khoản", dòng danh mục có hạn mức hiện thanh tiến độ nhỏ và chữ "Vượt X" (kèm màu và chữ, không chỉ màu) khi chi trong tháng hiện tại vượt hạn mức. Ngân sách tổng hiện có (AC-26) giữ nguyên và độc lập. [T]
- Cần đổi cơ sở dữ liệu: thêm cột hạn mức vào bảng danh mục, tăng `schemaVersion` lên 2 và có migration giữ dữ liệu cũ; file sao lưu mang theo hạn mức, đọc được file sao lưu cũ (không có cột này) và khôi phục đúng. [T]

### F-21 · Mã hóa file sao lưu bằng mật khẩu
- AC-55: Khi **Xuất bản sao lưu** có lựa chọn "Đặt mật khẩu cho file" (tùy chọn, mặc định tắt; nhập mật khẩu hai lần, tối thiểu 6 ký tự; cảnh báo "Quên mật khẩu thì không mở được file này"). Có mật khẩu: file `.vigon` được mã hóa (khóa suy ra từ mật khẩu bằng PBKDF2-HMAC-SHA256 nhiều vòng và muối ngẫu nhiên, mã hóa AES-256-GCM); không mật khẩu: như cũ. Khôi phục: nhận ra file mã hóa, hỏi mật khẩu; sai mật khẩu hoặc file bị sửa thì báo "Sai mật khẩu hoặc file bị hỏng", không đụng dữ liệu hiện có. File sao lưu cũ không mã hóa vẫn khôi phục được. [T]
- Mật khẩu không được lưu ở đâu cả. Không thêm quyền, không dùng mạng. Chạy cả Android và iOS (Dart thuần).

### F-22 · Che nội dung ở màn đa nhiệm (Android và iOS, D-022)
- AC-56: Mục Bảo mật trong Cài đặt có công tắc **"Che nội dung khi chuyển app"**. Bật: Android chặn chụp màn hình và hiện màn trống trong danh sách app gần đây (cờ `FLAG_SECURE` của cửa sổ). Mặc định tắt. Lưu trong bảng `settings`, áp dụng ngay khi mở app lần sau và khi đổi công tắc. [T cho phần lưu và công tắc; M cho hiệu ứng thật trên máy]
- iOS (D-022): cùng công tắc, cùng cách lưu. Bật: khi app rời trạng thái hoạt động (`sceneWillResignActive` / `sceneDidEnterBackground`: mở màn chuyển app, về màn hình chính, kéo Trung tâm điều khiển, có hộp thoại hệ thống) app phủ lớp che (màu nền `surface` sáng/tối + logo) lên nội dung; quay lại (`sceneDidBecomeActive`) thì gỡ. **iPhone không cho app chặn chụp màn hình** → không hứa điều đó; chú thích dưới công tắc trên iOS là `secureWindowNoteIos` ("Ẩn nội dung trong màn chuyển app. iPhone không cho app chặn chụp màn hình."). Mã: `ios/Runner/VigonNative.swift` (kênh `vigon/secure`, cùng giao thức Android). [T cho cấu hình và kênh: `test/hifi_d4_ios_config_test.dart`, `test/features/secure_window_test.dart`; M trên iPhone (TestFlight): ảnh trong màn chuyển app chỉ thấy lớp che, gỡ ngay khi quay lại, sáng/tối đúng màu]

### F-23 · Biểu tượng đơn sắc (chỉ Android)
- AC-57: Icon thích ứng có lớp `<monochrome>` để Android 13 trở lên tô màu theo giao diện hình nền. Hình đơn sắc là cùng logo "hai thẻ xếp chồng" (D-009), một màu. [M]

## 3c. Bản 1.2: sao lưu tự động, nhắc ghi chép, widget (F-24..F-26)
Người dùng yêu cầu làm ngày 2026-11-04 ba mục trước đó để ngoài phạm vi của bản 1.1. Bổ sung cho mục 3 và 3b. Mỗi mục được thiết kế để **không phá lời hứa riêng tư của app**: không SDK bên thứ ba, không quyền INTERNET, nhà phát triển vẫn không nhận dữ liệu nào. Quyết định kỹ thuật: D-014 (F-24), D-015 (F-25), D-016 (F-26); trên iOS: D-019 (F-25), D-022 (F-22, F-24, F-26).

### F-24 · Sao lưu tự động vào thư mục người dùng chọn (Android và iOS, D-022)
Thay cho "đồng bộ Google Drive/Dropbox qua API" (cần mạng, đăng nhập, khóa API; không làm). Dùng **Storage Access Framework** của Android: người dùng chọn một thư mục (trong Google Drive, Dropbox, thẻ nhớ hoặc bộ nhớ máy); các app đó tự tải lên đám mây, Ví Gọn chỉ ghi file vào thư mục đã chọn. Không thêm quyền nào, không mạng, không đăng nhập. iOS: cùng ý, dùng bộ chọn thư mục của app Tệp — gạch "iOS (D-022)" dưới AC-60.
- AC-58: Cài đặt → Dữ liệu có mục **"Sao lưu tự động"**: bật thì hỏi (1) chọn thư mục bằng bộ chọn thư mục của hệ thống, (2) đặt mật khẩu sao lưu (tối thiểu 6 ký tự, nhập hai lần, cảnh báo "Quên mật khẩu thì không mở được các file sao lưu; bạn cần nhớ nó khi khôi phục trên máy khác"). Mật khẩu được lưu trong bộ nhớ an toàn của Android (Keystore, `flutter_secure_storage` đã có) để app mã hóa được khi chạy nền; **không bao giờ** ghi mật khẩu vào file, log, cơ sở dữ liệu hay file sao lưu. File luôn được mã hóa theo F-21 (AES-256-GCM), KHÔNG bao giờ ghi bản rõ ra thư mục. Mặc định tắt. [T]
- AC-59 (sửa theo D-026, 2026-11-06): Khi bật, người dùng chọn **giờ sao lưu** (bộ chọn giờ của hệ thống ngay sau mật khẩu, điền sẵn **21:00**; hàng "Giờ sao lưu" đổi được bất cứ lúc nào; giờ theo múi giờ hiện tại của máy, lưu trong bộ nhớ an toàn cùng cấu hình F-24, không vào bảng `settings`). Android: đến giờ đó app **tự chạy nền kể cả khi đóng** (báo thức không chính xác, hệ thống có thể lùi vài phút; không xin quyền báo thức chính xác; đặt lại lịch sau khởi động lại, cập nhật app, đổi giờ, đổi múi giờ). **Bù khi lỡ:** đã qua giờ chọn mà mốc đó chưa được sao lưu (máy tắt, hệ thống không cho chạy…) thì lần mở app hoặc rời app kế tiếp sẽ sao lưu. App sao lưu tối đa **một lần cho mỗi mốc giờ trong ngày** (lần thử lỗi cũng tính; một lần bù phủ mọi mốc đã lỡ), và chỉ khi dữ liệu đã đổi kể từ lần sao lưu thành công trước. Dòng trạng thái có thêm "Lần tới: hôm nay/ngày mai, 21:00". File tên `vigon-auto-AAAAMMDD-GGPP.vigon`. Giữ tối đa **7 file tự động gần nhất** trong thư mục; xóa file `vigon-auto-*` cũ hơn (không đụng file khác trong thư mục, không đụng file sao lưu tay). [T: `test/data/backup_schedule_test.dart`, `test/data/auto_backup_test.dart`, `test/features/auto_backup_schedule_test.dart`, `test/features/auto_backup_ui_test.dart`; M: chạy nền khi app đóng trên máy thật — TESTING M-2]
- AC-60: Nút **"Sao lưu ngay"** chạy ngay và báo kết quả; hiện thời gian và kết quả lần tự sao lưu gần nhất ("Lần cuối: 3 thg 11, 18:30"; nếu lỗi: "Không ghi được vào thư mục. Chọn lại thư mục"). Quyền ghi bị thu hồi hoặc thư mục bị xóa thì báo lỗi rõ ràng, không crash và không dừng im lặng; có nút "Chọn lại thư mục". Tắt "Sao lưu tự động" thì xóa mật khẩu khỏi Keystore và bỏ quyền thư mục, không xóa các file đã ghi. [T]
- Khôi phục: bộ chọn file hiện có đã mở được file `.vigon` mã hóa (F-21), hỏi mật khẩu như thường lệ. [T]
- Chú thích trong app: "Ví Gọn chỉ ghi file vào thư mục bạn chọn. Việc tải lên Google Drive hay Dropbox do app đó thực hiện." [T]
- iOS (D-022):
  - AC-58 trên iOS: chọn thư mục bằng bộ chọn của app Tệp (`UIDocumentPickerViewController`, loại thư mục; vd iCloud Drive, Google Drive, "Trên iPhone"). App giữ quyền bằng security-scoped bookmark trong UserDefaults của app; Dart chỉ giữ mã `ios-bookmark:<uuid>` trong SecretStore như URI của Android. Mật khẩu trong **Keychain** (Keystore ↔ Keychain), cùng luật "không bao giờ ghi vào file, log, cơ sở dữ liệu"; file luôn mã hóa. Chú thích trong app: `autoBackupNoteIos` ("…thư mục bạn chọn trong app Tệp, ví dụ trong iCloud Drive."). [T]
  - AC-59 trên iOS (sửa theo D-026): iOS không cho app đã đóng tự chạy đúng giờ, nên đúng giờ đã chọn app hiện **thông báo cục bộ** lặp hằng ngày "Đến giờ sao lưu Ví Gọn. Chạm để sao lưu." (`autoBackupNotificationBody`, không số liệu, mã thông báo 1002 khác nhắc ghi chép 1001); chạm vào hoặc mở/quay lại app bất kỳ lúc nào sau giờ đó thì sao lưu chạy (không chạy lúc ra nền vì iOS có thể dừng app giữa chừng). Quyền thông báo xin khi bật hoặc đổi giờ nếu chưa có, sau lời giải thích (`autoBackupNotifyTitleIos`/`autoBackupNotifyBodyIos`, S-40); bị từ chối thì báo nhẹ (`autoBackupNotifyDeniedIos`), sao lưu tự động vẫn bật và vẫn bù khi mở app. Cùng luật mỗi mốc một lần, chỉ khi dữ liệu đổi, tên file và giữ 7 file như Android. Chú thích: `autoBackupRunsOnOpenIos` ("…Đúng giờ bạn chọn, Ví Gọn gửi thông báo; chạm vào hoặc mở app để sao lưu. Lỡ giờ thì sao lưu bù khi bạn mở app…"). [T: `test/data/hifi_d4_auto_backup_ios_test.dart`, `test/features/auto_backup_schedule_test.dart` nhóm "iOS: thông báo hằng ngày", `test/features/auto_backup_ui_test.dart` nhóm "iOS (D-026, S-40)"; M: thông báo thật trên iPhone — TestFlight]
  - Cảnh báo thư mục: thư mục không nằm trên iCloud Drive (`AutoBackupState.folderInICloud != true`) thì hiện `autoBackupLocalFolderWarningIos` ("Thư mục này có thể chỉ nằm trên iPhone…"), vì dữ liệu app không nằm trong sao lưu iPhone (D-021) và iOS không phân biệt được "Trên iPhone" với Google Drive/Dropbox. [T]
  - AC-60 trên iOS: bookmark mất hoặc bị thu hồi, thư mục bị xóa → cùng trạng thái lỗi và nút "Chọn lại thư mục" như Android; tắt thì xóa mật khẩu khỏi Keychain và xóa bookmark (`releaseFolder`), không xóa file đã ghi. [T: cùng file test, "lỗi thư mục iOS (bookmark mất / bị thu hồi)…"]
  - [M] trên iPhone (TestFlight): bộ chọn thư mục mở được; ghi file thật vào iCloud Drive và Google Drive; file iCloud chưa tải về vẫn được đếm/dọn đúng 7 file; bookmark còn hiệu lực sau khi khởi động lại máy; thu hồi quyền/xóa thư mục → báo lỗi, không crash; file ghi trên iPhone khôi phục được trên Android và ngược lại.

### F-25 · Nhắc ghi chép hằng ngày (Android và iOS)
- AC-61: Cài đặt có mục **"Nhắc ghi chép"** (công tắc, mặc định tắt) và **giờ nhắc** (mặc định 20:00, chọn bằng bộ chọn giờ của hệ thống). Bật công tắc thì trước tiên hiện một lời giải thích ngắn ("Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc ghi khoản. Thông báo không chứa số liệu.") rồi mới xin quyền thông báo của hệ điều hành (Android 13 trở lên; iOS: hộp thoại cho phép thông báo của iOS) đúng lúc này; bị từ chối thì công tắc về tắt và hiện hướng dẫn mở cài đặt hệ thống. Không xin quyền ở chỗ nào khác. [T cho logic; M cho thông báo thật]
- AC-62: Thông báo lặp **mỗi ngày** đúng giờ đã chọn, nội dung chung chung ("Hôm nay bạn đã ghi chi tiêu chưa?"), tiêu đề "Ví Gọn", KHÔNG chứa số tiền hay dữ liệu cá nhân; chạm vào mở app (qua màn khóa PIN nếu đang bật) ở màn Nhập khoản chi. Đổi giờ thì đặt lại lịch; tắt công tắc thì hủy lịch. Sau khi khởi động lại điện thoại, lịch được đặt lại. Dùng lịch không chính xác theo phút (không xin quyền báo thức chính xác `SCHEDULE_EXACT_ALARM`). [T cho logic lịch; M cho hiệu ứng thật]
- Quyền thêm vào manifest Android được phép đúng: `POST_NOTIFICATIONS` và `RECEIVE_BOOT_COMPLETED`; không quyền nào khác (kể cả `INTERNET`). Test `manifest_test` (AC-43) cập nhật thành danh sách cho phép đó. [T]
- iOS (D-019): thông báo cục bộ của iOS qua `flutter_local_notifications` (Darwin); lịch lặp hằng ngày do iOS giữ nên không cần tín hiệu khởi động lại; không cần khóa nào trong `Info.plist`. Thông báo thật, chạm thông báo và hộp thoại quyền của iOS: [M] trên iPhone (simulator CI chỉ thay thế tạm, mục 5 "iOS").

### F-26 · Widget màn hình chính (Android và iOS, D-022)
- AC-63: Widget Android "Ví Gọn" (thêm được từ danh sách widget của launcher), cỡ tối thiểu 2×2 (đã đổi từ 2×1 ngày 2026-11-04 vì một hàng cao cắt mất nút khi có dòng trạng thái), có hai nút lớn **"Chi"** và **"Thu"**: chạm mở app ngay màn Nhập khoản chi hoặc thu mới (`/entry/new?type=expense` hoặc `income`); nếu bật khóa PIN thì app vẫn hiện màn khóa trước rồi mới vào. Trình đọc màn hình đọc "Thêm khoản chi" và "Thêm khoản thu". [T cho phần liên kết sâu vào đúng màn; M cho giao diện widget]
- AC-64: Widget **mặc định không hiện số tiền nào**. Công tắc **"Hiện số tiền trên widget"** trong Cài đặt (mặc định tắt, kèm cảnh báo "Ai cầm máy cũng nhìn thấy số này trên màn hình chờ"). Khi bật VÀ không bật khóa PIN: widget hiện thêm dòng "Tháng này đã chi X" (X theo kỳ tháng hiện tại và mọi tài khoản, đúng định dạng tiền như trong app), và "/ hạn mức" nếu đã đặt ngân sách tháng. **Khi khóa PIN đang bật, widget luôn KHÔNG hiện số tiền** dù công tắc bật, mà hiện "Đã khóa bằng PIN"; công tắc hiển thị cảnh báo giải thích điều này. Widget cập nhật khi dữ liệu đổi, khi đổi công tắc, khi bật/tắt PIN, và khi sang ngày mới. Số liệu cho widget chỉ lưu trong bộ nhớ riêng của app (không lộ ra ngoài), chỉ chứa chuỗi đã định dạng khi được phép hiện; khi tắt công tắc hoặc bật PIN thì xóa sạch. [T cho quy tắc hiện/ẩn và nội dung ghi; M cho hiển thị]
- Không thêm quyền nào. Không mạng.
- iOS (D-022):
  - Widget WidgetKit "Ví Gọn" (`widgetPickerName`, extension `VigonWidgetExtension`), iOS 16 trở lên như cả app (D-024; trước đó app nhận iOS 15 nên mục widget hiện mà không có tác dụng). Hai cỡ: nhỏ và vừa; màu theo token `widget-*` giống Android, chữ chép từ `.arb`.
  - AC-63 trên iOS: cỡ vừa có hai nút mở `vigon://open/entry/new?type=expense|income` → cùng route và cùng kênh `vigon/deeplink` như Android (Dart chỉ nhận hai route, màn khóa PIN vẫn hiện trước). Cỡ nhỏ: iOS 17+ hai nút qua App Intent (mở app, route để trong App Group, app lấy trong 60 giây); iOS 16 cỡ nhỏ không có nút riêng, chạm cả widget → màn Nhập khoản chi. VoiceOver đọc "Thêm khoản chi" / "Thêm khoản thu". [T cho cấu hình URL scheme và chữ; M cho mở đúng màn — CI không tự kiểm được vì `simctl openurl` hiện hộp xác nhận]
  - AC-64 trên iOS: chuỗi đã định dạng nằm trong **App Group** `group.com.phiotron.vigon` (UserDefaults dùng chung chỉ giữa app và extension, trên máy) thay cho bộ nhớ riêng của app; luật PIN D-016 giữ nguyên (PIN bật → "Đã khóa bằng PIN", không bao giờ có số); tắt công tắc hoặc bật PIN → lệnh `clear` xóa khóa. Khác Android: số có hạn dùng tới hết kỳ tháng; quá hạn mà app chưa mở thì widget tự xóa số và hiện "Mở app để cập nhật" (`widgetStale`). [T: `test/hifi_d4_ios_config_test.dart` (App Group, "D-016: clear XÓA chuỗi", chữ EN/VI, màu), `test/features/f26_widget_test.dart`]
  - [M] trên iPhone (TestFlight, cần App Group thật do người dùng tạo trên Apple Developer): thêm widget từ thư viện widget; widget đọc đúng số app ghi khi công tắc bật + PIN tắt; bật PIN → hiện khóa, không số; nút mở đúng màn (app đang chạy và app đã tắt, cả khi qua màn PIN); nút widget nhỏ trên iOS 17; VoiceOver; sáng/tối.

## 4. Ngoài phạm vi (cố ý KHÔNG làm)
Đã đưa vào phạm vi (giữ dòng gạch để biết lịch sử):
- ~~Bản iOS~~: vào phạm vi ngày 2026-11-04 theo PLAN-001 (người dùng duyệt), xem mục 5 "iOS" và D-011; chỉ icon đơn sắc (F-23) là riêng Android (D-022).
- ~~Ngân sách theo từng danh mục~~: bản 1.1 (F-20). ~~Nhắc nhở bằng thông báo~~: bản 1.2 (F-25). ~~Widget màn hình chính~~: bản 1.2 (F-26; iOS theo D-022).
- ~~Sao lưu lên Google Drive, Dropbox~~: chỉ làm dạng sao lưu một chiều vào thư mục người dùng chọn (F-24, Android và iOS); đồng bộ qua API vẫn ngoài phạm vi (bảng dưới).
- ~~Bản iOS của widget, sao lưu tự động, che nội dung ở màn đa nhiệm~~ (trước để việc riêng theo D-019): làm ngay bản 1 theo D-022 (2026-11-05) — WidgetKit + App Group, bộ chọn thư mục app Tệp + bookmark, lớp phủ native.

Vẫn ngoài phạm vi:
- Tài khoản người dùng, đăng nhập, máy chủ, đồng bộ đám mây.
- Nhiều tiền tệ cùng lúc (mỗi tài khoản một tiền tệ). (Quy đổi tỉ giá khi ĐỔI tiền tệ của app đã làm theo D-025, AC-21, AC-70..AC-72.)
- Mở khóa bằng vân tay hoặc khuôn mặt.
- Quảng cáo, mua trong app, gói Pro, analytics, báo crash bằng SDK.
- Đọc tin nhắn ngân hàng, quét hóa đơn, AI.

Các mục còn hiệu lực từ bản 1.1, 1.2 và lần gộp (cần người dùng làm hoặc quyết, vì phá cam kết hiện tại của app hoặc cần việc riêng):
| Mục | Vì sao chưa làm |
|-----|-----------------|
| Đồng bộ (kể cả đồng bộ hai chiều giữa nhiều máy) qua Google Drive, Dropbox bằng API | Cần mạng, đăng nhập OAuth và khóa API/ID khách (do người dùng tạo trong Google Cloud, Dropbox App Console); trái D-002; kéo theo quyền INTERNET, khai Data safety khác, chính sách quyền riêng tư viết lại, nhiều mục COMPLIANCE. F-24 chỉ sao lưu một chiều vào thư mục đã chọn |
| Widget hiện số tiền khi đang bật PIN | Làm lộ số liệu ngoài màn khóa, vô hiệu khóa PIN (D-016) |
| Nhiều tiền tệ cùng lúc | Thay đổi lớn mô hình dữ liệu (mỗi tài khoản một tiền tệ). Nguồn tỉ giá đã có từ D-025 |
| Gói Pro hoặc nguồn thu khác | Thanh toán trong app (Play Billing, StoreKit), COMPLIANCE C-01/C-02/T-01, thuế |
## 5. Ràng buộc mobile
- Hệ điều hành: Android; minSdk theo mặc định của phiên bản Flutter được ghim (D-003); targetSdk theo yêu cầu Google Play hiện hành (COMPLIANCE P-06). iOS: xem mục "iOS" ngay dưới.
- Giao diện: theo bộ thiết kế đã duyệt `design/current/screens/` và `design/current/ui-spec.md` (token, chữ Be Vietnam Pro, icon Material Symbols Rounded), giống nhau trên hai nền tảng, chỉ khác ở chỗ hệ điều hành quyết định (D-010).
- Offline: toàn bộ app chạy không cần mạng; ~~không có tính năng nào gọi mạng~~ — từ D-025 (2026-11-05) chỉ một việc dùng mạng: tải bảng tỉ giá khi người dùng đổi tiền tệ (AC-72); không có mạng thì nhập tỉ giá tay (AC-71). Dữ liệu ghi xuống bộ nhớ máy ngay khi bấm Lưu.
- Quyền thiết bị:
  - Android: `INTERNET` (D-025, chỉ tải tỉ giá khi đổi tiền tệ; quyền thường, không hộp thoại) và hai quyền phục vụ nhắc ghi chép F-25 (D-015): `POST_NOTIFICATIONS` (chỉ xin khi người dùng bật công tắc "Nhắc ghi chép", sau lời giải thích; hộp thoại hệ thống chỉ có từ Android 13) và `RECEIVE_BOOT_COMPLETED` (đặt lại lịch nhắc sau khi khởi động lại máy, không hộp thoại). KHÔNG `ACCESS_NETWORK_STATE`, KHÔNG cleartext HTTP, KHÔNG `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, KHÔNG quyền bộ nhớ: sao lưu/khôi phục dùng bảng chia sẻ và trình chọn file của hệ điều hành, sao lưu tự động dùng Storage Access Framework; widget không cần quyền. Kiểm bằng `test/manifest_test.dart` (AC-43) và `aapt2 dump permissions` bản release.
  - iOS: không có khóa `NS…UsageDescription`; chỉ xin quyền thông báo (hộp thoại của iOS) khi người dùng bật nhắc ghi chép, sau lời giải thích (AC-61). Chọn file khôi phục và chọn thư mục sao lưu tự động dùng trình chọn hệ thống (app Tệp), không cần quyền; widget (App Group) và lớp che F-22 cũng không cần quyền.
- Màn hình: chiều rộng nhỏ nhất 360 dp; chỉ màn hình dọc.
- Hiệu năng/pin: không có service hay job chạy nền liên tục. Thông báo nhắc do hệ điều hành đặt lịch (F-25); sao lưu tự động tối đa một lần mỗi ngày, chạy lúc app ra nền trên Android, khi mở/quay lại app trên iOS (F-24). Ngưỡng ở 5b.

### iOS (thêm 2026-11-04 theo PLAN-001; cập nhật khi gộp 2026-11-05 theo D-019, rồi theo D-022 cùng ngày)
- Cùng codebase Flutter, cùng tính năng và AC như Android, **trừ F-23 icon đơn sắc** (chỉ Android) và phần chạy khác nhau của F-22, F-24, F-26 ở dưới. iOS tối thiểu **16.0** (D-024; trước là 15.0), chỉ iPhone, chỉ dọc. Build trên cloud có máy macOS vì máy phát triển là Windows (D-011; `.github/workflows/ios.yml`, `release-ios.yml`); yêu cầu App Store P-01 tới P-05 trong `docs/COMPLIANCE.md`.
- Tương ứng nền tảng khi đọc AC: TalkBack ↔ VoiceOver (AC-39); Android Keystore ↔ Keychain (AC-33); AC-43 trên iOS nghĩa là mã gọi mạng duy nhất là tải tỉ giá (AC-72), chỉ HTTPS theo ATS mặc định (iOS không có quyền INTERNET). Keychain giữ PIN sau khi gỡ app: khi cài lại với dữ liệu mới, app tự xóa PIN cũ (D-017).
- **Tính năng gốc nền tảng (D-022, thay phần iOS của D-019):** F-22, F-24, F-26 có trên cả hai nền tảng, cài khác nhau — F-22: Android `FLAG_SECURE` ↔ iOS lớp phủ khi rời app (không chặn chụp màn hình); F-24: Android SAF, chạy lúc ra nền ↔ iOS bộ chọn thư mục app Tệp + bookmark, chạy khi mở/quay lại app; F-26: Android AppWidget ↔ iOS WidgetKit + App Group. AC và cách kiểm iOS ở gạch "iOS (D-022)" dưới từng F. Kênh native dùng chung giao thức (`vigon/secure`, `vigon/widget`, `vigon/deeplink`, `vigon/backup_folder`; iOS: `ios/Runner/VigonNative.swift`) nên Dart không phân nhánh. Cờ nền tảng: `lib/src/platform_features.dart`; test `test/features/merge_ios_gating_test.dart` (iOS có đủ ba mục). **F-23 icon đơn sắc chỉ Android**: AC-57 không áp dụng iOS.
- **F-25 nhắc ghi chép chạy cả iOS** (thông báo cục bộ, xin quyền khi bật công tắc). F-21 mã hóa file sao lưu tay cũng chạy cả iOS.
- Kiểm chứng: AC ghi [M] áp dụng cho iOS phải thử trên iPhone thật (TestFlight) trước khi phát hành iOS. Khi chưa có iPhone, chỉ có iOS Simulator của GitHub Actions: biên bản ghi rõ phần nào mới thử trên simulator. Widget iOS cần App Group `group.com.phiotron.vigon` do người dùng tạo trên Apple Developer (từng bước ở `notes/2026-11-05-d4-ios-features-widget.md`); chưa có thì simulator CI chỉ xác nhận extension được nạp và vẽ được.

## 5b. Yêu cầu phi chức năng
Ngưỡng dưới đây là đề xuất của Claude, người dùng chỉnh khi duyệt. Máy đo chuẩn: Galaxy A13 (SM-A135F, Android 14), chốt ở G1.
- Hiệu năng: mở nguội tới màn chính ≤ 2 giây (trung vị 5 lần, bản release); lưu một khoản ≤ 200 ms; cuộn danh sách 5.000 khoản không có khung hình nào trên 32 ms trong Flutter DevTools (bản profile).
- Pin và bộ nhớ: không có service hay job nền chạy liên tục (thông báo nhắc do hệ điều hành đặt lịch); dùng liên tục 15 phút tiêu hao ≤ 3% pin; bộ nhớ ≤ 200 MB với 10.000 khoản.
- Dung lượng: file APK cho một kiến trúc (arm64) ≤ 25 MB.
- Khả năng truy cập: mục tiêu WCAG 2.2 AA (AC-37 tới AC-40).
- Ổn định: tỉ lệ người dùng không crash ≥ 99,5% theo Android vitals của Play Console (iOS: App Store Connect, Xcode Organizer), xem mỗi tuần trong tháng đầu sau phát hành.
- Toàn vẹn dữ liệu: tắt app đột ngột ngay sau khi bấm Lưu thì khoản vẫn còn khi mở lại (ghi trong giao dịch cơ sở dữ liệu).

## 5c. Thị trường và tiêu chuẩn bán app
Đã điền mục 1 của `docs/COMPLIANCE.md`: Việt Nam và toàn cầu (nhóm A và B, chưa mở nhóm C), miễn phí, không tài khoản, không SDK, dữ liệu chỉ nằm trên máy. Các mục cần xây tính năng đã thành F-11, F-12 (accessibility, ngôn ngữ), F-13 (chính sách, xóa dữ liệu, kênh báo lỗ hổng, giấy phép nguồn mở).

## 6. Dữ liệu
- Lưu ở đâu: cơ sở dữ liệu SQLite trong bộ nhớ riêng của app trên máy. Không có máy chủ, không đồng bộ. Sao lưu: người dùng tự xuất file (F-10), hoặc bật sao lưu tự động vào thư mục mình chọn (F-24, Android và iOS). Cấu hình sao lưu tự động (thư mục, mật khẩu, kết quả lần chạy) nằm trong bộ nhớ an toàn (Keystore trên Android, Keychain trên iOS; bookmark thư mục iOS trong UserDefaults của app), không trong bảng `settings`, nên không đi theo file sao lưu (D-014).
- Dữ liệu nhạy cảm: thói quen chi tiêu và thu nhập (tài chính cá nhân). Bảo vệ bằng bộ nhớ riêng của app, khóa PIN tùy chọn, và:
  - Android tắt sao lưu hệ thống (`allowBackup=false`) để dữ liệu không tự lên đám mây mà người dùng không biết. iOS: cơ sở dữ liệu được loại khỏi sao lưu iCloud/máy tính (`isExcludedFromBackup`, D-021; chính sách quyền riêng tư mục 2).
  - File sao lưu tay `.vigon` (F-10) **có thể mã hóa** bằng mật khẩu (F-21, AES-256-GCM, khóa từ PBKDF2, D-012); không đặt mật khẩu thì là JSON không mã hóa và app nói rõ điều đó. File sao lưu tự động (F-24) **luôn mã hóa**; mật khẩu nằm trong Keystore (Android) / Keychain (iOS), không bao giờ vào file, log hay cơ sở dữ liệu.
  - Thông báo nhắc (F-25) không chứa số liệu. Widget (F-26) mặc định không hiện số; chỉ hiện khi người dùng bật VÀ PIN tắt, chuỗi số nằm trong bộ nhớ riêng của app (iOS: App Group chỉ dùng chung với extension widget, trên máy).
  - Che nội dung (F-22) tùy chọn: Android chặn chụp màn hình + ẩn ảnh màn gần đây; iOS chỉ che ảnh ở màn chuyển app.
- Thu thập dữ liệu: nhà phát triển KHÔNG thu thập gì (kể cả bản 1.2: thông báo cục bộ, thư mục sao lưu do người dùng chọn, widget không gửi gì đi). Data safety khai "không thu thập, không chia sẻ"; App Store khai "Data Not Collected". Vẫn cần chính sách quyền riêng tư công khai (Play và App Store yêu cầu, và để giải thích dữ liệu nằm trên máy).

## 7. Rủi ro và điều chưa biết
- Pháp lý: chức năng giống Monefy là được, nhưng tên, icon, giao diện, mô tả store không được sao chép; rà lại trước khi phát hành.
- Mất dữ liệu: không có đám mây nên mất máy là mất dữ liệu nếu người dùng chưa xuất file. Giảm rủi ro: xuất sao lưu tay trong Cài đặt; bật sao lưu tự động (F-24) vào thư mục của Google Drive/Dropbox (Android) hoặc iCloud Drive/Google Drive (iOS). Dữ liệu app không nằm trong sao lưu hệ thống trên cả hai nền tảng (D-021), nên nếu thư mục sao lưu tự động chỉ nằm trên máy thì mất máy là mất cả file; iOS cảnh báo khi thư mục không ở iCloud Drive. Trên iOS sao lưu tự động chỉ chạy khi mở app → người ít mở app có bản sao lưu cũ hơn.
- Quên PIN là mất quyền vào dữ liệu (AC-34); phải nói rõ khi bật khóa. Quên mật khẩu file sao lưu là không mở được file (F-21, F-24).
- Máy phát triển là Windows: không build hay thử iOS cục bộ, mọi lỗi riêng iOS chỉ lộ trên CI hoặc TestFlight (D-011). Chưa có iPhone thật.
- Tài khoản Google Play cá nhân mới cần closed test 12 người trong 14 ngày (COMPLIANCE P-09).
- Tuổi người dùng: người dưới 18 có thể dùng; app không thu dữ liệu và không có tương tác xã hội. Cần người dùng quyết có tích hợp Play Age Signals / Declared Age Range hay không (COMPLIANCE D-12).
- Bán ở EU: CRA áp dụng cho app kể cả miễn phí nếu là hoạt động thương mại; chưa rõ app miễn phí của cá nhân có thuộc phạm vi không, cần luật sư xác nhận trước khi mở bán ở EU.

## 8. Tiêu chí hoàn thành bản 1 (Android + iOS)
- F-01 tới F-26 đạt toàn bộ AC áp dụng cho từng nền tảng (mục 5 "iOS": F-23 chỉ Android; F-22, F-24, F-26 trên iOS theo gạch "iOS (D-022)" của từng F).
- Android: biên bản [M] trên ít nhất một máy Android thật. iOS: biên bản [M] trên iPhone thật (TestFlight) cho các AC áp dụng iOS trước khi phát hành iOS; CI iOS (`ios.yml`) xanh trên nhánh `main`.
- `flutter analyze` không lỗi, `flutter test` đạt.
- `docs/COMPLIANCE.md` không còn dòng "chưa" ở các mục áp dụng cho Android, iOS (P-01 tới P-05) và các thị trường mở bán.
- Đã chạy closed test theo P-09 và sửa lỗi chặn trước khi mở bán trên Play.
