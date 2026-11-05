# [A002-vigon] D8 · Khai báo quyền riêng tư + bước thử quy đổi — 2026-11-05

Phiên con của phiên điều phối #2 ("Mockup Hi-Fi A002-vigon"). Nhánh `dev`.
- **Lần 1** (commit `18075d3`): soạn khai "thận trọng" (Play Approximate location collected + shared; Apple Coarse Location).
- **Lần 2** (commit ghi ở tin báo phiên chính): người dùng **đổi ý — khai GIỐNG A001 "không thu thập"**. Bản lần 1 đã gỡ khỏi store,
  COMPLIANCE, chính sách. Phần TESTING (H-18, Q-0..Q-7) giữ nguyên. Mẫu tham khảo (chỉ đọc): `apps/A001-subnest/store/forms/google-play.md`
  mục 6, `store/forms/app-store.md` mục 1.

## File + đoạn đã sửa (trạng thái cuối, so với trước D8 `3f9a69d`)
| File | Đoạn |
|---|---|
| `store/listing.md` | Mục "Data safety" viết lại: hướng khai "không thu thập, không chia sẻ" (giống A001), lý do (GET tỉ giá không mang dữ liệu người dùng; IP đi kèm mọi kết nối, nhà phát triển không nhận), **bảng từng màn**, "các điểm dễ hỏi khi review", điều kiện phải khai lại. Mô tả VI/EN câu sao lưu tự động: "Ví Gọn không kết nối mạng"/"does not use the network" → "không tự tải file lên"/"does not upload anything" (câu cũ sai từ D-025); số ký tự vi 2859 → 2862. IARC "Chia sẻ vị trí" ghi rõ "(với người dùng khác)" |
| `store/app-store.md` | Mục "App Privacy": hướng khai "Data Not Collected" (giống A001), **bảng từng câu** (Privacy Policy URL, Privacy Choices URL, câu collect, kết quả), lý do chi tiết; sao lưu tự động "app không gọi mạng" → "không tự tải file lên"; bullet privacy manifest: giữ `NSPrivacyCollectedDataTypes` rỗng + kiểm Generate Privacy Report; điều kiện phải khai lại (thêm "API key theo người dùng") |
| `store/closed-test-plan.md` | Tin mời tester VI/EN: "App không gửi dữ liệu nào đi"/"sends no data anywhere" → không gửi dữ liệu thu chi, chỉ lên mạng tải tỉ giá. "Value to users": thêm "no ads, no analytics", nêu nhà cung cấp chỉ thấy IP |
| `docs/COMPLIANCE.md` | Mục 1, D-01, D-02, P-02, P-10, mục 3 (dòng cập nhật D8), mục 4 (5.1.2, ghi chú privacy manifest), mục 5 (S-42, luật bảo vệ dữ liệu) — theo hướng "không thu thập" |
| `docs/legal/privacy-policy.md` | **Chữ chính sách VI/EN KHÔNG đổi** (câu thêm ở lần 1 đã bỏ). Chỉ thêm một mục ghi chú nội bộ (khối `>`) "Cập nhật 2026-11-05 (D8)" |
| `docs/TESTING.md` | Bảng D5 thêm H-18; mục mới "Thử máy: đổi tiền tệ có quy đổi tỉ giá" Q-0..Q-7 |

Không sửa: `lib/`, `test/`, `ios/` (privacy manifest giữ rỗng theo phiên chính), `android/`, `APP.md`, `docs/DECISIONS.md`, file cấp xưởng.
Không chạy `flutter analyze`/`test` vì chỉ đổi tài liệu.

## Bảng khai báo (chốt)
**Google Play — Data safety**
| Câu | Trả lời |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Encrypted in transit / deletion request | Không áp dụng (chỉ hiện khi Yes). Nếu vẫn hỏi: Yes (HTTPS) / người dùng tự xoá trong app hoặc gỡ app |
| Account creation | Không tạo tài khoản |
| Independent security review | Không (tuỳ chọn) |
| Kết quả trên store | "No data collected" · "No data shared with third parties" |

**Apple — App Privacy**
| Câu | Trả lời |
|---|---|
| Privacy Policy URL | Trang chính sách vi/en (chưa đăng) |
| Privacy Choices URL | Để trống |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |
| Kết quả trên store | **Data Not Collected** |
| `PrivacyInfo.xcprivacy` (app + widget) | `NSPrivacyTracking` false, `NSPrivacyTrackingDomains` rỗng, `NSPrivacyCollectedDataTypes` rỗng — không đổi |

## Câu người dùng cần duyệt
- Không còn câu chính sách mới (chữ chính sách giữ nguyên bản đã duyệt).
- Bảng khai báo trên: người dùng đã chốt hướng; chỉ cần xem lại lúc dán vào Play Console / App Store Connect (câu chữ form có thể đổi).
- Biết để cân nhắc (không phải việc phải làm): IP gửi tới ExchangeRate-API là dữ liệu cá nhân theo GDPR, và nhà cung cấp giới hạn tần suất theo
  IP (chặn 20 phút) nên có giữ IP một thời gian; xưởng đánh giá "IP đi kèm mọi kết nối không phải dữ liệu app collect" giống A001. COMPLIANCE
  mục 5 dòng luật bảo vệ dữ liệu vẫn "chờ luật sư (D-07)".

## Việc dở
- Bước thử Q-0..Q-7 CHƯA làm; Q-7 (khôi phục đè dữ liệu mẫu) cần phép rõ của phiên điều phối/người dùng.
- `docs/TESTING.md` bảng truy vết chưa có dòng AC-70..AC-72 (ngoài brief).

## Đề xuất cải tiến xưởng
1. **Chốt một mặc định xưởng cho "app gọi API công khai từ máy"** (A001 và A002 cùng gặp): ghi vào `playbook/STANDARDS.md` S-42 — "GET không
   mang dữ liệu người dùng, không API key theo người dùng → Data safety No / Data Not Collected; chính sách nêu nhà cung cấp thấy IP". Lần này
   phiên con soạn hướng "thận trọng" rồi phải làm lại vì quyết định nằm ở app khác.
2. **Mẫu `store/forms/` của A001** (bảng từng màn Play/Apple) nên đưa lên `playbook/templates/` để app mới chép — A002 đang để Data safety
   trong `listing.md`, khác chỗ với A001.
3. Brief phiên con về khai báo store nên dẫn luôn "app tham chiếu cùng tình huống" (ở đây A001) để đỡ một vòng làm lại.
4. Bước thử máy làm đổi dữ liệu mẫu chụp store: chuẩn hoá cặp "xuất `.vigon` trước / khôi phục sau" thành bước mẫu trong TESTING.
