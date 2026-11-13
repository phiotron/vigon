import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/entries/entry_filter_sheet.dart';
import 'package:vigon/src/features/home/range_calendar.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';

/// Chip danh mục trong bảng Lọc (tên danh mục cũng có thể xuất hiện ở danh
/// sách khoản phía sau bảng).
Finder _categoryChip(String name) => find.descendant(
  of: find.byType(EntryFilterSheet),
  matching: find.text(name),
);

/// Ghi các khoản mẫu: id danh mục theo seed (1 Ăn uống, 2 Đi lại, 5 Mua sắm,
/// 12 Lương — hai danh mục lãi thêm ở schema 8 đẩy id danh mục thu lên 12).
Future<void> _seedEntries(WidgetTester tester, AppDatabase db) async {
  Future<void> add(
    EntryType type,
    int amount,
    int category,
    String date,
    String note,
  ) => insertEntry(
    tester,
    db,
    type: type,
    amount: amount,
    categoryId: category,
    date: date,
    note: note,
  );
  await add(EntryType.expense, 150000, 1, '2026-11-02', 'Phở');
  await add(EntryType.expense, 30000, 2, '2026-11-02', 'Xe buýt');
  await add(EntryType.expense, 120000, 2, '2026-11-01', 'Grab');
  await add(EntryType.expense, 90000, 5, '2026-11-02', 'Áo');
  await add(EntryType.income, 9000000, 12, '2026-11-01', 'Lương');
  await add(EntryType.expense, 100000, 1, '2026-10-20', 'Cơm cũ');
}

Future<void> _openFilter(WidgetTester tester, {String tooltip = 'Lọc'}) async {
  await tester.tap(find.byTooltip('Các khoản'));
  await settle(tester);
  await tester.tap(find.byTooltip(tooltip));
  await settle(tester);
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pump();
}

