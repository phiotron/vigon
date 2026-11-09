import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

/// Khoản 0 do quy đổi tiền tệ (D-029): mở ra giữ nguyên số tiền thì vẫn lưu
/// được; AC-05 chỉ chặn số 0 do người dùng gõ.
void main() {
  Future<int> insertZero(
    WidgetTester tester,
    AppDatabase db, {
    EntryType type = EntryType.expense,
    int? toAccountId,
  }) async => (await tester.runAsync(
    () => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: type,
            amount: 0,
            amountMicro: const Value(400000), // 0,4 ₫, hiện 0 ₫
            categoryId: Value(type == EntryType.transfer ? null : 1),
            accountId: 1,
            toAccountId: Value(toAccountId),
            date: '2026-11-03',
            note: const Value('nhỏ'),
            // D-037: số gốc + tiền tệ, khớp Tiền tệ chính VND của test.
            currency: const Value('VND'),
            originalAmount: const Value(0),
            toCurrency: Value(type == EntryType.transfer ? 'VND' : null),
            toOriginalAmount: Value(type == EntryType.transfer ? 0 : null),
            toAmount: Value(type == EntryType.transfer ? 0 : null),
          ),
        ),
  ))!;

  Future<void> open(WidgetTester tester, String path) async {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);
    await settle(tester);
  }

  Future<Entry> read(WidgetTester tester, AppDatabase db, int id) async =>
      (await tester.runAsync(
        () =>
            (db.select(db.entries)..where((e) => e.id.equals(id))).getSingle(),
      ))!;

  testWidgets('sửa khoản 0 không đổi số tiền: lưu được, giữ số chính xác', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    final id = await insertZero(tester, db);
    await open(tester, '/entry/$id');
    expect(find.text('Sửa khoản'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'nhỏ 2');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsNothing);
    expect(find.text('Sửa khoản'), findsNothing);
    final e = await read(tester, db, id);
    expect((e.amount, e.amountMicro, e.note), (0, 400000, 'nhỏ 2'));
    await disposeApp(tester, db);
  });

  testWidgets('khoản mới gõ 0 vẫn bị chặn (AC-05)', (tester) async {
    final db = await pumpApp(tester);
    await insertZero(tester, db);
    await open(tester, '/entry/new?type=expense&category=1');
    await tester.tap(find.widgetWithText(TextButton, '0'));
    await tester.pump();
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows, hasLength(1));
    await disposeApp(tester, db);
  });

  testWidgets('sửa chuyển tiền 0 không đổi số tiền: lưu được', (tester) async {
    final db = await pumpApp(tester);
    final second = (await tester.runAsync(
      () => db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: const Value('Thẻ'))),
    ))!;
    final id = await insertZero(
      tester,
      db,
      type: EntryType.transfer,
      toAccountId: second,
    );
    await open(tester, '/transfer/$id');
    await tester.enterText(find.byType(TextField).last, 'nhỏ 3');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsNothing);
    final e = await read(tester, db, id);
    expect((e.amount, e.amountMicro, e.note), (0, 400000, 'nhỏ 3'));
    await disposeApp(tester, db);
  });
}
