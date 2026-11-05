import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

Future<void> openCategories(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  await tester.tap(find.text('Danh mục'));
  await settle(tester);
}

Future<void> openEntries(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Các khoản'));
  await settle(tester);
}

Future<int?> budgetOf(WidgetTester tester, AppDatabase db, int id) => tester
    .runAsync(
      () =>
          (db.select(db.categories)..where((c) => c.id.equals(id))).getSingle(),
    )
    .then((c) => c!.budget);

void main() {
  testWidgets('đặt hạn mức trong bảng sửa danh mục; ≤ 0 báo lỗi; xóa ô là bỏ '
      '(AC-54)', (tester) async {
    final db = await pumpApp(tester);
    await openCategories(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    expect(find.text('Ngân sách tháng của danh mục'), findsOneWidget);

    final field = find.byKey(const ValueKey('category-budget'));
    await tester.enterText(field, '0');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    expect(await budgetOf(tester, db, 1), isNull);

    await tester.enterText(field, '500000');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(await budgetOf(tester, db, 1), 500000);

    // Mở lại: ô hiện hạn mức đang có; xóa trống rồi lưu là bỏ hạn mức.
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('category-budget')))
          .controller!
          .text,
      '500000',
    );
    await tester.enterText(find.byKey(const ValueKey('category-budget')), '');
    await tester.tap(find.text('Lưu'));
    await settle(tester);
    expect(await budgetOf(tester, db, 1), isNull);
    await disposeApp(tester, db);
  });

  testWidgets('danh mục thu không có ô hạn mức (AC-54)', (tester) async {
    final db = await pumpApp(tester);
    await openCategories(tester);
    await tester.tap(find.text('Thu').last);
    await settle(tester);
    await tester.tap(find.text('Lương'));
    await settle(tester);
    expect(find.text('Sửa danh mục'), findsOneWidget);
    expect(find.text('Ngân sách tháng của danh mục'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('ở màn Các khoản: thanh tiến độ, vượt thì màu lỗi và chữ "Vượt" '
      '(AC-54)', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => CategoryRepository(db).setBudget(1, 100000));
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 40000,
      categoryId: 1,
    );
    // Danh mục khác không có hạn mức: không có thanh.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 9000,
      categoryId: 2,
    );
    await openEntries(tester);
    expect(findPlainText('Đã chi 40.000 ₫ / 100.000 ₫'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Vượt'), findsNothing);
    var bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.4, 1e-9));

    // Chi thêm cho vượt hạn mức: chữ "Vượt 50.000 ₫" và màu lỗi.
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 110000,
      categoryId: 1,
    );
    final text = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').contains('Vượt'),
    );
    expect(text, findsOneWidget);
    expect(plain(tester.widget<Text>(text).data!), contains('Vượt 50.000 ₫'));
    final error = Theme.of(tester.element(text)).colorScheme.error;
    expect(tester.widget<Text>(text).style?.color, error);
    bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect((bar.value, bar.color), (1.0, error));
    await disposeApp(tester, db);
  });

  testWidgets('thanh tính theo THÁNG HIỆN TẠI, không đổi theo kỳ đang xem '
      '(AC-54)', (tester) async {
    final db = memoryDatabase();
    await tester.runAsync(() => CategoryRepository(db).setBudget(1, 100000));
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 30000,
      categoryId: 1,
      date: '2026-11-02',
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 70000,
      categoryId: 1,
      date: '2026-10-20',
    );
    // Về tháng trước trên màn chính rồi mở Các khoản: kỳ đang xem là tháng 10
    // (chi 70.000) nhưng thanh vẫn là chi tháng 11 (30.000).
    await tester.tap(find.byTooltip('Kỳ trước'));
    await settle(tester);
    await openEntries(tester);
    expect(findPlainText('70.000 ₫'), findsWidgets);
    expect(
      findPlainText('Tháng này: Đã chi 30.000 ₫ / 100.000 ₫'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });
}
