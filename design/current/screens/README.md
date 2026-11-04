# Ví Gọn (A002-vigon) — thiết kế màn hình mobile

Bộ thiết kế giao diện dùng chung cho iPhone và Android, dựng từ `ui-spec.md` (bản 1.0.0+1, 2026-11-03). Nguồn gốc là design system “Ví Gọn” trên claude.ai; thư mục này là bản sao để đội code dùng offline.

## Có gì trong thư mục

| Đường dẫn | Nội dung |
|---|---|
| `README.md` | File này: token, khác biệt iOS/Android, danh sách màn, điều hướng, hướng dẫn code |
| `design-system-guide.md` | Quy tắc thiết kế đầy đủ (chữ, màu, khoảng cách, bố cục, biểu tượng, khả năng tiếp cận) |
| `tokens.json` | **Nguồn sự thật** của mọi token (màu sáng/tối, chữ, khoảng cách, bo góc, vùng chạm, bóng) |
| `tokens.css` | Token đã biên dịch ra biến CSS (sinh từ `tokens.json`, không sửa tay) |
| `bundle.css` | CSS dựng khung điện thoại và thành phần trong bản vẽ |
| `components/<Thẻ>/preview.html` | Source bản vẽ của từng nhóm màn (HTML tĩnh dùng token) |
| `components/<Thẻ>/README.md` | Ghi chú thiết kế của nhóm màn đó |
| `components/Cover/preview.html` | Bìa của design system |
| `xem/index.html` | **Mở file này để xem thiết kế**: mỗi nhóm màn một trang, có nút Sáng / Tối |

`preview.html` gốc không tự nạp `tokens.css` và `bundle.css`, vì trang design system nạp sẵn hai file đó. Muốn xem trên máy thì mở bản trong `xem/`; các trang này cần mạng để tải font từ Google Fonts.

> Design system này không có file `.dc.html` hay `canvas.json`. Hai loại file đó là của kiểu Design (canvas), còn bộ này làm bằng kiểu Design System, nên source là các file `preview.html`, `tokens.json` và README ở trên.

## Design tokens

Tên token giống nhau ở `tokens.json`, `tokens.css` và bản vẽ. Dưới đây là phần đội code cần nhớ; giá trị đầy đủ xem `tokens.json`.

### Màu (sáng / tối)

| Token | Sáng | Tối | Dùng cho |
|---|---|---|---|
| `primary` | `#2E7D6B` | `#8CD5BF` | Màu gốc: công tắc bật, tab đang chọn, thanh ngân sách, nút Lưu ở Chuyển tiền |
| `on-primary` | `#FFFFFF` | `#00382D` | Chữ trên `primary` |
| `primary-container` / `on-…` | `#B8EDDC` / `#002019` | `#0E5244` / `#B8EDDC` | Nút nổi +, dòng đang chọn trong bảng chọn |
| `secondary-container` / `on-…` | `#CCE8DF` / `#062019` | `#334B44` / `#CCE8DF` | Phím phép tính ÷ × − + = |
| `surface` | `#F7FAF8` | `#0F1513` | Nền màn hình |
| `surface-container` | `#ECF2EF` | `#1B211F` | Bảng kéo, menu |
| `surface-container-high` | `#E3EBE7` | `#252B29` | Hộp thoại, thanh Số dư, phím số |
| `ink` / `ink-muted` | `#171D1B` / `#3F4946` | `#DEE4E1` / `#BEC9C4` | Chữ chính / chữ phụ |
| `outline` / `outline-variant` | `#6F7975` / `#BEC9C4` | `#89938F` / `#3F4946` | Viền ô nhập, chip / đường kẻ |
| `income` / `on-income` | `#2E7D32` / `#FFFFFF` | `#81C784` / `#0A1F0B` | Tiền thu, nút + |
| `expense` / `on-expense` | `#C62828` / `#FFFFFF` | `#EF9A9A` / `#2D0A0A` | Tiền chi, nút − |
| `error` / `on-error` | `#BA1A1A` / `#FFFFFF` | `#FFB4AB` / `#690005` | Lỗi, vượt ngân sách, hành động xóa |
| `swipe-delete` | `#FFDAD6` | `#5C1714` | Nền khi vuốt xóa |
| `inverse-surface` / `inverse-ink` / `inverse-primary` | `#2C3230` / `#EDF2EF` / `#8CD5BF` | `#DEE4E1` / `#2C3230` / `#0E5244` | Thanh thông báo, nút Hoàn tác |
| `focus` | `#0E5244` | `#8CD5BF` | Vòng focus 2px |
| `scrim` | `rgba(0,0,0,.40)` | `rgba(0,0,0,.60)` | Lớp phủ sau hộp thoại |
| `cat-01` … `cat-16` | giống nhau ở hai chủ đề | | Màu danh mục, icon luôn trắng (`on-cat`) |

