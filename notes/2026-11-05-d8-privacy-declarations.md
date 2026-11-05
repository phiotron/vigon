# [A002-vigon] D8 · Khai báo quyền riêng tư (thận trọng) + bước thử quy đổi — 2026-11-05

Phiên con của phiên điều phối #2 ("Mockup Hi-Fi A002-vigon"). Nhánh `dev`. Theo D-025 và lựa chọn của người dùng: **khai THẬN TRỌNG**
ở Data safety / App Privacy cho kết nối tải tỉ giá (nhà cung cấp thấy IP → có thể suy ra vị trí gần đúng).

## File + đoạn đã sửa
| File | Đoạn |
|---|---|
| `store/listing.md` | Mục "Data safety" viết lại hết: hướng khai, lý do, bảng từng màn (Data collection and security · Data types · Approximate location), màn xem trước, ghi chú khi điền. Mô tả VI/EN câu sao lưu tự động: "Ví Gọn không kết nối mạng" / "does not use the network" → "không tự tải file lên" / "does not upload anything" (câu cũ sai từ D-025); số ký tự vi 2859 → 2862. Bảng IARC: "Chia sẻ vị trí" ghi rõ là với người dùng khác (vẫn No) |
| `store/app-store.md` | Mục "App Privacy" viết lại phần đầu: hướng khai, bảng từng câu, nhãn dự kiến, vì sao không dùng ngoại lệ optional disclosure; giữ các lý do cũ cho phần không phải thu thập (đổi "app không gọi mạng" → "không tự tải file lên" ở sao lưu tự động). Bullet privacy manifest: ghi CHƯA khớp, cần thêm Coarse Location. Đầu file (dòng `PrivacyInfo.xcprivacy`). App Review Notes: thêm một câu IP → Coarse Location |
| `store/closed-test-plan.md` | Tin nhắn mời tester VI/EN: "App không gửi dữ liệu nào đi"/"sends no data anywhere" → không gửi dữ liệu thu chi, chỉ lên mạng tải tỉ giá. Câu trả lời "value to users": bỏ "no data collection" |
| `docs/COMPLIANCE.md` | Mục 1 (dữ liệu cá nhân: IP → ExchangeRate-API), D-01, D-02, P-02, P-10, mục 3 (dòng cập nhật D8), mục 4 (5.1.2, ghi chú privacy manifest), mục 5 (S-42, luật bảo vệ dữ liệu) |
| `docs/legal/privacy-policy.md` | Mục 1 VI + EN: **thêm đúng MỘT câu** sau câu "nhà cung cấp tỉ giá nhận được địa chỉ IP…" (không sửa chữ đã duyệt). Ghi chú nội bộ (khối `>`): thêm mục "Cập nhật 2026-11-05 (D8)" |
| `docs/TESTING.md` | Bảng D5 thêm H-18; mục mới "Thử máy: đổi tiền tệ có quy đổi tỉ giá" Q-0..Q-7 |

Không sửa: `lib/`, `test/`, `ios/`, `android/`, `APP.md`, `docs/DECISIONS.md`, file cấp xưởng. Không chạy `flutter analyze`/`test` vì chỉ đổi tài liệu.

## Bảng khai báo
**Google Play — Data safety**
| Màn | Câu | Trả lời |
|---|---|---|
| Data collection and security | Collect or share required user data types? | **Yes** |
| | All collected data encrypted in transit? | **Yes** (HTTPS duy nhất) |
| | Account creation | Không có tài khoản |
| | Way for users to request data deletion? | **No** (cần duyệt — xem dưới) |
| Data types | Chọn | Chỉ **Location › Approximate location** |
| Approximate location | Collected / Shared | **Collected ✔ + Shared ✔** (ExchangeRate-API) |
| | Processed ephemerally? | **No** (xem dưới) |
| | Required or optional? | **Optional** (chỉ khi người dùng đổi tiền tệ) |
| | Purpose (collected) | **App functionality** |
| | Purpose (shared) | **App functionality** |

**Apple — App Privacy**
| Câu | Trả lời |
|---|---|
| Do you or your third-party partners collect data? | **Yes** |
| Loại dữ liệu | Chỉ **Location › Coarse Location** |
| Mục đích | Chỉ **App Functionality** |
| Linked to the user's identity? | **No** |
| Used for tracking? | **No** |
| Nhãn dự kiến | "Data Not Linked to You: Location"; không có "Data Used to Track You" |

