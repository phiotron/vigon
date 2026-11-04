import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/seed.dart';
import 'package:vigon/src/features/categories/category_icons.dart';
import 'package:vigon/src/features/entry/keypad.dart';
import 'package:vigon/src/features/lock/pin_pad.dart';
import 'package:vigon/src/ui/category_avatar.dart';
import 'package:vigon/src/ui/main_action_button.dart';
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/tokens.g.dart';

import '../helpers.dart';

/// Dựng [child] trong theme của app, tiếng Việt, màn 360×800.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

Category _category(String icon, int color) => Category(
  id: 1,
  type: CategoryType.expense,
  name: 'Ăn uống',
  icon: icon,
  color: color,
  sortOrder: 0,
);

void main() {
  test('31 icon danh mục đúng thứ tự trong design-system-guide (UI-03)', () {
    expect(categoryIcons.keys.toList(), [
      'restaurant', 'local_cafe', 'directions_bus', 'two_wheeler', //
      'local_gas_station', 'home', 'receipt_long', 'bolt', 'water_drop',
      'wifi', 'shopping_bag', 'checkroom', 'health_and_safety', 'medication',
      'movie', 'sports_esports', 'school', 'menu_book', 'family_restroom',
      'child_care', 'pets', 'redeem', 'payments', 'savings', 'work', 'flight',
      'fitness_center', 'spa', 'volunteer_activism', 'build', 'more_horiz',
    ]);
  });

  test('khóa icon cũ trong dữ liệu hoặc file sao lưu vẫn có icon riêng '
      '(UI-03)', () {
    for (final key in [
      'local_grocery_store',
      'phone_android',
      'medical_services',
      'card_giftcard',
      'trending_up',
    ]) {
      expect(categoryIcons.containsKey(key), isFalse, reason: key);
      expect(iconFor(key), isNot(Symbols.category_rounded), reason: key);
    }
    expect(iconFor('không-có'), Symbols.category_rounded);
  });

  test('bảng màu và danh mục mặc định theo token cat-xx', () {
    expect(categoryColors, [for (final c in vgCategoryColors) c.toARGB32()]);
    for (final (_, icon, color) in [
      ...defaultExpenseCategories,
      ...defaultIncomeCategories,
    ]) {
      expect(categoryIcons.containsKey(icon), isTrue, reason: icon);
      expect(categoryColors, contains(color), reason: icon);
    }
    // Ăn uống cat-13, Sức khỏe cat-01 (README thiết kế).
    expect(defaultExpenseCategories.first.$3, categoryColors[12]);
    expect(
      defaultExpenseCategories.firstWhere((c) => c.$1 == 'health').$3,
      categoryColors[0],
    );
  });

  testWidgets('icon danh mục tô đầy, màu on-cat, cỡ theo vòng tròn', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      Column(
        children: [
          CategoryAvatar(category: _category('restaurant', 0xFFE65100)),
          CategoryAvatar(
            category: _category('restaurant', 0xFFE65100),
            size: 40,
          ),
        ],
      ),
    );
    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons.map((i) => i.icon), everyElement(Symbols.restaurant_rounded));
    expect(icons.map((i) => i.fill), everyElement(1));
    expect(icons.map((i) => i.color), everyElement(vgLight.onCat));
    expect(icons.map((i) => i.size), [24, 22]);
  });

  testWidgets('nút lớn − Chi cao 64, có dấu và chữ, đọc "Thêm khoản chi"', (
    tester,
  ) async {
    var taps = 0;
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => MainActionButton(
          glyph: '−',
          label: 'Chi',
          semanticLabel: 'Thêm khoản chi',
          background: context.vg.expense,
          foreground: context.vg.onExpense,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('−'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)).height, VgSize.tapMain);
    expect(find.bySemanticsLabel('Thêm khoản chi'), findsOneWidget);
    await tester.tap(find.byTooltip('Thêm khoản chi'));
    expect(taps, 1);
  });

  testWidgets('bàn phím số: phím 56, cách 8, nút Lưu rộng đúng 3 cột (T2)', (
    tester,
  ) async {
    final keys = <String>[];
    await pumpThemed(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: Builder(
          builder: (context) => Keypad(
            decimalDigits: 0,
            onKey: keys.add,
            saveLabel: 'Chọn danh mục',
            saveColor: context.vg.expense,
            saveForeground: context.vg.onExpense,
            onSave: () {},
          ),
        ),
      ),
    );
    final seven = tester.getRect(find.widgetWithText(TextButton, '7'));
    final eight = tester.getRect(find.widgetWithText(TextButton, '8'));
    final four = tester.getRect(find.widgetWithText(TextButton, '4'));
    final div = tester.getRect(find.widgetWithText(TextButton, '÷'));
    final save = tester.getRect(find.byType(FilledButton));
    expect(seven.height, VgSize.tapKey);
    expect(eight.left - seven.right, VgSpace.s2);
    expect(four.top - seven.bottom, VgSpace.s2);
    // Nút Lưu bắt đầu ở cột 2 và kết thúc ở mép phải cột 4.
    expect(save.left, closeTo(eight.left, 0.01));
    expect(save.right, closeTo(div.right, 0.01));
    expect(find.text('000'), findsOneWidget);

    final op = tester.widget<TextButton>(find.widgetWithText(TextButton, '÷'));
    expect(op.style!.backgroundColor!.resolve({}), vgLight.secondaryContainer);
    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.style!.backgroundColor!.resolve({}), vgLight.expense);
    expect(saveButton.style!.foregroundColor!.resolve({}), vgLight.onExpense);

    await tester.tap(find.bySemanticsLabel('Xóa lùi'));
    await tester.tap(find.bySemanticsLabel('Bằng'));
    expect(keys, [keyBackspace, keyEquals]);
  });

  testWidgets('bàn phím PIN: phím bầu dục 88×64, đọc "Số N" (S01)', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      Center(
        child: PinPad(title: 'Nhập mã PIN', onCompleted: (_) async {}),
      ),
    );
    final one = find.widgetWithText(TextButton, '1');
    expect(tester.getSize(one), const Size(88, VgSize.tapMain));
    expect(find.bySemanticsLabel('Số 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Xóa lùi'), findsOneWidget);
  });

  testWidgets('chip cao 40, viền outline, bo 8 (T3_ChipDong)', (tester) async {
    await pumpThemed(
      tester,
      Center(
        child: ActionChip(
          avatar: const Icon(Symbols.calendar_today_rounded),
          label: const Text('Hôm nay'),
          onPressed: () {},
        ),
      ),
    );
    final chip = find.descendant(
      of: find.byType(ActionChip),
      matching: find.byType(Material),
    );
    expect(tester.getSize(chip.first).height, closeTo(40, 0.5));
    final theme = buildTheme(Brightness.light).chipTheme;
    expect(theme.side!.color, vgLight.outline);
    expect(theme.iconTheme!.color, vgLight.inkMuted);
  });
}
