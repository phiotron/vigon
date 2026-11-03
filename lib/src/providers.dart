import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/account_repository.dart';
import 'data/category_repository.dart';
import 'data/database.dart';
import 'data/entry_repository.dart';
import 'data/period.dart';
import 'data/recurring_repository.dart';
import 'data/settings_repository.dart';
import 'data/summary.dart';

/// Cơ sở dữ liệu của app; test ghi đè bằng cơ sở dữ liệu trong bộ nhớ.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Hôm nay; test ghi đè để cố định ngày.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => EntryRepository(ref.watch(databaseProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseProvider)),
);

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemeMode(),
);

final localeCodeProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchLocaleCode(),
);

final currencyProvider = StreamProvider<String>(
  (ref) => ref.watch(settingsRepositoryProvider).watchCurrency(),
);

final weekStartProvider = StreamProvider<int>(
  (ref) => ref.watch(settingsRepositoryProvider).watchWeekStart(),
);

final monthStartDayProvider = StreamProvider<int>(
  (ref) => ref.watch(settingsRepositoryProvider).watchMonthStartDay(),
);

final categoriesProvider = StreamProvider.family<List<Category>, CategoryType>(
  (ref, type) => ref.watch(categoryRepositoryProvider).watch(type),
);

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watch(),
);

/// Kỳ đang xem trên màn chính; mặc định tháng hiện tại (AC-10).
class PeriodNotifier extends Notifier<Period> {
  @override
  Period build() => Period.containing(
    PeriodType.month,
    ref.read(clockProvider)(),
    weekStart: ref.watch(weekStartProvider).value ?? DateTime.monday,
    monthStartDay: ref.watch(monthStartDayProvider).value ?? 1,
  );

  /// Chọn loại kỳ mới, lấy kỳ chứa hôm nay.
  void selectType(PeriodType type) => state = Period.containing(
    type,
    ref.read(clockProvider)(),
    weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
    monthStartDay: ref.read(monthStartDayProvider).value ?? 1,
  );

  void select(Period period) => state = period;

  void shift(int delta) => state = state.shift(delta);
}

final periodProvider = NotifierProvider<PeriodNotifier, Period>(
  PeriodNotifier.new,
);

/// Tài khoản đang lọc trên màn chính; null là tất cả (AC-20).
class AccountFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? accountId) => state = accountId;
}

final accountFilterProvider = NotifierProvider<AccountFilterNotifier, int?>(
  AccountFilterNotifier.new,
);

final periodEntriesProvider = StreamProvider<List<EntryView>>(
  (ref) => ref
      .watch(entryRepositoryProvider)
      .watchEntries(
        ref.watch(periodProvider),
        accountId: ref.watch(accountFilterProvider),
      ),
);

final periodSummaryProvider = Provider<PeriodSummary>(
  (ref) =>
      ref.watch(periodEntriesProvider).whenData(PeriodSummary.of).value ??
      PeriodSummary.empty,
);

/// Ngôn ngữ và vùng của máy, ví dụ `vi_VN`; test ghi đè.
final deviceLocaleProvider = Provider<String>(
  (ref) => WidgetsBinding.instance.platformDispatcher.locale.toString(),
);

/// Việc chạy một lần khi mở app: chọn tiền tệ theo vùng nếu chưa có (AC-21),
/// tạo các khoản định kỳ tới hạn (AC-24).
final startupProvider = FutureProvider<void>((ref) async {
  await ref
      .read(settingsRepositoryProvider)
      .ensureCurrency(ref.read(deviceLocaleProvider));
  await ref
      .read(recurringRepositoryProvider)
      .generateDue(ref.read(clockProvider)());
});

/// Số dư hiện tại của từng tài khoản (AC-18, AC-19).
final accountBalancesProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(accountRepositoryProvider).watchBalances(),
);

/// Hạn mức chi mỗi tháng; null là chưa đặt (AC-26).
final budgetProvider = StreamProvider<int?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchBudget(),
);

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(databaseProvider)),
);

final recurringRulesProvider = StreamProvider<List<RecurringRule>>(
  (ref) => ref.watch(recurringRepositoryProvider).watch(),
);

/// Tổng chi của tháng hiện tại (theo ngày bắt đầu tháng), mọi tài khoản (AC-27).
final budgetSpentProvider = StreamProvider<int>((ref) {
  final month = Period.containing(
    PeriodType.month,
    ref.read(clockProvider)(),
    monthStartDay: ref.watch(monthStartDayProvider).value ?? 1,
  );
  return ref
      .watch(entryRepositoryProvider)
      .watchEntries(month)
      .map((rows) => PeriodSummary.of(rows).expense);
});
