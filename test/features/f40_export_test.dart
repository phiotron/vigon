import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/debt_repository.dart';
import 'package:vigon/src/data/exchange_rate.dart';
import 'package:vigon/src/data/export_data.dart';
import 'package:vigon/src/data/money.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/data/rate_repository.dart';
import 'package:vigon/src/data/xlsx_writer.dart';
import 'package:vigon/src/features/export/export_pdf.dart';
import 'package:vigon/src/features/export/export_xlsx.dart';

import '../export_readers.dart';
import '../helpers.dart';

const _table = RateTable(
  base: 'USD',
  date: '2026-11-10',
  rates: {'VND': 25974},
);
const _usd = CurrencyService(_table, 'USD');
const _vnd = CurrencyService(_table, 'VND');
final _november = Period.custom(DateTime(2026, 11, 1), DateTime(2026, 11, 30));

Future<int> _entry(
  AppDatabase db, {
  required EntryType type,
  required int original,
  String currency = 'VND',
  int? categoryId,
  int accountId = 1,
  int? toAccountId,
  String date = '2026-11-05',
  String? time,
  String? note,
  EntrySource source = EntrySource.manual,
  int? toOriginal,
  String? toCurrency,
  CurrencyService service = _usd,
}) => db
    .into(db.entries)
    .insert(
      EntriesCompanion.insert(
        type: type,
        amount: service.toPrimary(original, currency)!,
        categoryId: Value(categoryId),
        accountId: accountId,
        toAccountId: Value(toAccountId),
        date: date,
        time: Value(time),
        note: Value(note),
        source: Value(source),
        currency: Value(currency),
        originalAmount: Value(original),
        toOriginalAmount: Value(toOriginal),
        toCurrency: Value(toCurrency),
        toAmount: Value(
          toOriginal == null
              ? null
              : service.toPrimary(toOriginal, toCurrency!),
        ),
      ),
    );

/// Sổ mẫu: Tiền mặt (₫, id 1) + Thẻ USD (id 2); danh mục theo seed (1 Ăn
/// uống, 2 Đi lại, 11 Lương). Ghi chú cố tình mở đầu bằng `= @ + -`.
Future<AppDatabase> _seed() async {
  final db = memoryDatabase();
  final card = await AccountRepository(db)
      .add(name: 'Thẻ USD', currency: 'USD');
  await _entry(
    db,
    type: EntryType.expense,
    original: 100000,
    categoryId: 1,
    time: '12:02',
    note: '=SUM(A1:A2)',
  );
  await _entry(
    db,
    type: EntryType.expense,
    original: 250,
    currency: 'USD',
    categoryId: 2,
    accountId: card,
    date: '2026-11-06',
    note: '@cmd Grab',
  );
  await _entry(
    db,
    type: EntryType.income,
    original: 9000000,
    categoryId: 11,
    date: '2026-11-01',
    note: '+84 912 345 678',
    source: EntrySource.emailMb,
  );
  await _entry(
    db,
    type: EntryType.transfer,
    original: 520000,
    toAccountId: card,
    toOriginal: 2000,
    toCurrency: 'USD',
    date: '2026-11-07',
    note: '-5 phí',
  );
  // Ngoài phạm vi: không có trong file.
  await _entry(
    db,
    type: EntryType.expense,
    original: 77000,
    categoryId: 1,
    date: '2026-10-31',
    note: 'Tháng trước',
  );
  final debts = DebtRepository(db);
  final debt = await debts.add(
    person: 'Anh Tuấn',
    direction: DebtDirection.lent,
    amount: _usd.toPrimary(1000000, 'VND')!,
    originalAmount: 1000000,
    currency: 'VND',
    date: '2026-11-02',
    dueDate: '2026-12-01',
  );
  await debts.addPayment(
    debt,
    amount: _usd.toPrimary(400000, 'VND')!,
    originalAmount: 400000,
    currency: 'VND',
    date: '2026-11-08',
  );
  return db;
}

