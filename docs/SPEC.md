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
- **2.0 — chưa duyệt**: F-27..F-44, AC-74..AC-141 (mục 3d), D-030..D-035; sửa §4, §5, §5b, §6, §7, §8 (các chỗ ghi "2.0"). Viết 2026-11-06 theo kế hoạch đã duyệt `notes/2026-11-06-ke-hoach-mo-rong.md`.
<!-- Dòng duyệt bản 2.0: khi người dùng duyệt, đổi dòng trên thành "**2.0** (duyệt YYYY-MM-DD): …" (sau khi đã trả lời mục "Câu hỏi mở" cuối 3d). Chưa đổi thì Claude không viết code cho F-27..F-44 (riêng phiên M0 schema cũng chờ dòng này). -->
Đã duyệt 2.0: <!-- TRỐNG — chờ người dùng ghi ngày -->

## 1. Vấn đề cần giải quyết
Người muốn biết tiền đi đâu mỗi tháng thường bỏ ghi chép vì app quá nhiều bước, đòi tài khoản hoặc gửi dữ liệu lên mạng. Họ đang ghi vào sổ, ghi chú điện thoại hoặc bảng tính, rồi không tổng hợp được. Ví Gọn ghi một khoản chi trong vài giây và cho xem ngay chi tiêu theo danh mục. Chức năng tương đương Monefy, nhưng tên, biểu tượng, icon danh mục và giao diện do mình tự thiết kế.

## 2. Người dùng và tình huống sử dụng trên điện thoại
- Người đi làm, sinh viên, người giữ tiền chợ trong gia đình. Dùng ở Việt Nam và nước khác (tiếng Việt, tiếng Anh).
- Ghi ngay sau khi trả tiền: đứng ở quầy, trên xe, cầm điện thoại MỘT tay, thường không có mạng hoặc mạng yếu.
- Cuối ngày hoặc cuối tháng: ngồi xem biểu đồ, lọc theo kỳ, sửa khoản ghi sai.

## 3. Tính năng bản đầu (MVP) và tiêu chí chấp nhận
Quy ước kiểm chứng (áp dụng cho mọi mục 3, 3b, 3c, 3d): **[T]** = test tự động (`flutter test`), **[M]** = thử tay trên máy thật (Android; iPhone theo mục 5 "iOS"), ghi biên bản vào `notes/` và cập nhật bảng truy vết trong `docs/TESTING.md`.

### F-01 · Ghi khoản chi / thu nhanh
- AC-01: Khi bấm nút "−" (chi) hoặc "+" (thu) trên màn chính thì mở màn nhập số tiền với bàn phím số riêng của app trong vòng 300 ms. [M]
- AC-02: Khi nhập số tiền, chọn danh mục thì khoản được lưu và người dùng quay về màn chính; từ lúc mở màn chính tới lúc lưu xong tối đa 3 lần chạm, không tính các lần chạm nhập số. [M]
- AC-03: Bàn phím số có các phép + − × ÷ và "="; khi nhập "120+35" rồi lưu thì số tiền lưu là 155. [T]
- AC-04: Có thể đặt ngày khác hôm nay (mặc định hôm nay), tài khoản (mặc định tài khoản mặc định) và ghi chú tối đa 200 ký tự. [T]
- AC-05: Số tiền bằng 0 hoặc âm thì không lưu được và hiện thông báo lỗi bên cạnh ô số. Ngoại lệ (D-029): khoản/chuỗi đang 0 do quy đổi tiền tệ, mở ra giữ nguyên số tiền thì vẫn lưu được. [T]

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
- AC-21: Lần mở đầu tự chọn tiền tệ theo vùng của máy (Việt Nam → VND); đổi được trong Cài đặt từ danh sách mã ISO 4217. App dùng MỘT tiền tệ cho toàn bộ dữ liệu. ~~Không quy đổi~~ — viết lại 2026-11-05 theo D-025: đổi sang tiền tệ khác thì **luôn quy đổi mọi số tiền** (khoản thu chi và chuyển tiền, khoản định kỳ, số dư ban đầu tài khoản, hạn mức danh mục, ngân sách tháng) theo tỉ giá "1 tiền cũ = X tiền mới", trong MỘT giao dịch: ~~làm tròn half-up tới đơn vị nhỏ nhất của tiền mới, số phải > 0 thì tối thiểu 1 đơn vị~~ — viết lại 2026-11-06 theo D-029: quy đổi từ **số chính xác 6 chữ số lẻ** (ẩn) của mỗi số tiền, giữ số chính xác mới, còn số hiện và cộng tổng làm tròn half-up tới đơn vị nhỏ nhất của tiền mới (0,00385 US$ hiện 0,00 US$); khoản và khoản định kỳ có thể thành 0, ngân sách tháng và hạn mức danh mục tối thiểu 1 đơn vị; có số nào vượt 10^12 thì báo lỗi và không đổi gì; lỗi giữa chừng thì không đổi gì. Chọn lại đúng tiền tệ đang dùng thì không làm gì. [T: `test/data/currency_conversion_test.dart`]
- AC-70 (D-025): Chọn tiền tệ khác → hộp "Quy đổi sang X?" hiện "Đang tải tỉ giá…" rồi: tỉ giá hai chiều ("1 VND = 0,0000385 USD", "1 USD = 25.974 VND"), ngày cập nhật và dòng ghi công nguồn "Rates By Exchange Rate API" (chạm mở exchangerate-api.com), ví dụ một số tiền trước → sau (khoản mới nhất, không có thì ngân sách), cảnh báo làm tròn, không hoàn tác tự động, gợi ý xuất sao lưu trước; nút "Hủy" (không đổi gì, kể cả khi đang tải) và "Quy đổi"; "Dùng tỉ giá khác" chuyển sang ô nhập tay. Xong thì báo "Đã quy đổi mọi số tiền sang X"; màn, widget cập nhật theo. [T: `test/features/currency_conversion_flow_test.dart`]
- AC-71 (D-025): Mất mạng, hết giờ chờ, dịch vụ lỗi hoặc nguồn không có tỉ giá cho cặp đó → hộp báo rõ lý do ("Không tải được tỉ giá" / "Không có tỉ giá từ A sang B") và ô "1 A = ? B" để nhập tay (đổi chiều được; điền sẵn tỉ giá gần nhất đã tải hoặc đã nhập, kèm ngày, nếu có); "Thử lại" (khi lỗi mạng/dịch vụ), "Tiếp tục" sang hộp xác nhận, hoặc "Hủy". Tỉ giá ≤ 0 hoặc sai → báo lỗi dưới ô. [T]
- AC-73 (D-029): Đổi A → B → A với **cùng một bảng tỉ giá** (tỉ giá chéo tính bằng phân số, B→A là nghịch đảo đúng của A→B) thì mọi số tiền về đúng số cũ (vd 50.000 ₫ → 1,93 US$ → 50.000 ₫; 100 ₫ → 0,00 US$ → 100 ₫), kể cả chuỗi nhiều tiền tệ quay về tiền gốc. Đổi lại vào ngày khác (tỉ giá khác) thì số khác theo biến động tỉ giá thật. Sửa tay số tiền sau khi đổi thì số gõ là số chính xác mới. [T: `test/data/currency_conversion_test.dart` nhóm "số tiền chính xác 6 lẻ", `test/data/exact_amount_storage_test.dart`]
- AC-72 (D-025; bản 2.0 chưa duyệt sẽ thêm việc mạng thứ hai — IMAP, AC-105, D-031 — và mạng của ML Kit, câu hỏi Q-01): Mạng chỉ dùng cho việc tải bảng tỉ giá công khai qua HTTPS (`GET https://open.er-api.com/v6/latest/USD`, URL cố định, không gửi dữ liệu người dùng hay tiền tệ đang dùng), chỉ khi người dùng đổi tiền tệ; không SDK, không analytics; nguồn miễn phí, không khóa API, ghi công đúng điều khoản. [T: `test/manifest_test.dart`, `test/data/exchange_rate_source_test.dart`]
- Hộp xác nhận, ô nhập tay đạt S-50 ở chữ 200%, sáng/tối (test trợ năng trong `currency_conversion_flow_test.dart`); gọi mạng thật trên máy thật: [M] CHƯA kiểm.
- AC-22: Số tiền hiển thị theo định dạng của ngôn ngữ đang dùng (vi: `1.250.000 ₫`; en: `$1,250.00`); tiền lưu dạng số nguyên theo đơn vị nhỏ nhất, không dùng số thực. [T]

### F-08 · Khoản định kỳ
- AC-23: Khi ghi khoản, bật "Lặp lại" với chu kỳ hằng ngày, hằng tuần, hằng tháng, hằng năm. [T]
- AC-24: Mở app sau khi tới hạn thì app tự tạo các khoản còn thiếu cho tới hôm nay, không tạo trùng khi mở app nhiều lần; không cần chạy nền. [T]
- AC-25: Dừng hoặc sửa một chuỗi định kỳ thì không đụng tới các khoản đã tạo trước đó. [T]

