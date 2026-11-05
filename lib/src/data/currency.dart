import 'dart:math';

import 'package:drift/drift.dart';

import 'calculator.dart';
import 'currency_table.dart';
import 'database.dart';
import 'exchange_rate.dart';
import 'money.dart';
import 'settings_repository.dart';

/// Tiền tệ chọn được trong Cài đặt: toàn bộ mã ISO 4217 đang lưu hành (AC-21, AC-53).
final supportedCurrencies = [for (final c in currencyTable) c.code];

/// Quy đổi xong có số tiền vượt [maxMinorUnits]: không đổi gì (AC-21).
class CurrencyConversionOverflow implements Exception {
  const CurrencyConversionOverflow(this.value);

  /// Số đầu tiên vượt giới hạn, đơn vị nhỏ nhất của tiền mới.
  final BigInt value;

  @override
  String toString() => 'CurrencyConversionOverflow($value)';
}

/// Đổi tiền tệ của app sang [newCode] và quy đổi MỌI số tiền theo [rate]
/// ("1 tiền cũ = rate tiền mới") trong MỘT giao dịch (D-025, AC-21):
/// khoản thu chi và chuyển tiền, khoản định kỳ, số dư ban đầu tài khoản, hạn
/// mức danh mục, ngân sách tháng.
///
/// Làm tròn half-up tới đơn vị nhỏ nhất của tiền mới ([convertMinorUnits]).
/// Số phải > 0 (khoản, khoản định kỳ, hạn mức, ngân sách) nhỏ hơn 1 đơn vị sau
/// làm tròn thì thành 1. Có số nào vượt [maxMinorUnits] thì ném
/// [CurrencyConversionOverflow] và không đổi gì. Lỗi giữa chừng thì giao dịch
/// quay lui, dữ liệu như cũ. Cùng mã với tiền hiện tại thì không làm gì.
Future<void> convertCurrency(
  AppDatabase db,
  String newCode,
  ExchangeRate rate,
) => db.transaction(() async {
  final settings = SettingsRepository(db);
  final oldCode = await settings.readCurrency();
  if (oldCode == newCode) return;
  final fromDigits = currencyDecimalDigits(oldCode);
  final toDigits = currencyDecimalDigits(newCode);

  int convert(int amount, {required bool positive}) {
    final v = convertMinorUnits(
      amount,
      rate,
      fromDigits: fromDigits,
      toDigits: toDigits,
    );
    if (v.abs() > BigInt.from(maxMinorUnits)) {
      throw CurrencyConversionOverflow(v);
    }
    return positive ? max(1, v.toInt()) : v.toInt();
  }

  // Tính hết trước, rồi mới ghi: vượt giới hạn thì chưa ghi dòng nào.
  final entries = [
    for (final e in await db.select(db.entries).get())
      (e.id, convert(e.amount, positive: true)),
  ];
  final rules = [
    for (final r in await db.select(db.recurringRules).get())
      (r.id, convert(r.amount, positive: true)),
  ];
  final accounts = [
    for (final a in await db.select(db.accounts).get())
      if (a.initialBalance != 0)
        (a.id, convert(a.initialBalance, positive: false)),
  ];
  final categories = [
    for (final c in await db.select(db.categories).get())
      if (c.budget != null) (c.id, convert(c.budget!, positive: true)),
  ];
  final oldBudget = await settings.readBudget();
  final budget = oldBudget == null ? null : convert(oldBudget, positive: true);

  await db.batch((b) {
    for (final (id, amount) in entries) {
      b.update(
        db.entries,
        EntriesCompanion(amount: Value(amount)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, amount) in rules) {
      b.update(
        db.recurringRules,
        RecurringRulesCompanion(amount: Value(amount)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, amount) in accounts) {
      b.update(
        db.accounts,
        AccountsCompanion(initialBalance: Value(amount)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, amount) in categories) {
      b.update(
        db.categories,
        CategoriesCompanion(budget: Value(amount)),
        where: (t) => t.id.equals(id),
      );
    }
  });
  if (budget != null) await settings.setBudget(budget);
  await settings.setCurrency(newCode);
});

/// Số tiền làm ví dụ trong hộp xác nhận quy đổi: khoản mới nhất, không có thì
/// ngân sách tháng; null khi chưa có số nào.
Future<int?> conversionExampleAmount(AppDatabase db) async {
  final latest =
      await (db.select(db.entries)
            ..orderBy([
              (e) => OrderingTerm.desc(e.date),
              (e) => OrderingTerm.desc(e.id),
            ])
            ..limit(1))
          .getSingleOrNull();
  return latest?.amount ?? await SettingsRepository(db).readBudget();
}
