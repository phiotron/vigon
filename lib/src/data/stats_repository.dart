import 'package:drift/drift.dart';

import 'database.dart';
import 'money_sum.dart';
import 'period.dart';
import 'stats.dart';

/// Truy vấn gom nhóm cho Tổng quan, Thống kê, Lịch (F-35, F-36, F-38): chỉ đọc,
/// gom **số gốc** theo ngày và tiền tệ ngay trong SQL nên 10.000 khoản vẫn
/// nhẹ, rồi mới quy đổi một lần cho mỗi tổng (D-042, AC-148). Chuyển tiền không
/// phải thu/chi; mục hàng đợi nằm bảng khác nên không bao giờ lọt vào.
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  static final _expense = EntryType.expense.index;
  static final _income = EntryType.income.index;
  static final _transfer = EntryType.transfer.index;

  /// Số gốc của khoản (dữ liệu cũ chưa có cột gốc: số dẫn xuất là số gốc),
  /// khớp `entryOriginal`.
  static const _original = 'COALESCE(original_amount, amount)';

  /// Thu chi gốc từng ngày trong [from]..[to] (`YYYY-MM-DD`, gồm hai đầu), cũ
  /// nhất trước; lọc theo tài khoản nếu có (AC-20). Chỉ ngày có thu hoặc chi.
  Stream<List<DailyFlow>> watchDailyFlow(
    String from,
    String to, {
    int? accountId,
  }) => _db
      .customSelect(
        'SELECT date, currency, '
        'SUM(CASE WHEN type = ? THEN $_original ELSE 0 END) AS income, '
        'SUM(CASE WHEN type = ? THEN $_original ELSE 0 END) AS expense '
        'FROM entries WHERE date BETWEEN ? AND ? AND type IN (?, ?)'
        '${accountId == null ? '' : ' AND account_id = ?'} '
        'GROUP BY date, currency ORDER BY date',
        variables: [
          Variable.withInt(_income),
          Variable.withInt(_expense),
          Variable.withString(from),
          Variable.withString(to),
          Variable.withInt(_income),
          Variable.withInt(_expense),
          if (accountId != null) Variable.withInt(accountId),
        ],
        readsFrom: {_db.entries},
      )
      .watch()
      .map((rows) {
        final out = <DailyFlow>[];
        for (final r in rows) {
          final date = r.read<String>('date');
          if (out.isEmpty || out.last.date != date) out.add(DailyFlow(date));
          final currency = r.read<String>('currency');
          out.last.income.add(currency, r.read<int>('income'));
          out.last.expense.add(currency, r.read<int>('expense'));
        }
        return out;
      });

  /// Thu chi từng ngày của một [Period]; kỳ "Tất cả" quét mọi ngày.
  Stream<List<DailyFlow>> watchPeriodFlow(Period period, {int? accountId}) =>
      watchDailyFlow(period.fromKey, period.toKey, accountId: accountId);

  /// Sổ tổng số dư mọi tài khoản, kể cả đã ẩn (AC-109): số dư đầu cộng thay đổi
  /// ròng mỗi ngày theo tiền tệ gốc — thu cộng, chi trừ, chuyển tiền trừ ở
  /// tiền gửi và cộng ở tiền nhận (như `balanceBags`).
  Stream<BalanceLedger> watchBalanceLedger() => _db
      .customSelect('SELECT 1', readsFrom: {_db.accounts, _db.entries})
      .watch()
      .asyncMap((_) => balanceLedger());

  Future<BalanceLedger> balanceLedger() async {
    final initial = MoneyBag();
    final accounts = await _db
        .customSelect(
          'SELECT COALESCE(initial_currency, currency) AS c, '
          'SUM(COALESCE(initial_balance_original, initial_balance)) AS total '
          'FROM accounts GROUP BY c',
          readsFrom: {_db.accounts},
        )
        .get();
    for (final r in accounts) {
      initial.add(r.read<String>('c'), r.read<int>('total'));
    }
    final net = <String, MoneyBag>{};
    MoneyBag bag(String date) => net[date] ??= MoneyBag();
    final moves = await _db
        .customSelect(
          'SELECT date, currency, '
          'SUM(CASE WHEN type = ? THEN $_original ELSE -$_original END) AS net '
          'FROM entries GROUP BY date, currency',
          variables: [Variable.withInt(_income)],
          readsFrom: {_db.entries},
        )
        .get();
    for (final r in moves) {
      bag(r.read<String>('date'))
          .add(r.read<String>('currency'), r.read<int>('net'));
    }
    final received = await _db
        .customSelect(
          'SELECT date, COALESCE(to_currency, currency) AS c, '
          'SUM(COALESCE(to_original_amount, original_amount, to_amount, '
          'amount)) AS total '
          'FROM entries WHERE type = ? AND to_account_id IS NOT NULL '
          'GROUP BY date, c',
          variables: [Variable.withInt(_transfer)],
          readsFrom: {_db.entries},
        )
        .get();
    for (final r in received) {
      bag(r.read<String>('date'))
          .add(r.read<String>('c'), r.read<int>('total'));
    }
    return BalanceLedger(initial: initial, netByDate: net);
  }
}
