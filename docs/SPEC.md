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
- **2.0** (duyệt 2026-11-06): F-27..F-42, AC-74..AC-126 (mục 3d), D-030..D-035; sửa §4, §5, §5b, §6, §7, thêm §8b (các chỗ ghi "2.0"). Viết 2026-11-06 theo kế hoạch `notes/2026-11-06-ke-hoach-mo-rong.md`, thu hẹp cùng ngày theo quyết định của người dùng (chỉ nhập khoản chi từ email MB Bank qua hàng đợi; bỏ đọc thông báo, quét hoá đơn, ảnh hoá đơn).
- **D-037** (người dùng chốt 2026-11-09): đa tiền tệ — thêm mục **3e** (F-43, AC-127..AC-135), thay cách hiểu "một tiền tệ toàn app" của F-07 và các chỗ quy đổi toàn bộ khi đổi tiền tệ (AC-70, AC-71 hết hiệu lực).
<!-- Dòng duyệt bản 2.0: khi người dùng duyệt, đổi dòng trên thành "**2.0** (duyệt YYYY-MM-DD): …" và ghi ngày vào dòng "Đã duyệt 2.0" dưới đây. Chưa có ngày thì Claude không viết code cho F-27..F-42 (riêng phiên M0 schema cũng chờ dòng này). -->
Đã duyệt 2.0: 2026-11-06

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
- AC-21: Lần mở đầu tiền tệ là **USD** — ~~tự chọn theo vùng của máy (Việt Nam → VND)~~ sửa 2026-11-06 theo D-036 (không đoán theo máy); đổi được trong Cài đặt từ danh sách mã ISO 4217. ~~App dùng MỘT tiền tệ cho toàn bộ dữ liệu.~~ **Sửa 2026-11-09 theo D-037:** app dùng **đa tiền tệ** — mỗi bản ghi có tiền tệ riêng, số dẫn xuất quy về **Tiền tệ chính** (mục 3e, F-43). Phần quy đổi toàn bộ dưới đây chỉ còn giá trị lịch sử: ~~Không quy đổi~~ — viết lại 2026-11-05 theo D-025: đổi sang tiền tệ khác thì **luôn quy đổi mọi số tiền** (khoản thu chi và chuyển tiền, khoản định kỳ, số dư ban đầu tài khoản, hạn mức danh mục, ngân sách tháng) theo tỉ giá "1 tiền cũ = X tiền mới", trong MỘT giao dịch: ~~làm tròn half-up tới đơn vị nhỏ nhất của tiền mới, số phải > 0 thì tối thiểu 1 đơn vị~~ — viết lại 2026-11-06 theo D-029: quy đổi từ **số chính xác 6 chữ số lẻ** (ẩn) của mỗi số tiền, giữ số chính xác mới, còn số hiện và cộng tổng làm tròn half-up tới đơn vị nhỏ nhất của tiền mới (0,00385 US$ hiện 0,00 US$); khoản và khoản định kỳ có thể thành 0, ngân sách tháng và hạn mức danh mục tối thiểu 1 đơn vị; có số nào vượt 10^12 thì báo lỗi và không đổi gì; lỗi giữa chừng thì không đổi gì. Chọn lại đúng tiền tệ đang dùng thì không làm gì. [T: `test/data/currency_conversion_test.dart`]
- AC-70 (D-025; **hết hiệu lực 2026-11-09 theo D-037** — xem AC-127..AC-135): Chọn tiền tệ khác → hộp "Quy đổi sang X?" hiện "Đang tải tỉ giá…" rồi: tỉ giá hai chiều ("1 VND = 0,0000385 USD", "1 USD = 25.974 VND"), ngày cập nhật và dòng ghi công nguồn "Rates By Exchange Rate API" (chạm mở exchangerate-api.com), ví dụ một số tiền trước → sau (khoản mới nhất, không có thì ngân sách), cảnh báo làm tròn, không hoàn tác tự động, gợi ý xuất sao lưu trước; nút "Hủy" (không đổi gì, kể cả khi đang tải) và "Quy đổi"; "Dùng tỉ giá khác" chuyển sang ô nhập tay. Xong thì báo "Đã quy đổi mọi số tiền sang X"; màn, widget cập nhật theo. [T: file test của D-025 đã xóa 2026-11-09; thay bằng `test/data/rate_repository_test.dart`]
- AC-71 (D-025; **hết hiệu lực 2026-11-09 theo D-037** — xem AC-127..AC-135): Mất mạng, hết giờ chờ, dịch vụ lỗi hoặc nguồn không có tỉ giá cho cặp đó → hộp báo rõ lý do ("Không tải được tỉ giá" / "Không có tỉ giá từ A sang B") và ô "1 A = ? B" để nhập tay (đổi chiều được; điền sẵn tỉ giá gần nhất đã tải hoặc đã nhập, kèm ngày, nếu có); "Thử lại" (khi lỗi mạng/dịch vụ), "Tiếp tục" sang hộp xác nhận, hoặc "Hủy". Tỉ giá ≤ 0 hoặc sai → báo lỗi dưới ô. [T]
- AC-73 (D-029; **hết hiệu lực 2026-11-09 theo D-037** — xem AC-127..AC-135): Đổi A → B → A với **cùng một bảng tỉ giá** (tỉ giá chéo tính bằng phân số, B→A là nghịch đảo đúng của A→B) thì mọi số tiền về đúng số cũ (vd 50.000 ₫ → 1,93 US$ → 50.000 ₫; 100 ₫ → 0,00 US$ → 100 ₫), kể cả chuỗi nhiều tiền tệ quay về tiền gốc. Đổi lại vào ngày khác (tỉ giá khác) thì số khác theo biến động tỉ giá thật. Sửa tay số tiền sau khi đổi thì số gõ là số chính xác mới. [T: `test/data/currency_conversion_test.dart` nhóm "số tiền chính xác 6 lẻ", `test/data/exact_amount_storage_test.dart`]
- AC-72 (D-025; sửa 2026-11-09 theo D-037; bản 2.0 chưa duyệt sẽ thêm việc mạng thứ hai — IMAP, AC-80, D-031): Mạng chỉ dùng cho việc tải bảng tỉ giá công khai qua HTTPS (`GET https://open.er-api.com/v6/latest/USD`, URL cố định, không gửi dữ liệu người dùng hay tiền tệ đang dùng), tự kiểm tra khi mở app/quay lại tối đa 1 lần/ngày và khi người dùng bấm "Cập nhật ngay"; không SDK, không analytics; nguồn miễn phí, không khóa API, ghi công đúng điều khoản. [T: `test/manifest_test.dart`, `test/data/exchange_rate_source_test.dart`]
- Màn Tỷ giá và hộp ghi đè đạt S-50 ở chữ 200%, sáng/tối (test trợ năng `hifi_d5_accessibility_test.dart`); gọi mạng thật trên máy thật: [M] CHƯA kiểm.
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
- AC-36: Có tiếng Việt và tiếng Anh, **mặc định English** (D-036; ~~theo ngôn ngữ máy~~ — không còn lựa chọn "Theo máy", Cài đặt chỉ có English / Tiếng Việt), đổi được trong Cài đặt; mọi chuỗi giao diện nằm trong file dịch, không viết thẳng trong code. [T]
- AC-37: Mọi nút chạm tối thiểu 48×48 dp; nút "−", "+" và bàn phím số nằm ở nửa dưới màn hình. [M]
- AC-38: Với cỡ chữ hệ thống 200%, các màn chính không bị cắt chữ hoặc chồng lên nhau. [M]
- AC-39: Bật TalkBack thì đọc được tên mọi nút, tên và số tiền từng danh mục trên biểu đồ (biểu đồ có bảng thay thế cho trình đọc màn hình). [M]
- AC-40: Tương phản chữ đạt tối thiểu 4,5:1 (chữ thường) và 3:1 (chữ lớn, icon) ở cả hai giao diện sáng và tối. [M]

### F-13 · Quyền riêng tư và thông tin pháp lý trong app
- AC-41: Màn "Giới thiệu" có: phiên bản, liên kết chính sách quyền riêng tư, kênh báo lỗi bảo mật (email), danh sách giấy phép nguồn mở (màn license của Flutter). [M]
- AC-42: Mục "Xóa toàn bộ dữ liệu" trong Cài đặt xóa hết dữ liệu trong app sau xác nhận hai bước; mở lại app thì như mới cài. [T]
- AC-43 (bản 2.0 chưa duyệt sẽ thay danh sách quyền bằng AC-125): ~~App không có quyền INTERNET trong manifest của bản phát hành~~ (sửa 2026-11-05 theo D-025): manifest bản phát hành chỉ có `INTERNET` (để tải tỉ giá, AC-72) và hai quyền nhắc ghi sổ; app không gửi dữ liệu người dùng đi đâu. [T: kiểm manifest nguồn và manifest release đã gộp]

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

