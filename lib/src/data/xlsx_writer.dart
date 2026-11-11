import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Một ô của bảng tính tối giản (F-40, AC-117).
sealed class XlsxCell {
  const XlsxCell();
}

/// Ô chữ. Luôn ghi vào bảng chuỗi dùng chung (`t="s"`) nên **không bao giờ**
/// là công thức; chữ mở đầu bằng `= + - @` còn được gắn cờ `quotePrefix` để
/// sửa ô trong Excel cũng không biến thành công thức.
class XlsxText extends XlsxCell {
  const XlsxText(this.value, {this.bold = false});

  final String value;
  final bool bold;
}

/// Ô tiền: số nguyên đơn vị nhỏ nhất + số chữ số lẻ của tiền tệ. Ghi thành
/// số thập phân đúng từng chữ số (không qua số thực) và định dạng
/// `#,##0.00` theo đúng số lẻ.
class XlsxMoney extends XlsxCell {
  const XlsxMoney(this.minor, this.decimalDigits);

  final int minor;
  final int decimalDigits;
}

/// Ô phần trăm, [tenths] là phần nghìn (123 = 12,3%), định dạng `0.0%`.
class XlsxPercent extends XlsxCell {
  const XlsxPercent(this.tenths);

  final int tenths;
}

/// Ô ngày (chỉ ngày), định dạng `yyyy-mm-dd`.
class XlsxDate extends XlsxCell {
  const XlsxDate(this.date);

  final DateTime date;
}

/// Ô trống.
class XlsxBlank extends XlsxCell {
  const XlsxBlank();
}

/// Một trang tính: tên, dòng tiêu đề (in đậm, cố định khi cuộn), các dòng.
class XlsxSheet {
  const XlsxSheet({
    required this.name,
    required this.header,
    required this.rows,
    this.widths = const [],
  });

  final String name;
  final List<String> header;
  final List<List<XlsxCell>> rows;

  /// Độ rộng cột (đơn vị ký tự của Excel); thiếu thì để mặc định.
  final List<double> widths;
}

/// Ký tự làm Excel/Sheets hiểu ô là công thức khi gõ lại.
final _formulaStart = RegExp(r'^[=+\-@\t\r]');

/// Ký tự XML 1.0 không cho phép (điều khiển trừ tab, xuống dòng, về đầu dòng).
final _invalidXml = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F￾￿]');