Màu danh mục: 01 `#C62828`, 02 `#AD1457`, 03 `#6A1B9A`, 04 `#4527A0`, 05 `#283593`, 06 `#1565C0`, 07 `#0277BD`, 08 `#00838F`, 09 `#00695C`, 10 `#2E7D32`, 11 `#558B2F`, 12 `#827717`, 13 `#E65100`, 14 `#BF360C`, 15 `#6D4C41`, 16 `#546E7A`.
Danh mục mặc định: Ăn uống 13, Đi lại 06, Nhà cửa 09, Hóa đơn 05, Mua sắm 02, Sức khỏe 01, Giải trí 03, Học tập 08, Gia đình 15, Khác 16; thu: Lương 10, Thưởng 12, Khác 16.

Hai cặp chưa đạt 4,5:1 ở chủ đề sáng, nên **không dùng**: chữ `income` trên `surface-container-high` (4,22:1) và chữ `primary` trên `surface-container-high` (4,06:1).

### Chữ — Be Vietnam Pro

| Style | Cỡ / dòng | Đậm | Dùng cho |
|---|---|---|---|
| `amount-xl` | 40 / 48 | 600 | Số tiền đang gõ (tự co nhỏ) |
| `amount-md` | 18 / 24 | 600 | Tổng thu, chi, số dư |
| `title-lg` | 22 / 28 | 600 | Tiêu đề thanh trên |
| `title-md` | 18 / 24 | 600 | Hộp thoại, bảng kéo, tên kỳ |
| `title-sm` | 16 / 24 | 600 | Tiêu đề phần, nhóm cài đặt |
| `body-md` | 16 / 24 | 400 | Chữ thường |
| `body-sm` | 14 / 20 | 400 | Phụ đề, ngày |
| `label-lg` | 16 / 24 | 600 | Nút lớn |
| `label-md` | 14 / 20 | 500 | Chip, tab, nút hộp thoại |
| `label-sm` | 12 / 16 | 500 | Tên dưới icon, bộ đếm |
| `key-digit` | 24 / 32 | 500 | Phím số, phím PIN |
| `key-glyph` | 32 / 40 | 500 | Dấu − + trên nút lớn |

Mọi số tiền dùng số đều độ rộng (`FontFeature.tabularFigures()`).

### Khoảng cách, bo góc, vùng chạm, bóng

- Khoảng cách: `space-1` 4, `space-2` 8, `space-3` 12, `space-4` 16 (lề màn hình), `space-6` 24, `space-8` 32.
- Bo góc: `radius-sm` 8 (chip, ô nhập, thanh thông báo), `radius-md` 12 (phím số, thanh Số dư), `radius-lg` 16 (nút − +, Lưu, nút nổi), `radius-xl` 28 (hộp thoại, góc trên bảng kéo), `radius-full` (icon tròn, công tắc, phím PIN).
- Vùng chạm: `tap-min` 48, `tap-key` 56 (phím số, dòng danh sách), `tap-main` 64 (nút − +, phím PIN), `appbar` 56. Đơn vị là dp trên Android, pt trên iPhone (Flutter dùng logical pixel cho cả hai).
- Bóng: `shadow-sheet` cho bảng kéo, `shadow-float` cho nút nổi, menu, thanh thông báo. Thẻ và dòng không có bóng.

## Khác biệt iOS / Android

Bố cục, màu, chữ và icon giống nhau trên hai nền tảng. Chỉ khác ở những chỗ do hệ điều hành quyết định:

