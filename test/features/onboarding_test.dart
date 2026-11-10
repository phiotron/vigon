import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/home/home_screen.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/features/onboarding/onboarding_screen.dart';
import 'package:vigon/src/features/reminder/reminder_providers.dart';
import 'package:vigon/src/providers.dart';

import '../helpers.dart';
import 'f25_reminder_test.dart' show FakeReminderScheduler;
import 'g5_lock_test.dart' show enterPin;

/// Màn chào (F-44, D-041) trên cơ sở dữ liệu vừa tạo — như máy cài mới: tiếng
/// Anh, USD, có cờ `onboardingPending`.
Future<
  ({AppDatabase db, FakeReminderScheduler reminder, MemorySecretStore secrets})
>
pumpFreshInstall(WidgetTester tester, {AppDatabase? db}) async {
  usePhoneScreen(tester);
  final database = db ?? memoryDatabase();
  final reminder = FakeReminderScheduler();
  final secrets = MemorySecretStore();
  final gate = ValueNotifier<bool?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(() => testToday),
        secretStoreProvider.overrideWithValue(secrets),
        appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
        reminderSchedulerProvider.overrideWithValue(reminder),
      ],
      child: VigonApp(
        router: createRouter(onboarding: gate),
        onboardingGate: gate,
      ),
    ),
  );
  await settle(tester);
  return (db: database, reminder: reminder, secrets: secrets);
}

Future<void> tapPrimary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onboarding-primary')));
  await settle(tester);
}

Future<String?> setting(WidgetTester tester, AppDatabase db, String key) =>
    tester
        .runAsync(
          () => (db.select(
            db.settings,
          )..where((s) => s.key.equals(key))).getSingleOrNull(),
        )
        .then((r) => r?.value);

