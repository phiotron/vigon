import 'package:flutter/foundation.dart';

/// Chữ riêng iOS (D-022: `autoBackupNoteIos`, `secureWindowNoteIos`…) hiện khi
/// nền tảng đích là iOS. Đọc [defaultTargetPlatform] mỗi lần để test đổi được
/// bằng `debugDefaultTargetPlatformOverride`. Việc có hiện mục hay không vẫn do
/// cờ trong `platform_features.dart` quyết định.
bool get useIosCopy => defaultTargetPlatform == TargetPlatform.iOS;
