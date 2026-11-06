# [A002-vigon] Kế hoạch mở rộng 2.0 trước phát hành — 2026-11-06

> Người dùng duyệt kế hoạch này ngày 2026-11-06, sau 5 vòng hỏi đáp (grill) ở phiên điều phối.
> Đây là **nguồn chung cho mọi phiên con** của phiên điều phối #3 và #4. Phiên con chỉ đọc file này; muốn đổi thì
> báo về phiên điều phối.
> Số quyết định: D-030..D-035 (D-029 đã dùng cho quy đổi tiền tệ chính xác). Số AC mới bắt đầu từ **AC-74**.

## ⚠ CẬP NHẬT 2026-11-06 sau khi duyệt bản nháp SPEC — các dòng dưới đây THẮNG phần cũ của file
- **Bỏ:** quét hoá đơn (OCR/ML Kit — ML Kit gửi dữ liệu chẩn đoán về Google, trái lời hứa "không thu thập"),
  đính kèm ảnh hoá đơn, đọc thông báo Android, khoản "Điều chỉnh số dư", số dư ban đầu lấy từ tin, ghép chuyển nội bộ
  tự động, bộ đọc 10 ngân hàng.
- **Nhập tự động chỉ còn email** (IMAP + mật khẩu ứng dụng). Bản đầu **chỉ MB Bank**; nguồn chưa có mẫu email thật
  thì ẩn. Email MB là biên lai chuyển tiền đi, **không có số dư, không có tiền vào**, nên chỉ tạo **khoản chi**.
  - Chỉ nhận email có tình trạng thành công.
  - Chống nhập trùng bằng **số tham chiếu**.
  - Account lấy từ "tài khoản trích nợ".
- **Mọi khoản từ email vào hàng đợi để người dùng chọn danh mục.** Chưa chọn danh mục thì khoản chưa được tính vào
  tổng. App gợi ý sẵn danh mục theo người thụ hưởng. Có lựa chọn "Chuyển sang tài khoản của tôi" để biến khoản thành
  Transfer.
- **Ghép với khoản ghi tay:** chỉ khi cùng Account, cùng số tiền, chênh ±2 giờ (Q-03).
- **Thông báo ngân sách** chỉ hiện %, không hiện số tiền (Q-08).
- **Dashboard** là màn/tab riêng "Tổng quan" (Q-09).
- **Phiên con #3 đổi thành:** S0 → M0 schema → M1 bộ đọc email MB + hàng đợi + ghép → N2 IMAP + cài đặt hộp thư · M5
  tiết kiệm/nợ/màn hàng đợi → V3. **Bỏ N1, N3.**

## Vì sao
Ví Gọn đã có F-01..F-26 nhưng chỉ cho nhập tay. Người dùng muốn trước khi phát hành phải có thêm hai phần:
- **Nhập tự động:** đọc thông báo ngân hàng/ví, đọc email ngân hàng, quét hoá đơn.
- **Bộ tài chính đầy đủ:** Dashboard, giao dịch, danh mục, ngân sách, thống kê, tiết kiệm, cùng nhóm nâng cao.

Yêu cầu này phá ba cam kết cũ:
- SPEC §4 đang ghi ngoài phạm vi: "đọc tin nhắn ngân hàng, quét hoá đơn, AI" và "vân tay/khuôn mặt".
- D-002: không dùng SDK bên thứ ba; mạng chỉ dùng để tải tỉ giá.
- Luật xưởng: mỗi app ≤ 3 phiên điều phối. Đã ghi ngoại lệ 5 phiên ở WORKFLOW §2 và METRICS.

## Đối chiếu: đã có ↔ phải làm
| Nhóm | Đã có (giữ) | Phải làm |
|---|---|---|
| Dashboard | Biểu đồ tròn; thu/chi/số dư của kỳ; ngân sách tháng | Tổng số dư mọi tài khoản · ô "Thu − chi tháng" và ô "Ngân sách còn lại" · biểu đồ cột thu–chi · so với tháng trước |
| Giao dịch | Thêm/sửa/xoá + hoàn tác; phép tính; ngày; ghi chú; danh mục; tìm kiếm | **Giờ** · ảnh hoá đơn · lọc nâng cao (khoảng số tiền, nhiều danh mục, khoảng ngày) |
| Danh mục | Đủ; tự tạo icon/màu | Không đổi (giữ tên Đi lại / Giáo dục / Nhà cửa) |
| Ngân sách | Theo tháng và theo danh mục; đã dùng/còn lại; "Vượt" | "Sắp vượt" từ 80% (chỉnh được 50–95%) + thông báo ở mốc 80% và 100%, mỗi mốc một lần mỗi tháng |
| Thống kê | Kỳ ngày/tuần/tháng/năm/tuỳ chọn; biểu đồ tròn; % | Biểu đồ cột thu/chi · danh mục chi nhiều nhất · ngày chi nhiều nhất · đường lịch sử tổng số dư |
| Tiết kiệm | — | Mục tiêu gắn một tài khoản; góp tiền = Chuyển tiền; tiến độ = số dư tài khoản đó; có hạn |
| Nâng cao | Định kỳ, ví, chuyển tiền, nhắc ghi chép, CSV, sao lưu, PIN | Khoản nợ (sổ ghi nhớ) · Excel + PDF · lịch chi tiêu · vân tay/Face ID |
| Nhập tự động | — | Thông báo (chỉ Android) · email IMAP (cả hai nền tảng) · OCR hoá đơn (cả hai nền tảng) |

