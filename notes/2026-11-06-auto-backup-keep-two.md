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
- CHƯA kiểm tay trên máy: M-2 (a) có thêm khoản → `adb logcat -s VigonBackup` thấy `result=ok`, thư mục còn 2 file; (b) không đổi dữ liệu →
  `result=null`, Cài đặt hiện dòng "Đã kiểm…".

## Ghi chú
- Lịch Android là báo thức KHÔNG chính xác: lần này trễ 19 s, nhưng Doze/tiết kiệm pin có thể lùi vài phút tới hơn 10 phút.
