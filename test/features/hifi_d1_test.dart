// Hi-Fi P1/P2 cho màn chính, ghi khoản, các khoản và tìm kiếm (phiên con D1):
// SCR-01 (A01, A04), SCR-07, SCR-10 (rãnh 24), SCR-11 (A06, A07, A21), chip
// tài khoản đang lọc (§10.1 #1), thanh Số dư có tên kỳ.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/entries/entry_search.dart';
import 'package:vigon/src/providers.dart';
import 'package:vigon/src/ui/category_avatar.dart';
import 'package:vigon/src/ui/category_grid.dart';
import 'package:vigon/src/ui/spending_ring.dart';

import '../helpers.dart';

/// Thêm danh mục chi cho đủ [total] (mặc định có 10).
Future<void> addExpenseCategories(
  WidgetTester tester,
  AppDatabase db,
  int total,
) => tester.runAsync(() async {
  final repo = CategoryRepository(db);
  for (var i = 11; i <= total; i++) {
    await repo.add(
      type: CategoryType.expense,
      name: 'Mục $i',
      icon: 'pets',
      color: 0xFF2E7D32,
    );
  }
});

/// Ô danh mục quanh vòng ở màn chính (không tính ô ⋯).
Finder ringIcons() =>
    find.byWidgetPredicate((w) => w is CategoryAvatar && w.onTap != null);

