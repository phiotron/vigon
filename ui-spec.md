# UI-SPEC — Ví Gọn (APP-001)

Mô tả giao diện và luồng xử lý của app **đúng như code hiện tại** (bản 1.0.0+1, ngày 2026-11-03), viết từ việc đọc `lib/src/app.dart`, `lib/src/features/**`, `lib/src/ui/**`, `lib/src/providers.dart` và các hàm dữ liệu mà giao diện gọi. Khác `docs/SPEC.md`: SPEC nói app PHẢI làm gì; file này nói giao diện ĐANG làm gì, kể cả chỗ chưa như SPEC (mục 9).

Nội dung chữ lấy từ `lib/l10n/app_vi.arb` (tiếng Việt, mặc định) và `app_en.arb` (tiếng Anh, cùng khóa). Chữ trong ngoặc kép là chữ tiếng Việt hiển thị.

## Mục lục
1. Tổng quan kiến trúc giao diện
2. Bản đồ điều hướng
3. Các màn hình (3.1 – 3.12)
4. Hộp thoại và bảng chọn dùng chung
5. Luồng xử lý (F-1 – F-15)
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
| Lớp phủ toàn app | `AppLifecycleWatcher` (theo dõi ra nền/quay lại) bọc `Stack` gồm: app (bị `Offstage` khi khóa) và `LockScreen` (khi bật PIN và đang khóa) |
| Thông báo nổi | `rootMessengerKey` (một `ScaffoldMessenger` gốc) để thanh "Đã xóa · Hoàn tác" còn hiện sau khi đóng màn sửa |
| Dữ liệu | Không có mạng. Mọi thay đổi ghi ngay vào SQLite khi bấm Lưu/xác nhận |

### Bảng route (`lib/src/app.dart`)

| Route | Màn hình | Tham số |
|-------|----------|---------|
| `/` | Màn chính (`HomeScreen`) | không |
| `/settings` | Cài đặt | không |
| `/about` | Giới thiệu | không |
| `/recurring` | Khoản định kỳ | không |
| `/categories` | Danh mục | không |
| `/accounts` | Tài khoản | không |
| `/transfer` | Chuyển tiền (mới) | không |
| `/transfer/:id` | Sửa/xóa một lần chuyển tiền | `id` của khoản |
| `/entries` | Các khoản (danh sách trong kỳ) | không |
| `/entry/new` | Nhập khoản mới | `type=expense\|income` (mặc định chi), `category=<id>` (chọn sẵn danh mục) |
| `/entry/:id` | Sửa/xóa một khoản thu hoặc chi | `id` của khoản |

Tất cả là route con của `/`, nên Back từ bất kỳ màn nào cũng về màn trước, và Back ở `/` thoát app.

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
       ├─ Xuất bản sao lưu ───► Bảng chia sẻ của Android
       ├─ Khôi phục ──────────► Trình chọn file Android ──► Hộp thoại xác nhận
       ├─ Xuất CSV ───────────► Bảng chia sẻ của Android
       ├─ Xóa toàn bộ dữ liệu ► 2 hộp thoại xác nhận
       └─ Giới thiệu ─────────► Giới thiệu /about
             ├─ Chính sách quyền riêng tư ► trình duyệt (đang tắt khi chưa có đường dẫn)
             ├─ Báo lỗi bảo mật ──► app email có sẵn người nhận và tiêu đề
             └─ Giấy phép nguồn mở ► trang giấy phép của Flutter
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
| 3 | **Thanh ngân sách** (`BudgetBar`) | Chỉ hiện khi đã đặt ngân sách. Dòng chữ "Ngân sách tháng: Đã chi X / Y" và thanh tiến độ. Chi quá thì chữ đổi màu lỗi, đậm, ghi "Ngân sách tháng: Vượt Z" và thanh đầy. Chạm mở hộp thoại ngân sách (mục 4.5) |
| 4 | **Vùng biểu đồ** (chiếm phần còn lại) | Vòng tròn ở giữa và icon danh mục chi xếp quanh (xem dưới). Vuốt ngang trong vùng này đổi kỳ |
| 5 | **Thanh Số dư** | Nền xám nhạt, chữ "Số dư: X", cao tối thiểu 56 dp. Chạm mở "Các khoản" |
| 6 | **Hai nút lớn** | Đỏ "−" bên trái (thêm khoản chi) và xanh "+" bên phải (thêm khoản thu), cao tối thiểu 64 dp, ở vùng ngón cái |

