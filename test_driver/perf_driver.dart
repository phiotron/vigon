import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Ghi số đo của `integration_test/perf_test.dart` ra build/perf_summary.json.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final out = File('build/perf_summary.json');
    await out.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data ?? {}),
    );
  },
);