| Việc | iPhone | Android |
|---|---|---|
| Vùng an toàn | Tai thỏ / Dynamic Island, thanh Home | Thanh trạng thái, thanh cử chỉ. Bật edge-to-edge |
| Quay lại | Mũi tên trên thanh tiêu đề + vuốt từ mép trái (`CupertinoPageTransitionsBuilder`) | Mũi tên + nút/cử chỉ Back, có predictive back |
| Hủy đặt PIN (8.1) | Mũi tên hoặc vuốt mép | Mũi tên hoặc Back |
| Thoát app | Không có nút thoát; Home | Back ở màn chính thì thoát |
| Chia sẻ file sao lưu, CSV | Bảng chia sẻ iOS (`UIActivityViewController`) | Sharesheet |
| Chọn file khôi phục | Ứng dụng Tệp (`UIDocumentPicker`) | Trình chọn file hệ thống (SAF) |
| Lưu mã PIN băm | Keychain | Keystore (`EncryptedSharedPreferences`) |
| Khóa chiều dọc | `UISupportedInterfaceOrientations` trong `Info.plist` | `screenOrientation` trong manifest |
| Mở email / trang web | `mailto:` / Safari | Intent, không cần quyền INTERNET |
| Rung | Haptic nhẹ khi sai PIN, khi xóa | Haptic nhẹ |
| Trình đọc màn hình | VoiceOver | TalkBack |

Quy tắc chung:

- iPhone không có nút Back cứng, nên **mọi màn con phải có mũi tên quay lại hoặc nút đóng nhìn thấy được**.
- Hộp chọn ngày một ngày (chip ngày) dùng bản Material ở cả hai nền tảng cho giống nhau. Khoảng tùy chọn (2.5) là lịch riêng của app trong bảng kéo.
- Thanh tiêu đề căn trái ở cả hai nền tảng (đặt `centerTitle: false`, vì mặc định trên iOS là căn giữa).
- Repo hiện chỉ có thư mục `android/`. Muốn chạy trên iPhone cần thêm iOS (`flutter create --platforms ios .`), rồi khai báo khóa chiều dọc, quyền Face ID nếu sau này dùng, và icon.

## Danh sách màn theo nhóm luồng

Mỗi khung trong bản vẽ có số bước (ví dụ 3.2) để nhắc trong ticket. Route lấy từ `lib/src/app.dart`.

| Nhóm | Thẻ (`components/…`) | Khung | Route / nơi mở |
|---|---|---|---|
| 01 · Mở app | `S01_KhoaPIN` | 1.1 Màn khóa · 1.2 Sai mã · 1.3–1.5 Quên mã (3 hộp thoại) | Lớp phủ `LockScreen`, ngoài router |
| 02 · Màn chính | `S02_ManChinh` | 2.1 Có dữ liệu · 2.2 Vượt ngân sách · 2.3 Kỳ trống | `/` |
| | `S03_ChonKy` | 2.4 Bảng chọn kỳ · 2.5 Khoảng tùy chọn · 2.6 Lọc tài khoản | Bảng kéo / menu trên `/` |
| 03 · Ghi khoản | `S04_GhiKhoan` | 3.1 Khoản chi mới · 3.2 Gõ phép tính · 3.3 Chọn danh mục · 3.4 Sẵn sàng lưu | `/entry/new?type=expense[&category=id]` |
| | `S05_TuyChonGhi` | 3.5 Lặp lại · 3.6 Chọn tài khoản · 3.7 Lỗi phép tính · 3.8 Khoản thu mới | `/entry/new?type=income` |
| 04 · Xem và sửa | `S06_CacKhoan` | 4.1 Các khoản · 4.2 Vuốt xóa · 4.3 Hoàn tác · 4.4 Trống | `/entries` |
| | `S07_SuaKhoan` | 4.5 Sửa khoản · 4.6 Đã dừng lặp · 4.7 Đang nạp | `/entry/:id` |
| 05 · Cài đặt | `S08_CaiDat` | 5.1 Phần trên · 5.2 Phần dưới | `/settings` |
| | `S09_NganSachTienTe` | 5.3 Ngân sách · 5.4 Lỗi ngân sách · 5.5 Tiền tệ · 5.6 Ngày bắt đầu tháng | Hộp thoại / menu trên `/settings` |
| 06 · Danh mục, tài khoản | `S10_DanhMuc` | 6.1 Danh mục · 6.2 Sửa danh mục · 6.3 Xóa danh mục | `/categories` |
| | `S11_TaiKhoan` | 6.4 Tài khoản · 6.5 Thêm/sửa · 6.6 Chuyển tiền · 6.7 Lỗi chuyển tiền | `/accounts`, `/transfer`, `/transfer/:id` |
| 07 · Khoản định kỳ | `S12_DinhKy` | 7.1 Danh sách · 7.2 Sửa chuỗi · 7.3 Trống | `/recurring` |
| 08 · Bảo mật, dữ liệu | `S13_DatPIN` | 8.1 Đặt PIN · 8.2 Nhập lại · 8.3 Không khớp · 8.4 Tắt PIN | Màn toàn khung từ `/settings` |
| | `S14_SaoLuu` | 8.5 Xuất sao lưu · 8.6 Khôi phục · 8.7 Khôi phục xong · 8.8 File hỏng | Từ `/settings` |
| | `S15_XoaDuLieu` | 8.9–8.10 Hai hộp thoại · 8.11 Sau khi xóa | Từ `/settings` |
| 09 · Giới thiệu | `S16_GioiThieu` | 9.1 Giới thiệu · 9.2 Không mở được | `/about` |
| 10 · Thành phần | `T1_Nut`, `T2_BanPhim`, `T3_ChipDong` | Nút, bàn phím số, chip, dòng, thanh ngân sách, thông báo | Dùng chung |

