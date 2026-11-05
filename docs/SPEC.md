# SPEC — Ví Gọn (A002-vigon)

Đã duyệt: 2026-11-03
<!-- Khi người dùng duyệt, đổi thành: "Đã duyệt: YYYY-MM-DD". Chưa có dòng này thì Claude không viết code. -->

## 1. Vấn đề cần giải quyết
Người muốn biết tiền đi đâu mỗi tháng thường bỏ ghi chép vì app quá nhiều bước, đòi tài khoản hoặc gửi dữ liệu lên mạng. Họ đang ghi vào sổ, ghi chú điện thoại hoặc bảng tính, rồi không tổng hợp được. Ví Gọn ghi một khoản chi trong vài giây và cho xem ngay chi tiêu theo danh mục. Chức năng tương đương Monefy, nhưng tên, biểu tượng, icon danh mục và giao diện do mình tự thiết kế.

## 2. Người dùng và tình huống sử dụng trên điện thoại
- Người đi làm, sinh viên, người giữ tiền chợ trong gia đình. Dùng ở Việt Nam và nước khác (tiếng Việt, tiếng Anh).
- Ghi ngay sau khi trả tiền: đứng ở quầy, trên xe, cầm điện thoại MỘT tay, thường không có mạng hoặc mạng yếu.
- Cuối ngày hoặc cuối tháng: ngồi xem biểu đồ, lọc theo kỳ, sửa khoản ghi sai.

## 3. Tính năng bản đầu (MVP) và tiêu chí chấp nhận
Quy ước kiểm chứng: **[T]** = test tự động (`flutter test`), **[M]** = thử tay trên máy Android thật, ghi biên bản vào BACKLOG.

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
- AC-21: Lần mở đầu tự chọn tiền tệ theo vùng của máy (Việt Nam → VND); đổi được trong Cài đặt từ danh sách mã ISO 4217. Bản đầu chỉ dùng MỘT tiền tệ cho toàn app, không quy đổi. [T]
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
- AC-43: App không có quyền INTERNET trong manifest của bản phát hành và không gửi dữ liệu đi đâu. [T: kiểm manifest đã build]

## 4. Ngoài phạm vi (cố ý KHÔNG làm ở bản đầu)
- ~~Bản iOS~~: đưa vào phạm vi ngày 2026-11-04 theo PLAN-001 (người dùng duyệt), xem mục 5 và D-011.
- Tài khoản người dùng, đăng nhập, máy chủ, đồng bộ đám mây (Google Drive, Dropbox).
- Nhiều tiền tệ cùng lúc và quy đổi tỉ giá.
- Ngân sách theo từng danh mục, nhắc nhở bằng thông báo, widget màn hình chính, mở khóa bằng vân tay.
- Quảng cáo, mua trong app, gói Pro, analytics, báo crash bằng SDK.
- Đọc tin nhắn ngân hàng, quét hóa đơn, AI.

## 5. Ràng buộc mobile
- Hệ điều hành: Android; minSdk theo mặc định của phiên bản Flutter được ghim (ghi rõ trong D-xxx khi khởi tạo); targetSdk theo yêu cầu Google Play hiện hành (P-06).
- iOS (thêm 2026-11-04, PLAN-001): cùng codebase Flutter, cùng tính năng và AC như Android; iOS tối thiểu theo mặc định của Flutter được ghim; build trên cloud có máy macOS vì máy phát triển là Windows (D-011); yêu cầu App Store P-01 tới P-05 trong COMPLIANCE. AC ghi [M] phải thử trên cả Android và iPhone thật trước khi phát hành iOS.
- Giao diện: theo bộ thiết kế đã duyệt `design-mobile/screens/` (token, chữ Be Vietnam Pro, icon Material Symbols Rounded), giống nhau trên hai nền tảng, chỉ khác ở chỗ hệ điều hành quyết định (D-010).
- Offline: toàn bộ app chạy không cần mạng; không có tính năng nào gọi mạng. Dữ liệu ghi xuống bộ nhớ máy ngay khi bấm Lưu.
- Quyền thiết bị: KHÔNG xin quyền nào. Sao lưu/khôi phục dùng bảng chia sẻ và trình chọn file của hệ điều hành (không cần quyền bộ nhớ).
- Màn hình: chiều rộng nhỏ nhất 360 dp; chỉ màn hình dọc.
- Hiệu năng/pin: không chạy nền; xem ngưỡng ở 5b.

