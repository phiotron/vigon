import 'package:drift/drift.dart';

import 'database.dart';
import 'table_watch.dart';

/// Lần trả vượt số còn lại (AC-105).
class DebtOverpaymentException implements Exception {
  const DebtOverpaymentException(this.remaining);

  /// Số còn lại (đơn vị nhỏ nhất) lúc thêm.
  final int remaining;

  @override
  String toString() => 'DebtOverpaymentException(remaining: $remaining)';
}

/// Một khoản nợ cùng các lần trả (cũ trước).
class DebtView {
  const DebtView(this.debt, this.payments);

  final Debt debt;
  final List<DebtPayment> payments;

  /// Số tiền khoản nợ theo tiền tệ của nó (số gốc).
  int get total => debt.originalAmount ?? debt.amount;

  /// Số còn lại theo **tiền tệ của khoản nợ**, tính thẳng từ số gốc (D-042,
  /// AC-148): không qua số dẫn xuất nên đổi Tiền tệ chính không làm lệch, trả
  /// đủ là còn đúng 0. Không âm. [digits] chỉ giữ cho chỗ gọi cũ.
  int remaining([int? digits]) => remainingOf(debt, payments);

  /// Đã trả theo tiền tệ khoản nợ (khớp với [remaining]).
  int paid([int? digits]) => total - remaining();

  /// "Đã xong" (AC-105).
  bool isSettled([int? digits]) => remaining() == 0;
}

/// Số còn lại của [debt] sau [payments], theo tiền tệ khoản nợ. Lần trả luôn
/// cùng tiền tệ khoản nợ (tiền tệ khoá sau lần trả đầu, AC-133).
int remainingOf(Debt debt, List<DebtPayment> payments, [int? digits]) {
  var left = debt.originalAmount ?? debt.amount;
  for (final p in payments) {
    left -= p.originalAmount ?? p.amount;
  }
  return left < 0 ? 0 : left;
}

/// Đọc, ghi khoản nợ và lần trả (AC-104..AC-106). Không tạo khoản (Entry),
/// không đụng số dư tài khoản.
class DebtRepository {
  DebtRepository(this._db);

  final AppDatabase _db;

  /// Mọi khoản nợ (mới nhất trước) kèm lần trả.
  Stream<List<DebtView>> watchAll() =>
      watchTables(_db, [_db.debts, _db.debtPayments]).asyncMap((_) => all());

  Future<List<DebtView>> all() async {
    final debts =
        await (_db.select(_db.debts)..orderBy([
              (d) => OrderingTerm.desc(d.date),
              (d) => OrderingTerm.desc(d.id),
            ]))
            .get();
    final payments =
        await (_db.select(_db.debtPayments)..orderBy([
              (p) => OrderingTerm(expression: p.date),
              (p) => OrderingTerm(expression: p.id),
            ]))
            .get();
    final byDebt = <int, List<DebtPayment>>{};
    for (final p in payments) {
      (byDebt[p.debtId] ??= []).add(p);
    }
    return [for (final d in debts) DebtView(d, byDebt[d.id] ?? const [])];
  }

  Future<DebtView?> find(int id) async {
    final debt = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    if (debt == null) return null;
    final payments =
        await (_db.select(_db.debtPayments)
              ..where((p) => p.debtId.equals(id))
              ..orderBy([
                (p) => OrderingTerm(expression: p.date),
                (p) => OrderingTerm(expression: p.id),
              ]))
            .get();
    return DebtView(debt, payments);
  }

  Future<int> add({
    required String person,
    required DebtDirection direction,
    required int amount,
    required String date,
    String? dueDate,
    String? note,
    int? originalAmount,
    String? currency,
  }) {
    _checkPositive(amount);
    return _db
        .into(_db.debts)
        .insert(
          DebtsCompanion.insert(
            person: person,
            direction: direction,
            amount: amount,
            date: date,
            dueDate: Value(dueDate),
            note: Value(note),
            currency: Value(currency ?? 'USD'),
            originalAmount: Value(originalAmount ?? amount),
          ),
        );
  }

  /// Sửa khoản nợ. Đổi số tiền thì bỏ số chính xác cũ (D-029). Tiền tệ khóa
  /// sau lần trả đầu (D-037): đã có lần trả thì giữ tiền tệ cũ.
  Future<void> edit(
    int id, {
    required String person,
    required DebtDirection direction,
    required int amount,
    required String date,
    String? dueDate,
    String? note,
    int? originalAmount,
    String? currency,
  }) async {
    _checkPositive(amount);
    final old = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    if (old == null) return;
    final hasPayments = await (_db.select(
      _db.debtPayments,
    )..where((p) => p.debtId.equals(id))).get().then((v) => v.isNotEmpty);
    final effectiveCurrency = hasPayments
        ? old.currency
        : currency ?? old.currency;
    await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        person: Value(person),
        direction: Value(direction),
        amount: Value(amount),
        amountMicro: amount == old.amount
            ? const Value.absent()
            : const Value(null),
        date: Value(date),
        dueDate: Value(dueDate),
        note: Value(note),
        currency: Value(effectiveCurrency),
        originalAmount: Value(originalAmount ?? amount),
      ),
    );
  }

  /// Xoá khoản nợ cùng mọi lần trả (khoá ngoại xoá theo).
  Future<void> delete(int id) =>
      (_db.delete(_db.debts)..where((d) => d.id.equals(id))).go();

  /// Thêm lần trả; ném [DebtOverpaymentException] nếu vượt số còn lại (AC-105).
  /// [amount] là số quy về Tiền tệ chính; [originalAmount]/[currency] là số gốc
  /// người dùng nhập (D-037).
  Future<int> addPayment(
    int debtId, {
    required int amount,
    required String date,
    int? originalAmount,
    String? currency,
  }) {
    _checkPositive(amount);
    return _db.transaction(() async {
      final view = await find(debtId);
      if (view == null) throw StateError('không có khoản nợ $debtId');
      // So bằng số gốc theo tiền tệ khoản nợ (G8, AC-158).
      final remaining = view.remaining();
      if ((originalAmount ?? amount) > remaining) {
        throw DebtOverpaymentException(remaining);
      }
      return _db
          .into(_db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              debtId: debtId,
              amount: amount,
              date: date,
              originalAmount: Value(originalAmount ?? amount),
              currency: Value(currency ?? view.debt.currency),
            ),
          );
    });
  }

  /// Xoá một lần trả; số còn lại tự tính lại (AC-105).
  Future<void> deletePayment(int id) =>
      (_db.delete(_db.debtPayments)..where((p) => p.id.equals(id))).go();

  static void _checkPositive(int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'phải > 0');
    }
  }
}
