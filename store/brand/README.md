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
- Icon App Store 1024×1024: **đã có** sau gộp PLAN-001 (2026-11-05) — `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`, vẽ từ vector logo bằng `tool/render_ios_icon.py`, RGB không alpha, không bo góc. Đổi logo thì chạy lại script đó, không phóng từ `icon-512.png`.
- Icon trong app: `android/app/src/main/res/` (`mipmap-anydpi-v26/ic_launcher.xml`, `drawable/ic_launcher_foreground.xml`, `values/ic_launcher_background.xml`, và `mipmap-*/ic_launcher.png` cho Android cũ).

Không dùng: đồng xu, dấu $, con heo, ví có nắp, chiếc lá, biểu đồ vòng làm logo.
Chưa kiểm trùng nhãn hiệu: tìm "Ví Gọn" và logo trên Google Play, Google Lens, và cơ sở dữ liệu nhãn hiệu (WIPO Global Brand Database, Cục Sở hữu trí tuệ) trước khi nộp.