**Nút trên thanh tiêu đề:**
- **Icon ví "Tài khoản"** — chỉ hiện khi có từ 2 tài khoản. Mở menu: "Tất cả tài khoản" và từng tài khoản; chọn một thì toàn bộ số liệu màn chính và màn Các khoản chỉ tính khoản của tài khoản đó (khoản chuyển tiền tính nếu tài khoản là nguồn hoặc đích). Lựa chọn nằm trong bộ nhớ của phiên chạy, KHÔNG lưu khi tắt app.
- **Icon danh sách "Các khoản"** → `/entries`.
- **Icon bánh răng "Cài đặt"** → `/settings`.

**Vòng tròn và icon danh mục:**
- Vòng tròn rỗng (kiểu bánh rán) vẽ bằng `fl_chart`: mỗi danh mục chi trong kỳ là một cung màu của danh mục, sắp từ lớn đến nhỏ, bắt đầu từ vị trí 12 giờ.
- Chính giữa hiện hai dòng: tổng **thu** (màu xanh) rồi tổng **chi** (màu đỏ) của kỳ.
- Kỳ không có khoản nào: thay vòng tròn bằng chữ "Bấm − để ghi khoản chi đầu tiên" (căn giữa).
- Nếu có thu mà không có chi: vòng tròn đầy một màu xanh thu.
- **Icon danh mục:** mỗi danh mục chi (theo thứ tự người dùng sắp) là một hình tròn 48 dp xếp đều quanh vòng. Số icon hiện tối đa bằng số icon xếp vừa chu vi (`floor(2π·bán kính / 56)`, tối thiểu 1); danh mục thừa không hiện. Chạm icon mở `/entry/new?type=expense&category=<id>`, danh mục đã chọn sẵn. Giữ lâu hiện tooltip tên danh mục.
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

---

### 3.4 Cài đặt — `/settings` (`features/settings/settings_screen.dart`)

Danh sách cuộn dọc. Thứ tự các mục từ trên xuống:

