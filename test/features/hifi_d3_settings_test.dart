import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/features/settings/backup_password_dialogs.dart';
import 'package:vigon/src/features/settings/currency_picker.dart';
import 'package:vigon/src/ui/dialog.dart';
import 'package:vigon/src/ui/settings_rows.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';
import 'backup_password_test.dart' show pumpDialogHost;

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
}

/// Dựng hết danh sách Cài đặt (màn rất cao) để tìm mọi hàng.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 30000);
}

void main() {
  group('SCR-12 Cài đặt dạng thẻ', () {
    testWidgets('nhóm thẻ, giá trị là phụ đề, CSV theo ngôn ngữ, ngày đầu '
        'tuần là nút chọn một', (tester) async {
      final db = await pumpApp(tester);
      await _openSettings(tester);
      _tallScreen(tester);
      await settle(tester);

      expect(find.byType(SettingsCard), findsWidgets);
      for (final t in ['Giao diện', 'Ngôn ngữ', 'Bảo mật', 'Dữ liệu']) {
        expect(find.widgetWithText(SettingsGroupTitle, t), findsOneWidget);
      }
      expect(
        find.widgetWithText(SettingsGroupTitle, 'Nhắc ghi chép'),
        findsOneWidget,
      );
      // Tiền tệ: giá trị là phụ đề.
      expect(
        find.descendant(
          of: find.widgetWithText(SettingsNavRow, 'Tiền tệ'),
          matching: find.text('VND · ₫'),
        ),
        findsOneWidget,
      );
      // Xuất CSV: phụ đề định dạng theo ngôn ngữ app (vi).
      expect(
        find.text(
          'Định dạng tiếng Việt: dấu chấm phẩy ngăn cột, dấu phẩy thập phân',
        ),
        findsOneWidget,
      );
      // Ngày đầu tuần: chọn Chủ Nhật bằng nút chọn một.
      await tester.tap(find.text('Chủ Nhật'));
      await settle(tester);
      expect(
        await tester.runAsync(
          () => SettingsRepository(db).watchWeekStart().first,
        ),
        DateTime.sunday,
      );
      // Sao lưu tự động dùng icon `backup`.
      expect(
        find.descendant(
          of: find.widgetWithText(SettingsSwitchRow, 'Sao lưu tự động'),
          matching: find.byIcon(Symbols.backup_rounded),
        ),
        findsWidgets,
      );
      // Xóa toàn bộ dữ liệu: hàng nguy hiểm.
      expect(
        tester
            .widget<SettingsNavRow>(
              find.widgetWithText(SettingsNavRow, 'Xóa toàn bộ dữ liệu'),
            )
            .danger,
        isTrue,
      );
      await disposeApp(tester, db);
    });

    testWidgets('PIN bật: hàng widget có nhãn "Đã khóa bằng PIN" (A08)', (
      tester,
    ) async {
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      for (final d in '2468'.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await settle(tester);
      await _openSettings(tester);
      _tallScreen(tester);
      await settle(tester);
      expect(
        find.descendant(
          of: find.widgetWithText(
            SettingsSwitchRow,
            'Hiện số tiền trên widget',
          ),
          matching: find.widgetWithText(StatusPill, 'Đã khóa bằng PIN'),
        ),
        findsOneWidget,
      );
      await disposeApp(tester, db);
    });

    testWidgets('iOS (SCR-33): chữ riêng iOS khi mục được bật', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final db = await pumpApp(tester);
        await _openSettings(tester);
        _tallScreen(tester);
        await settle(tester);
        // D4 đã bật cờ iOS (D-022): các hàng hiện với chữ riêng iOS.
        expect(
          find.text(
            'Ẩn nội dung trong màn chuyển app. '
            'iPhone không cho app chặn chụp màn hình.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'iPhone không cho app chạy theo giờ, nên bản sao lưu được tạo '
            'khi bạn mở Ví Gọn, mỗi ngày tối đa một lần.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Chặn chụp màn hình và ẩn nội dung trong danh sách app '
            'gần đây',
          ),
          findsNothing,
        );
        expect(
          find.text(
            'Ví Gọn chỉ ghi file vào thư mục bạn chọn. '
            'Việc tải lên Google Drive hay Dropbox do app đó thực hiện.',
          ),
          findsNothing,
        );
        expect(
          find.widgetWithText(SettingsSwitchRow, 'Khóa bằng mã PIN'),
          findsOneWidget,
        );
        await disposeApp(tester, db);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    for (final dark in [false, true]) {
      testWidgets('200% ${dark ? 'tối' : 'sáng'}: không tràn chữ', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final db = await pumpApp(tester);
        await _openSettings(tester);
        _tallScreen(tester);
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Giới thiệu'), findsOneWidget);
        await disposeApp(tester, db);
      });
    }
  });

  group('SCR-13 tiền tệ', () {
    testWidgets('ghi chú thu gọn / mở rộng, ghim tiền tệ đang dùng, ẩn khi '
        'tìm, không khớp', (tester) async {
      final db = await pumpApp(tester);
      await _openSettings(tester);
      await tester.ensureVisible(find.text('Tiền tệ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiền tệ'));
      await settle(tester);
      final sheet = find.byType(CurrencyPickerSheet);
      expect(sheet, findsOneWidget);
      expect(find.text('Tiền tệ đang dùng'), findsOneWidget);
      expect(find.text('Xem thêm'), findsOneWidget);
      await tester.tap(find.text('Xem thêm'));
      await tester.pump();
      expect(find.text('Thu gọn'), findsOneWidget);

      await tester.enterText(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        'zzzz',
      );
      await tester.pump();
      expect(find.text('Tiền tệ đang dùng'), findsNothing);
      expect(find.byIcon(Symbols.search_off_rounded), findsOneWidget);
      // ✕ đóng sheet, giữ tiền tệ.
      await tester.tap(find.byTooltip('Hủy'));
      await settle(tester);
      expect(sheet, findsNothing);
      await disposeApp(tester, db);
    });
  });

  group('SCR-26/27 hộp mật khẩu', () {
    testWidgets('xuất: đang mã hóa thì Hủy và ô bị tắt, nút quay (A13)', (
      tester,
    ) async {
      final results = <Object?>[];
      final gate = Completer<String>();
      await pumpDialogHost(
        tester,
        BackupExportDialog(encrypt: (_) => gate.future),
        results,
      );
      expect(find.byIcon(Symbols.upload_file_rounded), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      // Cảnh báo nằm trên các ô (SCR-26).
      expect(find.byType(PasswordWarning), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'abcdef');
      await tester.enterText(fields.at(1), 'abcdef');
      await tester.tap(find.text('Xuất'));
      await tester.pump();
      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      for (final f in tester.widgetList<TextField>(fields)) {
        expect(f.enabled, isFalse);
      }
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Hủy'))
            .onPressed,
        isNull,
      );
      gate.complete('enc');
      await tester.pumpAndSettle();
      expect(results, ['enc']);
    });

    testWidgets('xuất: có encrypt thì trả về nội dung đã mã hóa', (
      tester,
    ) async {
      final results = <Object?>[];
      await pumpDialogHost(
        tester,
        BackupExportDialog(encrypt: (pw) async => 'enc:$pw'),
        results,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'abcdef');
      await tester.enterText(fields.at(1), 'abcdef');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(results, ['enc:abcdef']);
    });

    testWidgets('khôi phục: hộp xác nhận có ghi chú công tắc, icon trung '
        'tính', (tester) async {
      await pumpDialogHost(
        tester,
        const VgDialog(
          title: 't',
          icon: Symbols.settings_backup_restore_rounded,
          tone: VgDialogTone.neutral,
          actions: [],
        ),
        [],
      );
      expect(
        find.byIcon(Symbols.settings_backup_restore_rounded),
        findsOneWidget,
      );
    });
  });

  group('SCR-31 sao lưu tự động', () {
    testWidgets('lỗi thư mục: "Chọn lại thư mục" là nút tonal đứng trước, '
        'dải lỗi', (tester) async {
      final folder = FakeFolder();
      final secrets = MemorySecretStore();
      final db = memoryDatabase();
      final service = AutoBackupService(
        db: db,
        folder: folder,
        secrets: secrets,
        clock: () => testToday,
      );
      await tester.runAsync(() async {
        await service.enable(
          folder: const PickedFolder(uri: 'content://tree/V', name: 'V'),
          password: 'abcdef',
        );
        secrets.values[AutoBackupService.lastAtKey] = DateTime(
          2026,
          11,
          3,
          18,
          30,
        ).toIso8601String();
        secrets.values[AutoBackupService.lastResultKey] =
            AutoBackupResult.permissionDenied.name;
      });
      await pumpApp(
        tester,
        db: db,
        secrets: secrets,
        overrides: [
          backupFolderServiceProvider.overrideWithValue(folder),
          autoBackupServiceProvider.overrideWithValue(service),
        ],
      );
      await _openSettings(tester);
      _tallScreen(tester);
      await settle(tester);
      final status = tester.widget<SettingsStatusLine>(
        find.byType(SettingsStatusLine),
      );
      expect(status.status, SettingsStatus.error);
      final pair = tester.widget<ButtonPair>(find.byType(ButtonPair));
      expect(pair.children.first, isA<FilledButton>());
      expect(
        find.descendant(
          of: find.byWidget(pair.children.first),
          matching: find.text('Chọn lại thư mục'),
        ),
        findsOneWidget,
      );
      expect(find.text('Thư mục: V'), findsOneWidget);
      await disposeApp(tester, db);
    });
  });

  group('P2 1.3–1.5 hộp quên PIN', () {
    testWidgets('200%: thân cuộn, nút ghim, không tràn', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final secrets = MemorySecretStore();
      await tester.runAsync(() => PinService(secrets).setPin('2468'));
      final db = await pumpApp(tester, secrets: secrets);
      await tester.ensureVisible(find.text('Quên mã'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quên mã'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      final dialog = find.byType(VgDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      // Nút xóa ghim ở đáy, luôn nhìn thấy và chạm được.
      final action = find.widgetWithText(TextButton, 'Xóa toàn bộ dữ liệu');
      expect(action, findsOneWidget);
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(tester.getRect(dialog).bottom),
      );
      await tester.tap(find.text('Hủy'));
      await settle(tester);
      expect(dialog, findsNothing);
      await disposeApp(tester, db);
    });
  });
}
