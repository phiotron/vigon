# [A002-vigon] product.md cho Claude Design — báo cáo phiên con A

Phiên điều phối #1 · 2026-11-04 · phạm vi: chỉ `product.md`, `CONTEXT.md`, file này.

## Đã làm / file đã đổi
- **`product.md`** (mới, tiếng Anh, ~915 dòng) — brief gửi Claude Design làm mockup Hi-Fi theo hướng **nâng cấp** từ
  `design/current/screens/`:
  - §1 tổng quan, 4 persona, 6 việc cốt lõi, 7 nguyên tắc (offline/riêng tư, ≤ 3 chạm, UI tài chính bình tĩnh, vùng ngón cái…).
  - §2 ràng buộc: Android M3 + iOS thích ứng (bảng khác biệt back/share sheet/document picker/safe area), khung
    360×800 dp và 393×852 pt, chỉ dọc, sáng/tối/hệ thống, cỡ chữ 200%, vùng chạm 48/56/64, vi/en + **bảng chuỗi VI dài
    nhất**, định dạng tiền/ngày/kỳ, logo D-009, token hiện có, ràng buộc màu/icon danh mục nằm trong dữ liệu.
  - §3 luật nghiệp vụ (2 loại "số dư", chuyển tiền, định kỳ, ngân sách, xóa/hoàn tác, sao lưu, PIN, đổi tiền tệ).
  - §4 bảng route + sơ đồ điều hướng. §5 **27 mục SCR-01..SCR-27** — mọi màn và hộp thoại trong ui-spec, mỗi mục có mục
    đích, thành phần, dữ liệu, trạng thái (trống/đang nạp/lỗi/khóa/chữ dài/số lớn/>10 danh mục/200%), tương tác, chữ
    EN + VI thật từ `.arb`, nhãn trợ năng; có ánh xạ sang số khung cũ (1.1…9.2).
  - §6 10 luồng. §7 dữ liệu mẫu nhất quán (tổng %, số dư, ngân sách khớp nhau). §8 16 điểm UX yếu → cơ hội thiết kế.
    §9 Ngoài phạm vi/Future. §10 bàn giao: khung theo nền tảng × chủ đề, biến thể VI/200%/stress, cách đặt tên file
    1:1 với route, token JSON cùng schema `tokens.json` + ánh xạ `ColorScheme`/`ThemeExtension`/`TextTheme`, component sheet.
- **`CONTEXT.md`** (mới) — bảng thuật ngữ 40 mục (Term (code) | VI | Định nghĩa | Tránh dùng) + bảng **10 chỗ lệch** code ↔ SPEC ↔ thiết kế.
- Không sửa code, `.arb`, `docs/`, `store/`, `APP.md`.

## Kiểm tra thế nào
- Đối chiếu từng màn/hộp thoại trong `design/current/ui-spec.md` §3–4 với `### SCR-xx` trong `product.md` (27 mục, đủ:
  Home, Entry editor + keypad, Edit, Entries, Settings, Categories, Accounts, Transfer, Recurring, About, Lock, PIN
  set/check, Forgot PIN, period sheet + lịch khoảng, account filter, budget, currency, month-start, category/account
  sheet, delete-move, recurring edit, date picker, backup/restore/CSV, delete all, dialog + snackbar dùng chung).
- Chữ copy lấy trực tiếp từ `lib/l10n/app_en.arb` / `app_vi.arb` (đo độ dài bằng script Python để chọn chuỗi VI dài nhất).
- Kiểm hành vi trong code khi ui-spec chưa đủ: `home_screen.dart` (icon vòng vẫn hiện khi kỳ trống; số icon = chu vi),
  `seed.dart` + `category_avatar.dart` + `category_icons.dart` (màu/icon thật), `money.dart`/`format.dart` (định dạng),
  `data_actions.dart`/`lock_screen.dart` (tiêu đề và nút hộp thoại), `account_repository.dart` (tài khoản mặc định =
  đầu danh sách, cột `archived`), `backup.dart` (phiên bản + checksum).
- Không có lệnh build/test vì không đổi code.

## Việc dở / rủi ro / câu hỏi cho người dùng
1. **Bảng màu + icon danh mục lệch** giữa `design/current` và code (CONTEXT mục lệch #5). Màu lưu dạng ARGB, icon lưu
   khóa chữ, cả hai nằm trong file `.vigon` → nếu Claude Design đổi thì phiên #2 cần bảng ánh xạ/migration. product.md
   đã yêu cầu Claude Design đưa ánh xạ cũ → mới.
2. **"Học tập" (thiết kế) vs "Giáo dục" (SPEC + code)** — đề xuất giữ "Giáo dục".
3. **Luồng nút "−" hiện tốn 4 chạm**, AC-02 đòi ≤ 3 (§8 mục 3). Sửa là đổi hành vi → cần người dùng duyệt phương án
   Claude Design đưa ra. Tương tự: lối vào Chuyển tiền phụ (§8 mục 12), nút "Chi"/"Thu" EN cần khóa `.arb` mới.
4. Ví dụ định dạng ngày "Ngày" (vd `Tue, Nov 3, 2026`) và USD trong tiếng Việt (`1.250,00 $`) suy từ `intl`, chưa chạy
   thật để chụp — sai lệch nhỏ chỉ ảnh hưởng chữ mẫu trong mockup.
5. Email thật trong `app_info.dart` không đưa vào product.md (dùng `hello@example.com` làm chỗ giữ).
6. Người dùng cần **duyệt product.md** trước khi gửi Claude Design (theo kế hoạch #1).

## Đề xuất cải tiến xưởng
- **Mẫu `product.md` cấp xưởng:** bố cục §1–§10 ở đây (persona → ràng buộc → luật nghiệp vụ → IA/route → từng màn theo
  khuôn Purpose/Components/Data/States/Interactions/Copy/A11y → luồng → dữ liệu mẫu → điểm yếu → Future → bàn giao
  + quy ước tên file theo route) dùng lại được cho mọi app; nên đưa vào `playbook/templates/product.md`.
- **Script đo chuỗi `.arb`** (liệt kê chuỗi VI dài hơn EN ≥ 30%) là bước lặp lại ở mọi app vi/en → nên thành tool
  dùng chung (`tool/arb_lengths.py`).
- Khi xuất design system từ Claude Design, nên ép **giữ khóa dữ liệu** (icon key, màu ARGB) ngay trong brief để tránh
  lệch như mục 1 ở trên.
