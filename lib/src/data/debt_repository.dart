import 'package:drift/drift.dart';

import 'balance_guard.dart';
import 'database.dart';
import 'dates.dart';
import 'interest.dart';
import 'rate_repository.dart';
import 'seed.dart';
import 'table_watch.dart';

/// Lần trả vượt gốc còn lại (AC-105, AC-173).
class DebtOverpaymentException implements Exception {
  const DebtOverpaymentException(this.remaining);

  /// Gốc còn lại (đơn vị nhỏ nhất, tiền tệ khoản nợ) lúc thêm.
  final int remaining;

  @override
  String toString() => 'DebtOverpaymentException(remaining: $remaining)';
}

/// Phần lãi của lần trả vượt lãi tới ngày trả chưa trả (AC-173).
class DebtInterestOverException implements Exception {
  const DebtInterestOverException(this.due);

  /// Lãi tới ngày trả còn chưa trả (tiền tệ khoản nợ).
  final int due;

  @override
  String toString() => 'DebtInterestOverException(due: $due)';
}

/// Một khoản nợ cùng các lần trả (cũ trước) và các mốc đổi lãi suất, nhìn
/// tại ngày [asOf] (hôm nay).
class DebtView {
  DebtView(
    this.debt,
    this.payments, {
    this.rateChanges = const [],
    DateTime? asOf,
  }) : asOf = dateOnly(asOf ?? DateTime.now());

  final Debt debt;
  final List<DebtPayment> payments;

  /// Các mốc đổi lãi suất, cũ trước (AC-171).
  final List<DebtRateChange> rateChanges;

  /// Ngày tính "lãi tới hôm nay".
  final DateTime asOf;

  late final DebtInterest interest = DebtInterest.of(
    debt,
    rateChanges,
    payments,
  );

  /// Số tiền khoản nợ (gốc vay) theo tiền tệ của nó (số gốc).
  int get total => debt.originalAmount ?? debt.amount;

  /// Có lãi suất không (AC-171).
  bool get hasInterest => interest.hasInterest;

  /// Gốc còn lại theo tiền tệ khoản nợ.
  int get principalLeft => interest.principalLeft;

  /// Lãi tới hôm nay còn chưa trả (AC-174).
  int get unpaidInterest => interest.unpaidInterest(asOf);

  /// "Còn lại" theo **tiền tệ của khoản nợ**, tính thẳng từ số gốc (D-042,
  /// AC-148): gốc còn lại + lãi tới hôm nay chưa trả (AC-174). Không âm.
  /// [digits] chỉ giữ cho chỗ gọi cũ.
  int remaining([int? digits]) => interest.remaining(asOf);

  /// Gốc đã trả theo tiền tệ khoản nợ.
  int paid([int? digits]) => total - principalLeft;

  /// "Đã xong" (AC-105, AC-174): gốc còn lại 0 và lãi chưa trả 0.
  bool isSettled([int? digits]) => remaining() == 0;

  /// Tổng phải trả ước tính tới hạn (nhắc trước hạn, AC-174); không có hạn
  /// thì như [remaining].
  int dueEstimate() {
    final due = debt.dueDate;
    if (due == null || !hasInterest) return remaining();
    final day = parseDateKey(due);
    return interest.dueEstimate(day.isBefore(asOf) ? asOf : day);
  }
}

/// Số còn lại (chỉ gốc) của [debt] sau [payments], theo tiền tệ khoản nợ.
int remainingOf(Debt debt, List<DebtPayment> payments, [int? digits]) {
  var left = debt.originalAmount ?? debt.amount;
  for (final p in payments) {
    left -= p.originalAmount ?? p.amount;
  }
  return left < 0 ? 0 : left;
}

