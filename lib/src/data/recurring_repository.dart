import 'package:drift/drift.dart';

import 'database.dart';
import 'dates.dart';

/// Lần lặp thứ [n] (0 là ngày bắt đầu). Tính từ ngày bắt đầu chứ không từ lần
/// trước, nên khoản ngày 31 vẫn về ngày 31 sau tháng 2 (AC-23).
DateTime occurrence(DateTime start, RecurrenceFrequency f, int n) =>
    switch (f) {
      RecurrenceFrequency.daily => addDays(start, n),
      RecurrenceFrequency.weekly => addDays(start, 7 * n),
      RecurrenceFrequency.monthly => addMonths(start, n, day: start.day),
      RecurrenceFrequency.yearly => addMonths(start, 12 * n, day: start.day),
    };

/// Khoản định kỳ: tạo chuỗi, tự sinh khoản tới hạn, dừng, sửa (F-08).
class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;

  /// Giới hạn số khoản sinh cho một chuỗi trong một lần, tránh treo khi ngày máy sai.
  static const _maxPerRun = 3700;

  Stream<List<RecurringRule>> watch() =>
      (_db.select(_db.recurringRules)..orderBy([
            (r) => OrderingTerm.desc(r.active),
            (r) => OrderingTerm(expression: r.startDate),
          ]))
          .watch();

  Future<RecurringRule?> find(int id) => (_db.select(
    _db.recurringRules,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Ghi khoản đầu tiên và tạo chuỗi lặp bắt đầu từ ngày của khoản đó (AC-23).
  Future<int> addWithRepeat(
    EntriesCompanion first,
    RecurrenceFrequency frequency,
  ) => _db.transaction(() async {
    final ruleId = await _db
        .into(_db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            type: first.type.value,
            amount: first.amount.value,
            amountMicro: first.amountMicro,
            categoryId: first.categoryId,
            accountId: first.accountId.value,
            toAccountId: first.toAccountId,
            note: first.note,
            frequency: frequency,
            startDate: first.date.value,
            lastGeneratedDate: Value(first.date.value),
            currency: first.currency,
            originalAmount: first.originalAmount,
            toAmount: first.toAmount,
            toOriginalAmount: first.toOriginalAmount,
            toCurrency: first.toCurrency,
          ),
        );
    await _db
        .into(_db.entries)
        .insert(first.copyWith(recurringRuleId: Value(ruleId)));
    return ruleId;
  });

  /// Tạo các khoản tới hạn còn thiếu tới hết [today]; chạy nhiều lần không tạo
  /// trùng vì chỉ tạo sau `lastGeneratedDate` (AC-24). Trả về số khoản đã tạo.
  Future<int> generateDue(DateTime today) => _db.transaction(() async {
    final todayKey = dateKey(today);
    final rules = await (_db.select(
      _db.recurringRules,
    )..where((r) => r.active.equals(true))).get();
    var created = 0;
    for (final rule in rules) {
      final start = parseDateKey(rule.startDate);
      final last = rule.lastGeneratedDate;
      String? newLast;
      for (var n = 0, made = 0; made < _maxPerRun; n++) {
        final key = dateKey(occurrence(start, rule.frequency, n));
        if (key.compareTo(todayKey) > 0) break;
        if (last != null && key.compareTo(last) <= 0) continue;
        await _db
            .into(_db.entries)
            .insert(
              EntriesCompanion.insert(
                type: rule.type,
                amount: rule.amount,
                // Số chính xác đi theo chuỗi (D-029): quy đổi lại vẫn đúng.
                amountMicro: Value(rule.amountMicro),
                categoryId: Value(rule.categoryId),
                accountId: rule.accountId,
                toAccountId: Value(rule.toAccountId),
                date: key,
                note: Value(rule.note),
                recurringRuleId: Value(rule.id),
                currency: Value(rule.currency),
                originalAmount: Value(rule.originalAmount ?? rule.amount),
                toAmount: Value(rule.toAmount),
                toOriginalAmount: Value(rule.toOriginalAmount),
                toCurrency: Value(rule.toCurrency),
              ),
            );
        newLast = key;
        made++;
        created++;
      }
      if (newLast != null) {
        await (_db.update(_db.recurringRules)
              ..where((r) => r.id.equals(rule.id)))
            .write(RecurringRulesCompanion(lastGeneratedDate: Value(newLast)));
      }
    }
    return created;
  });

  /// Ngày tới hạn kế tiếp của chuỗi, sau `lastGeneratedDate`.
  static DateTime nextDate(RecurringRule rule) {
    final start = parseDateKey(rule.startDate);
    final last = rule.lastGeneratedDate;
    for (var n = 0; ; n++) {
      final d = occurrence(start, rule.frequency, n);
      if (last == null || dateKey(d).compareTo(last) > 0) return d;
    }
  }

  /// Dừng chuỗi; các khoản đã tạo giữ nguyên (AC-25).
  Future<void> stop(int id) =>
      (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
        const RecurringRulesCompanion(active: Value(false)),
      );

  /// Chạy lại chuỗi đã dừng từ hôm nay; không tạo bù các lần đã lỡ khi dừng.
  Future<void> resume(int id, DateTime today) async {
    final yesterday = dateKey(addDays(today, -1));
    final last = (await find(id))?.lastGeneratedDate;
    // Không lùi: chuỗi đã sinh khoản hôm nay mà tắt rồi bật lại cùng ngày thì
    // không được sinh trùng.
    final from = last != null && last.compareTo(yesterday) > 0
        ? last
        : yesterday;
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        active: const Value(true),
        lastGeneratedDate: Value(from),
      ),
    );
  }

  /// Sửa chuỗi cho các lần sau; khoản đã tạo không đổi (AC-25, AC-50).
  ///
  /// [frequency], [categoryId], [accountId] null nghĩa là giữ nguyên. Đổi tần
  /// suất thì chuỗi bắt đầu lại từ ngày tới hạn kế tiếp theo lịch CŨ: `startDate`
  /// là ngày đó và `lastGeneratedDate` là ngày liền trước, nên lần sinh đầu theo
  /// tần suất mới chính là ngày đó, không sinh bù và không trùng khoản đã có.
  /// Không đổi tần suất thì giữ nguyên cả hai ngày.
  Future<void> edit(
    int id, {
    required int amount,
    String? note,
    RecurrenceFrequency? frequency,
    int? categoryId,
    int? accountId,
    int? originalAmount,
    String? currency,
  }) => _db.transaction(() async {
    final rule = await find(id);
    if (rule == null) return;
    String? startDate;
    String? lastGenerated;
    if (frequency != null && frequency != rule.frequency) {
      final next = nextDate(rule);
      startDate = dateKey(next);
      lastGenerated = dateKey(addDays(next, -1));
    }
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        amount: Value(amount),
        amountMicro: amount == rule.amount
            ? const Value.absent()
            : const Value(null),
        note: Value(note),
        frequency: frequency == null ? const Value.absent() : Value(frequency),
        categoryId: categoryId == null
            ? const Value.absent()
            : Value(categoryId),
        accountId: accountId == null ? const Value.absent() : Value(accountId),
        startDate: startDate == null ? const Value.absent() : Value(startDate),
        lastGeneratedDate: lastGenerated == null
            ? const Value.absent()
            : Value(lastGenerated),
        originalAmount: Value(originalAmount ?? amount),
        currency: currency == null ? const Value.absent() : Value(currency),
      ),
    );
  });
}
