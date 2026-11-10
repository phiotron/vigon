import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/app_info.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../helpers.dart';

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(TextButton, d));
    await tester.pump();
  }
  await settle(tester);
}

/// Mở Cài đặt rồi kéo tới dòng [text] và bấm vào.
///
/// `find.text(text).last` để không bấm vào tiêu đề nhóm trùng chữ với hàng
/// (ví dụ "Giới thiệu" ở cuối màn); kéo thì bám finder chưa lọc (`.last` ném
/// lỗi khi chưa có mục nào được dựng).
Future<void> _openSetting(WidgetTester tester, String text) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.scrollUntilVisible(find.text(text), 200);
  final row = find.text(text).last;
  await tester.ensureVisible(row);
  await settle(tester);
  await tester.tap(row);
  await settle(tester);
}

void main() {
  testWidgets(
    'đặt PIN (8.1): có mũi tên quay lại, quay lại thì PIN không bật',
    (tester) async {
      final secrets = MemorySecretStore();
      final db = await pumpApp(tester, secrets: secrets);
      await _openSetting(tester, 'Khóa bằng mã PIN');

      expect(find.text('Đặt mã PIN 4 số'), findsOneWidget);
      expect(
        find.text(
          'Nếu quên mã, cách duy nhất để dùng lại là xóa toàn bộ dữ liệu trong '
          'app.',
        ),
        findsWidgets,
      );
      final back = find.byType(BackButton);
      expect(back, findsOneWidget);
      expect(tester.getSize(back).width, greaterThanOrEqualTo(48));

      // Nhập lần đầu xong thì sang bước 8.2, cảnh báo không còn trên màn PIN.
      await _enterPin(tester, '1357');
      expect(find.text('Nhập lại mã PIN'), findsOneWidget);

      await tester.tap(back);
      await settle(tester);
      expect(find.text('Nhập lại mã PIN'), findsNothing);
      expect(
        await tester.runAsync(() => PinService(secrets).isEnabled()),
        isFalse,
      );
      final toggle = tester.widget<SettingsSwitchRow>(
        find.widgetWithText(SettingsSwitchRow, 'Khóa bằng mã PIN'),
      );
      expect(toggle.value, isFalse);
      await disposeApp(tester, db);
    },
  );

  testWidgets('màn đặt PIN ở cỡ chữ 200% vẫn cuộn được, không tràn', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final handle = tester.ensureSemantics();
    final db = await pumpApp(tester);
    await _openSetting(tester, 'Khóa bằng mã PIN');
    expect(find.text('Đặt mã PIN 4 số'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    final scroll = find.descendant(
      of: find.byType(Scaffold).last,
      matching: find.byType(Scrollable),
    );
    expect(scroll, findsOneWidget);
    // Phím 0 nằm dưới cùng; cuộn tới được và bấm được.
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, '0'),
      100,
      scrollable: scroll,
    );
    await tester.tap(find.widgetWithText(TextButton, '0'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    handle.dispose();
    await disposeApp(tester, db);
  });

  testWidgets('tắt PIN (8.4): sai báo "Sai mã PIN", đúng thì tắt', (
    tester,
  ) async {
    final secrets = MemorySecretStore();
    final db = await pumpApp(tester, secrets: secrets);
    await _openSetting(tester, 'Khóa bằng mã PIN');
    await _enterPin(tester, '2468');
    await _enterPin(tester, '2468');
    expect(
      await tester.runAsync(() => PinService(secrets).isEnabled()),
      isTrue,
    );

    await tester.tap(find.text('Khóa bằng mã PIN'));
    await settle(tester);
    expect(find.text('Nhập mã PIN'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await _enterPin(tester, '1111');
    expect(find.text('Sai mã PIN'), findsOneWidget);
    await _enterPin(tester, '2468');
    expect(find.text('Nhập mã PIN'), findsNothing);
    expect(
      await tester.runAsync(() => PinService(secrets).isEnabled()),
      isFalse,
    );
    await disposeApp(tester, db);
  });

  testWidgets('xóa toàn bộ (8.9, 8.10): hai hộp thoại đúng tiêu đề, nút nền '
      'error; Hủy ở bước 2 thì không xóa', (tester) async {
    final db = memoryDatabase();
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 1000,
      categoryId: 1,
    );
    await _openSetting(tester, 'Xóa toàn bộ dữ liệu');

    // Bước 1.
    expect(find.text('Xóa toàn bộ dữ liệu?'), findsOneWidget);
    expect(find.byIcon(Symbols.delete_forever_rounded), findsWidgets);
    final error = tester.element(find.byType(Dialog)).vg.error;
    Color? background(Finder button) =>
        tester.widget<FilledButton>(button).style?.backgroundColor?.resolve({});
    final step1 = find.widgetWithText(FilledButton, 'Xóa');
    expect(background(step1), error);
    await tester.tap(step1);
    await settle(tester);

    // Bước 2, chọn Hủy.
    expect(find.text('Không hoàn tác được'), findsOneWidget);
    expect(find.text('Không hoàn tác được. Xóa hết?'), findsOneWidget);
    expect(find.byIcon(Symbols.warning_rounded), findsOneWidget);
    final step2 = find.widgetWithText(FilledButton, 'Xóa toàn bộ dữ liệu');
    expect(background(step2), error);
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await settle(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(
      await tester.runAsync(() => db.select(db.entries).get()),
      hasLength(1),
    );

    // Làm lại đủ hai bước thì xóa (8.11).
    await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa toàn bộ dữ liệu'));
    await settle(tester);
    expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
    expect(find.text('Đã xóa toàn bộ dữ liệu'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Giới thiệu (9.1–9.2, AC-41): một thẻ trong Cài đặt có phiên '
      'bản, chính sách, điều khoản, giấy phép, đánh giá, góp ý', (
    tester,
  ) async {
    expect(
      AppInfo.privacyPolicyUrl('vi'),
      endsWith('/vigon/privacy-policy.vi.html'),
    );
    expect(
      AppInfo.privacyPolicyUrl('en'),
      endsWith('/vigon/privacy-policy.en.html'),
    );
    expect(AppInfo.termsUrl('vi'), endsWith('/vigon/terms-of-use.vi.html'));
    expect(AppInfo.termsUrl('en'), endsWith('/vigon/terms-of-use.en.html'));

    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Phiên bản'), 200);
    await tester.ensureVisible(find.text('Phiên bản'));
    await settle(tester);

    expect(find.text('1.0.0 (1)'), findsOneWidget);
    expect(find.text('Đánh giá Ví Gọn'), findsOneWidget);
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Gửi góp ý'), findsOneWidget);
    final policy = find.widgetWithText(
      SettingsNavRow,
      'Chính sách quyền riêng tư',
    );
    expect(policy, findsOneWidget);
    expect(tester.widget<SettingsNavRow>(policy).onTap, isNotNull);

    // Mở bản nhúng bằng nút Giấy phép (không qua trình duyệt nên test chạy
    // được cả khi máy không có ứng dụng ngoài).
    await tester.tap(find.text('Giấy phép mã nguồn mở'));
    await settle(tester);
    expect(find.byType(LicensePage), findsOneWidget);
    await disposeApp(tester, db);
  });
}