/// Đọc, ghi khoản nợ, lần trả và mốc lãi suất (AC-104..AC-106, D-049).
///
/// Khoản nợ có tài khoản: số tiền vay là một Debt movement (cho vay = tiền
/// ra, đi vay = tiền vào); mỗi lần trả là Debt movement phần gốc (thu nợ /
/// trả nợ) + khoản lãi (thu "Tiền lãi" / chi "Lãi vay"). Các khoản này ghi
/// theo **tiền tệ tài khoản** (số quy đổi lúc lưu), khoản nợ và lần trả giữ
/// số gốc theo tiền tệ khoản nợ (AC-167, như AC-132).
class DebtRepository {
  DebtRepository(this._db, [DateTime Function()? clock])
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Mọi khoản nợ (mới nhất trước) kèm lần trả.
  Stream<List<DebtView>> watchAll() => watchTables(_db, [
    _db.debts,
    _db.debtPayments,
    _db.debtRateChanges,
  ]).asyncMap((_) => all());

  Future<List<DebtView>> all() async {
    final debts =
        await (_db.select(_db.debts)..orderBy([
              (d) => OrderingTerm.desc(d.date),
              (d) => OrderingTerm.desc(d.id),
            ]))
            .get();
    final payments = await _payments().get();
    final changes = await _changes().get();
    final byDebt = <int, List<DebtPayment>>{};
    for (final p in payments) {
      (byDebt[p.debtId] ??= []).add(p);
    }
    final changesOf = <int, List<DebtRateChange>>{};
    for (final c in changes) {
      (changesOf[c.debtId] ??= []).add(c);
    }
    final today = _clock();
    return [
      for (final d in debts)
        DebtView(
          d,
          byDebt[d.id] ?? const [],
          rateChanges: changesOf[d.id] ?? const [],
          asOf: today,
        ),
    ];
  }

  SimpleSelectStatement<$DebtPaymentsTable, DebtPayment> _payments([
    int? debtId,
  ]) {
    final q = _db.select(_db.debtPayments);
    if (debtId != null) q.where((p) => p.debtId.equals(debtId));
    return q..orderBy([
      (p) => OrderingTerm(expression: p.date),
      (p) => OrderingTerm(expression: p.id),
    ]);
  }

  SimpleSelectStatement<$DebtRateChangesTable, DebtRateChange> _changes([
    int? debtId,
  ]) {
    final q = _db.select(_db.debtRateChanges);
    if (debtId != null) q.where((c) => c.debtId.equals(debtId));
    return q..orderBy([
      (c) => OrderingTerm(expression: c.date),
      (c) => OrderingTerm(expression: c.id),
    ]);
  }

  Future<DebtView?> find(int id) async {
    final debt = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    if (debt == null) return null;
    return DebtView(
      debt,
      await _payments(id).get(),
      rateChanges: await _changes(id).get(),
      asOf: _clock(),
    );
  }

  /// Khoản Debt movement số tiền vay của khoản nợ [debtId] (không phải lần
  /// trả), nếu có.
  Future<Entry?> loanEntry(int debtId) =>
      (_db.select(_db.entries)..where(
            (e) =>
                e.debtId.equals(debtId) &
                e.debtPaymentId.isNull() &
                e.type.equalsValue(EntryType.debt),
          ))
          .getSingleOrNull();

  /// Các khoản của lần trả [paymentId] (phần gốc + phần lãi).
  Future<List<Entry>> paymentEntries(int paymentId) => (_db.select(
    _db.entries,
  )..where((e) => e.debtPaymentId.equals(paymentId))).get();