## Khác brief (đã quyết theo hướng thận trọng, báo để biết)
- **Ephemeral = No**, không phải Yes: Google định nghĩa ephemeral là chỉ giữ trong bộ nhớ, không lâu hơn mức cần cho đúng yêu cầu đó.
  ExchangeRate-API giới hạn tần suất theo IP (chặn 20 phút — https://www.exchangerate-api.com/docs/free) → họ giữ IP lâu hơn một yêu cầu;
  không tìm được cam kết thời gian giữ nhật ký của họ. Brief ghi "ephemeral nếu đúng định nghĩa" → không đúng nên không khai.

## Câu người dùng cần duyệt
1. **Chính sách mục 1, câu thêm** (VI): "Địa chỉ IP có thể cho biết vị trí gần đúng của bạn (ví dụ thành phố hoặc quốc gia), vì vậy trong phần
   khai báo quyền riêng tư trên Google Play và App Store, Ví Gọn khai "vị trí gần đúng" là dữ liệu được chia sẻ với nhà cung cấp tỉ giá để phục
   vụ việc đổi tiền tệ; app không đọc và không dùng vị trí của bạn." — EN cùng nội dung.
2. **Play "request data deletion": No.** Đề xuất No vì dữ liệu duy nhất khai "thu thập" (IP/vị trí gần đúng) nằm ở nhật ký của ExchangeRate-API,
   nhà phát triển không xoá hộ được. Phương án khác: Yes (gỡ app/xoá trong app) — loại vì không xoá được thứ đã khai.
3. **Lệch nhẹ còn lại trong chính sách (chữ đã duyệt, KHÔNG tự sửa):** tiêu đề mục 1 "Chúng tôi không thu thập dữ liệu của bạn" / "We do not
   collect your data" và mục 8 "không thu thập dữ liệu của bất kỳ ai" / "does not collect data from anyone". Đúng theo nghĩa nhà phát triển
   không nhận gì, nhưng store giờ khai "thu thập" vị trí gần đúng (bởi bên thứ ba). Phương án: (a) giữ nguyên — câu thêm ở mục 1 đã giải thích
   ngay bên dưới; (b) đổi tiêu đề thành "Chúng tôi không nhận dữ liệu của bạn" / "We do not receive your data" và mục 8 "nhà phát triển không
   nhận dữ liệu của bất kỳ ai". **Đề xuất (b)** cho khớp hẳn, nhưng là chữ đã duyệt nên chờ người dùng.
4. Mô tả store "Ví Gọn không gửi dữ liệu của bạn đi đâu" giữ nguyên (đúng với dữ liệu người dùng nhập); ghi để người dùng biết.

## Việc dở cho phiên khác
- **Privacy manifest iOS chưa khớp nhãn**: `ios/Runner/PrivacyInfo.xcprivacy` → thêm `NSPrivacyCollectedDataTypes` một mục
  `NSPrivacyCollectedDataTypeCoarseLocation`, Linked false, Tracking false, purpose `NSPrivacyCollectedDataTypePurposeAppFunctionality`.
  Ngoài phạm vi (cấm sửa `ios/`) → phiên code. Widget extension giữ nguyên (không gọi mạng).
- Bước thử Q-0..Q-7 CHƯA làm; Q-7 (khôi phục đè dữ liệu mẫu) cần phép rõ của phiên điều phối/người dùng.
- `docs/TESTING.md` bảng truy vết chưa có dòng AC-70..AC-72 (ngoài brief).

## Đề xuất cải tiến xưởng
1. **Mẫu "khai báo quyền riêng tư theo luồng mạng"** trong `playbook/templates/`: mỗi yêu cầu mạng → (host, dữ liệu gửi, IP/vị trí suy ra,
   bên nhận giữ bao lâu) → map sẵn sang câu Data safety + App Privacy + `PrivacyInfo.xcprivacy`. Lần này phải dò lại từng định nghĩa.
2. **S-42 nên nêu rõ "IP tới bên thứ ba"**: mọi app gọi API bên thứ ba từ máy đều đụng câu hỏi này; xưởng chốt một mặc định (thận trọng hay
   không) để phiên con không phải hỏi lại mỗi app.
3. Khi đổi nhãn App Privacy luôn kiểm cùng lúc `PrivacyInfo.xcprivacy` (hai nơi phải khớp) — nên thêm vào checklist phát hành iOS, và giao
   cả hai cho cùng một phiên (hoặc cho phiên store quyền sửa file manifest).
4. Bước thử máy làm đổi dữ liệu mẫu chụp store: chuẩn hoá cặp "xuất `.vigon` trước / khôi phục sau" thành bước Q-0/Q-n mẫu trong TESTING.
