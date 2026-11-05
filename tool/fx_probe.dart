// Kiểm API tỉ giá THẬT bằng tay (D-025). Không nằm trong `test/` nên không
// chạy trong `flutter test` hay CI. Dùng đúng mã của app (`ErApiRateSource`,
// `parseErApiResponse`), nên nếu API đổi định dạng thì script này báo lỗi.
//
// Chạy:  dart run tool/fx_probe.dart
// Thoát mã 0 khi đạt; 1 khi lỗi mạng/định dạng hoặc thiếu VND, USD.
import 'dart:io';

import 'package:vigon/src/data/currency_table.dart';
import 'package:vigon/src/data/exchange_rate.dart';

Future<void> main() async {
  const source = ErApiRateSource();
  stdout.writeln('GET ${ErApiRateSource.endpoint}');
  final RateTable table;
  try {
    table = await source.fetch();
  } on ExchangeRateException catch (e) {
    stderr.writeln('LỖI: $e');
    exit(1);
  }
  stdout
    ..writeln('base: ${table.base}')
    ..writeln('ngày cập nhật (UTC, time_last_update_unix): ${table.date}')
    ..writeln('số mã: ${table.rates.length}');
  final usdVnd = table.rate('USD', 'VND');
  final vndUsd = table.rate('VND', 'USD');
  if (usdVnd == null || vndUsd == null) {
    stderr.writeln('LỖI: thiếu VND hoặc USD');
    exit(1);
  }
  stdout
    ..writeln('1 USD = ${usdVnd.toDouble()} VND')
    ..writeln('1 VND = ${vndUsd.toDouble()} USD');
  for (final pair in [('EUR', 'VND'), ('JPY', 'VND'), ('VND', 'KWD')]) {
    final r = table.rate(pair.$1, pair.$2);
    stdout.writeln('1 ${pair.$1} = ${r?.toDouble()} ${pair.$2}');
  }
  final missing = [
    for (final c in currencyTable)
      if (c.code != table.base && !table.rates.containsKey(c.code)) c.code,
  ];
  stdout.writeln(
    'Mã trong app không có ở nguồn (${missing.length}/${currencyTable.length}, '
    'đổi sang các mã này phải nhập tỉ giá tay): ${missing.join(', ')}',
  );
}
