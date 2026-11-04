import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

/// Nạp Be Vietnam Pro từ `assets/fonts/` để đo bề rộng chữ như trên máy.
Future<void> _loadAppFont() async {
  final loader = FontLoader('BeVietnamPro');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Giao diện các màn S06–S12 theo bản vẽ (PLAN-001 T4).
Future<void> _open(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route);
  await settle(tester);
}

void main() {
  testWidgets('Chuyển tiền: ô Từ nằm trên ô Đến; cùng tài khoản thì ô Đến '
      'báo lỗi và không lưu (6.6, 6.7)', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(
      () =>
          AccountRepository(db)
              .add(name: 'Thẻ ngân hàng rất dài tên', initialBalance: 0),
    );
    await pumpApp(tester, db: db);
    await _open(tester, '/transfer');

    final from = find.byKey(const ValueKey('transfer-from'));
    final to = find.byKey(const ValueKey('transfer-to'));
    // Xếp dọc: cùng lề trái, Đến ở dưới Từ.
    expect(
      tester.getTopLeft(to).dy,
      greaterThan(tester.getBottomLeft(from).dy),
    );
    expect(tester.getTopLeft(to).dx, tester.getTopLeft(from).dx);
    expect(find.text('Chọn hai tài khoản khác nhau'), findsNothing);

    // Chọn Tiền mặt cho ô Đến: trùng với ô Từ.
    await tester.tap(to);
    await settle(tester);
    await tester.tap(find.text('Tiền mặt').last);
    await settle(tester);
    expect(find.text('Chọn hai tài khoản khác nhau'), findsOneWidget);
    // Lỗi nằm dưới số tiền, tức là dưới cả hai ô.
    expect(
      tester.getTopLeft(find.text('Chọn hai tài khoản khác nhau')).dy,
      greaterThan(tester.getBottomLeft(to).dy),
    );
    final field = tester.widget<InputDecorator>(
      find.descendant(of: to, matching: find.byType(InputDecorator)),
    );
    final scheme = Theme.of(tester.element(to)).colorScheme;
    expect(field.decoration.enabledBorder?.borderSide.color, scheme.error);

    for (final k in '5000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, k));
      await tester.pump();
    }
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('Các khoản: kỳ trống hiện "Kỳ này chưa có khoản nào" (4.4)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _open(tester, '/entries');
    expect(find.text('Kỳ này chưa có khoản nào'), findsOneWidget);
    expect(find.text('Số dư'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('Các khoản: vuốt trái xóa một khoản rồi Hoàn tác (4.2, 4.3)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 45000,
      categoryId: 1,
      note: 'phở',
    );
    await _open(tester, '/entries');
    // Mở nhóm Ăn uống; khoản con lấy ghi chú làm tiêu đề, phụ đề là ngày.
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    expect(find.text('phở'), findsOneWidget);
    expect(find.text('3 thg 11, 2026'), findsOneWidget);

    await tester.drag(find.text('phở'), const Offset(-500, 0));
    await settle(tester);
    expect(await tester.runAsync(() => db.select(db.entries).get()), isEmpty);
    expect(find.text('Đã xóa'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows!.single.note, 'phở');
    await disposeApp(tester, db);
  });

  testWidgets('Sửa danh mục: ô màu đang chọn có vòng viền và ✓, chọn màu khác '
      'thì dấu chọn chuyển theo (6.2)', (tester) async {
    final handle = tester.ensureSemantics();
    final db = await pumpApp(tester);
    await _open(tester, '/categories');
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    // Ăn uống mặc định dùng màu 13 (cat-13).
    expect(find.byKey(const ValueKey('color-selected')), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Màu 13')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Màu 3')),
      isSemantics(isSelected: false, isButton: true, hasTapAction: true),
    );
    await tester.tap(find.bySemanticsLabel('Màu 3'));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Màu 3')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    expect(find.byKey(const ValueKey('color-selected')), findsOneWidget);
    // Nhãn đọc của icon vẫn là "Biểu tượng N" (BUG-008).
    expect(find.byTooltip('Biểu tượng 1'), findsOneWidget);
    handle.dispose();
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt: tiêu đề nhóm màu primary, "Xóa toàn bộ dữ liệu" màu '
      'lỗi (5.1, 5.2)', (tester) async {
    final db = await pumpApp(tester);
    await _open(tester, '/settings');
    final scheme = Theme.of(tester.element(find.text('Giao diện'))).colorScheme;
    for (final title in ['Giao diện', 'Ngôn ngữ']) {
      expect(
        tester.widget<Text>(find.text(title)).style?.color,
        scheme.primary,
      );
    }
    await tester.scrollUntilVisible(find.text('Xóa toàn bộ dữ liệu'), 200);
    for (final title in ['Bảo mật', 'Dữ liệu']) {
      expect(
        tester.widget<Text>(find.text(title)).style?.color,
        scheme.primary,
      );
    }
    final danger = find.text('Xóa toàn bộ dữ liệu');
    expect(
      tester.renderObject<RenderParagraph>(danger).text.style?.color,
      scheme.error,
    );
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt: cỡ chữ 200% thì nút chọn một xếp dọc (D-008)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = await pumpApp(tester);
    await _open(tester, '/settings');
    final system = tester.getTopLeft(find.text('Theo hệ thống'));
    final light = tester.getTopLeft(find.text('Sáng'));
    expect(light.dy, greaterThan(system.dy));
    expect(tester.takeException(), isNull);
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt: cỡ chữ 100% thì nút chọn một nằm ngang, "Theo hệ '
      'thống" một dòng (5.1)', (tester) async {
    // Đo bằng font thật của app; font mặc định của test rộng hơn nhiều.
    await tester.runAsync(_loadAppFont);
    final db = await pumpApp(tester);
    await _open(tester, '/settings');
    final system = find.text('Theo hệ thống');
    expect(
      tester.getTopLeft(find.text('Sáng')).dy,
      closeTo(tester.getTopLeft(system).dy, 1),
    );
    expect(tester.getSize(system).height, lessThan(24));
    await disposeApp(tester, db);
  });
}
