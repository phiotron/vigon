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

/// Số chữ số lẻ của số tiền chính xác: phần triệu đơn vị chính ("micro",
/// D-029). Mọi tiền tệ ISO có ≤ 3 chữ số lẻ nên micro luôn mịn hơn đơn vị nhỏ
/// nhất.
const exactDigits = 6;

/// Số micro trong một đơn vị nhỏ nhất của tiền có [digits] chữ số lẻ.
int microPerMinor(int digits) {
  assert(digits >= 0 && digits <= exactDigits);
  var v = 1;
  for (var i = digits; i < exactDigits; i++) {
    v *= 10;
  }
  return v;
}

/// Chia làm tròn half-up đối xứng (0,5 ra xa số 0), [den] > 0.
BigInt _divHalfUp(BigInt num, BigInt den) {
  final q = (num.abs() * BigInt.two + den) ~/ (den * BigInt.two);
  return num.isNegative ? -q : q;
}

/// Làm tròn half-up số micro về đơn vị nhỏ nhất của tiền có [digits] chữ số lẻ.
int roundMicroToMinor(int micro, int digits) =>
    _divHalfUp(BigInt.from(micro), BigInt.from(microPerMinor(digits))).toInt();

/// Số tiền chính xác (micro) của một dòng (D-029, tự kiểm, không trigger):
/// [micro] nếu làm tròn nó về [digits] chữ số lẻ ra đúng [amount]; không thì
/// (null, hoặc người dùng đã sửa tay số tiền) là [amount] × 10^(6 − digits).
int exactMicro(int amount, int? micro, int digits) {
  if (micro != null && roundMicroToMinor(micro, digits) == amount) {
    return micro;
  }
  return amount * microPerMinor(digits);
}

/// Quy đổi số chính xác [exact] (micro tiền cũ) theo [rate] ("1 tiền cũ = rate
/// tiền mới"): micro tiền mới (half-up về micro) và đơn vị nhỏ nhất của tiền
/// mới (half-up từ micro mới về [toDigits] chữ số lẻ). Tính bằng BigInt, không
/// sai số, không tràn.
({BigInt micro, BigInt minor}) convertExact(
  int exact,
  ExchangeRate rate, {
  required int toDigits,
}) {
  final micro = _divHalfUp(
    BigInt.from(exact) * rate.numerator,
    rate.denominator,
  );
  final minor = _divHalfUp(micro, BigInt.from(microPerMinor(toDigits)));
  return (micro: micro, minor: minor);
}

