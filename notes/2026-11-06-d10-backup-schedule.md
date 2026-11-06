# [A002-vigon] D10 · Sao lưu tự động theo giờ chọn (D-026) — 2026-11-06

Phiên con của phiên điều phối #2. Commit trên `dev`: `bed9549` (mã + test), commit tài liệu ngay sau, commit ghi chú này.

## Đã làm
- **Cài đặt:** hàng "Giờ sao lưu" (`SettingsNavRow` + `showTimePicker`, giống A14) trong thẻ Sao lưu tự động khi đang bật; bật →
  thư mục → mật khẩu → bộ chọn giờ điền sẵn 21:00 (đóng bộ chọn = giữ 21:00, vẫn bật) → sao lưu ngay → (iOS) xin quyền thông báo.
  Dòng mới dưới trạng thái: "Lần tới: hôm nay/ngày mai, HH:MM"; mốc đã qua mà chưa xử lý: "Lần tới: khi bạn rời Ví Gọn" (Android) /
  "khi bạn mở lại Ví Gọn" (iOS). Giờ lưu trong SecretStore khóa `auto_backup_time` (không vào `settings`, D-014).
- **Luật chạy (`lib/src/data/backup_schedule.dart`, `AutoBackupService.maybeRunIfDue`):** mỗi ngày có một **mốc** lúc giờ chọn theo giờ
  máy; mỗi mốc xử lý tối đa một lần (sao lưu, lỗi, hoặc thấy dữ liệu không đổi → ghi `auto_backup_last_check` để lần ra nền sau không
  xuất lại dữ liệu). Một lần xử lý phủ mọi mốc đã lỡ → máy tắt nhiều ngày chỉ bù một lần. `lastAt` nay lưu UTC (`…Z`), đọc được bản cũ.
- **Android (app đóng):** báo thức KHÔNG chính xác → JobService → FlutterEngine không giao diện → `autoBackupBackgroundMain`
  (`lib/main.dart`) → `runScheduledAutoBackup` (`lib/src/data/auto_backup_background.dart`) dùng chung `AutoBackupService`.
  Kotlin: `android/.../BackupSchedule.kt` (`BackupAlarm`, `BackupAlarmReceiver`, `BackupJobService`); `BackupFolderChannel` có thêm hàm
  dựng không Activity + `dispose()` công khai; `MainActivity` đăng ký kênh `vigon/backup_schedule`; manifest thêm receiver + service
  (`exported="false"`). Không thêm quyền, không thêm gói.
- **iPhone:** thông báo cục bộ lặp hằng ngày đúng giờ chọn, mã 1002 (nhắc ghi chép là 1001), payload `vigon:auto-backup`, chữ
  `autoBackupNotificationBody` "Đến giờ sao lưu Ví Gọn. Chạm để sao lưu." (không số). Chạm → app mở/quay lại → đường bù chạy (thêm cả nghe
  payload). Quyền: kiểm `checkPermissions` (không hỏi); chưa có → hộp giải thích (S-40) → "Tiếp tục" mới gọi hộp thoại iOS; từ chối/Hủy →
  snackbar nhẹ (có "Mở cài đặt" nếu đã thử xin). Dùng chung plugin đã khởi tạo ở `reminderReadyProvider` (không `initialize` lần 2).
- **Bù khi lỡ:** mở app (3 s sau khung hình đầu) và quay lại app: cả hai nền tảng; ra nền: chỉ Android (giữ `maybeRunDaily` trong
  `app_lock.dart`, không sửa file đó). Bỏ kiểu "ra nền là chạy (1 lần/ngày lịch)".
- **Đồng bộ lịch:** `autoBackupScheduleSyncProvider` (giữ sống trong `main.dart`) đặt/hủy lịch khi mở app, bật/tắt, đổi giờ, đổi ngôn ngữ.
- **Chữ (.arb vi+en):** `autoBackupTime`, `autoBackupNextToday`, `autoBackupNextTomorrow`, `autoBackupNextSoon`, `autoBackupNextSoonIos`,
  `autoBackupNotificationBody`, `autoBackupNotifyTitleIos`, `autoBackupNotifyBodyIos`, `autoBackupNotifyDeniedIos`; sửa
  `autoBackupRunsOnOpenIos`.
