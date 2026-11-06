import '../../data/pin_service.dart';
import 'bank_senders.dart';
import 'enough_imap.dart';
import 'imap_gateway.dart';
import 'mailbox_service.dart';
import 'mailbox_store.dart';
import 'raw_mail.dart';

/// Một lần kiểm thư nền khi app ĐÓNG (Android, AC-82): `MailCheckJob.kt` dựng
/// FlutterEngine không giao diện và gọi `mailCheckBackgroundMain` trong
/// `lib/main.dart`, hàm đó gọi tới đây. Theo đúng luật của lần kiểm khi mở app
/// (cách lần trước ≥ 15 phút, bỏ hộp thư sai mật khẩu). Không ném lỗi.
///
/// [handler]: bộ đọc email biên lai (M1 truyền bộ đọc có cơ sở dữ liệu và tự
/// đóng cơ sở dữ liệu sau khi hàm này trả về).
Future<MailCheckOutcome?> runScheduledMailCheck({
  required ReceiptMailHandler handler,
  SecretStore secrets = const SecureSecretStore(),
  ImapConnector connector = const EnoughImapConnector(),
  SenderAllowlist senders = defaultSenderAllowlist,
  InstallMarker? marker,
  DateTime Function() clock = DateTime.now,
}) async {
  try {
    final service = MailboxService(
      store: MailboxStore(secrets, marker: marker),
      connector: connector,
      senders: senders,
      handler: handler,
      clock: clock,
    );
    return await service.checkAll(MailCheckTrigger.background);
  } catch (_) {
    return null;
  }
}
