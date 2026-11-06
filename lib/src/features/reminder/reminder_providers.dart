import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import 'reminder_scheduler.dart';

/// Bản thật của lớp đặt lịch; test ghi đè bằng bản giả.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationsScheduler(),
);

final reminderEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchReminderEnabled(),
);

final reminderTimeProvider = StreamProvider<TimeOfDay>(
  (ref) => ref.watch(settingsRepositoryProvider).watchReminderTime(),
);

/// Một lần người dùng chạm thông báo. Không định nghĩa `==` để hai lần chạm
/// liên tiếp cùng payload vẫn là hai sự kiện riêng.
class ReminderTap {
  ReminderTap(this.payload);

  final String? payload;
}

class ReminderTapNotifier extends Notifier<ReminderTap?> {
  @override
  ReminderTap? build() => null;

  void tapped(String? payload) => state = ReminderTap(payload);
}

final reminderTapProvider = NotifierProvider<ReminderTapNotifier, ReminderTap?>(
  ReminderTapNotifier.new,
);

/// Khởi tạo plugin thông báo một lần khi mở app và lấy payload nếu app được
/// mở (từ trạng thái bị tắt hẳn) bằng cách chạm thông báo (AC-62).
final reminderReadyProvider = FutureProvider<void>((ref) async {
  final scheduler = ref.read(reminderSchedulerProvider);
  final tap = ref.read(reminderTapProvider.notifier);
  await scheduler.initialize(tap.tapped);
  final launch = await scheduler.launchPayload();
  if (launch != null) tap.tapped(launch);
});

/// Chữ của thông báo theo ngôn ngữ app (đã chọn, chưa chọn = English, D-036), lấy từ `.arb`.
AppLocalizations reminderStrings(String? localeCode) =>
    lookupAppLocalizations(Locale(localeCode ?? 'en'));

/// Giữ lịch nhắc khớp với cài đặt đã lưu: chạy khi mở app (đặt lại lịch sau khi
/// máy khởi động lại hay app bị cập nhật) và mỗi khi bật/tắt, đổi giờ hoặc đổi
/// ngôn ngữ (AC-61, AC-62). `VigonApp` theo dõi provider này.
final reminderSyncProvider = Provider<void>((ref) {
  final ready = ref.watch(reminderReadyProvider);
  final enabled = ref.watch(reminderEnabledProvider).value;
  final time = ref.watch(reminderTimeProvider).value;
  final localeCode = ref.watch(localeCodeProvider);
  if (!ready.hasValue ||
      enabled == null ||
      time == null ||
      !localeCode.hasValue) {
    return;
  }
  final scheduler = ref.read(reminderSchedulerProvider);
  if (!enabled) {
    unawaited(scheduler.cancel());
    return;
  }
  final l = reminderStrings(localeCode.value);
  unawaited(
    scheduler.schedule(
      time: time,
      title: l.appTitle,
      body: l.reminderNotificationBody,
      channelName: l.reminderChannelName,
      channelDescription: l.reminderChannelDescription,
    ),
  );
});

/// Chạm thông báo thì mở màn Nhập khoản chi. Màn khóa PIN phủ lên trên nên nếu
/// PIN đang bật, người dùng mở khóa xong mới thấy màn này (AC-62).
class ReminderTapBinder extends ConsumerWidget {
  const ReminderTapBinder({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(reminderTapProvider, (_, next) {
      // Chỉ nhận đúng đường dẫn của app, không đi theo chuỗi lạ.
      if (next?.payload == reminderPayload) router.go(reminderPayload);
    });
    return child;
  }
}
