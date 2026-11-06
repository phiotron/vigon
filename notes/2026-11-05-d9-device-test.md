# [A002-vigon] D9 — Thử máy thật Galaxy A13 (2026-11-05) — DỞ (hết hạn mức phiên)

Máy SM-A135F, Android 14, armeabi-v7a; cỡ chữ máy 0,8, **Chữ đậm bật** (`font_weight_adjustment=300`). Bản `dev` @ `ec8846e` + 2 bản sửa dưới (CHƯA commit).

## Kết quả
| Bước | Kết quả |
|---|---|
| H-1 | Đạt: `install -r` giữ dữ liệu mẫu; mở nguội 1551/832/646/780/597 ms (trung vị 780) |
| H-2 | Đạt (vòng, Thu/Chi giữa, Số dư + kỳ). Ô ⋯ nét đứt: không thử (mẫu có 10 danh mục) |
| H-3 | Không thử được: cần > 16 danh mục |
| H-4 | Đạt: số khoản con thẳng mép; ⚠ "Vượt 32.000 ₫" đỏ + thanh (hạn mức tạm 250.000 cho Ăn uống, đã xóa lại). "Hôm nay": không có khoản hôm nay |
| H-5 | Đạt: "pho"→Phở bò tô nền; "500" tô vắt qua dấu chấm; chip chọn một; cuộn ẩn bàn phím; "Không có khoản nào khớp" |
| H-6 | Đạt: 0 → "Số tiền phải lớn hơn 0", không đóng; tiêu đề đứng yên; lưu được; đã trả về trống |
| H-7 | Đạt: đã dùng chỉ "Ẩn" + gợi ý; ẩn Techcombank → "Tài khoản đã ẩn (1)" → Hiện lại (thứ tự như cũ). Tài khoản chưa dùng: không có |
| H-8 | Không thử được: mẫu không có khoản định kỳ |
| H-9 | **Lỗi → đã sửa**: "Thứ Hai" bẻ 2 dòng khi máy bật Chữ đậm. Còn lại đạt |
| H-10 | Widget chưa có trên launcher; thêm widget phải chạm launcher → **người dùng tự thêm**. PIN: chưa thử |
| H-11 | **Lỗi lớn → đã sửa**: bản release không có báo thức (icon `ic_stat_vigon` bị thu gọn tài nguyên xóa → plugin khởi tạo lỗi, bị nuốt). Sau sửa: hộp giải thích trước, đặt 17:31 → thông báo thật 17:32:14 "Ví Gọn"/"Hôm nay bạn đã ghi chi tiêu chưa?", không số; tự đặt lại ngày sau. Hộp quyền hệ thống: không chạm (cấp bằng `pm grant`, đã `pm revoke`); chạm thông báo: người dùng |
| H-12, H-13, Q-0, Q-2, Q-3, Q-5 | Chờ phiên chính (cần chạm bảng chia sẻ/bộ chọn file/Chrome) |
| H-14 | Không thử TalkBack thật (không nghe được qua adb); nhãn qua uiautomator đủ. Gợi ý: icon/màu trong Sửa danh mục chỉ đọc "Biểu tượng 1..31", "Màu 1..16" |
| H-15, Q-6 | Chưa làm (hết hạn mức) |
| H-16 | Đạt (màn chính, Các khoản tối đọc rõ); đã trả về Sáng |
| AC-56 | Đạt: Che nội dung bật → `screencap` rỗng (cờ FLAG_SECURE) |
| Q-1 | Đạt: 1 USD = 25.701,4 VND = đúng open.er-api 05/11; ngày, nguồn, ví dụ 180.000 ₫ → 7,00 $ đúng; Hủy |
| Q-4 | Đạt: lỗi + điền sẵn tỉ giá gần nhất, Đổi chiều, bàn phím số có `.`/`,`, 0 → "Nhập tỉ giá lớn hơn 0", Thử lại không treo, Tiếp tục → "Tỉ giá bạn tự nhập" → Hủy, vẫn VND. Lưu ý: Samsung bật máy bay vẫn giữ Wi-Fi (`wifi_on=2`) → phải tắt Wi-Fi riêng |
| M-1..M-7 | Chưa làm |

## Lỗi + sửa (chưa commit; test riêng đã chạy, CHƯA chạy `flutter analyze` + toàn bộ `flutter test`)
1. Chữ đậm hệ thống: `lib/src/ui/text_measure.dart` (mới, đo có `MediaQuery.boldText`), dùng ở `choice_segments.dart`, `messenger.dart`; test `test/ui/bold_text_measure_test.dart` (4 test, đỏ khi bỏ sửa).
2. Nhắc không chạy bản release: `android/app/src/main/res/raw/keep.xml` (`tools:keep="@drawable/ic_stat_vigon"`); test `test/release_resources_test.dart`. Đã kiểm `aapt2`: APK mới có `ic_stat_vigon`, có báo thức.
3. `.gitignore`: `notes/d9-shots/`.

## Máy đã trả về như cũ
Che nội dung bật; nhắc tắt, 20:00; chủ đề Sáng; quyền thông báo thu hồi; máy bay tắt, Wi-Fi bật; cỡ chữ 0,8 (không đổi). Một thông báo nhắc Ví Gọn còn trong khay (người dùng vuốt bỏ).

## Việc dở
Chạy `flutter analyze` + `flutter test`, commit + push `dev`; ghi kết quả vào `docs/TESTING.md`; H-10 PIN, H-12, H-13, H-15, Q-0..Q-3, Q-5, Q-6, M-1..M-7.

## Đề xuất cải tiến xưởng
- Bẫy Flutter: `TextPainter` không tính chữ đậm hệ thống → mọi đo chữ dùng một hàm chung có `MediaQuery.boldText`. Máy thử nên bật Chữ đậm.
- Mọi tài nguyên Android gọi bằng tên từ Dart (icon thông báo) phải có trong `res/raw/keep.xml`; thử máy phải dùng bản **release**.
- `catch (_) {}` nuốt lỗi plugin làm lỗi im lặng: nên ghi log ở bản debug.
- Luật adb nên nói rõ được chạm cửa sổ hệ thống do chính app mở (bảng chia sẻ, bộ chọn file) hay không.
