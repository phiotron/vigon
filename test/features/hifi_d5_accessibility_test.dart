// D5: kiểm trợ năng tự động cho các màn/trạng thái mới của mockup Hi-Fi P1
// (S-31, S-50; AC-37..AC-40): vùng chạm ≥ 48, nút có nhãn, tương phản chữ, ở
// sáng/tối và cỡ chữ 100%/200%; ở 200% không có lỗi vẽ (RenderFlex overflow…).
// `g6_accessibility_test` đi qua các route; file này đi tới các trạng thái chỉ
// mở được bằng chạm: bảng/hộp thoại, mục ẩn, lưới ⋯, tìm kiếm, sao lưu lỗi.
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/features/settings/backup_password_dialogs.dart';

import '../fake_backup_folder.dart';
import '../helpers.dart';
import 'f25_reminder_test.dart' show FakeReminderScheduler;

const _pin = '1357';

class _Env {
  _Env(this.t, this.db);
  final WidgetTester t;
  final AppDatabase db;
  AppLocalizations get l =>
      AppLocalizations.of(t.element(find.byType(Scaffold).first));
}

/// Dữ liệu đủ để mọi trạng thái có mặt: 25 danh mục (ô ⋯), hạn mức vượt và
/// chưa vượt, tài khoản ẩn / chưa dùng / đã dùng, khoản định kỳ, PIN bật, sao
/// lưu tự động đang lỗi thư mục.
Future<void> _seed(
  AppDatabase db,
  MemorySecretStore secrets,
  FakeFolder f,
) async {
  final settings = SettingsRepository(db);
  await settings.setBudget(1000000);
  for (var i = 0; i < 15; i++) {
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            type: CategoryType.expense,
            name: Value('Mục ${i + 11}'),
            icon: 'pets',
            color: 0xFF6A1B9A,
            sortOrder: Value(20 + i),
          ),
        );
  }
  await (db.update(db.categories)..where((c) => c.id.equals(1))).write(
    const CategoriesCompanion(budget: Value(100000)),
  );
  await (db.update(db.categories)..where((c) => c.id.equals(5))).write(
    const CategoriesCompanion(budget: Value(2000000)),
  );
  final bank = await db
      .into(db.accounts)
      .insert(AccountsCompanion.insert(name: const Value('Thẻ ngân hàng')));
  await db
      .into(db.accounts)
      .insert(AccountsCompanion.insert(name: const Value('Quỹ')));
  await db
      .into(db.accounts)
      .insert(
        AccountsCompanion.insert(
          name: const Value('Thẻ cũ'),
          archived: const Value(true),
        ),
      );
  Future<void> e(int cat, int amount, String note, {int account = 1}) => db
      .into(db.entries)
      .insert(
        EntriesCompanion.insert(
          type: EntryType.expense,
          amount: amount,
          categoryId: Value(cat),
          accountId: account,
          date: '2026-11-03',
          note: Value(note),
          // D-037: số gốc VND, tránh bị coi là USD rồi quy đổi thành số khổng lồ.
          currency: const Value('VND'),
          originalAmount: Value(amount),
        ),
      );
  await e(1, 155000, 'phở bò');
  await e(5, 300000, 'áo mưa', account: bank);
  await e(3, 3500000, 'tiền nhà');
  await e(22, 90000, 'thức ăn mèo');
  await db
      .into(db.recurringRules)
      .insert(
        RecurringRulesCompanion.insert(
          type: EntryType.expense,
          amount: 3500000,
          categoryId: const Value(3),
          accountId: 1,
          note: const Value('Tiền nhà'),
          frequency: RecurrenceFrequency.monthly,
          startDate: '2026-11-01',
          lastGeneratedDate: const Value('2026-11-01'),
          currency: const Value('VND'),
          originalAmount: const Value(3500000),
        ),
      );
  await PinService(secrets, settings: () => settings).setPin(_pin);
  final service = AutoBackupService(
    db: db,
    folder: f,
    secrets: secrets,
    clock: () => testToday,
  );
  await service.enable(
    folder: const PickedFolder(uri: 'content://tree/V', name: 'Ví Gọn'),
    password: 'abcdef',
  );
  secrets.values[AutoBackupService.lastAtKey] = DateTime(
    2026,
    11,
    2,
    21,
    4,
  ).toIso8601String();
  secrets.values[AutoBackupService.lastResultKey] =
      AutoBackupResult.permissionDenied.name;
}

Future<void> _tap(_Env e, Finder f) async {
  await e.t.tap(f.first);
  await settle(e.t);
}

Future<void> _settings(_Env e) => _tap(e, find.byTooltip(e.l.settings));

