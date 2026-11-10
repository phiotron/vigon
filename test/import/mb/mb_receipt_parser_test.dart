import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/import/mail/bank_senders.dart';
import 'package:vigon/src/import/mail/raw_mail.dart';
import 'package:vigon/src/import/mb/mb_receipt_parser.dart';

String _sample(String name) =>
    File('test/import/samples/mb/$name').readAsStringSync();

MbReceipt _ok(MbParseResult r) {
  expect(r, isA<MbReceipt>(), reason: '$r');
  return r as MbReceipt;
}

/// Thân thư text với một số trường thay đổi (null = bỏ cả dòng).
String _body({
  String? tradeTime = '08-11-2026 09:30:15',
  String? reference = '26110809301234567',
  String? debit = 'TRAN THI MAU - ········4821 (VND)',
  String? payee = 'LE VAN KHACH - 012300XXX7788',
  String? amount = '(VND) 48,000.00',
  String? content = 'TRAN THI MAU chuyen tien',
  String? status = 'Giao dịch thành công',
}) {
  final rows = <String, String?>{
    'Ngày, giờ giao dịch': tradeTime,
    'Loại giao dịch': 'Chuyển tiền nhanh ngoài MB',
    'Số tham chiếu': reference,
    'Tài khoản trích nợ': debit,
    'Người thụ hưởng': payee,
    'Số tiền giao dịch': amount,
    'Nội dung chuyển tiền': content,
    'Cách thức lệnh': 'Thanh toán ngay',
    'Ngày nhập lệnh': '08-11-2026',
    'Thời gian': tradeTime,
    'Tình trạng': status,
  };
  return [
    'MB xin thông báo giao dịch của Quý khách đã được thực hiện như sau:',
    for (final e in rows.entries)
      if (e.value != null) '${e.key}: ${e.value}',
    'Xin chân thành cảm ơn.',
  ].join('\n');
}

void _expectSample(MbReceipt r) {
  expect(r.dateKey, '2026-11-08');
  expect(r.time, '09:30');
  expect(r.reference, '26110809301234567');
  expect(r.debitLast4, '4821');
  expect(r.currency, 'VND');
  expect(r.amount, 48000);
  expect(r.payee, 'LE VAN KHACH');
  expect(r.transferContent, 'TRAN THI MAU chuyen tien');
  expect(r.transactionType, 'Chuyển tiền nhanh ngoài MB');
}

