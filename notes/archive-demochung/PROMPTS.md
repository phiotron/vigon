# PROMPTS — cách giao việc cho Claude hiệu quả với Ví Gọn

Ghi lại câu lệnh/cách giao việc ĐÃ chạy tốt và chỗ Claude hay sai. Đây là nguyên liệu cho mục 4 của RETROSPECTIVE.

## Cách giao việc hiệu quả
- Chốt SPEC có số thứ tự AC kiểm chứng được rồi giao theo giai đoạn (G1 tới G6): mỗi AC có test đặt tên theo mã AC nên đối chiếu nhanh.
- Cho Claude cắm điện thoại và tự thử bằng `adb` (cài APK, chạm, chụp màn hình, đọc cây giao diện bằng `uiautomator dump`): bắt được lỗi mà test trên máy tính không thấy (BUG-001).
- Người dùng nói "làm hết đến G6" thì Claude vẫn commit riêng từng giai đoạn sau khi analyze và test đạt: dễ quay lại điểm tốt gần nhất.

## Chỗ Claude hay sai / hay đi lệch ở app này
- Build APK một kiến trúc (`android-arm64`) để thử máy thật, không kiểm `ro.product.cpu.abilist` của máy trước (BUG-001, L-011).
- Viết xong cả lô file rồi mới chạy analyze, nên dồn nhiều cảnh báo nhỏ (thiếu dấu ngoặc, import thừa, API đã lỗi thời như `onReorder`); nên chạy `dart fix --apply` và analyze sau mỗi nhóm file.
- Tạo cơ sở dữ liệu trong `setUp` của widget test làm test treo hơn 10 phút; phải tạo trong thân `testWidgets` và bọc bằng `runAsync`.
- Ghi đường dẫn Windows có `\f` vào chuỗi Python thường làm hỏng thành ký tự điều khiển (`C:\src\flutter` thành `C:\src` + form feed trong CLAUDE.md); dùng dấu `/` hoặc chuỗi thô.
- Thêm một lúc nhiều gói (G5) rồi mới build release, nên lỗi Kotlin (BUG-002) không rõ do gói nào; nên thêm và build từng gói quan trọng.
- Khi lệnh chạy quá 10 phút bị đẩy xuống nền, đừng chờ: dừng tác vụ và chạy từng phần.