## 3c. Bản 1.2: sao lưu tự động, nhắc ghi sổ, widget (F-24..F-26)
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
  - AC-59 trên iOS (sửa theo D-026): iOS không cho app đã đóng tự chạy đúng giờ, nên đúng giờ đã chọn app hiện **thông báo cục bộ** lặp hằng ngày "Đến giờ sao lưu Ví Gọn. Chạm để sao lưu." (`autoBackupNotificationBody`, không số liệu, mã thông báo 1002 khác nhắc ghi sổ 1001); chạm vào hoặc mở/quay lại app bất kỳ lúc nào sau giờ đó thì sao lưu chạy (không chạy lúc ra nền vì iOS có thể dừng app giữa chừng). Quyền thông báo xin khi bật hoặc đổi giờ nếu chưa có, sau lời giải thích (`autoBackupNotifyTitleIos`/`autoBackupNotifyBodyIos`, S-40); bị từ chối thì báo nhẹ (`autoBackupNotifyDeniedIos`), sao lưu tự động vẫn bật và vẫn bù khi mở app. Cùng luật mỗi mốc một lần, chỉ khi dữ liệu đổi, tên file và giữ 2 file như Android. Chú thích: `autoBackupRunsOnOpenIos` ("…Đúng giờ bạn chọn, Ví Gọn gửi thông báo; chạm vào hoặc mở app để sao lưu. Lỡ giờ thì sao lưu bù khi bạn mở app…"). [T: `test/data/hifi_d4_auto_backup_ios_test.dart`, `test/features/auto_backup_schedule_test.dart` nhóm "iOS: thông báo hằng ngày", `test/features/auto_backup_ui_test.dart` nhóm "iOS (D-026, S-40)"; M: thông báo thật trên iPhone — TestFlight]
  - Cảnh báo thư mục: thư mục không nằm trên iCloud Drive (`AutoBackupState.folderInICloud != true`) thì hiện `autoBackupLocalFolderWarningIos` ("Thư mục này có thể chỉ nằm trên iPhone…"), vì dữ liệu app không nằm trong sao lưu iPhone (D-021) và iOS không phân biệt được "Trên iPhone" với Google Drive/Dropbox. [T]
  - AC-60 trên iOS: bookmark mất hoặc bị thu hồi, thư mục bị xóa → cùng trạng thái lỗi và nút "Chọn lại thư mục" như Android; tắt thì xóa mật khẩu khỏi Keychain và xóa bookmark (`releaseFolder`), không xóa file đã ghi. [T: cùng file test, "lỗi thư mục iOS (bookmark mất / bị thu hồi)…"]
  - [M] trên iPhone (TestFlight): bộ chọn thư mục mở được; ghi file thật vào iCloud Drive và Google Drive; file iCloud chưa tải về vẫn được đếm/dọn đúng 2 file; bookmark còn hiệu lực sau khi khởi động lại máy; thu hồi quyền/xóa thư mục → báo lỗi, không crash; file ghi trên iPhone khôi phục được trên Android và ngược lại.

### F-25 · Nhắc ghi sổ hằng ngày (Android và iOS)
- AC-61: Cài đặt có nhóm **"Nhắc ghi sổ"** gồm công tắc **"Nhắc ghi sổ hằng ngày"** (mặc định tắt) và **giờ nhắc** (mặc định 20:00, chọn bằng bộ chọn giờ của hệ thống). Bật công tắc thì trước tiên hiện một lời giải thích ngắn ("Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc bạn ghi lại chi tiêu. Thông báo không chứa số liệu.") rồi mới xin quyền thông báo của hệ điều hành (Android 13 trở lên; iOS: hộp thoại cho phép thông báo của iOS) đúng lúc này; bị từ chối thì công tắc về tắt và hiện hướng dẫn mở cài đặt hệ thống. Không xin quyền ở chỗ nào khác. [T cho logic; M cho thông báo thật]
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

## 3d. Bản 2.0: nhập khoản chi từ email MB Bank và bộ tài chính đầy đủ (F-27..F-42) — CHƯA DUYỆT
Người dùng duyệt **kế hoạch** ngày 2026-11-06 (`notes/2026-11-06-ke-hoach-mo-rong.md`) rồi **thu hẹp** cùng ngày sau khi đọc bản nháp đầu của mục này (trả lời Q-01..Q-09; D-030..D-034 viết lại). Chỗ kế hoạch và quyết định thu hẹp khác nhau thì theo quyết định thu hẹp. Mục này là đặc tả để duyệt trước khi có code. Bổ sung cho mục 3, 3b, 3c, không thay thế; chỗ nào sửa AC cũ thì ghi rõ. Quyết định: D-030 (nhập tự động chỉ qua email, chỉ MB Bank, qua hàng đợi), D-031 (IMAP + mật khẩu ứng dụng), D-032 (không quét hoá đơn, không ảnh hoá đơn, không đọc thông báo — giữ "không thu thập"), D-033 (luật nhập email MB), D-034 (Tổng quan là màn riêng; thông báo ngân sách chỉ %), D-035 (5 phiên điều phối, làm hết rồi mới phát hành).

Ràng buộc chung của 3d:
- **Cả Android và iOS**, cùng tính năng (nhập từ email chạy nền mỗi giờ chỉ có trên Android, AC-82).
- **Không thêm SDK nào gửi dữ liệu đi**; Data safety giữ "không thu thập, không chia sẻ", App Privacy giữ "Data Not Collected" (D-032). Việc mạng thứ hai là IMAP tới hộp thư của chính người dùng (D-031).
- **Số tiền chính xác (D-029)** cho mọi cột tiền mới (mục tiêu tiết kiệm, khoản nợ, lần trả nợ): có cột `*Micro` ẩn, quy đổi khi đổi tiền tệ (AC-122). Khoản từ email lấy đúng số tiền trong email.
- Mọi chữ trong `.arb` (vi, en); mọi màn mới đạt S-50 như các màn cũ (AC-126).
- Từ dùng theo `CONTEXT.md`: "khoản" (Entry), "email biên lai" (Bank receipt email), "số tham chiếu" (Reference number), "ghép" (Match), "hàng đợi" (Import queue). Không dùng chữ "giao dịch" cho khoản (trừ khi trích tên trường của email MB, vd "Loại giao dịch").
- Mục đánh dấu *(mặc định)* là chỗ quyết định chưa nói và Claude tự chọn; người dùng đổi được khi duyệt (tổng hợp ở cuối mục).

### F-27 · Giờ của khoản
- AC-74: Màn Nhập/Sửa khoản (cả chi, thu, chuyển tiền) có ô **Giờ** `HH:mm` mở bộ chọn giờ hệ thống (24 giờ hay 12 giờ theo máy). Khoản mới mặc định là giờ lúc mở màn nhập; đổi ngày không đổi giờ; lưu thì giữ đúng giờ đã chọn. [T]
- AC-75: Khoản có từ trước schema 4 và khoản sinh từ khoản định kỳ *(mặc định)* **không có giờ**: dòng khoản không hiện giờ; màn sửa hiện ô Giờ "Chưa đặt giờ"; lưu mà không đặt thì vẫn không có giờ. Khi ghép (F-31) khoản không giờ được coi là **12:00** của ngày đó. [T]
- AC-76: Trong một ngày, Các khoản xếp khoản có giờ theo giờ mới nhất trước, rồi tới khoản không giờ (theo thứ tự tạo, mới trước). Dòng khoản có giờ hiện giờ (vd "12:02") cạnh tên tài khoản. [T]
- AC-77: Giờ đi theo file sao lưu `.vigon`; file schema 1–3 vẫn khôi phục được (mọi khoản không giờ). CSV, Excel có cột Giờ (trống nếu không có; AC-124, AC-117). [T]

### F-28 · Hộp thư email (IMAP + mật khẩu ứng dụng, D-031)
- AC-78: Cài đặt → nhóm **"Nhập tự động"** có mục **"Nhập từ email ngân hàng"** (cùng nhóm với mục "Khoản chờ chọn danh mục"). Lần đầu mở: màn giải thích nói app đọc email biên lai của ngân hàng trong hộp thư bạn thêm, **chỉ trên máy**, không gửi nội dung đi đâu, không sửa hay xoá thư, cần **mật khẩu ứng dụng** (không phải mật khẩu chính), và hiện chỉ hỗ trợ **MB Bank**. "Thêm hộp thư": chọn **Gmail, Yahoo hoặc iCloud** *(mặc định: chỉ ba nhà cung cấp này)*, nhập địa chỉ và mật khẩu ứng dụng, có hướng dẫn từng bước và nút mở trang tạo mật khẩu ứng dụng của nhà cung cấp (trình duyệt ngoài app). App đăng nhập thử ngay và báo "Đã kết nối" hoặc lỗi rõ: "Sai địa chỉ hoặc mật khẩu ứng dụng", "Hộp thư chưa bật IMAP", "Không có mạng". Tối đa 3 hộp thư *(mặc định)*. [T với máy chủ IMAP giả; M Gmail thật — người dùng tự nhập mật khẩu]
- AC-79: Địa chỉ hộp thư và mật khẩu ứng dụng **chỉ** lưu trong Keystore (Android) / Keychain (iOS); không nằm trong cơ sở dữ liệu, file sao lưu, CSV, Excel, PDF hay log. Xoá hộp thư hoặc "Xóa toàn bộ dữ liệu" → xoá khỏi Keystore/Keychain. Khôi phục sang máy khác không mang hộp thư theo. [T]
- AC-80: App chỉ kết nối IMAP qua TLS ngay từ đầu (cổng 993) tới đúng `imap.gmail.com`, `imap.mail.yahoo.com`, `imap.mail.me.com`; chứng chỉ kiểm theo hệ thống; không STARTTLS, không bản rõ, không máy chủ nào khác. [T]
- AC-81: App chỉ **tìm trên máy chủ** thư trong INBOX có địa chỉ gửi nằm trong danh sách địa chỉ của MB Bank (lấy từ email mẫu thật người dùng gửi; người dùng không phải nhập) và *(mặc định)* nhận từ lúc kết nối hộp thư trở đi; thư khác không được tải. Thư được mở ở chế độ chỉ xem (không đánh dấu đã đọc, không xoá, không chuyển, không gửi thư). Thân thư chỉ được đọc như chữ (bỏ HTML, không tải ảnh hay link ngoài, không mở file đính kèm, bỏ thư > 256 KB), xử lý trong bộ nhớ rồi bỏ, không lưu. App nhớ thư cuối đã đọc (UID) để không tải lại. [T]
- AC-82: App kiểm thư khi mở hoặc quay lại app (cách lần trước ≥ 15 phút *(mặc định)*), khi người dùng kéo để làm mới ở Hàng đợi hoặc màn hộp thư, và **trên Android chạy nền khoảng mỗi giờ** khi app đóng (lịch không chính xác, không quyền báo thức chính xác, đặt lại sau khởi động lại máy — dùng lại cơ chế chạy nền của sao lưu tự động). iOS chỉ kiểm khi mở/quay lại app; màn cài đặt iOS ghi rõ điều này. Lỗi đăng nhập → dừng kiểm tự động hộp thư đó tới khi người dùng nhập lại mật khẩu *(mặc định, tránh bị nhà cung cấp khoá)*. Màn hộp thư hiện "Lần kiểm cuối: …", lỗi nếu có, và "N email MB không đọc được" (AC-85). [T cho lịch và trạng thái; M chạy nền thật trên A13]
- AC-83: Danh sách ngân hàng hỗ trợ chỉ gồm ngân hàng **đã có email mẫu thật và test đạt**; bản đầu chỉ **MB Bank**. Ngân hàng chưa có mẫu thì **không hiện** ở đâu trong app. Thêm ngân hàng sau này là thêm mẫu + test + một bản cập nhật app. [T]

