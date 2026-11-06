# [A002-vigon] Sao lưu tự động: giữ 2 file + báo rõ khi bỏ qua (D-027) — 2026-11-06

## Vấn đề người dùng báo
1. Mỗi lần sao lưu tự động thêm một file (giữ 7) → muốn xoá file cũ, chỉ giữ bản mới.
2. Đặt giờ rồi chờ quá 1 phút mà "không sao lưu".

## Chẩn đoán trên máy thật (Samsung A13, `adb`)
- `dumpsys alarm`: báo thức `AUTO_BACKUP_ALARM` nổ 10:05:19 (đặt 10:05) — lịch nền chạy đúng.
- `dumpsys jobscheduler`: `BackupJobService` START rồi `jobFinished` sau ~0,3 s.
- Người dùng xác nhận không thêm/sửa khoản nào → `maybeRunIfDue` bỏ qua vì dữ liệu không đổi (đúng luật D-026),
  nhưng Cài đặt không hiện gì → trông như không chạy.

## Đã làm
- `AutoBackupService.keepFiles` 7 → **2**; `_prune` giữ file vừa ghi + 1 file mới nhất còn lại, xoá phần còn lại (chỉ sau khi ghi xong;
  không giả định file vừa ghi mới nhất theo tên).
- Dòng trạng thái: `autoBackupLastUnchanged` "Lần cuối: … Đã kiểm …: dữ liệu không đổi, giữ bản cũ" khi `lastCheckAt > lastAt`.
- Kotlin `BackupJobService`: `Log.i("VigonBackup", "scheduled backup result=…")` (chỉ tên kết quả).
- Test: đổi test giữ 7 → giữ 2; thêm "ghi lỗi thì file cũ không bị xoá", "đồng hồ lùi vẫn đúng 2 file", widget test dòng "dữ liệu không
  đổi"; test "mỗi mốc giờ tối đa một lần" đếm `folder.writes` thay vì số file.
- Tài liệu: D-027 trong `docs/DECISIONS.md`; "7" → "2" ở SPEC, TESTING, SECURITY, privacy-policy (VI+EN), store (Play + App Store, độ dài
  không đổi), CONTEXT, ui-spec, CHANGELOG. `APP.md` dòng "giữ 7 file" để phiên điều phối sửa.

## Kiểm tra
- `flutter analyze`: No issues found. `flutter test`: **623 đạt**.
- `flutter build apk --release` → `adb install -r` lên Samsung A13: Success (giữ dữ liệu).
### Thử trên máy thật (Samsung A13, Android 14 32-bit armeabi-v7a, thư mục Google Drive "Chi tiêu") — 2026-11-06
- "Sao lưu ngay": thư mục từ 7 file còn 2 (`…1011`, `…1030`). ĐẠT.
- M-2 (a): thêm khoản thử, giờ 10:38, đóng app (`am kill`) → báo thức nổ 10:40:39 (cuối cửa sổ không chính xác), log
  `VigonBackup result=ok` sau ~7 s; Drive còn `…1030` + `…1040`. ĐẠT.
- M-2 (b): giờ 10:46, không đổi dữ liệu → 10:48:09 `result=null`; Cài đặt: "Lần cuối: 6 thg 11, 10:40. Đã kiểm 6 thg 11, 10:48: dữ liệu
  không đổi, giữ bản cũ". ĐẠT. Sao lưu mới sau đó thì dòng "Đã kiểm" tự ẩn.
- Thử thêm (không làm mất dữ liệu): kỳ trước/sau, lọc theo tài khoản, tìm kiếm, sửa khoản + máy tính (1.000+1.000), xóa + Hoàn tác, Tài
  khoản/Định kỳ/Danh mục, hộp Ngân sách (Hủy), đổi English ↔ Tiếng Việt, "Che nội dung" bật/tắt (FLAG_SECURE 0x2000 có/mất đúng), bật nhắc
  khi chưa có quyền (hộp giải thích → hộp hệ thống → từ chối → công tắc vẫn tắt). Không crash/ANR mới (dropbox sạch sau bản cài 09:40).
- Khoản thử đã xóa; giờ sao lưu trả về 21:00; "Sao lưu ngay" lúc 11:11 để bản mới nhất là dữ liệu sạch.

### Phát hiện
- **Thanh ngân sách ở màn chính luôn tính tháng hiện tại** (`budgetSpentProvider` dùng `todayProvider`) kể cả khi đang xem tháng khác:
  xem Tháng 10 (0 ₫) vẫn hiện "Vượt 3.523.179 ₫". Đúng ui-spec (dòng 613) nhưng dễ hiểu nhầm → cần phiên chính quyết định (ẩn khi xem kỳ
  khác, hoặc tính theo kỳ đang xem, hoặc ghi rõ "tháng này").
- Crash `Unsupported value: kotlin.Unit` (05/11 23:11, 06/11 07:28, 08:42) là bản cũ trước khi `runAsync` đổi Unit → null; không tái hiện.
- Crash `libflutter.so` 03/11 là bản build chỉ arm64 trên máy 32-bit — APK hiện tại có armeabi-v7a.
- Quyền thông báo của app nay là `USER_FIXED` (từ chối lần 2 khi thử) → muốn bật nhắc phải vào Cài đặt hệ thống.

### Chưa thử
Widget, khoá PIN, đổi tiền tệ (quy đổi thật), khôi phục, xoá toàn bộ, xuất file/CSV (bộ chọn file), iOS.

## Ghi chú
- Lịch Android là báo thức KHÔNG chính xác: lần này trễ 19 s, nhưng Doze/tiết kiệm pin có thể lùi vài phút tới hơn 10 phút.
