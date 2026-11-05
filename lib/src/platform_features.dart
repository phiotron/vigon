import 'package:flutter/foundation.dart';

/// Tính năng bản 1.2 có phần gốc riêng mỗi nền tảng. Có trên Android và iOS
/// (D-022, thay phần iOS của D-019):
/// - sao lưu tự động vào thư mục chọn (F-24): Android Storage Access
///   Framework; iOS bộ chọn thư mục của app Tệp + bookmark, chạy khi mở app;
/// - widget màn hình chính (F-26): Android AppWidget; iOS WidgetKit + App Group;
/// - che nội dung ở màn đa nhiệm (F-22): Android `FLAG_SECURE`; iOS lớp phủ
///   khi app rời trạng thái hoạt động (không chặn được chụp màn hình).
/// Nhắc ghi chép (F-25) chạy trên cả hai nền tảng. Nền tảng khác: ẩn mục.
///
/// Đọc [defaultTargetPlatform] mỗi lần gọi để test đổi được bằng
/// `debugDefaultTargetPlatformOverride`.
bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

bool get supportsAutoBackup => _isMobile;

bool get supportsHomeWidget => _isMobile;

bool get supportsSecureWindow => _isMobile;
