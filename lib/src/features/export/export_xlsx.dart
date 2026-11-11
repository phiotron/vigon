import 'dart:typed_data';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/export_data.dart';
import '../../data/money.dart';
import '../../data/money_sum.dart';
import '../../data/summary.dart';
import '../../data/xlsx_writer.dart';
import '../../l10n_names.dart';

/// Chữ của loại khoản theo ngôn ngữ app.
String exportTypeName(AppLocalizations l, EntryType type) => switch (type) {
  EntryType.expense => l.expense,
  EntryType.income => l.income,
  EntryType.transfer => l.transfer,
};

/// Chữ của nguồn khoản: "Ghi tay" / "Email MB" (như CSV, AC-124).
String exportSourceName(AppLocalizations l, EntrySource source) =>
    switch (source) {
      EntrySource.manual => l.csvSourceManual,
      EntrySource.emailMb => l.csvSourceEmailMb,
    };

XlsxCell _money(int? minor, String currency) => minor == null
    ? const XlsxBlank()
    : XlsxMoney(minor, currencyDecimalDigits(currency));

XlsxCell _text(String? s) =>
    s == null || s.isEmpty ? const XlsxBlank() : XlsxText(s);

/// Dựng file Excel `.xlsx` (AC-117): sheet "Khoản", "Theo danh mục",
/// "Khoản nợ"; tiêu đề theo ngôn ngữ app. Số tiền là ô số định dạng đúng số
/// lẻ của tiền tệ; có cả số gốc + tiền tệ gốc và cột theo Tiền tệ chính
/// (D-042). Ô chữ không bao giờ là công thức.
Uint8List buildExportXlsx(ExportData data, AppLocalizations l) {
  final primary = data.primary;
  final service = data.service;
  String accountName(int? id) {
    final a = id == null ? null : data.accounts[id];
    return a == null ? '' : accountLabel(l, a);
  }

  final entries = XlsxSheet(
    name: l.exportSheetEntries,
    header: [
      l.exportColDate,
      l.exportColTime,
      l.exportColType,
      l.exportColAmount,
      l.exportColCurrency,
      l.exportColAmountIn(primary),
      l.exportColCategory,
      l.exportColAccount,
      l.exportColToAccount,
      l.exportColReceived,
      l.exportColReceivedCurrency,
      l.exportColNote,
      l.exportColSource,
    ],
    widths: const [12, 7, 12, 14, 9, 16, 18, 18, 18, 14, 9, 30, 10],
    rows: [
      for (final r in data.rows)
        () {
          final e = r.entry;
          final isTransfer = e.type == EntryType.transfer;
          // Chuyển tiền khác tiền tệ: thêm số nhận gốc (AC-132).
          final crossCurrency =
              isTransfer && entryReceivedCurrency(e) != e.currency;
          return <XlsxCell>[
            XlsxDate(parseDateKey(e.date)),
            _text(e.time),
            XlsxText(exportTypeName(l, e.type)),
            _money(entryOriginal(e), e.currency),
            XlsxText(e.currency),
            _money(entryPrimaryAmount(e, service), primary),
            isTransfer || r.category == null
                ? const XlsxBlank()
                : XlsxText(categoryLabel(l, r.category!)),
            _text(accountName(e.accountId)),
            _text(isTransfer ? accountName(e.toAccountId) : null),
            crossCurrency
                ? _money(entryReceivedOriginal(e), entryReceivedCurrency(e))
                : const XlsxBlank(),
            crossCurrency
                ? XlsxText(entryReceivedCurrency(e))
                : const XlsxBlank(),
            _text(e.note),
            XlsxText(exportSourceName(l, e.source)),
          ];
        }(),
    ],
  );

  List<XlsxCell> categoryRow(EntryType type, CategoryTotal t) => [
    XlsxText(exportTypeName(l, type)),
    XlsxText(categoryLabel(l, t.category)),
    XlsxMoney(t.total, currencyDecimalDigits(primary)),
    XlsxPercent((t.percent * 10).round()),
  ];
  final byCategory = XlsxSheet(
    name: l.exportSheetCategories,
    header: [
      l.exportColType,
      l.exportColCategory,
      l.exportColTotalIn(primary),
      l.exportColShare,
    ],
    widths: const [12, 24, 18, 10],
    rows: [
      for (final t in data.summary.expenseByCategory)
        categoryRow(EntryType.expense, t),
      for (final t in data.summary.incomeByCategory)
        categoryRow(EntryType.income, t),
    ],
  );

  final debts = XlsxSheet(
    name: l.exportSheetDebts,
    header: [
      l.exportColPerson,
      l.exportColDirection,
      l.exportColAmount,
      l.exportColPaid,
      l.exportColRemaining,
      l.exportColCurrency,
      l.exportColRemainingIn(primary),
      l.exportColDate,
      l.exportColDue,
      l.exportColStatus,
      l.exportColNote,
    ],
    widths: const [20, 10, 14, 14, 14, 9, 18, 12, 12, 12, 30],
    rows: [
      for (final d in data.debts)
        <XlsxCell>[
          XlsxText(d.debt.person),
          XlsxText(switch (d.debt.direction) {
            DebtDirection.lent => l.debtLent,
            DebtDirection.borrowed => l.debtBorrowed,
          }),
          _money(d.total, d.debt.currency),
          _money(d.paid(), d.debt.currency),
          _money(d.remaining(), d.debt.currency),
          XlsxText(d.debt.currency),
          _money(debtPrimaryRemaining(d, service), primary),
          XlsxDate(parseDateKey(d.debt.date)),
          d.debt.dueDate == null
              ? const XlsxBlank()
              : XlsxDate(parseDateKey(d.debt.dueDate!)),
          XlsxText(d.isSettled() ? l.debtDone : l.exportDebtOpen),
          _text(d.debt.note),
        ],
    ],
  );

  return buildXlsx([entries, byCategory, debts]);
}
