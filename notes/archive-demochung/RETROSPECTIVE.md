# RETROSPECTIVE — Ví Gọn (APP-001)

Điền khi đạt mốc (chạy được / phát hành / bỏ dở). Sau đó chắt lọc sang `lessons/LESSONS.md`.

**(nháp, chưa được người dùng xác nhận)**: soạn từ CHANGELOG, BACKLOG, DECISIONS, PROMPTS ngày 2026-11-03; các mục "thời gian" và "điều bất ngờ" chỉ người dùng biết.

- Mốc: G1 tới G4 xong và commit; G1, G2 đã thử trên máy thật; G5 code xong, test đạt, chưa build được APK   Ngày: 2026-11-03
- Thời gian thực tế vs dự tính: {{người dùng điền: không có dự tính trước; toàn bộ G1 tới G5 làm trong một phiên}}

## 1. Điều đã làm tốt (nên lặp lại)
- SPEC có 43 tiêu chí chấp nhận đánh số AC-xx, mỗi tiêu chí ghi sẵn kiểm bằng test hay thử tay; test đặt tên theo mã AC nên đối chiếu nhanh (91 test đạt).
- Tách logic thuần (máy tính trên bàn phím, kỳ xem, tổng theo danh mục, lần lặp định kỳ, sao lưu) khỏi giao diện nên test không cần máy.
- Ghi quyết định ngay (D-001 tới D-007), tiền lưu số nguyên, ngày lưu chữ: tránh được lỗi làm tròn và lệch múi giờ ngay từ thiết kế.
- Thử ngay trên điện thoại thật sau G1 bắt được BUG-001 mà test trên máy tính không thấy.
- Commit riêng từng giai đoạn sau khi analyze và test đạt.

## 2. Điều đã làm sai / tốn thời gian (nên tránh)
- Widget test treo hơn 10 phút vì tạo cơ sở dữ liệu ở `setUp`.
- Build APK một kiến trúc làm máy 32-bit crash (BUG-001).
- Thêm nhiều gói cùng lúc ở G5 rồi mới build release, nên lỗi Kotlin (BUG-002) không rõ do gói nào.
- Từ G3 đến G5 làm liền, chưa thử tay trên máy sau từng giai đoạn như quy tắc L-003; việc này đang dồn lại.

## 3. Lỗi và sự cố đáng nhớ (nguyên nhân gốc, cách phát hiện, cách sửa)
- BUG-001: crash khi mở trên Galaxy A13. Gốc: APK chỉ có thư viện arm64, máy chạy hệ điều hành 32-bit. Phát hiện: thử máy thật, `adb logcat -b crash`. Sửa: build đủ kiến trúc. Đã thành L-011.
- BUG-002 (còn mở): build release thất bại ở Kotlin của `android_file_picker`, "Could not close incremental caches". Nghi do dự án ở ổ D còn pub cache ở ổ C, chưa kiểm chứng.
- Lần chạm đầu vào nút − mở nhầm "Khoản thu mới" (G2): chạm lại 2 lần đều đúng, chưa tái hiện được.

## 4. Về cách làm việc với Claude
- Prompt/cách giao việc hiệu quả: xem `docs/PROMPTS.md` (giao theo giai đoạn có AC; cho Claude tự thử qua `adb`).
- Chỗ Claude hay sai hoặc đi lệch: xem `docs/PROMPTS.md` (build một kiến trúc, viết cả lô rồi mới analyze, tạo DB ở `setUp`, đường dẫn Windows trong chuỗi Python, thêm nhiều gói cùng lúc).
- Thông tin lẽ ra phải đưa vào CLAUDE.md sớm hơn: vị trí Flutter và việc chưa có trong PATH; ABI của máy thử; cách tạo DB trong widget test.

## 5. Về mobile (hiệu năng, UI cảm ứng, quyền, offline, build/release store)
- Máy thử 32-bit: mọi APK thử phải có armeabi-v7a. APK đủ kiến trúc nặng 53,7 MB (G1) tới 59,4 MB (G2), vượt ngưỡng 25 MB của SPEC (dành cho một kiến trúc); phải đo lại bằng AAB ở G6.
- Thời gian mở nguội (bản G1) trung vị khoảng 1,7 giây theo `am start -W`; chưa phải số đo chuẩn.
- Nút "Theo hệ thống" ở Cài đặt xuống 2 dòng ở cỡ chữ mặc định; chưa thử cỡ chữ 200%.
- Chưa thử: xoay máy, mất mạng, khóa PIN và sao lưu trên máy thật.

## 6. Nếu làm lại từ đầu, sẽ đổi gì?
- Thử tay trên máy thật sau MỖI giai đoạn, kể cả khi người dùng bảo làm liền.
- Build release sau khi thêm từng gói có mã native.
- Đưa vị trí Flutter, ABI máy thử và cách viết widget test có DB vào CLAUDE.md ngay từ G1.

## 7. Ứng viên bài học cho kho chung
- Widget test dùng cơ sở dữ liệu: tạo DB bên trong thân `testWidgets` và bọc bằng `runAsync`, nếu không test treo → ĐÃ gặp thật, xác nhận được, nên ghi (chủ đề test).
- Thêm gói có mã native thì build release ngay, đừng gom nhiều gói rồi mới build → rút ra từ BUG-002; nên ghi sau khi BUG-002 được sửa và biết nguyên nhân thật.
- Thử máy thật sau mỗi giai đoạn dù được bảo làm liền (đã có L-003; ở đây là bằng chứng nó bị bỏ qua từ G3).
