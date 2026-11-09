// D5: ô số tiền hiện và đọc dấu ngăn nghìn theo ngôn ngữ (vi "3.000.000",
// en "3,000,000"; USD/KWD giữ phần lẻ), không vỡ phép tính và giới hạn 10^12.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/calculator.dart';
import 'package:vigon/src/data/money.dart';
import 'package:vigon/src/data/settings_repository.dart';

import '../helpers.dart';

int? _read(String text, String locale, int digits) {
  final n = normalizeAmountInput(text, locale: locale);
  return n == null ? null : evaluateToMinorUnits(n, decimalDigits: digits);
}

void main() {
  group('formatAmountInput', () {
    test('VND: dấu ngăn nghìn theo ngôn ngữ', () {
      expect(
        formatAmountInput(3000000, decimalDigits: 0, locale: 'vi'),
        '3.000.000',
      );
      expect(
        formatAmountInput(3000000, decimalDigits: 0, locale: 'en'),
        '3,000,000',
      );
      expect(formatAmountInput(999, decimalDigits: 0, locale: 'vi'), '999');
      expect(formatAmountInput(0, decimalDigits: 0, locale: 'vi'), '0');
      expect(
        formatAmountInput(maxMinorUnits, decimalDigits: 0, locale: 'vi'),
        '1.000.000.000.000',
      );
    });

    test('USD / KWD: có phần lẻ thì đủ chữ số, chẵn thì không', () {
      expect(formatAmountInput(1250, decimalDigits: 2, locale: 'en'), '12.50');
      expect(formatAmountInput(1250, decimalDigits: 2, locale: 'vi'), '12,50');
      expect(formatAmountInput(1205, decimalDigits: 2, locale: 'en'), '12.05');
      expect(formatAmountInput(1200, decimalDigits: 2, locale: 'en'), '12');
      expect(
        formatAmountInput(123456789, decimalDigits: 2, locale: 'en'),
        '1,234,567.89',
      );
      expect(
        formatAmountInput(123456789, decimalDigits: 2, locale: 'vi'),
        '1.234.567,89',
      );
      expect(formatAmountInput(1005, decimalDigits: 3, locale: 'en'), '1.005');
      expect(formatAmountInput(1005, decimalDigits: 3, locale: 'vi'), '1,005');
    });
  });

  group('normalizeAmountInput + evaluateToMinorUnits', () {
    test('đọc đúng định dạng của ngôn ngữ', () {
      expect(_read('3.000.000', 'vi', 0), 3000000);
      expect(_read('3,000,000', 'en', 0), 3000000);
      expect(_read('3000000', 'vi', 0), 3000000);
      expect(_read('12,5', 'vi', 2), 1250);
      expect(_read('12.5', 'en', 2), 1250);
      expect(_read('1.234.567,89', 'vi', 2), 123456789);
      expect(_read('1,234,567.89', 'en', 2), 123456789);
      expect(_read('1 500 000', 'vi', 0), 1500000);
      expect(_read('1,005', 'vi', 3), 1005);
    });

    test('gõ nhầm kiểu ngôn ngữ kia mà không mơ hồ vẫn hiểu', () {
      // Dấu ngăn nghìn luôn đứng trước đúng 3 chữ số.
      expect(_read('12.5', 'vi', 2), 1250);
      expect(_read('12,50', 'en', 2), 1250);
      // Dấu lặp lại là dấu ngăn nghìn; một dấu thập phân của ngôn ngữ thì
      // vẫn là thập phân ("3,000" ở vi = 3).
      expect(_read('3,000,000', 'vi', 0), 3000000);
      expect(_read('1.000.000', 'en', 0), 1000000);
      expect(_read('3,000', 'vi', 0), 3);
    });

    test('khứ hồi: hiện rồi đọc lại ra đúng số nguyên', () {
      for (final locale in ['vi', 'en']) {
        for (final (digits, values) in [
          (0, [1, 999, 1000, 45000, 3500000, 1250000000, maxMinorUnits]),
          (2, [1, 5, 50, 99, 100, 1250, 1205, 123456789, 99999999999]),
          (3, [1, 1005, 1234567]),
        ]) {
          for (final v in values) {
            final text = formatAmountInput(
              v,
              decimalDigits: digits,
              locale: locale,
            );
            expect(_read(text, locale, digits), v, reason: '$locale $text');
          }
        }
      }
    });

    test('sai, rỗng, phép tính hoặc vượt 10^12 → null', () {
      expect(normalizeAmountInput('', locale: 'vi'), isNull);
      expect(normalizeAmountInput('abc', locale: 'vi'), isNull);
      expect(normalizeAmountInput('12+3', locale: 'vi'), isNull);
      expect(normalizeAmountInput('1..2', locale: 'en'), isNull);
      expect(normalizeAmountInput('1,2,3', locale: 'en'), isNull);
      expect(normalizeAmountInput('1,5.000', locale: 'vi'), isNull);
      expect(_read('1.000.000.000.000', 'vi', 0), maxMinorUnits);
      expect(_read('1.000.000.000.001', 'vi', 0), isNull);
    });
  });

  group('formatExpressionForDisplay', () {
    test('mỗi số có dấu ngăn nghìn, dấu thập phân theo ngôn ngữ', () {
      expect(formatExpressionForDisplay('3500000', locale: 'vi'), '3.500.000');
      expect(
        formatExpressionForDisplay('120${opAdd}3500.5', locale: 'vi'),
        '120${opAdd}3.500,5',
      );
      expect(
        formatExpressionForDisplay('1234567${opMul}2', locale: 'en'),
        '1,234,567${opMul}2',
      );
      expect(formatExpressionForDisplay('12.', locale: 'vi'), '12,');
      expect(formatExpressionForDisplay('', locale: 'vi'), '');
    });
  });

  group('màn: sửa ô số tiền rồi lưu', () {
    testWidgets('vi, VND: ngân sách hiện "12.000.000", gõ "1.500.000" lưu '
        '1500000', (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() async {
        await SettingsRepository(db).setCurrency('VND');
        await SettingsRepository(db).setBudget(12000000);
      });
      await pumpApp(tester, db: db);
      await tester.tap(find.byTooltip('Cài đặt'));
      await settle(tester);
      await tester.tap(find.text('Ngân sách tháng'));
      await settle(tester);
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller!.text, '12.000.000');
      await tester.enterText(field, '1.500.000');
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      expect(
        await tester.runAsync(() => SettingsRepository(db).watchBudget().first),
        1500000,
      );
      await disposeApp(tester, db);
    });

    testWidgets('en, USD: ngân sách 12.50 hiện "12.50", gõ "1,234.5" lưu '
        '123450 cent', (tester) async {
      final db = memoryDatabase();
      await tester.runAsync(() async {
        await SettingsRepository(db).setCurrency('USD');
        await SettingsRepository(db).setBudget(1250);
      });
      await pumpApp(tester, db: db, localeCode: 'en');
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      await tester.tap(find.text('Monthly budget'));
      await settle(tester);
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller!.text, '12.50');
      await tester.enterText(field, '1,234.5');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(
        await tester.runAsync(() => SettingsRepository(db).watchBudget().first),
        123450,
      );
      await disposeApp(tester, db);
    });
  });
}
