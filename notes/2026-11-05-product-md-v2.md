# [A002-vigon] product.md v2 + CONTEXT.md theo app đã gộp — báo cáo phiên con

Phiên điều phối #1 · 2026-11-05 · yêu cầu từ phiên điều phối: viết lại `product.md` và `CONTEXT.md` theo `main` sau khi
gộp `integration/spec-1.1` (F-14..F-26) và `feature/PLAN-001` (giao diện mới + iOS). Bản 2026-11-04 (commit `9619720`)
viết theo UI 1.0 nên đã lỗi thời.

## Đã làm / file đã đổi
- **`product.md`** (viết lại, tiếng Anh):
  - Điểm xuất phát = **giao diện hiện tại theo PLAN-001** (token đã nối vào code, Be Vietnam Pro, Material Symbols,
    thành phần dùng chung), mô tả theo code hiện tại (vd nút "− Chi / + Thu", tiêu đề "Xem theo", lịch khoảng có
    "Áp dụng", chọn danh mục là lưu D-018, ô ⋯ "Danh mục khác").
  - Ký hiệu trạng thái bản vẽ cho từng màn: ✅ đã vẽ · 🟡 vẽ một phần · 🆕 chưa có khung (ưu tiên) · 🤖 chỉ Android ·
    🍏 cần đề xuất iOS. Đối chiếu bằng cách tìm chữ 1.1/1.2 trong `design/current/screens/components/*` — không khung
    nào có tìm kiếm, mật khẩu, ẩn tài khoản, hạn mức danh mục, nhắc, widget, che nội dung.
  - **33 mục SCR trong app + 5 mục EXT ngoài app** (widget 2×2, thông báo nhắc, Recents khi che nội dung, các bộ chọn
    của hệ điều hành, icon đơn sắc). Mới so với v1: SCR-11 tìm kiếm, SCR-12 nhóm cài đặt 1.2, SCR-13 tiền tệ có tìm,
    SCR-16 ô hạn mức danh mục, SCR-17/18 ẩn/xóa tài khoản, SCR-21 hộp sửa chuỗi 5 ô, SCR-26/27 hộp mật khẩu sao lưu /
    mở file, SCR-30 nhắc ghi chép, SCR-31 sao lưu tự động, SCR-33 Cài đặt bản iOS, EXT-01..05.
  - §9 khác biệt Android/iOS theo D-019 + **yêu cầu Claude Design đề xuất bản iOS** (WidgetKit, sao lưu tự động bằng
    thư mục Files + bookmark, che app switcher, icon tinted) — ghi rõ là đề xuất, ngoài phạm vi v1.
  - Chữ EN + VI lấy từ `.arb` (227 khóa) và `android/.../widget_strings.xml`; bảng chuỗi VI dài/rủi ro cập nhật (thêm
    nhắc, widget, sao lưu tự động, mật khẩu).
  - §7 15 luồng, §8 dữ liệu mẫu thêm tài khoản ẩn, hạn mức danh mục, tìm kiếm, sao lưu tự động, widget.
  - §10.1 điểm UX yếu: bỏ 3 điểm đã giải (ô ⋯, 3 chạm, bảng màu), thêm Cài đặt ~25 dòng, hộp sửa chuỗi chật, hiển thị
    hạn mức, trạng thái sao lưu, công tắc widget khi PIN bật…; §10.2 Future theo SPEC mục 4.
  - §11 bàn giao: thứ tự ưu tiên P1 (🆕) → P2 (làm mới ✅) → P3 (đề xuất iOS); tên file 1:1 route (thêm slug cho màn mới
    và EXT); token cùng schema `tokens.json` + ánh xạ `ColorScheme`/`ViGonColors`/`TextTheme`/`VgSpace…`.