| Mục | Kiểu | Hành vi |
|-----|------|---------|
| (tiêu đề nhóm) **Giao diện** | 3 nút chọn một: "Theo hệ thống" / "Sáng" / "Tối" | Chọn là đổi ngay, lưu lại. Chữ lớn (≥ 130%) thì 3 nút xếp dọc |
| (nhóm) **Ngôn ngữ** | 3 nút chọn một: "Theo máy" / "Tiếng Việt" / "English" | Đổi ngay mọi chữ, lưu lại |
| **Danh mục** ❯ | Dòng mở màn | → `/categories` |
| **Tài khoản** ❯ | Dòng mở màn | → `/accounts` |
| **Ngân sách tháng** | Dòng có phụ đề ("Chưa đặt" hoặc số tiền) | Mở hộp thoại ngân sách (mục 4.5) |
| **Khoản định kỳ** ❯ | Dòng mở màn | → `/recurring` |
| **Tiền tệ** | Dòng có phụ đề ("VND · ₫") | Mở hộp thoại chọn tiền tệ (mục 4.6) |
| **Ngày đầu tuần** | Dòng có phụ đề ("Thứ Hai"/"Chủ Nhật") | **Mỗi lần chạm là đảo** giữa Thứ Hai và Chủ Nhật, không có hộp thoại |
| **Tháng bắt đầu từ ngày** | Menu thả ở bên phải | Chọn số từ 1 đến 28 |
| (nhóm) **Bảo mật** | | |
| **Khóa bằng mã PIN** | Công tắc, kèm lời cảnh báo "Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong app." | Bật → đặt mã (F-10). Tắt → nhập đúng mã hiện tại (F-11) |
| (nhóm) **Dữ liệu** | Dòng nhắc "Dữ liệu chỉ nằm trên máy này. Nên xuất bản sao lưu thường xuyên." | |
| **Xuất bản sao lưu** | Dòng, phụ đề "File sao lưu không được mã hóa. Hãy cất ở nơi an toàn." | F-12 |
| **Khôi phục từ bản sao lưu** | Dòng | F-13 |
| **Xuất CSV** | Dòng | F-12 |
| **Xóa toàn bộ dữ liệu** | Dòng màu lỗi | F-14 |
| (đường kẻ) **Giới thiệu** ❯ | Dòng mở màn | → `/about` |

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
- Tài khoản mặc định "Tiền mặt" có sẵn khi cài. Trong code hiện **không có chức năng xóa tài khoản**.

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
- Chạm dòng → hộp thoại sửa (số tiền và ghi chú, F-6). Chỉ sửa được số tiền và ghi chú, không đổi tần suất hay danh mục tại đây.
- Trống: "Chưa có khoản định kỳ. Bật Lặp lại khi ghi khoản." (giữa màn hình).
- Không có nút thêm: chuỗi chỉ được tạo từ màn Nhập khoản (chip lặp lại).

---

### 3.9 Giới thiệu — `/about` (`features/about/about_screen.dart`)

Nội dung từ trên xuống: tên "Ví Gọn" (cỡ lớn), "Phiên bản 1.0.0 (1)", dòng "Dữ liệu chỉ lưu trên máy này. Ví Gọn không gửi dữ liệu đi đâu.", đường kẻ, rồi 3 dòng:

| Dòng | Hành vi |
|------|---------|
| **Chính sách quyền riêng tư** | Mở trình duyệt tới `AppInfo.privacyPolicyUrl`. Khi đường dẫn còn trống (hiện tại): dòng bị tắt và phụ đề "Đang chuẩn bị trang web" |
| **Báo lỗi bảo mật** (phụ đề "Email liên hệ: …") | Mở app email: người nhận là email liên hệ, tiêu đề "Báo lỗi bảo mật Ví Gọn" |
| **Giấy phép nguồn mở** | Mở trang giấy phép chuẩn của Flutter (tên app, phiên bản) |

Nếu hệ thống không mở được trình duyệt/email: hiện "Không mở được. Bạn có thể tự gửi email tới …". Mở liên kết bằng intent nên app không cần quyền INTERNET.

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

Bảng chọn kỳ, hộp chọn khoảng ngày, bảng thêm/sửa danh mục, hộp thoại chuyển khoản khi xóa danh mục, bảng thêm/sửa tài khoản, hộp thoại ngân sách, hộp thoại chọn tiền tệ, hộp thoại sửa chuỗi định kỳ, các hộp thoại xác nhận, bảng chọn lặp lại và tài khoản trong màn Nhập khoản.

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
- Hàng nút: **"Xóa danh mục"** (chỉ khi sửa và loại danh mục này còn từ 2 danh mục trở lên) ở trái, **"Lưu"** ở phải.
- **Xóa danh mục:** hộp thoại "Xóa danh mục này?" với dòng "N khoản sẽ được chuyển sang:" và danh sách danh mục cùng loại còn lại; chạm một danh mục đích là xóa danh mục cũ, chuyển mọi khoản và mọi chuỗi định kỳ sang danh mục đích (một giao dịch). Không cho xóa danh mục cuối cùng của một loại.