## Tab bar theo vai trò

**Ví Gọn không có tab bar và không có vai trò người dùng.** Đây là app một người dùng, không tài khoản, không máy chủ (ui-spec mục 1–2), nên không có quyền hay menu nào khác nhau theo vai trò. Đừng thêm `BottomNavigationBar` hay `NavigationBar`.

Điều hướng là một chồng màn (stack) từ màn chính:

- Thanh tiêu đề màn chính có 3 lối: icon ví (lọc tài khoản, chỉ hiện khi có từ 2 tài khoản), Các khoản (`/entries`), Cài đặt (`/settings`).
- Vùng dưới màn chính là hai nút lớn − / + để ghi khoản, không phải tab.
- Mọi màn khác mở bằng `context.push` và quay lại bằng mũi tên hoặc Back/vuốt mép.

Nếu sau này cần tab bar (ví dụ app có nhiều người dùng chung một ví), đó là thay đổi tính năng: cần cập nhật `docs/SPEC.md` và `ui-spec.md` trước rồi mới thiết kế lại.

## Hướng dẫn cho người code (Flutter)

### 1. Token → theme

- Đọc `tokens.json` một lần, sinh ra `lib/src/ui/tokens.g.dart` bằng một script trong `tool/`, rồi chạy lại mỗi khi token đổi. Không gõ tay mã màu trong widget.
- Bỏ `ColorScheme.fromSeed(seedColor: _seedColor)` trong `app.dart`. Tạo `ColorScheme` sáng và tối từ token, để màu giống bản vẽ thay vì màu Material tự sinh:
  `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondaryContainer`, `onSecondaryContainer`, `surface`, `surfaceContainer`, `surfaceContainerHigh`, `onSurface` = `ink`, `onSurfaceVariant` = `ink-muted`, `outline`, `outlineVariant`, `error`, `onError`, `inverseSurface`, `onInverseSurface` = `inverse-ink`, `inversePrimary`, `scrim`.
- Màu không có chỗ trong `ColorScheme` (`income`, `on-income`, `expense`, `on-expense`, `swipe-delete`, `focus`, `cat-01…16`) cho vào một `ThemeExtension<ViGonColors>` có bản sáng và tối.
- Khoảng cách, bo góc, vùng chạm: hằng số trong `tokens.g.dart` (`VgSpace.s4 = 16`, `VgRadius.lg = 16`, `VgTap.key = 56`…).
- `TextTheme`: map 12 style ở trên. Số tiền thêm `fontFeatures: [FontFeature.tabularFigures()]`.

### 2. Font và icon

- **Be Vietnam Pro**: đóng file `.ttf` (400, 500, 600, 700) vào `assets/fonts/` và khai trong `pubspec.yaml`. Không tải lúc chạy, vì app không có mạng và trên Android không xin quyền INTERNET.
- **Material Symbols Rounded**: dùng package `material_symbols_icons` (bản Rounded, weight 400), hoặc đóng font. Icon danh mục dùng bản tô đầy (`fill: 1`), icon chức năng dùng bản nét.
- 31 icon danh mục theo đúng thứ tự trong `design-system-guide.md` mục Biểu tượng; lưu trong DB bằng chỉ số 1…31 như hiện tại.

### 3. Thành phần cần dựng

