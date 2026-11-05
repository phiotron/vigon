import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vigon/src/data/currency.dart';
import 'package:vigon/src/data/currency_table.dart';
import 'package:vigon/src/data/money.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  group('bảng tiền tệ ISO 4217 (AC-53)', () {
    test('đủ khoảng 150 mã, không trùng, đúng ba chữ cái in hoa', () {
      expect(currencyTable.length, inInclusiveRange(145, 175));
      final codes = currencyTable.map((c) => c.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
      for (final c in currencyTable) {
        expect(c.code, matches(RegExp(r'^[A-Z]{3}$')), reason: c.code);
        expect(c.nameVi.trim(), isNotEmpty, reason: c.code);
        expect(c.nameEn.trim(), isNotEmpty, reason: c.code);
        expect(c.digits, anyOf(0, 2, 3), reason: c.code);
      }
      expect(supportedCurrencies, codes);
    });

    test('giữ đủ 31 mã của bản trước, cùng thứ tự đầu danh sách', () {
      const old = [
        'VND', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'CNY', 'TWD', 'HKD', 'SGD', //
        'THB', 'MYR', 'IDR', 'PHP', 'INR', 'AUD', 'NZD', 'CAD', 'CHF', 'SEK', //
        'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'TRY', 'BRL', 'MXN', 'ZAR', 'AED', //
        'SAR',
      ];
      expect(supportedCurrencies.take(old.length), old);
    });

    test('số chữ số thập phân đúng ISO: 0, 3 và còn lại 2', () {
      const zero = {
        'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG', //
        'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
      };
      const three = {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'};
      for (final c in currencyTable) {
        final expected = zero.contains(c.code)
            ? 0
            : three.contains(c.code)
            ? 3
            : 2;
        expect(c.digits, expected, reason: c.code);
        expect(currencyDecimalDigits(c.code), expected, reason: c.code);
      }
      // Mọi mã trong hai tập đều có trong bảng.
      for (final code in {...zero, ...three}) {
        expect(currencyInfo(code), isNotNull, reason: code);
      }
      expect(currencyDecimalDigits('JPY'), 0);
      expect(currencyDecimalDigits('USD'), 2);
      expect(currencyDecimalDigits('KWD'), 3);
    });

    test('mã lạ không có trong bảng vẫn có số chữ số hợp lệ', () {
      expect(currencyDecimalDigits('XXX'), anyOf(0, 2, 3));
    });

    test('formatMoney chạy được cho mọi mã, cả hai ngôn ngữ', () {
      for (final c in currencyTable) {
        for (final locale in ['vi', 'en']) {
          final unit = c.digits == 0 ? 1 : (c.digits == 2 ? 100 : 1000);
          final text = formatMoney(
            123 * unit,
            currencyCode: c.code,
            locale: locale,
          );
          expect(text, contains('123'), reason: '${c.code} $locale: $text');
          // Có phần lẻ đúng số chữ số: 5 đơn vị nhỏ nhất.
          final tiny = formatMoney(5, currencyCode: c.code, locale: 'en');
          if (c.digits > 0) {
            // Ký hiệu có thể chứa dấu chấm ("Af."), nên chỉ xét chữ số quanh dấu chấm.
            final frac = RegExp(r'\d\.(\d+)').firstMatch(tiny)?.group(1);
            expect(frac?.length, c.digits, reason: '${c.code}: $tiny');
          } else {
            expect(tiny, isNot(matches(RegExp(r'\d\.\d'))), reason: tiny);
          }
        }
      }
      expect(
        formatMoney(1500, currencyCode: 'JPY', locale: 'en'),
        contains('1,500'),
      );
      expect(
        formatMoney(12345, currencyCode: 'KWD', locale: 'en'),
        contains('12.345'),
      );
    });
  });

  group('tìm tiền tệ', () {
    test('chuỗi rỗng trả về toàn bộ bảng', () {
      expect(searchCurrencies('  '), hasLength(currencyTable.length));
    });

    test('bảng chọn xếp theo mã A→Z (SCR-13), đủ mã của bảng gốc', () {
      final codes = searchCurrencies('').map((c) => c.code).toList();
      expect(codes, [...codes]..sort());
      expect(codes.first, 'AED');
      expect(codes.toSet(), currencyTable.map((c) => c.code).toSet());
      expect(
        searchCurrencies('dollar').map((c) => c.code).toList(),
        [...searchCurrencies('dollar').map((c) => c.code)]..sort(),
      );
    });

    test('tìm theo mã, không phân biệt hoa thường', () {
      expect(searchCurrencies('jpy').map((c) => c.code), contains('JPY'));
      expect(searchCurrencies('KWD').single.code, 'KWD');
    });

    test('tìm theo tên tiếng Việt, không phân biệt dấu và hoa thường', () {
      expect(searchCurrencies('yen nhat').map((c) => c.code), ['JPY']);
      expect(searchCurrencies('YÊN NHẬT').map((c) => c.code), ['JPY']);
      expect(searchCurrencies('dong viet').map((c) => c.code), ['VND']);
      expect(searchCurrencies('đồng').map((c) => c.code), contains('VND'));
      expect(searchCurrencies('bang anh').map((c) => c.code), contains('GBP'));
    });

    test('tìm theo tên tiếng Anh', () {
      expect(searchCurrencies('kuwaiti').map((c) => c.code), ['KWD']);
      expect(
        searchCurrencies('dollar').map((c) => c.code),
        containsAll(['USD', 'AUD', 'CAD']),
      );
    });

    test('không khớp thì rỗng', () {
      expect(searchCurrencies('zzzz'), isEmpty);
    });

    test('foldForSearch bỏ dấu cả dạng tổ hợp rời', () {
      expect(foldForSearch('Đồng Việt Nam'), 'dong viet nam');
      expect(foldForSearch('ế'), 'e');
    });
  });
}