void main() {
  testWidgets('lọc số tiền + danh mục, chip gỡ được, Xóa lọc (AC-115)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _seedEntries(tester, db);
    await _openFilter(tester);

    await _enter(tester, 'filter-min', '50000');
    await _enter(tester, 'filter-max', '200000');
    await tester.tap(_categoryChip('Ăn uống'));
    await tester.tap(_categoryChip('Đi lại'));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);

    // Đúng các khoản thoả cả số tiền lẫn danh mục, danh sách phẳng.
    expect(find.text('Phở'), findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
    for (final other in ['Xe buýt', 'Áo', 'Lương', 'Cơm cũ']) {
      expect(find.text(other), findsNothing, reason: other);
    }
    expect(findPlainText('2 khoản · chi 270.000 ₫ · thu 0 ₫'), findsOneWidget);
    // Mỗi điều kiện một chip: số tiền + từng danh mục.
    expect(find.byKey(const ValueKey('chip-amount')), findsOneWidget);
    expect(find.byKey(const ValueKey('chip-category-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chip-category-2')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('chip-amount')),
        matching: find.byWidgetPredicate(
          (w) => w is Text && plain(w.data ?? '') == '50.000 ₫ – 200.000 ₫',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Xóa lọc'), findsOneWidget);

    // Gỡ chip số tiền: còn lọc danh mục, "Xe buýt" 30.000 hiện ra.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('chip-amount')),
        matching: find.byIcon(Symbols.close_rounded),
      ),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('chip-amount')), findsNothing);
    expect(find.text('Xe buýt'), findsOneWidget);
    expect(find.text('Áo'), findsNothing);
    expect(findPlainText('3 khoản · chi 300.000 ₫ · thu 0 ₫'), findsOneWidget);

    // Xóa lọc: về danh sách thường theo nhóm danh mục.
    await tester.tap(find.text('Xóa lọc'));
    await settle(tester);
    expect(find.text('Số dư'), findsOneWidget);
    expect(find.text('Xóa lọc'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('chọn cả danh mục thu, loại chuyển tiền, thu hiện ở dòng tổng', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _seedEntries(tester, db);
    await insertEntry(
      tester,
      db,
      type: EntryType.transfer,
      amount: 9000000,
      accountId: 1,
      toAccountId: 1,
      date: '2026-11-01',
      note: 'Chuyển ví',
    );
    await _openFilter(tester);
    await tester.tap(_categoryChip('Lương'));
    await tester.tap(_categoryChip('Mua sắm'));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);
    expect(find.text('Lương'), findsWidgets);
    expect(find.text('Áo'), findsOneWidget);
    expect(find.text('Chuyển ví'), findsNothing);
    expect(
      findPlainText('2 khoản · chi 90.000 ₫ · thu 9.000.000 ₫'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  testWidgets('"Từ" lớn hơn "Đến" báo lỗi dưới ô và không áp dụng', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _seedEntries(tester, db);
    await _openFilter(tester);
    await _enter(tester, 'filter-min', '200000');
    await _enter(tester, 'filter-max', '50000');
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);
    expect(find.text('“Từ” không được lớn hơn “Đến”'), findsOneWidget);
    expect(find.byType(EntryFilterSheet), findsOneWidget);
    // Sửa lại thì áp dụng được.
    await _enter(tester, 'filter-min', '100000');
    await _enter(tester, 'filter-max', '200000');
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);
    expect(find.byType(EntryFilterSheet), findsNothing);
    expect(find.text('Phở'), findsOneWidget);
    expect(find.text('Grab'), findsOneWidget);
    expect(find.text('Xe buýt'), findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('khoảng ngày thay kỳ đang xem; kết hợp với tìm kiếm', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _seedEntries(tester, db);
    // Đang xem tháng 10: chỉ có "Cơm cũ".
    await tester.tap(find.byTooltip('Kỳ trước'));
    await settle(tester);
    await _openFilter(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('filter-dates')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('filter-dates')));
    await settle(tester);
    // Lịch của kỳ hiện tại (tháng 11): chọn 01–02/11.
    final calendar = find.byType(RangeCalendarSheet);
    expect(calendar, findsOneWidget);
    await tester.tap(find.descendant(of: calendar, matching: find.text('1')));
    await tester.pump();
    await tester.tap(find.descendant(of: calendar, matching: find.text('2')));
    await tester.pump();
    await tester.tap(
      find.descendant(of: calendar, matching: find.text('Áp dụng')),
    );
    await settle(tester);
    expect(calendar, findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Áp dụng'));
    await settle(tester);

    expect(find.byKey(const ValueKey('chip-dates')), findsOneWidget);
    for (final shown in ['Phở', 'Xe buýt', 'Grab', 'Áo', 'Lương']) {
      expect(find.text(shown), findsOneWidget, reason: shown);
    }
    expect(find.text('Cơm cũ'), findsNothing);
    expect(
      findPlainText('5 khoản · chi 390.000 ₫ · thu 9.000.000 ₫'),
      findsOneWidget,
    );

    // Kết hợp VÀ với tìm kiếm F-15.
    await tester.tap(find.byTooltip('Tìm'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'grab');
    await settle(tester);
    expect(find.text('Grab'), findsOneWidget);
    expect(find.text('Phở'), findsNothing);
    expect(findPlainText('1 khoản · chi 120.000 ₫ · thu 0 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('lọc kết hợp VÀ với tìm kiếm và lọc tài khoản (AC-115)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _seedEntries(tester, db);
    final card = await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', currency: 'VND'),
    );
    // Cùng danh mục, cùng khoảng tiền nhưng ở tài khoản "Thẻ".
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 80000,
      categoryId: 1,
      accountId: card!,
      date: '2026-11-02',
      note: 'Phở thẻ',
    );
    await _openFilter(tester);
    await _enter(tester, 'filter-min', '50000');
    await tester.tap(_categoryChip('Ăn uống'));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await settle(tester);
    expect(find.text('Phở'), findsOneWidget);
    expect(find.text('Phở thẻ'), findsOneWidget);
    expect(findPlainText('2 khoản · chi 230.000 ₫ · thu 0 ₫'), findsOneWidget);

    // Lọc tài khoản "Thẻ": chỉ còn khoản của thẻ.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(accountFilterProvider.notifier).select(card);
    await settle(tester);
    expect(find.text('Phở'), findsNothing);
    expect(find.text('Phở thẻ'), findsOneWidget);
    expect(findPlainText('1 khoản · chi 80.000 ₫ · thu 0 ₫'), findsOneWidget);

    // Về mọi tài khoản + tìm "phở": cả hai; tìm "thẻ": một.
    container.read(accountFilterProvider.notifier).select(null);
    await settle(tester);
    await tester.tap(find.byTooltip('Tìm'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'thẻ');
    await settle(tester);
    expect(find.text('Phở'), findsNothing);
    expect(findPlainText('1 khoản · chi 80.000 ₫ · thu 0 ₫'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('giao diện tiếng Anh: nút Filter, chip, dòng tổng', (
    tester,
  ) async {
    final db = await pumpApp(tester, localeCode: 'en');
    await _seedEntries(tester, db);
    await tester.tap(find.byTooltip('Records'));
    await settle(tester);
    await tester.tap(find.byTooltip('Filter'));
    await settle(tester);
    expect(find.text('Amount range'), findsOneWidget);
    await _enter(tester, 'filter-min', '100000');
    await tester.tap(find.text('Apply'));
    await settle(tester);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.textContaining('From '), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            plain(w.data ?? '').startsWith('3 records · spent ') &&
            plain(w.data!).contains(' · income '),
      ),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('bảng lọc và kết quả đạt accessibility · ${theme.name} · '
          'cỡ chữ ${(scale * 100).round()}%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();
        final db = memoryDatabase();
        await tester.runAsync(() => SettingsRepository(db).setThemeMode(theme));
        await pumpApp(tester, db: db);
        await _seedEntries(tester, db);
        await _openFilter(tester);

        final problems = <String>[];
        Future<void> audit(String where) async {
          for (final (name, guideline) in [
            ('vùng chạm', androidTapTargetGuideline),
            ('nhãn', labeledTapTargetGuideline),
            ('tương phản', textContrastGuideline),
          ]) {
            final r = await guideline.evaluate(tester);
            if (!r.passed) problems.add('$where · $name: ${r.reason}');
          }
        }

        await audit('bảng lọc');
        await _enter(tester, 'filter-min', '50000');
        await tester.tap(_categoryChip('Ăn uống'));
        await tester.tap(_categoryChip('Đi lại'));
        await tester.pump();
        await tester.ensureVisible(find.text('Áp dụng'));
        await tester.tap(find.text('Áp dụng'));
        await settle(tester);
        await audit('kết quả lọc');
        expect(problems, isEmpty, reason: problems.join('\n'));
        expect(tester.takeException(), isNull);
        handle.dispose();
        await disposeApp(tester, db);
      });
    }
  }
}