- **`CONTEXT.md`** (viết lại): 5 nhóm thuật ngữ, thêm Hidden account, Delete account, Last visible account, Search,
  All time (search), More categories, Save on category pick, Category budget, Custom range, Encrypted backup, Backup
  password, Auto backup, Backup folder, Auto backup status, Device-only setting, Privacy screen, Reminder, Reminder time,
  Notification permission, Widget, Widget amounts, Deep link, Monochrome icon. Bảng **17 chỗ lệch** có trạng thái
  ✔/⚠ so với bản cũ (đã hết lệch: bảng màu/icon, cột `archived` không giao diện, cỡ widget, iOS gating).
- Không sửa code, `.arb`, `docs/`, `store/`, `design/`, `APP.md`.

## Kiểm tra thế nào
- Đọc: `APP.md`, `notes/2026-11-04-gop-nhanh.md` (bảng "Tính năng + màn sau gộp"), `docs/SPEC.md` (F-01..F-26),
  `docs/DECISIONS.md` (D-010..D-019), `design/current/ui-spec.md` (toàn bộ), `design/current/screens/*`.
- Code đối chiếu: `settings_screen.dart` (thứ tự dòng, `supports*` ẩn trên iOS), `home_screen.dart` (menu lọc, nút
  chính dùng `l.expense`/`l.income`), `entry_editor_screen.dart` (`_save` chọn danh mục rồi lưu luôn), `seed.dart`
  (màu theo token), `category_icons.dart` (31 + 5 khóa cũ), `data_actions.dart`/`lock_screen.dart` (tiêu đề hộp xác
  nhận mới "Xóa toàn bộ dữ liệu?", "Không hoàn tác được"), `backup_password_dialogs.dart`, `auto_backup_section.dart`,
  `reminder_section.dart`, `widget_section.dart`, `account_manage.dart`, `rule_dialog.dart`, `platform_features.dart`.
- Script Python liệt kê khóa `.arb` mới/đổi so với commit `9619720` và chuỗi VI dài nhất.
- Không có build/test vì không đổi code.

## Việc dở / rủi ro / câu hỏi cho người dùng
1. **Người dùng duyệt `product.md` v2** trước khi gửi Claude Design (dài; nếu cần có thể gửi kèm `design/current/`).
2. Đề xuất iOS (§9.2) chỉ là bản vẽ tham khảo; làm thật là việc riêng (Swift, extension) — người dùng quyết sau khi xem.
3. Chỗ lệch cần phiên điều phối xử lý ngoài phạm vi phiên này: README/guide thiết kế còn "Học tập" và "chỉ số 1…31";
   D-016 ghi `updatePeriodMillis="0"` (code 30 phút); nhãn EN "Expenses" (nút app) vs "Expense" (widget); "All time"
   dùng cho cả kỳ và phạm vi tìm.
4. Vài ví dụ định dạng (giờ trạng thái sao lưu tiếng Anh "3 Nov, 18:30", ngày có thứ) suy từ code, chưa chụp trên máy.
5. `ui-spec.md` vẫn mô tả bố cục trước PLAN-001 (tự ghi chú) — product.md v2 bám code; nếu phiên #2 cần ui-spec đúng
   thì nên rà lại sau khi áp Hi-Fi.

## Đề xuất cải tiến xưởng
- **product.md nên có ký hiệu trạng thái bản vẽ (✅/🟡/🆕) ngay từ đầu** — giúp Claude Design biết vẽ gì trước khi app có
  tính năng chạy trước thiết kế. Đưa vào mẫu `playbook/templates/product.md`.
- **Viết product.md SAU khi gộp nhánh**, không song song với nhánh tính năng — bản v1 phải viết lại toàn bộ sau 1 ngày.
  Thêm vào Playbook: "brief thiết kế chỉ viết từ nhánh chính đã ổn định".
- Script so `.arb` theo commit (khóa mới/đổi + chuỗi VI dài) dùng lại được cho mọi lần cập nhật brief → `tool/` cấp xưởng.
- Mỗi tính năng có phần ngoài app (widget, thông báo, Recents) nên có mục "EXT" riêng trong brief, vì design system
  thường chỉ vẽ màn trong app.
