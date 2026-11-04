import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/category_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/ui/category_avatar.dart';
import 'package:vigon/src/ui/category_grid.dart';

import '../helpers.dart';

/// Thêm các danh mục chi để tổng số danh mục chi là [total].
Future<void> addExpenseCategories(
  WidgetTester tester,
  AppDatabase db,
  int total,
) async {
  await tester.runAsync(() async {
    final repo = CategoryRepository(db);
    final have = (await repo.watch(CategoryType.expense).first).length;
    for (var i = have; i < total; i++) {
      await repo.add(
        type: CategoryType.expense,
        name: 'Mục $i',
        icon: 'restaurant',
        color: 0xFF607D8B,
      );
    }
  });
}

void main() {
  group('F-16: sửa chuỗi định kỳ (AC-50)', () {
    testWidgets('đổi tần suất, danh mục, tài khoản rồi lưu', (tester) async {
      final db = memoryDatabase();
      final card = await tester.runAsync(
        () => AccountRepository(db).add(name: 'Thẻ'),
      );
      await tester.runAsync(
        () => db
            .into(db.recurringRules)
            .insert(
              RecurringRulesCompanion.insert(
                type: EntryType.expense,
                amount: 100000,
                categoryId: const Value(3), // Nhà cửa
                accountId: 1,
                frequency: RecurrenceFrequency.monthly,
                startDate: '2026-10-03',
                lastGeneratedDate: const Value('2026-10-03'),
              ),
            ),
      );
      // Mở app sinh khoản 03/11; ngày tới hạn kế tiếp theo lịch cũ là 03/12.
      await pumpApp(tester, db: db);
      final before = await tester.runAsync(() => db.select(db.entries).get());
      expect(before!.map((e) => e.date), ['2026-11-03']);

      await tester.tap(find.byTooltip('Cài đặt'));
      await settle(tester);
      await tester.tap(find.text('Khoản định kỳ'));
      await settle(tester);
      expect(find.textContaining('Hằng tháng'), findsOneWidget);
      expect(find.textContaining('Nhà cửa'), findsOneWidget);

      await tester.tap(find.textContaining('Nhà cửa'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('rule-frequency')));
      await settle(tester);
      await tester.tap(find.text('Hằng tuần').last);
      await settle(tester);
      await tester.tap(find.byKey(const Key('rule-category')));
      await settle(tester);
      await tester.tap(find.text('Hóa đơn').last);
      await settle(tester);
      await tester.tap(find.byKey(const Key('rule-account')));
      await settle(tester);
      await tester.tap(find.text('Thẻ').last);
      await settle(tester);
      await tester.tap(find.text('Lưu'));
      await settle(tester);

      final rule = await tester.runAsync(
        () => db.select(db.recurringRules).getSingle(),
      );
      expect(
        (
          rule!.frequency,
          rule.categoryId,
          rule.accountId,
          rule.startDate,
          rule.lastGeneratedDate,
        ),
        (RecurrenceFrequency.weekly, 4, card, '2026-12-03', '2026-12-02'),
      );
      // Khoản đã sinh không đổi.
      final after = await tester.runAsync(() => db.select(db.entries).get());
      expect(after!.map((e) => (e.date, e.categoryId, e.accountId)), [
        ('2026-11-03', 3, 1),
      ]);
      // Danh sách hiện tên danh mục và tần suất mới.
      expect(find.textContaining('Hóa đơn'), findsOneWidget);
      expect(find.textContaining('Hằng tuần'), findsOneWidget);
      expect(find.textContaining('Nhà cửa'), findsNothing);
      await disposeApp(tester, db);
    });
  });

  group('F-17: ô "Danh mục khác" ở màn chính (AC-51)', () {
    testWidgets(
      'quá nhiều danh mục chi: có ô thêm, mở lưới đủ, chọn mở Nhập khoản',
      (tester) async {
        final db = memoryDatabase();
        const total = 24;
        await addExpenseCategories(tester, db, total);
        await pumpApp(tester, db: db);

        final more = find.bySemanticsLabel('Danh mục khác');
        expect(more, findsOneWidget);
        expect(find.byType(MoreCategoriesAvatar), findsOneWidget);
        // Ô thêm cùng cỡ 48 với icon danh mục.
        expect(
          tester.getSize(find.byType(MoreCategoriesAvatar)),
          const Size(48, 48),
        );
        final ringIcons = find.byType(CategoryAvatar).evaluate().length;
        expect(ringIcons, lessThan(total));

        await tester.tap(find.byType(MoreCategoriesAvatar));
        await settle(tester);
        expect(find.byType(CategoryGrid), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(CategoryGrid),
            matching: find.byType(CategoryAvatar),
          ),
          findsNWidgets(total),
        );

        // Chọn một danh mục không có trên vòng.
        await tester.tap(find.text('Mục ${total - 1}'));
        await settle(tester);
        expect(find.byType(CategoryGrid), findsNothing);
        expect(find.text('Mục ${total - 1}'), findsWidgets);
        expect(find.byType(MoreCategoriesAvatar), findsNothing);
        await disposeApp(tester, db);
      },
    );

    testWidgets('10 danh mục mặc định: không có ô thêm', (tester) async {
      final db = await pumpApp(tester);
      expect(find.byType(MoreCategoriesAvatar), findsNothing);
      expect(find.bySemanticsLabel('Danh mục khác'), findsNothing);
      await disposeApp(tester, db);
    });

    testWidgets(
      '14 danh mục: màn 360x800 đủ chỗ thì giữ như cũ; màn thấp 360x500 có ô thêm',
      (tester) async {
        final db = memoryDatabase();
        await addExpenseCategories(tester, db, 14);
        await pumpApp(tester, db: db);
        // 360x800: vòng xếp vừa 14 icon, không có ô thêm.
        expect(find.byType(MoreCategoriesAvatar), findsNothing);
        expect(find.byType(CategoryAvatar), findsNWidgets(14));

        // Màn thấp hơn: vòng nhỏ lại, danh mục thừa phải qua ô "Danh mục khác".
        tester.view.physicalSize = const Size(1080, 1500);
        await settle(tester);
        expect(find.byType(MoreCategoriesAvatar), findsOneWidget);
        expect(find.byType(CategoryAvatar).evaluate().length, lessThan(14));
        await tester.tap(find.byType(MoreCategoriesAvatar));
        await settle(tester);
        expect(
          find.descendant(
            of: find.byType(CategoryGrid),
            matching: find.byType(CategoryAvatar),
          ),
          findsNWidgets(14),
        );
        // Màn thấp: lưới cuộn được, kéo danh mục cuối vào tầm nhìn rồi chạm.
        await tester.ensureVisible(find.text('Mục 13'));
        await settle(tester);
        await tester.tap(find.text('Mục 13'));
        await settle(tester);
        expect(find.byType(CategoryGrid), findsNothing);
        expect(find.text('Mục 13'), findsWidgets);
        await disposeApp(tester, db);
      },
    );
  });
}
