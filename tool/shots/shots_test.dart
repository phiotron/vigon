// Chụp ảnh các màn của app (sáng và tối, font thật) để so với bản vẽ trong
// design-mobile/screens/xem/*.html (PLAN-001, UI-04).
//
// Chạy (KHÔNG nằm trong `flutter test` thường vì ở ngoài thư mục test/):
//   flutter test tool/shots/shots_test.dart
// Ảnh ra ở tool/shots/out/<số bước>_<chủ đề>.png, 720×1600 (360×800 dp, tỉ lệ 2).
// Số bước lấy theo bản vẽ (2.1, 3.2…). Dữ liệu dựng theo số liệu trong bản vẽ.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/data/pin_service.dart';

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
  await tester.runAsync(() => SettingsRepository(db).setBudget(8000000));
  await tester.runAsync(() => AccountRepository(db).add(name: 'Thẻ ngân hàng'));
  await tester.runAsync(() => AccountRepository(db).add(name: 'Ví điện tử'));
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
}

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

/// Mỗi màn một bài riêng (có giới hạn thời gian) để một màn kẹt không làm
/// treo cả loạt. [steps] đưa app tới màn cần chụp rồi gọi `shot`.
final _scenarios =
    <
      String,
      Future<void> Function(WidgetTester t, Future<void> Function() shot)
    >{
      '2.1_man_chinh': (t, shot) => shot(),
      '2.6_loc_tai_khoan': (t, shot) async {
        await _go(t, 'Tài khoản');
        await shot();
      },
      '2.4_chon_ky': (t, shot) async {
        await _tapText(t, 'Tháng 11 năm 2026');
        await shot();
      },
      '2.5_khoang_tuy_chon': (t, shot) async {
        await _tapText(t, 'Tháng 11 năm 2026');
        await _tapText(t, 'Khoảng tùy chọn');
        await shot();
      },
      '2.3_ky_trong': (t, shot) async {
        await _go(t, 'Kỳ sau');
        await shot();
      },
      '4.1_cac_khoan': (t, shot) async {
        await _go(t, 'Các khoản');
        await shot();
      },
      '4.1b_cac_khoan_mo_nhom': (t, shot) async {
        await _go(t, 'Các khoản');
        await _tapText(t, 'Hóa đơn');
        await shot();
      },
      '3.1_khoan_chi_moi': (t, shot) async {
        await t.tap(find.byTooltip('Thêm khoản chi').last);
        await settle(t);
        await shot();
      },
      '3.2_go_so': (t, shot) async {
        await t.tap(find.byTooltip('Thêm khoản chi').last);
        await settle(t);
        for (final k in ['3', '5', '0', '0', '0', '0', '0']) {
          await t.tap(find.widgetWithText(TextButton, k).first);
          await t.pump();
        }
        await shot();
      },
      '3.3_chon_danh_muc': (t, shot) async {
        await t.tap(find.byTooltip('Thêm khoản chi').last);
        await settle(t);
        await _tapText(t, 'Chọn danh mục');
        await shot();
      },
      '3.5_lap_lai': (t, shot) async {
        await t.tap(find.byTooltip('Thêm khoản chi').last);
        await settle(t);
        await _tapText(t, 'Không lặp');
        await shot();
      },
      '3.8_khoan_thu_moi': (t, shot) async {
        await t.tap(find.byTooltip('Thêm khoản thu').last);
        await settle(t);
        await shot();
      },
      '5.1_cai_dat': (t, shot) async {
        await _go(t, 'Cài đặt');
        await shot();
      },
      '5.2_cai_dat_duoi': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _scrollTo(t, 'Giới thiệu');
        await shot();
      },
      '5.3_ngan_sach': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _tapText(t, 'Ngân sách tháng');
        await shot();
      },
      '6.1_danh_muc': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _tapText(t, 'Danh mục');
        await shot();
      },
      '6.2_sua_danh_muc': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _tapText(t, 'Danh mục');
        await t.tap(find.byTooltip('Thêm danh mục'));
        await settle(t);
        await shot();
      },
      '6.4_tai_khoan': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _tapText(t, 'Tài khoản');
        await shot();
      },
      '7.1_dinh_ky': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _tapText(t, 'Khoản định kỳ');
        await shot();
      },
      '9.1_gioi_thieu': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _scrollTo(t, 'Giới thiệu');
        await _tapText(t, 'Giới thiệu');
        await shot();
      },
      '8.9_xoa_buoc_1': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _scrollTo(t, 'Xóa toàn bộ dữ liệu');
        await _tapText(t, 'Xóa toàn bộ dữ liệu');
        await shot();
      },
      '8.1_dat_pin': (t, shot) async {
        await _go(t, 'Cài đặt');
        await _scrollTo(t, 'Khóa bằng mã PIN');
        await _tapText(t, 'Khóa bằng mã PIN');
        await shot();
      },
    };

void main() {
  autoUpdateGoldenFiles = true;
  // Mặc định test vẽ bóng đổ thành khối đặc (viền đen); bật bóng thật.
  debugDisableShadows = false;
  WidgetsApp.debugAllowBannerOverride = false;
  setUpAll(_loadFonts);

  for (final theme in ['light', 'dark']) {
    for (final entry in _scenarios.entries) {
      testWidgets('${entry.key} · $theme', (tester) async {
        await _open(tester, theme);
        await entry.value(tester, () => _shot(tester, entry.key, theme));
      }, timeout: const Timeout(Duration(seconds: 90)));
    }

    testWidgets('1.1_khoa_pin · $theme', (tester) async {
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
