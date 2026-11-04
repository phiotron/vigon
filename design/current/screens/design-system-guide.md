Ví Gọn là sổ thu chi cá nhân, không mạng, dữ liệu chỉ nằm trên máy. Một bộ giao diện dùng chung cho iPhone và Android (Flutter), chỉ màn dọc. Mọi màn hình nằm ở mục Components, xếp theo luồng sử dụng từ 01 (Mở app) đến 09 (Giới thiệu); nhóm 10 là các thành phần dựng nên chúng.

## Luồng màn hình

| Nhóm | Thẻ | Màn hình |
|---|---|---|
| 01 · Mở app | `S01_KhoaPIN` | Màn khóa, sai mã, Quên mã (3 bước) |
| 02 · Màn chính | `S02_ManChinh`, `S03_ChonKy` | Màn chính có dữ liệu, vượt ngân sách, kỳ trống; bảng chọn kỳ, khoảng tùy chọn, lọc tài khoản |
| 03 · Ghi khoản | `S04_GhiKhoan`, `S05_TuyChonGhi` | Khoản chi mới → gõ phép tính → chọn danh mục → Lưu; lặp lại, tài khoản, lỗi, khoản thu |
| 04 · Xem và sửa khoản | `S06_CacKhoan`, `S07_SuaKhoan` | Các khoản, vuốt xóa, Hoàn tác, trống; Sửa khoản, dừng lặp, đang nạp |
| 05 · Cài đặt | `S08_CaiDat`, `S09_NganSachTienTe` | Cài đặt hai phần; ngân sách, tiền tệ, ngày bắt đầu tháng |
| 06 · Danh mục và tài khoản | `S10_DanhMuc`, `S11_TaiKhoan` | Danh mục, sửa, xóa; tài khoản, thêm, chuyển tiền |
| 07 · Khoản định kỳ | `S12_DinhKy` | Danh sách chuỗi, sửa, trống |
| 08 · Bảo mật và dữ liệu | `S13_DatPIN`, `S14_SaoLuu`, `S15_XoaDuLieu` | Đặt/tắt PIN; sao lưu, khôi phục; xóa toàn bộ |
| 09 · Giới thiệu | `S16_GioiThieu` | Giới thiệu, lỗi không mở được |

Mỗi khung có số bước (ví dụ 3.2) để nhắc tới trong trao đổi và trong ticket.

## Nội dung chữ

- Viết tiếng Việt ngắn, nói thẳng việc sẽ xảy ra: “Xóa toàn bộ dữ liệu”, không “Bạn có chắc không?”.
- Không xưng “tôi”; gọi người dùng là “bạn” chỉ khi cần (“Bạn có thể xóa toàn bộ dữ liệu trong app để dùng lại.”).
- Viết hoa chữ đầu câu và tên riêng, không viết hoa cả từ. Không dùng emoji.
- Nút ghi động từ hoặc kết quả: “Lưu”, “Chọn danh mục”, “Hoàn tác”, “Bỏ ngân sách”. Nút hủy luôn là “Hủy”.
- Số tiền: vi `155.000 ₫` (dấu chấm ngăn nghìn, ký hiệu sau, khoảng trắng không ngắt dòng); en `₫155,000`. Số âm có dấu `-`.
- Ngày ngắn: `3 thg 11, 2026`; hôm nay ghi “Hôm nay”. Phần trăm một chữ số thập phân: `53,7%`.
- Mọi chữ lấy từ `app_vi.arb` / `app_en.arb`; không viết cứng trong giao diện.

## Màu

