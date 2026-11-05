import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/src/data/currency_table.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/settings/currency_picker.dart';

import '../helpers.dart';

Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Cài đặt'));
  await settle(tester);
  // Cài đặt dạng thẻ (SCR-12) cao hơn: cuộn hàng vào màn trước khi chạm.
  await tester.ensureVisible(find.text('Tiền tệ'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tiền tệ'));
  await settle(tester);
}

final dialog = find.byType(CurrencyPickerSheet);
final rows = find.descendant(of: dialog, matching: find.byType(CurrencyRow));

void main() {
  testWidgets('sheet tiền tệ: ô tìm, dựng lười, dấu tick (AC-53)', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await openPicker(tester);
    expect(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      findsOneWidget,
    );
    // Dòng đang dùng có dấu tick.
    final checks = find.descendant(
      of: rows,
      matching: find.byIcon(Symbols.check_rounded),
    );
    expect(checks, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: checks, matching: find.byType(CurrencyRow)),
        matching: find.text('VND · ₫'),
      ),
      findsOneWidget,
    );
    // Dựng lười: mã cuối bảng chưa được dựng khi chưa cuộn.
    expect(
      find.descendant(
        of: dialog,
        matching: find.textContaining(currenciesByCode.last.nameEn),
      ),
      findsNothing,
    );
    expect(rows.evaluate().length, lessThan(currencyTable.length ~/ 2));
    // Danh sách theo mã A→Z như mockup SCR-13 (sau thẻ tiền tệ đang dùng).
    expect(
      find.descendant(of: dialog, matching: find.textContaining('AED')),
      findsOneWidget,
    );
    final field = find.descendant(of: dialog, matching: find.byType(TextField));
    // Tìm không phân biệt dấu và hoa thường.
    await tester.enterText(field, 'YEN nhat');
    await settle(tester);
    expect(rows, findsOneWidget);
    expect(find.text('Yên Nhật'), findsOneWidget);
    await tester.enterText(field, 'kwd');
    await settle(tester);
    expect(find.text('Dinar Kuwait'), findsOneWidget);
    await tester.enterText(field, 'zzzz');
    await settle(tester);
    expect(find.text('Không có tiền tệ nào khớp'), findsOneWidget);
    expect(rows, findsNothing);
    await disposeApp(tester, db);
  });

  testWidgets('chọn mã tìm được thì đổi tiền tệ và giữ con số', (tester) async {
    final db = await pumpApp(tester);
    await insertEntry(
      tester,
      db,
      type: EntryType.expense,
      amount: 155,
      categoryId: 1,
    );
    await openPicker(tester);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)),
      'kuwait',
    );
    await settle(tester);
    await tester.tap(
      find.descendant(of: dialog, matching: find.textContaining('KWD')),
    );
    await settle(tester);
    expect(
      await tester.runAsync(() => SettingsRepository(db).watchCurrency().first),
      'KWD',
    );
    expect(
      (await tester.runAsync(() => db.select(db.entries).getSingle()))!.amount,
      155000,
    );
    await disposeApp(tester, db);
  });
}
