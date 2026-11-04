---
name: flutter-deeplink-mac-dinh-bat
description: Flutter 3.47.8 bật deep link mặc định khi manifest thiếu flutter_deeplinking_enabled; app đã tắt
type: project
created: 2026-11-04
---
`FlutterActivityLaunchConfigs.deepLinkEnabled()` trả true khi manifest thiếu khóa (C:/src/flutter/engine/src/flutter/shell/platform/android/io/flutter/embedding/android/FlutterActivityLaunchConfigs.java dòng 55-63). MainActivity exported nên app khác gửi intent có data URI đi thẳng vào go_router. Đã thêm meta-data `flutter_deeplinking_enabled` = false; widget và thông báo dùng DeepLinkChannel riêng.

**Áp dụng thế nào:** giữ meta-data này; `test/manifest_deeplink_test.dart` canh. Route có `:id` dùng `int.tryParse` và chuyển về `/` khi id sai.
