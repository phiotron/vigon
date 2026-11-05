import 'package:flutter/foundation.dart';

/// Tính năng bản 1.2 chỉ có phần gốc Android (D-019). Trên iOS các mục cài đặt
/// tương ứng bị ẩn cho tới khi có bản iOS riêng:
/// - sao lưu tự động vào thư mục chọn (F-24) dùng Storage Access Framework;
/// - widget màn hình chính (F-26) là AppWidget;
/// - che nội dung ở màn đa nhiệm (F-22) dùng `FLAG_SECURE`.
/// Nhắc ghi chép (F-25) chạy trên cả hai nền tảng.
///
/// Đọc [defaultTargetPlatform] mỗi lần gọi để test đổi được bằng
/// `debugDefaultTargetPlatformOverride`.
bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

bool get supportsAutoBackup => _isAndroid;

bool get supportsHomeWidget => _isAndroid;

bool get supportsSecureWindow => _isAndroid;
