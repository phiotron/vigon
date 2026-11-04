# Nhận diện Ví Gọn

Logo đã chốt ngày 2026-11-04 (D-009): hai chiếc thẻ xếp chồng lệch nhau.

| Thành phần | Giá trị |
|------------|---------|
| Nền | `#0E5244` |
| Thẻ sau | `#8CD5BF`, quay −14° |
| Thẻ trước | `#F7FAF8`, quay +8°, bo góc lớn |
| Vạch kẻ | `#0E5244` (dài), `#0E5244` mờ 35% (ngắn) |
| Nút tròn | `#E65100` (cam) |
| Chữ | Be Vietnam Pro 600 và 700 |

File:
- `icon-512.png`: icon Google Play Store, 512×512, vuông trọn, không bo góc (Play tự bo). Vẽ từ chính hình logo.
- Ảnh bìa 1024×500 và bản xem thử các cỡ: trên canvas Design https://claude.ai/artifact/DBwgVoiivXzru6KwTwaypY. CHƯA có file PNG ảnh bìa trong repo: người dùng xuất bằng Share › Export rồi lưu vào thư mục này với tên `feature-graphic-1024x500.png`.
- Icon App Store 1024×1024 (cần cho iOS, thêm 2026-11-04): CHƯA có bản gốc. `AppIcon` của `ios/` đang phóng từ `icon-512.png` nên hơi mờ. Xuất từ canvas Design ở cỡ 1024×1024, PNG không trong suốt, không bo góc, lưu thành `icon-1024.png` trong thư mục này rồi thay vào `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- Icon trong app: `android/app/src/main/res/` (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`, `values/ic_launcher_background.xml`, và `mipmap-*/ic_launcher.png` cho Android cũ).

Không dùng: đồng xu, dấu $, con heo, ví có nắp, chiếc lá, biểu đồ vòng làm logo.
Chưa kiểm trùng nhãn hiệu: tìm "Ví Gọn" và logo trên Google Play, Google Lens, và cơ sở dữ liệu nhãn hiệu (WIPO Global Brand Database, Cục Sở hữu trí tuệ) trước khi nộp.