### 4.4 Bảng thêm/sửa tài khoản (`accounts_screen.dart`)
Tiêu đề "Thêm tài khoản"/"Sửa tài khoản"; ô **"Tên"** (tối đa 50, "Nhập tên" nếu trống); ô **"Số dư ban đầu"** (bàn phím số cho phép dấu âm và dấu thập phân; chỉ nhận ký tự `0-9 . , -`; để trống = 0; phép tính sai → "Phép tính không hợp lệ"); nút **"Lưu"**.

### 4.5 Hộp thoại ngân sách (`budget_dialog.dart`)
Tiêu đề "Ngân sách tháng", ô nhập số tiền (bàn phím số, tự focus). Nút: **"Bỏ ngân sách"** (chỉ khi đang có), **"Hủy"**, **"Lưu"**. Số tiền phải lớn hơn 0, không thì lỗi "Số tiền phải lớn hơn 0". Lưu thì thanh ngân sách hiện ngay ở màn chính; bỏ thì thanh biến mất. Ngân sách tính theo **tháng hiện tại** (theo ngày bắt đầu tháng), mọi tài khoản, độc lập với kỳ đang xem.

### 4.6 Hộp thoại chọn tiền tệ (`settings_screen.dart`)
Hộp thoại danh sách: dòng ghi chú "Đổi tiền tệ chỉ đổi ký hiệu, không quy đổi số tiền." và 31 mã (VND, USD, EUR, GBP, JPY, KRW, CNY, TWD, HKD, SGD, THB, MYR, IDR, PHP, INR, AUD, NZD, CAD, CHF, SEK, NOK, DKK, PLN, CZK, HUF, TRY, BRL, MXN, ZAR, AED, SAR); dòng đang dùng có ✓. Chọn mã khác → đổi ngay (xem F-9).

### 4.7 Hộp thoại sửa chuỗi định kỳ (`recurring_screen.dart`)
Tiêu đề "Khoản định kỳ"; ô số tiền (chỉ nhận `0-9 . ,`), ô ghi chú (tối đa 200); **"Hủy"** / **"Lưu"**. Số tiền ≤ 0 hoặc sai → "Số tiền phải lớn hơn 0".

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
- **Xuất bản sao lưu:** ghi file tạm `vigon-AAAAMMDD-GGPP.vigon` (JSON, có mã kiểm tra, gồm đủ tài khoản, danh mục, khoản, chuỗi định kỳ và cài đặt; không có PIN) rồi mở **bảng chia sẻ của Android** để người dùng chọn nơi gửi/lưu. App không xin quyền bộ nhớ. File không mã hóa.
- **Xuất CSV:** ghi `vigon-AAAAMMDD-GGPP.csv` (mã hóa UTF-8 có BOM để Excel đọc tiếng Việt; ghi chú bắt đầu bằng `= + - @` được thêm dấu `'` để Excel không chạy như công thức) rồi mở bảng chia sẻ.

### F-13 · Khôi phục từ bản sao lưu
1. Cài đặt → "Khôi phục từ bản sao lưu" → trình chọn file hệ thống → chọn file `.vigon`.
2. Đọc file; không đọc được → thông báo "File không hợp lệ hoặc bị hỏng. Dữ liệu hiện tại không thay đổi."
3. Hộp thoại "Dữ liệu hiện tại sẽ bị thay thế bằng bản sao lưu. Tiếp tục?" → "Đồng ý" / "Hủy".
4. Đồng ý → kiểm định dạng, phiên bản, mã kiểm tra và từng dòng dữ liệu; hợp lệ thì **xóa dữ liệu cũ và ghi dữ liệu mới trong một giao dịch**. Bất kỳ lỗi nào (định dạng, mã kiểm tra, khóa ngoại sai, số tiền ≤ 0) thì giữ nguyên dữ liệu cũ và báo "File không hợp lệ hoặc bị hỏng…".
5. Thành công: "Đã khôi phục dữ liệu"; bộ lọc tài khoản đặt lại "Tất cả". Cài đặt (giao diện, ngôn ngữ, tiền tệ, ngân sách…) lấy theo file.

