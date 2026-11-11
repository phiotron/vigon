import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Một ô đọc lại từ file `.xlsx` (test F-40).
class ReadCell {
  const ReadCell({
    required this.ref,
    required this.type,
    required this.value,
    required this.numFmt,
    required this.quotePrefix,
    required this.hasFormula,
  });

  final String ref;

  /// `s` (chuỗi dùng chung), `inlineStr`, `n` (số, mặc định)…
  final String type;

  /// Chuỗi đã tra bảng chuỗi dùng chung, hoặc chữ số như trong file.
  final String value;

  /// Mã định dạng số của kiểu ô (`#,##0.00`, `yyyy-mm-dd`…), rỗng nếu không.
  final String numFmt;
  final bool quotePrefix;
  final bool hasFormula;
}

/// Đọc lại file `.xlsx`: tên trang tính → các dòng → các ô (theo thứ tự cột).
Map<String, List<List<ReadCell>>> readXlsx(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  String part(String name) =>
      utf8.decode(zip.files.firstWhere((f) => f.name == name).content);

  final strings = [
    for (final si in XmlDocument.parse(
      part('xl/sharedStrings.xml'),
    ).findAllElements('si'))
      si.findAllElements('t').map((t) => t.innerText).join(),
  ];

  final styles = XmlDocument.parse(part('xl/styles.xml'));
  final formats = {
    for (final f in styles.findAllElements('numFmt'))
      f.getAttribute('numFmtId')!: f.getAttribute('formatCode')!,
  };
  final xfs = styles
      .findAllElements('cellXfs')
      .single
      .findElements('xf')
      .toList();

  final workbook = XmlDocument.parse(part('xl/workbook.xml'));
  final rels = XmlDocument.parse(part('xl/_rels/workbook.xml.rels'));
  final targetOf = {
    for (final r in rels.findAllElements('Relationship'))
      r.getAttribute('Id')!: r.getAttribute('Target')!,
  };

  final result = <String, List<List<ReadCell>>>{};
  for (final sheet in workbook.findAllElements('sheet')) {
    final target = targetOf[sheet.getAttribute('r:id')]!;
    final doc = XmlDocument.parse(part('xl/$target'));
    final rows = <List<ReadCell>>[];
    for (final row in doc.findAllElements('row')) {
      rows.add([
        for (final c in row.findElements('c'))
          () {
            final type = c.getAttribute('t') ?? 'n';
            final raw = c.getElement('v')?.innerText ?? '';
            final xf = xfs[int.parse(c.getAttribute('s') ?? '0')];
            return ReadCell(
              ref: c.getAttribute('r')!,
              type: type,
              value: type == 's' ? strings[int.parse(raw)] : raw,
              numFmt: formats[xf.getAttribute('numFmtId')] ?? '',
              quotePrefix: xf.getAttribute('quotePrefix') == '1',
              hasFormula: c.getElement('f') != null,
            );
          }(),
      ]);
    }
    result[sheet.getAttribute('name')!] = rows;
  }
  return result;
}

/// Trích chữ từ PDF do gói `pdf` tạo (font TTF mã Identity-H + ToUnicode):
/// giải nén các stream, tra bảng ToUnicode của font đang dùng (`/Fn … Tf`)
/// cho từng chuỗi hex. Mỗi chuỗi hex cách nhau một dấu cách.
String extractPdfText(Uint8List bytes) {
  final raw = latin1.decode(bytes);
  final objects = <int, (String dict, String? stream)>{};
  final objRe = RegExp(r'(\d+) 0 obj\s*(.*?)endobj', dotAll: true);
  for (final m in objRe.allMatches(raw)) {
    final body = m.group(2)!;
    final s = body.indexOf('stream');
    if (s < 0) {
      objects[int.parse(m.group(1)!)] = (body, null);
      continue;
    }
    final dict = body.substring(0, s);
    var start = s + 'stream'.length;
    if (body[start] == '\r') start++;
    if (body[start] == '\n') start++;
    final end = body.lastIndexOf('endstream');
    var data = latin1.encode(body.substring(start, end));
    if (dict.contains('/FlateDecode')) {
      data = Uint8List.fromList(const ZLibDecoder().decodeBytes(data));
    }
    objects[int.parse(m.group(1)!)] = (dict, latin1.decode(data));
  }

  // Bảng ToUnicode: số đối tượng font → (mã → chữ).
  Map<int, String> cmap(String text) => {
    for (final m in RegExp(
      r'<([0-9A-Fa-f]{4})>\s*<([0-9A-Fa-f]+)>',
    ).allMatches(text))
      int.parse(m.group(1)!, radix: 16): String.fromCharCode(
        int.parse(m.group(2)!, radix: 16),
      ),
  };
  final fontMaps = <int, Map<int, String>>{};
  for (final e in objects.entries) {
    final m = RegExp(r'/ToUnicode\s+(\d+)\s+0\s+R').firstMatch(e.value.$1);
    if (m == null) continue;
    final cmapObj = objects[int.parse(m.group(1)!)];
    if (cmapObj?.$2 != null) fontMaps[e.key] = cmap(cmapObj!.$2!);
  }
  // Tên font trong trang (/F1) → số đối tượng.
  final fontByName = <String, int>{};
  for (final o in objects.values) {
    for (final m in RegExp(r'/(F\d+)\s+(\d+)\s+0\s+R').allMatches(o.$1)) {
      fontByName[m.group(1)!] = int.parse(m.group(2)!);
    }
  }

  final out = StringBuffer();
  final tokenRe = RegExp(r'/(F\d+)\s+[\d.]+\s+Tf|<([0-9A-Fa-f]*)>');
  for (final o in objects.values) {
    final content = o.$2;
    if (content == null || !content.contains('Tf')) continue;
    Map<int, String>? current;
    for (final m in tokenRe.allMatches(content)) {
      if (m.group(1) != null) {
        current = fontMaps[fontByName[m.group(1)!]];
        continue;
      }
      final hex = m.group(2)!;
      if (current == null || hex.length % 4 != 0) continue;
      for (var i = 0; i < hex.length; i += 4) {
        out.write(current[int.parse(hex.substring(i, i + 4), radix: 16)] ?? '');
      }
      out.write(' ');
    }
    out.write('\n');
  }
  return out.toString();
}

/// Số trang của PDF.
int pdfPageCount(Uint8List bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(bytes)).length;
