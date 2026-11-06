import 'package:drift/drift.dart';

import 'database.dart';
import 'period.dart';
import 'stats.dart';

/// Truy vấn gom nhóm cho Tổng quan, Thống kê, Lịch (F-35, F-36, F-38): chỉ đọc,
/// gom thu chi theo ngày ngay trong SQL nên 10.000 khoản vẫn nhẹ. Chuyển tiền
/// không phải thu/chi; mục hàng đợi nằm bảng khác nên không bao giờ lọt vào.
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  static final _expense = EntryType.expense.index;
  static final _income = EntryType.income.index;

  /// Tổng thu chi từng ngày trong [from]..[to] (`YYYY-MM-DD`, gồm hai đầu), cũ
  /// nhất trước; lọc theo tài khoản nếu có (AC-20). Chỉ ngày có thu hoặc chi.
  Stream<List<DailyFlow>> watchDailyFlow(
    String from,
    String to, {
    int? accountId,
  }) => _db
      .customSelect(
        'SELECT date, '
        'SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS income, '
        'SUM(CASE WHEN type = ? THEN amount ELSE 0 END) AS expense '
        'FROM entries WHERE date BETWEEN ? AND ? AND type IN (?, ?)'
        '${accountId == null ? '' : ' AND account_id = ?'} '
        'GROUP BY date ORDER BY date',
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
      .map(
        (rows) => [
          for (final r in rows)
            DailyFlow(
              r.read<String>('date'),
              r.read<int>('income'),
              r.read<int>('expense'),
            ),
        ],
      );

  /// Thu chi từng ngày của một [Period]; kỳ "Tất cả" quét mọi ngày.
  Stream<List<DailyFlow>> watchPeriodFlow(Period period, {int? accountId}) =>
      watchDailyFlow(period.fromKey, period.toKey, accountId: accountId);

  /// Sổ tổng số dư mọi tài khoản, kể cả đã ẩn (AC-107, AC-109): số dư đầu cộng
  /// thay đổi ròng mỗi ngày (thu cộng, chi trừ, chuyển tiền không đổi tổng).
  Stream<BalanceLedger> watchBalanceLedger() => _db
      .customSelect('SELECT 1', readsFrom: {_db.accounts, _db.entries})
      .watch()
      .asyncMap((_) => balanceLedger());

  Future<BalanceLedger> balanceLedger() async {
    final initial = await _db
        .customSelect(
          'SELECT COALESCE(SUM(initial_balance), 0) AS total FROM accounts',
          readsFrom: {_db.accounts},
        )
        .getSingle();
    final rows = await _db
        .customSelect(
          'SELECT date, '
          'SUM(CASE WHEN type = ? THEN amount ELSE -amount END) AS net '
          'FROM entries WHERE type IN (?, ?) GROUP BY date',
          variables: [
            Variable.withInt(_income),
            Variable.withInt(_income),
            Variable.withInt(_expense),
          ],
          readsFrom: {_db.entries},
        )
        .get();
    return BalanceLedger(
      initial: initial.read<int>('total'),
      netByDate: {
        for (final r in rows) r.read<String>('date'): r.read<int>('net'),
      },
    );
  }
}
