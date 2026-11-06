import '../../data/database.dart';
import '../mail/bank_senders.dart';
import '../mail/raw_mail.dart';
import 'mb_import_service.dart';
import 'mb_receipt_parser.dart';

/// Bộ đọc email biên lai MB cắm vào lớp lấy thư của N2 (F-29..F-31).
///
/// Mỗi thư: đọc → (thành công) nhập qua [MbImportService]; thư không đọc được
/// chỉ tăng bộ đếm khi thiếu/hỏng trường bắt buộc (AC-85); tình trạng đọc
/// được mà khác "Giao dịch thành công" chỉ bị bỏ. Không lưu gì từ thư lỗi.
/// Lỗi cơ sở dữ liệu được ném ra: lớp lấy thư giữ UID cũ và đưa lại cả lô lần sau — an toàn vì mỗi số tham chiếu chỉ nhập một lần
/// (AC-86).
class MbReceiptHandler implements ReceiptMailHandler {
  MbReceiptHandler(AppDatabase db) : _service = MbImportService(db);

  final MbImportService _service;

  @override
  Future<MailHandleResult> handle(List<RawMail> mails) async {
    var unreadable = 0;
    for (final mail in mails) {
      final result = mail.bank.id == mbBank.id
          ? _read(mail)
          : const MbRejected(MbRejection.unreadable);
      switch (result) {
        case MbReceipt():
          await _service.importReceipt(result);
        case MbRejected(reason: MbRejection.unreadable):
          unreadable++;
        // Tình trạng đọc được nhưng không phải thành công (AC-85): chỉ bỏ,
        // không lưu, không đếm.
        case MbRejected():
          break;
      }
    }
    return MailHandleResult(unreadable: unreadable);
  }

  /// Đọc thân thư dạng chữ; nếu không được và có thêm HTML thì thử lại từ
  /// HTML (text/plain chỉ là dòng "xem bản HTML").
  MbParseResult _read(RawMail mail) {
    final first = parseMbReceipt(mail.bodyText);
    if (first is! MbRejected || first.reason != MbRejection.unreadable) {
      return first;
    }
    final html = mail.html;
    if (html == null || mail.textPlain == null) return first;
    return parseMbReceiptHtml(html);
  }
}
