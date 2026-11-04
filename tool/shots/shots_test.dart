// Chụp ảnh các màn của app (sáng và tối, font thật) để so với bản vẽ trong
// design-mobile/screens/xem/*.html (PLAN-001, UI-04).
//
// Chạy (KHÔNG nằm trong `flutter test` thường vì ở ngoài thư mục test/):
//   flutter test tool/shots/shots_test.dart
// Ảnh ra ở tool/shots/out/<số bước>_<chủ đề>.png, 720×1600 (360×800 dp, tỉ lệ 2).
// Số bước lấy theo bản vẽ (2.1, 3.2…). Dữ liệu dựng theo số liệu trong bản vẽ.
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/providers.dart';

import '../../test/helpers.dart';

const _symbols = 'packages/material_symbols_icons/MaterialSymbolsRounded';

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

Future<void> _shot(WidgetTester tester, String name, String theme) async {
  await tester.pump(const Duration(milliseconds: 50));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('out/${name}_$theme.png'),
  );
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(720, 1600)
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// Dựng dữ liệu của bản vẽ 2.1: tháng 11/2026, thu 15.000.000, chi 6.520.000.
Future<void> _seed(WidgetTester tester, AppDatabase db) async {
  Future<void> e(
    int cat,
    int amount, {
    String? note,
    String date = '2026-11-02',
  }) => insertEntry(
    tester,
    db,
    type: EntryType.expense,
    amount: amount,
    categoryId: cat,
    note: note,
    date: date,
  ).then((_) {});
  // Id danh mục theo seed: 1 Ăn uống, 2 Đi lại, 3 Nhà cửa, 4 Hóa đơn,
  // 5 Mua sắm, 7 Giải trí; thu 11 Lương.
  await e(3, 3500000, note: 'Tiền thuê nhà', date: '2026-11-01');
  await e(4, 520000, note: 'Tiền điện');
  await e(4, 300000, note: 'Internet');
  await e(1, 1240000, note: 'Ăn trưa', date: '2026-11-03');
  await e(2, 450000, date: '2026-11-03');
  await e(5, 300000, note: 'Áo mưa', date: '2026-11-03');
  await e(7, 210000, note: 'Xem phim', date: '2026-11-03');
  await insertEntry(
    tester,
    db,
    type: EntryType.income,
    amount: 15000000,
    categoryId: 11,
    note: 'Lương tháng 11',
    date: '2026-11-01',
  );
  await tester.runAsync(() async {
    await SettingsRepository(db).setBudget(8000000);
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: const Value('Thẻ ngân hàng')));
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(name: const Value('Ví điện tử')));
  });
  await settle(tester);
}

Future<void> _open(
  WidgetTester tester,
  String theme, {
  bool seed = true,
}) async {
  _phone(tester);
  final db = memoryDatabase();
  await tester.runAsync(
    () =>
        SettingsRepository(db)
            .setThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light),
  );
  await pumpApp(tester, db: db);
  if (seed) await _seed(tester, db);
  // pumpApp gọi usePhoneScreen (1080×2400); ép lại 720×1600 cho ảnh nhỏ gọn.
  _phone(tester);
  await settle(tester);
  _db = db;
}

late AppDatabase _db;

Future<void> _go(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await settle(tester);
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await settle(tester);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
}

void main() {
  autoUpdateGoldenFiles = true;
  setUpAll(_loadFonts);

  for (final theme in ['light', 'dark']) {
    testWidgets('chụp các màn · $theme', (tester) async {
      await _open(tester, theme);
      final s = (String n) => _shot(tester, n, theme);

      // 2.1 Màn chính có dữ liệu; 2.6 lọc tài khoản.
      await s('2.1_man_chinh');
      await _go(tester, 'Tài khoản');
      await s('2.6_loc_tai_khoan');
      await tester.tapAt(const Offset(10, 300));
      await settle(tester);

      // 2.4 bảng chọn kỳ; 2.5 khoảng tùy chọn.
      await _tapText(tester, 'Tháng 11 năm 2026');
      await s('2.4_chon_ky');
      await _tapText(tester, 'Khoảng tùy chọn');
      await s('2.5_khoang_tuy_chon');
      await _tapText(tester, 'Hủy');

      // 2.3 kỳ trống: sang tháng sau.
      await _go(tester, 'Kỳ sau');
      await s('2.3_ky_trong');
      await _go(tester, 'Kỳ trước');

      // 4.1 các khoản; 4.2 vuốt xóa.
      await _go(tester, 'Các khoản');
      await s('4.1_cac_khoan');
      await _tapText(tester, 'Hóa đơn');
      await s('4.1b_cac_khoan_mo_nhom');
      await _close(tester);

      // 3.1–3.5 ghi khoản chi.
      await tester.tap(find.byTooltip('Thêm khoản chi').last);
      await settle(tester);
      await s('3.1_khoan_chi_moi');
      for (final k in ['3', '5', '0', '0', '0', '0', '0']) {
        await tester.tap(find.widgetWithText(TextButton, k).first);
        await tester.pump();
      }
      await s('3.2_go_so');
      await _tapText(tester, 'Chọn danh mục');
      await s('3.3_chon_danh_muc');
      await tester.tapAt(const Offset(10, 100));
      await settle(tester);
      await _tapText(tester, 'Không lặp');
      await s('3.5_lap_lai');
      await tester.tapAt(const Offset(10, 100));
      await settle(tester);
      await _close(tester);

      // 3.8 khoản thu mới.
      await tester.tap(find.byTooltip('Thêm khoản thu').last);
      await settle(tester);
      await s('3.8_khoan_thu_moi');
      await _close(tester);

      // 5.x cài đặt.
      await _go(tester, 'Cài đặt');
      await s('5.1_cai_dat');
      await _scrollTo(tester, 'Giới thiệu');
      await s('5.2_cai_dat_duoi');
      await tester.scrollUntilVisible(
        find.text('Ngân sách tháng').first,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await _tapText(tester, 'Ngân sách tháng');
      await s('5.3_ngan_sach');
      await _tapText(tester, 'Hủy');

      // 6.1 danh mục; 6.4 tài khoản; 6.6 chuyển tiền; 7.1 định kỳ.
      await _tapText(tester, 'Danh mục');
      await s('6.1_danh_muc');
      await tester.tap(find.byTooltip('Thêm danh mục'));
      await settle(tester);
      await s('6.2_sua_danh_muc');
      await tester.tapAt(const Offset(10, 100));
      await settle(tester);
      await _close(tester);
      await _tapText(tester, 'Tài khoản');
      await s('6.4_tai_khoan');
      await _close(tester);

      // 9.1 giới thiệu.
      await _scrollTo(tester, 'Giới thiệu');
      await _tapText(tester, 'Giới thiệu');
      await s('9.1_gioi_thieu');
      await _close(tester);
      await _scrollTo(tester, 'Xóa toàn bộ dữ liệu');
      await _tapText(tester, 'Xóa toàn bộ dữ liệu');
      await s('8.9_xoa_buoc_1');
    });
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('chụp màn khóa · $theme', (tester) async {
      _phone(tester);
      final secrets = MemorySecretStore();
      final db = memoryDatabase();
      await tester.runAsync(() async {
        await SettingsRepository(db)
            .setThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
        await PinService(
          secrets,
          settings: () => SettingsRepository(db),
        ).setPin('1357');
      });
      await pumpApp(tester, db: db, secrets: secrets);
      _phone(tester);
      await settle(tester);
      await _shot(tester, '1.1_khoa_pin', theme);
    });
  }
}
