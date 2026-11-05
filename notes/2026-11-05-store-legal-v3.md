# [A002-vigon] Tài liệu theo quyết định mã hoá + iCloud — store & pháp lý v3 (báo cáo phiên con)

Phiên điều phối #1 · 2026-11-05 · tiếp `notes/2026-11-05-store-legal-v2.md` (commit `095ca39`), mục "chờ quyết".
Người dùng quyết 2026-11-05: (1) export compliance iOS = `true`, chọn "Standard encryption algorithms…", **vẫn bán ở Pháp ngay
bản 1**, người dùng tự nộp khai báo mã hoá cho Pháp (ANSSI); (2) DB iOS **loại khỏi sao lưu iCloud/máy tính**, giống Android.
Chỉ sửa tài liệu. Không sửa code, `ios/`, `APP.md`, `product.md`. Không push, không nộp/đăng gì. Không dùng subagent.

## Đã làm / file đã đổi
| File | Việc |
|---|---|
| `docs/DECISIONS.md` | Thêm **D-021** (DB iOS loại khỏi sao lưu, giống Android) và **D-020** (export compliance `true`, vẫn bán ở Pháp, khai ANSSI) đúng định dạng D cũ (Bối cảnh / Quyết định / Lý do – phương án đã loại / Hệ quả). D-021 ghi rõ câu "PIN vẫn giữ khi chuyển máy" ở D-017 không còn đúng, và khoảng hở D2D của Android |
| `store/app-store.md` | Đầu file: trạng thái khoá + DB theo D-020/D-021, lời nhắc đối chiếu code trước khi dán. Phân phối: **có Pháp**, tải khai báo Pháp trước App Review. Mô tả en/vi: bỏ "dữ liệu có trong sao lưu iPhone" → "không nằm trong sao lưu iCloud/máy tính; đổi máy tự xuất file" (EN 2.116, VI 2.033 ký tự, < 4.000). App Privacy giữ **Data Not Collected** + lý do D-021, mã hoá trên máy. **Viết lại mục Export compliance** theo D-020: sự thật code (AES-256-GCM, PBKDF2 100.000 vòng), bảng Apple có link, câu trả lời bảng hỏi, tải khai báo Pháp, `ITSEncryptionExportComplianceCode`, dự phòng nếu ANSSI chậm (hỏi lại người dùng, không tự bỏ Pháp) |
| `docs/legal/privacy-policy.md` | Mục 2 vi/en: iPhone loại dữ liệu khỏi sao lưu iCloud/máy tính; đoạn chung "cả hai nền tảng đừng trông vào sao lưu điện thoại → tự xuất `.vigon`"; câu khôi phục iPhone từ sao lưu → app trống, PIN cũ bị xoá (D-017). Mục 7: bỏ "bản sao lưu iPhone/iCloud". Ghi chú nội bộ: cập nhật D-021, chỉ đăng khi code vào `main`, lý do không hứa về chuyển máy trực tiếp |
| `docs/COMPLIANCE.md` | P-03 viết lại theo D-020 (còn CHƯA gì); D-02 thêm dòng D-021; mục 3 thêm dòng cập nhật + nguồn đã đọc; mục 4: dòng Data Storage Guidelines (cờ do-not-back-up), ghi chú "Sao lưu iCloud" và "Export compliance" theo quyết định |
| `docs/RELEASE.md` | Định danh iOS theo D-020/D-021. **Mục mới "Khai báo mã hoá cho Pháp (ANSSI)"**: vì sao, thời gian, 11 bước (nộp ở đâu, tài khoản, giấy tờ ANSSI ↔ bản tương đương cho cá nhân, tờ kỹ thuật điền sẵn theo code, xác nhận, tải lên App Store Connect, mã compliance, lưu hồ sơ ngoài repo), nguồn có link. Điều kiện chặn iOS: 2 quyết định đánh [x], thêm 5 việc còn mở (khoá trên `main`, ANSSI, Apple duyệt + mã, code loại DB + log CI) |