## 5b. Yêu cầu phi chức năng
Ngưỡng dưới đây là đề xuất của Claude, người dùng chỉnh khi duyệt. Máy đo chuẩn: một máy Android tầm thấp-trung bình (chốt tên máy khi bắt đầu G1).
- Hiệu năng: mở nguội tới màn chính ≤ 2 giây (trung vị 5 lần, bản release); lưu một khoản ≤ 200 ms; cuộn danh sách 5.000 khoản không có khung hình nào trên 32 ms trong Flutter DevTools (bản profile).
- Pin và bộ nhớ: không có tác vụ nền; dùng liên tục 15 phút tiêu hao ≤ 3% pin; bộ nhớ ≤ 200 MB với 10.000 khoản.
- Dung lượng: file APK cho một kiến trúc (arm64) ≤ 25 MB.
- Khả năng truy cập: mục tiêu WCAG 2.2 AA (AC-37 tới AC-40).
- Ổn định: tỉ lệ người dùng không crash ≥ 99,5% theo Android vitals của Play Console, xem mỗi tuần trong tháng đầu sau phát hành.
- Toàn vẹn dữ liệu: tắt app đột ngột ngay sau khi bấm Lưu thì khoản vẫn còn khi mở lại (ghi trong giao dịch cơ sở dữ liệu).

## 5c. Thị trường và tiêu chuẩn bán app
Đã điền mục 1 của `docs/COMPLIANCE.md`: Việt Nam và toàn cầu (nhóm A và B, chưa mở nhóm C), miễn phí, không tài khoản, không SDK, dữ liệu chỉ nằm trên máy. Các mục cần xây tính năng đã thành F-11, F-12 (accessibility, ngôn ngữ), F-13 (chính sách, xóa dữ liệu, kênh báo lỗ hổng, giấy phép nguồn mở).

## 6. Dữ liệu
- Lưu ở đâu: cơ sở dữ liệu SQLite trong bộ nhớ riêng của app trên máy. Không có máy chủ, không đồng bộ. Sao lưu chỉ khi người dùng tự xuất file.
- Dữ liệu nhạy cảm: thói quen chi tiêu và thu nhập (tài chính cá nhân). Bảo vệ bằng bộ nhớ riêng của app, khóa PIN tùy chọn, tắt sao lưu tự động của Android (`allowBackup=false`) để dữ liệu không tự lên đám mây mà người dùng không biết; file sao lưu do người dùng tự giữ (ghi rõ trong app là file không mã hóa ở v1).
- Thu thập dữ liệu: nhà phát triển KHÔNG thu thập gì. Data safety khai "không thu thập, không chia sẻ". Vẫn cần chính sách quyền riêng tư công khai (Play yêu cầu và để giải thích dữ liệu nằm trên máy).

## 7. Rủi ro và điều chưa biết
- Pháp lý: chức năng giống Monefy là được, nhưng tên, icon, giao diện, mô tả store không được sao chép; rà lại trước khi phát hành.
- Mất dữ liệu: không có đám mây nên mất máy là mất dữ liệu nếu người dùng chưa xuất file. Giảm rủi ro: nhắc xuất sao lưu trong Cài đặt (không dùng thông báo đẩy ở v1).
- Quên PIN là mất quyền vào dữ liệu (AC-34); phải nói rõ khi bật khóa.
- Máy này chưa cài Flutter và Android SDK (theo `shared/stacks/flutter.md`); G1 phải cài và chạy `flutter doctor` trước.
- Tài khoản Google Play cá nhân mới cần closed test 12 người trong 14 ngày (P-09).
- Tuổi người dùng: người dưới 18 có thể dùng; app không thu dữ liệu và không có tương tác xã hội. Cần người dùng quyết có tích hợp Play Age Signals hay không (D-12).
- Bán ở EU: CRA áp dụng cho app kể cả miễn phí nếu là hoạt động thương mại; chưa rõ app miễn phí của cá nhân có thuộc phạm vi không, cần luật sư xác nhận trước khi mở bán ở EU.

## 8. Tiêu chí hoàn thành bản đầu
- F-01 tới F-13 đạt toàn bộ AC, có biên bản thử trên ít nhất một máy Android thật.
- `flutter analyze` không lỗi, `flutter test` đạt.
- `docs/COMPLIANCE.md` không còn dòng "chưa" ở các mục áp dụng cho Android và các thị trường mở bán.
- Đã chạy closed test theo P-09 và sửa lỗi chặn trước khi mở bán.
