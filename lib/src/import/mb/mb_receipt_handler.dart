import '../../data/database.dart';
import '../mail/bank_senders.dart';
import '../mail/raw_mail.dart';
import 'mb_import_service.dart';
import 'mb_receipt_parser.dart';

/// Bộ đọc email biên lai MB cắm vào lớp lấy thư của N2 (F-29..F-31).
///
/// Mỗi thư: đọc → (thành công) nhập qua [MbImportService]; thư không đọc được
/// hoặc tình trạng khác "Giao dịch thành công" chỉ tăng bộ đếm (AC-85), không
/// lưu gì, kể cả nội dung. Lỗi cơ sở dữ liệu được ném ra: lớp lấy thư giữ UID
/// cũ và đưa lại cả lô lần sau — an toàn vì mỗi số tham chiếu chỉ nhập một lần
/// (AC-86).
class MbReceiptHandler implements ReceiptMailHandler {
  MbReceiptHandler(AppDatabase db) : _service = MbImportService(db);

  final MbImportService _service;

  @override
  Future<MailHandleResult> handle(List<RawMail> mails) async {
    var unreadable = 0;
    for (final mail in mails) {
      final receipt = mail.bank.id == mbBank.id ? _read(mail) : null;
      if (receipt == null) {
        unreadable++;
        continue;
      }
      await _service.importReceipt(receipt);
    }
    return MailHandleResult(unreadable: unreadable);
  }

  /// Đọc thân thư dạng chữ; nếu không được và có thêm HTML thì thử lại từ
  /// HTML (thư text/plain chỉ là dòng "xem bản HTML"). Chỉ trả biên lai khi
  /// thành công.
  MbReceipt? _read(RawMail mail) {
    final first = parseMbReceipt(mail.bodyText);
    if (first is MbReceipt) return first;
    if (first is MbRejected && first.reason == MbRejection.notSuccessful) {
      return null;
    }
    final html = mail.html;
    if (html == null || mail.textPlain == null) return null;
    final second = parseMbReceiptHtml(html);
    return second is MbReceipt ? second : null;
  }
}