### F-09 · Ngân sách tháng
- AC-26: Đặt được một hạn mức chi cho mỗi tháng (tổng, không theo danh mục). [T]
- AC-27: Màn chính hiện thanh tiến độ "đã chi / hạn mức" của tháng ứng với kỳ đang xem (D-028: tháng → tháng đó; ngày/tuần → tháng chứa ngày cuối; năm/tất cả/tùy chọn → ẩn); vượt 100% thì thanh đổi màu cảnh báo và có chữ "Vượt X" (không chỉ dựa vào màu). [M]

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
- AC-43 (bản 2.0 chưa duyệt sẽ thay danh sách quyền bằng AC-140): ~~App không có quyền INTERNET trong manifest của bản phát hành~~ (sửa 2026-11-05 theo D-025): manifest bản phát hành chỉ có `INTERNET` (để tải tỉ giá, AC-72) và hai quyền nhắc ghi chép; app không gửi dữ liệu người dùng đi đâu. [T: kiểm manifest nguồn và manifest release đã gộp]

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
- AC-59 (sửa theo D-026, 2026-11-06): Khi bật, người dùng chọn **giờ sao lưu** (bộ chọn giờ của hệ thống ngay sau mật khẩu, điền sẵn **21:00**; hàng "Giờ sao lưu" đổi được bất cứ lúc nào; giờ theo múi giờ hiện tại của máy, lưu trong bộ nhớ an toàn cùng cấu hình F-24, không vào bảng `settings`). Android: đến giờ đó app **tự chạy nền kể cả khi đóng** (báo thức không chính xác, hệ thống có thể lùi vài phút; không xin quyền báo thức chính xác; đặt lại lịch sau khởi động lại, cập nhật app, đổi giờ, đổi múi giờ). **Bù khi lỡ:** đã qua giờ chọn mà mốc đó chưa được sao lưu (máy tắt, hệ thống không cho chạy…) thì lần mở app hoặc rời app kế tiếp sẽ sao lưu. App sao lưu tối đa **một lần cho mỗi mốc giờ trong ngày** (lần thử lỗi cũng tính; một lần bù phủ mọi mốc đã lỡ), và chỉ khi dữ liệu đã đổi kể từ lần sao lưu thành công trước. Dòng trạng thái có thêm "Lần tới: hôm nay/ngày mai, 21:00". File tên `vigon-auto-AAAAMMDD-GGPP.vigon`. Giữ tối đa **2 file tự động gần nhất** (D-027) trong thư mục; xóa file `vigon-auto-*` cũ hơn (không đụng file khác trong thư mục, không đụng file sao lưu tay). [T: `test/data/backup_schedule_test.dart`, `test/data/auto_backup_test.dart`, `test/features/auto_backup_schedule_test.dart`, `test/features/auto_backup_ui_test.dart`; M: chạy nền khi app đóng trên máy thật — TESTING M-2]
- AC-60: Nút **"Sao lưu ngay"** chạy ngay và báo kết quả; hiện thời gian và kết quả lần tự sao lưu gần nhất ("Lần cuối: 3 thg 11, 18:30"; nếu lỗi: "Không ghi được vào thư mục. Chọn lại thư mục"). Quyền ghi bị thu hồi hoặc thư mục bị xóa thì báo lỗi rõ ràng, không crash và không dừng im lặng; có nút "Chọn lại thư mục". Tắt "Sao lưu tự động" thì xóa mật khẩu khỏi Keystore và bỏ quyền thư mục, không xóa các file đã ghi. [T]
- Khôi phục: bộ chọn file hiện có đã mở được file `.vigon` mã hóa (F-21), hỏi mật khẩu như thường lệ. [T]
- Chú thích trong app: "Ví Gọn chỉ ghi file vào thư mục bạn chọn. Việc tải lên Google Drive hay Dropbox do app đó thực hiện." [T]
- iOS (D-022):
  - AC-58 trên iOS: chọn thư mục bằng bộ chọn của app Tệp (`UIDocumentPickerViewController`, loại thư mục; vd iCloud Drive, Google Drive, "Trên iPhone"). App giữ quyền bằng security-scoped bookmark trong UserDefaults của app; Dart chỉ giữ mã `ios-bookmark:<uuid>` trong SecretStore như URI của Android. Mật khẩu trong **Keychain** (Keystore ↔ Keychain), cùng luật "không bao giờ ghi vào file, log, cơ sở dữ liệu"; file luôn mã hóa. Chú thích trong app: `autoBackupNoteIos` ("…thư mục bạn chọn trong app Tệp, ví dụ trong iCloud Drive."). [T]
  - AC-59 trên iOS (sửa theo D-026): iOS không cho app đã đóng tự chạy đúng giờ, nên đúng giờ đã chọn app hiện **thông báo cục bộ** lặp hằng ngày "Đến giờ sao lưu Ví Gọn. Chạm để sao lưu." (`autoBackupNotificationBody`, không số liệu, mã thông báo 1002 khác nhắc ghi chép 1001); chạm vào hoặc mở/quay lại app bất kỳ lúc nào sau giờ đó thì sao lưu chạy (không chạy lúc ra nền vì iOS có thể dừng app giữa chừng). Quyền thông báo xin khi bật hoặc đổi giờ nếu chưa có, sau lời giải thích (`autoBackupNotifyTitleIos`/`autoBackupNotifyBodyIos`, S-40); bị từ chối thì báo nhẹ (`autoBackupNotifyDeniedIos`), sao lưu tự động vẫn bật và vẫn bù khi mở app. Cùng luật mỗi mốc một lần, chỉ khi dữ liệu đổi, tên file và giữ 2 file như Android. Chú thích: `autoBackupRunsOnOpenIos` ("…Đúng giờ bạn chọn, Ví Gọn gửi thông báo; chạm vào hoặc mở app để sao lưu. Lỡ giờ thì sao lưu bù khi bạn mở app…"). [T: `test/data/hifi_d4_auto_backup_ios_test.dart`, `test/features/auto_backup_schedule_test.dart` nhóm "iOS: thông báo hằng ngày", `test/features/auto_backup_ui_test.dart` nhóm "iOS (D-026, S-40)"; M: thông báo thật trên iPhone — TestFlight]
  - Cảnh báo thư mục: thư mục không nằm trên iCloud Drive (`AutoBackupState.folderInICloud != true`) thì hiện `autoBackupLocalFolderWarningIos` ("Thư mục này có thể chỉ nằm trên iPhone…"), vì dữ liệu app không nằm trong sao lưu iPhone (D-021) và iOS không phân biệt được "Trên iPhone" với Google Drive/Dropbox. [T]
  - AC-60 trên iOS: bookmark mất hoặc bị thu hồi, thư mục bị xóa → cùng trạng thái lỗi và nút "Chọn lại thư mục" như Android; tắt thì xóa mật khẩu khỏi Keychain và xóa bookmark (`releaseFolder`), không xóa file đã ghi. [T: cùng file test, "lỗi thư mục iOS (bookmark mất / bị thu hồi)…"]
  - [M] trên iPhone (TestFlight): bộ chọn thư mục mở được; ghi file thật vào iCloud Drive và Google Drive; file iCloud chưa tải về vẫn được đếm/dọn đúng 2 file; bookmark còn hiệu lực sau khi khởi động lại máy; thu hồi quyền/xóa thư mục → báo lỗi, không crash; file ghi trên iPhone khôi phục được trên Android và ngược lại.

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

## 3d. Bản 2.0: nhập tự động và bộ tài chính đầy đủ (F-27..F-44) — CHƯA DUYỆT
Người dùng duyệt **kế hoạch** ngày 2026-11-06 (`notes/2026-11-06-ke-hoach-mo-rong.md`, nguồn duy nhất của các quyết định); mục này là đặc tả để duyệt trước khi có code. Bổ sung cho mục 3, 3b, 3c, không thay thế; chỗ nào sửa AC cũ thì ghi rõ. Quyết định: D-030 (nhập tự động), D-031 (email IMAP), D-032 (ML Kit), D-033 (ảnh hoá đơn), D-034 (ghép, chuyển nội bộ, điều chỉnh số dư, tự tạo tài khoản), D-035 (5 phiên điều phối, làm hết rồi mới phát hành).

Ràng buộc chung của 3d:
- **Hai nền tảng**, trừ F-28 (đọc thông báo) chỉ Android vì iOS không cho app đọc thông báo của app khác. iOS: email, quét hoá đơn và mọi tính năng còn lại như Android.
- **Số tiền chính xác (D-029)** cho mọi cột tiền mới (mục tiêu tiết kiệm, khoản nợ, lần trả nợ): có cột `*Micro` ẩn, quy đổi khi đổi tiền tệ (AC-137). Khoản tự nhập lấy đúng số tiền trong tin.
- Mọi chữ trong `.arb` (vi, en); mọi màn mới đạt S-50 như các màn cũ (AC-141).
- Từ dùng theo `CONTEXT.md`: "khoản" (Entry), "tin biến động" (Detected transaction), "ghép" (Match), "điều chỉnh số dư" (Balance adjustment). Không dùng chữ "giao dịch" cho khoản.
- **Thời điểm của tin** = ngày giờ ghi trong tin; tin không ghi giờ thì lấy lúc hệ thống nhận thông báo (thông báo) hoặc giờ gửi thư (email, header `Date`), theo giờ máy.
- Mục đánh dấu *(mặc định)* là chỗ kế hoạch chưa nói và Claude tự chọn; người dùng đổi được khi duyệt (tổng hợp ở cuối mục).

### F-27 · Giờ của khoản
- AC-74: Màn Nhập/Sửa khoản (cả chi, thu, chuyển tiền) có ô **Giờ** `HH:mm` mở bộ chọn giờ hệ thống (24 giờ hay 12 giờ theo máy). Khoản mới mặc định là giờ lúc mở màn nhập; đổi ngày không đổi giờ; lưu thì giữ đúng giờ đã chọn. [T]
- AC-75: Khoản có từ trước schema 4 và khoản sinh từ khoản định kỳ *(mặc định)* **không có giờ**: dòng khoản không hiện giờ; màn sửa hiện ô Giờ "Chưa đặt giờ"; lưu mà không đặt thì vẫn không có giờ. Khi ghép (F-31) khoản không giờ được coi là **12:00** của ngày đó. [T]
- AC-76: Trong một ngày, Các khoản xếp khoản có giờ theo giờ mới nhất trước, rồi tới khoản không giờ (theo thứ tự tạo, mới trước). Dòng khoản có giờ hiện giờ (vd "12:02") cạnh tên tài khoản. [T]
- AC-77: Giờ đi theo file sao lưu `.vigon`; file schema 1–3 vẫn khôi phục được (mọi khoản không giờ). CSV, Excel có cột Giờ (trống nếu không có, AC-139, AC-132). [T]

### F-28 · Nguồn nhập: đọc thông báo app ngân hàng/ví (chỉ Android, D-030)
- AC-78: Cài đặt có nhóm **"Nhập tự động"**: "Thông báo ngân hàng" (chỉ Android), "Email ngân hàng" (F-33), "Quy tắc danh mục" (AC-101), "Hàng chờ duyệt" (AC-102). Trên iOS **không** có dòng "Thông báo ngân hàng" và không có màn, chữ hay cấu hình nào về đọc thông báo. [T]
- AC-79: Bật "Đọc thông báo ngân hàng" thì **trước tiên** hiện màn giải thích (prominent disclosure) nói: app đọc thông báo của các app ngân hàng/ví bạn chọn để tự ghi khoản; mọi xử lý trên máy, không gửi đi đâu; thông báo của app khác bị bỏ ngay, không lưu; mã OTP không bao giờ được lưu; tắt được bất cứ lúc nào. Nút "Đồng ý và mở cài đặt" mở đúng trang "Truy cập thông báo" của hệ thống; "Không, cảm ơn" thì không mở gì, công tắc vẫn tắt. Không dẫn người dùng tới trang quyền này ở chỗ nào khác. [T cho luồng và chữ; M cho trang hệ thống trên Galaxy A13]
- AC-80: Quay lại app: đã có quyền → công tắc bật, hiện danh sách **10 app nguồn** (Vietcombank, Techcombank, MB, BIDV, VietinBank, ACB, VPBank, TPBank, MoMo, ZaloPay) *(mặc định: đều được chọn)*, bỏ chọn từng app được; chưa có quyền → công tắc tắt, "Chưa cấp quyền truy cập thông báo". Quyền bị thu hồi ngoài app → lần mở sau hiện "Đã mất quyền đọc thông báo" + nút "Cấp lại". [T]
- AC-81: Chỉ thông báo của đúng gói (package) app nguồn đang được chọn mới đi vào bộ đọc. Thông báo của app khác (kể cả Zalo, Messenger, Tin nhắn/SMS) bị bỏ ngay trong mã native: không ghi vào hàng đợi, cơ sở dữ liệu hay log. [T: test hợp đồng Kotlin + Dart với danh sách gói]
- AC-82: Tin tới khi app đã đóng hoặc đang khoá PIN vẫn được xử lý: Kotlin ghi tin vào hàng đợi bền trên máy rồi xử lý nền bằng Dart (như cơ chế chạy nền của sao lưu tự động); xử lý nền lỗi hoặc bị hệ thống chặn thì lần mở app kế tiếp xử lý nốt. Cùng một thông báo bị hệ thống đăng lại hoặc cập nhật (cùng app, cùng nội dung) không tạo khoản thứ hai. App không tự gửi thông báo "đã ghi khoản" *(mặc định)*. [T cho hàng đợi, xử lý lại, chống lặp; M: tắt hẳn app, chuyển một khoản nhỏ thật → mở app thấy khoản đúng tài khoản]
- AC-83: Tắt công tắc → bỏ mọi thông báo tới từ lúc đó, xoá hàng đợi chưa xử lý, hiện hướng dẫn kèm nút mở cài đặt hệ thống để thu hồi quyền (app không tự thu hồi được); khoản đã nhập giữ nguyên. [T]

