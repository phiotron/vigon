import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/currency_conversion.dart';
import 'package:vigon/src/features/settings/currency_picker.dart';

import '../helpers.dart';

/// Nguồn tỉ giá giả: trả bảng cho sẵn, hoặc ném lỗi; đếm số lần gọi.
class FakeRateSource implements ExchangeRateSource {
  FakeRateSource({this.table, this.error, this.pending});

  RateTable? table;
  ExchangeRateError? error;

  /// Có thì chờ cho tới khi test hoàn thành (xem trạng thái đang tải).
  Completer<void>? pending;
  int calls = 0;

  @override
  String get attribution => 'Rates By Exchange Rate API';

  @override
  Uri get homepage => Uri.parse('https://www.exchangerate-api.com');

  @override
  Future<RateTable> fetch() async {
    calls++;
    if (pending != null) await pending!.future;
    if (error != null) throw ExchangeRateException(error!);
    return table!;
  }
}

const usdTable = RateTable(
  base: 'USD',
  date: '2026-11-05',
  rates: {'USD': 1, 'VND': 25974, 'EUR': 0.89, 'IDR': 18132},
);

final sheet = find.byType(CurrencyPickerSheet);
final conversion = find.byType(CurrencyConversionDialog);

/// Mở Cài đặt → Tiền tệ → tìm [code] → chạm dòng đó.
Future<void> pickCurrency(
  WidgetTester tester,
  String code, {
  bool whileLoading = false,
}) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  // Cài đặt dựng lười: chữ 200% thì mục Tiền tệ chưa được dựng → cuộn tới.
  await tester.scrollUntilVisible(
    find.text('Tiền tệ'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tiền tệ'));
  await settle(tester);
  await tester.enterText(
    find.descendant(of: sheet, matching: find.byType(TextField)),
    code,
  );
  await settle(tester);
  await tester.tap(
    find
        .descendant(
          of: find.descendant(of: sheet, matching: find.byType(CurrencyRow)),
          matching: find.textContaining(code),
        )
        .first,
  );
  await flow(tester, whileLoading: whileLoading);
}

/// Như `settle` nhưng chịu được vòng xoay "đang tải" (chạy mãi nên
/// `pumpAndSettle` không dừng): pump theo bước cho tới khi hết vòng xoay, rồi
/// mới settle. [whileLoading] true thì dừng lại khi vẫn đang tải.
Future<void> flow(WidgetTester tester, {bool whileLoading = false}) async {
  final spinner = find.byType(CircularProgressIndicator);
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    // Vài nhịp đầu: chờ sheet đóng, đọc DB rồi mới mở hộp thoại.
    if (i >= 8 && (whileLoading || spinner.evaluate().isEmpty)) break;
  }
  if (spinner.evaluate().isNotEmpty) {
    expect(whileLoading, isTrue, reason: 'vẫn đang tải tỉ giá');
    return;
  }
  await settle(tester);
}

Future<int> amountOf(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => db.select(db.entries).getSingle()))!.amount;

Future<String> currencyOf(WidgetTester tester, AppDatabase db) async =>
    (await tester.runAsync(() => SettingsRepository(db).readCurrency()))!;

Future<AppDatabase> start(WidgetTester tester, FakeRateSource source) async {
  final db = await pumpApp(
    tester,
    overrides: [exchangeRateSourceProvider.overrideWithValue(source)],
  );
  await tester.runAsync(() => SettingsRepository(db).ensureCurrency(defaultCode: 'VND'));
  await insertEntry(
    tester,
    db,
    type: EntryType.expense,
    amount: 155000,
    categoryId: 1,
  );
  return db;
}

Finder inDialog(Finder f) => find.descendant(of: conversion, matching: f);

