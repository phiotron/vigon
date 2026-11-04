# [A002-vigon] Store & pháp lý 2 nền tảng — báo cáo phiên con

Phiên điều phối #1 · 2026-11-04 · Phiên con C. Không dùng subagent, không đổi nhánh, không push, không đăng/nộp gì.

## Đã làm / file đã đổi
| File | Việc |
|---|---|
| `store/app-store.md` (mới) | Listing App Store EN + VI: tên, subtitle, keywords (đã đếm ký tự), promotional text, mô tả, What's New (ghi rõ 1.0 không nhập được), category, phân phối (trừ TQ đại lục, Nga), age rating (bảng hỏi mới → 4+), App Privacy "Data Not Collected" + lý do, export compliance, URL bắt buộc, Review Notes, trader status EU, tra trùng tên |
| `store/listing.md` | Thống nhất với App Store: tên `Ví Gọn: Ghi Thu Chi` / `Ví Gọn: Expense Tracker` (bỏ Neat/Tidy Wallet), thêm bảng App content (ads, app access, IARC, target audience, financial features…), Data safety theo thứ tự form, mục "tài khoản cá nhân", ảnh chụp trỏ sang spec |
| `store/closed-test-plan.md` (mới) | Luật 12 tester × 14 ngày, đường găng, lịch 04/11 → ≈05/12, mời qua Google Group / email list, mẫu tin mời/nhắc vi/en, nhật ký, câu trả lời mẫu form production (chỗ số liệu để `[...]`, không bịa) |
| `store/screenshots-spec.md` (mới) | Kích thước/số lượng Play + iPhone 6.9" (không cần iPad), 8 ảnh với chú thích vi/en, kịch bản dữ liệu mẫu VND/USD (tổng đã cộng khớp), cách chụp (A13/emulator, simulator CI), chụp ở phiên #3 |
| `store/brand/README.md` | Ghi thiếu icon App Store 1024 gốc |
| `docs/legal/privacy-policy.md` | Thêm iPhone (vi/en): Keychain cho PIN (không iCloud Keychain, có thể còn sau khi gỡ), **dữ liệu có trong sao lưu iCloud/máy tính** (đúng với code), share sheet + thư mục tạm, trình chọn file; ghi chú nội bộ: bằng chứng code, nơi đăng (Google Sites / repo public cho GitHub Pages), chỗ điền URL |
| `docs/COMPLIANCE.md` | Sửa D-02, D-11, D-12, A-01, P-01..P-05, P-09, P-10 (P-03 → **đạt**, P-04 không áp dụng vì không tracking); phạm vi: 2 nền tảng, tài khoản cá nhân; thêm mục 4 "iOS / App Store — App Review" |
| `docs/RELEASE.md` | Thêm iOS: định danh, các bước ký qua `release-ios.yml` (7 secret do phiên CI đặt tên), bảng hồ sơ store, điều kiện chặn tách Chung/Android/iOS, theo dõi sau phát hành iOS |

## Kiểm tra thế nào
- Đọc code trước khi viết chính sách: `lib/src/data/database.dart` (`driftDatabase(name: 'vigon')`), pub cache `drift_flutter-0.3.1/lib/src/native.dart` → mặc định `getApplicationDocumentsDirectory()`; `flutter_secure_storage-11.2.0` `apple_options.dart` → `accessibility = unlocked`, `synchronizable = false`; `lib/src/features/settings/data_actions.dart` (thư mục tạm + `SharePlus`, `FilePicker`, xoá dữ liệu gọi `pinService.disable()`); grep `lib/` không có `HttpClient`/`http`/`dio`/WebView; `AndroidManifest.xml` `allowBackup="false"`.
- Đối chiếu `ios/` sau commit `9438ddd` của phiên CI: `TARGETED_DEVICE_FAMILY = 1`, chỉ Portrait, `CFBundleDisplayName = Ví Gọn`, `ITSAppUsesNonExemptEncryption = false`, `PrivacyInfo.xcprivacy` (C617.1, E174.1), không `UIFileSharingEnabled`.
- Nhãn trong chính sách/Review Notes khớp `.arb` ("Xuất bản sao lưu", "Khôi phục từ bản sao lưu", "Khóa bằng mã PIN"/"Lock with PIN", "Quên mã"/"Forgot PIN", "Xóa toàn bộ dữ liệu").
- Đếm ký tự bằng script Python (tên, subtitle, keywords, promo, mô tả ngắn Play) — đều trong giới hạn.
- Web (2026-11-04): không thấy app trùng "Ví Gọn"/"Vi Gon" trên App Store/Play; luật 12×14 của Play còn hiệu lực (Play Console Help); bảng tuổi mới Apple (4+/9+/13+/16+/18+); kích thước 6.9" — các chi tiết ngoài luật chính lấy từ nguồn thứ cấp, đã ghi "kiểm lại ngày nộp".
- Không chạy `flutter analyze/test` (không đổi code).

