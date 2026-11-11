import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/export_data.dart';
import '../../data/money.dart';
import '../../data/money_sum.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import 'export_xlsx.dart' show exportTypeName;

/// Font Be Vietnam Pro nhúng vào PDF để chữ có dấu hiện đúng (AC-118).
class ExportFonts {
  const ExportFonts({required this.regular, required this.bold});

  final Uint8List regular;
  final Uint8List bold;
}

const _muted = PdfColor.fromInt(0xFF5F6368);
const _line = PdfColor.fromInt(0xFFDADCE0);
const _headerFill = PdfColor.fromInt(0xFFF1F3F4);

/// Dựng báo cáo PDF khổ A4 (AC-118): "Báo cáo thu chi {kỳ}", tổng thu, tổng
/// chi, chênh lệch, bảng theo danh mục (số, %), danh sách khoản (ngày giờ,
/// danh mục, ghi chú, số tiền). Số theo Tiền tệ chính đứng trên, số gốc nhỏ
/// ở dưới khi khác tiền tệ (AC-146). Tự sang trang khi dài.
///
/// Cần dữ liệu ngày theo ngôn ngữ đã nạp (`initializeDateFormatting`).
Future<Uint8List> buildExportPdf(
  ExportData data,
  AppLocalizations l, {
  required String periodTitle,
  required ExportFonts fonts,
}) {
  final locale = l.localeName;
  final primary = data.primary;
  final service = data.service;
  String fmt(int minor, String currency) =>
      formatMoney(minor, currencyCode: currency, locale: locale);
  final dateFormat = DateFormat.yMd(locale);
  final summary = data.summary;
  // Be Vietnam Pro không có "→": dùng ký tự gần nhất font có (không thì ô trống).
  final glyphs = TtfParser(fonts.regular.buffer.asByteData())
      .charToGlyphIndexMap;
  final arrow = [
    '→',
    '›',
    '>',
  ].firstWhere((c) => glyphs.containsKey(c.runes.single));

  final doc = pw.Document(
    title: l.exportReportTitle(periodTitle),
    creator: 'Vigon',
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(fonts.regular.buffer.asByteData()),
      bold: pw.Font.ttf(fonts.bold.buffer.asByteData()),
    ),
  );

  const small = pw.TextStyle(fontSize: 8, color: _muted);
  const body = pw.TextStyle(fontSize: 9);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget stat(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: small),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  pw.Widget cell(String text, {bool right = false, pw.TextStyle? style}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(
          text,
          style: style ?? body,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        ),
      );

  pw.TableRow headerRow(List<String> titles, Set<int> rightCols) => pw.TableRow(
    repeat: true,
    decoration: const pw.BoxDecoration(color: _headerFill),
    children: [
      for (var i = 0; i < titles.length; i++)
        cell(titles[i], right: rightCols.contains(i), style: bold),
    ],
  );

  const rowLine = pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
  );

  pw.TableRow categoryRow(EntryType type, CategoryTotal t) => pw.TableRow(
    decoration: rowLine,
    children: [
      cell(exportTypeName(l, type)),
      cell(categoryLabel(l, t.category)),
      cell(fmt(t.total, primary), right: true),
      cell(
        '${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1).format(t.percent)}%',
        right: true,
      ),
    ],
  );

  String accountName(int? id) {
    final a = id == null ? null : data.accounts[id];
    return a == null ? '' : accountLabel(l, a);
  }

  pw.Widget amountCell(Entry e) {
    final original = entryOriginal(e);
    final converted = entryPrimaryAmount(e, service);
    final sign = switch (e.type) {
      EntryType.expense => '-',
      EntryType.income => '+',
      EntryType.transfer => '',
    };
    final lines = <pw.Widget>[];
    if (e.currency == primary) {
      lines.add(pw.Text('$sign${fmt(original, primary)}', style: body));
    } else if (converted == null) {
      lines
        ..add(pw.Text('$sign${fmt(original, e.currency)}', style: body))
        ..add(pw.Text(l.exportMissingRate, style: small));
    } else {
      lines
        ..add(pw.Text('$sign${fmt(converted, primary)}', style: body))
        ..add(pw.Text(fmt(original, e.currency), style: small));
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: lines,
      ),
    );
  }

  pw.TableRow entryRow(EntryView r) {
    final e = r.entry;
    final when = dateFormat.format(parseDateKey(e.date));
    final category = e.type == EntryType.transfer
        ? '${l.transfer}: ${l.transferLabel(accountName(e.accountId), accountName(e.toAccountId)).replaceAll('→', arrow)}'
        : r.category == null
        ? ''
        : categoryLabel(l, r.category!);
    return pw.TableRow(
      decoration: rowLine,
      verticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [
        cell(e.time == null ? when : '$when ${e.time}'),
        cell(category),
        cell(e.note ?? ''),
        amountCell(e),
      ],
    );
  }

  final categoryRows = [
    for (final t in summary.expenseByCategory)
      categoryRow(EntryType.expense, t),
    for (final t in summary.incomeByCategory) categoryRow(EntryType.income, t),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      // Mặc định 20 trang; 1.000 khoản cần ~30 trang (AC-118).
      maxPages: 1000,
      margin: const pw.EdgeInsets.all(36),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          l.exportPage(context.pageNumber, context.pagesCount),
          style: small,
        ),
      ),
      build: (context) => [
        pw.Text(
          l.exportReportTitle(periodTitle),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(l.exportAmountsIn(primary), style: small),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            stat(l.exportTotalIncome, fmt(summary.income, primary)),
            pw.SizedBox(width: 8),
            stat(l.exportTotalExpense, fmt(summary.expense, primary)),
            pw.SizedBox(width: 8),
            stat(l.exportDifference, fmt(summary.balance, primary)),
          ],
        ),
        heading(l.exportSheetCategories),
        if (categoryRows.isEmpty)
          pw.Text(l.exportNoEntries, style: body)
        else
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(50),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FixedColumnWidth(50),
            },
            children: [
              headerRow(
                [
                  l.exportColType,
                  l.exportColCategory,
                  l.exportColAmount,
                  l.exportColShare,
                ],
                {2, 3},
              ),
              ...categoryRows,
            ],
          ),
        heading(l.exportEntriesHeading),
        if (data.rows.isEmpty)
          pw.Text(l.exportNoEntries, style: body)
        else
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(80),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(4),
              3: pw.FixedColumnWidth(95),
            },
            children: [
              headerRow(
                [
                  l.exportColDate,
                  l.exportColCategory,
                  l.exportColNote,
                  l.exportColAmount,
                ],
                {3},
              ),
              for (final r in data.rows) entryRow(r),
            ],
          ),
      ],
    ),
  );
  return doc.save();
}
