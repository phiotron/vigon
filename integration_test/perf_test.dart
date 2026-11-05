import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/features/entry/keypad.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/providers.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Đo NFR mục 5b trên máy thật, bản profile (không đụng dữ liệu thật của app):
///   flutter drive --profile --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart -d MÁY
/// Kết quả ghi ở build/perf_summary.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lưu một khoản và cuộn 5.000 khoản (NFR 5b)', (tester) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/perf_test.sqlite');
    if (file.existsSync()) file.deleteSync();
    final db = AppDatabase(NativeDatabase(file));
    await db.batch((b) {
      for (var i = 0; i < 5000; i++) {
        final d = DateTime(2026, 11, 3).subtract(Duration(days: i % 365));
        b.insert(
          db.entries,
          EntriesCompanion.insert(
            type: EntryType.expense,
            amount: 10000 + (i * 7919) % 500000,
            categoryId: const Value(1),
            accountId: 1,
            date:
                '${d.year}-${d.month.toString().padLeft(2, '0')}-'
                '${d.day.toString().padLeft(2, '0')}',
            note: Value(i % 3 == 0 ? 'ghi chú $i' : null),
          ),
        );
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
        ],
        child: VigonApp(router: createRouter()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );

    // Lưu một khoản: từ lúc chạm Lưu tới lúc khoản nằm trong cơ sở dữ liệu.
    final saveTimes = <int>[];
    for (var round = 0; round < 5; round++) {
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .push('/entry/new?type=expense&category=2');
      await tester.pumpAndSettle();
      for (final k in ['1', '2', '0', '0', '0']) {
        await tester.tap(find.widgetWithText(TextButton, k).first);
        await tester.pump();
      }
      final before = await db.select(db.entries).get();
      final save = find.byType(FilledButton).last;
      final watch = Stopwatch()..start();
      await tester.tap(save);
      while ((await db.select(db.entries).get()).length == before.length) {
        await tester.pump(const Duration(milliseconds: 1));
        if (watch.elapsedMilliseconds > 5000) break;
      }
      watch.stop();
      saveTimes.add(watch.elapsedMilliseconds);
      await tester.pumpAndSettle();
    }
    // In ngay để còn số liệu nếu test bị ngắt giữa chừng (máy dùng chung).
    debugPrint('PERF save_ms=$saveTimes');

    // AC-01: từ lúc chạm nút "−" tới khung hình đầu tiên có bàn phím số.
    final openTimes = <int>[];
    for (var round = 0; round < 5; round++) {
      final watch = Stopwatch()..start();
      await tester.tap(find.byType(FilledButton).first);
      while (find.byType(Keypad).evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 1));
        if (watch.elapsedMilliseconds > 5000) break;
      }
      watch.stop();
      openTimes.add(watch.elapsedMilliseconds);
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();
    }
    debugPrint('PERF open_entry_ms=$openTimes');

    // Màn "Các khoản" với 5.000 khoản trong một danh mục, kỳ "Tất cả".
    container.read(periodProvider.notifier).selectType(PeriodType.all);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/entries');
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).first;

    await binding.watchPerformance(() async {
      await tester.tap(find.byIcon(Symbols.expand_more_rounded).first);
      await tester.pumpAndSettle();
    }, reportKey: 'expand_5000');
    debugPrint('PERF expand_5000=${binding.reportData?['expand_5000']}');

    await binding.watchPerformance(() async {
      for (var i = 0; i < 10; i++) {
        await tester.fling(list, const Offset(0, -1500), 4000);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 5; i++) {
        await tester.fling(list, const Offset(0, 1500), 4000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'scroll_5000');
    debugPrint('PERF scroll_5000=${binding.reportData?['scroll_5000']}');

    binding.reportData!['save_ms'] = saveTimes;
    // Gỡ cây widget (ProviderScope + stream drift) trước khi đóng DB; đóng khi
    // stream còn nghe thì test treo ở cuối trên iOS (notes/2026-11-04-ios-ci.md).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await db.close();
    file.deleteSync();
  });
}
