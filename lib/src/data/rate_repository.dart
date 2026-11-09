import 'package:drift/drift.dart';

import 'calculator.dart';
import 'database.dart';
import 'exchange_rate.dart';
import 'money.dart';
import 'settings_repository.dart';

/// Kết quả một lần làm mới tỉ giá (D-037).
enum RatesRefreshResult { updated, notNeeded, failed }

/// Tỉ giá tự động (cache trong settings) + ghi đè theo cặp + bảng dự phòng.
///
/// Nguồn: open.er-api.com (ExchangeRate-API Open Access) — miễn phí, không
/// khóa, cập nhật mỗi ngày; điều khoản yêu cầu ghi công nguồn.
class RateRepository {
  RateRepository(this._db, this._settings, this._source, this._clock);

  final AppDatabase _db;
  final SettingsRepository _settings;
  final ExchangeRateSource _source;
  final DateTime Function() _clock;

  /// Bảng cũ ≥ 1 ngày thì tải lại (Q2).
  static const staleAfter = Duration(days: 1);

  /// Bảng đang dùng: cache tải được, không có thì bảng đóng gói; luôn áp ghi
  /// đè của người dùng.
  Future<RateTable> load() async {
    final cached = await _settings.readRateTable();
    final overrides = await _settings.readRateOverrides();
    return (cached ?? RateTable.fallback).withOverrides(overrides);
  }

  /// Mọi tiền tệ đang có số liệu (D-037): Tiền tệ chính, tài khoản, khoản,
  /// chuỗi định kỳ, mục tiêu, nợ/lần trả, ngân sách tháng và hạn mức danh mục.
  /// Màn Tỷ giá chỉ hiện cặp với Tiền tệ chính có trong tập này.
  Future<Set<String>> usedCurrencies() async {
    final result = <String>{await _settings.readPrimaryCurrency()};
    final budgetCurrency = await _settings.readBudgetCurrency();
    if (budgetCurrency != null) result.add(budgetCurrency);
    final rows = await _db.customSelect('''
          SELECT currency AS c FROM accounts
          UNION SELECT currency FROM entries
          UNION SELECT to_currency FROM entries WHERE to_currency IS NOT NULL
          UNION SELECT currency FROM recurring_rules
          UNION SELECT to_currency FROM recurring_rules
            WHERE to_currency IS NOT NULL
          UNION SELECT currency FROM savings_goals
          UNION SELECT currency FROM debts
          UNION SELECT currency FROM debt_payments
          UNION SELECT budget_currency FROM categories
            WHERE budget_currency IS NOT NULL
        ''').get();
    for (final row in rows) {
      result.add(row.read<String>('c'));
    }
    return result;
  }

  /// Theo dõi settings để màn Tỷ giá tự cập nhật khi tải/ghi đè.
  Stream<RateTable> watch() => _db
      .select(_db.settings)
      .watch()
      .asyncMap((_) => load())
      .distinct(
        (a, b) => a.date == b.date && a.overrides.length == b.overrides.length,
      );

  /// Tải bảng mới nếu bảng cũ ≥ 1 ngày (hoặc [force]); không ném lỗi.
  Future<RatesRefreshResult> refreshIfStale({bool force = false}) async {
    final current = await load();
    if (!force && !current.isStale(_clock())) {
      return RatesRefreshResult.notNeeded;
    }
    try {
      final fetched = await _source.fetch();
      await _settings.setRateTable(fetched);
      return RatesRefreshResult.updated;
    } catch (_) {
      return RatesRefreshResult.failed;
    }
  }
}

/// Quy đổi số tiền giữa các tiền tệ bằng bảng tỉ giá hiện tại.
class CurrencyService {
  const CurrencyService(this.table, this.primary);

  final RateTable table;
  final String primary;

  bool has(String from, String to) => table.rate(from, to) != null;