### F-29 · Bộ đọc tin biến động (thông báo và email)
- AC-84: Bộ đọc chung lấy từ một tin: chiều tiền (ra/vào), số tiền, tiền tệ, số dư sau biến động (nếu có), nội dung/nơi bán, 4 số cuối tài khoản hoặc thẻ (nếu có), thời điểm. Ví dụ "TK 0071xxxx1234 -50,000VND luc 06/11/26 12:02. SD: 1,950,000VND. ND: THANH TOAN QR HIGHLANDS 4471" → ra; 50.000; VND; số dư 1.950.000; "THANH TOAN QR HIGHLANDS 4471"; "1234"; 06/11/2026 12:02. [T]
- AC-85: Có mẫu riêng cho từng nguồn trong 10 nguồn (AC-80) và email của các ngân hàng đó; mẫu riêng được thử trước bộ đọc chung. Mỗi mẫu tin thật người dùng gửi (đã che số tài khoản) nằm trong `test/import/samples/<nguồn>/` kèm kết quả mong đợi và cho đúng mọi trường. [T]
- AC-86: Số tiền VND: dấu "." và "," đều là dấu nghìn ("50.000", "50,000", "50 000" đều là 50.000 ₫). Chiều tiền lấy từ dấu +/− hoặc chữ ("ghi có", "ghi nợ", "nhận", "chuyển", "thanh toán", "PS:"). Khi **không chắc số tiền hoặc chiều tiền** (vd "50,00"; hai số tiền không nhãn; không có dấu hay chữ chỉ chiều) → tin vào Hàng chờ duyệt (AC-102), không tự lưu. [T]
- AC-87: Tin không phải biến động (OTP/mã xác thực, quảng cáo, cảnh báo đăng nhập, tin không có số tiền) bị bỏ: không tạo khoản, không vào hàng chờ, không lưu nội dung. Tin chứa "OTP", "mã xác thực", "mã xác nhận", "mật khẩu" không bao giờ được lưu dưới bất kỳ dạng nào. [T]
- AC-88: App **không bao giờ lưu số tài khoản hay số thẻ đầy đủ**: chỉ giữ 4 số cuối. Nội dung tin đưa vào Hàng chờ duyệt được che trước khi lưu: mọi dãy từ 9 chữ số liền trở lên không đứng ngay trước đơn vị tiền chỉ còn "…" + 4 số cuối (vd "0071000123456" → "…3456"); dãy đã có "x/*" che sẵn giữ nguyên. [T]
- AC-89 *(mặc định)*: Tiền tệ trong tin khác tiền tệ của app (vd tin VND, app đang dùng USD) → tin vào Hàng chờ duyệt với lý do "Tin bằng VND, app đang dùng USD"; app không tự quy đổi. [T]

### F-30 · Tự tạo tài khoản và khớp số dư (D-034)
- AC-90: Tin đầu tiên của một cặp (ngân hàng/ví, 4 số cuối) chưa có Account → app tạo Account tên "<tên ngân hàng> …<4 số cuối>" (vd "Vietcombank …1234"); ví không có số tài khoản → tên ví ("MoMo"); tin ngân hàng không có 4 số cuối *(mặc định)* → "<tên ngân hàng>". **Số dư ban đầu** = số dư trong tin trừ ngược biến động của chính tin đó: tin "−50.000, SD 1.950.000" → số dư ban đầu 2.000.000, lưu xong số dư tài khoản là 1.950.000. Tin không có số dư → số dư ban đầu 0. [T]
- AC-91: Account tự tạo là Account bình thường: đổi tên, ẩn được; xoá theo AC-45. Liên kết nằm ở (ngân hàng, 4 số cuối), không ở tên, nên đổi tên không mất liên kết. Account đã ẩn vẫn nhận khoản tự nhập *(mặc định)*. Xoá rồi có tin mới → tạo lại Account mới. Account tự tạo có icon nguồn (ngân hàng/ví) ở màn Tài khoản. [T]
- AC-92: **Khớp số dư:** sau khi lưu hoặc ghép khoản của một tin có số dư S, nếu số dư Account đó tính tới thời điểm tin (gồm mọi khoản có ngày giờ ≤ thời điểm tin; khoản không giờ coi là 12:00) là B ≠ S thì app tạo **một khoản** ở Account đó, thời điểm = thời điểm tin, số tiền |S − B|: S < B → chi danh mục "Khác"; S > B → "Thu khác"; ghi chú "Điều chỉnh số dư". Ví dụ: số dư app 2.000.000, tin "−50.000, SD 1.900.000" → khoản chi 50.000 của tin + khoản chi "Khác" 50.000 "Điều chỉnh số dư". **Không có loại khoản mới**: khoản điều chỉnh tính vào tổng chi/thu, biểu đồ, ngân sách như mọi khoản. [T]
- AC-93: B = S → không tạo gì; tin không có số dư → không khớp. Khoản điều chỉnh sửa, xoá được như khoản thường; xoá nó thì app không tạo lại cho tin cũ (chỉ tin mới mới kích hoạt khớp). [T]

### F-31 · Ghép trùng ±2 giờ và chuyển nội bộ (D-034)
- AC-94: Một tin (thông báo hoặc email) **ghép** vào một khoản có sẵn khi: cùng Account; cùng chiều tiền (ra ↔ khoản chi hoặc chuyển tiền đi từ Account đó; vào ↔ khoản thu hoặc chuyển tiền đến Account đó) *(cùng chiều: kế hoạch chưa ghi rõ, Claude hiểu là bắt buộc)*; cùng số tiền; thời điểm chênh ≤ 2 giờ. Ghép thì không tạo khoản mới; khoản có sẵn **giữ nguyên mọi dữ liệu** (số tiền, danh mục, ghi chú, ngày giờ, ảnh), chỉ gắn thêm nguồn. Tình huống: ghi tay chi 50.000 "Cà phê" ở "Vietcombank …1234" lúc 12:00; 12:02 có thông báo VCB −50.000 → vẫn một khoản "Cà phê" 12:00, nay có biểu tượng nguồn "Thông báo". Khoản không ở cùng Account (vd ghi tay ở "Tiền mặt") thì không ghép (xem Q-03). [T]
- AC-95: Biên 2 giờ tính cả hai đầu: 12:00 với 14:00 → ghép; 12:00 với 14:01 → không ghép, tạo khoản mới. Qua nửa đêm: ghi tay 23:30 ngày 05/11, tin 00:40 ngày 06/11 → ghép. Khoản không giờ ngày 06/11 (= 12:00) với tin 13:30 → ghép; với tin 15:00 → không. [T]
- AC-96: Mỗi khoản ghép được **một lần cho mỗi loại nguồn** (tối đa một thông báo và một email) *(cách hiểu "mỗi khoản chỉ ghép một lần", xem Q-04)*. Hai biến động thật cùng giá: thông báo −50.000 lúc 12:00 và 12:30 cùng tài khoản → hai khoản. Một biến động có cả thông báo và email → một khoản mang hai nguồn. Nhiều khoản đủ điều kiện → ghép vào khoản có thời điểm gần nhất; bằng nhau → khoản tạo trước. [T]
- AC-97: **Chuyển nội bộ:** tin tiền ra ở Account A và tin tiền vào ở Account B (A ≠ B, đều là Account trong app), cùng số tiền, chênh ≤ 2 giờ, và cả hai đều là khoản **tự nhập** chưa ghép chuyển *(mặc định: không ghép khoản ghi tay thành chuyển tiền)* → gộp thành **một Transfer** A→B (ngày giờ của tin ra, ghi chú của tin ra), hai khoản chi/thu tạm biến mất. Ví dụ "Vietcombank …1234" −2.000.000 lúc 10:00 và "MoMo" +2.000.000 lúc 10:01 → Transfer "Vietcombank …1234 → MoMo" 2.000.000; tổng thu/chi của kỳ không còn tính 2.000.000 này. Tin nào tới trước cũng ra cùng kết quả. [T]
- AC-98: Transfer tự ghép có nhãn "Tự ghép chuyển tiền" và lệnh **"Tách thành chi và thu"** *(mặc định)* trả lại hai khoản như trước khi gộp; cặp đã tách không bị tự ghép lại. Transfer ghi tay A→B được ghép với tin ra ở A và tin vào ở B theo AC-94. [T]

### F-32 · Lưu thẳng, quy tắc danh mục, hàng chờ duyệt
- AC-99: Tin chắc chắn (không vào hàng chờ) được **lưu thẳng**, không hỏi: danh mục theo Merchant rule nếu có, không thì chi "Khác" hoặc "Thu khác"; ghi chú = nội dung/nơi bán (cắt ở 200 ký tự); nguồn = "Thông báo <tên app>" hoặc "Email <địa chỉ gửi>". Dòng khoản có biểu tượng nguồn; màn sửa ghi "Tự nhập từ thông báo Vietcombank, 06/11 12:02". [T]
- AC-100: **Khoá nơi bán** (Merchant key) *(mặc định)* = nội dung tin sau khi bỏ dấu, viết thường, bỏ dãy từ 4 chữ số trở lên, gộp khoảng trắng (vd "THANH TOAN QR HIGHLANDS 4471" → "thanh toan qr highlands"). Người dùng đổi danh mục của một khoản tự nhập → app lưu (hoặc ghi đè) quy tắc khoá → danh mục và hiện thanh "Lần sau tự xếp vào Ăn uống · Hoàn tác". Tin sau cùng khoá, cùng chiều tiền → danh mục đó. Khoản đã có không đổi. Quét hoá đơn (F-34) dùng cùng quy tắc với khoá là tên cửa hàng. [T]
- AC-101: Cài đặt → Nhập tự động → **Quy tắc danh mục**: liệt kê khoá → danh mục, xoá từng quy tắc được. Xoá danh mục thì quy tắc trỏ tới nó chuyển sang danh mục nhận khoản (như AC-17). Quy tắc nằm trong file sao lưu. [T]
- AC-102: **Hàng chờ duyệt** chỉ nhận tin không chắc số tiền hoặc chiều tiền (AC-86) và tin lệch tiền tệ (AC-89). Màn chính hiện "N tin chờ duyệt" khi N > 0, chạm mở hàng chờ. Mỗi mục: nội dung đã che (AC-88), nguồn, thời điểm, số tiền và chiều đoán được (nếu có). "Ghi thành khoản" mở Nhập khoản điền sẵn; lưu xong mục rời hàng chờ và khoản đi qua ghép (F-31), khớp số dư (F-30) như tin chắc. "Bỏ qua" xoá mục. Mục quá 30 ngày tự xoá *(mặc định)*. Hàng chờ **không** vào file sao lưu *(mặc định)*. [T]