| Widget | Bản vẽ | Ghi chú |
|---|---|---|
| `MainActionButton` (− / +) | `T1_Nut`, 2.1 | Cao 64, `radius-lg`, có dấu và chữ “Chi”/“Thu” |
| `AmountKeypad` | `T2_BanPhim` | Lưới 4×5, phím 56, cách 8; “000” hoặc “.” theo số lẻ của tiền tệ; nút cuối chiếm 3 cột |
| `AmountDisplay` | 3.2 | Biểu thức `body-md` `ink-muted`, kết quả `amount-xl` dùng `FittedBox`; là `Semantics(liveRegion: true)` |
| `EntryChip` | `T3_ChipDong` | Cao 40, vùng chạm 48, viền `outline`, chip danh mục có chấm màu 24 |
| `CategoryAvatar` | 4.1, 6.1 | Tròn 40 (danh sách) / 48 (lưới, quanh biểu đồ), nền `cat-xx`, icon trắng |
| `SpendingRing` | 2.1 | `fl_chart` `PieChart`: `centerSpaceRadius` 77, mỗi cung `radius` 30 (ngoài 107), bắt đầu 12 giờ (`startDegreeOffset: -90`), sắp lớn → nhỏ, `sectionsSpace` 2 |
| `RingCategoryIcons` | 2.1 | Icon 48 xếp đều trên vòng bán kính 140 (khung 328), bắt đầu 12 giờ |
| `BudgetBar` | `T3_ChipDong`, 2.2 | Thanh 8, `radius-full`; vượt thì chữ `error` đậm + icon cảnh báo + thanh đầy |
| `BalanceBar` | 2.1 | Cao 56, `surface-container-high`, `radius-md`, có mũi tên › |
| `PinPad` | 1.1, 8.1 | Lưới 3×4, phím 88×64 bầu dục; chấm 16 |
| `VgBottomSheet` | 2.4, 3.3 | `surface-container`, góc trên 28, tay nắm 32×4 |
| `VgDialog` | 1.3, 5.3 | `surface-container-high`, bo 28, lề 24; nút nguy hiểm nền `error` |
| Thanh thông báo | 4.3 | `SnackBar` floating, `inverse-surface`, 5 giây; dùng `rootMessengerKey` có sẵn |

### 4. Quy tắc bố cục

- Lề màn hình 16. Nút chính nằm nửa dưới. Bàn phím số luôn ghim đáy; phần trên bọc `SingleChildScrollView`.
- Chữ lớn ≥ 130% (`MediaQuery.textScalerOf(context).scale(1) >= 1.3`): số tiền xuống dưới tiêu đề dòng, nút chọn một ở Cài đặt xếp dọc. Kiểm ở 100% và 200%.
- Danh sách Các khoản dựng lười (`ListView.builder` / `SliverList`).
- Vuốt xóa dùng `Dismissible` (hướng `endToStart`), nền `swipe-delete`, icon `error`.

### 5. Khả năng tiếp cận

- Nhãn đọc giữ đúng như ui-spec mục 8: icon quanh biểu đồ “Thêm khoản chi: Ăn uống, 1.240.000 ₫, 19,0%”; biểu đồ đọc một câu; PIN “Số N”, “Đã nhập N trên 4 số”; phím “Xóa lùi”, “Bằng”.
- Thu/chi không phân biệt chỉ bằng màu (hai màu cùng độ sáng): luôn có dấu − / + hoặc chữ Chi / Thu.
- Chạy lại `test/features/g6_accessibility_test.dart` sau khi đổi theme; thử thêm VoiceOver trên iPhone.

### 6. Chỗ thiết kế khác code hiện tại

- Theme dùng màu từ token thay cho `fromSeed`, nên màu nền, viền, container sẽ khác một chút so với bản đang chạy.
- Hai nút − / + có thêm chữ “Chi” / “Thu”.
- Khoảng tùy chọn dùng lịch trong bảng kéo thay cho `showDateRangePicker`.
- Ở Chuyển tiền, ô “Từ” và “Đến” xếp dọc để tên tài khoản dài không bị xuống dòng.
- Email ở màn Giới thiệu trong bản vẽ (`security@example.com`) chỉ để giữ chỗ.

### 7. Khi thiết kế đổi

Sửa trên design system “Ví Gọn” ở claude.ai trước, rồi xuất lại thư mục này. Không sửa `tokens.css` bằng tay; sửa `tokens.json` rồi sinh lại.
