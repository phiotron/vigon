# UI-SPEC — Ví Gọn (A002-vigon)

Mô tả giao diện và luồng xử lý của app **đúng như code hiện tại** (bản 1.0.0+1, ngày 2026-11-03), viết từ việc đọc `lib/src/app.dart`, `lib/src/features/**`, `lib/src/ui/**`, `lib/src/providers.dart` và các hàm dữ liệu mà giao diện gọi. Khác `docs/SPEC.md`: SPEC nói app PHẢI làm gì; file này nói giao diện ĐANG làm gì, kể cả chỗ chưa như SPEC (mục 9).

Nội dung chữ lấy từ `lib/l10n/app_vi.arb` (tiếng Việt, mặc định) và `app_en.arb` (tiếng Anh, cùng khóa). Chữ trong ngoặc kép là chữ tiếng Việt hiển thị.

**Bản 1.2 (chưa phát hành, nhánh `integration/spec-1.1`, 2026-11-04):** thêm Sao lưu tự động (F-24), Nhắc ghi sổ (F-25), Widget màn hình chính và liên kết sâu (F-26): mục 3.4, 3.13, 4.8, 4.9, 5 (luồng F-16 tới F-18), 9. Các phần này mô tả theo mã (`lib/src/features/settings/`, `reminder/`, `widget/`, `android/app/src/main/`) và test tự động; giao diện thật trên điện thoại (SAF vào Drive, thông báo, widget) CHƯA kiểm chứng trên máy, xem `docs/TESTING.md` (AC-58 tới AC-64). Lưu ý: số "F-n" ở mục 5 là số luồng của riêng file này, không phải số tính năng trong SPEC (khi cần, ghi rõ "SPEC F-24").

**Sau khi gộp nhánh (2026-11-05, D-019):** giao diện theo bộ thiết kế `design/current/screens/` (PLAN-001: token, chữ Be Vietnam Pro, icon Material Symbols Rounded, thành phần dùng chung); chi tiết bố cục và màu trong file này viết theo code trước khi gộp, CHƯA rà lại theo giao diện mới — khi lệch thì bản vẽ trong `design/current/screens/` và code là đúng. App chạy cả **iOS**: trên iOS các dòng "Che nội dung khi chuyển app", "Hiện số tiền trên widget", "Sao lưu tự động" bị ẩn và không có widget (mục 3.13) hay icon đơn sắc (`lib/src/platform_features.dart`); "Nhắc ghi sổ" có trên iOS (hộp xin quyền thông báo của iOS). Chỗ ghi "của Android" cho bảng chia sẻ và trình chọn file thì trên iOS là thành phần tương ứng của iOS.

**Cài đặt chia lại nhóm (2026-11-10):** màn Cài đặt chia **9 nhóm có tiêu đề** — Danh mục & tài khoản · Kế hoạch · Tiền tệ & kỳ · Nhập từ email · Bảo mật · Nhắc ghi sổ · Dữ liệu · Giao diện & ngôn ngữ · Giới thiệu; trước đây có nhóm không tiêu đề (A18) và "Xóa toàn bộ dữ liệu" đứng riêng, nay là hàng cuối nhóm Dữ liệu. Tính năng nhắc hằng ngày đổi tên **"Nhắc ghi chép" → "Nhắc ghi sổ"** trong mọi chữ hiển thị (kênh thông báo đã đăng ký giữ tên cũ để người dùng không mất cài đặt đã bật), dòng vào hàng đợi đổi thành **"Khoản chờ chọn danh mục"** (màn vẫn mang tiêu đề "Hàng đợi"). Mục 3.4 và 4.9 viết theo bố cục này; màn hình trên giấy tờ/bản vẽ cũ vẫn dùng tên cũ.

## Mục lục
1. Tổng quan kiến trúc giao diện
2. Bản đồ điều hướng
3. Các màn hình (3.1 – 3.13; 3.13 là Widget màn hình chính)
4. Hộp thoại và bảng chọn dùng chung
5. Luồng xử lý (F-1 – F-18)
6. Quy tắc hiển thị dùng chung
7. Trạng thái trống, lỗi và thông báo
8. Khả năng tiếp cận
9. Hạn chế và điểm lệch đã biết

---

## 1. Tổng quan kiến trúc giao diện

| Mục | Nội dung |
|-----|----------|
| Nền tảng | Android, điện thoại, chỉ màn dọc (khóa trong manifest và `SystemChrome`) |
| Framework | Flutter 3.47.8, Material 3, `MaterialApp.router` |
| Điều hướng | `go_router`: một cây route, mọi màn đẩy lên bằng `context.push`, quay lại bằng nút Back hệ thống hoặc mũi tên trên thanh tiêu đề |
| Trạng thái | Riverpod 3 (provider viết tay): dữ liệu lấy từ cơ sở dữ liệu SQLite (drift) qua `StreamProvider`, nên mọi màn tự cập nhật khi dữ liệu đổi |
| Chủ đề | Màu gốc `0xFF2E7D6B`; 3 chế độ Sáng, Tối, Theo hệ thống (lưu ở bảng `settings`) |
| Ngôn ngữ | Tiếng Việt, tiếng Anh, "Theo máy"; mọi chữ nằm trong `.arb`, trừ hai nhãn "Tiếng Việt", "English" |
| Lớp phủ toàn app | Từ ngoài vào trong: `DeepLinkBinder` (nhận route từ nút widget), `ReminderTapBinder` (nhận lần chạm thông báo nhắc), `AppLifecycleWatcher` (theo dõi ra nền/quay lại; ra nền thì thử sao lưu tự động), bọc `Stack` gồm: app (bị `Offstage` khi khóa) và `LockScreen` (khi bật PIN và đang khóa) |
| Theo dõi nền | `VigonApp` theo dõi `widgetSyncProvider` (đẩy dòng trạng thái sang widget) và `reminderSyncProvider` (giữ lịch nhắc khớp cài đặt) |
| Thông báo nổi | `rootMessengerKey` (một `ScaffoldMessenger` gốc) để thanh "Đã xóa · Hoàn tác" còn hiện sau khi đóng màn sửa |
| Dữ liệu | Không có mạng. Mọi thay đổi ghi ngay vào SQLite khi bấm Lưu/xác nhận |
| Icon app | Logo "hai thẻ xếp chồng" (D-009): icon thích ứng Android (nền xanh đậm `#0E5244`), không còn icon Flutter mặc định |

### Bảng route (`lib/src/app.dart`)

| Route | Màn hình | Tham số |
|-------|----------|---------|
| `/` | Màn chính (`HomeScreen`) | không |
| `/settings` | Cài đặt | không |
| `/recurring` | Khoản định kỳ | không |
| `/categories` | Danh mục | không |
| `/accounts` | Tài khoản | không |
| `/transfer` | Chuyển tiền (mới) | không |
| `/transfer/:id` | Sửa/xóa một lần chuyển tiền | `id` của khoản |
| `/entries` | Các khoản (danh sách trong kỳ) | không |
| `/entry/new` | Nhập khoản mới | `type=expense\|income` (mặc định chi), `category=<id>` (chọn sẵn danh mục). Cũng là đích của liên kết sâu từ nút Chi/Thu của widget (`type=expense` hoặc `income`) và của thông báo nhắc (`type=expense`), xem 3.13 |
| `/entry/:id` | Sửa/xóa một khoản thu hoặc chi | `id` của khoản |

Tất cả là route con của `/`, nên Back từ bất kỳ màn nào cũng về màn trước, và Back ở `/` thoát app.

**Liên kết sâu (bản 1.2):** hai đường từ ngoài app đi thẳng vào `/entry/new`, đều dùng `router.go` nên ngăn xếp là [Màn chính, Nhập khoản] và Back từ màn nhập về Màn chính (không thoát app):
- Nút **Chi / Thu** của widget: intent Android mang route `/entry/new?type=expense` hoặc `/entry/new?type=income`.
- **Chạm thông báo nhắc:** `payload` `/entry/new?type=expense`.
Chỉ hai route nhập khoản mới này được nhận (`allowedDeepLinkRoute`, và thông báo chỉ nhận đúng payload của app); route lạ, đường dẫn có `scheme` hay `host`, hoặc `type` khác `expense`/`income` bị bỏ và app ở yên màn đang xem. Màn khóa PIN là lớp phủ nên không bị bỏ qua: xem 3.13 và luồng F-18. Liên kết sâu mặc định của Flutter bị TẮT trong manifest (`flutter_deeplinking_enabled=false`), nên app khác không đẩy được đường dẫn tùy ý vào `go_router`; hai đường trên đi qua kênh riêng `vigon/deeplink`. Route `/entry/:id` và `/transfer/:id` có `id` không phải số nguyên thì chuyển về Màn chính thay vì ném lỗi.

---

## 2. Bản đồ điều hướng

```
                              ┌─────────────── KHÓA PIN (nếu bật) ───────────────┐
Mở app ──► [Màn khóa] ──đúng mã──► Màn chính                                      │
              │ "Quên mã" ──► 3 hộp thoại xóa dữ liệu ──► Màn chính (trống)       │
              └──────────────────────────────────────────────────────────────────┘

Màn chính "/"
 ├─ [−] / [+]  ───────────────► Nhập khoản mới  /entry/new?type=expense|income
 ├─ icon danh mục quanh biểu đồ ► Nhập khoản chi (danh mục chọn sẵn)
 ├─ tên kỳ  ──────────────────► Bảng chọn kỳ ──("Khoảng tùy chọn")──► Hộp chọn khoảng ngày
 ├─ ‹ ›  /  vuốt ngang ───────► đổi kỳ (không đổi màn)
 ├─ thanh ngân sách ──────────► Hộp thoại ngân sách
 ├─ thanh Số dư  /  icon Các khoản ► Các khoản  /entries
 │     └─ chạm một khoản ─────► Sửa khoản /entry/:id  (hoặc /transfer/:id nếu là chuyển tiền)
 ├─ icon ví (khi ≥ 2 tài khoản) ► Menu lọc tài khoản (không đổi màn)
 └─ icon bánh răng ───────────► Cài đặt  /settings
       ├─ Danh mục ───────────► Danh mục ──► Bảng thêm/sửa danh mục ──► Hộp thoại chuyển khoản khi xóa
       ├─ Tài khoản ──────────► Tài khoản ──► Bảng thêm/sửa tài khoản
       │     └─ icon ⇄ (≥ 2 tài khoản) ► Chuyển tiền /transfer
       ├─ Ngân sách tháng ────► Hộp thoại ngân sách
       ├─ Khoản định kỳ ──────► Khoản định kỳ ──► Hộp thoại sửa số tiền, ghi chú
       ├─ Tiền tệ ────────────► Hộp thoại chọn tiền tệ
       ├─ Ngày đầu tuần ──────► (đổi ngay, không hộp thoại)
       ├─ Tháng bắt đầu từ ngày ► Menu thả chọn 1–28
       ├─ Khóa bằng mã PIN ───► Màn toàn khung đặt mã / nhập mã để tắt
       ├─ Hiện số tiền trên widget ► (công tắc, đổi ngay, không hộp thoại; chỉ Android)
       ├─ Nhắc ghi sổ (công tắc) ► Hộp thoại giải thích ──"Tiếp tục"──► Hộp thoại quyền thông báo của Android / iOS
       │     └─ Giờ nhắc ─────► Bộ chọn giờ của hệ thống
       ├─ Xuất bản sao lưu ───► Bảng chia sẻ của Android
       ├─ Khôi phục ──────────► Trình chọn file Android ──► Hộp thoại xác nhận
       ├─ Xuất CSV ───────────► Bảng chia sẻ của Android
       ├─ Sao lưu tự động (công tắc, chỉ Android) ► Bộ chọn thư mục của Android ──► Hộp thoại mật khẩu ──► "Sao lưu ngay" lần đầu
       │     ├─ Sao lưu ngay ─► vòng quay ──► thông báo kết quả
       │     └─ Chọn lại thư mục ► Bộ chọn thư mục ──► "Sao lưu ngay"
       ├─ Xóa toàn bộ dữ liệu ► 2 hộp thoại xác nhận
       └─ Giới thiệu (thẻ cuối màn, không có màn riêng — D-039)
             ├─ Chính sách quyền riêng tư / Điều khoản sử dụng ► trình duyệt đúng ngôn ngữ app (không mở được: bản nhúng trong app)
             ├─ Giấy phép mã nguồn mở ► trang giấy phép của Flutter
             ├─ Đánh giá Ví Gọn (Android) ► Play Store
             ├─ Gửi góp ý / Báo lỗi bảo mật ► app email có sẵn người nhận và tiêu đề

Từ ngoài app (bản 1.2), đều qua màn khóa PIN nếu đang bật:
 Widget "Chi" ───────────────► Màn chính ► Nhập khoản chi  /entry/new?type=expense
 Widget "Thu" ───────────────► Màn chính ► Nhập khoản thu  /entry/new?type=income
 Thông báo nhắc (chạm) ──────► Màn chính ► Nhập khoản chi  /entry/new?type=expense
 Ra nền (tối đa 1 lần/ngày) ─► tự sao lưu vào thư mục đã chọn (không đổi màn)
```