### F-33 · Email ngân hàng qua IMAP (cả hai nền tảng, D-031)
- AC-103: Nhập tự động → Email ngân hàng → "Thêm hộp thư": chọn **Gmail, Yahoo hoặc iCloud** *(mặc định: chỉ ba nhà cung cấp này, không máy chủ tuỳ ý)*, nhập địa chỉ email và **mật khẩu ứng dụng** (không phải mật khẩu chính) với hướng dẫn từng bước và nút mở trang tạo mật khẩu ứng dụng của nhà cung cấp (trình duyệt ngoài app). App đăng nhập thử ngay và báo "Đã kết nối" hoặc lỗi rõ: "Sai địa chỉ hoặc mật khẩu ứng dụng", "Hộp thư chưa bật IMAP", "Không có mạng". Tối đa 3 hộp thư *(mặc định)*. [T với máy chủ IMAP giả; M Gmail thật — người dùng tự nhập mật khẩu]
- AC-104: Địa chỉ hộp thư và mật khẩu ứng dụng **chỉ** lưu trong Keystore (Android) / Keychain (iOS); không nằm trong cơ sở dữ liệu, file sao lưu, CSV, Excel, PDF hay log. Xoá hộp thư hoặc "Xóa toàn bộ dữ liệu" → xoá khỏi Keystore/Keychain. Khôi phục sang máy khác không mang hộp thư theo. [T]
- AC-105: App chỉ kết nối IMAP qua TLS ngay từ đầu (cổng 993) tới đúng `imap.gmail.com`, `imap.mail.yahoo.com`, `imap.mail.me.com`; chứng chỉ kiểm theo hệ thống; không STARTTLS, không bản rõ, không máy chủ nào khác. [T]
- AC-106: App chỉ **tìm trên máy chủ** thư trong INBOX có địa chỉ gửi nằm trong danh sách địa chỉ ngân hàng (mặc định theo các nguồn có mẫu, người dùng thêm/xoá địa chỉ được) và *(mặc định)* nhận từ lúc kết nối hộp thư trở đi; thư khác không được tải. Thư được mở ở chế độ chỉ xem (không đánh dấu đã đọc, không xoá, không chuyển, không gửi thư). Thân thư chỉ được đọc như chữ (bỏ HTML, không tải ảnh hay link ngoài), xử lý trong bộ nhớ rồi bỏ, không lưu (trừ mục hàng chờ đã che). App nhớ thư cuối đã đọc (UID) để không đọc lại. [T]
- AC-107: App kiểm thư khi mở hoặc quay lại app (cách lần trước ≥ 15 phút *(mặc định)*), khi người dùng kéo để làm mới ở Hàng chờ duyệt / màn Email ngân hàng, và **trên Android chạy nền khoảng mỗi giờ** khi app đóng (lịch không chính xác, không quyền báo thức chính xác, đặt lại sau khởi động lại máy — dùng lại cơ chế chạy nền của sao lưu tự động). iOS chỉ kiểm khi mở/quay lại app; màn cài đặt iOS ghi rõ điều này. Lỗi đăng nhập → dừng kiểm tự động hộp thư đó tới khi người dùng nhập lại mật khẩu *(mặc định, tránh bị nhà cung cấp khoá)*; màn hiện "Lần kiểm cuối: …" hoặc lỗi. [T cho lịch và trạng thái; M chạy nền thật trên A13]
- AC-108: Thư ngân hàng đi qua cùng bộ đọc (F-29), ghép (F-31), tự tạo tài khoản và khớp số dư (F-30), quy tắc danh mục (F-32) như thông báo. Một biến động có cả thông báo và email → một khoản (AC-96). [T]

### F-34 · Quét hoá đơn (OCR) và ảnh hoá đơn (D-032, D-033)
- AC-109: Màn Nhập khoản chi *(mặc định: chỉ khoản chi)* có nút **"Quét hoá đơn"** (icon máy ảnh): "Chụp ảnh" (app máy ảnh của hệ thống) hoặc "Chọn từ thư viện" (bộ chọn ảnh của hệ thống). Có ảnh → app nhận chữ **trên máy** bằng ML Kit gói kèm (ảnh không rời máy) rồi điền sẵn: **số tiền** = số trên dòng có "Tổng cộng", "Tổng tiền", "Thành tiền", "Cộng", "Total" (không có thì số lớn nhất có dạng tiền); **ngày, giờ** in trên hoá đơn (không có thì giữ giờ hiện tại); **ghi chú** = tên cửa hàng (dòng đầu có chữ cái); **danh mục** theo quy tắc danh mục nếu khớp tên cửa hàng. Người dùng sửa được rồi bấm Lưu; **không tự lưu**. Khoản lưu từ đây có nguồn "Hoá đơn". [T cho phần trích từ chữ OCR cố định; M chụp thật]
- AC-110: Không đọc được tổng tiền → báo "Không đọc được tổng tiền, hãy nhập tay", vẫn giữ ảnh đính kèm. Hoá đơn tiếng Việt có dấu in rõ: tổng tiền đọc đúng ở ≥ 8/10 hoá đơn mẫu; nhận chữ ≤ 3 giây trên Galaxy A13 *(ngưỡng đề xuất, chốt sau spike N3)*. [M]
- AC-111: Mọi khoản thu/chi (không chỉ khoản từ OCR) có "Thêm ảnh hoá đơn" ở màn nhập/sửa; tối đa **1 ảnh mỗi khoản** *(mặc định)*, thay hoặc gỡ được. Khi **lưu** khoản, ảnh được ghi vào album **"Ví Gọn"** của thư viện ảnh (Android: `Pictures/Ví Gọn`; iOS: album "Ví Gọn" trong Ảnh), tên `vigon-<uuid>.jpg`, JPEG cạnh dài ≤ 2048 px; app chỉ giữ tên file. Huỷ màn nhập thì không ghi ảnh nào. Chạm ảnh ở màn sửa mở xem toàn màn. [T cho tên file và luồng; M album thật trên A13 và iPhone]
- AC-112: Lần đầu đính kèm ảnh, hộp thông báo: "Ảnh hoá đơn được lưu trong album 'Ví Gọn' của thư viện ảnh. Ảnh **không** nằm trong file sao lưu và **không** được khoá PIN bảo vệ: app Ảnh và người cầm máy đều xem được." + "Đã hiểu". Ý này cũng có trong màn Giới thiệu → Quyền riêng tư và chính sách quyền riêng tư. [T]
- AC-113: Gỡ ảnh khỏi khoản hoặc xoá khoản: ảnh **vẫn ở thư viện ảnh** (app không xoá ảnh của người dùng); Hoàn tác xoá khoản gắn lại ảnh. Ảnh bị xoá khỏi thư viện từ bên ngoài → màn sửa hiện "Không tìm thấy ảnh" và nút gỡ liên kết. [T]
- AC-114: File sao lưu chỉ mang **tên file** ảnh. Sau khôi phục, app **gắn lại ảnh theo tên file**: iOS tìm trong album "Ví Gọn" (cần quyền đọc thư viện ảnh, hỏi lúc này nếu chưa có); Android *(mặc định, xem Q-06)* hỏi người dùng chọn thư mục `Pictures/Ví Gọn` một lần bằng bộ chọn thư mục của hệ thống rồi đọc trong đó (không xin quyền đọc toàn bộ ảnh). Xong báo "Đã gắn lại N/M ảnh"; tên không tìm thấy → khoản hiện "Không tìm thấy ảnh". [T cho phần so tên; M khôi phục thật trên máy cài mới]

