import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/app.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/pin_service.dart';
import 'package:vigon/src/data/settings_repository.dart';
import 'package:vigon/src/features/lock/app_lock.dart';
import 'package:vigon/src/providers.dart';

/// Ngày cố định cho test.
final testToday = DateTime(2026, 11, 3, 9);

/// Cơ sở dữ liệu trong bộ nhớ cho widget test. Phải tạo bên trong thân
/// `testWidgets`; tạo ở `setUp` thì thao tác đầu tiên bị treo.
AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Chờ thao tác cơ sở dữ liệu thật xong rồi vẽ lại.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

/// Mở app với cơ sở dữ liệu mới, tiếng Việt, VND, ngày [testToday].
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  String? localeCode = 'vi',
  AppDatabase? db,
  SecretStore? secrets,
  DateTime Function()? clock,
  List overrides = const [],
}) async {
  usePhoneScreen(tester);
  final database = db ?? memoryDatabase();
  await tester.runAsync(
    () async {
      final settings = SettingsRepository(database);
      await settings.setLocaleCode(localeCode);
      // Test mặc định VND (app thật mặc định USD, D-036).
      await settings.ensureCurrency(defaultCode: 'VND');
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock ?? () => testToday),
        secretStoreProvider.overrideWithValue(secrets ?? MemorySecretStore()),
        appVersionProvider.overrideWith((ref) async => '1.0.0 (1)'),
        ...overrides.cast(),
      ],
      child: VigonApp(router: createRouter()),
    ),
  );
  await settle(tester);
  return database;
}

/// Màn hình dọc 360×800 dp, bề rộng nhỏ nhất SPEC hỗ trợ (mục 5).
void usePhoneScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Gỡ cây widget và đóng cơ sở dữ liệu để không còn stream treo khi test kết thúc.
Future<void> disposeApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(db.close);
}

/// Bỏ khoảng trắng không ngắt mà intl dùng trong số tiền.
String plain(String s) => s.replaceAll(' ', ' ');

/// Tìm Text có nội dung [text] sau khi đổi khoảng trắng không ngắt.
Finder findPlainText(String text) => find.byWidgetPredicate(
  (w) => w is Text && w.data != null && plain(w.data!) == text,
);

/// Tìm vùng có nhãn đọc [label] (không phân biệt dấu cách thường/không ngắt),
/// ví dụ thanh Số dư hiện "Số dư" và số tiền ở hai chỗ nhưng đọc một câu.
Finder findSemanticsLabel(String label) => find.byWidgetPredicate(
  (w) =>
      w is Semantics &&
      w.properties.label != null &&
      plain(w.properties.label!) == label,
);

/// Ghi một khoản thẳng vào cơ sở dữ liệu.
Future<int> insertEntry(
  WidgetTester tester,
  AppDatabase db, {
  required EntryType type,
  required int amount,
  int? categoryId,
  int accountId = 1,
  int? toAccountId,
  String date = '2026-11-03',
  String? time,
  String? note,
}) async {
  final id = await tester.runAsync(
    () => db
        .into(db.entries)
        .insert(
          EntriesCompanion.insert(
            type: type,
            amount: amount,
            categoryId: Value(categoryId),
            accountId: accountId,
            toAccountId: Value(toAccountId),
            date: date,
            time: Value(time),
            note: Value(note),
          ),
        ),
  );
  await settle(tester);
  return id!;
}

/// Đi thẳng tới [route] của app đang chạy (đường dẫn gốc, ví dụ `/savings`).
Future<void> goTo(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await settle(tester);
}
