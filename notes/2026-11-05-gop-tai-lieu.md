# [A002-vigon] Gộp tài liệu sau khi gộp hai nhánh — 2026-11-05

Phiên con (chỉ tài liệu, không code), chạy trong lúc repo đang giữa `git merge feature/PLAN-001`. Không commit, không chạy flutter.
Đọc: `APP.md`, `docs/DECISIONS.md` (D-017..D-019) — chỉ đọc, không sửa.

## ⚠ Trạng thái git (đọc trước)
Phiên gộp đã commit merge `5227555` trong lúc phiên này đang làm. Commit đó **đã gồm việc xóa `docs/SPEC-1.1.md`, `docs/SPEC-1.2.md`**
(vì phiên này `git rm` sớm, nằm sẵn trong index) nhưng **chưa gồm nội dung SPEC hợp nhất** và các file dưới đây. Nghĩa là ở
`5227555` mục 3b/3c (F-14..F-26) chưa có trong repo; phải commit tiếp các file dưới (một commit tài liệu riêng sau merge) thì
SPEC mới đủ. Phiên này không commit (theo brief).

## Đã làm / file đã đổi
Chưa commit, cần `git add` (12 file sửa + file báo cáo này):

| File | Thay đổi |
|---|---|
| `docs/SPEC.md` | Hợp nhất SPEC (cấu trúc ở dưới); viết lại mục 4–8 |
| `docs/SPEC-1.1.md`, `docs/SPEC-1.2.md` | **Đã `git rm`** (đã nằm trong index dạng xóa) |
| `docs/TESTING.md` | BACKLOG → `notes/`; bỏ "lệch SPEC 2×1" ở AC-63/M-6; thêm mục "Bản 1.1/1.2 trên iOS (D-019)" (bảng AC chỉ-Android / F-25 / F-21 / D-017 với bước thử I-1..I-5); lệnh → `APP.md` |
| `docs/SECURITY.md` | Thêm mục quyền "iOS (D-019)"; bản đồ dữ liệu: Keychain + D-017, sao lưu iPhone/iCloud, lịch nhắc iOS; đánh dấu F-24/F-26 chỉ Android trong mô hình đe dọa; `/release` → phiên điều phối #3; BACKLOG → APP.md/notes |
| `docs/ARCHITECTURE.md` | Cập nhật theo code sau gộp: Android + iOS, schema 2, mã hóa sao lưu, sao lưu tự động, nhắc, widget, `platform_features.dart`, token/theme; bỏ "BUG-002 đang làm build hỏng" |
| `docs/RELEASE.md` | Quyền Android bản 1.2; dòng iOS chỉ-Android (D-019); export compliance trỏ sang `store/app-store.md`; mục "xóa PIN Keychain khi cài lại" → đã có (D-017), chưa kiểm chứng |
| `docs/security/MASVS-SELF-CHECK.md` | `/release` → phiên #3; câu "file sao lưu không mã hóa" sửa theo D-012; thêm mục iOS ở "Việc còn lại" |
| `docs/plans/PLAN-001-…md` | `design-mobile/` → `design/current/`; D-013 → D-018; BACKLOG → APP.md; lệnh `/check-ac`, `/spec-review` → phiên điều phối; câu hỏi mở về CI iOS → đã quyết (`ios.yml`, D-011); trạng thái "đã gộp" |
| `docs/legal/privacy-policy.md` | D-017: bỏ "app có thể hỏi PIN cũ" (vi + en, mục 2 và 7), nay app tự xóa PIN cũ khi cài lại với dữ liệu mới; khôi phục từ sao lưu iPhone thì PIN "có thể" về cùng dữ liệu; mục 9: che nội dung chỉ Android; ghi chú nội bộ cập nhật |
| `design/current/ui-spec.md` | Tiêu đề A002-vigon; đoạn "Sau khi gộp nhánh" (giao diện theo PLAN-001, iOS ẩn mục chỉ-Android); đánh dấu chỉ Android ở sơ đồ và bảng Cài đặt; bỏ "lệch SPEC 2×1"; mục 9 bỏ dẫn chiếu SPEC-1.x |
| `store/app-store.md` | Mô tả en/vi thêm tính năng có trên iPhone (tìm kiếm, ẩn tài khoản, ngân sách theo danh mục, tiền tệ ISO, nhắc ghi chép, mật khẩu file sao lưu); KHÔNG đưa widget/sao lưu tự động/che nội dung (chỉ Android, ghi ở đầu file và mục khác bản Play); What's New; App Privacy thêm gói 1.2; **Export compliance viết lại** (xem dưới); Review Notes thêm nhắc + mật khẩu |
| `store/listing.md` | Bỏ dẫn chiếu SPEC-1.2; thêm ghi chú chỉ-Android vs App Store (D-019); trạng thái kiểm chứng trỏ TESTING M-1..M-7 |
| `store/screenshots-spec.md` | Ảnh widget / sao lưu tự động chỉ cho bộ Play; ảnh iPhone không có công tắc che nội dung |