### F-29 · Đọc email biên lai MB Bank (D-033)
- AC-84: Từ một email biên lai chuyển tiền đi của MB Bank, bộ đọc lấy: **ngày giờ**, loại giao dịch, **số tham chiếu**, **tài khoản trích nợ** (chỉ giữ 4 số cuối), **người thụ hưởng**, **số tiền giao dịch**, **nội dung chuyển tiền**, cách thức lệnh, ngày nhập lệnh, thời gian, **tình trạng**. Mỗi email mẫu thật người dùng gửi (đã che số tài khoản) nằm trong `test/import/samples/mb/` kèm kết quả mong đợi và cho đúng mọi trường. Số tiền VND: "." và "," đều là dấu nghìn ("50.000", "50,000" = 50.000 ₫). Thời điểm của khoản = trường "ngày giờ" của email *(mặc định; nếu mẫu thật cho thấy "thời gian" khác "ngày giờ" thì chọn lại theo mẫu)*. [T]
- AC-85: Chỉ email có **tình trạng thành công** mới tạo **một khoản chi**; email thất bại, đang xử lý hay tình trạng khác bị bỏ, không lưu gì. Email từ địa chỉ MB nhưng không đọc được đủ trường bắt buộc (ngày giờ, số tham chiếu, tài khoản trích nợ, số tiền, tình trạng) cũng bị bỏ, không lưu nội dung; app chỉ tăng bộ đếm "N email MB không đọc được" ở màn hộp thư (dấu hiệu mẫu email đã đổi). Email MB chỉ có tiền **ra** nên app không tạo khoản thu từ email. [T]
- AC-86: **Chống nhập trùng bằng số tham chiếu:** một số tham chiếu chỉ tạo một mục, dù email được tải lại, nằm ở hai hộp thư, hay được chuyển tiếp. App nhớ số tham chiếu đã gặp (đã ghép, đã xác nhận, đã bỏ qua) nên xoá khoản hay "Bỏ qua" rồi cũng không nhập lại. [T]
- AC-87: Tiền tệ của app khác VND → mục vẫn vào hàng đợi, có dòng "Email bằng VND, app đang dùng USD"; xác nhận mục đó mở màn Nhập khoản với ô số tiền trống để người dùng tự nhập; app không tự quy đổi. [T]
- AC-88: App **không bao giờ lưu số tài khoản đầy đủ**: chỉ 4 số cuối của tài khoản trích nợ; số tài khoản của người thụ hưởng không lưu. Ghi chú của khoản = "<người thụ hưởng> · <nội dung chuyển tiền>", cắt ở 200 ký tự; trong đó mọi dãy từ 9 chữ số liền trở lên được che còn "…" + 4 số cuối. [T]

### F-30 · Tài khoản lấy từ "tài khoản trích nợ" (D-033)
- AC-89: Email thành công đầu tiên của một tài khoản trích nợ (4 số cuối) chưa gắn Account → app tạo Account **"MB Bank …<4 số cuối>"**, **số dư ban đầu 0**, và hiện thẻ ở đầu Hàng đợi: "Đã tạo tài khoản MB Bank …1234 · Gắn vào tài khoản có sẵn" *(mặc định, Q-05 người dùng chưa trả lời)*. Chọn "Gắn vào tài khoản có sẵn" → chọn một Account (không phải Account tự tạo khác) → liên kết (MB, 4 số cuối) chuyển sang Account đó, Account vừa tạo bị xoá (chưa có khoản nào), các mục hàng đợi chuyển theo và được thử ghép lại (AC-94). Đóng thẻ thì giữ Account mới. [T]
- AC-90: Account tự tạo là Account bình thường: đổi tên, sửa số dư ban đầu, ẩn được; xoá theo AC-45. Liên kết nằm ở (MB, 4 số cuối), không ở tên. Account đã ẩn vẫn nhận mục từ email *(mặc định)*. Account liên kết bị xoá → email sau của tài khoản đó tạo lại Account và hỏi lại như AC-89. Màn Tài khoản hiện nhãn "Từ email MB" dưới Account có liên kết. [T]

### F-31 · Ghép email với khoản ghi tay (D-033)
- AC-91: Email thành công **ghép** vào một khoản có sẵn khi: **cùng Account** (Account liên kết với tài khoản trích nợ); khoản là khoản chi, hoặc chuyển tiền đi từ Account đó; **cùng số tiền**; thời điểm chênh **≤ 2 giờ**; khoản chưa gắn email nào. Ghép thì **không vào hàng đợi**: khoản giữ nguyên mọi dữ liệu (số tiền, danh mục, ghi chú, ngày giờ), chỉ gắn thêm nguồn "Email MB" và số tham chiếu. Tình huống: ghi tay chi 50.000 "Cà phê" ở "MB Bank …1234" lúc 12:00; 12:02 có email MB thành công 50.000 từ tài khoản …1234 → vẫn một khoản "Cà phê" 12:00, có biểu tượng "Email". Khoản ghi tay ở Account khác (vd "Tiền mặt") **không** ghép (giữ kế hoạch) — email vào hàng đợi. [T]
- AC-92: Biên 2 giờ tính cả hai đầu: 12:00 với 14:00 → ghép; 12:00 với 14:01 → không ghép, vào hàng đợi. Qua nửa đêm: ghi tay 23:30 ngày 05/11, email 00:40 ngày 06/11 → ghép. Khoản không giờ ngày 06/11 (= 12:00) với email 13:30 → ghép; với email 15:00 → không. [T]
- AC-93: Mỗi khoản ghép được **tối đa một email** (một số tham chiếu). Hai lần chuyển thật cùng giá: chỉ một khoản ghi tay 50.000 lúc 12:00, hai email 50.000 lúc 12:00 và 12:30 → email đầu ghép, email sau vào hàng đợi. Nhiều khoản đủ điều kiện → ghép vào khoản có thời điểm gần nhất; bằng nhau → khoản tạo trước. [T]
- AC-94 *(mặc định — chiều ngược)*: Khi người dùng **lưu một khoản ghi tay** (hoặc gắn Account ở AC-89) mà trong hàng đợi có mục thoả AC-91 với khoản đó → mục rời hàng đợi, gắn vào khoản vừa lưu, hiện thanh "Đã ghép với email MB 12:02 · Hoàn tác" (Hoàn tác trả mục về hàng đợi). [T]

### F-32 · Hàng đợi chọn danh mục (D-030)
- AC-95: Mọi email thành công **không ghép** được trở thành một **mục hàng đợi**, **chưa là khoản**: không hiện ở Các khoản, không vào tổng thu/chi, biểu đồ, ngân sách, thông báo ngân sách, số dư tài khoản, Tổng quan, Thống kê, Lịch, widget, CSV/Excel/PDF. Màn chính hiện "N khoản chờ chọn danh mục" khi N > 0, chạm mở **Hàng đợi** (cũng vào được từ Cài đặt → Nhập tự động → "Khoản chờ chọn danh mục"). Mỗi mục hiện: ngày giờ, số tiền, người thụ hưởng, nội dung chuyển tiền, Account. Mục không tự hết hạn *(mặc định)*. [T]
- AC-96: Mỗi mục có lưới danh mục chi. Có gợi ý (AC-97) thì danh mục đó được chọn sẵn, gắn nhãn "Gợi ý", nút lớn ghi "Lưu vào <danh mục>"; người dùng **vẫn phải chạm** để xác nhận (không tự lưu); chạm danh mục khác trong lưới thì lưu vào danh mục đó (như D-018). Không có gợi ý → chạm một danh mục là lưu. Lưu → một **khoản chi**: ngày giờ của email, Account, số tiền, danh mục, ghi chú (AC-88), nguồn "Email MB", số tham chiếu; từ lúc này khoản tính vào mọi tổng. "Sửa trước khi lưu" mở màn Nhập khoản điền sẵn (đổi số tiền, ghi chú, ngày giờ được). [T]
- AC-97: **Gợi ý theo người thụ hưởng** *(mặc định)*: khoá = tên người thụ hưởng bỏ dấu, viết thường, gộp khoảng trắng. Lần lưu gần nhất của cùng khoá (một danh mục, hoặc "chuyển sang tài khoản X" ở AC-98) thành gợi ý cho mục sau cùng khoá. Ví dụ đã lưu "CONG TY ABC" vào Ăn uống → email sau gửi "Công ty ABC" gợi ý Ăn uống. Cài đặt → Nhập từ email ngân hàng → "Gợi ý đã nhớ": xem, xoá từng gợi ý. Gợi ý nằm trong file sao lưu; xoá danh mục thì gợi ý trỏ tới nó chuyển sang danh mục nhận khoản (như AC-17). [T]
- AC-98: **"Chuyển sang tài khoản của tôi"**: chọn Account đích (khác Account trích nợ, gồm cả Account của mục tiêu tiết kiệm) → lưu thành **một Transfer** từ Account trích nợ sang Account đó (ngày giờ, số tiền, ghi chú, số tham chiếu như AC-96); không vào thu/chi. Ví dụ email MB 2.000.000 người thụ hưởng là chính mình ở MoMo → Transfer "MB Bank …1234 → MoMo". [T]
- AC-99: **"Bỏ qua"** xoá mục khỏi hàng đợi (số tham chiếu được nhớ, AC-86) sau hộp xác nhận. Hàng đợi **không** vào file sao lưu *(mặc định)*; khôi phục không xoá hàng đợi hiện có nhưng mục có số tham chiếu đã nằm trong khoản của file khôi phục bị bỏ khỏi hàng đợi. [T]

