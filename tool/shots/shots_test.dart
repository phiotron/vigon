// Chụp ảnh các màn của app (font thật) để so 1:1 với mockup Hi-Fi
// `design/hifi/<platform>/<theme>/<frame>.png` (P1) và để duyệt các màn P2.
//
// Chạy (KHÔNG nằm trong `flutter test` thường vì ở ngoài thư mục test/):
//   flutter test tool/shots/shots_test.dart
//   flutter test tool/shots/shots_test.dart --plain-name 12_settings   # một nhóm
// Ảnh ra ở tool/shots/out/<platform>/<theme>/<frame>.png (ngoài git), 720×1600
// (360×800 dp, tỉ lệ 2) — cùng tên frame của Claude Design. Frame `__vi`,
// `__*-vi` chạy tiếng Việt; `__text-200`, `__*-text-200` chạy chữ 200%; hai loại
// này chỉ có bản sáng (mockup chỉ có bản sáng). Ảnh P2 (không có frame Hi-Fi)
// tên `P2_<số bước>_<màn>`, tiếng Việt.
//
// Dữ liệu theo giả định A22 của mockup: "hôm nay" = thứ Năm 26/11/2026, kỳ tháng
// 11/2026; tháng mặc định chi 11.780.000 / thu 19.500.000, ngân sách 12.000.000;
// tháng "25 danh mục" (01, 07) chi 15.240.000, ngân sách 16.000.000.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/auto_backup_service.dart';
import 'package:vigon/src/data/backup_folder_service.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/features/settings/auto_backup_providers.dart';
import 'package:vigon/src/features/settings/backup_password_dialogs.dart';
import 'package:vigon/src/ui/confirm_dialog.dart';
import 'package:vigon/src/ui/dialog.dart';

import '../../test/fake_backup_folder.dart';
import '../../test/features/f25_reminder_test.dart' show FakeReminderScheduler;
import '../../test/helpers.dart';

const _symbols = 'packages/material_symbols_icons/MaterialSymbolsRounded';

/// "Hôm nay" của mockup (A22).
final _today = DateTime(2026, 11, 26, 9);

Future<void> _loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ByteData> read(String path) async =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final app = FontLoader('BeVietnamPro');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    app.addFont(read('assets/fonts/BeVietnamPro-$w.ttf'));
  }
  await app.load();
  final cache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['LOCALAPPDATA']}/Pub/Cache';
  final pkg = Directory('$cache/hosted/pub.dev')
      .listSync()
      .firstWhere((e) => e.path.contains('material_symbols_icons-'))
      .path;
  final icons = FontLoader(_symbols)
    ..addFont(read('$pkg/lib/fonts/MaterialSymbolsRounded.ttf'));
  await icons.load();
}