Sơ đồ đường vào từ widget và thông báo, và chỗ màn khóa PIN chen vào:

```
 Chạm nút widget / thông báo
          │  Android mở MainActivity (kèm route, hoặc payload của thông báo)
          ▼
 App tắt hẳn?  ── có ──► khởi động, màn khóa (nếu bật PIN) hoặc màn chính; Dart lấy route chờ sau khung hình đầu
          │ không (đang chạy nền hoặc trước)
          ▼
 Dart nhận "routeAvailable" / lần chạm thông báo
          │ route hợp lệ? ── không ──► bỏ, ở yên màn hiện tại
          ▼ có
 router.go("/entry/new?type=...")   (đi dưới lớp phủ khóa)
          ▼
 PIN bật và đang khóa? ── có ──► màn khóa phủ trên; nhập đúng mã ──► thấy ngay màn Nhập khoản
          │ không
          ▼
 Màn Nhập khoản (Back ──► Màn chính)
```

---

## 3. Các màn hình

### 3.1 Màn chính — `/` (`features/home/home_screen.dart`)

**Mục đích:** nhìn nhanh tiền đi đâu trong kỳ đang chọn và ghi khoản mới trong vài chạm (F-01, F-02).

**Bố cục (trên xuống dưới), toàn bộ nằm trong `SafeArea`:**

| # | Thành phần | Hành vi |
|---|-----------|---------|
| 1 | **Thanh tiêu đề** "Ví Gọn" + 2 đến 3 nút bên phải | Xem dưới |
| 2 | **Đầu kỳ** (`_PeriodHeader`): nút ‹ "Kỳ trước", tên kỳ ở giữa, nút › "Kỳ sau" | ‹ › đổi sang kỳ cùng loại liền trước/sau. Chạm tên kỳ mở bảng chọn kỳ (mục 4.1). Tên kỳ cao tối thiểu 48 dp |
| 3 | **Thanh ngân sách** (`BudgetBar`) | Chỉ hiện khi đã đặt ngân sách. Tính theo **tháng của kỳ đang xem** (D-028): xem tháng → tháng đó; xem ngày/tuần → tháng chứa ngày cuối của kỳ; xem năm, tất cả, khoảng tùy chọn → ẩn. Dòng chữ "Ngân sách tháng: Đã chi X / Y" và thanh tiến độ. Chi quá thì chữ đổi màu lỗi, đậm, ghi "Ngân sách tháng: Vượt Z" và thanh đầy. Chạm mở hộp thoại ngân sách (mục 4.5) |
| 4 | **Vùng biểu đồ** (chiếm phần còn lại) | Vòng tròn ở giữa và icon danh mục chi xếp quanh (xem dưới). Vuốt ngang trong vùng này đổi kỳ |
| 5 | **Thanh Số dư** | Nền xám nhạt, chữ "Số dư: X", cao tối thiểu 56 dp. Chạm mở "Các khoản" |
| 6 | **Hai nút lớn** | Đỏ "−" bên trái (thêm khoản chi) và xanh "+" bên phải (thêm khoản thu), cao tối thiểu 64 dp, ở vùng ngón cái |

**Nút trên thanh tiêu đề:**
- **Icon ví "Tài khoản"** — chỉ hiện khi có từ 2 tài khoản; khi đang lọc, trình đọc màn hình nghe "Tài khoản: <tên>". Mở menu: "Tất cả tài khoản" và từng tài khoản; chọn một thì toàn bộ số liệu màn chính và màn Các khoản chỉ tính khoản của tài khoản đó (khoản chuyển tiền tính nếu tài khoản là nguồn hoặc đích). Lựa chọn nằm trong bộ nhớ của phiên chạy, KHÔNG lưu khi tắt app.
- **Icon danh sách "Các khoản"** → `/entries`.
- **Icon bánh răng "Cài đặt"** → `/settings`.

**Vòng tròn và icon danh mục:**
- Vòng tròn rỗng (kiểu bánh rán) vẽ bằng `fl_chart`: mỗi danh mục chi trong kỳ là một cung màu của danh mục, sắp từ lớn đến nhỏ, bắt đầu từ vị trí 12 giờ.
- Chính giữa hiện hai dòng: tổng **thu** (màu xanh) rồi tổng **chi** (màu đỏ) của kỳ.
- Kỳ không có khoản nào: thay vòng tròn bằng chữ "Bấm − để ghi khoản chi đầu tiên" (căn giữa).
- Nếu có thu mà không có chi: vòng tròn đầy một màu xanh thu.
- **Icon danh mục:** mỗi danh mục chi (theo thứ tự người dùng sắp) là một hình tròn 48 dp xếp đều quanh vòng. Số icon hiện tối đa bằng số icon xếp vừa chu vi (`floor(2π·bán kính / 56)`, tối thiểu 1). Nếu còn danh mục thừa, icon cuối là ô **"Danh mục khác"** (dấu ⋯, nền trung tính) mở bảng lưới tất cả danh mục chi; chọn một danh mục thì mở màn Nhập khoản chi với danh mục đó (F-17, AC-51). Chạm icon danh mục mở `/entry/new?type=expense&category=<id>`, danh mục đã chọn sẵn. Giữ lâu hiện tooltip tên danh mục.
- Khoản thu chỉ ghi được qua nút "+", không có icon thu quanh vòng.

**Vuốt ngang:** vận tốc vuốt tối thiểu 200; vuốt sang trái → kỳ sau, sang phải → kỳ trước.

**Dữ liệu và trạng thái:** kỳ mặc định là tháng chứa hôm nay. Số thu, chi, số dư trên màn chính **không tính khoản chuyển tiền** (chuyển tiền không phải thu hay chi). Số dư ở đây là thu − chi của kỳ, KHÔNG phải số dư tài khoản (số dư tài khoản ở màn Tài khoản, mục 3.8).

---

### 3.2 Nhập khoản — `/entry/new` và `/entry/:id` (`features/entry/entry_editor_screen.dart`, `keypad.dart`)

**Mục đích:** ghi khoản thu/chi mới hoặc sửa/xóa khoản có sẵn (F-01, F-04). Cùng một màn cho cả hai trường hợp.

**Tiêu đề:** "Khoản chi mới", "Khoản thu mới" hoặc "Sửa khoản". Khi sửa có thêm icon thùng rác "Xóa" ở góc phải.

**Bố cục:**
1. **Vùng hiển thị số tiền** (là vùng đọc tự động cho trình đọc màn hình): dòng nhỏ phía trên là **biểu thức đang gõ** (ví dụ `120+35`, cắt bằng dấu … nếu dài), dòng lớn là **số tiền đã tính và định dạng** (ví dụ `155.000 ₫`, màu đỏ khi chi, xanh khi thu, tự co chữ cho vừa). Nếu có lỗi, dòng lỗi màu đỏ hiện bên dưới.
2. **Hàng chip** (xuống dòng khi hết chỗ):
   - **Chip danh mục** (hiện khi đã chọn danh mục): icon + tên; chạm mở lưới chọn danh mục.
   - **Chip ngày**: "Hôm nay" hoặc ngày ngắn (ví dụ "3 thg 11, 2026"); chạm mở hộp chọn ngày (từ năm 2000 đến năm hiện tại + 10; nếu khoản có ngày cũ hơn 2000 thì cho phép đúng ngày đó).
   - **Chip lặp lại** — CHỈ khi **ghi khoản mới**: "Không lặp" / "Hằng ngày" / "Hằng tuần" / "Hằng tháng" / "Hằng năm"; chạm mở bảng chọn.
   - Khi **sửa** khoản thuộc chuỗi định kỳ còn chạy: chip loại lặp kèm nút ⏹ "Dừng lặp lại" (xem F-6).
   - **Chip tài khoản** — chỉ hiện khi có từ 2 tài khoản: tên tài khoản đang chọn (mặc định tài khoản đầu tiên); chạm mở bảng chọn.
3. **Ô ghi chú:** gợi ý "Ghi chú", tối đa 200 ký tự (có đếm), phím Enter là "Xong".
4. **Phần trên cuộn được** nếu không đủ chỗ (ví dụ cỡ chữ lớn); **bàn phím số luôn ghim ở đáy**.

**Bàn phím số (`Keypad`)** — 5 hàng, mỗi nút cao tối thiểu 56 dp:

```
 7   8   9   ÷
 4   5   6   ×
 1   2   3   −
 000 0   ⌫   +        (tiền không có phần lẻ như VND: "000"; tiền có phần lẻ như USD: ".")
 =   [      Lưu      ]
```

- Nút phép tính (`÷ × − +`, `=`) tô màu phụ để phân biệt với chữ số.
- Nút lớn cuối hàng ghi **"Lưu"**; nếu chưa chọn danh mục thì ghi **"Chọn danh mục"**. Màu đỏ (chi) hoặc xanh (thu); chữ đen trên giao diện tối, trắng trên giao diện sáng.
- Quy tắc gõ: tối đa 30 ký tự; kết quả tối đa 1.000.000.000.000 đơn vị nhỏ nhất (VND: 1.000 tỷ đồng), vượt thì báo "Phép tính không hợp lệ"; bấm hai phép tính liền nhau thì phép sau thay phép trước; không cho bắt đầu bằng phép tính; `⌫` xóa ký tự cuối; `=` thay cả biểu thức bằng kết quả (nếu hợp lệ và lớn hơn 0).
- Tính toán: nhân chia trước, cộng trừ sau; kết quả làm tròn tới đơn vị nhỏ nhất của tiền tệ.

**Lưới chọn danh mục** (bảng kéo từ dưới lên): tiêu đề "Chọn danh mục", lưới icon tròn kèm tên (tối đa 2 dòng), mỗi ô rộng tối đa 96 dp; chạm một danh mục là chọn và đóng. Loại danh mục theo loại khoản (chi hoặc thu).

**Lưu (nút "Lưu" / "Chọn danh mục"):**
1. Kiểm số tiền (xem mục 7 về lỗi). Không hợp lệ thì hiện lỗi ngay trên vùng số tiền và dừng.
2. Chưa chọn danh mục thì tự mở lưới chọn; đóng lưới mà không chọn thì dừng (không lưu).
3. Ghi vào cơ sở dữ liệu rồi tự đóng màn (quay về màn trước). Xem F-1, F-2, F-6.

**Xóa (khi sửa):** xóa ngay không hỏi lại, đóng màn và hiện thanh "Đã xóa" có nút **Hoàn tác** trong 5 giây (xem F-3).

---

### 3.3 Các khoản — `/entries` (`features/entries/entries_screen.dart`)