void main() {
  testWidgets('SCR-01 (A01): 25 danh mục ở 360 dp → 16 ô + ô ⋯ thứ 17', (
    tester,
  ) async {
    final db = memoryDatabase();
    await addExpenseCategories(tester, db, 25);
    await pumpApp(tester, db: db);
    expect(ringIcons(), findsNWidgets(16));
    expect(find.byType(MoreCategoriesAvatar), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('SCR-07: ô ⋯ mở lưới đủ 25 danh mục; chọn → Khoản chi mới đã '
      'chọn sẵn, chưa lưu', (tester) async {
    final db = memoryDatabase();
    await addExpenseCategories(tester, db, 25);
    await pumpApp(tester, db: db);
    await tester.tap(find.byType(MoreCategoriesAvatar));
    await settle(tester);
    final grid = find.byType(CategoryGrid);
    expect(grid, findsOneWidget);
    expect(find.text('Chọn danh mục'), findsOneWidget);
    // Bảng cao tối đa = màn − thanh trạng thái − 40.
    expect(tester.getSize(grid).height, lessThanOrEqualTo(800 - 40));
    await tester.scrollUntilVisible(
      find.text('Mục 25'),
      100,
      scrollable: find.descendant(of: grid, matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('Mục 25'));
    await settle(tester);
    expect(find.text('Khoản chi mới'), findsOneWidget);
    expect(find.text('Mục 25'), findsOneWidget); // chip danh mục
    expect(find.text('Lưu'), findsOneWidget);
    final rows = await tester.runAsync(() => db.select(db.entries).get());
    expect(rows, isEmpty);
    await disposeApp(tester, db);
  });

  testWidgets('thanh Số dư có tên kỳ, đọc "Số dư: X, tên kỳ" (§10.1 #2)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    // Đầu kỳ + dòng dưới "Số dư" (mockup v4: "… · theo VND").
    expect(find.text('Tháng 11 năm 2026'), findsOneWidget);
    expect(find.text('Tháng 11 năm 2026 · theo VND'), findsOneWidget);
    expect(findSemanticsLabel('Số dư: 0 ₫, Tháng 11 năm 2026 · theo VND'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('kỳ trống: lời nhắc + mũi tên trong vòng (§10.1 #16)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    expect(find.text('Ghi khoản chi đầu tiên'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('A04 (200%): tổng thu/chi ra danh sách dưới vòng, nút − / + '
      'cao ≥ 96, không tràn', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = memoryDatabase();
    await addExpenseCategories(tester, db, 25);
    await pumpApp(tester, db: db);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 155000,
      categoryId: 1,
    );
    final ring = tester.widget<SpendingRing>(find.byType(SpendingRing));
    expect(ring.showTotals, isFalse);
    expect(find.text('Thu'), findsWidgets);
    expect(findPlainText('155.000 ₫'), findsWidgets);
    final expense = find.bySemanticsLabel('Thêm khoản chi');
    expect(tester.getSize(expense).height, greaterThanOrEqualTo(96));
    expect(tester.takeException(), isNull);
    await disposeApp(tester, db);
  });

  testWidgets('chip tài khoản đang lọc trên thanh tiêu đề; chọn "Tất cả tài '
      'khoản" bỏ lọc (mockup v4 SCR-01 filtered)', (tester) async {
    final db = memoryDatabase();
    final card = await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ'),
    );
    await pumpApp(tester, db: db);
    expect(find.byTooltip('Tài khoản: Thẻ'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(accountFilterProvider.notifier).select(card);
    await settle(tester);
    expect(find.byTooltip('Tài khoản: Thẻ'), findsOneWidget);
    expect(find.text('Thẻ'), findsOneWidget);
    await tester.tap(find.byTooltip('Tài khoản: Thẻ'));
    await settle(tester);
    await tester.tap(find.text('Tất cả tài khoản'));
    await settle(tester);
    expect(container.read(accountFilterProvider), isNull);
    expect(find.byTooltip('Tài khoản: Thẻ'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('SCR-10: số tiền khoản thẳng mép phải với tổng danh mục '
      '(rãnh 24, §10.1 #12)', (tester) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 45000,
      categoryId: 1,
      note: 'Phở bò',
    );
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 20000,
      categoryId: 1,
      note: 'Trà đá',
    );
    await tester.tap(find.byTooltip('Các khoản'));
    await settle(tester);
    await tester.tap(find.text('Ăn uống'));
    await settle(tester);
    final total = tester.getTopRight(findPlainText('65.000 ₫').last).dx;
    final child = tester.getTopRight(findPlainText('45.000 ₫')).dx;
    expect(child, moreOrLessEquals(total, epsilon: 0.5));
    await disposeApp(tester, db);
  });

  group('SCR-11 tìm kiếm', () {
    Future<AppDatabase> openSearch(WidgetTester tester) async {
      final db = await pumpApp(tester);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 155000,
        categoryId: 1,
        note: 'Cà phê hạt',
        date: '2026-11-01',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.income,
        amount: 1550000,
        categoryId: 11,
        note: 'Thưởng',
        date: '2026-11-02',
      );
      await tester.tap(find.byTooltip('Các khoản'));
      await settle(tester);
      await tester.tap(find.byTooltip('Tìm'));
      await settle(tester);
      return db;
    }

    List<TextSpan> marked(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(SearchResultTile),
          matching: find.byType(Text),
        ),
      ))
        if (t.textSpan != null)
          ...((t.textSpan! as TextSpan).children ?? const <InlineSpan>[])
              .whereType<TextSpan>()
              .where((s) => s.style?.fontWeight == FontWeight.w600),
    ];

    testWidgets('truy vấn trống (A06): cặp chip, mới nhất trước, không có '
        'dòng tổng; dòng ≥ 72', (tester) async {
      final db = await openSearch(tester);
      expect(find.text('Tháng 11 năm 2026'), findsOneWidget); // chip kỳ
      expect(find.text('Tất cả thời gian'), findsOneWidget);
      expect(find.textContaining('tổng'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Thưởng')).dy,
        lessThan(tester.getTopLeft(find.text('Cà phê hạt')).dy),
      );
      expect(
        tester.getSize(find.byType(SearchResultTile).first).height,
        greaterThanOrEqualTo(72),
      );
      // Dấu − chi / + thu (A07).
      Finder rich(String text) => find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.textSpan != null &&
            plain(w.textSpan!.toPlainText()) == text,
      );
      expect(rich('−155.000 ₫'), findsOneWidget);
      expect(rich('+1.550.000 ₫'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('tô chữ khớp không dấu; số tiền vắt qua dấu ngăn cách (A07)', (
      tester,
    ) async {
      final db = await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'ca phe');
      await settle(tester);
      expect(marked(tester).map((s) => s.text), contains('Cà phê'));
      expect(find.byTooltip('Xóa nội dung tìm'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '155');
      await settle(tester);
      final hits = marked(tester).map((s) => plain(s.text!)).toList();
      expect(hits, containsAll(['155', '1.55']));
      expect(findPlainText('2 khoản · tổng 1.395.000 ₫'), findsOneWidget);
      await disposeApp(tester, db);
    });

    testWidgets('không khớp: icon + "Không có khoản nào khớp"', (tester) async {
      final db = await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'karaoke');
      await settle(tester);
      expect(find.text('Không có khoản nào khớp'), findsOneWidget);
      expect(find.byType(SearchResultTile), findsNothing);
      await disposeApp(tester, db);
    });
  });

  test('textMatches / amountMatches', () {
    expect(textMatches('Cà phê sữa', 'ca phe'), [(0, 6)]);
    expect(textMatches('Tiền nhà', 'NHA'), [(5, 8)]);
    expect(amountMatches('1.550.000 ₫', '155'), [(0, 4)]);
    expect(amountMatches('1.550.000 ₫', 'abc'), isEmpty);
  });
}