void _phone(WidgetTester tester) {
  // Mặc định test vẽ bóng đổ thành khối đặc (viền đen); bật bóng thật. Bộ test
  // đặt lại cờ này ở đầu mỗi bài và kiểm nó trước khi chạy addTearDown, nên
  // mỗi bài phải tự đặt lại `debugDisableShadows = true` ở cuối.
  debugDisableShadows = false;
  tester.view
    ..physicalSize = const Size(720, 1600)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

// ---------------------------------------------------------------- dữ liệu A22

enum _Data { normal, stress, empty }

/// Id danh mục theo seed: 1 Ăn uống, 2 Đi lại, 3 Nhà cửa, 4 Hóa đơn, 5 Mua sắm,
/// 6 Sức khỏe, 7 Giải trí, 8 Học tập, 9 Gia đình, 10 Khác; thu 11 Lương,
/// 12 Thưởng, 13 Thu khác. Tài khoản 1 Tiền mặt.
const _food = 1, _transport = 2, _home = 3, _bills = 4, _shopping = 5;
const _health = 6, _fun = 7, _family = 9, _salary = 11, _bonus = 12;

/// Tài khoản thêm ở [_seed]: 2 Bank card, 3 E-wallet, 4 Family savings account,
/// 5 Old credit card (ẩn), 6 Old e-wallet (ẩn).
const _bank = 2, _ewallet = 3, _savings = 4;

Future<void> _entry(
  AppDatabase db,
  int? cat,
  int amount,
  String date, {
  String? note,
  int account = 1,
  EntryType type = EntryType.expense,
  int? to,
}) => db
    .into(db.entries)
    .insert(
      EntriesCompanion.insert(
        type: type,
        amount: amount,
        categoryId: Value(cat),
        accountId: account,
        toAccountId: Value(to),
        date: date,
        note: Value(note),
      ),
    );

Future<int> _category(
  AppDatabase db,
  String name,
  String icon,
  int color, {
  int? budget,
  int? order,
}) => db
    .into(db.categories)
    .insert(
      CategoriesCompanion.insert(
        type: CategoryType.expense,
        name: Value(name),
        icon: icon,
        color: color,
        sortOrder: Value(order ?? 100),
        budget: Value(budget),
      ),
    );

Future<int> _account(
  AppDatabase db,
  String name,
  int initial, {
  bool archived = false,
  int order = 0,
}) => db
    .into(db.accounts)
    .insert(
      AccountsCompanion.insert(
        name: Value(name),
        initialBalance: Value(initial),
        sortOrder: Value(order),
        archived: Value(archived),
      ),
    );

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Tháng mặc định của A22 (frame 10, 11, 17, 18, 21, 12…).
Future<void> _seedNormal(AppDatabase db) async {
  await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(
    const AccountsCompanion(initialBalance: Value(2000000)),
  );
  await _account(db, 'Bank card', 15000000, order: 1);
  await _account(db, 'E-wallet', 0, order: 2);
  await _account(db, 'Family savings account', 1250000000, order: 3);
  await _account(db, 'Old credit card', -1200000, archived: true, order: 4);
  await _account(db, 'Old e-wallet', 0, archived: true, order: 5);
  final gym = await _category(db, 'Gym', 'fitness_center', 0xFF00838F);
  await SettingsRepository(db).setBudget(12000000);
  await (db.update(db.categories)..where((c) => c.id.equals(_food))).write(
    const CategoriesCompanion(budget: Value(3000000)),
  );
  await (db.update(db.categories)..where((c) => c.id.equals(_shopping))).write(
    const CategoriesCompanion(budget: Value(2000000)),
  );

  // Tiền nhà 12 tháng (frame 11 all-time: 12 khoản · 42.000.000).
  for (var i = 0; i < 12; i++) {
    final m = DateTime(2025, 12 + i);
    final date = '${m.year}-${m.month.toString().padLeft(2, '0')}-01';
    await _entry(
      db,
      _home,
      3500000,
      date,
      note: '${_months[m.month - 1]} rent',
      account: _bank,
    );
  }
  // Chi tháng 11: 11.780.000.
  await _entry(db, _food, 45000, '2026-11-26', note: 'Beef pho');
  await _entry(db, _food, 320000, '2026-11-25', note: 'Groceries');
  await _entry(db, _food, 85000, '2026-11-24', note: 'Lunch with Minh');
  await _entry(db, _food, 155000, '2026-11-22', note: 'Coffee beans');
  await _entry(db, _food, 2635000, '2026-11-08', note: 'Market');
  await _entry(db, _bills, 680000, '2026-11-20', note: 'Electricity');
  await _entry(db, _bills, 250000, '2026-11-03', note: 'Internet');
  await _entry(db, _bills, 190000, '2026-11-12', note: 'Water');
  await _entry(db, _transport, 35000, '2026-11-18', note: 'Ride to work');
  await _entry(db, _transport, 825000, '2026-11-09', note: 'Fuel');
  await _entry(db, _shopping, 1550000, '2026-11-14', note: 'Shoes');
  await _entry(db, _family, 600000, '2026-11-16', note: 'Gift for Mum');
  await _entry(db, _health, 510000, '2026-11-11', note: 'Pharmacy');
  await _entry(db, _fun, 400000, '2026-11-15', note: 'Cinema');
  await _entry(
    db,
    null,
    2000000,
    '2026-11-10',
    type: EntryType.transfer,
    account: _bank,
    to: 1,
  );
  // Thu tháng 11: 19.500.000.
  await _entry(
    db,
    _salary,
    18000000,
    '2026-11-05',
    type: EntryType.income,
    account: _bank,
  );
  await _entry(
    db,
    _bonus,
    1500000,
    '2026-11-15',
    type: EntryType.income,
    note: 'Year-end bonus',
    account: _bank,
  );

  // Khoản định kỳ (frame 21).
  Future<void> rule(
    EntryType type,
    int amount,
    int cat,
    RecurrenceFrequency f,
    String start,
    String last, {
    String? note,
    bool active = true,
    int account = _bank,
  }) => db
      .into(db.recurringRules)
      .insert(
        RecurringRulesCompanion.insert(
          type: type,
          amount: amount,
          categoryId: Value(cat),
          accountId: account,
          note: Value(note),
          frequency: f,
          startDate: start,
          lastGeneratedDate: Value(last),
          active: Value(active),
        ),
      );
  const m = RecurrenceFrequency.monthly;
  await rule(
    EntryType.expense,
    3500000,
    _home,
    m,
    '2025-12-01',
    '2026-11-01',
    note: 'Rent',
  );
  await rule(
    EntryType.income,
    18000000,
    _salary,
    m,
    '2026-01-05',
    '2026-11-05',
  );
  await rule(
    EntryType.expense,
    250000,
    _bills,
    m,
    '2026-01-03',
    '2026-09-03',
    note: 'Internet',
    active: false,
  );
  await rule(
    EntryType.expense,
    120000,
    gym,
    RecurrenceFrequency.weekly,
    '2026-11-02',
    '2026-11-23',
    account: 1,
  );
}

/// Tháng "25 danh mục" (frame 01, 07; A01): 15 danh mục tự thêm theo thứ tự
/// frame, 17 danh mục có khoản.
Future<void> _seedStress(AppDatabase db) async {
  await _seedNormal(db);
  // Gym của _seedNormal là danh mục thứ 11; xếp lại theo thứ tự frame.
  await (db.update(db.categories)..where((c) => c.name.equals('Gym'))).write(
    const CategoriesCompanion(sortOrder: Value(15)),
  );
  const extra = [
    ('Coffee', 'local_cafe', 0xFFBF360C, 420000),
    ('Groceries', 'shopping_bag', 0xFF558B2F, 600000),
    ('Fuel', 'local_gas_station', 0xFF4527A0, 380000),
    ('Phone', 'wifi', 0xFF0277BD, 200000),
    ('Travel', 'flight', 0xFF1565C0, 0),
    ('Gym', '', 0, 120000),
    ('Pets', 'pets', 0xFF6D4C41, 300000),
    ('Spa', 'spa', 0xFFAD1457, 450000),
    ('Gifts', 'redeem', 0xFF827717, 500000),
    ('Charity', 'volunteer_activism', 0xFFC62828, 0),
    ('Repairs', 'build', 0xFF546E7A, 0),
    ('Kids', 'child_care', 0xFF6A1B9A, 490000),
    ('Water', 'water_drop', 0xFF0277BD, 0),
    ('Internet', 'wifi', 0xFF283593, 0),
    ('Clothes', 'checkroom', 0xFF00695C, 0),
  ];
  var order = 10;
  for (final (name, icon, color, spent) in extra) {
    int id;
    if (icon.isEmpty) {
      final gym = await (db.select(
        db.categories,
      )..where((c) => c.name.equals(name))).getSingle();
      id = gym.id;
      order++;
    } else {
      id = await _category(db, name, icon, color, order: order++);
    }
    if (spent > 0) await _entry(db, id, spent, '2026-11-19', note: name);
  }
  await SettingsRepository(db).setBudget(16000000);
}

// --------------------------------------------------------------- dựng màn

class _Ctx {
  _Ctx(this.t, this.db, this.secrets, this.reminder, this.folder, this.lang);
  final WidgetTester t;
  final String lang;
  final AppDatabase db;
  final MemorySecretStore secrets;
  final FakeReminderScheduler reminder;
  final FakeFolder folder;
}

typedef _Prep = Future<void> Function(_Ctx c);
typedef _Steps = Future<void> Function(_Ctx c);

class _Shot {
  const _Shot(
    this.name,
    this.steps, {
    this.data = _Data.normal,
    this.prep,
    this.settings = false,
  });

  final String name;
  final _Steps steps;
  final _Data data;

  /// Ghi thêm dữ liệu/cài đặt trước khi mở app.
  final _Prep? prep;

  /// Cài đặt như frame 12 (PIN bật, nhắc 20:00, sao lưu tự động đã chạy…).
  final bool settings;

  String get language =>
      name.startsWith('P2_') || name.endsWith('vi') ? 'vi' : 'en';
  double get textScale => name.endsWith('text-200') ? 2 : 1;

  /// Frame tiếng Việt / 200% chỉ có bản sáng.
  bool get lightOnly => name.endsWith('vi') || name.endsWith('text-200');
}

const _pin = '1357';

Future<_Ctx> _boot(WidgetTester t, _Shot s, String theme) async {
  _phone(t);
  final db = memoryDatabase();
  final secrets = MemorySecretStore();
  final reminder = FakeReminderScheduler();
  final folder = FakeFolder();
  final c = _Ctx(t, db, secrets, reminder, folder, s.language);
  final service = AutoBackupService(
    db: db,
    folder: folder,
    secrets: secrets,
    clock: () => _today,
  );
  await t.runAsync(() async {
    final settings = SettingsRepository(db);
    await settings.setThemeMode(
      theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
    );
    switch (s.data) {
      case _Data.normal:
        await _seedNormal(db);
      case _Data.stress:
        await _seedStress(db);
      case _Data.empty:
        break;
    }
    if (s.settings) {
      await PinService(secrets, settings: () => settings).setPin(_pin);
      await settings.setSecureWindow(true);
      await settings.setReminderEnabled(true);
      await settings.setReminderTime(const TimeOfDay(hour: 20, minute: 0));
      await service.enable(
        folder: const PickedFolder(
          uri: 'content://tree/backups',
          name: 'Ví Gọn backups',
        ),
        password: 'abcdef',
      );
      secrets.values[AutoBackupService.lastAtKey] = DateTime(
        2026,
        11,
        25,
        21,
        4,
      ).toIso8601String();
      secrets.values[AutoBackupService.lastResultKey] =
          AutoBackupResult.ok.name;
    }
    await s.prep?.call(c);
  });
  await pumpApp(
    t,
    db: db,
    secrets: secrets,
    localeCode: s.language,
    clock: () => _today,
    overrides: [
      reminderSchedulerProvider.overrideWithValue(reminder),
      backupFolderServiceProvider.overrideWithValue(folder),
      autoBackupServiceProvider.overrideWithValue(service),
    ],
  );
  // pumpApp gọi usePhoneScreen (1080×2400); ép lại 720×1600 cho ảnh nhỏ gọn.
  _phone(t);
  if (s.textScale != 1) {
    t.platformDispatcher.textScaleFactorTestValue = s.textScale;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await settle(t);
  if (s.settings) {
    for (final d in _pin.split('')) {
      await t.tap(find.widgetWithText(TextButton, d));
      await t.pump();
    }
    await settle(t);
  }
  return c;
}

Future<void> _shot(WidgetTester t, String name, String theme) async {
  await t.pump(const Duration(milliseconds: 50));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('out/android/$theme/$name.png'),
  );
}

// ------------------------------------------------------------ thao tác

String _l(_Ctx c, String en, String vi) => c.lang == 'vi' ? vi : en;

Future<void> _tip(_Ctx c, String en, String vi) async {
  await c.t.tap(find.byTooltip(_l(c, en, vi)).last);
  await settle(c.t);
}

Future<void> _tapRule(_Ctx c, String name) async {
  // Tên chuỗi là RichText "Rent · ₫3,500,000".
  await c.t.tap(find.textContaining(name, findRichText: true).first);
  await settle(c.t);
}

Future<void> _tapText(_Ctx c, String text) async {
  await c.t.tap(find.text(text).first);
  await settle(c.t);
}

/// Cuộn danh sách chính tới [text] rồi đặt nó ở [alignment] (0 = mép trên).
Future<void> _reveal(_Ctx c, String text, {double alignment = 0.5}) async {
  final f = find.text(text);
  await c.t.scrollUntilVisible(
    f,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await c.t.pumpAndSettle();
  await Scrollable.ensureVisible(c.t.element(f.first), alignment: alignment);
  await settle(c.t);
}

Future<void> _openSettings(_Ctx c) => _tip(c, 'Settings', 'Cài đặt');
Future<void> _openEntries(_Ctx c) => _tip(c, 'Records', 'Các khoản');

Future<void> _settingsRow(_Ctx c, String text) async {
  await _openSettings(c);
  await _reveal(c, text);
  await _tapText(c, text);
}

Future<void> _search(_Ctx c, [String? query]) async {
  await _openEntries(c);
  await _tip(c, 'Search', 'Tìm kiếm');
  if (query != null) {
    await c.t.enterText(find.byType(TextField).first, query);
    await settle(c.t);
  }
}

/// Mở hộp thoại [dialog] trên màn Cài đặt (như frame 26, 27, 31).
Future<void> _dialogOverSettings(
  _Ctx c,
  Widget Function(BuildContext context) dialog, {
  String? reveal,
}) async {
  await _openSettings(c);
  if (reveal != null) await _reveal(c, reveal, alignment: 0.3);
  final context = c.t.element(find.byType(Scaffold).last);
  unawaited(showDialog<Object?>(context: context, builder: dialog));
  await c.t.pumpAndSettle();
}

Future<void> _type(_Ctx c, int field, String text) async {
  await c.t.enterText(find.byType(TextField).at(field), text);
  await c.t.pump();
}

Future<void> _press(_Ctx c, String text, {bool settleAll = true}) async {
  await c.t.tap(find.text(text).last);
  if (settleAll) {
    await c.t.pumpAndSettle();
  } else {
    await c.t.pump();
    await c.t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _archive(_Ctx c, List<int> ids) async {
  for (final id in ids) {
    await (c.db.update(c.db.accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(archived: Value(true)),
    );
  }
}

// ------------------------------------------------------------ kịch bản

Future<void> _none(_Ctx c) async {}

Future<void> _export(_Ctx c, {bool on = false, String? a, String? b}) async {
  await _dialogOverSettings(
    c,
    (_) => BackupExportDialog(encrypt: (_) => Completer<String>().future),
    reveal: _l(c, 'Export backup', 'Xuất bản sao lưu'),
  );
  if (on) {
    await c.t.tap(find.byType(SwitchListTile));
    await c.t.pumpAndSettle();
  }
  if (a != null) await _type(c, 0, a);
  if (b != null) await _type(c, 1, b);
}

Future<void> _unlock(
  _Ctx c, {
  String? typed,
  bool wrong = false,
  bool busy = false,
}) async {
  await _dialogOverSettings(
    c,
    (_) => BackupUnlockDialog(
      envelope: '{}',
      decrypt: (_, _) => busy
          ? Completer<String>().future
          : Future<String>.error(Exception('wrong')),
    ),
    reveal: _l(c, 'Restore from backup', 'Khôi phục từ bản sao lưu'),
  );
  if (typed != null) await _type(c, 0, typed);
  if (wrong || busy) {
    await _press(c, _l(c, 'Open', 'Mở'), settleAll: !busy);
  }
}

Future<void> _autoBackupState(_Ctx c, AutoBackupResult? result) async {
  final service = AutoBackupService(
    db: c.db,
    folder: c.folder,
    secrets: c.secrets,
    clock: () => _today,
  );
  await service.enable(
    folder: const PickedFolder(
      uri: 'content://tree/backups',
      name: 'Ví Gọn backups',
    ),
    password: 'abcdef',
  );
  if (result != null) {
    c.secrets.values[AutoBackupService.lastAtKey] = DateTime(
      2026,
      11,
      25,
      21,
      4,
    ).toIso8601String();
    c.secrets.values[AutoBackupService.lastResultKey] = result.name;
  }
}

Future<void> _showAutoBackup(_Ctx c) async {
  await _openSettings(c);
  await _reveal(
    c,
    _l(c, 'Automatic backup', 'Sao lưu tự động'),
    alignment: 0.15,
  );
}

Future<void> _reminderTap(
  _Ctx c, {
  bool deny = false,
  bool cont = false,
}) async {
  c.reminder.permission = !deny;
  await _openSettings(c);
  final label = _l(c, 'Daily reminder', 'Nhắc ghi chép hằng ngày');
  await _reveal(c, label);
  await _tapText(c, label);
  if (cont) {
    await _press(c, _l(c, 'Continue', 'Tiếp tục'), settleAll: false);
    await settle(c.t);
  }
}

final _p1 = <_Shot>[
  // SCR-01 / 07 — màn chính 25 danh mục.
  const _Shot('01_home__more-categories', _none, data: _Data.stress),
  const _Shot('01_home__vi', _none, data: _Data.stress),
  const _Shot('01_home__text-200', _none, data: _Data.stress),
  _Shot('07_home~more-categories__default', (c) async {
    await _tip(c, 'More categories', 'Danh mục khác');
  }, data: _Data.stress),
  // SCR-10 Các khoản.
  for (final n in ['category-budget', 'vi', 'text-200'])
    _Shot('10_entries__$n', (c) async {
      await _openEntries(c);
      await _tapText(c, _l(c, 'Food', 'Ăn uống'));
    }),
  _Shot(
    '10_entries__long-text',
    (c) async {
      await _openEntries(c);
      await _tapText(c, 'Food');
    },
    prep: (c) async {
      await _entry(
        c.db,
        _food,
        1480000,
        '2026-11-26',
        note:
            'Dinner with the whole team after the quarterly review at the '
            'seafood place by the river; we split the bill eight ways and I '
            'also covered drinks, dessert and two taxis home for colleagues.',
      );
      await (c.db.update(c.db.categories)..where((x) => x.id.equals(_shopping)))
          .write(const CategoriesCompanion(budget: Value(1300000)));
      final id = await _category(
        c.db,
        // Tên tối đa 50 ký tự (frame dùng 53).
        'Sửa chữa xe máy và bảo dưỡng định kỳ hằng năm',
        'build',
        0xFF546E7A,
        budget: 500000,
        order: 4,
      );
      await _entry(c.db, id, 620000, '2026-11-21', note: 'Thay nhớt');
    },
  ),
  // SCR-11 Tìm kiếm.
  _Shot('11_entries~search__empty', (c) => _search(c)),
  _Shot('11_entries~search__searching', (c) => _search(c, 'rent')),
  for (final n in ['all-time', 'text-200'])
    _Shot('11_entries~search__$n', (c) async {
      await _search(c, 'rent');
      await _tapText(c, 'All time');
    }),
  _Shot('11_entries~search__amount', (c) => _search(c, '155')),
  _Shot('11_entries~search__no-match', (c) => _search(c, 'karaoke')),
  // SCR-12 Cài đặt.
  for (final n in ['top', 'top-vi', 'top-text-200'])
    _Shot('12_settings__$n', _openSettings, settings: true),
  for (final n in ['middle', 'middle-vi', 'middle-text-200'])
    _Shot('12_settings__$n', (c) async {
      await _openSettings(c);
      await _reveal(c, _l(c, 'Security', 'Bảo mật'), alignment: 0);
    }, settings: true),
  for (final n in ['bottom', 'bottom-vi'])
    _Shot('12_settings__$n', (c) async {
      await _openSettings(c);
      await c.t.fling(
        find.byType(Scrollable).first,
        const Offset(0, -6000),
        3000,
      );
      await settle(c.t);
    }, settings: true),
  // SCR-13 Tiền tệ.
  for (final n in ['default', 'vi'])
    _Shot('13_settings~currency__$n', (c) async {
      await _settingsRow(c, _l(c, 'Currency', 'Tiền tệ'));
    }, settings: true),
  for (final (n, q) in [('searching', 'dol'), ('no-match', 'zzz')])
    _Shot('13_settings~currency__$n', (c) async {
      await _settingsRow(c, 'Currency');
      await c.t.enterText(find.byType(TextField).first, q);
      await settle(c.t);
    }, settings: true),
  // SCR-16 Sửa danh mục.
  for (final n in ['budget-set', 'budget-error'])
    _Shot('16_categories~edit__$n', (c) async {
      await _settingsRow(c, 'Categories');
      await _tapText(c, 'Food');
      final budget = find.byKey(const ValueKey('category-budget'));
      await c.t.ensureVisible(budget);
      await c.t.pumpAndSettle();
      if (n == 'budget-error') {
        await c.t.enterText(budget, '0');
        await _press(c, 'Save');
      }
    }),
  // SCR-17 / 18 Tài khoản.
  _Shot('17_accounts__hidden', (c) => _settingsRow(c, 'Accounts')),
  _Shot('17_accounts__hidden-open', (c) async {
    await _settingsRow(c, 'Accounts');
    await _tapText(c, 'Hidden accounts (2)');
  }),
  for (final n in ['unused', 'text-200'])
    _Shot('18_accounts~edit__$n', (c) async {
      await _settingsRow(c, 'Accounts');
      await _tapText(c, 'Family savings account');
    }),
  for (final n in ['used', 'vi'])
    _Shot('18_accounts~edit__$n', (c) async {
      await _settingsRow(c, _l(c, 'Accounts', 'Tài khoản'));
      await _tapText(c, 'Bank card');
    }),
  _Shot('18_accounts~edit__last-visible', (c) async {
    await _settingsRow(c, 'Accounts');
    await _tapText(c, 'Cash');
  }, prep: (c) => _archive(c, [_bank, _ewallet, _savings])),
  _Shot('18_accounts~delete__default', (c) async {
    await _settingsRow(c, 'Accounts');
    await _tapText(c, 'Family savings account');
    await _press(c, 'Delete account');
  }),
  // SCR-21 Sửa khoản định kỳ.
  for (final n in ['running', 'text-200'])
    _Shot('21_recurring~edit__$n', (c) async {
      await _settingsRow(c, 'Repeating records');
      await _tapRule(c, 'Rent');
    }),
  for (final n in ['frequency-changed', 'vi'])
    _Shot('21_recurring~edit__$n', (c) async {
      await _settingsRow(c, _l(c, 'Repeating records', 'Khoản định kỳ'));
      await _tapRule(c, 'Rent');
      await _tapText(c, _l(c, 'Weekly', 'Hằng tuần'));
    }),
  _Shot('21_recurring~edit__error', (c) async {
    await _settingsRow(c, 'Repeating records');
    await _tapRule(c, 'Rent');
    await _type(c, 0, '0');
    await _press(c, 'Save');
  }),
  _Shot(
    '21_recurring~edit__one-account',
    (c) async {
      await _settingsRow(c, 'Repeating records');
      await _tapRule(c, 'Rent');
    },
    prep: (c) async {
      await (c.db.update(c.db.recurringRules)
            ..where((r) => r.note.equals('Rent')))
          .write(const RecurringRulesCompanion(active: Value(false)));
      await _archive(c, [_bank, _ewallet, _savings]);
    },
  ),
  // SCR-26 Xuất sao lưu.
  _Shot('26_settings~backup-export__off', (c) => _export(c)),
  for (final n in ['on-empty', 'vi'])
    _Shot('26_settings~backup-export__$n', (c) => _export(c, on: true)),
  _Shot('26_settings~backup-export__error', (c) async {
    await _export(c, on: true, a: 'abc', b: 'abd');
    await _press(c, 'Export');
  }),
  for (final n in ['working', 'text-200'])
    _Shot('26_settings~backup-export__$n', (c) async {
      await _export(c, on: true, a: 'abcdef12', b: 'abcdef12');
      await _press(c, 'Export', settleAll: false);
    }),
  // SCR-27 Khôi phục.
  _Shot('27_settings~restore-password__default', (c) => _unlock(c)),
  _Shot(
    '27_settings~restore-password__error',
    (c) => _unlock(c, typed: 'secret12', wrong: true),
  ),
  _Shot(
    '27_settings~restore-password__working',
    (c) => _unlock(c, typed: 'secret12', busy: true),
  ),
  _Shot('27_settings~restore__confirm', (c) async {
    await _openSettings(c);
    await _reveal(c, 'Restore from backup', alignment: 0.3);
    final context = c.t.element(find.byType(Scaffold).last);
    final l = AppLocalizations.of(context);
    unawaited(
      showConfirmDialog(
        context,
        icon: Symbols.settings_backup_restore_rounded,
        iconTone: VgDialogTone.neutral,
        title: l.restore,
        body: l.restoreConfirm,
        note: l.restoreSwitchesNote,
        action: l.confirm,
      ),
    );
    await c.t.pumpAndSettle();
  }),
  // SCR-30 Nhắc ghi chép.
  for (final n in ['explain', 'vi'])
    _Shot('30_settings~reminder__$n', (c) => _reminderTap(c)),
  for (final n in ['denied', 'denied-vi'])
    _Shot(
      '30_settings~reminder__$n',
      (c) => _reminderTap(c, deny: true, cont: true),
    ),
  _Shot('30_settings~reminder__time-picker', (c) async {
    await _openSettings(c);
    await _reveal(c, 'Reminder time');
    await _tapText(c, 'Reminder time');
  }, prep: (c) => SettingsRepository(c.db).setReminderEnabled(true)),
  // SCR-31 Sao lưu tự động.
  _Shot('31_settings~auto-backup__off', _showAutoBackup),
  _Shot(
    '31_settings~auto-backup__never-run',
    _showAutoBackup,
    prep: (c) => _autoBackupState(c, null),
  ),
  _Shot(
    '31_settings~auto-backup__ok',
    _showAutoBackup,
    prep: (c) => _autoBackupState(c, AutoBackupResult.ok),
  ),
  for (final n in ['folder-error', 'vi', 'text-200'])
    _Shot(
      '31_settings~auto-backup__$n',
      _showAutoBackup,
      prep: (c) => _autoBackupState(c, AutoBackupResult.permissionDenied),
    ),
  _Shot(
    '31_settings~auto-backup__other-error',
    _showAutoBackup,
    prep: (c) => _autoBackupState(c, AutoBackupResult.failed),
  ),
  for (final n in ['default', 'vi'])
    _Shot(
      '31_settings~auto-backup-password__$n',
      (c) => _dialogOverSettings(
        c,
        (_) => const AutoBackupPasswordDialog(),
        reveal: _l(c, 'Automatic backup', 'Sao lưu tự động'),
      ),
    ),
  _Shot('31_settings~auto-backup-password__error', (c) async {
    await _dialogOverSettings(
      c,
      (_) => const AutoBackupPasswordDialog(),
      reveal: 'Automatic backup',
    );
    await _type(c, 0, 'abc');
    await _type(c, 1, 'abd');
    await _press(c, 'Turn on');
  }),
];

/// Màn P2 (không có frame Hi-Fi; so với CHANGELOG P2 + bản vẽ design/current).
final _p2 = <_Shot>[
  const _Shot('P2_2.1_home', _none),
  _Shot('P2_2.3_empty_period', (c) => _tip(c, 'Next period', 'Kỳ sau')),
  _Shot('P2_2.4_period_sheet', (c) => _tapText(c, 'Tháng 11 năm 2026')),
  _Shot('P2_2.6_account_filter', (c) async {
    await c.t.tap(find.byIcon(Symbols.account_balance_wallet_rounded).first);
    await settle(c.t);
  }),
  _Shot('P2_2.6b_account_chip', (c) async {
    await c.t.tap(find.byIcon(Symbols.account_balance_wallet_rounded).first);
    await settle(c.t);
    await _tapText(c, 'Bank card');
  }),
  _Shot('P2_3.1_new_expense', (c) async {
    await c.t.tap(find.byTooltip('Thêm khoản chi').last);
    await settle(c.t);
  }),
  _Shot('P2_3.3_category_grid', (c) async {
    await c.t.tap(find.byTooltip('Thêm khoản chi').last);
    await settle(c.t);
    await c.t.tap(find.widgetWithText(TextButton, '5').first);
    await c.t.pump();
    await _tapText(c, 'Chọn danh mục');
  }),
  _Shot('P2_3.8_new_income', (c) async {
    await c.t.tap(find.byTooltip('Thêm khoản thu').last);
    await settle(c.t);
  }),
  _Shot('P2_4.1_entries', _openEntries),
  _Shot('P2_5.3_budget_dialog', (c) => _settingsRow(c, 'Ngân sách tháng')),
  _Shot('P2_6.1_categories', (c) => _settingsRow(c, 'Danh mục')),
  _Shot('P2_6.6_transfer', (c) async {
    await _settingsRow(c, 'Tài khoản');
    await _tip(c, 'Transfer', 'Chuyển tiền');
  }),
  _Shot('P2_7.1_recurring', (c) => _settingsRow(c, 'Khoản định kỳ')),
  _Shot('P2_8.9_delete_all', (c) async {
    await _openSettings(c);
    await _reveal(c, 'Xóa toàn bộ dữ liệu');
    await _tapText(c, 'Xóa toàn bộ dữ liệu');
  }),
  _Shot('P2_9.1_about', (c) async {
    await _openSettings(c);
    await _reveal(c, 'Giới thiệu');
    await _tapText(c, 'Giới thiệu');
  }),
  _Shot('P2_2.1_home_empty', _none, data: _Data.empty),
];

void main() {
  autoUpdateGoldenFiles = true;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  WidgetsApp.debugAllowBannerOverride = false;
  setUpAll(_loadFonts);

  for (final s in [..._p1, ..._p2]) {
    for (final theme in ['light', 'dark']) {
      if (theme == 'dark' && s.lightOnly) continue;
      testWidgets('${s.name} · $theme', (t) async {
        final c = await _boot(t, s, theme);
        await s.steps(c);
        await _shot(t, s.name, theme);
        debugDisableShadows = true;
      }, timeout: const Timeout(Duration(seconds: 90)));
    }
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('P2_1.1_lock · $theme', (t) async {
      _phone(t);
      final secrets = MemorySecretStore();
      final db = memoryDatabase();
      await t.runAsync(() async {
        await SettingsRepository(db)
            .setThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
        await PinService(
          secrets,
          settings: () => SettingsRepository(db),
        ).setPin(_pin);
      });
      await pumpApp(t, db: db, secrets: secrets, clock: () => _today);
      _phone(t);
      await settle(t);
      await _shot(t, 'P2_1.1_lock', theme);
      debugDisableShadows = true;
    });
  }
}