AppLocalizations _l(String code) => lookupAppLocalizations(Locale(code));

Future<ExportFonts> _fonts() async => ExportFonts(
  regular: await File('assets/fonts/BeVietnamPro-Regular.ttf').readAsBytes(),
  bold: await File('assets/fonts/BeVietnamPro-Bold.ttf').readAsBytes(),
);

String _flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
    await initializeDateFormatting('en');
  });

  group('xlsx (AC-117)', () {
    late AppDatabase db;
    late Uint8List bytes;
    late Map<String, List<List<ReadCell>>> book;

    setUp(() async {
      db = await _seed();
      final data = await loadExportData(db, _november, _usd);
      bytes = buildExportXlsx(data, _l('vi'));
      book = readXlsx(bytes);
    });
    tearDown(() => db.close());

    test('ba sheet, tiêu đề theo ngôn ngữ app', () {
      expect(book.keys, ['Khoản', 'Theo danh mục', 'Khoản nợ']);
      expect(
        [for (final c in book['Khoản']!.first) c.value],
        [
          'Ngày',
          'Giờ',
          'Loại',
          'Số tiền',
          'Tiền tệ',
          'Số tiền (USD)',
          'Danh mục',
          'Tài khoản',
          'Đến tài khoản',
          'Số nhận',
          'Tiền tệ nhận',
          'Ghi chú',
          'Nguồn',
        ],
      );
      final en = readXlsx(
        buildExportXlsx(
          ExportData(
            range: _november,
            rows: const [],
            accounts: const {},
            debts: const [],
            service: _usd,
          ),
          _l('en'),
        ),
      );
      expect(en.keys, ['Records', 'By category', 'Debts']);
      expect(en['Records']!.first.first.value, 'Date');
    });

    test('khoản trong phạm vi, cũ nhất trước; ô số đúng số lẻ (D-042)', () {
      final rows = book['Khoản']!.skip(1).toList();
      expect(rows, hasLength(4)); // khoản 31/10 không có
      String col(List<ReadCell> r, String letter) =>
          r.firstWhere((c) => c.ref.startsWith(letter)).value;
      ReadCell cell(List<ReadCell> r, String letter) =>
          r.firstWhere((c) => c.ref.startsWith(letter));
      expect(
        [for (final r in rows) col(r, 'L')],
        ['+84 912 345 678', '=SUM(A1:A2)', '@cmd Grab', '-5 phí'],
      );

      // Ngày là ô ngày thật: 2026-11-01 = 46327 kể từ 1899-12-30.
      expect(cell(rows[0], 'A').numFmt, 'yyyy-mm-dd');
      expect(
        DateTime.utc(
          1899,
          12,
          30,
        ).add(Duration(days: int.parse(col(rows[0], 'A')))),
        DateTime.utc(2026, 11, 1),
      );

      // Khoản chi 100 000 ₫, Tiền tệ chính USD: gốc 100000 (₫, không lẻ) và
      // 3.85 USD (2 số lẻ).
      final food = rows[1];
      expect(col(food, 'B'), '12:02');
      expect(col(food, 'C'), 'Chi');
      expect(cell(food, 'D').type, 'n');
      expect(col(food, 'D'), '100000');
      expect(cell(food, 'D').numFmt, '#,##0');
      expect(col(food, 'E'), 'VND');
      expect(col(food, 'F'), '3.85');
      expect(cell(food, 'F').numFmt, '#,##0.00');
      expect(col(food, 'G'), 'Ăn uống');
      expect(col(food, 'H'), 'Tiền mặt');
      expect(col(food, 'M'), 'Ghi tay');

      // Khoản USD: số gốc 2.50, cột USD cũng 2.50.
      expect(col(rows[2], 'D'), '2.50');
      expect(col(rows[2], 'F'), '2.50');
      expect(col(rows[2], 'H'), 'Thẻ USD');

      // Thu từ email MB: nguồn "Email MB", không giờ thì ô Giờ trống.
      expect(col(rows[0], 'C'), 'Thu');
      expect(col(rows[0], 'M'), 'Email MB');
      expect(rows[0].any((c) => c.ref.startsWith('B')), isFalse);

      // Chuyển tiền khác tiền tệ: đến tài khoản + số nhận gốc.
      final transfer = rows[3];
      expect(col(transfer, 'C'), 'Chuyển tiền');
      expect(transfer.any((c) => c.ref.startsWith('G')), isFalse);
      expect(col(transfer, 'I'), 'Thẻ USD');
      expect(col(transfer, 'J'), '20.00');
      expect(col(transfer, 'K'), 'USD');
    });

    test('ô chữ mở đầu bằng = + - @ vẫn là chữ, không là công thức', () {
      for (final sheet in book.values) {
        for (final row in sheet) {
          for (final c in row) {
            expect(c.hasFormula, isFalse, reason: c.ref);
            expect(c.type, anyOf('s', 'n'), reason: c.ref);
          }
        }
      }
      final notes = [
        for (final r in book['Khoản']!.skip(1))
          r.firstWhere((c) => c.ref.startsWith('L')),
      ];
      for (final c in notes) {
        expect(c.type, 's', reason: c.value);
        expect(c.quotePrefix, isTrue, reason: c.value);
      }
      // Không ô chữ thường nào bị gắn cờ.
      final plain = book['Khoản']![1].firstWhere((c) => c.ref.startsWith('G'));
      expect(plain.quotePrefix, isFalse);
    });

    test('theo danh mục: tổng theo Tiền tệ chính và %', () {
      final rows = book['Theo danh mục']!;
      expect(
        [for (final c in rows.first) c.value],
        ['Loại', 'Danh mục', 'Tổng (USD)', 'Tỷ lệ'],
      );
      final body = [
        for (final r in rows.skip(1)) [for (final c in r) c.value],
      ];
      // Chi: 100 000 ₫ + $2.50, cộng gốc rồi quy một lần = $6.35.
      expect(body, [
        ['Chi', 'Ăn uống', '3.85', '0.606'],
        ['Chi', 'Đi lại', '2.50', '0.394'],
        ['Thu', 'Lương', '346.50', '1.000'],
      ]);
      expect(rows[1][3].numFmt, '0.0%');
    });

    test('khoản nợ: số tiền, đã trả, còn lại, hạn, trạng thái', () {
      final rows = book['Khoản nợ']!;
      expect(
        [for (final c in rows.first) c.value],
        [
          'Người',
          'Chiều',
          'Số tiền',
          'Đã trả',
          'Còn lại',
          'Tiền tệ',
          'Còn lại (USD)',
          'Ngày',
          'Hạn',
          'Trạng thái',
          'Ghi chú',
        ],
      );
      final d = rows[1];
      expect(
        [for (final c in d.take(7)) c.value],
        ['Anh Tuấn', 'Cho vay', '1000000', '400000', '600000', 'VND', '23.10'],
      );
      expect(d.firstWhere((c) => c.ref.startsWith('J')).value, 'Chưa xong');
      expect(d.firstWhere((c) => c.ref.startsWith('I')).numFmt, 'yyyy-mm-dd');
    });
  });

  group('xlsx_writer', () {
    test('số thập phân chính xác, không qua số thực', () {
      expect(xlsxDecimal(0, 2), '0.00');
      expect(xlsxDecimal(5, 2), '0.05');
      expect(xlsxDecimal(-123456, 2), '-1234.56');
      expect(xlsxDecimal(999999999999, 0), '999999999999');
      expect(xlsxDecimal(1, 3), '0.001');
      expect(xlsxColumnName(0), 'A');
      expect(xlsxColumnName(25), 'Z');
      expect(xlsxColumnName(26), 'AA');
    });

    test('ký tự đặc biệt XML được thoát, tên sheet hợp lệ', () {
      final book = readXlsx(
        buildXlsx([
          XlsxSheet(
            name: 'A/B:C',
            header: const ['x'],
            rows: const [
              [XlsxText('<b>&"tag"\u0001')],
            ],
          ),
        ]),
      );
      expect(book.keys.single, 'A B C');
      expect(book.values.single[1].single.value, '<b>&"tag"');
    });
  });

  group('PDF (AC-118)', () {
    test(
      'tiêu đề, tổng, theo danh mục, danh sách khoản; chữ có dấu đúng',
      () async {
        final db = await _seed();
        addTearDown(db.close);
        final data = await loadExportData(db, _november, _vnd);
        final l = _l('vi');
        final bytes = await buildExportPdf(
          data,
          l,
          periodTitle: 'Tháng 11 năm 2026',
          fonts: await _fonts(),
        );
        expect(latin1Prefix(bytes), '%PDF');
        final text = _flat(extractPdfText(bytes));
        String vnd(int v) =>
            _flat(formatMoney(v, currencyCode: 'VND', locale: 'vi'));
        for (final s in [
          'Báo cáo thu chi Tháng 11 năm 2026',
          'Số tiền theo VND',
          'Tổng thu',
          'Tổng chi',
          'Chênh lệch',
          'Theo danh mục',
          'Ăn uống',
          'Đi lại',
          'Lương',
          'Danh sách khoản',
          '=SUM(A1:A2)',
          '-5 phí',
          'Chuyển tiền: Tiền mặt',
          'Thẻ USD',
          '12:02',
          vnd(9000000),
          'Trang 1/1',
        ]) {
          expect(text, contains(_flat(s)), reason: s);
        }
        // Khoản USD khi Tiền tệ chính VND: số ₫ trên, số gốc $ dưới (AC-146).
        expect(
          text,
          contains(_flat(formatMoney(250, currencyCode: 'USD', locale: 'vi'))),
        );
        expect(text, isNot(contains('Tháng trước')));
      },
    );

    test('tự sang trang khi dài; 1.000 khoản xuất nhanh', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      await db.batch((b) {
        for (var i = 0; i < 1000; i++) {
          b.insert(
            db.entries,
            EntriesCompanion.insert(
              type: EntryType.expense,
              amount: 10000 + i,
              categoryId: Value(1 + i % 3),
              accountId: 1,
              date: '2026-11-${(1 + i % 28).toString().padLeft(2, '0')}',
              note: Value('Ghi chú số $i — phở, bún, cà phê'),
              currency: const Value('VND'),
              originalAmount: Value(10000 + i),
            ),
          );
        }
      });
      final watch = Stopwatch()..start();
      final data = await loadExportData(db, _november, _vnd);
      final bytes = await buildExportPdf(
        data,
        _l('vi'),
        periodTitle: 'Tháng 11 năm 2026',
        fonts: await _fonts(),
      );
      final xlsx = buildExportXlsx(data, _l('vi'));
      watch.stop();
      expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
      final pages = pdfPageCount(bytes);
      expect(pages, greaterThan(10));
      final text = _flat(extractPdfText(bytes));
      expect(text, contains('Trang $pages/$pages'));
      expect(text, contains('Ghi chú số 999'));
      expect(readXlsx(xlsx)['Khoản']!, hasLength(1001));
    });

    test('font nhúng có đủ chữ tiếng Việt và ký hiệu tiền', () async {
      final fonts = await _fonts();
      final font = TtfParser(fonts.regular.buffer.asByteData());
      for (final ch
          in 'ĂăÂâĐđÊêÔôƠơƯưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ₫'
              .runes) {
        expect(
          font.charToGlyphIndexMap.containsKey(ch),
          isTrue,
          reason: String.fromCharCode(ch),
        );
      }
    });
  });
}

String latin1Prefix(Uint8List bytes) => String.fromCharCodes(bytes.take(4));
