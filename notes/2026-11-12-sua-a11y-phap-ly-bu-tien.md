# [A002-vigon] Trợ năng hàng "Tháng bắt đầu từ ngày" · chính sách vân tay · test "Bù tiền" cách 1–2 · 2026-11-12

Ba việc không cần điện thoại, làm tiếp sau khi gộp C1 (`2e588cc`). Chỉ sửa trong
`apps/A002-vigon`; không chạm file xưởng. **Chưa push.**

## 1. Trợ năng hàng "Tháng bắt đầu từ ngày"
- Lỗi cũ: cả hàng chạm được (`InkWell`) nhưng phần chữ bị `ExcludeSemantics`, nên
  `labeledTapTargetGuideline` thấy một vùng chạm **không nhãn**; trước đây test
  g6 phải tạm bỏ kiểm nhãn cho nhóm Cài đặt.
- Sửa `lib/src/features/settings/settings_screen.dart` (`_MonthStartRow`): bọc cả
  hàng bằng `Semantics(label: '${l.monthStartDay}: ${value}', button: true, onTap: _toggle, excludeSemantics: true)`.
  Cả hàng là **một** nút trợ năng; ô xổ bên trong bị gộp nên TalkBack không đọc
  hai lần cùng một việc.
- `test/features/g6_accessibility_test.dart`: bật lại kiểm nhãn cho nhóm Cài đặt
  và thêm hàng này vào danh sách kiểm; danh sách xếp theo thứ tự cuộn
  (Thông báo ngân sách → Tháng bắt đầu từ ngày → Mở khoá bằng vân tay).

## 2. Chính sách quyền riêng tư cho mở khoá bằng vân tay (F-41)
- `store/legal/privacy-policy.vi.md` + `.en.md`: thêm đoạn ở mục 2 — sinh trắc chỉ
  bật được khi có PIN; app chỉ lưu **cờ bật/tắt** trong kho khoá an toàn; vân
  tay/khuôn mặt do hệ điều hành giữ và đối chiếu, app không đọc/không nhận/không
  lưu dữ liệu sinh trắc, chỉ nhận đúng/sai; cờ không vào file sao lưu, mất khi tắt
  PIN hoặc "Xóa toàn bộ dữ liệu"; Android chỉ hiện khi máy có sinh trắc lớp mạnh.
- Mục 11 nhắc lại sinh trắc là cách mở khoá nhanh, dữ liệu do hệ điều hành giữ.
- Ngày "Cập nhật lần cuối" → **2026-11-12**.
- Sinh lại `store/legal/privacy-policy.{vi,en}.html` (`python tool/md_to_html.py`)
  và bản nhúng `lib/src/features/settings/legal_texts.dart`
  (`python tool/md_to_dart.py`).
- **Chưa đăng lại** trang công khai `phamphuongphuongnd.github.io/legal/vigon/`
  (repo pháp lý riêng, chỉ đăng khi người dùng bảo).

## 3. Test "Bù tiền" cách 1 và 2 (AC-165)
Trước chỉ có cách 3 (sửa số dư ban đầu). Thêm vào `test/features/f49_ledger_test.dart`:
- **Cách 1 — ghi khoản thu:** mở màn Nhập khoản với tài khoản + số tiền bằng số
  thiếu, chọn danh mục thu → quay lại hàng đợi tự kiểm và lưu mục; kiểm 2 khoản
  (thu bù + chi có `REF9`), Hoàn tác chỉ bỏ khoản chi, khoản thu còn lại, mục về
  hàng đợi.
- **Cách 2 — chuyển tiền:** màn Chuyển tiền với ô Đến chọn sẵn tài khoản thiếu;
  chuyển 200.000 từ Tiền mặt (cấp 500.000) → tự lưu mục; kiểm khoản chuyển
  `(from 1, to MB)` + khoản chi `REF9`, hàng đợi rỗng.
- Thêm helper `_queuedEmail` cho hai test mới.

## Kết quả
- `flutter analyze`: không lỗi.
- `flutter test`: **1070 qua** (1068 cũ + 2 test Bù tiền), không test nào đỏ.
- Chưa build APK/không thử máy (điện thoại đang bận); chưa push.

## Việc dở
- Push `dev` + chạy CI bản sao khi người dùng cho phép.
- Thử máy 8 kịch bản C1 (`notes/2026-11-11-ledger-core.md`) khi điện thoại rảnh.
- Đăng lại trang pháp lý công khai sau khi duyệt nội dung vân tay.
- Mockup v5 vẫn chờ Claude Design.
