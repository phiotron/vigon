# SPEC 1.1 — Bổ sung chức năng cho Ví Gọn (APP-001)

Người dùng duyệt làm ngày 2026-11-04 ("làm tiếp đi, chia nhiều agent"). Bổ sung cho `docs/SPEC.md` (F-01..F-13, AC-01..AC-43), không thay thế. Ràng buộc giữ nguyên: **không mạng, không xin thêm quyền thiết bị** (SPEC mục 5, D-002), chỉ màn dọc, mọi chữ trong `.arb` (vi và en), mọi AC có test tự động (`[T]`) hoặc biên bản máy thật (`[M]`).

## F-14 · Quản lý tài khoản: ẩn, hiện, xóa
Hiện chỉ thêm và sửa được tài khoản. Cột `archived` đã có sẵn trong bảng `accounts` (và trong file sao lưu).
- AC-44: Trong bảng sửa tài khoản có nút **"Ẩn tài khoản"**. Tài khoản đã ẩn không hiện trong: bảng chọn tài khoản khi ghi khoản, menu lọc ở màn chính, ô "Từ/Đến" của Chuyển tiền. Khoản và chuyển tiền cũ của nó vẫn nằm trong danh sách khoản và vẫn tính vào thu/chi của kỳ. [T]
- AC-45: **"Xóa tài khoản"** chỉ cho phép khi tài khoản chưa có khoản nào (kể cả chuyển tiền) và không có chuỗi định kỳ nào trỏ tới; nếu có thì nút xóa không hiện và giải thích "Tài khoản đã có khoản, chỉ ẩn được". Xóa có hộp thoại xác nhận. [T]
- AC-46: Luôn còn ít nhất một tài khoản hiện: không ẩn, không xóa tài khoản hiện cuối cùng. [T]
- AC-47: Màn Tài khoản có mục "Tài khoản đã ẩn" (thu gọn, mặc định đóng) liệt kê tài khoản đã ẩn kèm số dư; chạm vào để **"Hiện lại"**. [T]
- Sao lưu và khôi phục giữ nguyên trạng thái ẩn. [T]

## F-15 · Tìm kiếm khoản
- AC-48: Màn "Các khoản" có nút tìm kiếm (icon kính lúp) trên thanh tiêu đề; chạm mở ô nhập. Gõ chữ thì lọc các khoản có **ghi chú, tên danh mục hoặc số tiền** chứa chuỗi đó (không phân biệt hoa thường và dấu tiếng Việt; số tiền khớp theo chữ số, bỏ dấu ngăn cách). [T]
- AC-49: Mặc định tìm trong kỳ đang xem; có chip **"Tất cả thời gian"** để tìm trên toàn bộ dữ liệu. Kết quả là danh sách phẳng theo ngày mới nhất trước, kèm dòng tổng số khoản và tổng tiền khớp; chạm một khoản mở sửa như thường lệ; vuốt xóa và Hoàn tác vẫn dùng được. Không có kết quả thì hiện "Không có khoản nào khớp". [T]
- Tuân theo bộ lọc tài khoản đang chọn ở màn chính. [T]

## F-16 · Sửa đầy đủ khoản định kỳ
Hiện chỉ sửa được số tiền và ghi chú.
- AC-50: Hộp thoại sửa chuỗi định kỳ cho đổi thêm **tần suất** (ngày/tuần/tháng/năm), **danh mục**, **tài khoản**. Khoản đã sinh không đổi; các lần sinh sau theo cài đặt mới. Quy tắc lịch (đã chốt): đổi tần suất thì chuỗi **bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ** (`startDate` = ngày tới hạn kế tiếp cũ, `lastGeneratedDate` = ngày liền trước), nên lần sinh đầu theo tần suất mới chính là ngày đó; không sinh bù các ngày trước và không trùng khoản đã có. Hệ quả cần biết: ngày neo đổi theo lịch mới (ví dụ tuần bắt đầu 03/11 đổi sang tháng thì thành ngày 17 hằng tháng) và neo ngày 31 mất khi đổi qua lại. Không đổi tần suất thì giữ nguyên `startDate`, `lastGeneratedDate`. [T]

## F-17 · Mọi danh mục chi đều chạm được từ màn chính
- AC-51: Khi số danh mục chi nhiều hơn số icon xếp vừa quanh biểu đồ, icon thứ cuối thành ô **"Thêm"** (dấu ⋯, nhãn "Danh mục khác") mở lưới chọn danh mục chi đầy đủ; chọn một danh mục thì mở màn Nhập khoản chi với danh mục đó. Khi đủ chỗ thì giữ như cũ. [T]