## Kiểm tra thế nào
- Đọc code đang sửa của phiên iOS chạy song song (chỉ đọc `git diff`, chưa commit lúc kiểm): `ios/Runner/Info.plist` đổi
  `ITSAppUsesNonExemptEncryption` → `<true/>`; `AppDelegate.swift` kênh `vigon/backup_exclusion` đặt `isExcludedFromBackup` và đọc lại cờ;
  `lib/src/data/database.dart` gọi loại khỏi sao lưu sau mỗi lần mở DB. Tài liệu mô tả theo cách này, ghi "chưa commit lúc ghi".
- `lib/src/data/backup_crypto.dart`: AES-256-GCM, nonce 12 byte, PBKDF2-HMAC-SHA256 100.000 vòng, muối 16 byte → dùng cho tờ kỹ thuật ANSSI.
- `android/app/src/main/AndroidManifest.xml`: `allowBackup="false"`, **không** có `dataExtractionRules`.
- Nhãn trong chính sách khớp `.arb`: "Khôi phục từ bản sao lưu" / "Restore from backup".
- Dò lại 5 file bằng grep: không còn câu "có trong sao lưu iPhone", "bỏ Pháp" (trừ chỗ ghi phương án đã loại), "đề xuất đổi", "vẫn hỏi mã PIN".
- Đếm ký tự mô tả App Store bằng script (EN 2.116, VI 2.033).
- Web (đọc trực tiếp 2026-11-05 bằng trình duyệt trong app):
  - Apple — [Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/) (chuẩn ngoài OS → khai báo Pháp, chỉ khi bán ở Pháp);
    [Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance);
    [Determine and upload app encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation) (đường dẫn trong App Store Connect, ~2 ngày làm việc, giá trị khoá cho Xcode, xong trước App Review/TestFlight App Review).
  - ANSSI — [Contrôle relatif à un moyen de cryptologie](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/),
    [Démarches à accomplir](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/controle-rglementaire-cryptographie-demarches/) (fourniture en France → déclaration),
    [Formulaires](https://cyber.gouv.fr/controle-reglementaire-sur-la-cryptographie-les-formulaires) → [biểu mẫu demarche.numerique](https://demarche.numerique.gouv.fr/commencer/declaration-relative-a-un-moyen-de-cryptologie) (giấy tờ, ~28 phút),
    [Contact](https://cyber.gouv.fr/contact-acces/contact/) (`controle@ssi.gouv.fr` cho thủ tục mật mã).
  - Android — [Behavior changes Android 12, Backup and restore](https://developer.android.com/about/versions/12/behavior-changes-12#backup-restore) (D2D).
  - **Không đọc trực tiếp được** Nghị định 2007-663 trên Légifrance (trang chặn trình duyệt tự động); thời hạn 1 tháng / im lặng = được tiến
    hành / đòi bổ sung lấy từ kết quả tìm kiếm trích văn bản → ghi rõ trong RELEASE để người dùng đọc lại. Không tải notice PDF (cần hỏi trước khi tải file).
- Không chạy `flutter analyze/test` (không đổi code).

## Việc người dùng phải làm
1. **Nộp khai báo mã hoá cho ANSSI ngay** (chờ ~1 tháng từ khi hồ sơ đủ): `docs/RELEASE.md` mục "Khai báo mã hoá cho Pháp" — tạo tài khoản
   demarche.numerique bằng email, đọc notice, chọn Fourniture, đính 4 giấy tờ (giới thiệu cá nhân, ghi chú không có Kbis/giấy tuỳ thân,
   mô tả + ảnh, tờ kỹ thuật điền sẵn). Chỗ chưa chắc (cá nhân không có Kbis, biểu mẫu hỏi importation) → email `controle@ssi.gouv.fr`.
2. Khi có xác nhận ANSSI: điền Description + Availability (có Pháp) trong App Store Connect → App Information → App Encryption
   Documentation → trả lời bảng hỏi → tải PDF → khi Apple duyệt, gửi giá trị khoá cho phiên điều phối.
3. Ghi ngày nộp, số hồ sơ, ngày duyệt vào COMPLIANCE P-03; giấy tờ cất ngoài repo.
4. Mỹ (mass market 5D992.c) và mọi điểm pháp lý: luật sư xác nhận nếu cần — Claude không khẳng định.
5. Đăng chính sách: chỉ đăng bản này **sau khi** code loại DB khỏi sao lưu iOS đã vào `main` (nếu không, chính sách hứa sai).

## Việc dở / rủi ro (cho phiên điều phối)
- **Phụ thuộc phiên code iOS:** khoá `true`, test, `ios.yml`, cờ loại DB khỏi sao lưu — lúc ghi CHƯA commit. Tài liệu đã viết theo quyết định; nếu phiên code làm khác (ví dụ đổi chỗ DB) thì sửa mục 2 chính sách, D-021, COMPLIANCE mục 4.
- **Sau khi Apple duyệt:** cần một việc code nhỏ thêm `ITSEncryptionExportComplianceCode` vào `Info.plist` (và test nếu test kiểm khoá).
- **Android D2D:** app target 36; ở máy một số hãng `allowBackup=false` vẫn cho chuyển dữ liệu máy-sang-máy trực tiếp. Chính sách đã viết
  để không hứa điều này. Muốn thật sự "giống nhau" → thêm `android:dataExtractionRules` loại `device-transfer` (việc code, cần quyết).
- **File ngoài phạm vi còn câu cũ về sao lưu iCloud** (không sửa vì ngoài brief): `store/listing.md:105` ("iOS thì dữ liệu nằm trong sao lưu
  iPhone nếu người dùng bật"), `docs/SPEC.md:213` (mục 6), `docs/SECURITY.md` dòng 26–27 (bảng dữ liệu), `docs/security/MASVS-SELF-CHECK.md:22`,
  có thể cả `product.md`/`CONTEXT.md`; `APP.md` "Việc dở" còn câu "Export compliance phải xem lại". Cần một lượt sửa nhỏ.
- **ANSSI chậm hơn ngày nộp iOS:** D-020 không cho tự bỏ Pháp; phiên điều phối phải hỏi lại người dùng.
- Câu chữ bảng hỏi App Store Connect và biểu mẫu ANSSI (đang "en cours de développement") có thể đổi — đọc lại ngày làm.
- Khôi phục iPhone từ sao lưu → app trống, PIN cũ bị xoá: suy ra từ D-017 + cờ loại sao lưu, CHƯA thử trên máy thật.

## Đề xuất cải tiến xưởng
1. **Checklist `release-ios.md`:** thêm mục "mã hoá tự cài (gói Dart/JS/C) → `ITSAppUsesNonExemptEncryption=true` + khai báo Pháp **nộp
   ANSSI ≥ 6 tuần trước ngày nộp iOS**" — đây là việc có thời gian chờ dài nhất của iOS, phải vào kế hoạch phiên #3 từ sớm.
2. **Mẫu `docs/legal/` cho xưởng:** một khung "tờ kỹ thuật mật mã" (sản phẩm, chức năng mã hoá, thuật toán, độ dài khoá, thư viện, không key
   escrow) dùng lại cho mọi app có mã hoá; và câu chuẩn chính sách "không vào sao lưu hệ thống, tự xuất file" cho app offline.
3. **Mặc định cho app offline của xưởng:** Android thêm `dataExtractionRules` (loại cả cloud-backup và device-transfer) thay vì chỉ
   `allowBackup=false`; iOS đặt cờ loại sao lưu ngay từ template DB — tránh lệch nền tảng phát hiện muộn như lần này.
4. Khi một quyết định đổi câu chữ chính sách, giao luôn **một danh sách mọi file nhắc chủ đề đó** (grep theo từ khoá, ví dụ "iCloud") cho
   phiên tài liệu, để không còn file ngoài phạm vi giữ câu cũ.