- Nền màn hình `surface`; bảng kéo, menu `surface-container`; hộp thoại, thanh Số dư, phím số `surface-container-high`.
- Chữ chính `ink`, chữ phụ `ink-muted`, cả hai trên mọi nền surface ở hai chủ đề.
- `primary` (`#2E7D6B`) cho công tắc bật, tab đang chọn, thanh ngân sách, nút Lưu ở Chuyển tiền, tiêu đề nhóm cài đặt. Không dùng `primary` làm chữ trên `surface-container-high` (chỉ 4,06:1 ở chủ đề sáng).
- Thu `income`, chi `expense`; chữ trên nền của chúng là `on-income`, `on-expense` (trắng ở sáng, đen ở tối). Hai màu này là màu gốc của app và cùng độ sáng, nên **luôn kèm dấu − / + hoặc chữ Chi / Thu**; không phân biệt thu chi chỉ bằng màu. Không đặt chữ `income` trên `surface-container-high` ở chủ đề sáng (4,22:1).
- Lỗi, vượt ngân sách, hành động xóa: `error`; nút xóa trong hộp thoại nền `error`, chữ `on-error`.
- Danh mục: 16 màu đậm `cat-01` … `cat-16`, giống nhau ở hai chủ đề, icon luôn `on-cat` (trắng). Danh mục mặc định: Ăn uống `cat-13`, Đi lại `cat-06`, Nhà cửa `cat-09`, Hóa đơn `cat-05`, Mua sắm `cat-02`, Sức khỏe `cat-01`, Giải trí `cat-03`, Học tập `cat-08`, Gia đình `cat-15`, Khác `cat-16`; thu: Lương `cat-10`, Thưởng `cat-12`.
- Thanh thông báo `inverse-surface` + `inverse-ink`, nút hành động `inverse-primary`.
- Lớp phủ sau hộp thoại và bảng: `scrim`. `canvas` chỉ là nền bảng trình bày, không dùng trong app.
- Vòng focus 2px màu `focus`, liền nét, đủ 3:1 trên mọi nền.

## Chữ

- Họ chữ **Be Vietnam Pro** (Google Fonts, giấy phép OFL), vẽ cho dấu tiếng Việt, dùng giống nhau trên iPhone và Android; nhúng vào app bằng file font, không tải lúc chạy.
- Số tiền luôn dùng số đều độ rộng (`font-feature-settings: "tnum"`), để cột tiền thẳng hàng.
- Số tiền đang gõ `amount-xl` (tự co nhỏ cho vừa); tổng thu chi, số dư `amount-md`.
- Tiêu đề thanh trên `title-lg`; hộp thoại, bảng, tên kỳ `title-md`; tiêu đề phần `title-sm`.
- Chữ thường `body-md`; phụ đề, ngày `body-sm`. Nút lớn `label-lg`; chip, tab, nút hộp thoại `label-md`; tên dưới icon `label-sm`.
- Bàn phím `key-digit`; dấu trên hai nút lớn `key-glyph`.
- Chữ lớn (≥ 130% cỡ chữ hệ thống): số tiền chuyển xuống dưới tiêu đề, nút chọn một xếp dọc, phần trên bàn phím cuộn được.

## Khoảng cách, vùng chạm, bo góc

- Lề màn hình `space-4` (16). Lề trong hộp thoại `space-6`. Giữa các phím, chip `space-2`; giữa hai nút lớn `space-3`.
- Vùng chạm tối thiểu `tap-min` (48) cho mọi nút; dòng danh sách, phím số, thanh Số dư `tap-key` (56); nút − + và phím PIN `tap-main` (64). Áp dụng như nhau cho pt (iPhone) và dp (Android).
- Thanh tiêu đề cao `appbar` (56), tiêu đề căn trái trên cả hai nền tảng.
- Bo góc: chip, ô nhập, thanh thông báo `radius-sm`; phím số, thanh Số dư `radius-md`; nút − +, nút Lưu, nút nổi `radius-lg`; hộp thoại và góc trên bảng kéo `radius-xl`; icon tròn, công tắc, phím PIN `radius-full`.
- Bóng chỉ cho thứ nổi lên: bảng kéo `shadow-sheet`; nút nổi, menu, thanh thông báo `shadow-float`. Thẻ và dòng không có bóng.

## Bố cục màn hình

