import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app_info.dart';
import 'package:vigon/src/features/settings/legal_actions.dart';

/// D-051: hàng "Đánh giá" chỉ hiện khi thật sự có trang cửa hàng để mở.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android: chỉ có hàng Đánh giá khi đã phát hành trên Play', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(LegalActions.canRate, AppInfo.playStorePublished);
  });

  test('iOS: chỉ có hàng Đánh giá khi đã có App Store id', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(LegalActions.canRate, AppInfo.appStoreId != null);
  });

  test('máy tính: không có cửa hàng nên ẩn', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(LegalActions.canRate, isFalse);
  });
}