String _esc(String s) => s
    .replaceAll(_invalidXml, '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Tên cột kiểu Excel: 0 → A, 25 → Z, 26 → AA.
String xlsxColumnName(int index) {
  var n = index + 1;
  final chars = <String>[];
  while (n > 0) {
    chars.insert(0, String.fromCharCode(65 + (n - 1) % 26));
    n = (n - 1) ~/ 26;
  }
  return chars.join();
}

/// Số thập phân chính xác từ đơn vị nhỏ nhất, dấu chấm thập phân (chuẩn XML).
String xlsxDecimal(int minor, int digits) {
  if (digits <= 0) return '$minor';
  final unit = BigInt.from(10).pow(digits);
  final abs = BigInt.from(minor).abs();
  final whole = abs ~/ unit;
  final frac = (abs % unit).toString().padLeft(digits, '0');
  return '${minor < 0 ? '-' : ''}$whole.$frac';
}

/// Số ngày kiểu Excel (gốc 1899-12-30) của một ngày.
int _excelSerial(DateTime d) => DateTime.utc(
  d.year,
  d.month,
  d.day,
).difference(DateTime.utc(1899, 12, 30)).inDays;

/// Dựng file `.xlsx` (Office Open XML) từ [sheets]. Không gọi mạng, không
/// dùng công thức; chỉ chuỗi dùng chung, số và kiểu ô.
Uint8List buildXlsx(List<XlsxSheet> sheets) {
  // Bảng chuỗi dùng chung.
  final strings = <String>[];
  final stringIndex = <String, int>{};
  int sst(String s) => stringIndex.putIfAbsent(s, () {
    strings.add(s);
    return strings.length - 1;
  });

  // Kiểu ô: 0 mặc định · 1 tiêu đề đậm · 2 chữ có quotePrefix · 3 ngày ·
  // 4 phần trăm · 5.. tiền theo số lẻ.
  const xfDefault = 0, xfBold = 1, xfQuote = 2, xfDate = 3, xfPercent = 4;
  final moneyXf = <int, int>{}; // số lẻ → chỉ số xf
  int xfMoney(int digits) =>
      moneyXf.putIfAbsent(digits, () => 5 + moneyXf.length);

  String sheetXml(XlsxSheet sheet) {
    final b = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
      )
      ..write(
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>',
      );
    if (sheet.widths.isNotEmpty) {
      b.write('<cols>');
      for (var i = 0; i < sheet.widths.length; i++) {
        b.write(
          '<col min="${i + 1}" max="${i + 1}" width="${sheet.widths[i]}" customWidth="1"/>',
        );
      }
      b.write('</cols>');
    }
    b.write('<sheetData>');
    void row(int r, List<XlsxCell> cells) {
      b.write('<row r="$r">');
      for (var c = 0; c < cells.length; c++) {
        final ref = '${xlsxColumnName(c)}$r';
        switch (cells[c]) {
          case XlsxBlank():
            break;
          case XlsxText(:final value, :final bold):
            if (value.isEmpty) break;
            final style = bold
                ? xfBold
                : _formulaStart.hasMatch(value)
                ? xfQuote
                : xfDefault;
            final s = style == xfDefault ? '' : ' s="$style"';
            b.write('<c r="$ref" t="s"$s><v>${sst(value)}</v></c>');
          case XlsxMoney(:final minor, :final decimalDigits):
            b.write(
              '<c r="$ref" s="${xfMoney(decimalDigits)}">'
              '<v>${xlsxDecimal(minor, decimalDigits)}</v></c>',
            );
          case XlsxPercent(:final tenths):
            b.write(
              '<c r="$ref" s="$xfPercent"><v>${xlsxDecimal(tenths, 3)}</v></c>',
            );
          case XlsxDate(:final date):
            b.write('<c r="$ref" s="$xfDate"><v>${_excelSerial(date)}</v></c>');
        }
      }
      b.write('</row>');
    }

    row(1, [for (final h in sheet.header) XlsxText(h, bold: true)]);
    for (var i = 0; i < sheet.rows.length; i++) {
      row(i + 2, sheet.rows[i]);
    }
    b.write('</sheetData></worksheet>');
    return b.toString();
  }

  final sheetXmls = [for (final s in sheets) sheetXml(s)];

  // styles.xml: định dạng số tuỳ chỉnh bắt đầu từ 164.
  final digitsList = moneyXf.keys.toList()
    ..sort((a, b) => moneyXf[a]!.compareTo(moneyXf[b]!));
  String moneyFormat(int digits) =>
      digits <= 0 ? '#,##0' : '#,##0.${'0' * digits}';
  final numFmts = <String>[
    '<numFmt numFmtId="164" formatCode="yyyy-mm-dd"/>',
    '<numFmt numFmtId="165" formatCode="0.0%"/>',
    for (var i = 0; i < digitsList.length; i++)
      '<numFmt numFmtId="${166 + i}" formatCode="${_esc(moneyFormat(digitsList[i]))}"/>',
  ];
  final xfs = <String>[
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>',
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>',
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" quotePrefix="1"/>',
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>',
    '<xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>',
    for (var i = 0; i < digitsList.length; i++)
      '<xf numFmtId="${166 + i}" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>',
  ];
  final styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<numFmts count="${numFmts.length}">${numFmts.join()}</numFmts>'
      '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
      '<fills count="2"><fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill></fills>'
      '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="${xfs.length}">${xfs.join()}</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';

  final sharedStrings = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'count="${strings.length}" uniqueCount="${strings.length}">',
    );
  for (final s in strings) {
    sharedStrings.write('<si><t xml:space="preserve">${_esc(s)}</t></si>');
  }
  sharedStrings.write('</sst>');

  final contentTypes = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>',
    );
  for (var i = 0; i < sheets.length; i++) {
    contentTypes.write(
      '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
    );
  }
  contentTypes.write('</Types>');

  const rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>';

  final workbook = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>',
    );
  final workbookRels = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    );
  for (var i = 0; i < sheets.length; i++) {
    workbook.write(
      '<sheet name="${_esc(_sheetName(sheets[i].name))}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
    );
    workbookRels.write(
      '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>',
    );
  }
  final n = sheets.length;
  workbook.write('</sheets></workbook>');
  workbookRels
    ..write(
      '<Relationship Id="rId${n + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
    )
    ..write(
      '<Relationship Id="rId${n + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>',
    )
    ..write('</Relationships>');

  final archive = Archive();
  void add(String name, String content) =>
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  add('[Content_Types].xml', contentTypes.toString());
  add('_rels/.rels', rootRels);
  add('xl/workbook.xml', workbook.toString());
  add('xl/_rels/workbook.xml.rels', workbookRels.toString());
  add('xl/styles.xml', styles);
  add('xl/sharedStrings.xml', sharedStrings.toString());
  for (var i = 0; i < n; i++) {
    add('xl/worksheets/sheet${i + 1}.xml', sheetXmls[i]);
  }
  return ZipEncoder().encodeBytes(archive);
}

/// Tên trang tính hợp lệ: bỏ ký tự cấm `[]:*?/\`, tối đa 31 ký tự.
String _sheetName(String name) {
  final clean = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
  final safe = clean.isEmpty ? 'Sheet' : clean;
  return safe.length > 31 ? safe.substring(0, 31) : safe;
}