### F-33 · Tiết kiệm
- AC-100: Màn **"Tiết kiệm"** (vào từ Tổng quan và Cài đặt; vị trí theo mockup phiên #4): tạo Savings goal gồm tên (≤ 50 ký tự), số tiền mục tiêu > 0, hạn (ngày, *(mặc định)* tuỳ chọn), và Account gắn: chọn Account có sẵn chưa gắn mục tiêu khác, hoặc "Tạo tài khoản mới" (tên = tên mục tiêu, số dư ban đầu 0). Một Account gắn tối đa một mục tiêu. [T]
- AC-101: **Tiến độ** = số dư hiện tại của Account gắn (gồm số dư ban đầu) so với mục tiêu: thanh %, "Đã có X / Y", "Còn thiếu Z"; có hạn thì "Còn N ngày" hoặc "Quá hạn N ngày". Số dư ≥ mục tiêu → **"Đã đạt"** (dấu ✓ kèm chữ). Rút tiền khỏi Account làm tiến độ giảm và có thể mất "Đã đạt". Ví dụ: mục tiêu 10.000.000, Account có 3.000.000 → 30%, còn thiếu 7.000.000. [T]
- AC-102: **"Góp tiền"** mở màn Chuyển tiền với "Đến" = Account của mục tiêu, "Từ" = tài khoản mặc định; lưu ra một Transfer bình thường: tổng thu, tổng chi, biểu đồ, ngân sách **không đổi**; Tổng số dư (AC-107) không đổi. [T]
- AC-103: Xoá mục tiêu không xoá Account hay khoản nào. Mục tiêu (kèm số tiền chính xác D-029) đi theo file sao lưu và được quy đổi khi đổi tiền tệ (AC-122). [T]

### F-34 · Khoản nợ (sổ ghi nhớ)
- AC-104: Màn **"Khoản nợ"**: thêm Debt record gồm người (≤ 50 ký tự), chiều **"Cho vay"** (người khác nợ bạn) hoặc **"Đi vay"** (bạn nợ người khác), số tiền > 0, ngày, hạn (tuỳ chọn), ghi chú (≤ 200 ký tự). Danh sách chia hai nhóm "Người khác nợ bạn" / "Bạn nợ người khác", mỗi nhóm có tổng còn lại. [T]
- AC-105: Thêm **lần trả** (số tiền > 0, ngày; không vượt số còn lại, vượt thì báo lỗi); còn lại = số tiền − tổng các lần trả; về 0 → **"Đã xong"**, chuyển xuống mục "Đã xong" (thu gọn). Xoá lần trả thì tính lại. Quá hạn mà chưa xong → "Quá hạn" (chữ, không chỉ màu). **Không có thông báo nhắc hạn**. [T]
- AC-106: Khoản nợ và lần trả **không** tạo khoản (Entry), không đổi số dư Account nào, không vào thu/chi, biểu đồ, ngân sách hay Tổng số dư. Có trong file sao lưu; được quy đổi khi đổi tiền tệ (AC-122). [T]

### F-35 · Tổng quan (màn riêng, D-034)
- AC-107: Màn **"Tổng quan"** riêng, **màn chính giữ nguyên** như bản 1 (vị trí điều hướng tới Tổng quan theo mockup phiên #4). Tổng quan có chọn tháng riêng (‹ Tháng 11/2026 ›, mặc định tháng hiện tại theo Ngày bắt đầu tháng; *(mặc định)* không phụ thuộc kỳ đang xem ở màn chính) và hiện: (1) **"Tổng số dư"** = tổng số dư mọi Account, **gồm cả tài khoản ẩn**; (2) ô **"Thu − chi tháng"**; (3) ô **"Ngân sách còn lại"** = hạn mức tháng − đã chi; âm → "Vượt X"; chưa đặt ngân sách → ô "Đặt ngân sách" mở chỗ đặt; (4) **biểu đồ cột thu–chi** 6 tháng *(mặc định)* kết thúc ở tháng đang chọn; (5) **"So với tháng trước"**: % thay đổi của chi và của thu so với tháng liền trước, mũi tên kèm chữ "tăng"/"giảm"; tháng trước bằng 0 → "—". Mọi số tính trên mọi tài khoản *(mặc định)* và không gồm mục hàng đợi (AC-95). [T]
- AC-108: Ví dụ: tháng 10 chi 4.000.000, tháng 11 chi 5.000.000 → "Chi tăng 25% so với tháng 10". Mọi số khớp tổng các khoản tới đơn vị nhỏ nhất. Biểu đồ cột có bảng thay thế cho trình đọc màn hình (như AC-39). [T]

### F-36 · Thống kê
- AC-109: Màn **"Thống kê"** dùng cùng chọn kỳ (F-03) và bộ lọc tài khoản, có: (1) **biểu đồ cột thu/chi** theo kỳ con — Ngày: một cặp cột; Tuần: 7 ngày; Tháng: từng ngày; Năm: 12 tháng; Tất cả: từng năm; Khoảng tuỳ chọn ≤ 31 ngày: từng ngày, ≤ 366 ngày: từng tháng, dài hơn: từng năm *(mặc định)*; (2) **5 danh mục chi nhiều nhất** (số tiền, % trên tổng chi kỳ); (3) **"Ngày chi nhiều nhất"** (ngày + số tiền; bằng nhau → ngày sớm hơn; kỳ Ngày thì ẩn); (4) **đường lịch sử tổng số dư** (mọi Account, giá trị cuối mỗi kỳ con). Biểu đồ tròn và % theo danh mục đã có giữ nguyên. [T]
- AC-110: Kỳ không có khoản → trạng thái trống, không vẽ biểu đồ rỗng. Mọi biểu đồ có bảng thay thế cho trình đọc màn hình. Với 10.000 khoản, kỳ "Tất cả" mở xong ≤ 1 giây trên Galaxy A13 (bản release). [T cho số liệu; M cho thời gian]

### F-37 · Cảnh báo sắp vượt ngân sách (D-034)
- AC-111: Ngưỡng **"Sắp vượt"** mặc định **80%**, chỉnh trong Cài đặt từ 50% tới 95%, bước 5%. Đã chi ≥ ngưỡng × hạn mức và ≤ hạn mức → "Sắp vượt" (icon + chữ "Đã dùng 82%", màu cảnh báo khác màu "Vượt"); > hạn mức → "Vượt X" như AC-27. Áp cho ngân sách tháng (thanh màn chính, ô "Ngân sách còn lại") và ngân sách danh mục (AC-54). Ví dụ hạn mức 5.000.000, ngưỡng 80%: đã chi 3.999.999 → bình thường; 4.000.000 → Sắp vượt; 5.000.000 → Sắp vượt; 5.000.001 → Vượt 1. [T]
- AC-112: Công tắc **"Thông báo ngân sách"** *(mặc định tắt)*; bật thì giải thích rồi mới xin quyền thông báo như AC-61. Khi bật: một khoản (ghi tay, sinh định kỳ, xác nhận từ hàng đợi) làm đã chi **của tháng hiện tại** vượt qua mốc ngưỡng hoặc mốc 100% của một ngân sách (tháng hoặc danh mục) → gửi **một** thông báo cục bộ. Mỗi mốc của mỗi ngân sách tối đa một lần mỗi tháng: giảm xuống rồi lên lại trong tháng không báo lại; sang tháng mới đặt lại. Khoản ghi lùi vào tháng cũ không gây thông báo. [T]
- AC-113: Nội dung **chỉ có phần trăm, không bao giờ có số tiền**, dù PIN bật hay tắt *(mặc định: nội dung như nhau khi bật PIN)*: "Ngân sách tháng 11: đã dùng 80%", "Ăn uống: đã dùng 100% hạn mức tháng 11". Chạm mở app (qua màn khoá nếu bật) ở Tổng quan. Test kiểm nội dung không chứa số tiền hay ký hiệu tiền tệ (vi và en). [T]

### F-38 · Lịch chi tiêu
- AC-114: Màn **"Lịch"** dạng tháng (dùng lại lưới lịch của `range_calendar.dart`): mỗi ngày hiện tổng chi rút gọn (vi: "50k", "1,2tr"; en: "50K", "1.2M") và một chấm nếu có thu; ‹ › hoặc vuốt để đổi tháng; theo Ngày đầu tuần (AC-12) và bộ lọc tài khoản. Chạm một ngày → danh sách khoản của ngày đó kèm tổng thu/chi ngày (sửa, vuốt xoá, Hoàn tác như Các khoản). Trình đọc màn hình đọc từng ngày dạng "6 tháng 11, chi 250.000 ₫". [T]

### F-39 · Lọc nâng cao
- AC-115: Màn Các khoản có nút **"Lọc"**: khoảng số tiền (từ/đến, bỏ trống một đầu được; từ > đến → lỗi dưới ô), **nhiều danh mục** (chọn nhiều, cả chi và thu), **khoảng ngày** (bộ chọn khoảng như Khoảng tuỳ chọn; đặt rồi thì thay kỳ đang xem cho danh sách này). Các điều kiện kết hợp với nhau, với tìm kiếm (F-15) và bộ lọc tài khoản bằng VÀ. Kết quả: danh sách phẳng mới nhất trước + "N khoản · chi X · thu Y"; mỗi điều kiện là một chip gỡ được, có "Xoá lọc". Có lọc danh mục thì loại chuyển tiền. Bộ lọc chỉ sống trong phiên chạy. Ví dụ: 50.000–200.000, Ăn uống + Đi lại, 01–15/11/2026 → đúng các khoản thoả cả ba. [T]

### F-40 · Xuất Excel và PDF
- AC-116: Cài đặt → Dữ liệu → **"Xuất Excel"** / **"Xuất PDF"**: chọn phạm vi (kỳ đang xem hoặc khoảng tuỳ chọn) rồi mở bảng chia sẻ của hệ điều hành (như AC-28; không xin quyền bộ nhớ). [T]
- AC-117: Excel `.xlsx` có sheet "Khoản" (ngày, giờ, loại, số tiền là ô số định dạng tiền đúng số lẻ, tiền tệ, danh mục, tài khoản, đến tài khoản, ghi chú, nguồn), sheet "Theo danh mục" (danh mục, tổng, %), sheet "Khoản nợ" (người, chiều, số tiền, đã trả, còn lại, hạn, trạng thái). Tiêu đề theo ngôn ngữ app. Ô chữ bắt đầu bằng `= + - @` vẫn là chữ, không thành công thức. [T: đọc lại file vừa xuất; M mở bằng Excel và Google Sheets, tiếng Việt đúng]
- AC-118: PDF khổ A4: "Báo cáo thu chi <kỳ>", tổng thu, tổng chi, chênh lệch, bảng theo danh mục (số, %), danh sách khoản (ngày giờ, danh mục, ghi chú, số tiền); nhúng font Be Vietnam Pro nên chữ có dấu hiện đúng; tự sang trang khi dài. 1.000 khoản xuất xong ≤ 10 giây trên Galaxy A13. [T: kiểm chữ trích từ PDF; M thời gian và hiển thị]

### F-41 · Mở khoá bằng vân tay / Face ID
- AC-119: Chỉ khi **đã bật PIN** và máy có sinh trắc học đã đăng ký, Cài đặt → Bảo mật hiện công tắc **"Mở khoá bằng vân tay"** (Android) / **"Mở khoá bằng Face ID"** hoặc "Touch ID" (iPhone, theo máy), mặc định tắt; bật phải xác thực sinh trắc một lần. Chưa bật PIN → không hiện; máy không có hoặc chưa đăng ký sinh trắc → công tắc tắt kèm lý do. Tắt PIN thì sinh trắc tự tắt. [T với lớp sinh trắc giả]
- AC-120: Khi bật, màn khoá tự mở hộp sinh trắc của hệ thống (chỉ sinh trắc mạnh, không cho mã khoá máy thay thế); đúng → vào app; huỷ, sai hoặc bị hệ thống khoá tạm → ở lại màn PIN, nhập PIN vẫn được; có nút sinh trắc để thử lại. Áp dụng cả khi vào từ widget và thông báo. "Quên mã" như AC-34. App không lưu dữ liệu sinh trắc (do hệ điều hành giữ). [T; M vân tay trên A13, Face ID trên iPhone qua TestFlight]

### F-42 · Dữ liệu, sao lưu, quyền của bản 2.0 (chung)
- AC-121: Cơ sở dữ liệu lên **schema 4** với migration giữ nguyên dữ liệu v3: khoản thêm giờ, nguồn, số tham chiếu; tài khoản thêm liên kết (ngân hàng, 4 số cuối); bảng mới cho mục tiêu tiết kiệm, khoản nợ, lần trả nợ, gợi ý theo người thụ hưởng, hàng đợi, số tham chiếu đã gặp. File `.vigon` mang mọi phần trên **trừ** hàng đợi và cấu hình hộp thư (địa chỉ, mật khẩu, UID); số tham chiếu đã gặp đi theo file *(mặc định)* để khôi phục xong không nhập lại; file schema 1–3 vẫn khôi phục được; app cũ gặp file schema 4 thì từ chối như hiện nay. [T: test migration dựng DB v3, sao lưu/khôi phục có bảng mới]
- AC-122: Đổi tiền tệ (AC-21, D-029) quy đổi thêm số tiền mục tiêu tiết kiệm, khoản nợ, lần trả nợ, mục hàng đợi (giữ số chính xác 6 lẻ; mục tiêu tối thiểu 1 đơn vị) trong cùng MỘT giao dịch cơ sở dữ liệu; đổi A→B→A cùng bảng tỉ giá về đúng số cũ. [T]
- AC-123: "Xóa toàn bộ dữ liệu" xoá thêm mục tiêu, khoản nợ, gợi ý, hàng đợi, số tham chiếu đã gặp, hộp thư và mật khẩu ứng dụng (Keystore/Keychain), tắt kiểm thư nền và tắt sinh trắc. [T]
- AC-124: CSV thêm hai cột **Giờ** và **Nguồn** (Ghi tay / Email MB) ở **cuối** để giữ thứ tự cột cũ; vẫn đúng AC-30, AC-52. [T]
- AC-125 (thay danh sách quyền của AC-43 khi 2.0 được duyệt): `manifest_test` là danh sách cho phép đúng các quyền ở §5 "2.0" (thêm `USE_BIOMETRIC`) và cấm `CAMERA`, `READ_MEDIA_*`, `READ/WRITE_EXTERNAL_STORAGE`, quyền SMS, dịch vụ đọc thông báo; iOS `Info.plist` có đúng một chuỗi mới `NSFaceIDUsageDescription` (vi, en), không `NSCamera…`/`NSPhotoLibrary…`; mã gọi mạng Dart chỉ ở hai chỗ (tỉ giá, IMAP), chỉ TLS; `pubspec` không có ML Kit hay SDK gửi dữ liệu. [T]
- AC-126: Mọi màn mới (Nhập từ email, giải thích, hộp thư, hàng đợi, gợi ý đã nhớ, Tổng quan, Tiết kiệm, Khoản nợ, Thống kê, Lịch, Lọc, Xuất) có mặt trong `g6_accessibility_test` (vùng chạm 48 dp, nhãn, tương phản, chữ 200%, sáng/tối) và mọi chữ trong `.arb` vi + en. [T; TalkBack/VoiceOver trên máy: M]

### Mặc định Claude chọn trong 3d (người dùng đổi được khi duyệt)
Từ kế hoạch (đã ghi ở đó): email kiểm khi mở app, kéo để làm mới, chạy nền ~mỗi giờ trên Android, iOS chỉ khi mở app (AC-82); sinh trắc chỉ khi có PIN (AC-119); khoản nợ không nhắc hạn (AC-105); "so với tháng trước" là % của chi và của thu (AC-107); lịch dùng lại `range_calendar.dart` (AC-114).
Phiên S0 thêm (quyết định chưa nói):
1. Khoản cũ và khoản sinh từ định kỳ không có giờ (AC-75).
2. Email: chỉ Gmail/Yahoo/iCloud, tối đa 3 hộp thư, chỉ thư từ lúc kết nối, chỉ xem không đánh dấu đã đọc, bỏ thư > 256 KB, dừng kiểm khi sai mật khẩu, kiểm khi mở app cách ≥ 15 phút (AC-78..AC-82).
3. Thời điểm khoản = trường "ngày giờ" của email MB (chốt lại khi có mẫu thật) (AC-84).
4. Tiền tệ app khác VND → mục hàng đợi nhập tay số tiền, không tự quy đổi (AC-87).
5. **Q-05 (người dùng chưa trả lời):** tạo ngay "MB Bank …xxxx" số dư 0 và hiện thẻ "Gắn vào tài khoản có sẵn" (AC-89); Account ẩn vẫn nhận mục từ email (AC-90).
6. Ghép cả chiều ngược: lưu khoản ghi tay khớp mục đang chờ → mục tự gắn vào, có Hoàn tác (AC-94).
7. Mục hàng đợi không tự hết hạn; hàng đợi không vào sao lưu, nhưng số tham chiếu đã gặp thì có (AC-95, AC-99, AC-121).
8. Gợi ý theo tên người thụ hưởng (bỏ dấu, viết thường), nhớ cả lựa chọn "chuyển sang tài khoản X"; xem/xoá được (AC-97).
9. Hạn mục tiêu tiết kiệm là tuỳ chọn; một Account gắn tối đa một mục tiêu (AC-100).
10. Tổng quan có chọn tháng riêng, không theo kỳ của màn chính; số tính trên mọi tài khoản; cột thu–chi 6 tháng (AC-107).
11. Cách chia cột của Thống kê theo kỳ (AC-109).
12. "Thông báo ngân sách" mặc định tắt; nội dung chỉ % như nhau dù bật PIN hay không, có tên ngân sách/danh mục (AC-112, AC-113).

### Câu hỏi mở
Không còn câu hỏi bắt buộc phải trả lời trước khi duyệt (Q-01..Q-09 của bản nháp đầu đã được trả lời 2026-11-06; Q-05 dùng mặc định ở mục trên, người dùng đổi được khi duyệt).
**Phụ thuộc (chặn M1, không chặn duyệt SPEC):** người dùng gửi email biên lai MB thật (đã che số tài khoản) — ít nhất vài email **thành công**, và nếu có, một email **thất bại / đang xử lý** — kèm **địa chỉ gửi** đúng như trong hộp thư. Không có mẫu thất bại thì app chỉ nhận chữ tình trạng đúng như mẫu thành công, mọi tình trạng khác đều bỏ (an toàn theo AC-85).

### Ghi chú cho chính sách quyền riêng tư (KHÔNG sửa `docs/legal/privacy-policy.md` trong phiên này)
Khi 2.0 được duyệt, phiên viết lại chính sách (vi + en) cần sửa:
- Mục 1: "Kết nối mạng duy nhất" → hai kết nối: tải tỉ giá và **đọc email biên lai MB qua IMAP/TLS** tới nhà cung cấp email người dùng chọn (Gmail/Yahoo/iCloud), chỉ khi người dùng thêm hộp thư; nội dung thư xử lý trên máy, không gửi cho nhà phát triển. Câu "không có công cụ phân tích… của bên thứ ba" vẫn đúng (D-032).
- Mục 2: dữ liệu mới (giờ, nguồn, số tham chiếu, 4 số cuối tài khoản trích nợ — không lưu số đầy đủ, tên người thụ hưởng và nội dung chuyển tiền trong ghi chú, hàng đợi, gợi ý, tiết kiệm, khoản nợ); mật khẩu ứng dụng và địa chỉ hộp thư trong Keystore/Keychain; sinh trắc do hệ điều hành giữ.
- Mục 3: file sao lưu không có hộp thư/mật khẩu, không có hàng đợi; thêm Excel và PDF.
- Mục 4: thêm vân tay/Face ID; thông báo dùng thêm cho cảnh báo ngân sách; Internet dùng thêm cho email. Câu "App không xin quyền vị trí, danh bạ, ảnh, camera hay micro" vẫn đúng.
- Mục 5: link mở trang tạo mật khẩu ứng dụng của Google/Yahoo/Apple.
- Mục 7: quyền của người dùng — xoá hộp thư, "Xóa toàn bộ dữ liệu" xoá cả mật khẩu ứng dụng.
- Mục 9: sinh trắc; thông báo ngân sách chỉ có %, không có số tiền.
- Mục 10: câu "Đây là bản đầu tiên" giữ được nếu chính sách đăng lần đầu cùng bản 2.0 (D-035).

## 3e. Đa tiền tệ (D-037 — người dùng chốt 2026-11-09)

Mục này thay cách hiểu "một tiền tệ toàn app" ở F-07 (AC-21, AC-70, AC-71, AC-73) và áp cho mọi tính năng F-01..F-42: số tiền vẫn lưu `int` theo Minor unit của tiền tệ gốc, nhưng mỗi bản ghi có tiền tệ riêng và có thêm số dẫn xuất quy về **Tiền tệ chính**.

### F-43 · Đa tiền tệ và tỷ giá
- AC-127: Mỗi Account có Currency riêng; Entry, Recurring series, Savings goal, Debt, Budget tháng và Category budget cũng có Currency riêng. Entry thường lấy Currency của Account; Transfer lưu Currency nguồn và Currency đích cùng hai số tiền. [T]
- AC-128: Mỗi bản ghi lưu **số gốc** + Currency (`originalAmount` / `originalBudget` / `originalTargetAmount` / `originalInitialBalance` …); các cột `amount` / `budget` / `targetAmount` / `initialBalance` là **số dẫn xuất** quy về Tiền tệ chính tại tỷ giá hiện tại. Danh sách hiện số gốc và dòng `≈` Tiền tệ chính; chi tiết/form hiện số gốc; tổng, biểu đồ và thanh ngân sách dùng số dẫn xuất. [T]
- AC-129: Đổi Tiền tệ chính không sửa số gốc; đổi qua lại với cùng bảng tỷ giá thì số gốc và cách hiển thị trở lại như cũ. Đổi Currency của Account cũng không đổi số gốc, chỉ đổi Currency đích và dòng `≈` (giống A001). [T]
- AC-130: Tỷ giá tự kiểm tra khi mở app/quay lại, tải tối đa 1 lần/ngày, có nút "Cập nhật ngay"; offline dùng bảng đã lưu, chưa có thì dùng bảng dự phòng đóng gói. Màn Tỷ giá chỉ hiện **cặp đang dùng**, có banner offline và ghi công nguồn. [T/M]
- AC-131: Ghi đè tỷ giá trong màn Tỷ giá xem trước số dư Account đầu tiên dùng Currency đó; áp dụng ngay cho mọi số dẫn xuất và tổng đang hiện. [T]
- AC-132: Chuyển tiền khác Currency cho nhập/lưu cả số gửi và số nhận; số dư hai Account đổi đúng từng số đã lưu; không tự bắt buộc quy đổi. [T]
- AC-133: Đổi Currency của Budget thì quy đổi số đã nhập; Debt chọn Currency và **khóa sau lần trả đầu**; Savings goal theo Currency của Account; hàng đợi email so Currency của email với Account liên kết, khác thì bắt nhập tay, **không tự quy đổi**. [T]
- AC-134: Cặp thiếu tỷ giá: `CurrencyService.convert` trả `null`; UI hiện ghi chú "Thiếu tỷ giá", khoản đó không được cộng vào tổng (khi recompute thì giữ số dẫn xuất cũ), không quy đổi ngầm. [T]
- AC-135: Màn Tỷ giá, dòng `≈`, hộp ghi đè và các chỗ chọn Currency nằm trong test trợ năng G6; mọi chữ mới có trong `.arb` vi + en. [T]

### Ghi chú kỹ thuật cho 3e
- Schema **v5** + migration 4→5: thêm cột Currency/số gốc cho các bảng, backfill dữ liệu cũ theo tiền tệ đang lưu; file sao lưu chứa đủ cột mới và có test migration.
- Hai hàm trung tâm: `promoteLegacyAmounts(oldPrimary)` (chuyển dữ liệu cũ sang số gốc) và `recomputeDerivedAmounts(...)` (tính lại số dẫn xuất khi đổi Tiền tệ chính hoặc tỷ giá).
- `features/settings/currency_conversion.dart` (D-025) không còn dùng cho đổi Tiền tệ chính; chỉ còn `formatRate` cho màn Tỷ giá. Thêm cặp tiền tệ mới phải cập nhật bảng dự phòng.

## 4. Ngoài phạm vi (cố ý KHÔNG làm)
Đã đưa vào phạm vi (giữ dòng gạch để biết lịch sử):
- ~~Bản iOS~~: vào phạm vi ngày 2026-11-04 theo PLAN-001 (người dùng duyệt), xem mục 5 "iOS" và D-011; chỉ icon đơn sắc (F-23) là riêng Android (D-022).
- ~~Ngân sách theo từng danh mục~~: bản 1.1 (F-20). ~~Nhắc nhở bằng thông báo~~: bản 1.2 (F-25). ~~Widget màn hình chính~~: bản 1.2 (F-26; iOS theo D-022).
- ~~Sao lưu lên Google Drive, Dropbox~~: chỉ làm dạng sao lưu một chiều vào thư mục người dùng chọn (F-24, Android và iOS); đồng bộ qua API vẫn ngoài phạm vi (bảng dưới).
- ~~Bản iOS của widget, sao lưu tự động, che nội dung ở màn đa nhiệm~~ (trước để việc riêng theo D-019): làm ngay bản 1 theo D-022 (2026-11-05) — WidgetKit + App Group, bộ chọn thư mục app Tệp + bookmark, lớp phủ native.
- ~~Mở khóa bằng vân tay hoặc khuôn mặt~~: bản 2.0 (F-41, chưa duyệt), chỉ khi đã bật PIN.
- ~~Đọc tin nhắn ngân hàng, quét hóa đơn, AI~~ (tách dòng 2026-11-06, D-030, D-032): chỉ **đọc email biên lai MB Bank qua IMAP** (F-28..F-32) vào bản 2.0 (chưa duyệt), và khoản từ email luôn qua hàng đợi để người dùng chọn danh mục. Đọc SMS, đọc thông báo, quét hoá đơn, ảnh hoá đơn, AI vẫn ngoài phạm vi (dưới đây).

Vẫn ngoài phạm vi:
- Tài khoản người dùng, đăng nhập, máy chủ, đồng bộ đám mây.
- Nhiều tiền tệ cùng lúc (mỗi tài khoản một tiền tệ). (Quy đổi tỉ giá khi ĐỔI tiền tệ của app đã làm theo D-025, AC-21, AC-70..AC-72.)
- Quảng cáo, mua trong app, gói Pro, analytics, báo crash bằng SDK.
- **Quét hoá đơn (OCR) và đính ảnh hoá đơn** (D-032): thư viện nhận chữ trên máy phổ biến cho cả hai nền tảng là Google ML Kit, mà ML Kit (kể cả bản gói kèm) gửi dữ liệu chẩn đoán về Google → phá khai báo "không thu thập"; ảnh hoá đơn lưu ngoài app sẽ nằm ngoài khoá PIN và sao lưu, và kéo theo quyền máy ảnh/ảnh.
- **Đọc thông báo app ngân hàng/ví** (D-032): chỉ làm được trên Android, quyền truy cập thông báo nhạy cảm (Google Play xét kỹ, cần màn giải thích riêng), người dùng chọn bỏ để giữ app đơn giản và ít quyền.
- **Đọc SMS** (Google Play chỉ cho app nhắn tin mặc định và vài nhóm ngoại lệ); AI/mô hình ngôn ngữ phân tích nội dung.
- Ngân hàng khác MB Bank cho tới khi có email mẫu thật (AC-83); bộ đọc "chung" cho mọi ngân hàng; khoản thu từ email (email MB chỉ có tiền ra).
- Khớp số dư tự động (khoản "điều chỉnh số dư"), lấy số dư ban đầu từ email, tự ghép chuyển tiền giữa hai tài khoản (thay bằng lựa chọn "Chuyển sang tài khoản của tôi" trong hàng đợi, AC-98) (D-033).
- Gmail API / OAuth, Outlook/Hotmail, máy chủ IMAP tuỳ ý (D-031); gửi, xoá hay đánh dấu thư.
- Kết nối thẳng ngân hàng (open banking, API ngân hàng), thanh toán từ app.
- Nhắc hạn khoản nợ; khoản nợ làm đổi số dư tài khoản (F-34 chỉ là sổ ghi nhớ).

Các mục còn hiệu lực từ bản 1.1, 1.2 và lần gộp (cần người dùng làm hoặc quyết, vì phá cam kết hiện tại của app hoặc cần việc riêng):
| Mục | Vì sao chưa làm |
|-----|-----------------|
| Đồng bộ (kể cả đồng bộ hai chiều giữa nhiều máy) qua Google Drive, Dropbox bằng API | Cần mạng, đăng nhập OAuth và khóa API/ID khách (do người dùng tạo trong Google Cloud, Dropbox App Console); trái D-002; kéo theo quyền INTERNET, khai Data safety khác, chính sách quyền riêng tư viết lại, nhiều mục COMPLIANCE. F-24 chỉ sao lưu một chiều vào thư mục đã chọn |
| Widget hiện số tiền khi đang bật PIN | Làm lộ số liệu ngoài màn khóa, vô hiệu khóa PIN (D-016) |
| Nhiều tiền tệ cùng lúc | Thay đổi lớn mô hình dữ liệu (mỗi tài khoản một tiền tệ). Nguồn tỉ giá đã có từ D-025 |
| Gói Pro hoặc nguồn thu khác | Thanh toán trong app (Play Billing, StoreKit), COMPLIANCE C-01/C-02/T-01, thuế |
| Đọc SMS ngân hàng | Chính sách SMS/Call Log của Google Play chỉ cho app nhắn tin mặc định và vài nhóm ngoại lệ; thay bằng email biên lai (F-28, D-030) |
| Quét hoá đơn, ảnh hoá đơn, đọc thông báo ngân hàng | Bỏ ở bản 2.0 (D-032): ML Kit gửi chẩn đoán về Google (phá "không thu thập"); ảnh ngoài khoá PIN/sao lưu; quyền truy cập thông báo nhạy cảm, chỉ Android. Muốn làm lại phải chọn OCR không gửi dữ liệu và sửa khai báo |
| Gmail API (OAuth) | Phạm vi đọc thư là "restricted scope": phải qua đánh giá bảo mật CASA hằng năm; thay bằng IMAP + mật khẩu ứng dụng (D-031) |

## 5. Ràng buộc mobile
- Hệ điều hành: Android; minSdk theo mặc định của phiên bản Flutter được ghim (D-003); targetSdk theo yêu cầu Google Play hiện hành (COMPLIANCE P-06). iOS: xem mục "iOS" ngay dưới.
- Giao diện: theo bộ thiết kế đã duyệt `design/current/screens/` và `design/current/ui-spec.md` (token, chữ Be Vietnam Pro, icon Material Symbols Rounded), giống nhau trên hai nền tảng, chỉ khác ở chỗ hệ điều hành quyết định (D-010).
- Offline: toàn bộ app chạy không cần mạng; ~~không có tính năng nào gọi mạng~~ — từ D-025 (2026-11-05) chỉ một việc dùng mạng: tải bảng tỉ giá khi người dùng đổi tiền tệ (AC-72); không có mạng thì nhập tỉ giá tay (AC-71). Dữ liệu ghi xuống bộ nhớ máy ngay khi bấm Lưu.
  - **2.0 (chưa duyệt, D-031):** thêm việc mạng thứ hai — đọc email biên lai MB qua IMAP/TLS tới Gmail, Yahoo, iCloud (AC-80), chỉ khi người dùng đã thêm hộp thư. Ghép, hàng đợi, ghi chép, xem, Tổng quan, thống kê, xuất file đều không cần mạng.
- Quyền thiết bị:
  - Android: `INTERNET` (D-025, chỉ tải tỉ giá khi đổi tiền tệ; quyền thường, không hộp thoại) và hai quyền phục vụ nhắc ghi sổ F-25 (D-015): `POST_NOTIFICATIONS` (chỉ xin khi người dùng bật công tắc "Nhắc ghi sổ hằng ngày", sau lời giải thích; hộp thoại hệ thống chỉ có từ Android 13) và `RECEIVE_BOOT_COMPLETED` (đặt lại lịch nhắc sau khi khởi động lại máy, không hộp thoại). KHÔNG `ACCESS_NETWORK_STATE`, KHÔNG cleartext HTTP, KHÔNG `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, KHÔNG quyền bộ nhớ: sao lưu/khôi phục dùng bảng chia sẻ và trình chọn file của hệ điều hành, sao lưu tự động dùng Storage Access Framework; widget không cần quyền. Kiểm bằng `test/manifest_test.dart` (AC-43) và `aapt2 dump permissions` bản release.
  - iOS: không có khóa `NS…UsageDescription`; chỉ xin quyền thông báo (hộp thoại của iOS) khi người dùng bật nhắc ghi sổ, sau lời giải thích (AC-61). Chọn file khôi phục và chọn thư mục sao lưu tự động dùng trình chọn hệ thống (app Tệp), không cần quyền; widget (App Group) và lớp che F-22 cũng không cần quyền.
  - **2.0 (chưa duyệt) — Android**, danh sách cho phép của `manifest_test` (AC-125):
    - `USE_BIOMETRIC` (F-41; quyền thường, không hộp thoại) — quyền mới duy nhất.
    - `INTERNET` (đã có) thêm mục đích thứ hai: IMAP tới ba máy chủ email (AC-80).
    - `POST_NOTIFICATIONS` (đã có) thêm mục đích: thông báo ngân sách (AC-112), vẫn chỉ xin khi bật công tắc, sau lời giải thích. `RECEIVE_BOOT_COMPLETED` (đã có) thêm: đặt lại lịch kiểm thư nền (AC-82).
    - Vẫn KHÔNG (D-032): `CAMERA`, `READ_MEDIA_IMAGES`/`READ_MEDIA_*`, `READ_EXTERNAL_STORAGE`/`WRITE_EXTERNAL_STORAGE`, `READ_SMS`/`RECEIVE_SMS`, dịch vụ đọc thông báo (`BIND_NOTIFICATION_LISTENER_SERVICE`), `SCHEDULE_EXACT_ALARM`, `ACCESS_NETWORK_STATE`, cleartext, `FOREGROUND_SERVICE`.
  - **2.0 (chưa duyệt) — iOS**: thêm đúng một chuỗi mục đích `NSFaceIDUsageDescription` (vi + en, trung thực, S-40) cho mở khoá bằng Face ID; không `NSCameraUsageDescription`, không `NSPhotoLibrary…`. Quyền thông báo (đã có) dùng thêm cho thông báo ngân sách. Kết nối IMAP theo ATS mặc định (TLS).
- Màn hình: chiều rộng nhỏ nhất 360 dp; chỉ màn hình dọc.
- Hiệu năng/pin: không có service hay job chạy nền liên tục. Thông báo nhắc do hệ điều hành đặt lịch (F-25); sao lưu tự động tối đa một lần mỗi ngày, chạy lúc app ra nền trên Android, khi mở/quay lại app trên iOS (F-24). Ngưỡng ở 5b.
  - **2.0 (chưa duyệt):** kiểm thư nền Android khoảng mỗi giờ (AC-82), lịch không chính xác, mỗi lần chỉ tải thư mới của địa chỉ MB; không có dịch vụ chạy liên tục.

### iOS (thêm 2026-11-04 theo PLAN-001; cập nhật khi gộp 2026-11-05 theo D-019, rồi theo D-022 cùng ngày)
- Cùng codebase Flutter, cùng tính năng và AC như Android, **trừ F-23 icon đơn sắc** (chỉ Android) và phần chạy khác nhau của F-22, F-24, F-26 ở dưới. iOS tối thiểu **16.0** (D-024; trước là 15.0), chỉ iPhone, chỉ dọc. Build trên cloud có máy macOS vì máy phát triển là Windows (D-011; `.github/workflows/ios.yml`, `release-ios.yml`); yêu cầu App Store P-01 tới P-05 trong `docs/COMPLIANCE.md`.
- Tương ứng nền tảng khi đọc AC: TalkBack ↔ VoiceOver (AC-39); Android Keystore ↔ Keychain (AC-33); AC-43 trên iOS nghĩa là mã gọi mạng duy nhất là tải tỉ giá (AC-72), chỉ HTTPS theo ATS mặc định (iOS không có quyền INTERNET). Keychain giữ PIN sau khi gỡ app: khi cài lại với dữ liệu mới, app tự xóa PIN cũ (D-017).
- **Tính năng gốc nền tảng (D-022, thay phần iOS của D-019):** F-22, F-24, F-26 có trên cả hai nền tảng, cài khác nhau — F-22: Android `FLAG_SECURE` ↔ iOS lớp phủ khi rời app (không chặn chụp màn hình); F-24: Android SAF, chạy lúc ra nền ↔ iOS bộ chọn thư mục app Tệp + bookmark, chạy khi mở/quay lại app; F-26: Android AppWidget ↔ iOS WidgetKit + App Group. AC và cách kiểm iOS ở gạch "iOS (D-022)" dưới từng F. Kênh native dùng chung giao thức (`vigon/secure`, `vigon/widget`, `vigon/deeplink`, `vigon/backup_folder`; iOS: `ios/Runner/VigonNative.swift`) nên Dart không phân nhánh. Cờ nền tảng: `lib/src/platform_features.dart`; test `test/features/merge_ios_gating_test.dart` (iOS có đủ ba mục). **F-23 icon đơn sắc chỉ Android**: AC-57 không áp dụng iOS.
- **F-25 nhắc ghi sổ chạy cả iOS** (thông báo cục bộ, xin quyền khi bật công tắc). F-21 mã hóa file sao lưu tay cũng chạy cả iOS.
- Kiểm chứng: AC ghi [M] áp dụng cho iOS phải thử trên iPhone thật (TestFlight) trước khi phát hành iOS. Khi chưa có iPhone, chỉ có iOS Simulator của GitHub Actions: biên bản ghi rõ phần nào mới thử trên simulator. Widget iOS cần App Group `group.com.phiotron.vigon` do người dùng tạo trên Apple Developer (từng bước ở `notes/2026-11-05-d4-ios-features-widget.md`); chưa có thì simulator CI chỉ xác nhận extension được nạp và vẽ được.

## 5b. Yêu cầu phi chức năng
Ngưỡng dưới đây là đề xuất của Claude, người dùng chỉnh khi duyệt. Máy đo chuẩn: Galaxy A13 (SM-A135F, Android 14), chốt ở G1.
- Hiệu năng: mở nguội tới màn chính ≤ 2 giây (trung vị 5 lần, bản release); lưu một khoản ≤ 200 ms; cuộn danh sách 5.000 khoản không có khung hình nào trên 32 ms trong Flutter DevTools (bản profile).
- Pin và bộ nhớ: không có service hay job nền chạy liên tục (thông báo nhắc do hệ điều hành đặt lịch); dùng liên tục 15 phút tiêu hao ≤ 3% pin; bộ nhớ ≤ 200 MB với 10.000 khoản.
- Dung lượng: file APK cho một kiến trúc (arm64) ≤ 25 MB. **2.0 (chưa duyệt):** giữ ngưỡng này (không còn ML Kit, D-032); đo lại sau khi thêm `enough_mail`, `excel`, `pdf`, `fl_chart`, `local_auth` bằng `flutter build apk --analyze-size --target-platform android-arm64`; vượt thì báo người dùng trước khi nâng ngưỡng.
- Bản 2.0 thêm (đề xuất, người dùng chỉnh khi duyệt): một lần kiểm thư (đăng nhập, tìm, tải ≤ 20 thư mới) ≤ 10 giây trên mạng 4G; đọc một email MB ≤ 50 ms; ghép một email với 10.000 khoản ≤ 200 ms; mở Hàng đợi 100 mục ≤ 500 ms.
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
  - Bảng mới trong SQLite (schema 4, AC-121): mục tiêu tiết kiệm, khoản nợ + lần trả, gợi ý theo người thụ hưởng, hàng đợi, số tham chiếu đã gặp; khoản thêm giờ, nguồn, số tham chiếu; tài khoản thêm liên kết (MB, **4 số cuối** tài khoản trích nợ — không bao giờ lưu số tài khoản đầy đủ, AC-88). Tên người thụ hưởng và nội dung chuyển tiền nằm trong ghi chú của khoản (dữ liệu của người dùng, trên máy).
  - **Mật khẩu ứng dụng IMAP** và địa chỉ hộp thư: chỉ trong Keystore (Android) / Keychain (iOS) qua `SecretStore` như mật khẩu sao lưu tự động; không vào cơ sở dữ liệu, file sao lưu, log (AC-79). UID thư đã đọc, trạng thái kiểm thư là cài đặt theo máy, không theo file sao lưu.
  - **Email chỉ được đọc trên máy**: chỉ tải thư của địa chỉ MB; thân thư xử lý trong bộ nhớ rồi bỏ, chỉ giữ các trường cần cho mục hàng đợi/khoản; thư không bị đánh dấu đã đọc hay sửa trên máy chủ (AC-81). Nhà phát triển không nhận gì.
  - Không ảnh, không máy ảnh, không đọc thông báo, không SDK gửi dữ liệu (D-032) → Data safety giữ "không thu thập, không chia sẻ", App Privacy giữ "Data Not Collected" (đối chiếu lại định nghĩa khi điền: IMAP là kết nối từ máy người dùng tới hộp thư của chính họ, nhà phát triển không nhận gì).
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
  - **MB đổi mẫu email:** bộ đọc chỉ hiểu đúng mẫu đã có → email không đọc được bị bỏ và đếm (AC-85), không lưu sai; bộ đếm tăng là dấu hiệu cần bản cập nhật. Mẫu test lấy từ email thật.
  - **Email không phủ hết chi tiêu:** email MB chỉ là biên lai chuyển tiền đi; tiêu bằng thẻ, phí, tiền vào… có thể không có email → vẫn phải ghi tay. Không có khớp số dư (D-033) nên khoản bị sót không tự lộ ra; người dùng tự đối chiếu số dư.
  - **Trùng giữa ghi tay và email:** chỉ ghép khi khoản ghi tay ở đúng Account "MB Bank …xxxx" (giữ kế hoạch); ghi tay vào "Tiền mặt" hay Account khác thì email vẫn vào hàng đợi và người dùng phải "Bỏ qua" bằng tay. Hai lần chuyển thật cùng giá trong 2 giờ mà chỉ ghi tay một lần → email đầu ghép, email sau vào hàng đợi (đúng).
  - **Hàng đợi bị bỏ quên:** khoản chưa xác nhận không tính vào tổng/ngân sách (D-030) → số trên app thấp hơn thực tế tới khi người dùng xử lý hàng đợi; giảm bằng dòng "N khoản chờ chọn danh mục" ở màn chính.
  - **Mật khẩu ứng dụng:** Google/Yahoo/Apple có thể siết hoặc bỏ mật khẩu ứng dụng cho IMAP; Gmail đòi bật xác minh 2 bước mới tạo được. Mất kênh email thì vẫn nhập tay được.
  - **Chạy nền:** tiết kiệm pin, Samsung "Ứng dụng ngủ" có thể hoãn kiểm thư nền trên Android; luôn kiểm bù khi mở app (AC-82). iOS chỉ kiểm khi mở app.
  - **Phụ thuộc mẫu thật:** chưa có email MB thật thì M1 không làm được (SPEC 3d "Câu hỏi mở").
  - **Phạm vi:** 16 tính năng mới trong 2 phiên điều phối (#3, #4); vượt sức thì cắt theo thứ tự ưu tiên người dùng chọn, ghi vào DECISIONS (D-035).

## 8. Tiêu chí hoàn thành bản 1 (Android + iOS)
- F-01 tới F-26 đạt toàn bộ AC áp dụng cho từng nền tảng (mục 5 "iOS": F-23 chỉ Android; F-22, F-24, F-26 trên iOS theo gạch "iOS (D-022)" của từng F).
- Android: biên bản [M] trên ít nhất một máy Android thật. iOS: biên bản [M] trên iPhone thật (TestFlight) cho các AC áp dụng iOS trước khi phát hành iOS; CI iOS (`ios.yml`) xanh trên nhánh `main`.
- `flutter analyze` không lỗi, `flutter test` đạt.
- `docs/COMPLIANCE.md` không còn dòng "chưa" ở các mục áp dụng cho Android, iOS (P-01 tới P-05) và các thị trường mở bán.
- Đã chạy closed test theo P-09 và sửa lỗi chặn trước khi mở bán trên Play.

## 8b. Tiêu chí hoàn thành bản 2.0 (chưa duyệt) — điều kiện để phát hành (D-035: làm hết rồi mới phát hành)
- Mọi tiêu chí mục 8 vẫn đúng, cộng: F-27 tới F-42 đạt toàn bộ AC trên cả Android và iOS (riêng kiểm thư nền chỉ Android, AC-82).
- Dòng "Đã duyệt 2.0" có ngày.
- Test tự động có đủ: bộ đọc với từng email MB mẫu thật (thành công, và thất bại/đang xử lý nếu có mẫu); chống trùng theo số tham chiếu (tải lại, hai hộp thư, sau "Bỏ qua", sau khôi phục); ghép ±2 giờ (cùng Account, khác Account, hai lần chuyển thật cùng giá, qua nửa đêm, khoản không giờ, chiều ngược AC-94); tự tạo và gắn Account; hàng đợi không tính vào tổng, xác nhận, gợi ý, chuyển sang tài khoản của tôi; máy chủ IMAP giả (chỉ tìm địa chỉ MB, không đánh dấu đã đọc, chặn máy chủ/cổng lạ, không rò mật khẩu); migration v3 → v4; sao lưu/khôi phục có bảng mới và file cũ; tiết kiệm không đổi tổng thu/chi; nợ không đụng số dư; ngưỡng 80% và thông báo mỗi mốc một lần, không số tiền; quy đổi tiền tệ các bảng mới; manifest/Info.plist đúng §5.
- `flutter analyze` sạch, `flutter test` đạt; CI Android + iOS xanh.
- Biên bản [M] trên Galaxy A13: thêm hộp thư Gmail (người dùng tự nhập mật khẩu ứng dụng), chuyển một khoản tiền thật nhỏ từ MB → email vào hàng đợi đúng Account, chọn danh mục → khoản đúng; một lần ghi tay trước rồi chuyển → ghép; kiểm thư nền khi app đóng; vân tay; thông báo ngân sách thật. Claude chỉ dùng adb sau khi hỏi người dùng. Ghi vào `notes/` và `docs/TESTING.md`.
- iOS: [M] trên iPhone qua TestFlight cho email, Face ID, thông báo ngân sách trước khi phát hành iOS.
- `docs/COMPLIANCE.md` và `docs/SECURITY.md` không còn dòng "chưa" ở các mục 2.0 (S-08, S-09, D-11, P-02, P-10…); chính sách quyền riêng tư đã viết lại theo ghi chú cuối 3d và người dùng duyệt câu chữ.
