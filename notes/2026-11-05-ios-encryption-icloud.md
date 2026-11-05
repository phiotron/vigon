# [A002-vigon] iOS: mã hoá true + loại DB khỏi iCloud · 2026-11-05

Phiên con của phiên điều phối #1. Quyết định người dùng 2026-11-05: (1) `ITSAppUsesNonExemptEncryption = true`
(F-21 AES-256-GCM; người dùng tự nộp khai báo Pháp); (2) loại cơ sở dữ liệu khỏi sao lưu iCloud/máy tính
cho giống Android `allowBackup=false`.

## Đã làm / file đổi
- `ios/Runner/Info.plist`: `ITSAppUsesNonExemptEncryption` → `<true/>`.
- `ios/Runner/AppDelegate.swift`: thêm kênh `vigon/backup_exclusion` (`BackupExclusionChannel`, đăng ký trong
  `didInitializeImplicitFlutterEngine` qua `registrar(forPlugin: "VigonBackupExclusion")`). Method
  `excludeFromBackup {paths: [String]}` đặt `URLResourceValues.isExcludedFromBackup = true` cho từng đường dẫn
  **đang tồn tại**, đọc lại để xác nhận, trả số mục đã đặt; lỗi từng mục chỉ ghi `NSLog("VigonBackupExclusion: …")`.
  Không thêm file vào project.pbxproj, không dependency mới.
- `lib/src/data/device_backup_exclusion.dart` (mới): `DeviceBackupExclusion.excludeDatabase()` — chỉ chạy trên iOS,
  gửi `[<Documents>, vigon.sqlite, -wal, -shm, -journal]`. Gửi cả thư mục Documents (drift đặt DB ở đó và app không
  để gì khác) để file `-journal` sinh ra giữa giao dịch cũng không vào bản sao lưu. **Không bao giờ ném lỗi**
  (MissingPlugin/PlatformException/path_provider → log + trả 0).
- `lib/src/data/database.dart`: `AppDatabase([executor, afterOpen])`; khi dùng file mặc định (executor null) thì
  `afterOpen` = loại khỏi sao lưu. Gọi trong `beforeOpen` (sau `PRAGMA foreign_keys`) **không chờ** (`unawaited` +
  `catchError`) → kênh lỗi/treo không làm chậm hay hỏng việc mở app. Chạy mỗi lần mở app (file bị thay/ tạo lại vẫn
  được đặt lại cờ). Vị trí DB **không đổi** → không cần di chuyển dữ liệu. Hằng `databaseName = 'vigon'`.
- `.github/workflows/ios.yml`: kiểm plist đổi sang `"true"`; bước "Cài + mở app" thêm kiểm trên simulator: liệt kê
  `Documents/`, đọc log hệ thống, bắt buộc có `VigonBackupExclusion: excluded=≥2 failed=0`.
- Test: `test/data/device_backup_exclusion_test.dart` (mới, 10 test: đường dẫn, gọi kênh giả, Android không gọi,
  PlatformException/MissingPlugin/lỗi thư mục không ném, AppDatabase gọi afterOpen đúng 1 lần, afterOpen lỗi/treo không
  hỏng việc mở, DB bộ nhớ không gọi kênh, kịch bản khôi phục iCloud D-017); `test/plan001_t6_ios_config_test.dart`
  (plist `<true/>`, kiểm AppDelegate có kênh, kiểm ios.yml).
- Android: không đổi.

## Keychain PIN (D-017)
Code không chạm Keychain. `flutter_secure_storage` mặc định `kSecAttrAccessibleWhenUnlocked` (không phải
`ThisDeviceOnly`) → Keychain VẪN theo bản sao lưu iCloud/mã hoá sang máy mới, còn DB thì không nữa. Khi đó máy mới
= "cài lại": `PinService.clearIfReinstalled` thấy mã cài đặt trong Keychain không khớp settings của DB mới → xoá PIN,
người dùng không bị khoá ngoài một ví trống (test mới + `plan001_t6_pin_reinstall_test.dart` đều đạt).
Ngoại lệ đã biết: PIN đặt trước D-017 (không có mã) sẽ giữ → khoá ví trống; chưa có bản iOS phát hành nên không ai gặp.
**Hệ quả với người dùng:** chuyển iPhone bằng iCloud/máy tính sẽ KHÔNG mang dữ liệu Ví Gọn theo (cũng như PIN bị xoá);
phải dùng file `.vigon` (F-21/F-24). D-017 "PIN vẫn giữ khi chuyển máy" không còn đúng — phiên điều phối cập nhật
`docs/DECISIONS.md` + chính sách/listing (phiên này không sửa `docs/`, `store/`).

## Kiểm tra
- `flutter analyze`: sạch.
- `flutter test`: **364 test đạt** (All tests passed), gồm 10 test mới + 2 test cấu hình iOS mới.
- `flutter build apk --release`: đạt (app-release.apk 65.0MB).
- Commit `8441b6a` trên `main`. CI Android xanh: https://github.com/phiotron/vigon/actions/runs/41956213357 · CI iOS xanh: https://github.com/phiotron/vigon/actions/runs/41956213343 (plist `true`, build simulator + release không ký, mở app trên simulator). Artifact `ios-simulator-logs/backup-exclusion.txt`: `VigonBackupExclusion: excluded=3 failed=0` (Documents + vigon.sqlite + 1 file kèm); `documents.txt`: Documents chỉ có `vigon.sqlite`.

## Chỉ kiểm được trên iPhone thật
- iCloud Backup/Finder thật sự bỏ `vigon.sqlite` (Cài đặt › iCloud › Quản lý dung lượng › Sao lưu › Ví Gọn gần 0;
  khôi phục sang máy khác → ví trống, PIN bị xoá).
- Keychain đi theo bản sao lưu đúng như trên.
CI simulator chỉ chứng minh cờ được đặt và đọc lại thấy bật.

## Việc dở / rủi ro
- Docs cần cập nhật (ngoài phạm vi): D-017 hệ quả, COMPLIANCE/khai báo xuất khẩu (`true`), chính sách quyền riêng tư
  & mô tả store nói rõ "không vào sao lưu iCloud — hãy dùng file .vigon", note chung `A002-ios-ci-facts.md` còn ghi `false`.
- Cờ đặt sau khi mở DB lần đầu; nếu iOS sao lưu đúng trong vài mili-giây giữa tạo file và đặt cờ ở lần mở đầu tiên
  thì có thể vào một bản sao lưu (DB mới chỉ có dữ liệu mẫu) — chấp nhận.
- Excluding cả thư mục Documents: tính năng sau này ghi file vào Documents cũng sẽ không được sao lưu (khớp Android).

## Đề xuất cải tiến xưởng
- Mẫu "kênh nền tảng iOS nhỏ" đặt thẳng trong `AppDelegate.swift` + dòng `NSLog` có tiền tố, CI đọc log simulator để
  khẳng định — cách kiểm phần native iOS khi không có Mac. Nên đưa vào playbook/template iOS.
- Quyết định "loại khỏi sao lưu hệ thống" nên là mục checklist chung cho app offline (Android `allowBackup` ↔ iOS
  `isExcludedFromBackup`) và luôn kéo theo xét lại Keychain/secure storage.
