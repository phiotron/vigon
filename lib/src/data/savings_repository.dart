import 'package:drift/drift.dart';

import 'database.dart';

/// Tài khoản đã gắn một mục tiêu khác (AC-100: một tài khoản tối đa một mục tiêu).
class AccountHasGoalException implements Exception {
  const AccountHasGoalException(this.accountId);

  final int accountId;

  @override
  String toString() => 'AccountHasGoalException($accountId)';
}

/// Đọc, ghi mục tiêu tiết kiệm (AC-100..AC-103). Tiến độ = số dư của tài
/// khoản gắn (`AccountRepository.watchBalances`), không lưu ở đây.
class SavingsGoalRepository {
  SavingsGoalRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$SavingsGoalsTable, SavingsGoal> _ordered() =>
      _db.select(_db.savingsGoals)..orderBy([
        (g) => OrderingTerm(expression: g.createdAt),
        (g) => OrderingTerm(expression: g.id),
      ]);

  Stream<List<SavingsGoal>> watchAll() => _ordered().watch();

  Future<List<SavingsGoal>> all() => _ordered().get();

  Future<SavingsGoal?> find(int id) => (_db.select(
    _db.savingsGoals,
  )..where((g) => g.id.equals(id))).getSingleOrNull();

  /// Mục tiêu của tài khoản [accountId], nếu có.
  Future<SavingsGoal?> forAccount(int accountId) => (_db.select(
    _db.savingsGoals,
  )..where((g) => g.accountId.equals(accountId))).getSingleOrNull();

  /// Id các tài khoản đã gắn mục tiêu (để ẩn khỏi lựa chọn khi tạo mục tiêu).
  Stream<Set<int>> watchLinkedAccountIds() =>
      watchAll().map((goals) => {for (final g in goals) g.accountId});

  /// Tạo mục tiêu gắn tài khoản có sẵn [accountId]. Ném
  /// [AccountHasGoalException] nếu tài khoản đã gắn mục tiêu khác.
  Future<int> add({
    required String name,
    required int targetAmount,
    required int accountId,
    String? dueDate,
    int? originalTargetAmount,
    String? currency,
  }) {
    _checkTarget(targetAmount);
    return _db.transaction(() async {
      if (await forAccount(accountId) != null) {
        throw AccountHasGoalException(accountId);
      }
      return _db
          .into(_db.savingsGoals)
          .insert(
            SavingsGoalsCompanion.insert(
              name: name,
              targetAmount: targetAmount,
              accountId: accountId,
              dueDate: Value(dueDate),
              currency: Value(currency ?? 'USD'),
              originalTargetAmount: Value(originalTargetAmount ?? targetAmount),
            ),
          );
    });
  }

  /// "Tạo tài khoản mới" (AC-100): tài khoản tên = tên mục tiêu, số dư ban
  /// đầu 0, rồi mục tiêu gắn nó — cùng một giao dịch. Trả về (id mục tiêu,
  /// id tài khoản).
  Future<(int, int)> addWithNewAccount({
    required String name,
    required int targetAmount,
    String? dueDate,
    int? originalTargetAmount,
    String currency = 'USD',
  }) {
    _checkTarget(targetAmount);
    return _db.transaction(() async {
      final accountId = await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: Value(name),
              currency: Value(currency),
              initialCurrency: Value(currency),
            ),
          );
      final goalId = await add(
        name: name,
        targetAmount: targetAmount,
        accountId: accountId,
        dueDate: dueDate,
        originalTargetAmount: originalTargetAmount,
        currency: currency,
      );
      return (goalId, accountId);
    });
  }

  /// Sửa tên, số tiền mục tiêu, hạn. Đổi số tiền thì bỏ số chính xác cũ (D-029).
  Future<void> edit(
    int id, {
    required String name,
    required int targetAmount,
    String? dueDate,
    int? originalTargetAmount,
    String? currency,
  }) async {
    _checkTarget(targetAmount);
    final old = await find(id);
    if (old == null) return;
    await (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        name: Value(name),
        targetAmount: Value(targetAmount),
        targetAmountMicro: targetAmount == old.targetAmount
            ? const Value.absent()
            : const Value(null),
        dueDate: Value(dueDate),
        originalTargetAmount: Value(originalTargetAmount ?? targetAmount),
        currency: currency == null ? const Value.absent() : Value(currency),
      ),
    );
  }

  /// Xoá mục tiêu; tài khoản và khoản giữ nguyên (AC-103).
  Future<void> delete(int id) =>
      (_db.delete(_db.savingsGoals)..where((g) => g.id.equals(id))).go();

  static void _checkTarget(int targetAmount) {
    if (targetAmount <= 0) {
      throw ArgumentError.value(targetAmount, 'targetAmount', 'phải > 0');
    }
  }
}
