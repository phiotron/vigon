import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/features/settings/backup_password_dialogs.dart';

import '../helpers.dart';

/// Mở [dialog] từ một nút và ghi lại kết quả trả về.
Future<void> pumpDialogHost(
  WidgetTester tester,
  Widget dialog,
  List<Object?> results,
) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(
              await showDialog<Object?>(
                context: context,
                builder: (_) => dialog,
              ),
            ),
            child: const Text('mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
}

void main() {
  group('hộp thoại xuất có mật khẩu (AC-55)', () {
    testWidgets('mặc định không mật khẩu: xuất ra chuỗi rỗng', (tester) async {
      final results = <Object?>[];
      await pumpDialogHost(tester, const BackupExportDialog(), results);
      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isFalse);
      expect(find.text('Đặt mật khẩu cho file'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(results, ['']);
    });

    testWidgets('bật công tắc: hiện hai ô và cảnh báo; hủy trả về null', (
      tester,
    ) async {
      final results = <Object?>[];
      await pumpDialogHost(tester, const BackupExportDialog(), results);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        find.text('Quên mật khẩu thì không mở được file này.'),
        findsOneWidget,
      );
      for (final f in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(f.obscureText, isTrue);
      }
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('mật khẩu ngắn hơn 6 ký tự và hai lần không khớp báo lỗi', (
      tester,
    ) async {
      final results = <Object?>[];
      await pumpDialogHost(tester, const BackupExportDialog(), results);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'abcde');
      await tester.enterText(fields.at(1), 'abcde');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
      expect(results, isEmpty);

      await tester.enterText(fields.at(0), 'abcdef');
      await tester.enterText(fields.at(1), 'abcdeg');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Hai mật khẩu không khớp'), findsOneWidget);
      expect(results, isEmpty);

      await tester.enterText(fields.at(1), 'abcdef');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(results, ['abcdef']);
    });

    testWidgets('emoji tính là một ký tự khi đếm độ dài', (tester) async {
      final results = <Object?>[];
      await pumpDialogHost(tester, const BackupExportDialog(), results);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '🔐🔐🔐🔐🔐');
      await tester.enterText(fields.at(1), '🔐🔐🔐🔐🔐');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
      await tester.enterText(fields.at(0), '🔐🔐🔐🔐🔐🔐');
      await tester.enterText(fields.at(1), '🔐🔐🔐🔐🔐🔐');
      await tester.tap(find.text('Xuất'));
      await tester.pumpAndSettle();
      expect(results, ['🔐🔐🔐🔐🔐🔐']);
    });
  });

  group('hộp thoại hỏi mật khẩu khi khôi phục (AC-55)', () {
    testWidgets('sai mật khẩu báo lỗi, ở lại cho thử lại, đúng thì mở', (
      tester,
    ) async {
      final envelope = (await tester.runAsync(
        () => encryptBackup('{"a":1}', 'matkhau1', iterations: 50),
      ))!;
      final results = <Object?>[];
      await pumpDialogHost(
        tester,
        BackupUnlockDialog(envelope: envelope, decrypt: decryptBackup),
        results,
      );
      expect(find.text('File có mật khẩu'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );

      await tester.enterText(find.byType(TextField), 'sai-roi');
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Sai mật khẩu hoặc file bị hỏng'), findsOneWidget);
      expect(results, isEmpty);
      // Ô nhập đã được xóa.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );

      await tester.enterText(find.byType(TextField), 'matkhau1');
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(results, ['{"a":1}']);
    });

    testWidgets('đang giải mã: hiện vòng quay, chặn bấm lặp và hủy', (
      tester,
    ) async {
      final gate = Completer<String>();
      var calls = 0;
      final results = <Object?>[];
      await pumpDialogHost(
        tester,
        BackupUnlockDialog(
          envelope: 'x',
          decrypt: (_, _) {
            calls++;
            return gate.future;
          },
        ),
        results,
      );
      await tester.enterText(find.byType(TextField), 'matkhau1');
      await tester.tap(find.text('Mở'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Mở'), warnIfMissed: false);
      await tester.tap(find.text('Hủy'), warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(BackupUnlockDialog), findsOneWidget);
      gate.complete('{}');
      await tester.pumpAndSettle();
      expect(results, ['{}']);
    });

    testWidgets('hủy trả về null', (tester) async {
      final results = <Object?>[];
      await pumpDialogHost(
        tester,
        const BackupUnlockDialog(envelope: 'x'),
        results,
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(results, [null]);
    });
  });

  testWidgets('Cài đặt: "Xuất bản sao lưu" mở hộp thoại hỏi mật khẩu', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Xuất bản sao lưu'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xuất bản sao lưu'));
    await settle(tester);
    expect(find.text('Đặt mật khẩu cho file'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await settle(tester);
    expect(find.text('Đặt mật khẩu cho file'), findsNothing);
    await disposeApp(tester, db);
  });
}