- **Tài liệu:** SPEC AC-59 + gạch iOS; chính sách VI+EN (mục 3, mục 4 thông báo + tín hiệu khởi động lại, ghi chú nội bộ D-026);
  `store/app-store.md`, `store/listing.md` (đếm lại ký tự: vi 2909, en 3023); TESTING AC-59 + M-2 mới; SECURITY (quyền khởi động, dòng
  dữ liệu giờ sao lưu, dòng rủi ro chạy nền); COMPLIANCE ghi chú iOS.

### File đã đổi
`lib/main.dart`, `lib/src/data/{auto_backup_service,backup_schedule*,auto_backup_background*}.dart`,
`lib/src/features/settings/{auto_backup_section,auto_backup_providers,auto_backup_scheduler*}.dart`,
`lib/src/features/reminder/reminder_scheduler.dart` (tách `ensureLocalTimeZone()` dùng chung), `lib/l10n/*`,
`android/app/src/main/{AndroidManifest.xml, kotlin/.../BackupSchedule.kt*, BackupFolderChannel.kt, MainActivity.kt}`,
`test/data/{backup_schedule_test*,auto_backup_test,hifi_d4_auto_backup_ios_test}.dart`,
`test/features/{auto_backup_schedule_test*,auto_backup_ui_test,hifi_d3_settings_test}.dart`, docs/store như trên. (* = file mới)

## Cách làm Android + lý do
**AlarmManager `setAndAllowWhileIdle` (không chính xác) → `BackupAlarmReceiver` → JobScheduler (expedited trên Android 12+, hết hạn mức
thì job thường hạn 60 s) → `BackupJobService` dựng FlutterEngine không giao diện chạy hàm Dart `autoBackupBackgroundMain`.**
- Không dùng gói `workmanager`: (1) WorkManager chạy trên JobScheduler nên giờ 21:00 dễ bị Doze hoãn tới cửa sổ bảo trì (có thể hàng
  giờ); báo thức allow-while-idle nổ được trong Doze, gần giờ chọn hơn. (2) Gói WorkManager tự thêm `WAKE_LOCK`, `ACCESS_NETWORK_STATE`
  (bị `manifest_test` cấm), `FOREGROUND_SERVICE` vào manifest gộp. (3) Engine nền của plugin không có kênh riêng `vigon/backup_folder`
  (đăng ký trong `MainActivity`) nếu không móc thêm. Cách tự viết: 0 gói mới, 0 quyền mới, ~250 dòng Kotlin.