  /// Thêm khoản nợ. Có [accountId] thì ghi Debt movement số tiền vay trên
  /// tài khoản đó (AC-169), cần [service] để quy số gốc sang tiền tệ tài
  /// khoản; cho vay chịu "có thu mới có chi" (AC-160) — thiếu tiền ném
  /// [InsufficientFundsException], không lưu gì.
  Future<int> add({
    required String person,
    required DebtDirection direction,
    required int amount,
    required String date,
    String? dueDate,
    String? note,
    int? originalAmount,
    String? currency,
    int? accountId,
    int? interestRate,
    InterestPeriod? interestPeriod,
    String? interestStart,
    CurrencyService? service,
  }) {
    _checkPositive(amount);
    final cur = currency ?? 'USD';
    final original = originalAmount ?? amount;
    return _db.transaction(() async {
      final movement = accountId == null
          ? null
          : await _movement(
              accountId: accountId,
              kind: direction == DebtDirection.lent
                  ? DebtMovementKind.lend
                  : DebtMovementKind.borrow,
              original: original,
              currency: cur,
              date: date,
              service: service,
            );
      if (movement != null && service != null) {
        final short = await BalanceGuard(_db, service).checkAdd(movement);
        if (short != null) throw InsufficientFundsException(short);
      }
      final id = await _db
          .into(_db.debts)
          .insert(
            DebtsCompanion.insert(
              person: person,
              direction: direction,
              amount: amount,
              date: date,
              dueDate: Value(dueDate),
              note: Value(note),
              currency: Value(cur),
              originalAmount: Value(original),
              accountId: Value(accountId),
              interestRate: Value(interestRate),
              interestPeriod: Value(
                interestRate == null ? null : interestPeriod,
              ),
              interestStart: Value(interestRate == null ? null : interestStart),
            ),
          );
      if (movement != null) {
        await _db
            .into(_db.entries)
            .insert(movement.copyWith(debtId: Value(id)));
      }
      return id;
    });
  }

  /// Khoản Debt movement (chưa lưu) cho [original] theo tiền tệ khoản nợ
  /// [currency], ghi theo tiền tệ tài khoản [accountId].
  Future<EntriesCompanion> _movement({
    required int accountId,
    required DebtMovementKind kind,
    required int original,
    required String currency,
    required String date,
    required CurrencyService? service,
    int? debtId,
    int? paymentId,
  }) async {
    final amounts = await _inAccount(accountId, original, currency, service);
    return EntriesCompanion.insert(
      type: EntryType.debt,
      amount: amounts.primary,
      accountId: accountId,
      date: date,
      currency: Value(amounts.currency),
      originalAmount: Value(amounts.original),
      debtKind: Value(kind),
      debtId: Value(debtId),
      debtPaymentId: Value(paymentId),
    );
  }

  /// [original] theo [currency] quy về tiền tệ tài khoản [accountId] (số gốc
  /// của khoản) và về Tiền tệ chính (số dẫn xuất). Thiếu tỷ giá: ném
  /// [StateError] — nơi gọi đã kiểm trước khi lưu.
  Future<({String currency, int original, int primary})> _inAccount(
    int accountId,
    int original,
    String currency,
    CurrencyService? service,
  ) async {
    final account = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();
    final target = account.currency;
    if (service == null) {
      if (target != currency) throw StateError('cần tỷ giá $currency→$target');
      return (currency: target, original: original, primary: original);
    }
    final inAccount = service.convert(original, currency, target);
    final primary = inAccount == null
        ? null
        : service.toPrimary(inAccount, target);
    if (inAccount == null || primary == null) {
      throw StateError('thiếu tỷ giá $currency→$target');
    }
    return (currency: target, original: inAccount, primary: primary);
  }

