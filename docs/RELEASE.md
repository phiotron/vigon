# RELEASE — Ví Gọn (A002-vigon)

Cập nhật 2026-11-04 (thêm iOS / App Store); 2026-11-05 sau khi gộp bản 1.2 (D-019). Chưa phát hành. Mục nào ghi "CHƯA" là việc còn lại; việc của người dùng ghi rõ.
Checklist xưởng dùng kèm: `D:\Mobile App\playbook\checklists\release-android.md`, `release-ios.md`.

## Định danh
- Bundle ID / package name: `com.phiotron.vigon` (cả Android và iOS)
- Phiên bản hiện tại: `pubspec.yaml` `version: 1.0.0+1` → Android versionName `1.0.0` / versionCode `1`. Mỗi lần nộp Play phải tăng số sau `+`.
  iOS: `CFBundleShortVersionString` lấy `1.0.0` từ pubspec; **build number = số lần chạy workflow** (`github.run_number`, đặt trong
  `.github/workflows/release-ios.yml`) nên tự tăng mỗi lần build ký — không trùng với versionCode Android, đó là bình thường.
- Store: Google Play [x] · App Store [x] (iOS thêm vào bản 1 ngày 2026-11-04, D-001) · phân phối nội bộ [ ]
- Android: minSdk 24 (Android 7.0), targetSdk 36 (kiểm bằng `aapt2 dump badging`, 2026-11-03). Quyền (bản 1.2): chỉ `POST_NOTIFICATIONS`
  và `RECEIVE_BOOT_COMPLETED` cho nhắc ghi chép (D-015); bản release không có INTERNET (`test/manifest_test.dart` và `aapt2 dump permissions`).
- iOS: min iOS 15.0, **chỉ iPhone**, chỉ dọc, tên hiển thị `Ví Gọn`, không khoá `NS…UsageDescription`,
  `ITSAppUsesNonExemptEncryption` = **`true`** (D-020: F-21 dùng AES-256-GCM Dart thuần trên iOS; bán ở Pháp → khai báo mã hoá Pháp, mục
  "Khai báo mã hoá cho Pháp" bên dưới), DB **loại khỏi sao lưu iCloud/máy tính** (D-021, giống Android `allowBackup=false`) — cả hai đã có trong
  code (commit `8441b6a`, 2026-11-05; CHƯA thấy CI iOS xanh), `ios/Runner/PrivacyInfo.xcprivacy` (commit `9438ddd`).
  Widget, sao lưu tự động, che nội dung, icon đơn sắc chỉ có trên Android; nhắc ghi chép có cả iOS (D-019).
- Tài khoản nhà phát triển: **cá nhân** trên cả hai store (2026-11-04) → tên người bán hiện công khai là họ tên thật; Play bắt closed test.

## Ký ứng dụng — Android
**Trạng thái: CHƯA có khóa ký phát hành.** Bản `flutter build apk --release` hiện ký bằng khóa debug, chỉ để thử trên máy, KHÔNG nộp store. Cấu hình ký đã sẵn trong `android/app/build.gradle.kts`: có `android/key.properties` thì ký bằng khóa đó; không có thì `flutter build appbundle` bị chặn với thông báo "Thiếu android/key.properties".

Việc của **người dùng** (Claude không tạo, không giữ, không đọc khóa và mật khẩu):