/// Đổi tiền tệ của app sang [newCode] và quy đổi MỌI số tiền theo [rate]
/// ("1 tiền cũ = rate tiền mới") trong MỘT giao dịch (D-025, AC-21, D-029):
/// khoản thu chi và chuyển tiền, khoản định kỳ, số dư ban đầu tài khoản, hạn
/// mức danh mục, ngân sách tháng; bản 2.0 thêm mục tiêu tiết kiệm, khoản nợ,
/// lần trả, mục hàng đợi (AC-122).
///
/// Quy đổi từ số tiền CHÍNH XÁC ([exactMicro], 6 chữ số lẻ) chứ không từ số
/// đã làm tròn, rồi ghi cả hai: số làm tròn half-up về đơn vị nhỏ nhất của
/// tiền mới (cột hiện, cộng tổng) và số chính xác (cột `*Micro`, null khi bằng
/// đúng số làm tròn). Nhờ vậy đổi A→B→A cùng bảng tỉ giá ra đúng số cũ (AC-73).
/// Khoản, khoản định kỳ, khoản nợ, lần trả, mục hàng đợi có thể thành 0 (số
/// rất nhỏ); hạn mức danh mục, ngân sách tháng và mục tiêu tiết kiệm tối
/// thiểu 1 đơn vị; số dư ban đầu có dấu. Có số nào vượt
/// [maxMinorUnits] thì ném [CurrencyConversionOverflow] và không đổi gì. Lỗi
/// giữa chừng thì giao dịch quay lui, dữ liệu như cũ. Cùng mã với tiền hiện
/// tại thì không làm gì.
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
  final scale = microPerMinor(toDigits);

  /// (số làm tròn, số chính xác hoặc null khi bằng đúng số làm tròn).
  (int, int?) convert(int amount, int? micro, {bool atLeastOne = false}) {
    final v = convertExact(
      exactMicro(amount, micro, fromDigits),
      rate,
      toDigits: toDigits,
    );
    if (v.minor.abs() > BigInt.from(maxMinorUnits)) {
      throw CurrencyConversionOverflow(v.minor);
    }
    final minor = v.minor.toInt();
    // Hạn mức, ngân sách phải > 0: nâng lên 1, số chính xác là chính số 1 đó.
    if (atLeastOne && minor < 1) return (1, null);
    final newMicro = v.micro.toInt();
    return (minor, newMicro == minor * scale ? null : newMicro);
  }

  // Tính hết trước, rồi mới ghi: vượt giới hạn thì chưa ghi dòng nào.
  final entries = [
    for (final e in await db.select(db.entries).get())
      (e.id, convert(e.amount, e.amountMicro)),
  ];
  final rules = [
    for (final r in await db.select(db.recurringRules).get())
      (r.id, convert(r.amount, r.amountMicro)),
  ];
  final accounts = [
    for (final a in await db.select(db.accounts).get())
      if (a.initialBalance != 0 || a.initialBalanceMicro != null)
        (a.id, convert(a.initialBalance, a.initialBalanceMicro)),
  ];
  final categories = [
    for (final c in await db.select(db.categories).get())
      if (c.budget != null)
        (c.id, convert(c.budget!, c.budgetMicro, atLeastOne: true)),
  ];
  // Bản 2.0 (AC-122): mục tiêu tiết kiệm (tối thiểu 1), khoản nợ, lần trả,
  // mục hàng đợi. Mục hàng đợi chỉ đổi khi đang ở đúng tiền tệ cũ của app
  // (mục bằng tiền khác — AC-87 — giữ nguyên số và tiền tệ của nó).
  final goals = [
    for (final g in await db.select(db.savingsGoals).get())
      (g.id, convert(g.targetAmount, g.targetAmountMicro, atLeastOne: true)),
  ];
  final debts = [
    for (final d in await db.select(db.debts).get())
      (d.id, convert(d.amount, d.amountMicro)),
  ];
  final payments = [
    for (final p in await db.select(db.debtPayments).get())
      (p.id, convert(p.amount, p.amountMicro)),
  ];
  final queue = [
    for (final q in await (db.select(
      db.importQueueItems,
    )..where((q) => q.currency.equals(oldCode))).get())
      (q.id, convert(q.amount, q.amountMicro)),
  ];
  final oldBudget = await settings.readBudget();
  final budget = oldBudget == null
      ? null
      : convert(oldBudget, await settings.readBudgetMicro(), atLeastOne: true);

  await db.batch((b) {
    for (final (id, (amount, micro)) in entries) {
      b.update(
        db.entries,
        EntriesCompanion(amount: Value(amount), amountMicro: Value(micro)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in rules) {
      b.update(
        db.recurringRules,
        RecurringRulesCompanion(
          amount: Value(amount),
          amountMicro: Value(micro),
        ),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in accounts) {
      b.update(
        db.accounts,
        AccountsCompanion(
          initialBalance: Value(amount),
          initialBalanceMicro: Value(micro),
        ),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in categories) {
      b.update(
        db.categories,
        CategoriesCompanion(budget: Value(amount), budgetMicro: Value(micro)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in goals) {
      b.update(
        db.savingsGoals,
        SavingsGoalsCompanion(
          targetAmount: Value(amount),
          targetAmountMicro: Value(micro),
        ),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in debts) {
      b.update(
        db.debts,
        DebtsCompanion(amount: Value(amount), amountMicro: Value(micro)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in payments) {
      b.update(
        db.debtPayments,
        DebtPaymentsCompanion(amount: Value(amount), amountMicro: Value(micro)),
        where: (t) => t.id.equals(id),
      );
    }
    for (final (id, (amount, micro)) in queue) {
      b.update(
        db.importQueueItems,
        ImportQueueItemsCompanion(
          amount: Value(amount),
          amountMicro: Value(micro),
          currency: Value(newCode),
        ),
        where: (t) => t.id.equals(id),
      );
    }
  });
  if (budget != null) {
    await settings.setBudget(budget.$1);
    await settings.setBudgetMicro(budget.$2);
  } else {
    await settings.setBudgetMicro(null);
  }
  await settings.setCurrency(newCode);
});

/// Số tiền làm ví dụ trong hộp xác nhận quy đổi: khoản mới nhất, không có thì
/// ngân sách tháng; null khi chưa có số nào. [minor] là số đang hiện, [exact]
/// là số chính xác (micro, D-029) để tính "sau quy đổi" đúng như khi đổi thật.
Future<({int minor, int exact})?> conversionExampleAmount(
  AppDatabase db,
) async {
  final digits = currencyDecimalDigits(
    await SettingsRepository(db).readCurrency(),
  );
  final latest =
      await (db.select(db.entries)
            ..orderBy([
              (e) => OrderingTerm.desc(e.date),
              (e) => OrderingTerm.desc(e.id),
            ])
            ..limit(1))
          .getSingleOrNull();
  if (latest != null) {
    return (
      minor: latest.amount,
      exact: exactMicro(latest.amount, latest.amountMicro, digits),
    );
  }
  final settings = SettingsRepository(db);
  final budget = await settings.readBudget();
  if (budget == null) return null;
  return (
    minor: budget,
    exact: exactMicro(budget, await settings.readBudgetMicro(), digits),
  );
}