  /// Sửa khoản nợ. Đổi số tiền thì bỏ số chính xác cũ (D-029). Tiền tệ khoá
  /// sau lần trả đầu và khi đã có Debt movement (AC-176); chiều khoá sau lần
  /// trả đầu. Khoản nợ có tài khoản: Debt movement số tiền vay đổi theo (số
  /// tiền, ngày, tài khoản [accountId]), chịu "có thu mới có chi".
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
    int? accountId,
    int? interestRate,
    InterestPeriod? interestPeriod,
    String? interestStart,
    CurrencyService? service,
  }) async {
    _checkPositive(amount);
    await _db.transaction(() async {
      final old = await (_db.select(
        _db.debts,
      )..where((d) => d.id.equals(id))).getSingleOrNull();
      if (old == null) return;
      final hasPayments = (await _payments(id).get()).isNotEmpty;
      final loan = await loanEntry(id);
      final locked = hasPayments || loan != null;
      final effectiveCurrency = locked
          ? old.currency
          : currency ?? old.currency;
      final effectiveDirection = hasPayments ? old.direction : direction;
      final original = originalAmount ?? amount;
      // Khoản nợ chỉ ghi nhớ giữ nguyên là ghi nhớ; có tài khoản thì đổi được
      // sang tài khoản khác nhưng không bỏ tài khoản.
      final account = old.accountId == null ? null : accountId ?? old.accountId;
      if (loan != null && account != null) {
        final next = await _movement(
          accountId: account,
          kind: effectiveDirection == DebtDirection.lent
              ? DebtMovementKind.lend
              : DebtMovementKind.borrow,
          original: original,
          currency: effectiveCurrency,
          date: date,
          service: service,
        );
        final updated = loan.copyWith(
          accountId: next.accountId.value,
          amount: next.amount.value,
          amountMicro: const Value(null),
          date: date,
          currency: next.currency.value,
          originalAmount: next.originalAmount,
          debtKind: next.debtKind,
        );
        if (service != null) {
          final short = await BalanceGuard(
            _db,
            service,
          ).checkReplace(loan, updated);
          if (short != null) throw InsufficientFundsException(short);
        }
        await _db.update(_db.entries).replace(updated);
      }
      await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
        DebtsCompanion(
          person: Value(person),
          direction: Value(effectiveDirection),
          amount: Value(amount),
          amountMicro: amount == old.amount
              ? const Value.absent()
              : const Value(null),
          date: Value(date),
          dueDate: Value(dueDate),
          note: Value(note),
          currency: Value(effectiveCurrency),
          originalAmount: Value(original),
          accountId: Value(account),
          interestRate: Value(interestRate),
          interestPeriod: Value(interestRate == null ? null : interestPeriod),
          interestStart: Value(interestRate == null ? null : interestStart),
        ),
      );
    });
  }

  /// Xoá khoản nợ cùng mọi lần trả và mốc lãi suất (khoá ngoại xoá theo).
  /// Các khoản trong sổ (Debt movement, khoản lãi) **giữ nguyên**, mất liên
  /// kết (Orphan debt movement, AC-175).
  Future<void> delete(int id) =>
      (_db.delete(_db.debts)..where((d) => d.id.equals(id))).go();

  /// Thêm lần trả ngày [date]: phần gốc [amount]/[originalAmount] (≤ gốc còn
  /// lại, không thì [DebtOverpaymentException]) và phần lãi [interest] theo
  /// tiền tệ khoản nợ (≤ lãi tới ngày trả chưa trả, không thì
  /// [DebtInterestOverException]). Có [accountId] thì ghi Debt movement phần
  /// gốc + khoản lãi (AC-170, AC-173); trả nợ chịu "có thu mới có chi".
  /// [amount] là phần gốc quy về Tiền tệ chính (D-037); có thể 0 khi chỉ trả
  /// lãi.
  Future<int> addPayment(
    int debtId, {
    required int amount,
    required String date,
    int? originalAmount,
    String? currency,
    int interest = 0,
    int? accountId,
    CurrencyService? service,
  }) {
    final principal = originalAmount ?? amount;
    if (principal < 0 || interest < 0 || principal + interest <= 0) {
      throw ArgumentError.value(principal + interest, 'amount', 'phải > 0');
    }
    return _db.transaction(() async {
      final view = await find(debtId);
      if (view == null) throw StateError('không có khoản nợ $debtId');
      // So bằng số gốc theo tiền tệ khoản nợ (G8, AC-158).
      if (principal > view.principalLeft) {
        throw DebtOverpaymentException(view.principalLeft);
      }
      final due = view.interest.unpaidInterest(parseDateKey(date));
      if (interest > due) throw DebtInterestOverException(due);
      final debt = view.debt;
      final lent = debt.direction == DebtDirection.lent;
      final entries = <EntriesCompanion>[];
      if (accountId != null) {
        if (principal > 0) {
          entries.add(
            await _movement(
              accountId: accountId,
              kind: lent ? DebtMovementKind.collect : DebtMovementKind.repay,
              original: principal,
              currency: debt.currency,
              date: date,
              service: service,
              debtId: debtId,
            ),
          );
        }
        if (interest > 0) {
          final amounts = await _inAccount(
            accountId,
            interest,
            debt.currency,
            service,
          );
          entries.add(
            EntriesCompanion.insert(
              type: lent ? EntryType.income : EntryType.expense,
              amount: amounts.primary,
              categoryId: Value(await interestCategoryId(_db, expense: !lent)),
              accountId: accountId,
              date: date,
              currency: Value(amounts.currency),
              originalAmount: Value(amounts.original),
              debtId: Value(debtId),
            ),
          );
        }
        if (service != null && !lent) {
          final short = await BalanceGuard(
            _db,
            service,
          ).check(add: [for (final e in entries) ...companionEffects(e)]);
          if (short != null) throw InsufficientFundsException(short);
        }
      }
      final paymentId = await _db
          .into(_db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              debtId: debtId,
              amount: amount,
              date: date,
              originalAmount: Value(principal),
              currency: Value(currency ?? debt.currency),
              accountId: Value(accountId),
              interest: Value(interest),
            ),
          );
      for (final e in entries) {
        await _db
            .into(_db.entries)
            .insert(e.copyWith(debtPaymentId: Value(paymentId)));
      }
      return paymentId;
    });
  }

  /// Xoá một lần trả cùng các khoản của nó; số còn lại tự tính lại (AC-105).
  /// Xoá lần thu nợ làm tài khoản âm thì ném [InsufficientFundsException]
  /// khi có [service] (AC-161). Trả về bản ghi đã xoá để Hoàn tác.
  Future<DeletedPayment?> deletePayment(int id, {CurrencyService? service}) =>
      _db.transaction(() async {
        final payment = await (_db.select(
          _db.debtPayments,
        )..where((p) => p.id.equals(id))).getSingleOrNull();
        if (payment == null) return null;
        final entries = await paymentEntries(id);
        if (service != null) {
          final short = await BalanceGuard(_db, service).checkDelete(entries);
          if (short != null) throw InsufficientFundsException(short);
        }
        await (_db.delete(
          _db.entries,
        )..where((e) => e.debtPaymentId.equals(id))).go();
        await (_db.delete(
          _db.debtPayments,
        )..where((p) => p.id.equals(id))).go();
        return DeletedPayment(payment, entries);
      });

  /// Ghi lại đúng lần trả đã xoá cùng các khoản của nó (Hoàn tác). Khoản nợ
  /// đã bị xoá trong lúc đó thì không làm gì. Trả nợ làm tài khoản âm thì ném
  /// [InsufficientFundsException] khi có [service].
  Future<void> restorePayment(
    DeletedPayment deleted, {
    CurrencyService? service,
  }) => _db.transaction(() async {
    final debt = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(deleted.payment.debtId))).getSingleOrNull();
    if (debt == null) return;
    if (service != null) {
      final short = await BalanceGuard(
        _db,
        service,
      ).check(add: [for (final e in deleted.entries) ...entryEffects(e)]);
      if (short != null) throw InsufficientFundsException(short);
    }
    await _db.into(_db.debtPayments).insert(deleted.payment);
    for (final e in deleted.entries) {
      await _db.into(_db.entries).insert(e);
    }
  });

  /// Thêm mốc đổi lãi suất áp từ [date] (AC-171); cùng ngày thì thay mốc cũ.
  Future<void> addRateChange(
    int debtId, {
    required String date,
    required int rate,
    required InterestPeriod period,
  }) => _db.transaction(() async {
    await (_db.delete(
      _db.debtRateChanges,
    )..where((c) => c.debtId.equals(debtId) & c.date.equals(date))).go();
    await _db
        .into(_db.debtRateChanges)
        .insert(
          DebtRateChangesCompanion.insert(
            debtId: debtId,
            date: date,
            rate: rate,
            period: period,
          ),
        );
  });

  /// Xoá một mốc đổi lãi suất.
  Future<void> deleteRateChange(int id) =>
      (_db.delete(_db.debtRateChanges)..where((c) => c.id.equals(id))).go();

  static void _checkPositive(int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'phải > 0');
    }
  }
}

/// Lần trả vừa xoá cùng các khoản của nó, để Hoàn tác.
class DeletedPayment {
  const DeletedPayment(this.payment, this.entries);

  final DebtPayment payment;
  final List<Entry> entries;
}
