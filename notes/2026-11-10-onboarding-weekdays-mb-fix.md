# [A002-vigon] Màn chào · Lặp theo thứ · Sửa đọc email MB — 2026-11-10

> Phiên #4 tiếp (làm trực tiếp, không phiên con). Grill bằng popup rồi làm; kế hoạch đã duyệt.

## Quyết định người dùng chốt
| # | Quyết định |
|---|---|
| O1 | Màn chào 5 bước: Ngôn ngữ → Chào mừng → Tiền tệ chính → Nhắc ghi sổ → Khoá PIN |
| O2 | "Bỏ qua" → vào app ngay; phần chưa chọn = mặc định (English, USD, Nhắc tắt không xin quyền, không PIN) |
| O3 | Chỉ khi cài mới (không sau nâng cấp, Xóa toàn bộ dữ liệu, Khôi phục) → D-041 |
| O4 | Chọn tiền tệ → tài khoản Tiền mặt đổi theo |
| R1 | Lặp lại thêm "Chọn thứ…" (7 chip); đủ 7 = Hằng ngày |
| R2 | Ngày khoản không thuộc thứ đã chọn → **không lưu khoản hôm nay** → D-040 |
| R3 | Dòng "Khoản đầu: T6 6/11" trên màn nhập + thanh báo sau Lưu |
| R4 | Sửa chuỗi có sẵn sang "Chọn thứ" được |
| E1 | Claude tự vào điện thoại (adb) xem, không gửi email/tin nhắn |
| E2 | Sửa xong không đọc lại thư cũ, chỉ thư mới |

## Email MB — nguyên nhân và cách sửa
- Lấy thư gốc bằng **bản build chẩn đoán tạm** (đã gỡ, không commit): app tải lại thư MB từ ngày kết nối, không gọi bộ đọc,
  không đổi UID, ghi HTML ra `Android/data/com.phiotron.vigon/files/diag/`; `adb pull` về scratchpad rồi **xoá trên máy và máy tính**.
- 6 thư thật (06–09/11), cùng một dạng: chỉ `text/html` kiểu Outlook/Word, mỗi ô bọc `<p class=MsoNormal>`, chữ có dấu là thực thể
  `&#7883;`, và **nhãn ngắt dòng trong mã nguồn** (`Ng&#224;y,⏎  gi&#7901; giao d&#7883;ch`). `htmlToText` cũ giữ xuống dòng
  của mã nguồn → nhãn bị cắt đôi → mọi thư "không đọc được".
- Sửa: `htmlToText` gộp mọi khoảng trắng của mã nguồn thành một dấu cách trước khi đổi thẻ khối thành xuống dòng; thêm `&ndash;`/`&mdash;`.
  Cả 6 thư thật đọc đúng (ngày giờ, VND, số tiền, 4 số cuối). Mẫu đã che: `test/import/samples/mb/real_outlook_2026-11-09.html`.
- Địa chỉ gửi xác nhận `mbebanking@mbbank.com.vn`. Kiểm trên máy với thư mới: chờ người dùng có giao dịch MB mới.

## Lặp theo thứ
- `lib/src/data/repeat.dart` (`Repeat`: tần suất + bitmask thứ, `occurrences`, `firstOn`); schema **v6** cột `recurring_rules.weekdays`.
- `RecurringRepository.addWithRepeat(..., weekdays:)` có thể không chèn khoản (D-040); `edit(..., weekdays:)`.
- UI: `features/recurring/repeat_picker.dart` (bảng Lặp lại + bảng 7 chip), màn nhập, bảng sửa chuỗi, danh sách chuỗi.

## Màn chào
- `features/onboarding/onboarding_screen.dart`; cờ `onboardingPending` chỉ ghi ở `onCreate`; route `/onboarding` + `redirect`
  theo `ValueNotifier` (`createRouter(onboarding:)`, `VigonApp(onboardingGate:)`); `_OnboardingCurtain` che app khi chưa biết cờ.
- Chưa thử trên máy thật: phải xoá dữ liệu (máy đang giữ dữ liệu mẫu chụp store) → cần người dùng cho phép, hoặc thử khi cài máy khác.

## Test mới
`test/data/recurring_weekdays_test.dart`, `test/features/repeat_days_test.dart`, `test/features/onboarding_test.dart`,
nhóm "thư MB thật" trong `test/import/mb/mb_receipt_parser_test.dart`.

## Bài học
- **Thêm cột vào `recurring_rules`/`entries` phải thêm luôn vào `newColumns` của bước dựng lại bảng `from < 3`** trong
  `database.dart` — quên thì nâng cấp từ schema 1–2 lỗi "no such column" (test migration 1→ và 2→ bắt được).
- Cờ màn chào có trong mọi DB mới → test so ảnh chụp sao lưu phải cho máy nguồn "đã qua màn chào" (`finishOnboarding`).
- `dart format lib test` định dạng lại cả file không liên quan → chỉ format file mình sửa.
- Bash heredoc trong môi trường này làm hỏng `\t`/`\n` trong chuỗi Python → viết script ra file bằng Write rồi chạy.
