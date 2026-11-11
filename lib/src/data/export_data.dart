import 'database.dart';
import 'debt_repository.dart';
import 'entry_filter.dart';
import 'entry_repository.dart';
import 'money_sum.dart';
import 'period.dart';
import 'rate_repository.dart';
import 'summary.dart';

/// Dữ liệu cho một lần xuất Excel/PDF (F-40): các khoản trong [range] (mọi
/// tài khoản), danh mục đã cộng theo Tiền tệ chính, và mọi khoản nợ.
class ExportData {
  ExportData({
    required this.range,
    required this.rows,
    required this.accounts,
    required this.debts,
    required this.service,
  }) : summary = PeriodSummary.of(rows, service: service);

  /// Phạm vi xuất (kỳ đang xem hoặc khoảng tùy chọn, AC-116).
  final Period range;

  /// Khoản trong phạm vi, cũ nhất trước (như CSV).
  final List<EntryView> rows;

  /// Mọi tài khoản kể cả đã ẩn, để gọi tên tài khoản của khoản cũ.
  final Map<int, Account> accounts;

  /// Mọi khoản nợ kèm lần trả (sheet "Khoản nợ" không theo phạm vi ngày).
  final List<DebtView> debts;

  /// Tỷ giá + Tiền tệ chính lúc xuất (D-042).
  final CurrencyService service;

  /// Tổng thu, chi và theo danh mục, cộng số gốc theo từng tiền tệ rồi quy
  /// đổi một lần (AC-148); khoản thiếu tỷ giá không vào tổng (AC-134).
  final PeriodSummary summary;

  String get primary => service.primary;
}

/// Số của khoản quy theo Tiền tệ chính, tính từ số gốc (D-042): cùng tiền tệ
/// thì chính là số gốc; thiếu tỷ giá thì null (ô để trống, AC-134).
int? entryPrimaryAmount(Entry e, CurrencyService service) =>
    service.convert(entryOriginal(e), e.currency, service.primary);

/// Số còn lại của khoản nợ theo Tiền tệ chính (null nếu thiếu tỷ giá).
int? debtPrimaryRemaining(DebtView d, CurrencyService service) =>
    service.convert(d.remaining(), d.debt.currency, service.primary);

/// Nạp dữ liệu xuất cho [range].
Future<ExportData> loadExportData(
  AppDatabase db,
  Period range,
  CurrencyService service,
) async {
  final rows = await EntryRepository(db).watchEntries(range).first;
  final oldestFirst = [...rows]..sort((a, b) => newestFirst(b, a));
  final accounts = {
    for (final a in await db.select(db.accounts).get()) a.id: a,
  };
  return ExportData(
    range: range,
    rows: oldestFirst,
    accounts: accounts,
    debts: await DebtRepository(db).all(),
    service: service,
  );
}