Không đụng: `DECISIONS.md`, `COMPLIANCE.md`, `CHANGELOG.md`, `APP.md`, `product.md`, `CONTEXT.md`, `lib/`, `test/`, `ios/`, `android/`, `.github/`, `pubspec.*`.

## Cấu trúc SPEC mới (`docs/SPEC.md`)
- Đầu file: dòng "Đã duyệt" giữ nguyên + bảng phiên bản (1.0, 1.1, 1.2, iOS, Gộp 2026-11-05).
- 1, 2: giữ nguyên.
- **3** Bản đầu F-01..F-13 (AC-01..AC-43), giữ nguyên; quy ước [M] nay ghi biên bản vào `notes/` + TESTING (bỏ BACKLOG).
- **3b** Bản 1.1 F-14..F-23 (AC-44..AC-57), chép nguyên văn từ SPEC-1.1; tiêu đề F-22, F-23 thêm "(chỉ Android)".
- **3c** Bản 1.2 F-24..F-26 (AC-58..AC-64), chép nguyên văn từ SPEC-1.2; F-24, F-26 "(chỉ Android, D-019)"; F-25 "(Android và iOS)" + gạch đầu dòng iOS. AC-61 thêm cụm "iOS: hộp thoại cho phép thông báo của iOS" (dòng AC duy nhất bị đổi chữ; đã đối chiếu tự động: mọi dòng AC khác giống hệt bản gốc).
- **4** Ngoài phạm vi: phần "đã đưa vào phạm vi" (gạch: iOS, ngân sách danh mục, nhắc, widget, Drive/Dropbox → F-24) + "vẫn ngoài phạm vi" + bảng gộp các mục còn hiệu lực của 1.1/1.2 (đồng bộ API, widget hiện số khi PIN bật, đa tiền tệ, gói Pro) và thêm dòng "bản iOS của widget/sao lưu tự động/che nội dung" (D-019).
- **5** Ràng buộc: quyền Android (POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED) và iOS (chỉ quyền thông báo khi bật nhắc), giao diện `design/current/`; tiểu mục **"iOS"** (COMPLIANCE D-11 trỏ tới "SPEC mục iOS"): tương ứng nền tảng khi đọc AC, danh sách tính năng chỉ Android + test `merge_ios_gating_test.dart`, F-25 chạy iOS, cách kiểm chứng khi chưa có iPhone.
- **5b, 5c**: giữ; 5b sửa "không tác vụ nền" cho đúng bản 1.2, chốt máy đo Galaxy A13.
- **6** Dữ liệu: sao lưu tay có thể mã hóa, sao lưu tự động luôn mã hóa, cấu hình ở Keystore; iOS nằm trong sao lưu iPhone/iCloud.
- **7** Rủi ro: bỏ "máy chưa cài Flutter" (khung cũ), thêm rủi ro Windows/iOS, quên mật khẩu sao lưu.
- **8** Tiêu chí hoàn thành: F-01..F-26 theo nền tảng, biên bản Android + iPhone (TestFlight), CI iOS xanh, COMPLIANCE P-01..P-05.