  /// Quy đổi [amount] (đơn vị nhỏ nhất của [from]) sang [to]; null nếu thiếu
  /// cặp tỉ giá.
  int? convert(int amount, String from, String to) {
    if (from == to) return amount;
    final rate = table.rate(from, to);
    if (rate == null) return null;
    final value = convertMinorUnits(
      amount,
      rate,
      fromDigits: currencyDecimalDigits(from),
      toDigits: currencyDecimalDigits(to),
    );
    if (value.abs() > BigInt.from(maxMinorUnits)) return null;
    return value.toInt();
  }

  int? toPrimary(int amount, String currency) =>
      convert(amount, currency, primary);

  int? fromPrimary(int amount, String currency) =>
      convert(amount, primary, currency);
}

/// Chuyển các số gốc cũ (chưa có cột gốc) thành số gốc trước khi đổi Tiền tệ
/// chính: giữ nguyên số người dùng đã ghi, gán tiền tệ cũ. Không làm gì với
/// dòng đã có số gốc.
Future<void> promoteLegacyAmounts(AppDatabase db, String oldPrimary) =>
    db.transaction(() async {
      await db.customStatement(
        'UPDATE accounts SET initial_balance_original = initial_balance, '
        'initial_currency = currency WHERE initial_balance_original IS NULL',
        [],
      );
      await db.customStatement(
        'UPDATE entries SET original_amount = amount, currency = ? '
        'WHERE original_amount IS NULL',
        [oldPrimary],
      );
      await db.customStatement(
        'UPDATE recurring_rules SET original_amount = amount, currency = ? '
        'WHERE original_amount IS NULL',
        [oldPrimary],
      );
      await db.customStatement(
        'UPDATE savings_goals SET original_target_amount = target_amount, '
        'currency = ? WHERE original_target_amount IS NULL',
        [oldPrimary],
      );
      await db.customStatement(
        'UPDATE debts SET original_amount = amount, currency = ? '
        'WHERE original_amount IS NULL',
        [oldPrimary],
      );
      await db.customStatement(
        'UPDATE debt_payments SET original_amount = amount, currency = ? '
        'WHERE original_amount IS NULL',
        [oldPrimary],
      );
      await db.customStatement(
        'UPDATE categories SET budget_original = budget, budget_currency = ? '
        'WHERE budget IS NOT NULL AND budget_original IS NULL',
        [oldPrimary],
      );
      final settings = SettingsRepository(db);
      final budget = await settings.readBudget();
      if (budget != null && await settings.readBudgetOriginal() == null) {
        await settings.setBudgetOriginal(budget);
        await settings.setBudgetCurrency(
          await settings.readBudgetCurrency() ?? oldPrimary,
        );
      }
    });