- Các nút chính nằm nửa dưới màn hình, trong tầm ngón cái: nút − + ở màn chính, bàn phím số ghim đáy ở Nhập khoản và Chuyển tiền.
- Màn nhập số dùng **bàn phím số riêng của app**, không bật bàn phím hệ thống. Phần trên bàn phím cuộn được khi thiếu chỗ.
- Bảng kéo từ dưới lên cho việc chọn (danh mục, kỳ, lặp lại, tài khoản, sửa danh mục); hộp thoại giữa màn cho xác nhận và nhập một giá trị.
- Xóa một khoản không hỏi lại; luôn có thanh “Đã xóa · Hoàn tác” 5 giây. Xóa dữ liệu lớn (danh mục, toàn bộ) luôn qua hộp thoại.
- Lỗi nhập liệu hiện ngay dưới ô hoặc dưới số tiền, màu `error`, không dùng hộp thoại.

## iPhone và Android

Cùng một bố cục, cùng màu, cùng chữ trên hai nền tảng. Chỉ khác ở chỗ hệ điều hành quyết định:

| Việc | iPhone | Android |
|---|---|---|
| Vùng an toàn trên/dưới | Tai thỏ / Dynamic Island, thanh Home | Thanh trạng thái, thanh điều hướng cử chỉ |
| Quay lại | Mũi tên trên thanh tiêu đề và vuốt từ mép trái | Mũi tên và nút/cử chỉ Back |
| Hủy đặt PIN (8.1) | Mũi tên quay lại hoặc vuốt mép | Mũi tên hoặc Back |
| Chia sẻ file sao lưu, CSV | Bảng chia sẻ iOS | Sharesheet Android |
| Chọn file khôi phục | Ứng dụng Tệp | Trình chọn file hệ thống |
| Lưu mã PIN băm | Keychain | Keystore |
| Rung khi sai PIN, khi xóa | Haptic nhẹ | Haptic nhẹ |

Vì iPhone không có nút Back cứng, **mọi màn con phải có mũi tên quay lại hoặc nút đóng nhìn thấy được**. Lịch chọn khoảng ngày (2.5) là lịch riêng của app trong bảng kéo, để giống nhau trên hai nền tảng.

## Biểu tượng

- Dùng **Material Symbols Rounded** (Google, Apache 2.0) cho mọi icon, nét 400, cỡ 24 (20–22 trong dòng và chip). Icon danh mục dùng bản tô đầy (`FILL 1`) trên nền màu danh mục; icon chức năng dùng bản nét.
- 31 icon chọn được cho danh mục: restaurant, local_cafe, directions_bus, two_wheeler, local_gas_station, home, receipt_long, bolt, water_drop, wifi, shopping_bag, checkroom, health_and_safety, medication, movie, sports_esports, school, menu_book, family_restroom, child_care, pets, redeem, payments, savings, work, flight, fitness_center, spa, volunteer_activism, build, more_horiz.
- Không dùng emoji thay icon. App chưa có logo; tên “Ví Gọn” đặt bằng chữ.

## Khả năng tiếp cận

- Mọi nút có nhãn đọc: icon danh mục quanh biểu đồ “Thêm khoản chi: Ăn uống, 1.240.000 ₫, 19,0%”; phím “Xóa lùi”, “Bằng”; PIN “Số N”, “Đã nhập N trên 4 số”.
- Biểu đồ đọc thành một câu “Chi tiêu theo danh mục: Nhà cửa, 3.500.000 ₫, 53,7%; …”.
- Vùng số tiền đang gõ và dòng lỗi PIN là vùng thông báo trực tiếp.
- Màu không bao giờ là kênh duy nhất: vượt ngân sách có chữ “Vượt” và icon cảnh báo; thu chi có dấu và vị trí; ô màu đang chọn có viền và dấu ✓.
- Chữ đạt 4,5:1 trên nền của nó ở cả hai chủ đề (trừ hai cặp ghi ở mục Màu); viền, icon, vòng focus đạt 3:1.