## Việc người dùng phải làm
1. **Đăng chính sách + trang Support** (Google Sites khuyên dùng), điền tên thật vào `[Tên nhà phát triển]`, ngày hiệu lực; đưa URL cho phiên code điền `AppInfo.privacyPolicyUrl`.
2. **Play Console cá nhân** (25 USD, xác minh danh tính + thiết bị) → tạo keystore → gom **15–20 tester** → bắt đầu closed test sớm theo `store/closed-test-plan.md`.
3. **Apple Developer cá nhân** (99 USD/năm) → App ID, chứng chỉ Distribution `.p12`, profile App Store, API key → 7 GitHub Secrets (`docs/RELEASE.md`).
4. Duyệt tên `Ví Gọn: Ghi Thu Chi` / `Ví Gọn: Expense Tracker` và mô tả hai store; tra nhãn hiệu (WIPO, Cục SHTT).
5. Xuất từ canvas Design: ảnh bìa 1024×500 và **icon 1024×1024 gốc** cho App Store.
6. Quyết: trader status EU (DSA) trên App Store Connect; Play Age Signals / Declared Age Range (D-12); luật sư cho D-07, D-09, S-06.

## Rủi ro App Review / store
- **Cao nếu quên:** liên kết chính sách trong app đang rỗng (nút bị tắt) → 2.1/5.1.1. Phải có URL trước khi nộp cả hai store.
- **Lệch hành vi iOS ↔ Android (cần phiên điều phối quyết, sửa ở `lib/`):**
  (a) DB iOS nằm trong Documents → **vào sao lưu iCloud**; Android tắt sao lưu. Tài liệu hiện mô tả đúng thực tế; muốn đồng nhất "không lên đám mây" thì đặt `NSURLIsExcludedFromBackupKey` cho file DB rồi sửa lại chính sách mục 2 + mô tả App Store.
  (b) **Keychain giữ PIN sau khi gỡ app** → cài lại thì màn khoá đòi PIN cũ dù DB trống (lỗi trải nghiệm, reviewer có thể gặp nếu cài lại). Sửa: DB vừa tạo mới mà còn PIN thì xoá PIN.
- 5.1.1(ix) lĩnh vực tài chính + tài khoản cá nhân: thấp–vừa; app chỉ là sổ ghi chép, Review Notes đã nói rõ.
- 2.4.1: app chỉ iPhone nhưng reviewer có thể mở trên iPad (chế độ tương thích) → thử simulator iPad một lần.
- ITMS-90683 (thiếu chuỗi mô tả quyền) có thể đến nếu plugin `file_picker` liên kết API ảnh — xử lý khi có email sau build đầu.
- Play: form production bị từ chối nếu tester ít tương tác → mời dư, nhắc ngày 3/7/11, đẩy build UI mới vào cùng track.
- VoiceOver chưa thử (không có iPhone); mô tả store đã hạ xuống mức đã kiểm được ("mọi nút có nhãn"), không hứa "tối ưu".
- Đã gửi phiên nền iOS 6 điểm Info.plist/project (trước khi họ commit) — commit `9438ddd` đã có đủ.

## Đề xuất cải tiến xưởng
1. **Template store dùng lại:** tách `store/app-store.md`, `store/listing.md`, `store/closed-test-plan.md`, `store/screenshots-spec.md` thành mẫu trong `playbook/templates/store/` (để trống tên/mô tả, giữ bảng age rating, App content, Data safety, App Privacy, export compliance, mẫu tin tester, form production). App sau chỉ điền.
2. **Checklist `release-ios.md` v0 → v1:** thêm: chỉ iPhone thì `TARGETED_DEVICE_FAMILY = 1`; `ITSAppUsesNonExemptEncryption`; Support URL bắt buộc; trader status EU; What's New không nhập được ở 1.0; icon 1024 gốc; kiểm DB có vào iCloud backup không (Documents vs `NSURLIsExcludedFromBackupKey`); Keychain còn sau khi gỡ app.
3. **Checklist `release-android.md`:** thêm mục "App content" đầy đủ (financial features, health, government…); closed test là **đường găng** cho tài khoản cá nhân → bắt đầu ngay khi có build chạy được, song song với làm UI.
4. **Fact xưởng:** "Flutter + drift_flutter trên iOS lưu DB trong Documents (vào iCloud backup)" và "flutter_secure_storage trên iOS: Keychain còn sau khi gỡ app" — nên vào `memory/facts/` vì app nào cũng gặp.
5. Kịch bản dữ liệu mẫu chụp store nên thành file `.vigon` mẫu commit trong repo (sinh bằng test) để chụp lặp lại được trên cả 2 nền tảng.