/// Quy đổi lại MỌI cột dẫn xuất (số dùng để cộng/hiển thị) từ số gốc theo
/// bảng tỉ giá hiện tại (Q9, D-037). Không sửa số gốc; cặp thiếu tỉ giá thì
/// giữ số cũ để không mất dữ liệu.
Future<void> recomputeDerivedAmounts(
  AppDatabase db,
  CurrencyService service,
) async {
  final primary = service.primary;

  int? converted(int? original, String currency) {
    if (original == null) return null;
    if (currency == primary) return original;
    return service.toPrimary(original, currency);
  }

  await db.transaction(() async {
    final accounts = await db.select(db.accounts).get();
    final entries = await db.select(db.entries).get();
    final rules = await db.select(db.recurringRules).get();
    final goals = await db.select(db.savingsGoals).get();
    final debts = await db.select(db.debts).get();
    final payments = await db.select(db.debtPayments).get();
    final categories = await db.select(db.categories).get();
    final settings = SettingsRepository(db);

    await db.batch((b) {
      for (final a in accounts) {
        final original = a.initialBalanceOriginal ?? a.initialBalance;
        final currency = a.initialCurrency ?? a.currency;
        final amount = converted(original, currency);
        if (amount == null) continue;
        b.update(
          db.accounts,
          AccountsCompanion(
            initialBalance: Value(amount),
            initialBalanceMicro: Value(
              amount == original && currency == primary
                  ? a.initialBalanceMicro
                  : null,
            ),
          ),
          where: (t) => t.id.equals(a.id),
        );
      }
      for (final e in entries) {
        final original = e.originalAmount ?? e.amount;
        final amount = converted(original, e.currency);
        if (amount == null) continue;
        final toOriginal = e.toOriginalAmount;
        final toCurrency = e.toCurrency;
        final toAmount = toOriginal == null || toCurrency == null
            ? null
            : converted(toOriginal, toCurrency);
        b.update(
          db.entries,
          EntriesCompanion(
            amount: Value(amount),
            amountMicro: Value(
              amount == original && e.currency == primary
                  ? e.amountMicro
                  : null,
            ),
            toAmount: Value(toAmount),
          ),
          where: (t) => t.id.equals(e.id),
        );
      }
      for (final r in rules) {
        final original = r.originalAmount ?? r.amount;
        final amount = converted(original, r.currency);
        if (amount == null) continue;
        final toOriginal = r.toOriginalAmount;
        final toCurrency = r.toCurrency;
        b.update(
          db.recurringRules,
          RecurringRulesCompanion(
            amount: Value(amount),
            amountMicro: Value(
              amount == original && r.currency == primary
                  ? r.amountMicro
                  : null,
            ),
            toAmount: Value(
              toOriginal == null || toCurrency == null
                  ? null
                  : converted(toOriginal, toCurrency),
            ),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
      for (final g in goals) {
        final original = g.originalTargetAmount ?? g.targetAmount;
        final amount = converted(original, g.currency);
        if (amount == null) continue;
        b.update(
          db.savingsGoals,
          SavingsGoalsCompanion(
            targetAmount: Value(amount < 1 ? 1 : amount),
            targetAmountMicro: Value(
              amount == original && g.currency == primary
                  ? g.targetAmountMicro
                  : null,
            ),
          ),
          where: (t) => t.id.equals(g.id),
        );
      }
      for (final d in debts) {
        final original = d.originalAmount ?? d.amount;
        final amount = converted(original, d.currency);
        if (amount == null) continue;
        b.update(
          db.debts,
          DebtsCompanion(
            amount: Value(amount),
            amountMicro: Value(
              amount == original && d.currency == primary
                  ? d.amountMicro
                  : null,
            ),
          ),
          where: (t) => t.id.equals(d.id),
        );
      }
      for (final p in payments) {
        final original = p.originalAmount ?? p.amount;
        final amount = converted(original, p.currency);
        if (amount == null) continue;
        b.update(
          db.debtPayments,
          DebtPaymentsCompanion(
            amount: Value(amount),
            amountMicro: Value(
              amount == original && p.currency == primary
                  ? p.amountMicro
                  : null,
            ),
          ),
          where: (t) => t.id.equals(p.id),
        );
      }
      for (final c in categories) {
        final original = c.budgetOriginal ?? c.budget;
        final currency = c.budgetCurrency ?? primary;
        final amount = converted(original, currency);
        if (amount == null) continue;
        b.update(
          db.categories,
          CategoriesCompanion(
            budget: Value(amount < 1 ? 1 : amount),
            budgetMicro: Value(
              amount == original && currency == primary ? c.budgetMicro : null,
            ),
          ),
          where: (t) => t.id.equals(c.id),
        );
      }
    });

    final budgetOriginal = await settings.readBudgetOriginal();
    final budgetCurrency = await settings.readBudgetCurrency() ?? primary;
    final budget = await settings.readBudget();
    final original = budgetOriginal ?? budget;
    if (original != null) {
      final amount = converted(original, budgetCurrency);
      if (amount != null) {
        await settings.setBudget(amount < 1 ? 1 : amount);
        await settings.setBudgetMicro(null);
      }
    }
    await settings.setRatesAppliedDate(service.table.date);
  });
}
