import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'data/account_repository.dart';
import 'data/category_repository.dart';
import 'data/database.dart';
import 'data/dates.dart';
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

/// Tài khoản đang hiện; tài khoản đã ẩn không có ở đây (AC-44).
final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watch(),
);

/// Mọi tài khoản kể cả đã ẩn, để gọi tên tài khoản của khoản cũ (AC-44).
final allAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAll(),
);

/// Tài khoản đã ẩn (AC-47).
final archivedAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchArchived(),
);

/// Tài khoản đã có khoản hay chuỗi định kỳ trỏ tới chưa (AC-45).
final accountInUseProvider = StreamProvider.family<bool, int>(
  (ref, id) => ref.watch(accountRepositoryProvider).watchInUse(id),
);

/// Kỳ đang xem trên màn chính; mặc định tháng hiện tại (AC-10).
class PeriodNotifier extends Notifier<Period> {
  @override
  Period build() {
    // Đổi ngày đầu tuần/tháng thì tính lại kỳ cùng loại, không đổi loại kỳ.
    void recompute(Object? previous, Object? next) {
      if (previous == next) return;
      final type = state.type;
      if (type == PeriodType.week || type == PeriodType.month) selectType(type);
    }

    ref.listen(weekStartProvider, (p, n) => recompute(p?.value, n.value));
    ref.listen(monthStartDayProvider, (p, n) => recompute(p?.value, n.value));
    return Period.containing(
      PeriodType.month,
      ref.read(clockProvider)(),
      weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
      monthStartDay: ref.read(monthStartDayProvider).value ?? 1,
    );
  }

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
  int? build() {
    // Tài khoản đang lọc bị ẩn hoặc xóa thì bỏ bộ lọc (AC-44).
    ref.listen(accountsProvider, (_, next) {
      final visible = next.value;
      if (state != null &&
          visible != null &&
          !visible.any((a) => a.id == state)) {
        state = null;
      }
    });
    return null;
  }

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

/// Phiên bản app cho màn Giới thiệu, ví dụ "1.0.0 (1)"; test ghi đè.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

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

/// Ngày hôm nay. Làm mới khi app quay lại từ nền, để app sống qua nửa đêm hay
/// qua ngày đầu tháng vẫn tính ngân sách đúng tháng.
class TodayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.read(clockProvider)());

  void refresh() {
    final today = dateOnly(ref.read(clockProvider)());
    if (today != state) state = today;
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

/// Tổng chi của tháng hiện tại (theo ngày bắt đầu tháng), mọi tài khoản (AC-27).
///
/// Chờ cài đặt ngày bắt đầu tháng đọc xong rồi mới tính: không đoán ngày 1, để
/// không phát ra số của sai kỳ lúc khởi động (widget F-26 đẩy số này ra ngoài).
final budgetSpentProvider = StreamProvider<int>((ref) async* {
  final today = ref.watch(todayProvider);
  final entries = ref.watch(entryRepositoryProvider);
  final monthStartDay = await ref.watch(monthStartDayProvider.future);
  final month = Period.containing(
    PeriodType.month,
    today,
    monthStartDay: monthStartDay,
  );
  yield* entries
      .watchEntries(month)
      .map((rows) => PeriodSummary.of(rows).expense);
});
