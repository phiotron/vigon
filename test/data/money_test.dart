import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vigon/src/data/money.dart';

/// intl dùng khoảng trắng không ngắt; đổi về khoảng trắng thường để so sánh.
String _plain(String s) => s.replaceAll(' ', ' ');

void main() {
  setUpAll(() => initializeDateFormatting());

  test('số chữ số thập phân theo ISO 4217', () {
    expect(currencyDecimalDigits('VND'), 0);
    expect(currencyDecimalDigits('USD'), 2);
    expect(currencyDecimalDigits('JPY'), 0);
  });

  test('định dạng tiếng Việt, VND (AC-22)', () {
    expect(
      _plain(formatMoney(1250000, currencyCode: 'VND', locale: 'vi')),
      '1.250.000 ₫',
    );
  });

  test('định dạng tiếng Anh, USD từ cent (AC-22)', () {
    expect(
      formatMoney(125000, currencyCode: 'USD', locale: 'en'),
      r'$1,250.00',
    );
  });
}