- Không xin `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (giữ D-015); test cấm `setExact*`/`setAlarmClock`.
- Báo thức nổ → đặt báo thức ngày mai **trước** rồi mới xếp job: Dart lỗi/bị dừng không làm đứt chuỗi.
- Giờ + cờ bật được Kotlin chép vào SharedPreferences riêng (`vigon_auto_backup_schedule`) để receiver đặt lại lịch sau
  `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_SET`, `TIMEZONE_CHANGED` (dùng múi giờ trong intent), QUICKBOOT — không cần chạy Dart.
  Đây chỉ là giờ trong ngày (không bí mật); nguồn gốc vẫn là SecretStore.
- Job tự kết thúc khi Dart báo `done` (kênh `vigon/backup_job`) hoặc sau 9 phút; hệ thống dừng job → không thử lại (đường bù lo).

## Kiểm tra thế nào
- `flutter analyze`: No issues found.
- `flutter test` toàn bộ: **620 đạt** ("01:10 +620: All tests passed!"). Test mới: `test/data/backup_schedule_test.dart` (21: BackupTime,
  lần tới qua nửa đêm/cuối tháng/năm, bù khi lỡ, múi giờ Hà Nội↔Tokyo, DST London, SecretStore, UTC, chạy nền giả),
  `test/features/auto_backup_schedule_test.dart` (10: kênh Android giả, iOS `zonedSchedule` qua kênh plugin giả, chữ không số, provider
  đồng bộ, hợp đồng Kotlin/manifest), thêm 6 widget test trong `auto_backup_ui_test.dart` (bộ chọn giờ, hàng giờ, lần tới, hủy, iOS quyền).
- `flutter build apk --release` (không `--target-platform`): build đạt (66 MB). Lần build đầu hỏng vì `GeneratedPluginRegistrant.java`
  bị bản debug có `integration_test` của D9 ghi đè giữa chừng — chạy lại là đạt, không phải lỗi mã.

## CHƯA kiểm chứng (không dùng máy thật — D9 đang giữ máy)
- Toàn bộ phần chạy nền Android trên máy thật: báo thức nổ khi app đóng, job expedited, FlutterEngine headless mở DB/Keystore/SAF
  (plugin `flutter_secure_storage`, `path_provider`, sqlite3 native asset trong engine nền), thời gian mã hoá 100.000 vòng ở nền,
  đặt lại lịch sau khởi động lại/cập nhật/đổi múi giờ, độ trễ thật. Bước thử: `docs/TESTING.md` M-2 (a)…(g).
- iOS: thông báo thật, hộp quyền thật, chạm thông báo khi app bị tắt hẳn (`launchPayload`) — chỉ TestFlight (phiên #3).
- Hai engine (app đang mở + job nền) cùng chạm DB/SecretStore một lúc: chưa thử; rủi ro thấp (job chỉ đọc DB; trùng thì cùng tên file).

## Việc dở / rủi ro
- **Pin/Doze/hãng máy:** Samsung "Ứng dụng ngủ/ngủ sâu", Xiaomi, Oppo… có thể chặn báo thức hoặc job của app ít dùng → không sao lưu
  đúng giờ; còn đường bù khi mở/rời app. "Buộc dừng" trong cài đặt hệ thống xóa báo thức tới lần mở app kế tiếp (Android quy định).
  Chưa có chữ trong app nói "máy tiết kiệm pin có thể lùi giờ" — đề xuất thêm nếu M-2 thấy lệch nhiều.
- Người dùng cũ (bật trước bản này): giờ mặc định 21:00, nhưng báo thức Android chỉ được đặt sau lần mở app đầu tiên sau cập nhật.
- iOS: thông báo lặp mỗi ngày kể cả khi dữ liệu không đổi hoặc đã sao lưu tay (iOS không cho app tự bỏ một lần). Đổi múi giờ: giờ
  thông báo theo múi giờ mới sau lần mở app kế tiếp (tz nạp một lần mỗi tiến trình).
- **Quyết định nhỏ đã tự chọn (cần phiên chính xác nhận):** "tối đa 1 lần/ngày" hiểu là **mỗi mốc giờ một lần**: bù lúc 8:00 cho mốc
  21:00 hôm qua rồi 21:00 hôm nay vẫn chạy (có thể 2 file trong một ngày lịch). Cách kia (1 lần/ngày lịch) làm mất thay đổi trong ngày
  sau lần bù tới tận tối hôm sau.
- Đổi giờ muộn hơn trong cùng tối (vd 21:00 đã chạy, đổi sang 22:00) tạo mốc mới → có thể thêm một bản nếu dữ liệu đổi.

## Đề xuất cải tiến xưởng
- **Mẫu "việc nền theo giờ" dùng lại được:** báo thức không chính xác + JobService + FlutterEngine headless + receiver đặt lại lịch +
  test hợp đồng đọc mã nguồn Kotlin/manifest. Nên đưa vào `playbook/templates/flutter` cho app sau (nhắc, đồng bộ, dọn dữ liệu…).
- Hàm tính mốc giờ nhận "hàm dựng giờ địa phương" để test múi giờ/DST bằng `timezone` mà không đổi giờ máy — mẫu test tốt, nên ghi vào
  STANDARDS/test guide.
- Va chạm build song song: hai phiên cùng thư mục app chạy `flutter build`/`flutter test` → khoá `sqlite3.dll` và
  `GeneratedPluginRegistrant` bị ghi đè lẫn nhau. Đề xuất WORKFLOW: phiên thử máy dùng worktree riêng, hoặc quy ước lượt build.