## F-18 · CSV theo ngôn ngữ
- AC-52: Tiêu đề cột và tên loại khoản (chi/thu/chuyển tiền) trong file CSV theo ngôn ngữ đang dùng của app (vi hoặc en). Tiếng Việt: dùng dấu `;` ngăn cột và dấu `,` thập phân (Excel vùng Việt đọc đúng); tiếng Anh: dấu `,` ngăn cột và `.` thập phân. Vẫn UTF-8 có BOM và vẫn chặn chèn công thức. [T]

## F-19 · Đủ tiền tệ ISO 4217
- AC-53: Danh sách tiền tệ trong Cài đặt có đủ các mã ISO 4217 đang dùng (khoảng 150 mã), có **ô tìm** theo mã hoặc tên; số chữ số thập phân theo đúng ISO (0, 2 hoặc 3 chữ số, ví dụ JPY 0, USD 2, KWD 3). Đổi giữa các tiền tệ có số chữ số khác nhau vẫn giữ đúng con số hiển thị (D-005). [T]

## F-20 · Ngân sách theo danh mục
- AC-54: Mỗi danh mục chi có thể đặt **hạn mức tháng riêng** (trong bảng sửa danh mục, ô "Ngân sách tháng của danh mục", để trống là không đặt). Ở màn "Các khoản", dòng danh mục có hạn mức hiện thanh tiến độ nhỏ và chữ "Vượt X" (kèm màu và chữ, không chỉ màu) khi chi trong tháng hiện tại vượt hạn mức. Ngân sách tổng hiện có (AC-26) giữ nguyên và độc lập. [T]
- Cần đổi cơ sở dữ liệu: thêm cột hạn mức vào bảng danh mục, tăng `schemaVersion` lên 2 và có migration giữ dữ liệu cũ; file sao lưu mang theo hạn mức, đọc được file sao lưu cũ (không có cột này) và khôi phục đúng. [T]

## F-21 · Mã hóa file sao lưu bằng mật khẩu
- AC-55: Khi **Xuất bản sao lưu** có lựa chọn "Đặt mật khẩu cho file" (tùy chọn, mặc định tắt; nhập mật khẩu hai lần, tối thiểu 6 ký tự; cảnh báo "Quên mật khẩu thì không mở được file này"). Có mật khẩu: file `.vigon` được mã hóa (khóa suy ra từ mật khẩu bằng PBKDF2-HMAC-SHA256 nhiều vòng và muối ngẫu nhiên, mã hóa AES-256-GCM); không mật khẩu: như cũ. Khôi phục: nhận ra file mã hóa, hỏi mật khẩu; sai mật khẩu hoặc file bị sửa thì báo "Sai mật khẩu hoặc file bị hỏng", không đụng dữ liệu hiện có. File sao lưu cũ không mã hóa vẫn khôi phục được. [T]
- Mật khẩu không được lưu ở đâu cả. Không thêm quyền, không dùng mạng.

## F-22 · Che nội dung ở màn đa nhiệm
- AC-56: Mục Bảo mật trong Cài đặt có công tắc **"Che nội dung khi chuyển app"**. Bật: Android chặn chụp màn hình và hiện màn trống trong danh sách app gần đây (cờ `FLAG_SECURE` của cửa sổ). Mặc định tắt. Lưu trong bảng `settings`, áp dụng ngay khi mở app lần sau và khi đổi công tắc. [T cho phần lưu và công tắc; M cho hiệu ứng thật trên máy]

## F-23 · Biểu tượng đơn sắc
- AC-57: Icon thích ứng có lớp `<monochrome>` để Android 13 trở lên tô màu theo giao diện hình nền. Hình đơn sắc là cùng logo "hai thẻ xếp chồng" (D-009), một màu. [M]

---

## Ngoài phạm vi 1.1, chưa làm vì cần người dùng quyết (phá cam kết hiện tại của app)
| Mục | Vì sao chưa làm |
|-----|-----------------|
| Đồng bộ hoặc sao lưu lên Google Drive, Dropbox | Cần mạng, đăng nhập tài khoản; trái D-002; kéo theo quyền INTERNET, khai Data safety khác, chính sách quyền riêng tư viết lại, nhiều mục COMPLIANCE |
| Nhắc ghi chép bằng thông báo | Cần quyền thông báo (Android 13+) và có thể báo thức chính xác; trái "không xin quyền nào"; Play yêu cầu giải thích quyền |
| Widget màn hình chính | Phần Android gốc (AppWidget); hiện số liệu tài chính ngoài màn khóa PIN, cần quyết định riêng về quyền riêng tư |
| Nhiều tiền tệ kèm quy đổi tỉ giá | Tỉ giá cần nguồn dữ liệu (mạng) hoặc người dùng tự nhập; thay đổi lớn mô hình dữ liệu (mỗi tài khoản một tiền tệ) |
| Bản iOS | Chat khác đang lập `PLAN-001` (D-010, D-011); không làm ở đây |
| Gói Pro hoặc nguồn thu khác | Thanh toán trong app, Play Billing, COMPLIANCE C-01/C-02/T-01, thuế |
