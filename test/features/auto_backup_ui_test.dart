import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/providers.dart';

import 'package:vigon/src/ui/settings_rows.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';

const _tree = 'content://tree/Vigon';

/// Mở app với thư mục giả và dịch vụ mã hóa ít vòng; vào Cài đặt.
Future<({FakeFolder folder, MemorySecretStore secrets, dynamic db})> _open(
  WidgetTester tester,
) async {
  final folder = FakeFolder()
    ..pickResult = const PickedFolder(uri: _tree, name: 'Vigon');
  final secrets = MemorySecretStore();
  final db = memoryDatabase();
  await pumpApp(
    tester,
    db: db,
    secrets: secrets,
    overrides: [
      backupFolderServiceProvider.overrideWithValue(folder),
      autoBackupServiceProvider.overrideWith(
        (ref) => AutoBackupService(
          db: ref.watch(databaseProvider),
          folder: folder,
          secrets: secrets,
          clock: ref.watch(clockProvider),
          encrypt: (json, pw) => encryptBackup(json, pw, iterations: 1000),
        ),
      ),
    ],
  );
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.scrollUntilVisible(
    find.text('Sao lưu tự động'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await settle(tester);
  return (folder: folder, secrets: secrets, db: db);
}

Finder get _switch => find.widgetWithText(SettingsSwitchRow, 'Sao lưu tự động');

void main() {
  testWidgets('bật: chọn thư mục, đặt mật khẩu, sao lưu ngay (AC-58, AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    // Mặc định tắt; có chú thích về Drive/Dropbox.
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(
      find.text(
        'Ví Gọn chỉ ghi file vào thư mục bạn chọn. '
        'Việc tải lên Google Drive hay Dropbox do app đó thực hiện.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sao lưu ngay'), findsNothing);

    await tester.tap(_switch);
    await settle(tester);
    expect(find.text('Mật khẩu sao lưu tự động'), findsOneWidget);
    expect(
      find.textContaining('Quên mật khẩu thì không mở được các file sao lưu'),
      findsOneWidget,
    );
    final fields = find.byType(TextField);
    for (final f in tester.widgetList<TextField>(fields)) {
      expect(f.obscureText, isTrue);
    }

    // Ngắn quá, rồi không khớp: báo lỗi, chưa lưu gì.
    await tester.enterText(fields.at(0), 'abc');
    await tester.enterText(fields.at(1), 'abc');
    await tester.tap(find.text('Bật'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
    await tester.enterText(fields.at(0), 'abcdef');
    await tester.enterText(fields.at(1), 'abcdeg');
    await tester.tap(find.text('Bật'));
    await tester.pumpAndSettle();
    expect(find.text('Hai mật khẩu không khớp'), findsOneWidget);
    expect(h.secrets.values, isEmpty);

    await tester.enterText(fields.at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);

    expect(h.secrets.values[AutoBackupService.passwordKey], 'abcdef');
    expect(h.folder.files.keys, ['vigon-auto-20261103-0900.vigon']);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);
    expect(find.text('Thư mục: Vigon'), findsOneWidget);
    expect(find.textContaining('Lần cuối: '), findsOneWidget);
    expect(find.text('Sao lưu ngay'), findsOneWidget);
    expect(find.text('Chọn lại thư mục'), findsOneWidget);

    await disposeApp(tester, h.db);
  });

  testWidgets('hủy ở hộp mật khẩu: không bật, bỏ quyền thư mục', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(h.folder.released, [_tree]);
    expect(h.folder.files, isEmpty);
    expect(h.secrets.values, isEmpty);
    await disposeApp(tester, h.db);
  });

  testWidgets('"Sao lưu ngay" và lỗi quyền có nút chọn lại (AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.writes, 1);

    // Giao diện mới cao hơn: cuộn nút vào màn trước khi chạm (gộp 2026-11-05).
    await tester.ensureVisible(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.tap(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.writes, 2);
    expect(find.text('Đã sao lưu'), findsOneWidget);

    // Quyền bị thu hồi: báo lỗi rõ, app không văng, công tắc vẫn bật.
    h.folder.failWith = BackupFolderError.permissionDenied;
    // Giao diện mới cao hơn: cuộn nút vào màn trước khi chạm (gộp 2026-11-05).
    await tester.ensureVisible(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.tap(find.text('Sao lưu ngay'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    const error = 'Không ghi được vào thư mục. Chọn lại thư mục';
    expect(find.text(error), findsWidgets);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isTrue);

    // Chọn lại thư mục: sao lưu lại và hết lỗi.
    h.folder
      ..failWith = null
      ..pickResult = const PickedFolder(uri: 'content://tree/Moi', name: 'Mới');
    await tester.ensureVisible(find.text('Chọn lại thư mục'));
    await tester.pump();
    await tester.tap(find.text('Chọn lại thư mục'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('Thư mục: Mới'), findsOneWidget);
    expect(find.text(error), findsNothing);
    expect(h.folder.released, [_tree]);
    expect(h.folder.writes, 3);

    await disposeApp(tester, h.db);
  });

  testWidgets('tắt: xóa mật khẩu, bỏ quyền thư mục, giữ file (AC-60)', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(_switch);
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), 'abcdef');
    await tester.enterText(find.byType(TextField).at(1), 'abcdef');
    await tester.tap(find.text('Bật'));
    await settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await settle(tester);
    expect(h.folder.files.length, 1);

    await tester.tap(_switch);
    await settle(tester);
    expect(tester.widget<SettingsSwitchRow>(_switch).value, isFalse);
    expect(h.secrets.values, isEmpty);
    expect(h.folder.released, [_tree]);
    expect(h.folder.files.length, 1);
    expect(find.text('Sao lưu ngay'), findsNothing);
    expect(
      find.textContaining('File đã ghi vẫn còn trong thư mục'),
      findsOneWidget,
    );
    await disposeApp(tester, h.db);
  });

  testWidgets('app ra nền thì tự sao lưu một lần mỗi ngày (AC-59)', (
    tester,
  ) async {
    final h = await _open(tester);
    final service = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(service);
    await tester.runAsync(
      () => container
          .read(autoBackupServiceProvider)
          .enable(
            folder: const PickedFolder(uri: _tree, name: 'Vigon'),
            password: 'abcdef',
          ),
    );

    Future<void> goToBackgroundAndBack() async {
      final b = tester.binding;
      b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
    }

    await goToBackgroundAndBack();
    expect(h.folder.writes, 1);
    await goToBackgroundAndBack();
    expect(h.folder.writes, 1, reason: 'cùng ngày, dữ liệu không đổi');
    await disposeApp(tester, h.db);
  });
}