**Mục đích:** xem chi tiết các khoản trong kỳ, gom theo danh mục (F-02, AC-08).

**Tiêu đề:** tên kỳ đang xem (cùng định dạng như màn chính).

**Danh sách** (dựng lười, chỉ vẽ phần đang nhìn thấy; cuộn dọc):
1. Dòng **"Số dư"** cỡ lớn: tổng thu − chi của kỳ; kế bên (hoặc ngay dưới khi chữ lớn) là số tiền.
2. Đường kẻ ngang.
3. Phần **"Chi"** (hiện khi có chi): dòng tổng chi (màu đỏ), rồi từng danh mục chi theo thứ tự tổng giảm dần. Mỗi danh mục là một dòng có thể mở rộng:
   - Trái: icon danh mục 40 dp. Giữa: tên và phần trăm (một chữ số thập phân, ví dụ "53,7%"). Phải: tổng tiền và mũi tên ⌄ / ⌃.
   - Chạm dòng để mở hoặc thu gọn. Khi mở, hiện các khoản của danh mục đó, mới nhất trước.
   - Chữ lớn (≥ 130%): tổng tiền chuyển xuống cùng dòng với phần trăm.
4. Phần **"Thu"** (hiện khi có thu): giống phần chi, màu xanh.
5. Phần **"Chuyển tiền"** (hiện khi có): liệt kê phẳng từng lần chuyển, nhãn "Tài khoản A → Tài khoản B".
6. Đệm 24 dp ở đáy.

**Một dòng khoản:** tiêu đề là ghi chú (nếu không có ghi chú thì tên danh mục), phụ đề là ngày ngắn, bên phải là số tiền. Chữ lớn thì số tiền xuống dòng thứ hai của phụ đề.
- **Chạm** → mở `/entry/:id` (khoản thu/chi) hoặc `/transfer/:id` (chuyển tiền) để sửa hoặc xóa.
- **Vuốt sang trái** → xóa ngay, hiện nền đỏ nhạt với icon thùng rác; sau khi xóa hiện "Đã xóa · Hoàn tác" 5 giây (F-3).

**Trạng thái trống:** kỳ không có khoản nào → giữa màn hình ghi "Kỳ này chưa có khoản nào" (không có số dư, không có danh sách).

**Trạng thái mở/thu gọn** của từng danh mục chỉ giữ trong phiên màn hình này; thoát ra và vào lại thì thu gọn hết. Danh sách tuân theo kỳ và bộ lọc tài khoản đang đặt ở màn chính.

**Tìm kiếm (F-15, AC-48, AC-49):** icon kính lúp "Tìm" trên thanh tiêu đề mở ô nhập (Back đóng ô tìm trước, rồi mới thoát màn). Gõ chữ thì lọc khoản có **ghi chú, tên danh mục hoặc số tiền** chứa chuỗi đó, không phân biệt hoa thường và dấu tiếng Việt; chuỗi chỉ gồm chữ số và dấu ngăn thì khớp theo chữ số của số tiền ("155" khớp 155.000 và 1.550.000). Mặc định tìm trong kỳ đang xem; chip **"Tất cả thời gian"** tìm trên toàn bộ dữ liệu. Kết quả là danh sách phẳng, mới nhất trước, kèm dòng tổng "N khoản · tổng X"; chạm sửa, vuốt xóa và Hoàn tác như thường. Khoản chuyển tiền cũng được tìm (theo ghi chú và số tiền). Không có kết quả: "Không có khoản nào khớp".

**Ngân sách theo danh mục (F-20, AC-54):** dòng danh mục chi đã đặt hạn mức hiện thêm thanh tiến độ nhỏ "Đã chi X / Y" của THÁNG HIỆN TẠI (theo ngày bắt đầu tháng, mọi tài khoản, không phụ thuộc kỳ đang xem). Chi quá hạn mức thì đổi màu lỗi, đậm, thêm chữ "Vượt Z" (không chỉ dựa vào màu).

---

### 3.4 Cài đặt — `/settings` (`features/settings/settings_screen.dart`)

Danh sách cuộn dọc, chia thành **9 nhóm có tiêu đề** (`SettingsGroupTitle`, chữ `title-sm` màu `primary`); mỗi nhóm là một thẻ `SettingsCard` (nhóm Dữ liệu có thể hai thẻ khi bật sao lưu tự động). Thứ tự từ trên xuống (chốt 2026-11-10):

