import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/home/range_calendar.dart';

import '../export_readers.dart';
import '../helpers.dart';

/// Giả bảng chia sẻ của hệ điều hành và thư mục tạm: ghi lại các file được
/// chia sẻ (AC-116: mở bảng chia sẻ, không xin quyền bộ nhớ).
List<String> _mockShareAndTemp(WidgetTester tester, Directory temp) {
  final shared = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => temp.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (call) async {
      final args = (call.arguments as Map).cast<String, Object?>();
      shared.addAll((args['paths'] as List? ?? const []).cast<String>());
      return 'dev.fluttercommunity.plus/share/unavailable';
    },
  );
  addTearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      null,
    );
  });
  return shared;
}

Future<void> _openExportRow(WidgetTester tester, String title) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  final row = find.text(title);
  await tester.dragUntilVisible(
    row,
    find.byType(ListView).first,
    const Offset(0, -300),
  );
  await tester.ensureVisible(row);
  await settle(tester);
  await tester.tap(row);
  await settle(tester);
}

/// Chờ file được dựng (isolate riêng, thời gian thật) và chia sẻ.
Future<void> _waitShared(WidgetTester tester, List<String> shared) async {
  for (var i = 0; i < 100 && shared.isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('Cài đặt → Xuất Excel: chọn kỳ đang xem rồi chia sẻ .xlsx', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('vigon-export');
    addTearDown(() => temp.deleteSync(recursive: true));
    final shared = _mockShareAndTemp(tester, temp);
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 155000,
      categoryId: 1,
      note: '=phở',
    );
    await _openExportRow(tester, 'Xuất Excel');
    expect(find.text('Xuất khoảng nào'), findsOneWidget);
    expect(find.textContaining('Kỳ đang xem · '), findsOneWidget);
    expect(find.text('Khoảng tùy chọn…'), findsOneWidget);
    await tester.tap(find.textContaining('Kỳ đang xem · '));
    // Vòng xoay "Đang tạo file…" quay tới khi xong: không pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đang tạo file…'), findsOneWidget);
    await _waitShared(tester, shared);
    await settle(tester);

    expect(shared, hasLength(1));
    expect(shared.single, endsWith('.xlsx'));
    final book = await tester.runAsync(
      () async => readXlsx(await File(shared.single).readAsBytes()),
    );
    final rows = book!['Khoản']!;
    expect(rows, hasLength(2));
    final note = rows[1].firstWhere((c) => c.ref.startsWith('L'));
    expect((note.value, note.type, note.quotePrefix), ('=phở', 's', true));
    expect(find.text('Đang tạo file…'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt → Xuất PDF: khoảng tùy chọn, font nhúng từ assets', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('vigon-export');
    addTearDown(() => temp.deleteSync(recursive: true));
    final shared = _mockShareAndTemp(tester, temp);
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 155000,
      categoryId: 1,
      date: '2026-11-02',
      note: 'Bún chả',
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 99000,
      categoryId: 1,
      date: '2026-11-03',
      note: 'Ngoài khoảng',
    );
    await _openExportRow(tester, 'Xuất PDF');
    await tester.tap(find.text('Khoảng tùy chọn…'));
    await settle(tester);
    final calendar = find.byType(RangeCalendarSheet);
    await tester.tap(find.descendant(of: calendar, matching: find.text('1')));
    await tester.pump();
    await tester.tap(find.descendant(of: calendar, matching: find.text('2')));
    await tester.pump();
    await tester.tap(
      find.descendant(of: calendar, matching: find.text('Áp dụng')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _waitShared(tester, shared);
    await settle(tester);

    expect(shared.single, endsWith('.pdf'));
    final text = await tester.runAsync(
      () async => extractPdfText(await File(shared.single).readAsBytes()),
    );
    final flat = text!.replaceAll(RegExp(r'\s+'), ' ');
    expect(flat, contains('Báo cáo thu chi'));
    expect(flat, contains('Bún chả'));
    expect(flat, isNot(contains('Ngoài khoảng')));
    await disposeApp(tester, db);
  });

  testWidgets('Cài đặt → Xuất PDF: đóng bảng phạm vi thì không xuất gì', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('vigon-export');
    addTearDown(() => temp.deleteSync(recursive: true));
    final shared = _mockShareAndTemp(tester, temp);
    final db = await pumpApp(tester);
    await _openExportRow(tester, 'Xuất PDF');
    expect(find.text('Xuất khoảng nào'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(find.text('Xuất khoảng nào'), findsNothing);
    expect(shared, isEmpty);
    await disposeApp(tester, db);
  });
}
