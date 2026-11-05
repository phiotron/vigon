import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/exchange_rate.dart';

/// Nguồn tỉ giá với HTTP giả: không gọi mạng thật (D-025).
String okBody({Map<String, Object> rates = const {'USD': 1, 'VND': 25974.5}}) =>
    jsonEncode({
      'result': 'success',
      'provider': 'https://www.exchangerate-api.com',
      'time_last_update_unix': 1793836951, // 2026-11-05 00:02:31 UTC
      'base_code': 'USD',
      'rates': rates,
    });

void main() {
  test(
    'thành công: gọi đúng một URL HTTPS gốc USD, đọc bảng và ngày',
    () async {
      final calls = <Uri>[];
      final source = ErApiRateSource(
        get: (uri, timeout) async {
          calls.add(uri);
          return okBody(
            rates: {
              'USD': 1,
              'VND': 25974.5,
              'EUR': 0.889912,
              'bad': 2,
              'XXX': -1,
            },
          );
        },
      );
      final table = await source.fetch();
      expect(calls, [Uri.parse('https://open.er-api.com/v6/latest/USD')]);
      expect(calls.single.scheme, 'https');
      // Yêu cầu không chứa gì của người dùng (không query, không tiền tệ đang dùng).
      expect(calls.single.query, isEmpty);
      expect(table.date, '2026-11-05');
      expect(table.rates.keys, unorderedEquals(['USD', 'VND', 'EUR']));
      expect(table.rate('VND', 'USD')!.toDouble(), closeTo(1 / 25974.5, 1e-15));
      expect(source.attribution, 'Rates By Exchange Rate API');
      expect(source.homepage.scheme, 'https');
    },
  );

  test('hết giờ chờ → lỗi offline', () async {
    final never = Completer<String>();
    final source = ErApiRateSource(
      get: (uri, timeout) => never.future,
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(
      source.fetch(),
      throwsA(
        isA<ExchangeRateException>().having(
          (e) => e.kind,
          'kind',
          ExchangeRateError.offline,
        ),
      ),
    );
  });

  test('lỗi mạng của lớp HTTP được giữ nguyên loại', () async {
    final source = ErApiRateSource(
      get: (uri, timeout) async =>
          throw const ExchangeRateException(ExchangeRateError.offline),
    );
    await expectLater(
      source.fetch(),
      throwsA(
        isA<ExchangeRateException>().having(
          (e) => e.kind,
          'kind',
          ExchangeRateError.offline,
        ),
      ),
    );
  });

  group('JSON lỗi → unavailable', () {
    for (final (name, body) in [
      ('không phải JSON', '<html>oops</html>'),
      ('mảng', '[]'),
      ('result error', jsonEncode({'result': 'error', 'error-type': 'x'})),
      (
        'thiếu rates',
        jsonEncode({
          'result': 'success',
          'base_code': 'USD',
          'time_last_update_unix': 1,
        }),
      ),
      ('rates rỗng', okBody(rates: const {})),
      ('rates toàn số sai', okBody(rates: const {'VND': 0, 'USD': -1})),
      (
        'thiếu ngày',
        jsonEncode({
          'result': 'success',
          'base_code': 'USD',
          'rates': {'VND': 1},
        }),
      ),
    ]) {
      test(name, () async {
        final source = ErApiRateSource(get: (uri, timeout) async => body);
        await expectLater(
          source.fetch(),
          throwsA(
            isA<ExchangeRateException>().having(
              (e) => e.kind,
              'kind',
              ExchangeRateError.unavailable,
            ),
          ),
        );
      });
    }
  });

  test('thiếu cặp tiền: bảng tải được nhưng không có mã → null', () async {
    final source = ErApiRateSource(get: (uri, timeout) async => okBody());
    final table = await source.fetch();
    expect(table.rate('VND', 'KPW'), isNull);
    expect(table.rate('VND', 'USD'), isNotNull);
  });

  test('HTTP thật từ chối URL không phải HTTPS (không mở kết nối)', () async {
    await expectLater(
      ioHttpGetText(
        Uri.parse('http://open.er-api.com/v6/latest/USD'),
        const Duration(seconds: 1),
      ),
      throwsA(
        isA<ExchangeRateException>().having(
          (e) => e.kind,
          'kind',
          ExchangeRateError.unavailable,
        ),
      ),
    );
  });
}