| Mục | Kiểu | Hành vi |
|-----|------|---------|
| (nhóm) **Danh mục & tài khoản** | Thẻ hai dòng | Thứ hay sửa nhất, đứng đầu màn |
| **Danh mục** ❯ | Dòng mở màn | → `/categories` |
| **Tài khoản** ❯ | Dòng mở màn | → `/accounts` |
| (nhóm) **Kế hoạch** | Thẻ bốn dòng | |
| **Ngân sách tháng** | Dòng có phụ đề ("Chưa đặt" hoặc số tiền) | Mở hộp thoại ngân sách (mục 4.5) |
| **Khoản định kỳ** ❯ | Dòng mở màn | → `/recurring` |
| **Tiết kiệm** ❯ | Dòng mở màn | → `/savings` |
| **Khoản nợ** ❯ | Dòng mở màn | → `/debts` |
| (nhóm) **Tiền tệ & kỳ** | Thẻ bốn dòng | |
| **Tiền tệ chính** | Dòng có phụ đề mã tiền ("VND · ₫") | Mở hộp thoại chọn tiền tệ có ô tìm (mục 4.6) |
| **Tỷ giá** | Dòng có phụ đề tóm tắt trạng thái bảng tỷ giá ("Tự động · hôm qua", "Có sẵn", "Bạn đặt tay") | → `/rates` |
| **Ngày đầu tuần** | Hai nút chọn một `SettingsSegmentRow`: "Thứ Hai" / "Chủ Nhật" | Chạm nút nào là lưu nút đó, không có hộp thoại (§10.1 #4) |
| **Tháng bắt đầu từ ngày** | Menu thả ở bên phải | Chọn số từ 1 đến 28 |
| (nhóm) **Nhập từ email** | Thẻ hai dòng | Chỉ có khi bản build bật nhập từ email |
| **Nhập từ email ngân hàng** ❯ | Dòng có phụ đề số hộp thư ("Chưa thêm hộp thư" hoặc "N hộp thư") | → `/email-import` (F-28, AC-78) |
| **Khoản chờ chọn danh mục** ❯ | Dòng có phụ đề "Không có khoản nào đang chờ" hoặc "N khoản chờ" | → `/import-queue` (màn vẫn mang tiêu đề "Hàng đợi") |
| (nhóm) **Bảo mật** | Thẻ công tắc | |
| **Khóa bằng mã PIN** | Công tắc, kèm lời cảnh báo "Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app." | Bật → đặt mã (F-10). Tắt → nhập đúng mã hiện tại (F-11) |
| **Che nội dung khi chuyển app** | Công tắc (mặc định tắt), kèm chú thích | Bật: Android chặn chụp màn hình và hiện màn trống trong danh sách app gần đây (`FLAG_SECURE`). Lưu trong cài đặt, áp dụng ngay (F-22, AC-56). Chỉ Android: trên iOS dòng này bị ẩn (D-019) |
| **Hiện số tiền trên widget** | Công tắc (mặc định tắt), nằm cuối nhóm Bảo mật (`WidgetAmountsSwitch`), kèm chú thích "Ai cầm máy cũng nhìn thấy số này trên màn hình chờ. Khi đang bật khóa PIN, widget luôn ẩn số." | Bật/tắt là lưu ngay, không hộp thoại; widget cập nhật theo (AC-64, mục 3.13). Khi khóa PIN đang bật, công tắc vẫn gạt được nhưng widget chỉ hiện "Đã khóa bằng PIN". Chỉ Android: trên iOS dòng này bị ẩn (D-019) |
| (nhóm) **Nhắc ghi sổ** | Tiêu đề nhóm riêng (`ReminderSection`), nằm giữa nhóm Bảo mật và nhóm Dữ liệu | Xem hai dòng dưới và mục 4.9, luồng F-17. Tên cũ "Nhắc ghi sổ" (đổi 2026-11-10); kênh thông báo đã đăng ký vẫn giữ tên cũ để không mất cài đặt của người dùng |
| **Nhắc ghi sổ hằng ngày** | Công tắc (mặc định tắt), chú thích "Mỗi ngày một thông báo vào giờ bạn chọn, không chứa số liệu" | Bật: hộp thoại giải thích rồi mới xin quyền thông báo của hệ điều hành (Android 13 trở lên; iOS). Tắt: hủy lịch ngay, không hộp thoại (AC-61, AC-62) |
| **Giờ nhắc** | Dòng có phụ đề giờ đã chọn (mặc định 20:00, định dạng theo máy) | Chạm mở bộ chọn giờ của hệ thống (tiêu đề "Giờ nhắc"); chọn giờ khác thì đặt lại lịch ở giờ mới. Hoạt động cả khi công tắc đang tắt (chỉ lưu giờ, chưa đặt lịch) |
| (nhóm) **Dữ liệu** | Dòng nhắc "Dữ liệu chỉ nằm trên máy này. Nên xuất bản sao lưu thường xuyên." | Nhóm kết thúc bằng dòng nguy hiểm "Xóa toàn bộ dữ liệu" |
| **Xuất bản sao lưu** | Dòng, phụ đề "Có thể đặt mật khẩu cho file. Không đặt thì file không được mã hóa." | F-12 (hộp thoại hỏi có đặt mật khẩu không) |
| **Khôi phục từ bản sao lưu** | Dòng | F-13 |
| **Xuất CSV** | Dòng | F-12 |
| **Sao lưu tự động** | Công tắc (mặc định tắt) với biểu tượng đám mây, chú thích "Ví Gọn chỉ ghi file vào thư mục bạn chọn. Việc tải lên Google Drive hay Dropbox do app đó thực hiện." (`AutoBackupSection`) | Bật → bộ chọn thư mục của hệ thống → hộp thoại đặt mật khẩu (mục 4.8) → "Sao lưu ngay" lần đầu (luồng F-16). Tắt → xóa mật khẩu và quyền thư mục, giữ file đã ghi, hiện "Đã tắt sao lưu tự động. File đã ghi vẫn còn trong thư mục." (AC-58, AC-60). Chỉ Android: trên iOS cả mục này bị ẩn (D-019) |
| ↳ **Thư mục: <tên>** | Chỉ hiện khi đang bật. Dòng tiêu đề lùi vào, tên thư mục lấy từ bộ chọn ("Thư mục đã chọn" nếu hệ thống không cho tên); phụ đề là trạng thái lần thử gần nhất | Phụ đề: "Chưa sao lưu lần nào" / "Lần cuối: 3 thg 11, 18:30" (ngày giờ theo ngôn ngữ app) / chữ màu lỗi khi lần gần nhất thất bại, kèm giờ lần thử: "Lần thử 3 thg 11, 18:30: Không ghi được vào thư mục. Chọn lại thư mục" (quyền bị thu hồi hoặc thư mục mất) hoặc "Lần thử …: Sao lưu không thành công. Thử lại bằng Sao lưu ngay" (lỗi khác) (AC-60). Trạng thái được đọc lại mỗi lần mở Cài đặt và mỗi lần app quay lại từ nền (lần chạy nền có thể vừa lỗi) |
| ↳ Nút **Sao lưu ngay**, **Chọn lại thư mục** | Hai nút (tonal và viền) xếp ngang, tự xuống dòng khi hẹp hoặc chữ lớn; chỉ hiện khi đang bật | "Sao lưu ngay": vòng quay trong lúc chạy, rồi thông báo "Đã sao lưu" hoặc dòng lỗi như trên; chạy cả khi dữ liệu không đổi; nếu đang có lần sao lưu khác chạy thì báo "Đang sao lưu, thử lại sau giây lát" và không ghi đè trạng thái. "Chọn lại thư mục": chọn thư mục mới, giữ mật khẩu, bỏ quyền thư mục cũ, rồi "Sao lưu ngay" để kiểm |
| ↳ **Xóa toàn bộ dữ liệu** | Dòng màu lỗi, luôn là **hàng cuối của nhóm Dữ liệu** (trên Android nối vào cuối thẻ Sao lưu tự động) | F-14 |
| (nhóm) **Giao diện & ngôn ngữ** | Thẻ hai dòng; hai dòng của nhóm cùng mở **một bảng kéo** (D-038) | Đặt gần cuối màn, trước Giới thiệu |
| **Giao diện** | Dòng có giá trị bên phải ("Theo hệ thống"/"Sáng"/"Tối") | Mở bảng kéo chọn giao diện; chọn là đổi ngay, lưu lại |
| **Ngôn ngữ** | Dòng có giá trị bên phải ("Tiếng Việt"/"English") | Mở bảng kéo chọn ngôn ngữ; đổi ngay mọi chữ, lưu lại |
| (nhóm) **Giới thiệu** | Thẻ bảy dòng như A001 (D-039); không còn màn riêng | |
| **Phiên bản** | Giá trị `1.0.0 (1)` căn phải (`valueInline`), không mũi tên | Chỉ hiển thị |
| **Chính sách quyền riêng tư** | Dòng có icon mở-trang | Trình duyệt, đúng ngôn ngữ app; không mở được thì màn đọc bản nhúng |
| **Điều khoản sử dụng** | Dòng có icon mở-trang | Như trên |
| **Giấy phép mã nguồn mở** | Dòng | Trang giấy phép chuẩn của Flutter |
| **Đánh giá Ví Gọn** | Dòng có icon mở-trang, **chỉ Android**; iOS ẩn khi chưa có App Store id | `market://` rồi Play HTTPS |
| **Gửi góp ý** | Dòng có icon mở-trang | `mailto:` tiêu đề có phiên bản |
| **Báo lỗi bảo mật** | Dòng có phụ đề email liên hệ, icon mở-trang | `mailto:` tiêu đề "Báo lỗi bảo mật Ví Gọn" |
| ↳ chú thích cuối thẻ | "Dữ liệu chỉ lưu trên máy này…" | |

Đổi **Ngày đầu tuần** hoặc **Tháng bắt đầu từ ngày** khi đang xem kỳ Tuần hoặc Tháng ở màn chính thì kỳ đó được tính lại theo cài đặt mới nhưng vẫn là cùng loại kỳ (không nhảy về "Tháng").

---

### 3.5 Danh mục — `/categories` (`features/categories/categories_screen.dart`)

- **Tiêu đề** "Danh mục" và hai **tab**: "Chi" và "Thu". Vuốt ngang hoặc chạm tab để đổi.
- Mỗi tab là danh sách danh mục (icon 40 dp, tên) có **tay nắm ☰** ở bên phải để **kéo thả sắp xếp** (tooltip "Kéo để sắp xếp"). Thứ tự này quyết định thứ tự icon quanh biểu đồ ở màn chính và thứ tự trong lưới chọn.
- Chạm một dòng → bảng sửa danh mục (mục 4.3).
- Nút tròn **"+" "Thêm danh mục"** ở góc phải dưới: mở bảng thêm cho tab đang xem. Đệm 88 dp ở đáy để nút không che dòng cuối.

---

### 3.6 Tài khoản — `/accounts` (`features/accounts/accounts_screen.dart`)

- **Tiêu đề** "Tài khoản". Khi có từ 2 tài khoản: icon ⇄ "Chuyển tiền" ở góc phải → `/transfer`.
- Mỗi tài khoản một dòng: icon ví, tên, và **số dư hiện tại** bên phải (= số dư ban đầu + thu − chi ± chuyển tiền; chữ lớn thì xuống dưới tên). Chạm → bảng sửa tài khoản (mục 4.4).
- Nút tròn **"+" "Thêm tài khoản"** → bảng thêm tài khoản.
- Tài khoản mặc định "Tiền mặt" có sẵn khi cài.
- **Ẩn, hiện, xóa (F-14, AC-44 đến AC-47):** bảng sửa tài khoản có nút **"Ẩn tài khoản"** và **"Xóa tài khoản"**. Xóa chỉ hiện khi tài khoản chưa có khoản nào (kể cả chuyển tiền đến) và không chuỗi định kỳ nào trỏ tới; nếu có thì hiện dòng "Tài khoản đã có khoản, chỉ ẩn được"; xóa qua hộp thoại xác nhận. Tài khoản hiện cuối cùng không có nút nào, chỉ có dòng "Phải còn ít nhất một tài khoản". Tài khoản đã ẩn không hiện khi chọn tài khoản ghi khoản, trong menu lọc ở màn chính, ô Từ/Đến Chuyển tiền; khoản cũ của nó vẫn nằm trong danh sách khoản và vẫn tính vào tổng thu chi, số dư của nó vẫn tính. Cuối màn có mục thu gọn **"Tài khoản đã ẩn"** liệt kê tài khoản ẩn kèm số dư; chạm hoặc bấm **"Hiện lại"** để dùng lại. Đang lọc theo một tài khoản mà ẩn nó thì bộ lọc tự bỏ.

---

### 3.7 Chuyển tiền — `/transfer` và `/transfer/:id` (`features/accounts/transfer_screen.dart`)

Chỉ dùng được khi có ít nhất 2 tài khoản (nếu không, màn để trống).

**Bố cục:** hai ô chọn thả xuống **"Từ"** → **"Đến"** (mặc định tài khoản thứ nhất và thứ hai), số tiền cỡ lớn, chip ngày, ô ghi chú (tối đa 200 ký tự), bàn phím số y hệt màn nhập khoản (nút lớn ghi "Lưu", màu chính của giao diện). Phần trên cuộn được, bàn phím ghim đáy.

**Lưu:** chặn nếu hai tài khoản giống nhau ("Chọn hai tài khoản khác nhau") hoặc số tiền ≤ 0 ("Số tiền phải lớn hơn 0"). Hợp lệ thì ghi một khoản loại chuyển tiền rồi đóng màn.
**Sửa/xóa:** từ danh sách Các khoản, chạm một lần chuyển → màn này nạp sẵn dữ liệu; có icon thùng rác; xóa có Hoàn tác (như F-3).

---

### 3.8 Khoản định kỳ — `/recurring` (`features/recurring/recurring_screen.dart`)

- **Tiêu đề** "Khoản định kỳ". Danh sách chuỗi (còn chạy xếp trước, rồi theo ngày bắt đầu).
- Mỗi dòng: icon danh mục, tiêu đề "Danh mục · số tiền", phụ đề "Hằng tháng · <ngày tới hạn kế tiếp>" (nếu đã dừng thì "Hằng tháng · Đã dừng"), **công tắc** bên phải: tắt = dừng, bật = chạy lại.
- Chạm dòng → hộp thoại sửa (F-6, F-16, AC-50): **số tiền, ghi chú, tần suất** (ngày/tuần/tháng/năm), **danh mục** (cùng loại thu/chi) và **tài khoản** (chỉ tài khoản hiện; ô này chỉ hiện khi có từ 2 tài khoản). Khoản đã sinh không đổi. Đổi tần suất thì chuỗi bắt đầu lại từ ngày tới hạn kế tiếp theo lịch cũ (không sinh bù, không trùng).
- Trống: "Chưa có khoản định kỳ. Bật Lặp lại khi ghi khoản." (giữa màn hình).
- Không có nút thêm: chuỗi chỉ được tạo từ màn Nhập khoản (chip lặp lại).

---

### 3.9 Giới thiệu — thẻ cuối màn Cài đặt (`features/settings/about_section.dart`)

Không còn màn riêng hay route `/about` (D-039, 2026-11-10). Một `SettingsGroupTitle` "Giới thiệu" + một `SettingsCard` như A001, từ trên xuống:

| Dòng | Hành vi |
|------|---------|
| **Phiên bản** (giá trị `1.0.0 (1)` căn phải, không mũi tên) | Chỉ hiển thị |
| **Chính sách quyền riêng tư** (icon mở-trang) | Mở `AppInfo.privacyPolicyUrl(localeName)` trong trình duyệt — bản `vi` khi app tiếng Việt, `en` khi còn lại. Không mở được (offline/không có trình duyệt): đẩy `LegalScreen` đọc bản nhúng |
| **Điều khoản sử dụng** (icon mở-trang) | Như trên với `AppInfo.termsUrl(localeName)` |
| **Giấy phép mã nguồn mở** | Mở trang giấy phép chuẩn của Flutter (tên app, phiên bản); luôn đọc được offline |
| **Đánh giá Ví Gọn** (icon mở-trang, chỉ Android) | Thử `market://details?id=com.phiotron.vigon` rồi tới Play HTTPS. iOS ẩn hàng này khi `AppInfo.appStoreId == null` (không để nút chết) |
| **Gửi góp ý** (icon mở-trang) | `mailto:` tới email liên hệ, tiêu đề "Góp ý Ví Gọn {phiên bản}" |
| **Báo lỗi bảo mật** (phụ đề "Email liên hệ: …", icon mở-trang) | `mailto:` tiêu đề "Báo lỗi bảo mật Ví Gọn" (COMPLIANCE S-05: kênh nêu đích danh trong app) |

Dưới thẻ, chữ phụ: "Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.".

Không mở được trình duyệt/email: hiện "Không mở được. Bạn có thể tự gửi email tới …". Mở liên kết bằng intent nên app không cần quyền INTERNET.

Nguồn chữ pháp lý: `store/legal/{privacy-policy,terms-of-use,support}.{vi,en}.md`; xuất HTML bằng `tool/md_to_html.py` và bản nhúng bằng `tool/md_to_dart.py`; trang công khai ở `phamphuongphuongnd.github.io/legal/vigon/`.

---

### 3.10 Màn khóa PIN (`features/lock/lock_screen.dart`, `pin_pad.dart`)

Phủ kín app, không thuộc router (có `Navigator` riêng). Chỉ hiện khi đã bật PIN và đang ở trạng thái khóa.

- Trong lúc đang kiểm tra có bật PIN hay không: màn trống cùng màu nền.
- Khi đã khóa: icon ổ khóa, tiêu đề "Nhập mã PIN", **4 chấm tiến độ** (đầy dần khi gõ), dòng báo lỗi (cao cố định 24 dp), **bàn phím 3×4** (1–9, ô trống, 0, ⌫; nút bầu dục cao ≥ 64 dp), và nút chữ **"Quên mã"**.
- Gõ đủ 4 số thì tự kiểm: đúng → mở khóa, vào lại đúng màn đang xem; sai → "Sai mã PIN", xóa các chấm để nhập lại (không giới hạn số lần, không chờ).
- "Quên mã": xem F-11.
- Trình đọc màn hình nghe "Đã nhập N trên 4 số" (vùng thông báo trực tiếp) và "Số N" cho từng nút.

---

### 3.11 Đặt mã / nhập mã (hộp thoại toàn khung, `data_actions.dart`)

Dùng chung `PinPad` với màn khóa, mở từ công tắc "Khóa bằng mã PIN":
- **Bật** (`_PinSetup`): tiêu đề "Đặt mã PIN 4 số" kèm cảnh báo quên mã; nhập xong chuyển sang "Nhập lại mã PIN"; hai lần khớp thì lưu và đóng; lệch thì "Hai lần nhập không khớp" và bắt đầu lại từ lần nhập đầu. Thanh tiêu đề "Khóa bằng mã PIN" có mũi tên quay lại; quay lại (hoặc Back hệ thống) là hủy, mã không được bật.
- **Tắt** (`_PinCheck`): tiêu đề "Nhập mã PIN"; đúng → tắt PIN; sai → "Sai mã PIN".

---

### 3.12 Hộp thoại và bảng phụ (tóm tắt, chi tiết ở mục 4)

Bảng chọn kỳ, hộp chọn khoảng ngày, bảng thêm/sửa danh mục, hộp thoại chuyển khoản khi xóa danh mục, bảng thêm/sửa tài khoản, hộp thoại ngân sách, hộp thoại chọn tiền tệ, hộp thoại sửa chuỗi định kỳ, các hộp thoại xác nhận, bảng chọn lặp lại và tài khoản trong màn Nhập khoản, hộp thoại mật khẩu sao lưu tự động (4.8), hộp thoại giải thích nhắc ghi sổ (4.9).

---

### 3.13 Widget màn hình chính (bản 1.2, F-26, chỉ Android; `android/app/src/main/`)

**Mục đích:** ghi khoản chi hoặc thu từ màn hình chờ bằng một chạm, không phải tìm app (AC-63). Đây là widget Android (`AppWidgetProvider`), không phải màn của Flutter; nó vẽ bằng `RemoteViews` từ `res/layout/vigon_widget.xml`. Giao diện thật trên launcher CHƯA kiểm chứng trên máy (docs/TESTING.md, AC-63 và AC-64).

**Thêm vào màn hình chờ:** nhấn giữ màn hình chờ → Widget → "Ví Gọn" (mô tả "Thêm nhanh khoản chi hoặc thu"). Cỡ mặc định 2×2 ô (`targetCellWidth=2`, `targetCellHeight=2`), tối thiểu 110×110 dp, co giãn được cả hai chiều. Khớp SPEC AC-63 (`docs/SPEC.md` mục 3c, cỡ tối thiểu 2×2; SPEC đã đổi từ 2×1 ngày 2026-11-04 vì một hàng 40 dp cắt mất nút khi có thêm dòng trạng thái, ghi chú trong `vigon_widget_info.xml`). App đẩy nội dung mới khi có thay đổi (xem dưới); ngoài ra Android vẽ lại widget mỗi 30 phút (`updatePeriodMillis=1800000`, mức tối thiểu cho phép) chỉ để bỏ số của kỳ đã hết khi app không chạy. Không cần quyền nào và không dùng mạng.

**Bố cục (trên xuống dưới), nền xanh đậm `#0E5244` bo góc 20 dp, đệm 8 dp:**

| # | Thành phần | Hành vi |
|---|-----------|---------|
| 1 | **Dòng trạng thái** (chữ sáng `#F7FAF8`, cỡ 12 sp, một dòng, căn giữa, cắt bằng … nếu dài) | **Ẩn mặc định** (`GONE`). Chỉ hiện khi app đã đẩy một dòng chữ sang (xem bảng trạng thái) |
| 2 | Nút **"Chi"** (tiếng Anh "Expense"), nền đỏ `#C62828`, chữ trắng đậm 18 sp, cao tối thiểu 48 dp | Chạm → mở app ở `/entry/new?type=expense`. Trình đọc màn hình: "Thêm khoản chi" ("Add expense") |
| 3 | Nút **"Thu"** (tiếng Anh "Income"), nền xanh `#2E7D32`, cùng cỡ | Chạm → mở app ở `/entry/new?type=income`. Trình đọc màn hình: "Thêm khoản thu" ("Add income") |

Hai nút nằm cạnh nhau, chia đều chiều ngang (cách nhau 8 dp). Chữ trên hai nút và nhãn đọc màn hình theo ngôn ngữ HỆ THỐNG của máy (tài nguyên Android `values`, `values-vi`, `values-en`); riêng dòng trạng thái theo ngôn ngữ đã chọn TRONG app (hoặc ngôn ngữ máy nếu chọn "Theo máy"). Widget có màu cố định, không đổi theo giao diện sáng/tối của app.

**Trạng thái của dòng trạng thái (AC-64):**

| Công tắc "Hiện số tiền trên widget" | Khóa PIN | Dòng trạng thái | Ghi chú |
|---|---|---|---|
| Tắt (mặc định) | bật hoặc tắt | Không có dòng nào: chỉ hai nút | Bộ nhớ của widget bị XÓA (không chỉ ẩn), nên không còn số nào trong máy |
| Bật | Tắt | "Tháng này đã chi 150.000 ₫" (vi) hoặc câu tương ứng tiếng Anh | Tháng hiện tại theo ngày bắt đầu tháng, mọi tài khoản, định dạng tiền như trong app |
| Bật | Tắt, có ngân sách tháng | "Tháng này đã chi 150.000 ₫ / 1.000.000 ₫" | Thêm "/ hạn mức" khi đã đặt ngân sách tháng tổng |
| Bật | **Bật** | "Đã khóa bằng PIN" | Số tiền KHÔNG được tính và không được đưa sang widget; xóa chuỗi số cũ nếu có |
| Bật | Chưa biết (đang đọc trạng thái PIN, hoặc đọc lỗi) | "Đã khóa bằng PIN" | Coi như PIN đang bật, ưu tiên không lộ số |
| Bật | Tắt, nhưng đã qua ngày cuối của kỳ tháng mà app chưa chạy để đẩy số mới | "Mở app để cập nhật" ("Open the app to update") | Dòng số cũ bị XÓA khỏi bộ nhớ widget khi hết hạn; không bao giờ hiện số của tháng cũ như của tháng này |

Chưa đọc xong cài đặt thì chưa đẩy gì; lần thay đổi kế tiếp sẽ đẩy. Số "đang tính lại" (giữ giá trị của kỳ trước lúc vừa sang kỳ mới, hoặc đang đọc ngày bắt đầu tháng) cũng không được đẩy. Nội dung được đẩy lại khi: đổi công tắc, bật/tắt PIN, đổi số đã chi (thêm, sửa, xóa khoản), đổi ngân sách tháng, đổi ngày bắt đầu tháng, đổi tiền tệ, đổi ngôn ngữ, sang ngày mới (khi app quay lại từ nền). Android giữ dòng chữ trong một file riêng của app (`SharedPreferences` chế độ riêng tư) chỉ chứa chuỗi đã định dạng kèm hạn dùng (`validUntil` = 0 giờ ngày đầu kỳ tháng kế tiếp, giờ máy); nút "xóa" của app xóa hẳn các khóa đó rồi vẽ lại widget. Hạn dùng được kiểm mỗi lần vẽ widget và bằng một báo thức không chính xác (`AlarmManager.set`, không cần quyền) đặt đúng lúc hết hạn.

**Chạm nút khi PIN bật:** Android mở app như thường; app hiện **màn khóa PIN** (mục 3.10) phủ lên, nhập đúng mã mới thấy màn Nhập khoản đã chọn đúng loại (luồng F-18). Widget không bao giờ bỏ qua PIN.

**Giới hạn của giao diện (đã biết):**
- Widget **không tự tính số của tháng mới** khi app chưa được mở: qua hết kỳ tháng thì dòng số bị bỏ và hiện "Mở app để cập nhật" tới lần mở app kế tiếp (chỉ Dart tính được số). Báo thức hết hạn không chính xác nên có thể chậm; hệ thống cũng vẽ lại mỗi 30 phút.
- Công tắc "Hiện số tiền trên widget" (và công tắc nhắc ghi sổ) là cài đặt **theo máy**: không ghi vào file sao lưu, khôi phục file (kể cả file 1.0/1.1 có chứa chúng) thì không áp, và sau khôi phục cả hai về TẮT (widget bị xóa số, lịch nhắc bị hủy). Giờ nhắc vẫn đi theo file. Phải bật lại bằng tay trên máy (có cảnh báo, có xin quyền).
- Chưa có widget hiện số tiền khi PIN bật (ngoài phạm vi, làm lộ số liệu ngoài màn khóa).

---

## 4. Hộp thoại và bảng chọn dùng chung

### 4.1 Bảng chọn kỳ (`period_picker.dart`)
Bảng kéo từ dưới lên, 6 dòng: **Ngày, Tuần, Tháng, Năm, Tất cả, Khoảng tùy chọn**; dòng đang chọn tô nổi kèm dấu ✓. Chọn một loại → đổi ngay sang kỳ chứa **hôm nay** của loại đó. Riêng "Khoảng tùy chọn" mở tiếp hộp chọn khoảng ngày chuẩn của Android (từ 2000 đến năm nay + 10, mặc định là khoảng đang xem); chọn xong áp dụng khoảng đó (tự đổi chỗ nếu chọn ngược), bấm hủy thì giữ kỳ cũ. "Tất cả" không có kỳ trước/sau (nút ‹ › không đổi gì).

**Tên kỳ hiển thị:** Ngày: "Thứ Ba, 3 thg 11, 2026"; Tuần: "2 thg 11 – 8 thg 11, 2026"; Tháng (bắt đầu ngày 1): "Tháng 11 năm 2026"; Tháng (bắt đầu ngày khác): khoảng ngày; Năm: "2026"; Tất cả: "Tất cả"; Tùy chọn: khoảng ngày.

### 4.2 Hộp thoại xác nhận chung (`_confirm`)
Tiêu đề và nội dung tùy ngữ cảnh, hai nút: **Hủy** và nút hành động (nền đậm). Đóng bằng chạm ra ngoài hoặc Back tính là Hủy.

### 4.3 Bảng thêm/sửa danh mục (`categories_screen.dart`)
Bảng kéo từ dưới lên (đẩy lên theo bàn phím):
- Tiêu đề "Thêm danh mục" hoặc "Sửa danh mục".
- Ô **"Tên"** tối đa 50 ký tự (tự focus khi thêm). Để trống → lỗi "Nhập tên". Danh mục mặc định có tên theo ngôn ngữ; nếu người dùng không đổi tên thì vẫn giữ tên mặc định theo ngôn ngữ (đổi ngôn ngữ thì tên đổi theo).
- **"Biểu tượng":** lưới 31 icon (ăn uống, đi lại, nhà, hóa đơn, mua sắm, sức khỏe, giải trí, học tập, gia đình, quà, tiền, tiết kiệm, công việc, khác…). Icon đang chọn tô màu của danh mục. TalkBack đọc "Biểu tượng 1…31".
- **"Màu":** 16 ô tròn 48 dp (đỏ, hồng, tím, chàm, xanh dương, lam, ngọc, lục, cam, nâu, xám…) toàn màu đậm để icon trắng đủ tương phản; ô đang chọn có viền và dấu ✓. TalkBack đọc "Màu 1…16".
- Chỉ với danh mục chi: ô **"Ngân sách tháng của danh mục"** (gợi ý "Để trống nếu không đặt"; số ≤ 0 báo "Số tiền phải lớn hơn 0"), xem 3.3.
- Hàng nút: **"Xóa danh mục"** (chỉ khi sửa và loại danh mục này còn từ 2 danh mục trở lên) ở trái, **"Lưu"** ở phải.
- **Xóa danh mục:** hộp thoại "Xóa danh mục này?" với dòng "N khoản sẽ được chuyển sang:" và danh sách danh mục cùng loại còn lại; chạm một danh mục đích là xóa danh mục cũ, chuyển mọi khoản và mọi chuỗi định kỳ sang danh mục đích (một giao dịch). Không cho xóa danh mục cuối cùng của một loại.

### 4.4 Bảng thêm/sửa tài khoản (`accounts_screen.dart`)
Tiêu đề "Thêm tài khoản"/"Sửa tài khoản"; ô **"Tên"** (tối đa 50, "Nhập tên" nếu trống); ô **"Số dư ban đầu"** (bàn phím số cho phép dấu âm và dấu thập phân; chỉ nhận ký tự `0-9 . , -`; để trống = 0; phép tính sai → "Phép tính không hợp lệ"); nút **"Lưu"**.

### 4.5 Hộp thoại ngân sách (`budget_dialog.dart`)
Tiêu đề "Ngân sách tháng", ô nhập số tiền (bàn phím số, tự focus). Nút: **"Bỏ ngân sách"** (chỉ khi đang có), **"Hủy"**, **"Lưu"**. Số tiền phải lớn hơn 0, không thì lỗi "Số tiền phải lớn hơn 0". Lưu thì thanh ngân sách hiện ngay ở màn chính; bỏ thì thanh biến mất. Ngân sách tính theo **tháng hiện tại** (theo ngày bắt đầu tháng), mọi tài khoản, độc lập với kỳ đang xem.

### 4.6 Hộp thoại chọn tiền tệ (`settings_screen.dart`)
Hộp thoại có **ô tìm** theo mã hoặc tên tiền tệ (không phân biệt hoa thường và dấu), danh sách dựng lười gồm đủ các mã ISO 4217 đang lưu hành (khoảng 150; JPY, KRW, VND… 0 chữ số thập phân, KWD, BHD… 3 chữ số, còn lại 2); dòng ghi chú đầu danh sách "Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi tỉ giá…" (kèm giải thích nhân/chia khi số chữ số thập phân khác nhau và có thể mất phần lẻ khi đổi ngược); dòng đang dùng có ✓. Chọn mã khác → đổi ngay (xem F-9). Khi đổi, hạn mức ngân sách tổng và hạn mức từng danh mục cũng được nhân hoặc chia theo.

### 4.7 Hộp thoại sửa chuỗi định kỳ (`recurring_screen.dart`)
Tiêu đề "Khoản định kỳ"; ô số tiền (chỉ nhận `0-9 . ,`), ô ghi chú (tối đa 200); **"Hủy"** / **"Lưu"**. Số tiền ≤ 0 hoặc sai → "Số tiền phải lớn hơn 0".

### 4.8 Hộp thoại mật khẩu sao lưu tự động (`auto_backup_section.dart`, AC-58)
Hiện sau khi người dùng đã chọn thư mục. Tiêu đề "Mật khẩu sao lưu tự động"; hai ô che ký tự (không gợi ý, không tự sửa) "Mật khẩu" (tự focus) và "Nhập lại mật khẩu"; dòng cảnh báo chữ màu lỗi "Quên mật khẩu thì không mở được các file sao lưu; bạn cần nhớ nó khi khôi phục trên máy khác."; nút **"Hủy"** và **"Bật"**. Bấm "Bật": dưới 6 ký tự → lỗi "Mật khẩu tối thiểu 6 ký tự" ở ô đầu; hai ô lệch → "Hai mật khẩu không khớp" ở ô thứ hai; hợp lệ thì đóng và trả mật khẩu. **Hủy** (hoặc Back) thì không bật gì và quyền thư mục vừa xin được bỏ lại. Hai ô bị xóa trước khi giải phóng; mật khẩu không được ghi ra file, log hay cơ sở dữ liệu, chỉ vào bộ nhớ an toàn của Android (Keystore).

### 4.9 Hộp thoại giải thích nhắc ghi sổ (`reminder_section.dart`, AC-61)
Hiện khi gạt công tắc "Nhắc ghi sổ hằng ngày" sang bật, TRƯỚC khi xin quyền của hệ điều hành. Tiêu đề "Bật nhắc ghi sổ?", nội dung "Ví Gọn sẽ gửi một thông báo mỗi ngày vào giờ bạn chọn để nhắc bạn ghi lại chi tiêu. Thông báo không chứa số liệu.", nút **"Hủy"** (không xin quyền, công tắc giữ tắt) và **"Tiếp tục"** (mới xin quyền). Đóng bằng chạm ra ngoài hoặc Back tính là Hủy. Quyền thông báo không được xin ở chỗ nào khác của app.

---

## 5. Luồng xử lý

### F-1 · Ghi một khoản chi hoặc thu (nhanh nhất)
1. Màn chính → chạm **"−"** (chi) hoặc **"+"** (thu); hoặc chạm icon danh mục quanh biểu đồ (chi, danh mục chọn sẵn).
2. Gõ số tiền (có thể kèm phép tính). Tùy chọn: ghi chú, đổi ngày, đổi tài khoản.
3. Chạm **"Chọn danh mục"** → chọn danh mục trong lưới (nút trở thành **"Lưu"**), hoặc nếu đã chọn sẵn thì chạm thẳng **"Lưu"**.
4. App ghi khoản, đóng màn; màn chính tự cập nhật biểu đồ, số dư, thanh ngân sách.
Có hai đường ngắn nhất:
- **Qua icon danh mục:** chạm icon → gõ số → chạm "Lưu" (danh mục đã chọn sẵn).
- **Qua nút "−" / "+":** chạm nút → gõ số → chạm "Chọn danh mục" → chạm một danh mục (đóng lưới, **không tự lưu**) → nút đổi thành "Lưu" → chạm "Lưu".

Lưu ý: chọn danh mục chỉ đóng lưới và điền danh mục vào chip, chưa ghi khoản; phải chạm "Lưu" ở bước cuối (xem 3.2, mục "Lưu").

### F-2 · Sửa một khoản
Các khoản → chạm khoản → màn Nhập khoản đã nạp sẵn (loại, danh mục, số tiền dạng biểu thức đơn giản, ngày, tài khoản, ghi chú) → đổi → "Lưu" (cập nhật tại chỗ, giữ nguyên liên kết chuỗi định kỳ nếu có). Không đổi được loại thu/chi của khoản đã ghi.

### F-3 · Xóa và hoàn tác
- Từ màn Nhập khoản/Chuyển tiền: icon thùng rác. Từ danh sách Các khoản: vuốt dòng sang trái.
- Xóa **ngay lập tức, không hỏi** (kể cả khoản thuộc chuỗi định kỳ; chuỗi không bị xóa).
- Hiện thanh dưới màn hình "Đã xóa" + nút **"Hoàn tác"** trong **5 giây**. Chạm Hoàn tác → ghi lại đúng bản ghi cũ (giữ nguyên id). Hết 5 giây, hoặc khi có thông báo khác thay thế, thì không hoàn tác được nữa.

### F-4 · Chọn và đổi kỳ xem
1. Chạm tên kỳ → bảng chọn loại kỳ (mục 4.1), hoặc dùng ‹ ›, hoặc **vuốt ngang** vùng biểu đồ.
2. Màn chính và danh sách Các khoản cùng đổi theo. Kỳ đang xem chỉ nằm trong bộ nhớ phiên (mở lại app về tháng hiện tại).
3. Quy tắc tính kỳ: Tuần bắt đầu theo cài đặt "Ngày đầu tuần" (Thứ Hai mặc định); Tháng bắt đầu theo "Tháng bắt đầu từ ngày" (1 đến 28; nếu hôm nay chưa tới ngày đó thì tháng bắt đầu từ ngày đó của tháng trước); Năm là 1/1 đến 31/12; Tất cả là mọi khoản.

### F-5 · Lọc theo tài khoản
Chỉ hiện icon ví khi có ≥ 2 tài khoản. Chọn một tài khoản → màn chính và Các khoản chỉ gồm khoản của tài khoản đó; chọn "Tất cả tài khoản" để bỏ lọc. Bộ lọc tự bỏ sau khi khôi phục sao lưu hoặc xóa toàn bộ dữ liệu; không giữ khi tắt app.

### F-6 · Khoản định kỳ
- **Tạo:** ở màn Nhập khoản mới, chạm chip lặp lại → chọn Hằng ngày/tuần/tháng/năm → Lưu. App ghi khoản đầu tiên (ngày đã chọn) và tạo chuỗi bắt đầu từ ngày đó.
- **Tự sinh khoản:** khi **mở app** và mỗi lần **quay lại app từ nền**, app sinh các khoản tới hạn còn thiếu tới hết ngày hôm nay (mỗi lần lặp tính từ ngày bắt đầu nên khoản ngày 31 vẫn về ngày 31 sau tháng 2; chạy nhiều lần không tạo trùng; giới hạn 3.700 khoản mỗi chuỗi mỗi lần để chống ngày máy sai). Nếu chọn ngày bắt đầu ở quá khứ thì các lần đã tới hạn được sinh ngay sau khi Lưu.
- **Dừng:** (a) ở màn Nhập khoản khi sửa một khoản thuộc chuỗi còn chạy: nút ⏹ trên chip lặp lại, hiện "Đã dừng"; hoặc (b) màn Khoản định kỳ: gạt công tắc tắt. Khoản đã tạo giữ nguyên.
- **Chạy lại:** bật công tắc ở màn Khoản định kỳ. Chuỗi tiếp tục từ **hôm nay**, KHÔNG sinh bù các lần đã lỡ lúc dừng.
- **Sửa:** chạm dòng ở màn Khoản định kỳ → đổi số tiền và ghi chú; chỉ áp dụng cho các lần sinh sau, khoản đã sinh không đổi.

### F-7 · Chuyển tiền giữa hai tài khoản
Cài đặt → Tài khoản → icon ⇄ (hoặc từ danh sách tài khoản) → chọn "Từ" và "Đến" → số tiền → Lưu. Số dư tài khoản nguồn giảm, tài khoản đích tăng cùng số tiền. Khoản chuyển **không** cộng vào thu hay chi ở màn chính và Các khoản (xuất hiện ở phần "Chuyển tiền"). Sửa/xóa từ danh sách Các khoản.

### F-8 · Quản lý danh mục
- **Thêm:** tab Chi hoặc Thu → "+" → tên (bắt buộc), icon, màu → Lưu; xuất hiện cuối danh sách.
- **Sửa:** chạm danh mục → đổi tên/icon/màu → Lưu. Danh mục mặc định giữ tên theo ngôn ngữ nếu không đổi tên.
- **Sắp xếp:** kéo tay nắm ☰; thứ tự lưu ngay và áp dụng cho biểu đồ và lưới chọn.
- **Xóa:** mở bảng sửa → "Xóa danh mục" → chọn danh mục nhận các khoản → xong. Không có lựa chọn xóa luôn cùng các khoản.

### F-9 · Đổi tiền tệ
Cài đặt → Tiền tệ → chọn mã. Đây là **đổi ký hiệu, không quy đổi tỉ giá**: con số người dùng nhìn thấy giữ nguyên. Khi số chữ số thập phân khác nhau (VND 0, USD 2…) app nhân hoặc chia (làm tròn, tối thiểu 1) mọi số tiền đã lưu (khoản, chuỗi định kỳ, số dư ban đầu, ngân sách) trong một giao dịch để giữ đúng con số. Lần mở app đầu tiên, tiền tệ tự chọn theo vùng của máy.

### F-10 · Bật khóa PIN
Cài đặt → gạt công tắc "Khóa bằng mã PIN" → màn "Đặt mã PIN 4 số" (có cảnh báo quên mã) → nhập mã → "Nhập lại mã PIN" → khớp thì lưu (chỉ lưu mã băm có muối trong bộ nhớ an toàn của Android) và công tắc bật. Lệch → "Hai lần nhập không khớp", làm lại từ đầu.

### F-11 · Mở khóa, tắt khóa, quên mã
- **Khóa lại khi nào:** mỗi lần mở app từ đầu; và khi quay lại app sau **hơn 1 phút** ở nền (đo bằng đồng hồ máy). Ra nền dưới 1 phút rồi quay lại thì không khóa.
- **Mở khóa:** nhập đúng 4 số. Sai thì xóa chấm, báo "Sai mã PIN", thử lại không giới hạn.
- **Tắt PIN:** công tắc → nhập đúng mã hiện tại → tắt.
- **Quên mã:** nút "Quên mã" → hộp thoại "Quên mã" ("Ví Gọn không có máy chủ nên không lấy lại được mã PIN. Bạn có thể xóa toàn bộ dữ liệu trong app để dùng lại.") → "Xóa toàn bộ dữ liệu" → hộp thoại 2 ("Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này?") → hộp thoại 3 ("Không hoàn tác được. Xóa hết?") → xóa toàn bộ, tắt PIN, mở khóa, vào màn chính trống. Hủy ở bất kỳ bước nào thì quay lại màn khóa.
- Nếu bộ nhớ an toàn của máy lỗi khi mở app: coi như đang khóa; màn khóa hiện bình thường và nhập mã không mở được; lối ra duy nhất là "Quên mã".

### F-12 · Sao lưu và xuất CSV
- **Xuất bản sao lưu:** hộp thoại hỏi có đặt mật khẩu không (công tắc "Đặt mật khẩu cho file", mặc định tắt; bật thì hai ô mật khẩu che ký tự, tối thiểu 6 ký tự, hai lần phải khớp, cảnh báo "Quên mật khẩu thì không mở được file này."). Không mật khẩu: ghi file tạm `vigon-AAAAMMDD-GGPP.vigon` (JSON, có mã kiểm tra, gồm đủ tài khoản, danh mục, khoản, chuỗi định kỳ và cài đặt; không có PIN), không mã hóa. Có mật khẩu (F-21, AC-55): bọc file vào phong bì mã hóa AES-256-GCM, khóa suy ra bằng PBKDF2-HMAC-SHA256 (100.000 vòng, muối ngẫu nhiên), vòng quay hiện trong lúc mã hóa. Rồi mở **bảng chia sẻ của Android** để chọn nơi gửi/lưu. App không xin quyền bộ nhớ và không lưu mật khẩu ở đâu cả.
- **Xuất CSV (F-18, AC-52):** ghi `vigon-AAAAMMDD-GGPP.csv`, tiêu đề cột và tên loại khoản theo ngôn ngữ của app. Tiếng Việt: ngăn cột bằng `;`, số thập phân bằng `,`; tiếng Anh: `,` và `.`. UTF-8 có BOM để Excel đọc tiếng Việt; ghi chú bắt đầu bằng `= + - @`, tab hoặc xuống dòng được thêm dấu `'` để Excel không chạy như công thức. Rồi mở bảng chia sẻ.

### F-13 · Khôi phục từ bản sao lưu
1. Cài đặt → "Khôi phục từ bản sao lưu" → trình chọn file hệ thống → chọn file `.vigon`.
2. App **kiểm file trước** (định dạng, phiên bản, mã kiểm tra, từng dòng) mà chưa ghi gì; file hỏng hoặc không đọc được → thông báo ngay "File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi.", không hỏi xác nhận.
3. File hợp lệ → hộp thoại "Dữ liệu hiện tại sẽ bị thay thế bằng bản sao lưu. Tiếp tục?" → "Đồng ý" / "Hủy".
4. Đồng ý → **xóa dữ liệu cũ và ghi dữ liệu mới trong một giao dịch**. Lỗi ràng buộc lúc ghi (khóa ngoại sai, số tiền ≤ 0) thì giao dịch quay lui, giữ nguyên dữ liệu cũ và báo "File không hợp lệ hoặc bị hỏng…".
5. Thành công: "Đã khôi phục dữ liệu"; bộ lọc tài khoản đặt lại "Tất cả". Cài đặt (giao diện, ngôn ngữ, tiền tệ, ngân sách…) lấy theo file.

### F-14 · Xóa toàn bộ dữ liệu
Cài đặt → "Xóa toàn bộ dữ liệu" → hộp thoại 1 ("Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này?" — nút "Xóa") → hộp thoại 2 ("Không hoàn tác được. Xóa hết?" — nút "Xóa toàn bộ dữ liệu") → xóa hết, tắt PIN, rồi tạo lại ngay các danh mục chi/thu và tài khoản "Tiền mặt" mặc định như lúc mới cài và chọn lại tiền tệ theo vùng máy (cài đặt giao diện, ngôn ngữ, ngân sách bị xóa nên về mặc định); thông báo "Đã xóa toàn bộ dữ liệu".

### F-15 · Khởi động và vòng đời
1. Mở app: kiểm tra có PIN không → khóa hoặc vào màn chính. Song song: chọn tiền tệ theo vùng (nếu chưa có) và sinh khoản định kỳ tới hạn (F-6).
2. Tắt hẳn rồi mở lại: về màn chính, kỳ là tháng hiện tại, bộ lọc tài khoản là "Tất cả". Dữ liệu đã ghi luôn còn.
3. Ra nền: ghi lại thời điểm; nếu đang bật Sao lưu tự động thì thử sao lưu (F-16). Quay lại: nếu quá 1 phút và đang bật PIN thì khóa; đồng thời sinh khoản định kỳ tới hạn và làm mới "hôm nay".
4. Xoay máy: giữ nguyên chiều dọc.
5. Mở app (bản 1.2): khởi tạo plugin thông báo, lấy route chờ từ widget và payload của thông báo nếu app được mở bằng chúng (F-17, F-18), giữ lịch nhắc khớp cài đặt đã lưu, và đẩy dòng trạng thái sang widget.

### F-16 · Sao lưu tự động vào thư mục đã chọn (SPEC F-24, AC-58 tới AC-60)
1. **Bật:** Cài đặt → Dữ liệu → gạt "Sao lưu tự động" → bộ chọn thư mục của Android (Storage Access Framework; chọn thư mục trong Google Drive, Dropbox, thẻ nhớ hoặc bộ nhớ máy) → hộp thoại mật khẩu (mục 4.8) → app lưu thư mục và mật khẩu vào bộ nhớ an toàn rồi chạy "Sao lưu ngay" lần đầu và báo "Đã sao lưu" (hoặc lỗi). Đóng bộ chọn thư mục mà không chọn: không có gì xảy ra. Không mở được bộ chọn: "Không mở được bộ chọn thư mục". Keystore lỗi lúc lưu: "Sao lưu không thành công. Thử lại bằng Sao lưu ngay", app tắt lại phần vừa bật.
2. **Tự chạy:** khi app ra nền, nếu đang bật, hôm nay chưa thử lần nào, và dữ liệu đã đổi kể từ lần sao lưu thành công trước thì ghi một file `vigon-auto-AAAAMMDD-GGPP.vigon` vào thư mục, luôn mã hóa bằng mật khẩu đã đặt (cùng định dạng F-12/F-21, không bao giờ ghi bản rõ). Phía Android ghi vào file tạm `vigon-auto-tmp-<mili giây>.part` rồi mới đổi tên thành tên chính, nên bị tắt giữa chừng thì không để lại file `.vigon` dở (file tạm mồ côi cũ hơn một ngày bị dọn). Tối đa một lần thử mỗi ngày (lần lỗi cũng tính là một lần thử); nếu lần hôm nay lỗi thì hôm sau thử lại dù dữ liệu không đổi. Sau mỗi lần ghi, app giữ 2 file `vigon-auto-*` mới nhất (D-027) và xóa file cũ hơn; không đụng file khác trong thư mục, kể cả file sao lưu tay.
3. **Lỗi:** quyền ghi bị thu hồi hoặc thư mục bị xóa: ô trạng thái hiện chữ lỗi "Không ghi được vào thư mục. Chọn lại thư mục" và nút "Chọn lại thư mục" dùng để chọn thư mục mới (giữ mật khẩu). Không crash, không dừng im lặng.
4. **Tắt:** gạt công tắc tắt → xóa mật khẩu khỏi Keystore, bỏ quyền thư mục, xóa trạng thái; file đã ghi vẫn nằm trong thư mục. "Xóa toàn bộ dữ liệu" (F-14) cũng tắt sao lưu tự động theo cách này, để một bản sao lưu rỗng không đẩy dần các file tốt ra khỏi 2 bản (D-014).
5. **Khôi phục:** dùng "Khôi phục từ bản sao lưu" (F-13) chọn file `vigon-auto-*.vigon`; app hỏi mật khẩu như file mã hóa thường. Có thể khôi phục trên máy khác nếu nhớ mật khẩu.
Việc tải lên Google Drive hay Dropbox do app đó làm; Ví Gọn không có mạng, không đăng nhập, không thêm quyền. Thư mục, mật khẩu và kết quả lần gần nhất chỉ nằm trong bộ nhớ an toàn của máy này, KHÔNG đi theo file sao lưu: khôi phục sang máy khác thì phải bật lại.

### F-17 · Nhắc ghi sổ hằng ngày (SPEC F-25, AC-61, AC-62)
1. **Bật:** Cài đặt → "Nhắc ghi sổ hằng ngày" → hộp thoại giải thích (4.9) → "Tiếp tục" → hộp xin quyền thông báo của Android (từ Android 13; máy cũ hơn không có hộp, chỉ kiểm thông báo của app có bị tắt không). Cho phép: công tắc bật và lịch được đặt. Từ chối: công tắc ở lại tắt, hiện thanh thông báo 10 giây "Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài đặt hệ thống." kèm nút **"Mở cài đặt"** (mở cài đặt thông báo của app trong hệ thống).
2. **Thông báo:** lặp mỗi ngày vào giờ đã chọn (mặc định 20:00), kênh "Nhắc ghi sổ", tiêu đề "Ví Gọn", nội dung "Hôm nay bạn đã ghi chi tiêu chưa?" (chữ theo ngôn ngữ app). Không có số tiền, không có chữ số nào. Giờ là xấp xỉ, không chính xác theo phút (không dùng quyền báo thức chính xác), nên có thể trễ vài phút tùy hệ thống tiết kiệm pin. Không rung.
3. **Đổi giờ:** chạm "Giờ nhắc" → bộ chọn giờ → lịch đặt lại ở giờ mới. **Tắt:** hủy lịch.
4. **Giữ lịch:** mỗi lần mở app, app đặt lại lịch theo cài đặt đã lưu (việc này cũng khôi phục lịch sau khi điện thoại khởi động lại hoặc app được cập nhật, bên cạnh bộ nhận BOOT_COMPLETED của thư viện thông báo); đổi ngôn ngữ thì lịch được đặt lại ngay với chữ mới.
5. **Chạm thông báo:** mở app (hoặc đưa app lên) ở **màn Nhập khoản chi**; Back về Màn chính. PIN đang bật thì màn khóa hiện trước (F-18).

### F-18 · Mở app từ widget hoặc thông báo, qua khóa PIN (SPEC F-26 và F-25, AC-62, AC-63)
1. Người dùng chạm "Chi" hoặc "Thu" trên widget, hoặc chạm thông báo nhắc.
2. **App đang tắt hẳn:** Android khởi động app kèm route (hoặc payload). Dart lấy route chờ sau khung hình đầu tiên, kiểm tra (chỉ nhận `/entry/new?type=expense|income`) rồi đi tới đó. **App đang chạy:** Android báo có route mới và Dart đi lấy ngay.
3. **PIN tắt:** thấy ngay màn "Khoản chi mới" hoặc "Khoản thu mới". **PIN bật và đang khóa** (mỗi lần mở app từ đầu; hoặc quay lại sau hơn 1 phút ở nền): màn khóa (3.10) phủ lên, nhập đúng 4 số thì lộ ra màn Nhập khoản đã chọn; không có đường nào vào màn đó mà không qua mã. Màn Cài đặt và các màn khác không bị lộ trong lúc chờ mở khóa.
4. Route lạ hoặc hỏng bị bỏ im lặng, app ở yên màn hiện tại. Mỗi route chỉ dùng một lần; mở lại app từ danh sách ứng dụng gần đây không phát lại route cũ.
---

## 6. Quy tắc hiển thị dùng chung

| Đối tượng | Quy tắc |
|-----------|---------|
| **Số tiền** | Lưu là số nguyên đơn vị nhỏ nhất (VND: đồng; USD: cent). Hiển thị theo ngôn ngữ: vi "155.000 ₫" (dấu chấm ngăn nghìn, ký hiệu sau), en "₫155,000" (dấu phẩy, ký hiệu trước). Số âm có dấu "-" |
| **Màu thu/chi** | Thu xanh (sáng `#2E7D32`, tối `#81C784`); chi đỏ (sáng `#C62828`, tối `#EF9A9A`) |
| **Màu danh mục** | 16 màu đậm cố định; icon luôn màu trắng |
| **Phần trăm** | Một chữ số thập phân ("53,7%" vi, "53.7%" en); phần trăm các danh mục trong một phần cộng đúng 100,0 (chia theo phần dư lớn nhất) |
| **Ngày** | Ngày ngắn "3 thg 11, 2026" (vi) / "Nov 3, 2026" (en); lưu `YYYY-MM-DD` giờ địa phương |
| **Chữ lớn (≥ 130% cỡ chữ hệ thống)** | Số tiền chuyển xuống dưới tiêu đề thay vì cuối dòng; hai nhóm 3 nút ở Cài đặt xếp dọc; phần trên màn Nhập khoản và Chuyển tiền cuộn được |
| **Vùng chạm** | Tối thiểu 48×48 dp cho mọi nút; nút "−", "+" cao 64 dp; phím số cao 56 dp (PIN: 64 dp); các nút chính nằm nửa dưới màn hình |
| **Thanh tiêu đề** | Tiêu đề căn trái; mũi tên Back tự có khi vào màn con |
| **Nút nổi "+"** | Hình tròn bo góc ở góc phải dưới (Danh mục, Tài khoản), đệm 88 dp ở đáy danh sách để không che dòng cuối |
| **Thông báo nhanh** | `SnackBar` ở đáy: "Đã xóa · Hoàn tác" (5 giây), "Đã khôi phục dữ liệu", "Đã xóa toàn bộ dữ liệu", "Đã dừng", "File không hợp lệ…", "Không mở được…" |
| **Giao diện** | Sáng/Tối/Theo hệ thống, màu gốc xanh ngọc `#2E7D6B` (Material 3) |

---

## 7. Trạng thái trống, lỗi và thông báo

| Tình huống | Hiển thị |
|-----------|----------|
| Kỳ chưa có khoản (màn chính) | "Bấm − để ghi khoản chi đầu tiên" thay cho vòng tròn |
| Kỳ chưa có khoản (Các khoản) | "Kỳ này chưa có khoản nào" |
| Chưa có khoản định kỳ | "Chưa có khoản định kỳ. Bật Lặp lại khi ghi khoản." |
| Nhập sai phép tính (ví dụ `5+`) | "Phép tính không hợp lệ" (đỏ, dưới số tiền) |
| Số tiền bằng 0 hoặc âm | "Số tiền phải lớn hơn 0" |
| Tên danh mục hoặc tài khoản trống | "Nhập tên" |
| Chuyển tiền hai tài khoản giống nhau | "Chọn hai tài khoản khác nhau" |
| Nhập PIN sai | "Sai mã PIN" |
| Hai lần đặt PIN lệch | "Hai lần nhập không khớp" |
| File sao lưu hỏng | "File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi." |
| Không mở được liên kết/email | "Không mở được. Bạn có thể tự gửi email tới …" |
| Vượt ngân sách | Chữ đỏ đậm "Ngân sách tháng: Vượt X", thanh đầy màu lỗi (có chữ, không chỉ dựa vào màu) |
| Mật khẩu sao lưu tự động dưới 6 ký tự / hai ô lệch | "Mật khẩu tối thiểu 6 ký tự" / "Hai mật khẩu không khớp" (dưới ô, trong hộp thoại) |
| Sao lưu tự động: quyền ghi bị thu hồi hoặc thư mục mất | Phụ đề trạng thái chữ màu lỗi và thông báo "Không ghi được vào thư mục. Chọn lại thư mục"; nút "Chọn lại thư mục" |
| Sao lưu tự động: lỗi khác (mã hóa, ghi file, Keystore) | "Sao lưu không thành công. Thử lại bằng Sao lưu ngay" |
| Không mở được bộ chọn thư mục | "Không mở được bộ chọn thư mục" |
| Chưa sao lưu tự động lần nào (đang bật) | Phụ đề "Chưa sao lưu lần nào" |
| Bấm "Sao lưu ngay" khi đang có lần sao lưu khác chạy | "Đang sao lưu, thử lại sau giây lát" |
| Widget có số của tháng đã hết mà app chưa chạy | "Mở app để cập nhật" thay cho dòng số |
| Nhắc ghi sổ bị từ chối quyền thông báo | Thanh 10 giây "Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài đặt hệ thống." kèm nút "Mở cài đặt"; công tắc ở lại tắt |
| Widget khi PIN bật (công tắc hiện số đang bật) | "Đã khóa bằng PIN" thay cho số tiền; công tắc tắt thì không có dòng nào |
| Đang nạp khoản để sửa | Vòng quay tiến trình giữa màn Nhập khoản |
| Khoản cần sửa không còn | Màn Nhập khoản tự đóng |

Mọi lỗi nhập liệu hiện ngay trên màn, không dùng hộp thoại; không có trạng thái lỗi mạng hay "đang tải" kéo dài vì app không dùng mạng.

---

## 8. Khả năng tiếp cận (TalkBack)

- Mọi nút bấm được có nhãn đọc (tooltip hoặc `Semantics`); đã kiểm tự động bằng `test/features/g6_accessibility_test.dart` (vùng chạm, nhãn, tương phản, lỗi vỡ bố cục, ở giao diện sáng/tối, cỡ chữ 100% và 200%) và bằng cây giao diện trên máy thật.
- **Biểu đồ:** trình đọc màn hình nghe một câu "Chi tiêu theo danh mục: Nhà cửa, 3.500.000 ₫, 53,7%; …", không đọc từng cung.
- **Icon danh mục quanh biểu đồ:** nhãn "Thêm khoản chi: Ăn uống, 282.000 ₫, 4,3%" (hoặc "…, chưa có khoản"), có hành động chạm.
- **Thanh ngân sách:** đọc nguyên câu trạng thái.
- **Vùng số tiền đang gõ:** vùng thông báo trực tiếp, đọc lại mỗi khi đổi.
- **PIN:** "Số N" cho nút số, "Xóa lùi" cho ⌫, "Đã nhập N trên 4 số" cho chấm tiến độ.
- **Nút ⌫, "=":** "Xóa lùi", "Bằng".
- **Danh mục:** icon đọc "Biểu tượng N", màu đọc "Màu N" kèm trạng thái đã chọn.
- Màu không phải kênh thông tin duy nhất: vượt ngân sách có chữ "Vượt"; thu chi có dấu và vị trí.
- **Widget (bản 1.2):** nút "Chi" và "Thu" có `contentDescription` "Thêm khoản chi" và "Thêm khoản thu" (hoặc "Add expense", "Add income" theo ngôn ngữ máy), cao tối thiểu 48 dp; test tự động chỉ kiểm file bố cục có hai mô tả này. Đọc bằng TalkBack thật CHƯA kiểm chứng.
- **Sao lưu tự động và nhắc ghi sổ:** hai công tắc là `SwitchListTile` có tiêu đề và chú thích đọc được; lỗi sao lưu có chữ, không chỉ màu lỗi. Màn `/settings` nằm trong danh sách màn của `g6_accessibility_test` (vùng chạm, nhãn, tương phản, cỡ chữ 200%) và 273 test gần nhất đạt; chưa có test riêng cho các dòng mới (cuộn tới cuối màn có thể chưa được quét hết), TalkBack thật CHƯA kiểm chứng.

---

## 9. Hạn chế và điểm lệch đã biết

Ghi theo code hiện tại; chi tiết và mức độ nằm ở `APP.md` mục "Việc dở".

- **Chưa có:** đồng bộ hai chiều giữa nhiều máy qua đám mây (cần khóa OAuth do người dùng tạo; chỉ có sao lưu một chiều vào thư mục đã chọn, F-24), widget hiện số tiền khi PIN bật (làm lộ số liệu), quy đổi tỉ giá nhiều tiền tệ, bản iOS của widget, sao lưu tự động và che nội dung (D-019) (xem `docs/SPEC.md` mục 4). Ẩn tài khoản không tự dừng các chuỗi định kỳ đang trỏ tới nó (chuỗi vẫn sinh khoản vào tài khoản ẩn).
- **PIN:** không đếm lần nhập sai, không làm chậm; giờ ra nền lấy từ đồng hồ máy nên đổi giờ máy có thể qua được hạn 1 phút. PIN chỉ chặn người cầm máy, không mã hóa dữ liệu (D-007).
- **Kỳ mặc định** ở màn chính là tháng lúc mở app; app sống qua nửa đêm thì kỳ đang xem không tự nhảy (thanh ngân sách đi theo kỳ đang xem, D-028; widget màn hình chờ thì luôn tháng hiện tại và tự sang tháng mới khi quay lại từ nền).
- **Đổi tiền tệ** USD→VND làm tròn phần lẻ, đổi lại không hoàn được (hộp chọn tiền tệ đã nói rõ điều này).
- **Số tiền một khoản tối đa 1.000.000.000.000 đơn vị nhỏ nhất**; vượt thì chỉ báo "Phép tính không hợp lệ" (chưa có thông báo riêng "quá lớn").
- **Ô "Danh mục khác"** chỉ xuất hiện khi số danh mục chi nhiều hơn số icon xếp vừa quanh biểu đồ (khoảng 17 icon ở màn 360×800), nên với vài chục danh mục mới thấy.
- **Màn Các khoản:** số tiền ở dòng khoản con căn mép phải xa hơn số tiền ở dòng danh mục (do danh mục có thêm mũi tên); chỉ là lệch thị giác.
- **Nút lọc tài khoản** ở màn chính vẫn chỉ là icon ví (không hiện tên bằng chữ trên màn hình); tên tài khoản đang lọc chỉ có ở tooltip và trình đọc màn hình.
- **Tài khoản ví ở màn chính** là menu lọc, không phải màn Tài khoản (màn đó vào qua Cài đặt).
- **CSV:** chưa thử mở bằng Excel (vi dùng `;` và dấu phẩy thập phân, cần người dùng kiểm).
- **Chưa thử trên máy thật:** TalkBack thật và cỡ chữ lớn nhất.
- Đường dẫn chính sách quyền riêng tư chưa có nên dòng đó ở màn Giới thiệu đang tắt.
- **Bản 1.2, chưa thử trên máy thật (CHƯA kiểm chứng):** chọn thư mục và ghi file vào Google Drive qua SAF, giờ thông báo thật và chạm thông báo, hộp xin quyền thông báo, giao diện widget trên launcher, nút Chi/Thu của widget, hiệu ứng khóa PIN khi vào từ widget. Phần logic có test tự động (xem `docs/TESTING.md`).
- **Widget không tự tính số tháng mới** khi app chưa mở: số chỉ được đẩy lại khi app chạy; qua hết kỳ tháng thì widget bỏ số cũ và ghi "Mở app để cập nhật". Cỡ widget 2×2 (khớp SPEC AC-63) và việc tự bỏ số cũ (báo thức, cập nhật 30 phút) CHƯA thử trên launcher thật. Công tắc "Hiện số tiền trên widget" và công tắc nhắc ghi sổ không đi theo file sao lưu (sau khôi phục về tắt).
- **Sao lưu tự động:** việc mã hóa (PBKDF2 100.000 vòng, chạy ở isolate) bắt đầu lúc app ra nền; Android có thể đóng băng app ẩn nên một lần sao lưu có thể dang dở và chỉ hoàn tất (hoặc thử lại) lần sau; thời gian mã hóa trên Galaxy A13 chưa đo. Thư mục và mật khẩu không đi theo file sao lưu nên khôi phục sang máy khác thì phải bật lại.
- **Nhắc ghi sổ:** giờ nhắc không chính xác theo phút; đổi múi giờ lúc app đang đóng thì lịch lệch tới lần mở app kế tiếp (lúc đó app đặt lại lịch theo múi giờ mới). Thông báo có thể bị tiết kiệm pin hoặc cài đặt thông báo của máy chặn.