## Quyết định đã chốt
1. **Làm hết rồi mới phát hành**, trong 5 phiên điều phối: #3 Mở rộng A · #4 Mở rộng B · #5 Phát hành (**D-035**).
2. **Nguồn nhập (Import source)** (**D-030**, sửa SPEC §4):
   - **Thông báo app ngân hàng/ví:** chỉ Android, dùng `NotificationListenerService`; người dùng tự cấp quyền
     "Truy cập thông báo". Không đọc SMS vì Google Play cấm với loại app này.
   - **Email:** IMAP + **mật khẩu ứng dụng** (Gmail/Yahoo/iCloud), chỉ đọc thư gửi từ địa chỉ ngân hàng. Mật khẩu
     lưu trong Keystore/Keychain. Không dùng Gmail API vì phải qua đánh giá CASA hằng năm (**D-031**; mạng nay
     phục vụ việc thứ hai, sửa D-002/AC-43).
   - **Ảnh hoá đơn:** OCR bằng **ML Kit gói kèm trong app, cả hai nền tảng** (**D-032**, sửa "không SDK" của D-002).
3. **Bộ đọc tin:** một bộ đọc chung (±số tiền, số dư, nội dung, 4 số cuối tài khoản) + mẫu riêng cho VCB, TCB, MB,
   BIDV, VietinBank, ACB, VPBank, TPBank, MoMo, ZaloPay. Mẫu dựng từ **tin thật người dùng gửi, đã che số tài khoản**.
4. **Tự tạo tài khoản:** mỗi số tài khoản/thẻ (theo 4 số cuối) của mỗi ngân hàng thành một Account riêng, vd
   "Vietcombank …1234". Số dư ban đầu lấy từ "Số dư" trong tin, trừ ngược giao dịch của chính tin đó.
5. **Khớp số dư:** khi tin có số dư lệch với app, app tự tạo một khoản cho khớp: lệch âm → chi "Khác", lệch dương
   → "Thu khác", ghi chú "Điều chỉnh số dư". Đây là khoản thu/chi bình thường, **không thêm loại khoản mới** (**D-034**).
6. **Ghép trùng:** cùng số tiền + cùng Account trong ±2 giờ coi là một giao dịch, kể cả khi trùng với khoản ghi
   tay. Khoản có sẵn giữ dữ liệu của nó, chỉ gắn thêm nguồn. Mỗi khoản chỉ ghép được một lần (**D-034**).
7. **Chuyển nội bộ:** tiền ra ở Account A và tiền vào ở Account B (đều của người dùng), cùng số tiền, trong ±2 giờ
   → ghép thành một Transfer (**D-034**).
8. **Lưu thẳng:** khoản tự động luôn được lưu thẳng; nơi bán lạ vào "Khác"/"Thu khác". Khi người dùng sửa danh mục,
   app nhớ quy tắc **nơi bán → danh mục** (Merchant rule) cho lần sau.
   - **Hàng chờ duyệt** chỉ nhận tin mà bộ đọc không chắc số tiền hoặc chiều tiền.
   - OCR mở màn Nhập khoản đã điền sẵn; người dùng bấm Lưu.
9. **Ảnh hoá đơn** (**D-033**):
   - Lưu vào album "Ví Gọn" trong thư viện ảnh của máy, tên file `vigon-<uuid>.jpg`; app chỉ giữ tên file.
   - Ảnh **không** vào file sao lưu và nằm ngoài khoá PIN; phải nói rõ điều này trong app và trong chính sách.
   - Sau khôi phục, app gắn lại ảnh theo tên file.
10. **Tiết kiệm:** mỗi Savings goal gắn một Account (chọn sẵn có hoặc tạo mới). Góp tiền = Transfer vào Account đó.
    Đạt mục tiêu khi số dư ≥ số tiền mục tiêu.
11. **Khoản nợ:** chỉ là sổ ghi nhớ (người, cho vay/đi vay, số tiền, các lần trả, hạn). Không đụng Account, không
    tính thu/chi.
12. **Dashboard:** hiện cả "Thu − chi tháng" và "Ngân sách còn lại". Tổng số dư = tổng mọi Account, kể cả tài khoản
    ẩn (theo luật đang có).
13. **Giờ của khoản:** thêm giờ HH:mm, mặc định là lúc ghi. Khoản cũ chưa có giờ được coi là 12:00 khi ghép.
14. **Số tiền chính xác (D-029)** áp dụng cho mọi bảng/cột tiền mới. Khoản tự động lấy số tiền đúng như trong tin.