Future<void> _reveal(_Env e, String text) async {
  final f = find.text(text);
  await e.t.scrollUntilVisible(
    f,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(e.t.element(f.first), alignment: 0.2);
  await settle(e.t);
}

Future<void> _row(_Env e, String Function(AppLocalizations l) text) async {
  await _settings(e);
  final label = text(e.l);
  await _reveal(e, label);
  await _tap(e, find.text(label));
}

Future<void> _dialog(_Env e, Widget dialog) async {
  await _settings(e);
  final context = e.t.element(find.byType(Scaffold).last);
  unawaited(showDialog<Object?>(context: context, builder: (_) => dialog));
  await e.t.pumpAndSettle();
}

/// Trạng thái cần kiểm: tên → các bước đi tới đó từ màn chính.
final _states = <String, Future<void> Function(_Env e)>{
  'SCR-01 màn chính 25 danh mục': (e) async {},
  'SCR-07 lưới ⋯': (e) => _tap(e, find.byTooltip(e.l.otherCategories)),
  'SCR-10 các khoản, hạn mức': (e) async {
    await _tap(e, find.byTooltip(e.l.entries));
    await _reveal(e, e.l.categoryFood);
    await _tap(e, find.text(e.l.categoryFood));
  },
  'SCR-11 tìm kiếm': (e) async {
    await _tap(e, find.byTooltip(e.l.entries));
    await _tap(e, find.byTooltip(e.l.search));
    await e.t.enterText(find.byType(TextField).first, 'pho');
    await settle(e.t);
  },
  'SCR-12 cài đặt (đầu)': _settings,
  'SCR-12/31 cài đặt, sao lưu tự động lỗi': (e) async {
    await _settings(e);
    await _reveal(e, e.l.autoBackup);
  },
  'SCR-13 tiền tệ': (e) => _row(e, (l) => l.primaryCurrency),
  'SCR-16 sửa danh mục': (e) async {
    await _row(e, (l) => l.categories);
    await _tap(e, find.text(e.l.categoryFood));
  },
  'SCR-17 tài khoản, mục ẩn mở': (e) async {
    await _row(e, (l) => l.accounts);
    await _tap(e, find.text(e.l.archivedAccountsCount(1)));
  },
  'SCR-18 sửa tài khoản chưa dùng': (e) async {
    await _row(e, (l) => l.accounts);
    await _tap(e, find.text('Quỹ'));
  },
  'SCR-18 sửa tài khoản đã dùng': (e) async {
    await _row(e, (l) => l.accounts);
    await _tap(e, find.text('Thẻ ngân hàng'));
    // Đưa gợi ý ra khỏi vùng dưới nút Lưu ghim (200%), để đo tương phản trên
    // nền thật chứ không trên nút.
    await e.t.ensureVisible(find.text(e.l.accountInUseHint));
    await settle(e.t);
  },
  'SCR-21 sửa khoản định kỳ': (e) async {
    await _row(e, (l) => l.recurring);
    await _tap(e, find.textContaining('Tiền nhà'));
  },
  'SCR-26 hộp xuất có mật khẩu': (e) async {
    await _dialog(
      e,
      BackupExportDialog(encrypt: (_) => Completer<String>().future),
    );
    await _tap(e, find.byType(SwitchListTile));
  },
  'SCR-27 hộp mật khẩu khôi phục': (e) => _dialog(
    e,
    BackupUnlockDialog(
      envelope: '{}',
      decrypt: (_, _) => Future<String>.error(Exception('x')),
    ),
  ),
  'SCR-30 hộp giải thích nhắc': (e) async {
    await _settings(e);
    await _reveal(e, e.l.reminderSwitch);
    await _tap(e, find.text(e.l.reminderSwitch));
  },
  'SCR-31 hộp mật khẩu sao lưu tự động': (e) =>
      _dialog(e, const AutoBackupPasswordDialog()),
};

Future<List<String>> _audit(WidgetTester tester, String where) async {
  final problems = <String>[];
  for (final (name, guideline) in [
    ('vùng chạm', androidTapTargetGuideline),
    ('nhãn', labeledTapTargetGuideline),
    ('tương phản', textContrastGuideline),
  ]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) problems.add('$where · $name: ${result.reason}');
  }
  return problems;
}

void main() {
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      for (final MapEntry(key: name, value: steps) in _states.entries) {
        testWidgets('$name · ${theme.name} · ${(scale * 100).round()}%', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          final db = memoryDatabase();
          final secrets = MemorySecretStore();
          final folder = FakeFolder();
          await tester.runAsync(() async {
            await SettingsRepository(db).setThemeMode(theme);
            await _seed(db, secrets, folder);
          });
          final drawErrors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) =>
              drawErrors.add(d.exceptionAsString().split('\n').first);
          try {
            await pumpApp(
              tester,
              db: db,
              secrets: secrets,
              overrides: [
                reminderSchedulerProvider.overrideWithValue(
                  FakeReminderScheduler(),
                ),
                backupFolderServiceProvider.overrideWithValue(folder),
                autoBackupServiceProvider.overrideWithValue(
                  AutoBackupService(
                    db: db,
                    folder: folder,
                    secrets: secrets,
                    clock: () => testToday,
                  ),
                ),
              ],
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            await settle(tester);
            for (final d in _pin.split('')) {
              await tester.tap(find.widgetWithText(TextButton, d));
              await tester.pump();
            }
            await settle(tester);
            await steps(_Env(tester, db));
            final problems = await _audit(tester, name);
            problems.addAll(drawErrors.map((e) => '$name · lỗi vẽ: $e'));
            expect(problems, isEmpty, reason: problems.join('\n'));
          } finally {
            FlutterError.onError = previous;
          }
          handle.dispose();
          await disposeApp(tester, db);
        });
      }
    }
  }
}