### F-35 · Tiết kiệm
- AC-115: Màn **"Tiết kiệm"** (vào từ màn chính và Cài đặt; vị trí theo mockup phiên #4): tạo Savings goal gồm tên (≤ 50 ký tự), số tiền mục tiêu > 0, hạn (ngày, *(mặc định)* tuỳ chọn), và Account gắn: chọn Account có sẵn chưa gắn mục tiêu khác, hoặc "Tạo tài khoản mới" (tên = tên mục tiêu, số dư ban đầu 0). Một Account gắn tối đa một mục tiêu. [T]
- AC-116: **Tiến độ** = số dư hiện tại của Account gắn (gồm số dư ban đầu) so với mục tiêu: thanh %, "Đã có X / Y", "Còn thiếu Z"; có hạn thì "Còn N ngày" hoặc "Quá hạn N ngày". Số dư ≥ mục tiêu → **"Đã đạt"** (dấu ✓ kèm chữ). Rút tiền khỏi Account làm tiến độ giảm và có thể mất "Đã đạt". Ví dụ: mục tiêu 10.000.000, Account có 3.000.000 → 30%, còn thiếu 7.000.000. [T]
- AC-117: **"Góp tiền"** mở màn Chuyển tiền với "Đến" = Account của mục tiêu, "Từ" = tài khoản mặc định; lưu ra một Transfer bình thường: tổng thu, tổng chi, biểu đồ, ngân sách **không đổi**; tổng số dư (AC-122) không đổi. [T]
- AC-118: Xoá mục tiêu không xoá Account hay khoản nào. Mục tiêu (kèm số tiền chính xác D-029) đi theo file sao lưu và được quy đổi khi đổi tiền tệ (AC-137). [T]

### F-36 · Khoản nợ (sổ ghi nhớ)
- AC-119: Màn **"Khoản nợ"**: thêm Debt record gồm người (≤ 50 ký tự), chiều **"Cho vay"** (người khác nợ bạn) hoặc **"Đi vay"** (bạn nợ người khác), số tiền > 0, ngày, hạn (tuỳ chọn), ghi chú (≤ 200 ký tự). Danh sách chia hai nhóm "Người khác nợ bạn" / "Bạn nợ người khác", mỗi nhóm có tổng còn lại. [T]
- AC-120: Thêm **lần trả** (số tiền > 0, ngày; không vượt số còn lại, vượt thì báo lỗi); còn lại = số tiền − tổng các lần trả; về 0 → **"Đã xong"**, chuyển xuống mục "Đã xong" (thu gọn). Xoá lần trả thì tính lại. Quá hạn mà chưa xong → "Quá hạn" (chữ, không chỉ màu). **Không có thông báo nhắc hạn** *(mặc định)*. [T]
- AC-121: Khoản nợ và lần trả **không** tạo khoản (Entry), không đổi số dư Account nào, không vào thu/chi, biểu đồ, ngân sách hay tổng số dư. Có trong file sao lưu; được quy đổi khi đổi tiền tệ (AC-137). [T]

### F-37 · Dashboard (màn chính mở rộng)
- AC-122: Màn chính giữ vòng danh mục, thu/chi/số dư của kỳ và thanh ngân sách đã có, thêm *(mặc định: các ô nằm dưới vòng, bố cục theo mockup phiên #4)*: (1) **"Tổng số dư"** = tổng số dư mọi Account, **gồm cả tài khoản ẩn**, không theo bộ lọc tài khoản; (2) ô **"Thu − chi tháng"** (thu − chi của tháng, theo bộ lọc tài khoản); (3) ô **"Ngân sách còn lại"** = hạn mức tháng − đã chi (mọi tài khoản); âm → "Vượt X"; chưa đặt ngân sách → ô "Đặt ngân sách" mở chỗ đặt; (4) **biểu đồ cột thu–chi** 6 tháng *(mặc định)* kết thúc ở tháng đang xem; (5) **"So với tháng trước"**: % thay đổi của chi và của thu so với tháng liền trước, có mũi tên kèm chữ "tăng"/"giảm"; tháng trước bằng 0 → "—". "Tháng" của (2), (3), (5) *(mặc định)* theo luật D-028 (kỳ ngày/tuần/tháng → tháng của kỳ đó; kỳ năm/tất cả/tuỳ chọn → tháng hiện tại); ô ghi rõ tháng (vd "Tháng 11/2026"). [T]
- AC-123: Ví dụ: tháng 10 chi 4.000.000, tháng 11 chi 5.000.000 → "Chi tăng 25% so với tháng 10". Mọi số khớp tổng các khoản tới đơn vị nhỏ nhất. Biểu đồ cột có bảng thay thế cho trình đọc màn hình (như AC-39). [T]

### F-38 · Thống kê
- AC-124: Màn **"Thống kê"** dùng cùng chọn kỳ (F-03) và bộ lọc tài khoản, có: (1) **biểu đồ cột thu/chi** theo kỳ con — Ngày: một cặp cột; Tuần: 7 ngày; Tháng: từng ngày; Năm: 12 tháng; Tất cả: từng năm; Khoảng tuỳ chọn ≤ 31 ngày: từng ngày, ≤ 366 ngày: từng tháng, dài hơn: từng năm *(mặc định)*; (2) **5 danh mục chi nhiều nhất** (số tiền, % trên tổng chi kỳ); (3) **"Ngày chi nhiều nhất"** (ngày + số tiền; bằng nhau → ngày sớm hơn; kỳ Ngày thì ẩn); (4) **đường lịch sử tổng số dư** (mọi Account, giá trị cuối mỗi kỳ con). Biểu đồ tròn và % theo danh mục đã có giữ nguyên. [T]
- AC-125: Kỳ không có khoản → trạng thái trống, không vẽ biểu đồ rỗng. Mọi biểu đồ có bảng thay thế cho trình đọc màn hình. Với 10.000 khoản, kỳ "Tất cả" mở xong ≤ 1 giây trên Galaxy A13 (bản release). [T cho số liệu; M cho thời gian]

### F-39 · Cảnh báo sắp vượt ngân sách
- AC-126: Ngưỡng **"Sắp vượt"** mặc định **80%**, chỉnh trong Cài đặt từ 50% tới 95%, bước 5%. Đã chi ≥ ngưỡng × hạn mức và ≤ hạn mức → "Sắp vượt" (icon + chữ "Đã dùng 82%", màu cảnh báo khác màu "Vượt"); > hạn mức → "Vượt X" như AC-27. Áp cho ngân sách tháng (thanh màn chính, ô "Ngân sách còn lại") và ngân sách danh mục (AC-54). Ví dụ hạn mức 5.000.000, ngưỡng 80%: đã chi 3.999.999 → bình thường; 4.000.000 → Sắp vượt; 5.000.000 → Sắp vượt; 5.000.001 → Vượt 1. [T]
- AC-127: Công tắc **"Thông báo ngân sách"** *(mặc định tắt)*; bật thì giải thích rồi mới xin quyền thông báo như AC-61. Khi bật: một khoản (ghi tay, sinh định kỳ, tự nhập — kể cả khi chạy nền) làm đã chi **của tháng hiện tại** vượt qua mốc ngưỡng hoặc mốc 100% của một ngân sách (tháng hoặc danh mục) → gửi **một** thông báo cục bộ. Mỗi mốc của mỗi ngân sách tối đa một lần mỗi tháng: giảm xuống rồi lên lại trong tháng không báo lại; sang tháng mới đặt lại. Khoản ghi lùi vào tháng cũ không gây thông báo. [T]
- AC-128: Nội dung khi **PIN tắt** *(mặc định)*: "Ngân sách tháng 11: đã dùng 80% (4.000.000 ₫ / 5.000.000 ₫)" hoặc "Ăn uống đã vượt hạn mức tháng 11". Khi **PIN bật**: "Một ngân sách sắp hết. Mở Ví Gọn để xem." — không số tiền, không %, không tên danh mục. Chạm mở app (qua màn khoá nếu bật) ở màn chính. [T]

### F-40 · Lịch chi tiêu
- AC-129: Màn **"Lịch"** dạng tháng (dùng lại lưới lịch của `range_calendar.dart`): mỗi ngày hiện tổng chi rút gọn (vi: "50k", "1,2tr"; en: "50K", "1.2M") và một chấm nếu có thu; ‹ › hoặc vuốt để đổi tháng; theo Ngày đầu tuần (AC-12) và bộ lọc tài khoản. Chạm một ngày → danh sách khoản của ngày đó kèm tổng thu/chi ngày (sửa, vuốt xoá, Hoàn tác như Các khoản). Trình đọc màn hình đọc từng ngày dạng "6 tháng 11, chi 250.000 ₫". [T]

### F-41 · Lọc nâng cao
- AC-130: Màn Các khoản có nút **"Lọc"**: khoảng số tiền (từ/đến, bỏ trống một đầu được; từ > đến → lỗi dưới ô), **nhiều danh mục** (chọn nhiều, cả chi và thu), **khoảng ngày** (bộ chọn khoảng như Khoảng tuỳ chọn; đặt rồi thì thay kỳ đang xem cho danh sách này). Các điều kiện kết hợp với nhau, với tìm kiếm (F-15) và bộ lọc tài khoản bằng VÀ. Kết quả: danh sách phẳng mới nhất trước + "N khoản · chi X · thu Y"; mỗi điều kiện là một chip gỡ được, có "Xoá lọc". Có lọc danh mục thì loại chuyển tiền. Bộ lọc chỉ sống trong phiên chạy. Ví dụ: 50.000–200.000, Ăn uống + Đi lại, 01–15/11/2026 → đúng các khoản thoả cả ba. [T]

### F-42 · Xuất Excel và PDF
- AC-131: Cài đặt → Dữ liệu → **"Xuất Excel"** / **"Xuất PDF"**: chọn phạm vi (kỳ đang xem hoặc khoảng tuỳ chọn) rồi mở bảng chia sẻ của hệ điều hành (như AC-28; không xin quyền bộ nhớ). [T]
- AC-132: Excel `.xlsx` có sheet "Khoản" (ngày, giờ, loại, số tiền là ô số định dạng tiền đúng số lẻ, tiền tệ, danh mục, tài khoản, đến tài khoản, ghi chú, nguồn), sheet "Theo danh mục" (danh mục, tổng, %), sheet "Khoản nợ" (người, chiều, số tiền, đã trả, còn lại, hạn, trạng thái). Tiêu đề theo ngôn ngữ app. Ô chữ bắt đầu bằng `= + - @` vẫn là chữ, không thành công thức. [T: đọc lại file vừa xuất; M mở bằng Excel và Google Sheets, tiếng Việt đúng]
- AC-133: PDF khổ A4: "Báo cáo thu chi <kỳ>", tổng thu, tổng chi, chênh lệch, bảng theo danh mục (số, %), danh sách khoản (ngày giờ, danh mục, ghi chú, số tiền); nhúng font Be Vietnam Pro nên chữ có dấu hiện đúng; tự sang trang khi dài. 1.000 khoản xuất xong ≤ 10 giây trên Galaxy A13. [T: kiểm chữ trích từ PDF; M thời gian và hiển thị]

### F-43 · Mở khoá bằng vân tay / Face ID
- AC-134: Chỉ khi **đã bật PIN** và máy có sinh trắc học đã đăng ký, Cài đặt → Bảo mật hiện công tắc **"Mở khoá bằng vân tay"** (Android) / **"Mở khoá bằng Face ID"** hoặc "Touch ID" (iPhone, theo máy), mặc định tắt; bật phải xác thực sinh trắc một lần. Chưa bật PIN → không hiện; máy không có hoặc chưa đăng ký sinh trắc → công tắc tắt kèm lý do. Tắt PIN thì sinh trắc tự tắt. [T với lớp sinh trắc giả]
- AC-135: Khi bật, màn khoá tự mở hộp sinh trắc của hệ thống (chỉ sinh trắc mạnh, không cho mã khoá máy thay thế); đúng → vào app; huỷ, sai hoặc bị hệ thống khoá tạm → ở lại màn PIN, nhập PIN vẫn được; có nút sinh trắc để thử lại. Áp dụng cả khi vào từ widget và thông báo. "Quên mã" như AC-34. App không lưu dữ liệu sinh trắc (do hệ điều hành giữ). [T; M vân tay trên A13, Face ID trên iPhone qua TestFlight]

### F-44 · Dữ liệu, sao lưu, quyền của bản 2.0 (chung)
- AC-136: Cơ sở dữ liệu lên **schema 4** với migration giữ nguyên dữ liệu v3: khoản thêm giờ, nguồn, mã tin gốc; tài khoản thêm ngân hàng/ví và 4 số cuối; bảng mới cho mục tiêu tiết kiệm, khoản nợ, lần trả nợ, quy tắc danh mục, hàng chờ duyệt, ảnh hoá đơn (tên file). File `.vigon` mang mọi phần trên **trừ** hàng chờ duyệt, cấu hình nhập tự động (app nguồn đã chọn, hộp thư, mật khẩu, UID) và bản thân ảnh; file schema 1–3 vẫn khôi phục được; app cũ gặp file schema 4 thì từ chối như hiện nay. [T: test migration dựng DB v3, sao lưu/khôi phục có bảng mới]
- AC-137: Đổi tiền tệ (AC-21, D-029) quy đổi thêm số tiền mục tiêu tiết kiệm, khoản nợ, lần trả nợ (giữ số chính xác 6 lẻ, mục tiêu tối thiểu 1 đơn vị), trong cùng MỘT giao dịch cơ sở dữ liệu; đổi A→B→A cùng bảng tỉ giá về đúng số cũ. [T]
- AC-138: "Xóa toàn bộ dữ liệu" xoá thêm mục tiêu, khoản nợ, quy tắc, hàng chờ, cấu hình nhập tự động, mật khẩu ứng dụng (Keystore/Keychain), tắt đọc thông báo trong app (kèm hướng dẫn thu hồi quyền hệ thống) và tắt sinh trắc; **không** xoá ảnh trong thư viện ảnh — hộp xác nhận nói rõ. [T]
- AC-139: CSV thêm hai cột **Giờ** và **Nguồn** (Ghi tay / Thông báo / Email / Hoá đơn) ở **cuối** để giữ thứ tự cột cũ; vẫn đúng AC-30, AC-52. [T]
- AC-140 (thay danh sách quyền của AC-43 khi 2.0 được duyệt): `manifest_test` là danh sách cho phép đúng các quyền ở §5 "2.0"; dịch vụ đọc thông báo `exported` chỉ qua `BIND_NOTIFICATION_LISTENER_SERVICE`; iOS `Info.plist` có đúng 4 chuỗi `NS…UsageDescription` của §5 (vi, en) và không khoá nào khác; mã gọi mạng Dart chỉ ở hai chỗ (tỉ giá, IMAP), chỉ TLS. [T]
- AC-141: Mọi màn mới (Nhập tự động, giải thích quyền, hàng chờ, hộp thư, quy tắc, tiết kiệm, khoản nợ, thống kê, lịch, lọc, xuất) có mặt trong `g6_accessibility_test` (vùng chạm 48 dp, nhãn, tương phản, chữ 200%, sáng/tối) và mọi chữ trong `.arb` vi + en. [T; TalkBack/VoiceOver trên máy: M]

### Mặc định Claude chọn trong 3d (người dùng đổi được khi duyệt)
Từ kế hoạch (đã ghi ở đó): email kiểm khi mở app, kéo để làm mới, chạy nền ~mỗi giờ trên Android, iOS chỉ khi mở app (AC-107); sinh trắc chỉ khi có PIN (AC-134); khoản nợ không nhắc hạn (AC-120); "so với tháng trước" là % của chi và của thu (AC-122); lịch dùng lại `range_calendar.dart` (AC-129).
Phiên S0 thêm (kế hoạch chưa nói):
1. Khoản cũ và khoản sinh từ định kỳ không có giờ (AC-75).
2. 10 app nguồn mặc định đều được chọn sau khi cấp quyền (AC-80); app không tự gửi thông báo "đã ghi khoản" (AC-82).
3. Ghép đòi **cùng chiều tiền** (AC-94); "mỗi khoản ghép một lần" hiểu là một lần cho mỗi loại nguồn (AC-96, Q-04).
4. Chuyển nội bộ chỉ gộp hai khoản **tự nhập**, có lệnh "Tách thành chi và thu" (AC-97, AC-98).
5. Tin ngân hàng không có 4 số cuối → Account "<tên ngân hàng>"; Account ẩn vẫn nhận khoản tự nhập (AC-90, AC-91).
6. Tin lệch tiền tệ của app → hàng chờ, không tự quy đổi (AC-89).
7. Khoá nơi bán bỏ dấu, viết thường, bỏ dãy ≥ 4 chữ số (AC-100); hàng chờ tự xoá sau 30 ngày, không vào sao lưu (AC-102).
8. Email: chỉ Gmail/Yahoo/iCloud, tối đa 3 hộp thư, chỉ thư từ lúc kết nối, chỉ xem không đánh dấu đã đọc, dừng kiểm khi sai mật khẩu, kiểm khi mở app cách ≥ 15 phút (AC-103..AC-107).
9. Quét hoá đơn chỉ ở màn khoản chi; 1 ảnh mỗi khoản; ảnh JPEG cạnh dài ≤ 2048 px; xoá khoản không xoá ảnh (AC-109..AC-113).
10. Android gắn lại ảnh sau khôi phục bằng bộ chọn thư mục, không xin quyền đọc toàn bộ ảnh (AC-114, Q-06).
11. Hạn mục tiêu tiết kiệm là tuỳ chọn; một Account gắn tối đa một mục tiêu (AC-115).
12. Ô dashboard nằm dưới vòng; cột thu–chi 6 tháng; tháng theo luật D-028 (AC-122).
13. Cách chia cột của Thống kê theo kỳ (AC-124).
14. "Thông báo ngân sách" mặc định tắt; PIN tắt thì thông báo có số, PIN bật thì không số, không %, không tên danh mục (AC-127, AC-128).
15. Android dùng app máy ảnh của hệ thống qua intent, không xin quyền `CAMERA` (§5).

### Câu hỏi mở (người dùng quyết trước khi duyệt 2.0)
- **Q-01 — ML Kit gửi dữ liệu chẩn đoán về Google (mâu thuẫn lớn nhất).** Trang công bố dữ liệu chính thức của ML Kit (developers.google.com/ml-kit/android-data-disclosure, cập nhật 2026-07-15; bản iOS: …/ios-data-disclosure; đọc 2026-11-06) ghi: mọi tính năng ML Kit, **kể cả bản gói kèm**, thu thông tin máy (hãng, đời máy, bản hệ điều hành), thông tin app (tên gói, phiên bản), **mã theo bản cài**, số đo hiệu năng, cấu hình API, mã lỗi — "dùng cho chẩn đoán và thống kê sử dụng", gửi qua HTTPS về Google. Ảnh và chữ nhận được **không** nằm trong danh sách. Điều này trái với: D-002 ("không analytics"), khai Data safety "không thu thập" và App Privacy "Data Not Collected" (D8), chính sách mục 1 ("không có công cụ phân tích… của bên thứ ba"). Phương án: **(A)** giữ ML Kit (D-032) và đổi khai báo: Play "App info and performance → Diagnostics; Device or other IDs" thu thập (không chia sẻ), Apple "Diagnostics / Product Interaction, không liên kết danh tính", viết lại chính sách mục 1; mất lời hứa "không thu thập". **(B)** OCR khác không gửi gì: iOS dùng Vision của Apple (có sẵn trong hệ điều hành), Android dùng Tesseract gói kèm (to hơn, đọc kém hơn ML Kit) — đổi D-032. **(C)** Giữ ML Kit nhưng chỉ tải/khởi động khi người dùng bật "Quét hoá đơn" sau màn giải thích, khai báo như (A). Claude đề xuất **làm spike N3 cho cả ML Kit và Vision/Tesseract** rồi người dùng chọn; nếu cần quyết ngay: (A) — trung thực, ít việc nhất. **Chưa quyết thì không được nộp store**.
- **Q-02 — Khoản điều chỉnh số dư bị ghép bởi tin đến muộn.** Hai biến động tới lệch thứ tự (tin B có số dư tới trước tin A) → app tạo khoản "Điều chỉnh số dư" = A; khi tin A tới, theo AC-94 nó **ghép vào khoản điều chỉnh** (cùng Account, chiều, số tiền, ±2 giờ) nên không bị đếm hai lần, nhưng khoản đó giữ danh mục "Khác" và ghi chú "Điều chỉnh số dư". Đề xuất: ngoại lệ — khi tin ghép vào khoản **điều chỉnh do app tạo**, khoản lấy ghi chú, nơi bán, danh mục (theo quy tắc) của tin. Đồng ý không? (Lệch thứ tự quá 2 giờ thì vẫn đếm hai lần; xem §7.)
- **Q-03 — Khoản ghi tay ở "Tiền mặt" không ghép với tin ngân hàng.** Kế hoạch đòi "cùng Account"; người dùng hay ghi tay vào tài khoản mặc định ("Tiền mặt") trong khi tin vào "Vietcombank …1234" → ra hai khoản. Phương án: (A) giữ đúng kế hoạch, người dùng tự chọn đúng tài khoản khi ghi tay; (B) khi **lưu khoản ghi tay** mà trong ±2 giờ có khoản tự nhập cùng chiều, cùng số tiền ở bất kỳ Account nào thì hỏi "Có thể trùng với khoản Vietcombank …1234 12:02 · Gộp / Lưu riêng" (thêm AC); (C) ghép không cần cùng Account (rủi ro ghép nhầm cao). Claude đề xuất **(B)** — nó còn giải quyết chiều ngược lại: tin tới trước, người dùng ghi tay sau (kế hoạch chưa tính).
- **Q-04 — Hiểu "mỗi khoản chỉ ghép một lần".** Nếu hiểu đúng chữ (một lần duy nhất) thì khoản ghi tay đã ghép thông báo sẽ không ghép được email của cùng biến động → trùng. Claude viết AC-96 theo cách hiểu "một lần cho mỗi loại nguồn". Đồng ý không? (Kéo theo M0: khoản cần giữ được hai mã nguồn, không chỉ một cột `source`/`externalRef`.)
- **Q-05 — Đã có Account tay cho cùng ngân hàng.** Người dùng đã tự tạo "Vietcombank" với số dư → tin đầu tiên tạo thêm "Vietcombank …1234" (trùng). Đề xuất: lần tạo đầu hiện thẻ "Đã tạo Vietcombank …1234 · Gắn vào tài khoản có sẵn" (chọn Account cũ, gắn ngân hàng + 4 số cuối vào nó, xoá Account vừa tạo nếu còn trống). Đồng ý thì thêm AC.
- **Q-06 — Ảnh trên Android sau khi cài lại.** Android 11+ không cho app mới cài đọc ảnh do bản cài cũ ghi nếu không có quyền đọc ảnh; `READ_MEDIA_IMAGES` bị Google Play hạn chế (chính sách "Photo and video permissions": chỉ app cần truy cập ảnh thường xuyên). AC-114 chọn bộ chọn thư mục (SAF) — không quyền, nhưng người dùng phải tự chọn `Pictures/Ví Gọn` một lần. Android 7–9 (minSdk 24) cần `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion="28"`) để ghi album. Đồng ý cách này? iOS: nếu người dùng chỉ cho "quyền truy cập giới hạn" thì app chỉ thấy ảnh đã chọn → gắn lại thiếu; app báo số ảnh không tìm thấy.
- **Q-07 — Mẫu tin của nguồn chưa có mẫu.** Nguồn nào người dùng chưa gửi mẫu thật (AC-85) thì bộ đọc chưa kiểm được. Đề xuất: nguồn chưa có mẫu vẫn hiện trong danh sách nhưng chỉ dùng bộ đọc chung, tin không chắc vào hàng chờ; hoặc ẩn nguồn đó tới khi có mẫu. Chọn cách nào? Địa chỉ email gửi của từng ngân hàng cũng lấy từ mẫu người dùng gửi.
- **Q-08 — Thông báo ngân sách khi PIN tắt có hiện số không** (AC-128 mặc định có số, giống quy tắc widget D-016)? Hay luôn không số?
- **Q-09 — Dashboard** là màn chính mở rộng (mặc định) hay một tab/màn riêng? Mockup phiên #4 sẽ cần câu trả lời này.

### Ghi chú cho chính sách quyền riêng tư (KHÔNG sửa `docs/legal/privacy-policy.md` trong phiên này)
Khi 2.0 được duyệt, phiên viết lại chính sách (vi + en) cần sửa:
- Mục 1: câu "không có công cụ phân tích, theo dõi hay báo lỗi của bên thứ ba" (sai nếu giữ ML Kit, Q-01); "Kết nối mạng duy nhất" → thêm kết nối IMAP tới nhà cung cấp email người dùng chọn (dùng mật khẩu ứng dụng, chỉ đọc thư của địa chỉ ngân hàng), và kết nối chẩn đoán của ML Kit nếu chọn Q-01 (A)/(C).
- Mục 2: dữ liệu mới (giờ, nguồn, 4 số cuối tài khoản — không lưu số đầy đủ, nội dung tin đã che trong hàng chờ, quy tắc danh mục, tiết kiệm, nợ); đọc thông báo (chỉ Android, chỉ app đã chọn, OTP không lưu); mật khẩu ứng dụng trong Keystore/Keychain; ảnh hoá đơn trong thư viện ảnh — **ngoài** vùng riêng của app, ngoài khoá PIN, không trong sao lưu; sinh trắc do hệ điều hành giữ.
- Mục 3: file sao lưu không có ảnh, không có hộp thư/mật khẩu, không có hàng chờ; thêm Excel và PDF.
- Mục 4: bỏ câu "App không xin quyền … ảnh, camera"; thêm truy cập thông báo, máy ảnh (iOS), thư viện ảnh, vân tay/Face ID, thông báo ngân sách.
- Mục 5: link mở trang tạo mật khẩu ứng dụng của Google/Yahoo/Apple.
- Mục 7: gỡ app hoặc "Xóa toàn bộ dữ liệu" không xoá ảnh trong album "Ví Gọn".
- Mục 9: sinh trắc; thông báo ngân sách không số khi bật PIN.
- Mục 10: câu "Đây là bản đầu tiên" — nếu chính sách 1.x đã đăng trước 2.0 thì cần lịch sử thay đổi (theo D-035 sẽ không đăng trước, nên có thể giữ).

## 4. Ngoài phạm vi (cố ý KHÔNG làm)
Đã đưa vào phạm vi (giữ dòng gạch để biết lịch sử):
- ~~Bản iOS~~: vào phạm vi ngày 2026-11-04 theo PLAN-001 (người dùng duyệt), xem mục 5 "iOS" và D-011; chỉ icon đơn sắc (F-23) là riêng Android (D-022).
- ~~Ngân sách theo từng danh mục~~: bản 1.1 (F-20). ~~Nhắc nhở bằng thông báo~~: bản 1.2 (F-25). ~~Widget màn hình chính~~: bản 1.2 (F-26; iOS theo D-022).
- ~~Sao lưu lên Google Drive, Dropbox~~: chỉ làm dạng sao lưu một chiều vào thư mục người dùng chọn (F-24, Android và iOS); đồng bộ qua API vẫn ngoài phạm vi (bảng dưới).
- ~~Bản iOS của widget, sao lưu tự động, che nội dung ở màn đa nhiệm~~ (trước để việc riêng theo D-019): làm ngay bản 1 theo D-022 (2026-11-05) — WidgetKit + App Group, bộ chọn thư mục app Tệp + bookmark, lớp phủ native.
- ~~Mở khóa bằng vân tay hoặc khuôn mặt~~: bản 2.0 (F-43, chưa duyệt), chỉ khi đã bật PIN.
- ~~Đọc tin nhắn ngân hàng, quét hóa đơn, AI~~ (tách dòng 2026-11-06, D-030, D-032): **đọc thông báo app ngân hàng/ví** (chỉ Android, F-28), **email ngân hàng qua IMAP** (F-33) và **quét hoá đơn bằng ML Kit trên máy** (F-34) vào bản 2.0 (chưa duyệt). Đọc **SMS** và AI vẫn ngoài phạm vi (bảng dưới).

Vẫn ngoài phạm vi:
- Tài khoản người dùng, đăng nhập, máy chủ, đồng bộ đám mây.
- Nhiều tiền tệ cùng lúc (mỗi tài khoản một tiền tệ). (Quy đổi tỉ giá khi ĐỔI tiền tệ của app đã làm theo D-025, AC-21, AC-70..AC-72.)
- Quảng cáo, mua trong app, gói Pro, analytics, báo crash bằng SDK. (Bản 2.0: ML Kit có gửi dữ liệu chẩn đoán của chính nó — câu hỏi Q-01.)
- Đọc tin nhắn SMS (Google Play cấm với loại app này, D-030); AI/mô hình ngôn ngữ, gửi nội dung tin hay ảnh lên máy chủ để phân tích.
- Đọc thông báo trên iOS (hệ điều hành không cho phép).
- Gmail API / OAuth, Outlook/Hotmail, máy chủ IMAP tuỳ ý (D-031); gửi, xoá hay đánh dấu thư.
- Kết nối thẳng ngân hàng (open banking, API ngân hàng), thanh toán từ app.
- Nhắc hạn khoản nợ; khoản nợ làm đổi số dư tài khoản (F-36 chỉ là sổ ghi nhớ).

Các mục còn hiệu lực từ bản 1.1, 1.2 và lần gộp (cần người dùng làm hoặc quyết, vì phá cam kết hiện tại của app hoặc cần việc riêng):
| Mục | Vì sao chưa làm |
|-----|-----------------|
| Đồng bộ (kể cả đồng bộ hai chiều giữa nhiều máy) qua Google Drive, Dropbox bằng API | Cần mạng, đăng nhập OAuth và khóa API/ID khách (do người dùng tạo trong Google Cloud, Dropbox App Console); trái D-002; kéo theo quyền INTERNET, khai Data safety khác, chính sách quyền riêng tư viết lại, nhiều mục COMPLIANCE. F-24 chỉ sao lưu một chiều vào thư mục đã chọn |
| Widget hiện số tiền khi đang bật PIN | Làm lộ số liệu ngoài màn khóa, vô hiệu khóa PIN (D-016) |
| Nhiều tiền tệ cùng lúc | Thay đổi lớn mô hình dữ liệu (mỗi tài khoản một tiền tệ). Nguồn tỉ giá đã có từ D-025 |
| Gói Pro hoặc nguồn thu khác | Thanh toán trong app (Play Billing, StoreKit), COMPLIANCE C-01/C-02/T-01, thuế |
| Đọc SMS ngân hàng | Chính sách SMS/Call Log của Google Play chỉ cho app nhắn tin mặc định và vài nhóm ngoại lệ; thay bằng đọc thông báo app ngân hàng (F-28, D-030) |
| Gmail API (OAuth) | Phạm vi đọc thư là "restricted scope": phải qua đánh giá bảo mật CASA hằng năm; thay bằng IMAP + mật khẩu ứng dụng (D-031) |

## 5. Ràng buộc mobile
- Hệ điều hành: Android; minSdk theo mặc định của phiên bản Flutter được ghim (D-003); targetSdk theo yêu cầu Google Play hiện hành (COMPLIANCE P-06). iOS: xem mục "iOS" ngay dưới.
- Giao diện: theo bộ thiết kế đã duyệt `design/current/screens/` và `design/current/ui-spec.md` (token, chữ Be Vietnam Pro, icon Material Symbols Rounded), giống nhau trên hai nền tảng, chỉ khác ở chỗ hệ điều hành quyết định (D-010).
- Offline: toàn bộ app chạy không cần mạng; ~~không có tính năng nào gọi mạng~~ — từ D-025 (2026-11-05) chỉ một việc dùng mạng: tải bảng tỉ giá khi người dùng đổi tiền tệ (AC-72); không có mạng thì nhập tỉ giá tay (AC-71). Dữ liệu ghi xuống bộ nhớ máy ngay khi bấm Lưu.
  - **2.0 (chưa duyệt, D-031, D-032):** thêm việc mạng thứ hai — đọc thư ngân hàng qua IMAP/TLS tới Gmail, Yahoo, iCloud (AC-105), chỉ khi người dùng đã thêm hộp thư. Đọc thông báo, quét hoá đơn (nhận chữ), ghép, khớp số dư đều chạy offline. ML Kit tự gửi dữ liệu chẩn đoán khi có mạng (Q-01). Ghi chép, xem, thống kê, xuất file vẫn không cần mạng.
- Quyền thiết bị:
  - Android: `INTERNET` (D-025, chỉ tải tỉ giá khi đổi tiền tệ; quyền thường, không hộp thoại) và hai quyền phục vụ nhắc ghi chép F-25 (D-015): `POST_NOTIFICATIONS` (chỉ xin khi người dùng bật công tắc "Nhắc ghi chép", sau lời giải thích; hộp thoại hệ thống chỉ có từ Android 13) và `RECEIVE_BOOT_COMPLETED` (đặt lại lịch nhắc sau khi khởi động lại máy, không hộp thoại). KHÔNG `ACCESS_NETWORK_STATE`, KHÔNG cleartext HTTP, KHÔNG `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, KHÔNG quyền bộ nhớ: sao lưu/khôi phục dùng bảng chia sẻ và trình chọn file của hệ điều hành, sao lưu tự động dùng Storage Access Framework; widget không cần quyền. Kiểm bằng `test/manifest_test.dart` (AC-43) và `aapt2 dump permissions` bản release.
  - iOS: không có khóa `NS…UsageDescription`; chỉ xin quyền thông báo (hộp thoại của iOS) khi người dùng bật nhắc ghi chép, sau lời giải thích (AC-61). Chọn file khôi phục và chọn thư mục sao lưu tự động dùng trình chọn hệ thống (app Tệp), không cần quyền; widget (App Group) và lớp che F-22 cũng không cần quyền.
  - **2.0 (chưa duyệt) — Android**, thêm vào danh sách cho phép của `manifest_test` (AC-140):
    - Dịch vụ đọc thông báo (`NotificationListenerService`) khai `android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"` — đây **không** phải `uses-permission`; người dùng tự bật "Truy cập thông báo" trong cài đặt hệ thống sau màn giải thích (AC-79). Dịch vụ chỉ hệ thống gắn vào được.
    - `USE_BIOMETRIC` (F-43; quyền thường, không hộp thoại).
    - `INTERNET` (đã có) thêm mục đích thứ hai: IMAP tới ba máy chủ email (AC-105).
    - `POST_NOTIFICATIONS` (đã có) thêm mục đích: thông báo ngân sách (AC-127), vẫn chỉ xin khi bật công tắc. `RECEIVE_BOOT_COMPLETED` (đã có) thêm: đặt lại lịch kiểm thư nền (AC-107).
    - Máy ảnh: *(mặc định)* dùng app máy ảnh của hệ thống qua intent nên **không** khai `CAMERA` (nếu khai thì intent cũng đòi quyền); test cấm `CAMERA`. Nếu sau này cần máy ảnh trong app thì phải đổi SPEC.
    - Ảnh: ghi album bằng MediaStore (Android 10+ không cần quyền); Android 7–9 cần `WRITE_EXTERNAL_STORAGE` với `maxSdkVersion="28"` (Q-06). **Không** `READ_MEDIA_IMAGES`/`READ_EXTERNAL_STORAGE` (chọn ảnh bằng bộ chọn ảnh hệ thống; gắn lại sau khôi phục bằng bộ chọn thư mục).
    - Vẫn KHÔNG: `READ_SMS`/`RECEIVE_SMS`, `SCHEDULE_EXACT_ALARM`, `ACCESS_NETWORK_STATE`, cleartext, `FOREGROUND_SERVICE`.
  - **2.0 (chưa duyệt) — iOS**, thêm đúng 4 chuỗi mục đích (vi + en, viết trung thực, S-40): `NSCameraUsageDescription` (chụp hoá đơn), `NSPhotoLibraryUsageDescription` (tạo album "Ví Gọn", xem và gắn lại ảnh hoá đơn — cần quyền đọc/ghi), `NSPhotoLibraryAddUsageDescription` (lưu ảnh hoá đơn), `NSFaceIDUsageDescription` (mở khoá bằng Face ID). Quyền ảnh/máy ảnh chỉ xin lần đầu dùng tính năng; từ chối thì tính năng đó báo cách bật lại, phần còn lại của app dùng bình thường. Không đọc được thông báo (F-28 không có trên iOS). Kết nối IMAP theo ATS mặc định (TLS).
- Màn hình: chiều rộng nhỏ nhất 360 dp; chỉ màn hình dọc.
- Hiệu năng/pin: không có service hay job chạy nền liên tục. Thông báo nhắc do hệ điều hành đặt lịch (F-25); sao lưu tự động tối đa một lần mỗi ngày, chạy lúc app ra nền trên Android, khi mở/quay lại app trên iOS (F-24). Ngưỡng ở 5b.
  - **2.0 (chưa duyệt):** dịch vụ đọc thông báo (F-28) do hệ thống gắn và gọi khi có thông báo, không tự chạy vòng lặp; app chỉ khởi động Dart nền khi có tin của app nguồn. Kiểm thư nền Android khoảng mỗi giờ (AC-107), lịch không chính xác, mỗi lần chỉ tải thư mới của địa chỉ ngân hàng.

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
- Dung lượng: file APK cho một kiến trúc (arm64) ≤ 25 MB. **2.0 (chưa duyệt):** ML Kit nhận chữ gói kèm (mô hình chữ Latin nằm trong app) cùng các gói Excel/PDF/biểu đồ làm app to ra; đề xuất nâng ngưỡng arm64 lên **≤ 35 MB**, iOS ghi số đo ở spike N3 rồi mới đặt ngưỡng (gói ML Kit iOS lớn hơn Android). Đo bằng `flutter build apk --analyze-size --target-platform android-arm64`.
- Bản 2.0 thêm (đề xuất, người dùng chỉnh khi duyệt): một tin biến động từ lúc hệ thống nhận thông báo tới lúc khoản có trong cơ sở dữ liệu ≤ 10 giây khi app đang chạy, ≤ 1 phút khi app đóng (trừ khi hệ điều hành hoãn); bộ đọc xử lý một tin ≤ 50 ms; ghép và khớp số dư với 10.000 khoản ≤ 200 ms.
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
- **Bản 2.0 (chưa duyệt):**
  - Bảng mới trong SQLite (schema 4, AC-136): mục tiêu tiết kiệm, khoản nợ + lần trả, quy tắc danh mục, hàng chờ duyệt, ảnh hoá đơn (chỉ tên file); khoản thêm giờ và nguồn; tài khoản thêm ngân hàng/ví + **4 số cuối** (không bao giờ lưu số tài khoản/thẻ đầy đủ, AC-88).
  - **Mật khẩu ứng dụng IMAP** và địa chỉ hộp thư: chỉ trong Keystore (Android) / Keychain (iOS) qua `SecretStore` như mật khẩu sao lưu tự động; không vào cơ sở dữ liệu, file sao lưu, log (AC-104). Cấu hình nhập tự động (app nguồn đã chọn, UID thư đã đọc) là cài đặt theo máy, không theo file sao lưu.
  - **Thông báo và thư ngân hàng chỉ được đọc trên máy**: nội dung xử lý trong bộ nhớ rồi bỏ; chỉ tin vào hàng chờ duyệt mới được lưu và đã che số (AC-88), tự xoá sau 30 ngày; OTP không bao giờ lưu (AC-87). Thư không bị đánh dấu đã đọc hay sửa trên máy chủ (AC-106). Nhà phát triển không nhận gì.
  - **Ảnh hoá đơn nằm ngoài app**: album "Ví Gọn" trong thư viện ảnh của máy (D-033) — app khác có quyền ảnh và người cầm máy xem được, **không** được khoá PIN che, **không** nằm trong file sao lưu `.vigon`, có thể vào sao lưu ảnh của hệ thống/Google Photos/iCloud Photos theo cài đặt của người dùng. Nói rõ trong app (AC-112) và chính sách.
  - Nhận chữ hoá đơn chạy trên máy; ảnh và chữ không gửi đi. ML Kit gửi dữ liệu chẩn đoán của chính nó về Google (Q-01) — khai báo "không thu thập" phải xem lại trước khi phát hành.
  - Sinh trắc học: app chỉ nhận kết quả đúng/sai từ hệ điều hành, không lưu hay thấy dữ liệu sinh trắc.

## 7. Rủi ro và điều chưa biết
- Pháp lý: chức năng giống Monefy là được, nhưng tên, icon, giao diện, mô tả store không được sao chép; rà lại trước khi phát hành.
- Mất dữ liệu: không có đám mây nên mất máy là mất dữ liệu nếu người dùng chưa xuất file. Giảm rủi ro: xuất sao lưu tay trong Cài đặt; bật sao lưu tự động (F-24) vào thư mục của Google Drive/Dropbox (Android) hoặc iCloud Drive/Google Drive (iOS). Dữ liệu app không nằm trong sao lưu hệ thống trên cả hai nền tảng (D-021), nên nếu thư mục sao lưu tự động chỉ nằm trên máy thì mất máy là mất cả file; iOS cảnh báo khi thư mục không ở iCloud Drive. Trên iOS sao lưu tự động chỉ chạy khi mở app → người ít mở app có bản sao lưu cũ hơn.
- Quên PIN là mất quyền vào dữ liệu (AC-34); phải nói rõ khi bật khóa. Quên mật khẩu file sao lưu là không mở được file (F-21, F-24).
- Máy phát triển là Windows: không build hay thử iOS cục bộ, mọi lỗi riêng iOS chỉ lộ trên CI hoặc TestFlight (D-011). Chưa có iPhone thật.
- Tài khoản Google Play cá nhân mới cần closed test 12 người trong 14 ngày (COMPLIANCE P-09).
- Tuổi người dùng: người dưới 18 có thể dùng; app không thu dữ liệu và không có tương tác xã hội. Cần người dùng quyết có tích hợp Play Age Signals / Declared Age Range hay không (COMPLIANCE D-12).
- Bán ở EU: CRA áp dụng cho app kể cả miễn phí nếu là hoạt động thương mại; chưa rõ app miễn phí của cá nhân có thuộc phạm vi không, cần luật sư xác nhận trước khi mở bán ở EU.
- **Bản 2.0 (chưa duyệt):**
  - **Mẫu tin ngân hàng đổi:** ngân hàng/ví đổi câu chữ thông báo hoặc email bất cứ lúc nào → bộ đọc bỏ sót hoặc đẩy vào hàng chờ. Giảm: bộ đọc chung làm lưới đỡ, tin không chắc vào hàng chờ chứ không lưu sai, mẫu test từ tin thật; mỗi bản cập nhật app phải kèm mẫu mới. Người dùng không cập nhật app thì lỗi kéo dài.
  - **Google Play duyệt quyền truy cập thông báo:** app tài chính đọc thông báo của app khác dễ bị hỏi khi duyệt; cần màn giải thích rõ (AC-79), mô tả store và video/ghi chú cho người duyệt nêu mục đích; đọc lại chính sách "Permissions and APIs that Access Sensitive Information" và "User Data" ngày nộp (COMPLIANCE P-13). Bị từ chối → phát hành không có F-28 (tắt bằng cờ), không chặn cả bản.
  - **ML Kit và khai báo dữ liệu:** xem Q-01; nộp store với khai "không thu thập" trong khi ML Kit gửi chẩn đoán là khai sai (Play có thể gỡ app).
  - **iOS không đọc được thông báo:** người dùng iPhone chỉ có email + quét hoá đơn; mô tả App Store không được nhắc tính năng đọc thông báo (2.3.1).
  - **Ghép nhầm / sót:** hai khoản thật cùng giá cùng tài khoản trong 2 giờ mà một khoản đã ghi tay không có nguồn → tin của khoản thứ hai ghép nhầm vào khoản ghi tay (mất một khoản). Chuyển nội bộ ghép nhầm khi tình cờ có tiền vào cùng số ở tài khoản khác → có lệnh "Tách" (AC-98). Tin tới lệch thứ tự quá 2 giờ có thể làm khoản điều chỉnh số dư đếm hai lần (Q-02).
  - **Khoản điều chỉnh số dư** vào tổng chi/thu và ngân sách (D-034) → một tin lương bị sót sẽ hiện thành "Thu khác" lớn; người dùng sửa danh mục được.
  - **Chạy nền bị hãng máy chặn:** Samsung "Ứng dụng ngủ", tiết kiệm pin có thể ngắt dịch vụ đọc thông báo hoặc hoãn kiểm thư; giảm: xử lý bù khi mở app (AC-82), hướng dẫn tắt tối ưu pin trong màn cài đặt; kiểm trên Galaxy A13.
  - **Mật khẩu ứng dụng:** Google/Yahoo/Apple có thể siết hoặc bỏ mật khẩu ứng dụng cho IMAP; Gmail đòi bật xác minh 2 bước mới tạo được. Mất kênh email thì vẫn còn thông báo (Android) và nhập tay.
  - **OCR tiếng Việt và dung lượng:** chưa biết ML Kit đọc hoá đơn tiếng Việt có dấu tốt đến đâu và build iOS simulator trên CI (lát cắt arm64) có chạy không → spike N3 trước khi làm; app to thêm (§5b).
  - **Ảnh ngoài app:** người dùng có thể tưởng ảnh được khoá PIN hay sao lưu cùng dữ liệu; Android cài lại phải chọn lại thư mục ảnh (Q-06).
  - **Phạm vi lớn:** 18 tính năng mới trong 2 phiên điều phối (#3, #4); vượt sức thì cắt theo thứ tự ưu tiên người dùng chọn, ghi vào DECISIONS (D-035).

## 8. Tiêu chí hoàn thành bản 1 (Android + iOS)
- F-01 tới F-26 đạt toàn bộ AC áp dụng cho từng nền tảng (mục 5 "iOS": F-23 chỉ Android; F-22, F-24, F-26 trên iOS theo gạch "iOS (D-022)" của từng F).
- Android: biên bản [M] trên ít nhất một máy Android thật. iOS: biên bản [M] trên iPhone thật (TestFlight) cho các AC áp dụng iOS trước khi phát hành iOS; CI iOS (`ios.yml`) xanh trên nhánh `main`.
- `flutter analyze` không lỗi, `flutter test` đạt.
- `docs/COMPLIANCE.md` không còn dòng "chưa" ở các mục áp dụng cho Android, iOS (P-01 tới P-05) và các thị trường mở bán.
- Đã chạy closed test theo P-09 và sửa lỗi chặn trước khi mở bán trên Play.

## 8b. Tiêu chí hoàn thành bản 2.0 (chưa duyệt) — điều kiện để phát hành (D-035: làm hết rồi mới phát hành)
- Mọi tiêu chí mục 8 vẫn đúng, cộng: F-27 tới F-44 đạt toàn bộ AC áp dụng cho từng nền tảng (F-28 chỉ Android; AC nhắc "Android"/"iOS" theo chữ của AC).
- Mọi câu hỏi Q-01..Q-09 đã có câu trả lời và đã sửa AC theo đó; dòng "Đã duyệt 2.0" có ngày.
- Test tự động có đủ: bộ đọc với từng mẫu tin của từng nguồn có mẫu; ghép ±2 giờ (có khoản ghi tay, hai khoản thật cùng giá, qua nửa đêm, khoản không giờ); ghép chuyển nội bộ và tách; tự tạo tài khoản; khớp số dư; migration v3 → v4; sao lưu/khôi phục có bảng mới và file cũ; tiết kiệm không đổi tổng thu/chi; nợ không đụng số dư; ngưỡng 80% và thông báo mỗi mốc một lần; quy đổi tiền tệ các bảng mới; manifest/Info.plist đúng §5.
- `flutter analyze` sạch, `flutter test` đạt; CI Android + iOS xanh, có bước kiểm riêng build ML Kit trên iOS.
- Biên bản [M] trên Galaxy A13: bật quyền thông báo, chuyển một khoản tiền thật nhỏ → khoản tự hiện đúng tài khoản (app đang chạy và app đã đóng); email IMAP đọc được thư ngân hàng (người dùng tự nhập mật khẩu ứng dụng); chụp hoá đơn → số tiền điền sẵn, ảnh vào album; khôi phục trên máy cài mới → ảnh gắn lại; vân tay; thông báo ngân sách thật. Claude chỉ dùng adb sau khi hỏi người dùng. Ghi vào `notes/` và `docs/TESTING.md`.
- iOS: [M] trên iPhone qua TestFlight cho quét hoá đơn, album ảnh, Face ID, email, thông báo ngân sách trước khi phát hành iOS.
- `docs/COMPLIANCE.md` và `docs/SECURITY.md` không còn dòng "chưa" ở các mục 2.0 (P-02, P-10, P-13..P-15, S-08, S-09, D-11…); chính sách quyền riêng tư đã viết lại theo ghi chú cuối 3d và người dùng duyệt câu chữ.
