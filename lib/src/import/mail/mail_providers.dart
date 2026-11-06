import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/lock/app_lock.dart';
import '../../providers.dart';
import 'bank_senders.dart';
import 'enough_imap.dart';
import 'imap_gateway.dart';
import 'mail_check_scheduler.dart';
import 'mailbox_service.dart';
import 'mailbox_store.dart';
import 'raw_mail.dart';

/// Kết nối IMAP; test ghi đè bằng máy chủ giả.
final imapConnectorProvider = Provider<ImapConnector>(
  (ref) => const EnoughImapConnector(),
);

/// Địa chỉ gửi được phép (AC-81); test ghi đè.
final senderAllowlistProvider = Provider<SenderAllowlist>(
  (ref) => defaultSenderAllowlist,
);

/// Bộ đọc email biên lai trong app. **M1 thay bằng bộ đọc thật** (vd
/// `MbReceiptHandler(ref.watch(databaseProvider))`).
final receiptMailHandlerProvider = Provider<ReceiptMailHandler>(
  (ref) => const DiscardingMailHandler(),
);

/// Dấu cài đặt (dọn Keychain khi cài lại trên iOS); test ghi đè.
final mailInstallMarkerProvider = Provider<InstallMarker>(
  (ref) => const FileInstallMarker(),
);

final mailboxServiceProvider = Provider<MailboxService>(
  (ref) => MailboxService(
    store: MailboxStore(
      ref.watch(secretStoreProvider),
      marker: ref.watch(mailInstallMarkerProvider),
    ),
    connector: ref.watch(imapConnectorProvider),
    senders: ref.watch(senderAllowlistProvider),
    handler: ref.watch(receiptMailHandlerProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Hộp thư đã thêm; làm mới bằng `ref.invalidate` sau mỗi thao tác/lần kiểm.
final mailboxesProvider = FutureProvider<List<Mailbox>>(
  (ref) => ref.watch(mailboxServiceProvider).mailboxes(),
);

/// Đã xem màn giải thích (AC-78) chưa.
final mailIntroSeenProvider = FutureProvider<bool>(
  (ref) => ref.watch(mailboxServiceProvider).introSeen(),
);

/// Lịch kiểm thư nền (Android); test ghi đè.
final mailCheckSchedulerProvider = Provider<MailCheckScheduler>(
  (ref) => platformMailCheckScheduler(),
);

/// Giữ lịch nền khớp danh sách hộp thư: có hộp thư → bật, không có → tắt.
/// `main.dart` giữ provider này sống.
final mailScheduleSyncProvider = Provider<void>((ref) {
  final boxes = ref.watch(mailboxesProvider);
  if (!boxes.hasValue) return;
  final scheduler = ref.watch(mailCheckSchedulerProvider);
  unawaited(boxes.value!.isEmpty ? scheduler.disable() : scheduler.enable());
});

/// Kiểm thư rồi làm mới trạng thái màn hộp thư. Không ném lỗi.
Future<MailCheckOutcome> checkMail(
  ProviderContainer container,
  MailCheckTrigger trigger,
) async {
  final outcome = await container
      .read(mailboxServiceProvider)
      .checkAll(trigger);
  container.invalidate(mailboxesProvider);
  return outcome;
}

/// Kiểm thư khi MỞ app (vài giây sau khung hình đầu) và mỗi khi QUAY LẠI app,
/// cách lần trước ≥ 15 phút (AC-82). Gọi một lần trong `main()`.
void runMailCheckOnOpen(
  ProviderContainer container, {
  Duration delay = const Duration(seconds: 4),
}) {
  void run() => unawaited(checkMail(container, MailCheckTrigger.open));
  container.listen(mailScheduleSyncProvider, (_, _) {});
  WidgetsBinding.instance.addPostFrameCallback((_) => Timer(delay, run));
  // Sống cùng app; không cần gỡ.
  AppLifecycleListener(onResume: run);
}

/// Hook của "Xóa toàn bộ dữ liệu" (AC-123): xoá mọi hộp thư, mật khẩu ứng
/// dụng, UID đã nhớ khỏi Keystore/Keychain và tắt kiểm thư nền. Phần cơ sở dữ
/// liệu (hàng đợi, số tham chiếu đã gặp…) do `deleteAllData` của M0 lo.
Future<void> eraseEmailImport(WidgetRef ref) async {
  await ref.read(mailboxServiceProvider).removeAll();
  await ref.read(mailCheckSchedulerProvider).disable();
  ref.invalidate(mailboxesProvider);
  ref.invalidate(mailIntroSeenProvider);
}