Kiểm: 64 dòng AC duy nhất (AC-01..AC-64), 26 mục F. `grep -rn "SPEC-1.1\|SPEC-1.2\|docs/store/\|design-mobile/" docs store design` chỉ còn: `docs/DECISIONS.md` (không được sửa; nói về lịch sử), dòng bảng phiên bản ở đầu `docs/SPEC.md` (lịch sử có chủ đích). Ngoài phạm vi grep: `notes/2026-11-04-*.md` (nhật ký, giữ nguyên).

## Export compliance (store/app-store.md) — cần người dùng/phiên #3 xác nhận
Bản nháp cũ ghi "app không tự mã hoá dữ liệu" và "Pháp: không phải khai báo" — **không còn đúng** từ bản 1.1 (AES-256-GCM file sao lưu bằng gói `cryptography`, không dùng mã hoá của iOS). Đã viết: vẫn đề xuất `ITSAppUsesNonExemptEncryption = NO` với lý do (thuật toán chuẩn, mã hoá chỉ hỗ trợ chức năng chính / bảo vệ dữ liệu người dùng, không truyền mạng), đánh dấu **⚠ PHẢI XÁC NHẬN LẠI KHI NỘP**; nếu bảng hỏi của Apple xếp là không miễn trừ thì đổi khoá thành YES (việc phiên code) và làm giấy tờ; Pháp phải kiểm lại khai báo ANSSI. Đây là nhận định của Claude, không phải tư vấn pháp lý.

## Chỗ còn nghi vấn / việc dở
1. **D-016 lệch code:** DECISIONS D-016 ghi widget `updatePeriodMillis="0"`, còn ui-spec, TESTING và test ghi 30 phút (`1800000`, để bỏ số cũ khi hết tháng). Không sửa DECISIONS (ngoài phạm vi) — phiên điều phối nên thêm dòng cập nhật vào D-016.
2. **COMPLIANCE** (không được sửa) có thể cần đồng bộ: D-11 nói "xem `docs/SPEC.md` mục iOS" (đã có tiểu mục "iOS" trong mục 5, khớp); P-01..P-05 nên ghi việc xác nhận export compliance; mục 4 về xóa PIN Keychain nay đã có code (D-017).
3. **ui-spec.md** chỉ được sửa dẫn chiếu và ghi chú iOS; mô tả bố cục/màu chi tiết vẫn theo code trước khi gộp (nhánh 1.2), CHƯA rà theo giao diện PLAN-001 — đã ghi rõ ở đầu file. Nên làm một lượt rà ui-spec riêng sau khi giao diện ổn định (phiên điều phối #2).
4. **Privacy policy:** câu "khôi phục iPhone từ sao lưu thì PIN có thể về cùng dữ liệu" dựa trên D-017 "Hệ quả" (Keychain `accessibility = unlocked`, không `ThisDeviceOnly`), CHƯA kiểm chứng trên Keychain thật. Ngày hiệu lực vẫn 2026-11-04 (chưa đăng; sửa khi đăng).
5. **TESTING:** số test sau gộp và kết quả `merge_ios_gating_test` chưa ghi — phiên gộp chạy `flutter test` thì điền vào dòng "Tổng số test tự động sau khi gộp".
6. **ARCHITECTURE** được cập nhật nhanh theo cấu trúc thư mục và DECISIONS, không đọc từng file code; mục "Điểm cần cẩn thận" vẫn dẫn `test/helpers.dart` như cũ.
7. App Store mô tả en (2.078 ký tự) và vi (2.003 ký tự), dưới 4.000. Keywords chưa thêm "reminder" vì sẽ vượt 100 ký tự.

## Kiểm tra thế nào
- Đối chiếu tự động từng dòng `- AC-` của SPEC-1.1/1.2 với `docs/SPEC.md` trước khi xóa (chỉ AC-61 khác, có chủ đích); đếm AC/F.
- grep dẫn chiếu cũ như trên. Không chạy flutter (tài liệu thuần).

## Đề xuất cải tiến xưởng
- Khi một app có SPEC bổ sung theo bản (SPEC-1.x), nên viết thẳng vào `docs/SPEC.md` thành mục 3b/3c ngay từ đầu, tránh phải gộp khi gộp nhánh.
- Mọi tính năng gốc một nền tảng nên có cột "Nền tảng" trong SPEC từ khi viết AC (để store/chính sách/TESTING lấy đúng một nguồn).