void main() {
  testWidgets('tải tỉ giá → xác nhận → Quy đổi: mọi số tiền đổi sang USD '
      '(AC-21, AC-70)', (tester) async {
    final source = FakeRateSource(table: usdTable, pending: Completer());
    final db = await start(tester, source);
    await pickCurrency(tester, 'USD', whileLoading: true);
    // Đang tải.
    expect(inDialog(find.text('Đang tải tỉ giá…')), findsOneWidget);
    expect(await currencyOf(tester, db), 'VND');
    source.pending!.complete();
    await flow(tester);
    expect(inDialog(find.text('Quy đổi sang USD?')), findsOneWidget);
    expect(inDialog(findPlainText('1 VND = 0,0000385 USD')), findsOneWidget);
    expect(inDialog(findPlainText('1 USD = 25.974 VND')), findsOneWidget);
    expect(inDialog(find.text('Rates By Exchange Rate API')), findsOneWidget);
    expect(
      inDialog(find.textContaining('Tỉ giá cập nhật ngày')),
      findsOneWidget,
    );
    expect(inDialog(find.textContaining('Ví dụ: 155.000')), findsOneWidget);
    expect(
      inDialog(find.textContaining('Nên xuất bản sao lưu')),
      findsOneWidget,
    );
    // Bảng tỉ giá được lưu để lần sau mất mạng vẫn điền sẵn.
    expect(
      await tester.runAsync(() => SettingsRepository(db).readRateTable()),
      isNotNull,
    );
    await tester.tap(inDialog(find.text('Quy đổi')));
    await settle(tester);
    expect(conversion, findsNothing);
    expect(await currencyOf(tester, db), 'USD');
    // 155.000 ₫ / 25.974 = 5,9675... US$ → 597 cent.
    expect(await amountOf(tester, db), 597);
    expect(find.text('Đã quy đổi mọi số tiền sang USD'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('Hủy ở hộp xác nhận thì không đổi gì', (tester) async {
    final db = await start(tester, FakeRateSource(table: usdTable));
    await pickCurrency(tester, 'USD');
    expect(inDialog(find.text('Quy đổi sang USD?')), findsOneWidget);
    await tester.tap(inDialog(find.text('Hủy')));
    await settle(tester);
    expect(conversion, findsNothing);
    expect(await currencyOf(tester, db), 'VND');
    expect(await amountOf(tester, db), 155000);
    await disposeApp(tester, db);
  });

  testWidgets('Hủy khi đang tải thì không đổi gì', (tester) async {
    final source = FakeRateSource(table: usdTable, pending: Completer());
    final db = await start(tester, source);
    await pickCurrency(tester, 'USD', whileLoading: true);
    await tester.tap(inDialog(find.text('Hủy')));
    await flow(tester);
    source.pending!.complete();
    await settle(tester);
    expect(conversion, findsNothing);
    expect(await currencyOf(tester, db), 'VND');
    await disposeApp(tester, db);
  });

  testWidgets('mất mạng → báo rõ, nhập tỉ giá tay (đổi chiều) → quy đổi '
      '(AC-71)', (tester) async {
    final source = FakeRateSource(error: ExchangeRateError.offline);
    final db = await start(tester, source);
    await pickCurrency(tester, 'USD');
    expect(inDialog(find.text('Không tải được tỉ giá')), findsOneWidget);
    expect(
      inDialog(find.textContaining('Kiểm tra kết nối mạng')),
      findsOneWidget,
    );
    expect(inDialog(find.text('1 VND = ? USD')), findsOneWidget);
    // Chưa nhập mà bấm Tiếp tục → báo lỗi ô.
    await tester.tap(inDialog(find.text('Tiếp tục')));
    await flow(tester);
    expect(inDialog(find.text('Nhập tỉ giá lớn hơn 0')), findsOneWidget);
    await tester.tap(inDialog(find.byTooltip('Đổi chiều tỉ giá')));
    await settle(tester);
    expect(inDialog(find.text('1 USD = ? VND')), findsOneWidget);
    await tester.enterText(inDialog(find.byType(TextField)), '25.000');
    await tester.tap(inDialog(find.text('Tiếp tục')));
    await settle(tester);
    expect(inDialog(find.text('Tỉ giá bạn tự nhập')), findsOneWidget);
    expect(inDialog(findPlainText('1 VND = 0,00004 USD')), findsOneWidget);
    await tester.tap(inDialog(find.text('Quy đổi')));
    await settle(tester);
    expect(await currencyOf(tester, db), 'USD');
    expect(await amountOf(tester, db), 620); // 155.000 / 25.000 = 6,20
    // Tỉ giá tự nhập được lưu để lần sau điền sẵn.
    final saved = await tester.runAsync(
      () => SettingsRepository(db).readManualRate('VND', 'USD'),
    );
    expect(saved!.rate, ExchangeRate.tryParse('0.00004'));
    await disposeApp(tester, db);
  });

  testWidgets('mất mạng có bảng tỉ giá cũ → điền sẵn tỉ giá gần nhất; Thử lại '
      'gọi lại nguồn', (tester) async {
    final source = FakeRateSource(error: ExchangeRateError.offline);
    final db = await start(tester, source);
    await tester.runAsync(() => SettingsRepository(db).setRateTable(usdTable));
    await pickCurrency(tester, 'USD');
    // Tỉ giá < 1 nên hiện chiều ngược lại cho dễ đọc.
    expect(inDialog(find.text('1 USD = ? VND')), findsOneWidget);
    final field = tester.widget<TextField>(inDialog(find.byType(TextField)));
    expect(field.controller!.text, '25.974');
    expect(inDialog(find.textContaining('Đã điền tỉ giá gần nhất')), findsOne);
    expect(source.calls, 1);
    source
      ..error = null
      ..table = usdTable;
    await tester.tap(inDialog(find.text('Thử lại')));
    await flow(tester);
    expect(source.calls, 2);
    expect(inDialog(find.text('Quy đổi sang USD?')), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('nguồn không có tỉ giá cho cặp → nhập tay, không có Thử lại', (
    tester,
  ) async {
    final db = await start(tester, FakeRateSource(table: usdTable));
    await pickCurrency(tester, 'KPW');
    expect(
      inDialog(
        find.text('Không có tỉ giá từ VND sang KPW. Hãy tự nhập tỉ giá.'),
      ),
      findsOneWidget,
    );
    expect(inDialog(find.text('Thử lại')), findsNothing);
    await tester.tap(inDialog(find.text('Hủy')));
    await settle(tester);
    expect(await currencyOf(tester, db), 'VND');
    await disposeApp(tester, db);
  });

  testWidgets(
    'Dùng tỉ giá khác ở hộp xác nhận → ô nhập điền sẵn tỉ giá vừa tải',
    (tester) async {
      final db = await start(tester, FakeRateSource(table: usdTable));
      await pickCurrency(tester, 'USD');
      await tester.ensureVisible(inDialog(find.text('Dùng tỉ giá khác')));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.text('Dùng tỉ giá khác')));
      await settle(tester);
      expect(inDialog(find.text('Nhập tỉ giá')), findsOneWidget);
      expect(inDialog(find.text('Không tải được tỉ giá')), findsNothing);
      final field = tester.widget<TextField>(inDialog(find.byType(TextField)));
      expect(field.controller!.text, '25.974');
      await disposeApp(tester, db);
    },
  );

  testWidgets('vượt 10^12 sau quy đổi → báo lỗi, không đổi gì', (tester) async {
    final db = await start(tester, FakeRateSource(table: usdTable));
    await insertEntry(
      tester,
      db,
      type: EntryType.income,
      amount: 900000000000, // 900 tỉ ₫
      categoryId: 1,
    );
    // 1 VND = 0,698 IDR, IDR 2 chữ số → 900 tỉ × 69,8 > 10^12.
    await pickCurrency(tester, 'IDR');
    await tester.tap(inDialog(find.text('Quy đổi')));
    await settle(tester);
    expect(find.text('Số tiền quá lớn'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await settle(tester);
    expect(await currencyOf(tester, db), 'VND');
    final amounts = await tester.runAsync(
      () async => [for (final e in await db.select(db.entries).get()) e.amount],
    );
    expect(amounts, [155000, 900000000000]);
    await disposeApp(tester, db);
  });

  group('trợ năng hộp quy đổi (S-31)', () {
    Future<List<String>> audit(WidgetTester tester, String where) async {
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

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      for (final scale in [1.0, 2.0]) {
        for (final offline in [false, true]) {
          final name =
              '${offline ? 'nhập tay' : 'xác nhận'} · ${theme.name} · '
              '${(scale * 100).round()}%';
          testWidgets(name, (tester) async {
            final handle = tester.ensureSemantics();
            final drawErrors = <String>[];
            final previous = FlutterError.onError;
            FlutterError.onError = (d) =>
                drawErrors.add(d.exceptionAsString().split('\n').first);
            final source = offline
                ? FakeRateSource(error: ExchangeRateError.offline)
                : FakeRateSource(table: usdTable);
            final db = await start(tester, source);
            try {
              if (offline) {
                await tester.runAsync(
                  () => SettingsRepository(db).setRateTable(usdTable),
                );
              }
              await tester.runAsync(
                () => SettingsRepository(db).setThemeMode(theme),
              );
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              await settle(tester);
              await pickCurrency(tester, 'USD');
              expect(conversion, findsOneWidget);
              final problems = await audit(tester, name);
              problems.addAll(drawErrors.map((e) => '$name · lỗi vẽ: $e'));
              expect(problems, isEmpty, reason: problems.join('\n'));
              // Nút chính vẫn chạm được (không bị đẩy khỏi màn).
              final action = inDialog(
                find.text(offline ? 'Tiếp tục' : 'Quy đổi'),
              );
              expect(action.hitTestable(), findsOneWidget);
            } finally {
              FlutterError.onError = previous;
            }
            handle.dispose();
            await disposeApp(tester, db);
          });
        }
      }
    }
  });
}