### F-14 · Xóa toàn bộ dữ liệu
Cài đặt → "Xóa toàn bộ dữ liệu" → hộp thoại 1 ("Xóa mọi khoản ghi, danh mục, tài khoản và cài đặt trên máy này?" — nút "Xóa") → hộp thoại 2 ("Không hoàn tác được. Xóa hết?" — nút "Xóa toàn bộ dữ liệu") → xóa hết, tắt PIN, rồi tạo lại ngay các danh mục chi/thu và tài khoản "Tiền mặt" mặc định như lúc mới cài và chọn lại tiền tệ theo vùng máy (cài đặt giao diện, ngôn ngữ, ngân sách bị xóa nên về mặc định); thông báo "Đã xóa toàn bộ dữ liệu".

### F-15 · Khởi động và vòng đời
1. Mở app: kiểm tra có PIN không → khóa hoặc vào màn chính. Song song: chọn tiền tệ theo vùng (nếu chưa có) và sinh khoản định kỳ tới hạn (F-6).
2. Tắt hẳn rồi mở lại: về màn chính, kỳ là tháng hiện tại, bộ lọc tài khoản là "Tất cả". Dữ liệu đã ghi luôn còn.
3. Ra nền: ghi lại thời điểm. Quay lại: nếu quá 1 phút và đang bật PIN thì khóa; đồng thời sinh khoản định kỳ tới hạn.
4. Xoay máy: giữ nguyên chiều dọc.

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

---

## 9. Hạn chế và điểm lệch đã biết

Ghi theo code hiện tại; chi tiết và mức độ nằm ở `docs/BACKLOG.md` (mục "Phát hiện của `/spec-review` chưa xử lý").

- **Chưa có chức năng xóa hay ẩn tài khoản**; chưa có tìm kiếm khoản; chưa có sửa tần suất/danh mục của chuỗi định kỳ (chỉ sửa số tiền và ghi chú).
- **PIN:** không đếm lần nhập sai, không làm chậm; giờ ra nền lấy từ đồng hồ máy nên đổi giờ máy có thể qua được hạn 1 phút. PIN chỉ chặn người cầm máy, không mã hóa dữ liệu (D-007).
- **Kỳ mặc định** ở màn chính là tháng lúc mở app; app sống qua nửa đêm thì kỳ đang xem không tự nhảy (thanh ngân sách thì tự sang tháng mới khi quay lại từ nền).
- **Khôi phục** hỏi xác nhận trước khi kiểm file (dữ liệu vẫn an toàn vì kiểm hết trước khi xóa).
- **Đổi tiền tệ** USD→VND làm tròn phần lẻ, đổi lại không hoàn được.
- **Số tiền một khoản tối đa 1.000.000.000.000 đơn vị nhỏ nhất**; vượt thì chỉ báo "Phép tính không hợp lệ" (chưa có thông báo riêng "quá lớn").
- **Danh mục chi vượt số icon xếp vừa quanh biểu đồ** thì danh mục thừa không chạm được từ biểu đồ (vẫn chọn được ở lưới chọn danh mục). Với 10 danh mục mặc định trên màn 360 dp thì đủ chỗ.
- **Màn Các khoản:** số tiền ở dòng khoản con căn mép phải xa hơn số tiền ở dòng danh mục (do danh mục có thêm mũi tên); chỉ là lệch thị giác.
- **Nút lọc tài khoản** ở màn chính chỉ là icon ví, không hiện tên tài khoản đang lọc.
- **Tài khoản ví ở màn chính** là menu lọc, không phải màn Tài khoản (màn đó vào qua Cài đặt).
- **CSV:** tiêu đề cột và loại khoản (expense, income, transfer) luôn tiếng Anh; số lẻ dùng dấu chấm; chưa thử mở bằng Excel.
- **Chưa thử trên máy thật:** TalkBack thật và cỡ chữ lớn nhất.
- Đường dẫn chính sách quyền riêng tư chưa có nên dòng đó ở màn Giới thiệu đang tắt.