void main() {
  testWidgets('cài mới: hiện Màn chào bước 1 (English), không chớp màn chính', (
    tester,
  ) async {
    final app = await pumpFreshInstall(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Choose your language'), findsOneWidget);
    // Bước 1 không có "Bỏ qua".
    expect(find.byKey(const Key('onboarding-skip')), findsNothing);
    await disposeApp(tester, app.db);
  });

  testWidgets(
    'đi hết 5 bước: Tiếng Việt, VND (Tiền mặt theo), bật nhắc, đặt PIN → màn chính',
    (tester) async {
      final app = await pumpFreshInstall(tester);
      final db = app.db;

      // 1 Ngôn ngữ: đổi ngay.
      await tester.tap(find.byKey(const ValueKey('onboarding-lang-vi')));
      await settle(tester);
      expect(find.text('Chọn ngôn ngữ'), findsOneWidget);
      await tapPrimary(tester);

      // 2 Chào mừng.
      expect(find.text('Bước 2/5'), findsOneWidget);
      expect(find.text('Chào mừng đến Ví Gọn'), findsOneWidget);
      await tapPrimary(tester);

      // 3 Tiền tệ chính: USD chọn sẵn → VND.
      expect(find.text('Tiền tệ chính'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-currency-VND')));
      await settle(tester);
      await tapPrimary(tester);

      // 4 Nhắc ghi sổ: "Bật nhắc" xin quyền ngay.
      expect(find.text('Nhắc ghi sổ mỗi ngày'), findsOneWidget);
      await tapPrimary(tester);
      expect(app.reminder.permissionRequests, 1);

      // 5 Khoá PIN.
      expect(find.text('Khoá Ví Gọn bằng mã PIN?'), findsOneWidget);
      await tapPrimary(tester);
      await enterPin(tester, '1357');
      await enterPin(tester, '1357');

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await setting(tester, db, 'locale'), 'vi');
      expect(await setting(tester, db, 'primaryCurrency'), 'VND');
      expect(await setting(tester, db, 'reminderEnabled'), '1');
      expect(
        await setting(tester, db, SettingsRepository.onboardingPendingKey),
        isNull,
      );
      final cash = await tester.runAsync(
        () => db.select(db.accounts).getSingle(),
      );
      expect((cash!.currency, cash.initialCurrency), ('VND', 'VND'));
      expect(
        await tester.runAsync(() => PinService(app.secrets).verify('1357')),
        isTrue,
      );
      await disposeApp(tester, db);
    },
  );

  for (final step in [2, 3, 4, 5]) {
    testWidgets('Bỏ qua ở bước $step → vào app, còn lại mặc định', (
      tester,
    ) async {
      final app = await pumpFreshInstall(tester);
      final db = app.db;
      for (var i = 1; i < step; i++) {
        // Bước 4 nút chính là "Bật nhắc": đi tiếp bằng "Để sau".
        if (i == 4) {
          await tester.tap(find.byKey(const Key('onboarding-secondary')));
          await settle(tester);
        } else {
          await tapPrimary(tester);
        }
      }
      expect(find.text('Step $step of 5'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-skip')));
      await settle(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await setting(tester, db, 'locale'), isNull); // English
      expect(await setting(tester, db, 'primaryCurrency'), 'USD');
      expect(await setting(tester, db, 'reminderEnabled'), isNull);
      expect(app.reminder.permissionRequests, 0);
      expect(
        await tester.runAsync(() => PinService(app.secrets).isEnabled()),
        isFalse,
      );
      await disposeApp(tester, db);
    });
  }

  testWidgets('"Để sau" ở Nhắc: không xin quyền; Back lùi một bước', (
    tester,
  ) async {
    final app = await pumpFreshInstall(tester);
    await tapPrimary(tester); // 1 → 2
    await tapPrimary(tester); // 2 → 3
    await tapPrimary(tester); // 3 → 4
    await tester.tap(find.byKey(const Key('onboarding-secondary')));
    await settle(tester);
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(app.reminder.permissionRequests, 0);

    // Back của hệ thống: về bước 4, không thoát.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Step 4 of 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-secondary'))); // 4 → 5
    await settle(tester);
    await tester.tap(find.byKey(const Key('onboarding-secondary'))); // xong
    await settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    await disposeApp(tester, app.db);
  });

  testWidgets('từ chối quyền thông báo: nhắc vẫn tắt, sang bước PIN', (
    tester,
  ) async {
    final app = await pumpFreshInstall(tester);
    app.reminder.permission = false;
    for (var i = 0; i < 3; i++) {
      await tapPrimary(tester);
    }
    await tapPrimary(tester); // Turn on reminder → bị từ chối
    expect(app.reminder.permissionRequests, 1);
    expect(find.text('Step 5 of 5'), findsOneWidget);
    expect(await setting(tester, app.db, 'reminderEnabled'), isNull);
    await disposeApp(tester, app.db);
  });

  testWidgets('máy đã dùng bản cũ (không có cờ) → vào thẳng màn chính', (
    tester,
  ) async {
    final db = memoryDatabase();
    await tester.runAsync(() => SettingsRepository(db).finishOnboarding());
    final app = await pumpFreshInstall(tester, db: db);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    await disposeApp(tester, app.db);
  });

  test('cờ chỉ ghi khi tạo DB mới, không ghi khi nâng cấp (D-041)', () async {
    final dir = Directory.systemTemp.createTempSync('vigon_onb_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final fresh = AppDatabase(NativeDatabase(file));
    expect(
      await SettingsRepository(fresh).watchOnboardingPending().first,
      isTrue,
    );
    // Như máy đã dùng bản trước: chưa có cờ, schema 5.
    await SettingsRepository(fresh).finishOnboarding();
    await fresh.customStatement(
      'ALTER TABLE recurring_rules DROP COLUMN weekdays',
    );
    await fresh.customStatement(
      'ALTER TABLE savings_goals DROP COLUMN completed_at',
    );
    await fresh.customStatement('PRAGMA user_version = 5');
    await fresh.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(
      await SettingsRepository(upgraded).watchOnboardingPending().first,
      isFalse,
    );
  });
  test('Khôi phục file sao lưu thì không hiện lại Màn chào (D-041)', () async {
    final source = AppDatabase(NativeDatabase.memory());
    addTearDown(source.close);
    await SettingsRepository(source).finishOnboarding();
    final json = await exportBackup(source, now: testToday);
    expect(json, isNot(contains(SettingsRepository.onboardingPendingKey)));

    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    expect(
      await SettingsRepository(fresh).watchOnboardingPending().first,
      isTrue,
    );
    await importBackup(fresh, json);
    expect(
      await SettingsRepository(fresh).watchOnboardingPending().first,
      isFalse,
    );
  });
}
