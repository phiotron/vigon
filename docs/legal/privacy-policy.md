# Chính sách quyền riêng tư — đã chuyển

> **Từ 2026-11-10 (D-039), nguồn chính thức nằm ở `store/legal/`.** File này chỉ còn để trỏ tới đó, không sửa nội dung ở đây nữa.

| Bản | Nguồn Markdown | Bản công khai |
|---|---|---|
| Tiếng Việt | `store/legal/privacy-policy.vi.md` | https://phamphuongphuongnd.github.io/legal/vigon/privacy-policy.vi.html |
| English | `store/legal/privacy-policy.en.md` | https://phamphuongphuongnd.github.io/legal/vigon/privacy-policy.en.html |

Quy trình sửa:

1. Sửa file `.md` trong `store/legal/` (nguồn duy nhất).
2. Chạy lại **cả hai** script trong `apps/A002-vigon`:
   - `python tool/md_to_html.py` → xuất HTML tự chứa vào `store/legal/`.
   - `python tool/md_to_dart.py` → sinh `lib/src/features/settings/legal_texts.dart` (bản nhúng đọc offline).
3. Chép `store/legal/*.html` sang `legal/vigon/` ở gốc repo và đẩy repo `phamphuongphuongnd/legal` (GitHub Pages). URL không đổi nên app không cần sửa.
4. Chạy `flutter analyze` + `flutter test` (test `plan001_t5_test` kiểm URL/hàng Giới thiệu).

Điều khoản sử dụng và trang hỗ trợ nằm cạnh chính sách: `store/legal/terms-of-use.{vi,en}.md`, `store/legal/support.{vi,en}.md`.

Nhà phát hành hiện ghi **Phiotron** (tạm). Đổi tên sau này: sửa `privacy-policy.*.md` + `terms-of-use.*.md` rồi làm lại bước 2–4; URL và app giữ nguyên.