1. Tạo khóa ngoài repo, ví dụ ở `D:\Keys\vigon\` (thư mục này KHÔNG nằm trong `D:\Mobile App`). Trong PowerShell hoặc Git Bash, mở một cửa sổ tại thư mục đó và chạy (keytool có trong thư mục `jbr\bin` của Android Studio):
   ```bash
   keytool -genkeypair -v -keystore vigon-upload.jks -alias vigon -keyalg RSA -keysize 2048 -validity 10000
   ```
   Keytool sẽ hỏi mật khẩu và thông tin; tự đặt và tự nhớ. Cho Play App Signing: khóa này là **khóa tải lên (upload key)**, Google giữ khóa ký thật.
2. **Sao lưu ngay** file `vigon-upload.jks` và mật khẩu sang ít nhất một nơi khác ổ D (USB, kho mật khẩu). Mất khóa tải lên thì phải xin Google đặt lại, mất nhiều ngày.
3. Tạo file `android/key.properties` (đã nằm trong `.gitignore`, không bao giờ commit) với nội dung, thay bằng giá trị của bạn:
   ```
   storePassword=<mật khẩu kho khóa>
   keyPassword=<mật khẩu khóa>
   keyAlias=vigon
   storeFile=D:/Keys/vigon/vigon-upload.jks
   ```
4. Build bản phát hành: `flutter build appbundle` → file ở `build/app/outputs/bundle/release/app-release.aab`.
5. Kiểm: `flutter build apk --release` rồi `apksigner verify --print-certs` phải hiện tên chủ khóa của bạn, KHÔNG phải "Android Debug".

Nơi cất keystore (NGOÀI repo, có sao lưu): **người dùng điền sau khi tạo:** `____________` · Nơi sao lưu: `____________`
Người giữ mật khẩu: người dùng. KHÔNG ghi mật khẩu vào file này.

Lưu ý: nhánh "có khóa" trong `build.gradle.kts` CHƯA được chạy thử với khóa thật. Nếu bước 4 hoặc 5 lỗi, báo lại để sửa cấu hình.

## Ký ứng dụng và tải lên — iOS (GitHub Actions)
**Trạng thái: CHƯA có tài khoản Apple Developer.** Workflow do phiên nền iOS + CI chuẩn bị, **chưa chạy thật**:
- `.github/workflows/ios.yml`: build simulator không ký + test trên `macos-26` (chạy theo push).
- `.github/workflows/release-ios.yml`: **chạy tay** (Actions → Release iOS → Run workflow) → cài chứng chỉ + profile vào keychain tạm →
  `xcodebuild archive` ký thủ công → xuất `.ipa` → tải lên App Store Connect (TestFlight) bằng API key. Chi tiết và tên secret ở đầu file đó.

Việc của **người dùng** (Claude không tạo, không giữ chứng chỉ/khóa; không nhập mật khẩu):
1. Đăng ký **Apple Developer Program** dạng **cá nhân** (99 USD/năm) bằng Apple ID có bật xác thực hai lớp. Duyệt có thể mất 1–2 ngày.
2. developer.apple.com → Certificates, Identifiers & Profiles:
   - **Identifiers** → App ID `com.phiotron.vigon` (không cần capability nào).
   - **Certificates** → "Apple Distribution": tạo CSR (cần máy Mac, hoặc tạo bằng `openssl` trên Windows rồi ghép `.p12`), tải về, xuất `.p12` có mật khẩu.
   - **Profiles** → "App Store Connect" cho `com.phiotron.vigon` dùng chứng chỉ trên → tải `.mobileprovision`.
3. App Store Connect → Users and Access → Integrations → **App Store Connect API** → tạo key vai trò **App Manager** → ghi Key ID,
   Issuer ID, tải `AuthKey_XXXX.p8` (chỉ tải được một lần).
4. App Store Connect → Apps → "+" → New App: iOS, tên `Ví Gọn: Expense Tracker`, ngôn ngữ chính English (U.S.), Bundle ID trên, SKU `vigon-ios-1`.
5. GitHub repo `phiotron/vigon` → Settings → Secrets and variables → Actions → thêm 7 secret: `IOS_TEAM_ID`, `IOS_DIST_CERT_P12_BASE64`,
   `IOS_DIST_CERT_PASSWORD`, `IOS_PROFILE_BASE64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` (base64 của file tương ứng).
6. Cất `.p12`, `.p8`, `.mobileprovision` và mật khẩu NGOÀI repo (ví dụ `D:\Keys\vigon-ios\`) + một bản sao lưu. `.gitignore` đã chặn `*.p12`, `*.mobileprovision`.
7. Chạy "Release iOS" → build xuất hiện trong TestFlight sau khi Apple xử lý (vài phút tới vài giờ). Lỗi → gửi log `ci-logs/` cho phiên điều phối.

Nơi cất chứng chỉ iOS: **người dùng điền:** `____________` · Hạn chứng chỉ Distribution (1 năm): `____________`
Không có iPhone → không thử được TestFlight trên máy thật; App Review vẫn chạy trên máy của Apple. Mượn được iPhone thì thêm làm tester nội bộ.

## Khai báo mã hoá cho Pháp (ANSSI) — việc của người dùng (D-020)
**Vì sao:** Ví Gọn tự cài AES-256-GCM (không lấy từ iOS) và bán ở Pháp ngay bản 1 → Apple yêu cầu tải **khai báo mã hoá của Pháp**
lên App Store Connect trước khi gửi duyệt. Ở Pháp, *dùng* mã hoá là tự do, nhưng *cung cấp* (fourniture) một "moyen de cryptologie"
tại Pháp phải khai báo với ANSSI, và nghĩa vụ thuộc về **người cung cấp** — ở đây là người đứng tên tài khoản Apple Developer cá nhân.
Claude chỉ chuẩn bị nội dung; **không** tạo tài khoản, không điền, không nộp thay.

**Thời gian — bắt đầu ngay, không đợi build iOS:** ANSSI có **1 tháng** kể từ khi hồ sơ **đủ**; thiếu giấy tờ thì ANSSI đòi bổ sung và
thời hạn tính lại từ lúc nhận đủ; hết 1 tháng mà ANSSI im lặng thì người khai được tiến hành (Nghị định 2007-663). Sau đó Apple duyệt
tài liệu khoảng **2 ngày làm việc**. Dự trù **≥ 6 tuần** trước ngày định nộp iOS.

**Các bước:**
1. Mở biểu mẫu "Déclaration relative à un moyen de cryptologie" trên demarche.numerique.gouv.fr (link ở mục Nguồn). Không phải cư dân
   Pháp → không dùng FranceConnect; chọn **"Create an account"** bằng email rồi đăng nhập. Biểu mẫu tiếng Pháp, trang ước ~28 phút điền;
   trang ghi biểu mẫu đang được phát triển, có thể chập chờn.
2. Tải và đọc **notice** (PDF hướng dẫn của thủ tục, ngay trên trang đó) trước khi điền.
3. Thao tác khai: **Fourniture** (cung cấp tại Pháp — app phát hành qua App Store tới người dùng ở Pháp). Phân loại "grand public" chỉ
   để xuất khẩu tự do *từ* Pháp, không bắt buộc cho việc này. Nếu biểu mẫu hỏi điều khác (ví dụ importation) mà không chắc → hỏi
   ANSSI qua email `controle@ssi.gouv.fr` hoặc luật sư, không đoán.
4. **Giấy tờ đính kèm** (danh sách của trang biểu mẫu; Ví Gọn là cá nhân nên nộp bản tương đương):
   | ANSSI yêu cầu | Ví Gọn nộp |
   |---|---|
   | Document général présentant la société | 1 trang giới thiệu nhà phát triển **cá nhân**: họ tên, địa chỉ, email, tài khoản Apple Developer cá nhân, app duy nhất là Ví Gọn |
   | Extrait K bis < 3 tháng (hoặc giấy tương đương cho đơn vị nước ngoài) | Cá nhân không đăng ký kinh doanh: ghi rõ điều này trong trang giới thiệu; kèm giấy tờ tuỳ thân nếu biểu mẫu đòi. Hệ thống không cho nộp thiếu → email ANSSI hỏi trước |
   | Brochure commerciale | Mô tả App Store bản English + 2–3 ảnh chụp (`store/app-store.md`, `store/screenshots/`) |
   | Brochure technique | Tờ kỹ thuật 1–2 trang, nội dung ở bước 5 |
   | Manuel utilisateur / guide administrateur (nếu có) | Không bắt buộc; có thể đính trang Support |
5. **Tờ kỹ thuật** (đúng code 2026-11-05; code đổi thì sửa lại):
   - Sản phẩm: Ví Gọn, app iPhone (bundle `com.phiotron.vigon`, bản 1.0.0), sổ thu chi cá nhân, miễn phí, chạy offline, không máy chủ,
     không truyền dữ liệu qua mạng.
   - Chức năng mã hoá **duy nhất**: mã hoá tuỳ chọn file sao lưu do người dùng tự xuất (bảo mật dữ liệu lưu trữ). Không mã hoá truyền
     thông, không nhắn tin, không VPN.
   - Thuật toán: **AES-256-GCM** (khoá 256 bit, nonce 12 byte); khoá suy ra từ mật khẩu người dùng bằng **PBKDF2-HMAC-SHA256**,
     100.000 vòng, muối ngẫu nhiên 16 byte (`lib/src/data/backup_crypto.dart`). Không lưu mật khẩu hay khoá; không có khoá dự phòng.
     Người dùng không đổi được thuật toán hay độ dài khoá.
   - Thư viện: gói Dart `cryptography` 2.9.0 (Apache-2.0), cài bằng Dart, không dùng mã hoá của iOS. Băm mã PIN chỉ để xác thực, không mã hoá dữ liệu.
6. Nộp, ghi lại **số hồ sơ**. Theo dõi email của demarche.numerique / ANSSI, trả lời yêu cầu bổ sung sớm (thời hạn tính lại từ lúc đủ).
7. Khi ANSSI xác nhận (biên nhận / accusé de réception): tải PDF bản khai từ hồ sơ + văn bản xác nhận, gộp thành **một PDF**. Hết 1 tháng
   mà không có văn bản nào → email ANSSI xin xác nhận trước khi tải lên Apple (Apple cần thấy giấy tờ).
8. App Store Connect → Apps → Ví Gọn → **App Information** → **App Encryption Documentation** → "+" → trả lời bảng hỏi như
   `store/app-store.md` mục Export compliance → **Choose File** (PDF ở bước 7) → **Save**. Điền Description và Availability (có Pháp)
   **trước** bước này — Apple cần hai thông tin đó để xét tài liệu.
9. Apple duyệt xong → chép **giá trị khoá** hiện cạnh tài liệu → gửi phiên điều phối để phiên code thêm `ITSEncryptionExportComplianceCode`
   vào `ios/Runner/Info.plist` rồi build lại.
10. Ghi ngày nộp ANSSI, số hồ sơ, ngày xác nhận, ngày Apple duyệt vào COMPLIANCE P-03. Giấy tờ tuỳ thân và PDF hồ sơ cất **ngoài repo**
    (ví dụ `D:\Keys\vigon-legal\`), không commit.
11. Thêm hoặc đổi chức năng mã hoá sau này (mã hoá DB, đồng bộ mạng, thuật toán khác) → có thể phải khai lại với ANSSI và Apple; xem lại trước bản đó.

**Nguồn (đọc 2026-11-05):**
- ANSSI — [Contrôle relatif à un moyen de cryptologie](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/) (dùng tự do; cung cấp/nhập/xuất phải khai; nộp trên demarche.numerique)
- ANSSI — [Démarches à accomplir](https://cyber.gouv.fr/reglementation/reglementation-identite-confiance-numerique/controles-reglementaires-cryptographie/controle-moyen-de-cryptologie/controle-rglementaire-cryptographie-demarches/) (fourniture en France → déclaration; "grand public")
- ANSSI — [Les formulaires](https://cyber.gouv.fr/controle-reglementaire-sur-la-cryptographie-les-formulaires) → [biểu mẫu trên demarche.numerique.gouv.fr](https://demarche.numerique.gouv.fr/commencer/declaration-relative-a-un-moyen-de-cryptologie) (danh sách giấy tờ, notice PDF)
- [Nghị định 2007-663 trên Légifrance](https://www.legifrance.gouv.fr/loda/id/JORFTEXT000000646995) (thời hạn 1 tháng; trang chặn trình duyệt tự động nên thời hạn lấy từ kết quả tìm kiếm trích văn bản — người dùng đọc lại bản hiện hành)
- Liên hệ ANSSI: [trang Contact](https://cyber.gouv.fr/contact-acces/contact/) (hộp thư cho thủ tục quy định về sản phẩm mật mã theo Nghị định 2007-663: `controle@ssi.gouv.fr`, kiểm 2026-11-05)
- Apple — [Export compliance documentation for encryption](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/), [Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance), [Determine and upload app encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation)

## Hồ sơ store
| Store | File nội dung | Trạng thái |
|---|---|---|
| Google Play | `store/listing.md` (tên, mô tả vi/en, App content, Data safety, lưu ý tài khoản cá nhân) | Nháp xong 2026-11-04, chờ người dùng duyệt |
| App Store | `store/app-store.md` (tên, subtitle, keywords, mô tả vi/en, age rating, App Privacy, export compliance, Review Notes) | Nháp xong 2026-11-04, chờ người dùng duyệt |
| Closed test Play | `store/closed-test-plan.md` (12+ tester × 14 ngày, lịch, mẫu tin nhắn, form production) | Chờ người dùng mở tài khoản Play |
| Ảnh chụp | `store/screenshots-spec.md` (Play 1080×2160, iPhone 6.9" 1320×2868, kịch bản dữ liệu mẫu) | Chụp ở phiên #3 với UI mới; ảnh cũ `store/screenshots/` chỉ tham khảo |
- Tên: `Ví Gọn: Ghi Thu Chi` (vi) / `Ví Gọn: Expense Tracker` (en); tên dưới icon `Ví Gọn`. Tra trùng web 2026-11-04: chưa thấy trùng.
- Icon: Play 512×512 có (`store/brand/icon-512.png`). App Store 1024×1024: **có** (`AppIcon` vẽ từ vector logo bằng `tool/render_ios_icon.py`, RGB không alpha, gộp từ PLAN-001).
  Ảnh bìa Play 1024×500: CHƯA có PNG (xuất từ canvas Design, `store/brand/README.md`).
- Phân loại: Finance (phụ: Productivity trên App Store); Play target audience 13+; App Store age rating dự kiến 4+.
- Data safety / App Privacy: "không thu thập, không chia sẻ" / "Data Not Collected" (khớp `docs/SECURITY.md`, SBOM, `PrivacyInfo.xcprivacy`).
- Đường dẫn chính sách quyền riêng tư: **CHƯA có**. Nội dung ở `docs/legal/privacy-policy.md` (vi/en, Android + iOS); người dùng đăng
  (Google Sites khuyên dùng) rồi điền vào `lib/src/app_info.dart` (`AppInfo.privacyPolicyUrl`), Play Console, App Store Connect.
- Support URL (App Store bắt buộc): **CHƯA có** — trang "support" cùng site với chính sách.
- Email liên hệ nhà phát triển: `phamphuongphuong@gmail.com` (đã in trong app và chính sách; hiện công khai trên cả hai store).

## Điều kiện chặn phát hành (còn lại, 2026-11-04; iOS cập nhật 2026-11-05 theo D-020, D-021)
Chung:
- [ ] Đường dẫn chính sách quyền riêng tư công khai + Support URL; điền `AppInfo.privacyPolicyUrl` (App Review 2.1/5.1.1 sẽ bấm thử)
- [ ] Người dùng duyệt tên + mô tả hai store; tra trùng nhãn hiệu logo và tên (WIPO, Cục SHTT)
- [ ] Ảnh chụp mới hai nền tảng theo `store/screenshots-spec.md` (phiên #3)
- [ ] Thử TalkBack thật và cỡ chữ lớn nhất (AC-38, AC-39); mở CSV bằng Excel; VoiceOver (khi có máy hoặc trên simulator)
- [ ] Người dùng quyết: Play Age Signals / Declared Age Range (D-12); luật sư xác nhận CRA (S-06), DPIA ở Việt Nam (D-07), D-09
- [ ] COMPLIANCE.md còn dòng "chưa" và kiểm lại hạn chót Apple/Google trong ngày nộp
- [ ] Người dùng duyệt rõ ràng trước khi nộp; Claude chỉ chuẩn bị, KHÔNG nộp store
Android:
- [ ] Khóa ký phát hành (mục trên); xuất PNG ảnh bìa 1024×500
- [ ] Closed test ≥ 12 người trong 14 ngày liên tục (P-09) → xin production (`store/closed-test-plan.md`)
- [ ] Điền App content + Data safety trong Play Console (P-10); ghi chú phát hành vi/en ở `store/listing.md`
- [ ] Thử trên máy Android thật các tính năng 1.2 trước khi production (M-1..M-7 `docs/TESTING.md`): thông báo nhắc + hộp thoại quyền, widget, sao lưu tự động vào thư mục Drive — nhờ tester closed test thử cùng
iOS:
- [ ] Tài khoản Apple Developer cá nhân, App ID, chứng chỉ, profile, API key, 7 GitHub Secrets (mục trên)
- [ ] Chạy "Release iOS" thành công một lần; xác nhận Xcode 26+ trong log (P-01)
- [x] Icon App Store 1024×1024 gốc: có sau gộp PLAN-001 (kiểm header PNG 2026-11-05)
- [x] Quyết export compliance: khoá `true`, bảng hỏi "Standard encryption algorithms…", vẫn bán ở Pháp (D-020, 2026-11-05)
- [ ] `ITSAppUsesNonExemptEncryption = true` trên `main` + test + plutil `ios.yml` (đã commit `8441b6a`) — còn: CI iOS xanh
- [ ] **Người dùng:** nộp khai báo mã hoá cho ANSSI và có xác nhận (mục "Khai báo mã hoá cho Pháp" — nộp ngay, chờ ~1 tháng)
- [ ] **Người dùng:** tải khai báo lên App Store Connect (App Encryption Documentation), Apple duyệt; phiên code thêm `ITSEncryptionExportComplianceCode` vào `Info.plist` — phải xong TRƯỚC khi gửi App Review / TestFlight App Review
- [ ] Điền App Privacy, Age Rating, Review Notes, trader status (EU) trong App Store Connect (`store/app-store.md`)
- [x] Quyết sao lưu iCloud: loại DB khỏi sao lưu hệ thống, giống Android (D-021, 2026-11-05)
- [ ] Code loại DB khỏi sao lưu (đã commit `8441b6a`) — còn: CI iOS xanh với bước kiểm log `VigonBackupExclusion`; chỉ đăng chính sách bản D-021 khi mục này xong
- [x] Xoá PIN còn sót trong Keychain khi cài lại: đã có trong code (D-017, `PinService.clearIfReinstalled`); CHƯA kiểm chứng trên iPhone thật (COMPLIANCE mục 4)

## Lịch sử phát hành
| Phiên bản | Ngày | Nội dung | Ghi chú |
|-----------|------|----------|---------|
| (chưa có) | | | |

## Sau phát hành
- Theo dõi crash: Android vitals trong Google Play Console; iOS: App Store Connect → TestFlight/App Analytics → Crashes và Xcode Organizer
  (chỉ có từ người dùng đồng ý chia sẻ dữ liệu với nhà phát triển). App không có SDK báo crash (D-002).
- Nơi nhận phản hồi: đánh giá trên Google Play và App Store, email `phamphuongphuong@gmail.com`
- Mốc rà soát: sau 1 ngày, 1 tuần → ghi kết quả vào `notes/`; mục tiêu không crash ≥ 99,5%
- Chứng chỉ Apple Distribution hết hạn sau 1 năm, thành viên Apple Developer phải gia hạn hằng năm (hết hạn thì app bị gỡ khỏi App Store).