**Mặc định Claude tự chọn** (người dùng đổi được khi duyệt SPEC):
- Email kiểm khi mở app, kéo để làm mới, và chạy nền khoảng mỗi giờ trên Android (dùng lại cơ chế FlutterEngine
  không giao diện của `android/.../BackupSchedule.kt`). iOS chỉ kiểm khi mở app.
- Vân tay/Face ID chỉ bật được khi đã có PIN; PIN vẫn là đường dự phòng.
- Khoản nợ không có nhắc hạn.
- "So với tháng trước" là % thay đổi của chi và của thu.
- Lịch chi tiêu dùng lại `range_calendar.dart`.

## Phiên con
### #3 Mở rộng A — dữ liệu + nhập tự động
- **S0 — SPEC + quyết định** (chỉ tài liệu). Người dùng duyệt xong mới có code.
- **M0 — schema** (chạy một mình): sửa `lib/src/data/database.dart` lên schema v4 + migration.
  - Entries thêm giờ, `source`, `externalRef`.
  - Accounts thêm `bankKey`, `last4`.
  - Bảng mới: SavingsGoals, Debts + DebtPayments, MerchantRules, PendingImports, ReceiptPhotos.
  - Cập nhật sao lưu `.vigon` + CSV, test migration và sao lưu.
- **M1 — bộ máy nhập** (Dart thuần, `lib/src/import/`): bộ đọc chung + mẫu 10 ngân hàng/ví, ghép trùng, ghép chuyển
  nội bộ, tự tạo tài khoản, điều chỉnh số dư, Merchant rule. Test bằng mẫu tin thật.
- **Song song sau M1:**
  - **N1:** Android NotificationListenerService (Kotlin, hàng đợi native → Dart, xử lý nền) + màn cấp quyền và
    chọn app nguồn.
  - **N2:** Email IMAP (`enough_mail`) + màn cài đặt hộp thư + bộ lọc địa chỉ ngân hàng.
  - **N3:** Chụp ảnh + OCR (`google_mlkit_text_recognition`, `image_picker`) + lưu album + gắn ảnh vào khoản +
    gắn lại sau khôi phục. **Làm spike trước:** ML Kit trên iOS simulator ở CI (lát cắt arm64) và đọc tiếng Việt
    có dấu.
- **M5** (song song với M1, sau M0): màn Tiết kiệm + Khoản nợ + Hàng chờ duyệt.
- **V3:** chạy toàn bộ test + `flutter analyze` + CI Android/iOS.

### #4 Mở rộng B — xem, phân tích, tiện ích + thiết kế
- Dashboard mới.
- Màn Thống kê (`fl_chart`).
- Cảnh báo "sắp vượt" + thông báo: không hiện số khi bật PIN.
- Lịch chi tiêu, lọc nâng cao.
- Xuất Excel (`excel`) + PDF (`pdf`).
- Vân tay/Face ID (`local_auth`).
- Claude Design vẽ các màn mới → áp UI → so với mockup.
- Thử máy Galaxy A13: thông báo ngân hàng thật, IMAP thật. Phải hỏi trước khi dùng adb.

### #5 Phát hành
Giữ kế hoạch E/F/G cũ, cộng thêm khai báo mới: Data safety, App Privacy, chính sách quyền riêng tư, quyền
notification access trên Play.

## Người dùng cần làm
- Gửi mẫu thông báo và email thật của ngân hàng/ví đang dùng (che số tài khoản). Cần trước M1.
- Tạo mật khẩu ứng dụng Gmail để thử, rồi **tự nhập vào app**. Claude không nhập mật khẩu.
- Duyệt SPEC 3d trước khi có code; duyệt mockup các màn mới.

## Kiểm chứng
- `flutter analyze`, `flutter test`.
- Test tự động phải có:
  - Bộ đọc: từng mẫu tin của từng ngân hàng.
  - Ghép trùng ±2 giờ, gồm cả ca có khoản ghi tay và ca hai khoản thật cùng giá.
  - Ghép chuyển nội bộ; điều chỉnh số dư.
  - Migration; sao lưu/khôi phục có các bảng mới.
  - Tiết kiệm không làm đổi tổng thu/chi; nợ không đụng số dư.
  - Ngưỡng cảnh báo 80%.
- CI Android + iOS xanh, kiểm riêng phần build ML Kit trên iOS.
- [M] trên Galaxy A13:
  - Bật quyền thông báo, chuyển một khoản tiền thật nhỏ → khoản tự hiện đúng tài khoản.
  - Email IMAP đọc được thư ngân hàng.
  - Chụp hoá đơn → số tiền điền sẵn, ảnh vào album.
  - Khôi phục → ảnh gắn lại.
  - Vân tay.
  - Ghi biên bản vào `notes/` và `docs/TESTING.md`.