void main() {
  group('mẫu đã che (AC-84)', () {
    test('HTML dạng bảng → đúng mọi trường (qua htmlToText)', () {
      _expectSample(_ok(parseMbReceiptHtml(_sample('success_table.html'))));
    });

    test('HTML dạng bảng qua RawMail.bodyText (đường N2 thật)', () {
      // N2 chỉ có html → bodyText = htmlToText(html).
      final text = htmlToText(_sample('success_table.html'));
      _expectSample(_ok(parseMbReceipt(text)));
    });

    test('text thuần "Nhãn: giá trị"', () {
      _expectSample(_ok(parseMbReceipt(_sample('success_text.txt'))));
    });

    test('nhãn một dòng, giá trị dòng kế', () {
      final text = [
        'Ngày, giờ giao dịch',
        '08-11-2026 09:30:15',
        'Loại giao dịch',
        'Chuyển tiền nhanh ngoài MB',
        'Số tham chiếu',
        '26110809301234567',
        'Tài khoản trích nợ',
        'TRAN THI MAU - ········4821 (VND)',
        'Người thụ hưởng',
        'LE VAN KHACH - 012300XXX7788',
        'Số tiền giao dịch',
        '(VND) 48,000.00',
        'Nội dung chuyển tiền',
        'TRAN THI MAU chuyen tien',
        'Tình trạng',
        'Giao dịch thành công',
      ].join('\n');
      _expectSample(_ok(parseMbReceipt(text)));
    });

    test('nhãn và giá trị cách bằng tab (bảng đã bỏ thẻ)', () {
      final text = _sample('success_text.txt').replaceAll(': ', '\t');
      _expectSample(_ok(parseMbReceipt(text)));
    });
  });

  group('thư MB thật (Outlook/Word HTML, đã che) — 2026-11-10', () {
    // Thư thật chỉ có text/html; nhãn bị ngắt dòng trong mã nguồn
    // ("Ng&#224;y,⏎  gi&#7901; giao d&#7883;ch"), mỗi ô bọc <p>. Trước khi
    // sửa htmlToText, mọi thư thật đều "không đọc được".
    final html = _sample('real_outlook_2026-11-09.html');

    void expectReal(MbReceipt r) {
      expect(r.dateKey, '2026-11-09');
      expect(r.time, '11:23');
      expect(r.reference, '26110900000000001');
      expect(r.debitLast4, '2004');
      expect(r.currency, 'VND');
      expect(r.amount, 87000);
      expect(r.payee, 'NGUYEN VAN A');
      expect(r.transferContent, 'NGUYEN VAN A chuyen tien');
      expect(r.transactionType, 'Chuyển tiền nhanh ngoài MB');
    }

    test('đọc được qua RawMail.bodyText (chỉ có html)', () {
      final mail = RawMail(
        mailboxId: 'm0',
        uid: 1,
        from: 'mbebanking@mbbank.com.vn',
        bank: mbBank,
        subject: 'Thong bao giao dich thanh cong',
        date: DateTime(2026, 11, 9, 11, 50),
        html: html,
      );
      expectReal(_ok(parseMbReceipt(mail.bodyText)));
    });

    test('htmlToText: xuống dòng trong mã nguồn chỉ là khoảng trắng', () {
      final text = htmlToText(html);
      expect(text, contains('Ngày, giờ giao dịch'));
      expect(text, contains('Số tham chiếu'));
      expect(text, contains('Giao dịch thành công'));
      expect(text, isNot(contains('&ndash;')));
    });

    test('htmlToText giữ <br> và </p> là xuống dòng', () {
      expect(htmlToText('<p>a\n b</p><p>c<br>d</p>'), 'a b\nc\nd');
    });
  });

  group('nhãn và khoảng trắng', () {
    test('nhãn không dấu, viết hoa/thường lẫn lộn, thiếu dấu phẩy', () {
      final text = _body()
          .replaceAll('Ngày, giờ giao dịch', 'NGAY GIO GIAO DICH')
          .replaceAll('Số tham chiếu', 'so tham chieu')
          .replaceAll('Tài khoản trích nợ', 'Tai khoan trich no')
          .replaceAll('Tình trạng', 'tinh trang');
      _expectSample(_ok(parseMbReceipt(text)));
    });

    test('khoảng trắng không ngắt dòng và khoảng trắng thừa', () {
      final text = _body()
          .replaceAll(
            'Số tiền giao dịch: (VND) 48,000.00',
            'Số tiền giao dịch  :  (VND) 48,000.00',
          )
          .replaceAll(
            'Tình trạng: Giao dịch thành công',
            '  Tình   trạng :   Giao  dịch thành   công  ',
          );
      _expectSample(_ok(parseMbReceipt(text)));
    });

    test('HTML có thực thể &nbsp; trong nhãn và giá trị', () {
      const html = '''
<table>
<tr><td>Ng&agrave;y,&nbsp;giờ giao dịch</td><td>08-11-2026&nbsp;09:30:15</td></tr>
<tr><td>Số&nbsp;tham&nbsp;chiếu</td><td>26110809301234567</td></tr>
<tr><td>Tài khoản trích nợ</td><td>X - 0123456789 (VND)</td></tr>
<tr><td>Số tiền giao dịch</td><td>(VND)&nbsp;48,000.00</td></tr>
<tr><td>Tình trạng</td><td>Giao&nbsp;dịch&nbsp;thành&nbsp;công</td></tr>
</table>''';
      final r = _ok(parseMbReceiptHtml(html));
      expect(r.time, '09:30');
      expect(r.debitLast4, '6789');
      expect(r.payee, isNull);
      expect(r.transferContent, isNull);
    });
  });

  group('giờ giao dịch (AC-84)', () {
    test('lấy từ thân thư, có giây, bỏ giây', () {
      final r = _ok(parseMbReceipt(_body(tradeTime: '06-11-2026 12:11:42')));
      expect((r.dateKey, r.time), ('2026-11-06', '12:11'));
    });

    test('thiếu "Ngày, giờ giao dịch" thì dùng "Thời gian"', () {
      final text = _body().replaceAll(
        RegExp(r'Ngày, giờ giao dịch: [^\n]*\n'),
        '',
      );
      expect(_ok(parseMbReceipt(text)).time, '09:30');
    });

    for (final bad in [
      '31-02-2026 10:00:00',
      '2026-11-08 09:30:15',
      '08-11-2026',
      '08-11-2026 25:00:00',
      '08/11/2026 09:30:15',
      'hôm nay',
    ]) {
      test('ngày giờ sai "$bad" → không đọc được', () {
        expect(
          parseMbReceipt(_body(tradeTime: bad)),
          isA<MbRejected>().having(
            (r) => r.reason,
            'reason',
            MbRejection.unreadable,
          ),
        );
      });
    }
  });

  group('số tiền', () {
    test('en-US 48,000.00 / 1,250,000.00', () {
      expect(
        _ok(parseMbReceipt(_body(amount: '(VND) 48,000.00'))).amount,
        48000,
      );
      expect(
        _ok(parseMbReceipt(_body(amount: '(VND) 1,250,000.00'))).amount,
        1250000,
      );
    });

    test('không có phần lẻ và dạng nghìn kiểu Việt cho VND (AC-84)', () {
      expect(_ok(parseMbReceipt(_body(amount: '(VND) 50,000'))).amount, 50000);
      expect(_ok(parseMbReceipt(_body(amount: '(VND) 50.000'))).amount, 50000);
      expect(
        _ok(parseMbReceipt(_body(amount: '(VND) 1.250.000'))).amount,
        1250000,
      );
      expect(
        _ok(parseMbReceipt(_body(amount: '(VND) 48.000,00'))).amount,
        48000,
      );
      expect(_ok(parseMbReceipt(_body(amount: '(VND)48000'))).amount, 48000);
    });

    test('tiền tệ có phần lẻ: USD theo cent', () {
      final r = _ok(parseMbReceipt(_body(amount: '(USD) 1,234.50')));
      expect((r.currency, r.amount), ('USD', 123450));
      expect(_ok(parseMbReceipt(_body(amount: '(usd) 12.5'))).amount, 1250);
    });

    for (final bad in [
      '48,000.00', // thiếu tiền tệ trong ngoặc
      '(VND) 48,000.50', // lẻ khác 0 mà VND không có
      '(VND) 0.00',
      '(VND) abc',
      '(VND) 1,23,456',
      '(VND) -48,000.00',
      '(VND) 48,000.00.00',
      '(VND) 999,999,999,999,999.00', // vượt giới hạn
      '(VN) 48,000.00',
      '',
    ]) {
      test('số tiền sai "$bad" → không đọc được', () {
        expect(
          parseMbReceipt(_body(amount: bad)),
          isA<MbRejected>().having(
            (r) => r.reason,
            'reason',
            MbRejection.unreadable,
          ),
        );
      });
    }
  });

  group('tài khoản trích nợ, người thụ hưởng, nội dung (AC-88)', () {
    test('chỉ giữ 4 số cuối; số đầy đủ không lọt ra kết quả', () {
      final r = _ok(
        parseMbReceipt(_body(debit: 'TRAN THI MAU - 0123456789 (VND)')),
      );
      expect(r.debitLast4, '6789');
      expect('$r', isNot(contains('0123')));
    });

    test('không có tiền tệ ở tài khoản trích nợ vẫn được', () {
      expect(
        _ok(parseMbReceipt(_body(debit: 'TRAN THI MAU - ····4821'))).debitLast4,
        '4821',
      );
    });

    test('thiếu số tài khoản → không đọc được', () {
      expect(
        parseMbReceipt(_body(debit: 'TRAN THI MAU (VND)')),
        isA<MbRejected>(),
      );
    });

    test('cắt " - số TK" khỏi người thụ hưởng, giữ gạch ngang trong tên', () {
      expect(
        _ok(parseMbReceipt(_body(payee: 'CTY A - B - 054100XXX3102'))).payee,
        'CTY A - B',
      );
      expect(
        _ok(parseMbReceipt(_body(payee: 'LE VAN KHACH - 0123456789'))).payee,
        'LE VAN KHACH',
      );
      // Không có số TK → giữ nguyên tên.
      expect(
        _ok(parseMbReceipt(_body(payee: 'QUY - TU THIEN'))).payee,
        'QUY - TU THIEN',
      );
    });

    test('người thụ hưởng / nội dung thiếu hoặc rỗng → null, vẫn đọc được', () {
      final r = _ok(parseMbReceipt(_body(payee: null, content: null)));
      expect(r.payee, isNull);
      expect(r.transferContent, isNull);
      final empty = _ok(parseMbReceipt(_body(payee: '', content: '')));
      expect(empty.transferContent, isNull);
    });

    test('nội dung dài bị cắt ở 500 ký tự', () {
      final long = 'a' * 700;
      expect(
        _ok(parseMbReceipt(_body(content: long))).transferContent!.length,
        500,
      );
    });
  });

  group('tình trạng (AC-85)', () {
    test('chấp nhận đúng chữ thành công, không phân biệt hoa/thường, khoảng '
        'trắng, dấu', () {
      for (final s in [
        'Giao dịch thành công',
        'GIAO DỊCH THÀNH CÔNG',
        'giao dich thanh cong',
        '  Giao   dịch thành công. ',
      ]) {
        expect(parseMbReceipt(_body(status: s)), isA<MbReceipt>(), reason: s);
      }
    });

    test('chữ khác → notSuccessful, không tạo khoản', () {
      for (final s in [
        'Giao dịch không thành công',
        'Giao dịch thất bại',
        'Giao dịch đang xử lý',
        'Thành công',
        'Giao dịch thành công một phần',
      ]) {
        expect(
          parseMbReceipt(_body(status: s)),
          isA<MbRejected>().having(
            (r) => r.reason,
            'reason',
            MbRejection.notSuccessful,
          ),
          reason: s,
        );
      }
    });

    test('thiếu hẳn dòng tình trạng → không đọc được; để trống → bỏ', () {
      expect(
        parseMbReceipt(_body(status: null)),
        isA<MbRejected>().having(
          (r) => r.reason,
          'reason',
          MbRejection.unreadable,
        ),
      );
      // Giá trị trống: không bao giờ là thành công.
      expect(parseMbReceipt(_body(status: '')), isA<MbRejected>());
    });
  });

  group('thiếu trường bắt buộc / thư lạ', () {
    test('thiếu từng trường bắt buộc → không đọc được', () {
      for (final r in [
        _body(tradeTime: null),
        _body(reference: null),
        _body(debit: null),
        _body(amount: null),
      ]) {
        expect(parseMbReceipt(r), isA<MbRejected>());
      }
      // Số tham chiếu sai định dạng.
      expect(parseMbReceipt(_body(reference: '12 34')), isA<MbRejected>());
      expect(parseMbReceipt(_body(reference: '123')), isA<MbRejected>());
    });

    test('thư không phải biên lai (quảng cáo, rỗng) → không đọc được', () {
      for (final t in [
        '',
        'MB tặng bạn ưu đãi 50% phí chuyển tiền',
        '<html></html>',
      ]) {
        expect(parseMbReceipt(t), isA<MbRejected>());
      }
    });

    test('toString không in nội dung thư', () {
      final r = parseMbReceipt(_body());
      expect('$r', isNot(contains('LE VAN')));
      expect('$r', isNot(contains('4821')));
    });
  });
}
