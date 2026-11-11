import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/debt_repository.dart';
import '../../data/money.dart';
import '../../data/money_sum.dart';
import '../../providers.dart';
import '../debts/debts_providers.dart';
import '../savings/savings_providers.dart';
import 'reminder_providers.dart';
import 'reminder_scheduler.dart';

/// Payload khi chạm thông báo nhắc hạn: mở đúng màn (AC-157).
const deadlineDebtPayload = '/debts';
const deadlineSavingsPayload = '/savings';

/// Mã thông báo nhắc hạn nằm trong [_idBase, _idBase + _idSpan) để thay cả
/// lô mà không đụng lịch nhắc ghi sổ hay sao lưu.
const _idBase = 20000;
const _idSpan = 10000;
const deadlineChannelId = 'deadline_reminder';

/// Một thông báo nhắc hạn cần đặt.
class DeadlineNotification {
  const DeadlineNotification({
    required this.id,
    required this.at,
    required this.body,
    required this.payload,
  });

  final int id;

  /// Thời điểm theo giờ máy.
  final DateTime at;
  final String body;
  final String payload;

  @override
  String toString() => 'DeadlineNotification($id, $at, $body)';
}

/// Một mục có hạn (mục tiêu tiết kiệm hoặc khoản nợ) cùng số còn lại.
class DeadlineItem {
  const DeadlineItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.due,
    required this.remaining,
    required this.currency,
    this.borrowed = false,
  });

  final DeadlineKind kind;
  final int id;
  final String name;
  final DateTime due;

  /// Còn lại / còn thiếu theo tiền tệ của mục, đơn vị nhỏ nhất.
  final int remaining;
  final String currency;

  /// Khoản nợ chiều "Đi vay".
  final bool borrowed;
}

enum DeadlineKind { goal, debt }

/// Lịch nhắc hạn (F-48, AC-156): mỗi mục chưa xong có hạn báo hai lần — trước
/// [days] ngày và đúng ngày hạn — lúc [time]; mốc đã qua thì bỏ. Nội dung có
/// số tiền còn lại (AC-157, D-044).
List<DeadlineNotification> planDeadlineNotifications({
  required List<DeadlineItem> items,
  required int days,
  required TimeOfDay time,
  required DateTime now,
  required AppLocalizations l,
  required String locale,
}) {
  final result = <DeadlineNotification>[];
  for (final item in items) {
    if (item.remaining <= 0) continue;
    final amount = formatMoney(
      item.remaining,
      currencyCode: item.currency,
      locale: locale,
    );
    final offsets = {days, 0};
    for (final before in offsets) {
      final day = item.due.subtract(Duration(days: before));
      final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      if (!at.isAfter(now)) continue;
      final when = before == 0
          ? l.deadlineWhenToday
          : l.deadlineWhenDays(before);
      final body = switch (item.kind) {
        DeadlineKind.goal => l.deadlineGoal(item.name, amount, when),
        DeadlineKind.debt =>
          item.borrowed
              ? l.deadlineDebtBorrowed(item.name, amount, when)
              : l.deadlineDebtLent(item.name, amount, when),
      };
      // Mã ổn định theo (loại, id, mốc): goal chẵn, debt lẻ; mốc 0 hoặc 1.
      final kindBit = item.kind == DeadlineKind.goal ? 0 : 1;
      final slot = before == 0 ? 0 : 1;
      result.add(
        DeadlineNotification(
          id: _idBase + ((item.id * 4 + kindBit * 2 + slot) % _idSpan),
          at: at,
          body: body,
          payload: item.kind == DeadlineKind.goal
              ? deadlineSavingsPayload
              : deadlineDebtPayload,
        ),
      );
    }
  }
  return result;
}

/// Lớp ngăn giữa lịch nhắc hạn và plugin thông báo; test dùng bản giả.
abstract class DeadlineNotifier {
  /// Thay toàn bộ lịch nhắc hạn đã đặt bằng [items].
  Future<void> replaceAll(
    List<DeadlineNotification> items, {
    required String title,
    required String channelName,
    required String channelDescription,
  });
}

/// Bản thật dùng `flutter_local_notifications` (plugin đã được khởi tạo bởi
/// lịch nhắc ghi sổ, `reminderReadyProvider`).
class LocalDeadlineNotifier implements DeadlineNotifier {
  LocalDeadlineNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> replaceAll(
    List<DeadlineNotification> items, {
    required String title,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await ensureLocalTimeZone();
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= _idBase && p.id < _idBase + _idSpan) {
          await _plugin.cancel(id: p.id);
        }
      }
      final mode = await reminderScheduleMode(_plugin);
      for (final n in items) {
        await _plugin.zonedSchedule(
          id: n.id,
          title: title,
          body: n.body,
          payload: n.payload,
          scheduledDate: tz.TZDateTime.from(n.at, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              deadlineChannelId,
              channelName,
              channelDescription: channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              enableVibration: false,
              styleInformation: BigTextStyleInformation(n.body),
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: mode, // đúng phút nếu được phép (D-045)
        );
      }
    } catch (_) {
      // Không có plugin (test, nền tảng khác): bỏ qua, app vẫn chạy.
    }
  }
}

final deadlineNotifierProvider = Provider<DeadlineNotifier>(
  (ref) => LocalDeadlineNotifier(),
);

final deadlineReminderEnabledProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDeadlineReminderEnabled(),
);

final deadlineReminderDaysProvider = StreamProvider<int>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDeadlineReminderDays(),
);

final deadlineReminderTimeProvider = StreamProvider<TimeOfDay>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDeadlineReminderTime(),
);

/// Các mục có hạn chưa xong, kèm số còn lại theo tiền tệ của mục.
List<DeadlineItem> deadlineItems({
  required List<SavingsGoal> goals,
  required Map<int, MoneyBag> bags,
  required List<DebtView> debts,
  required int Function(MoneyBag bag, String currency) convert,
}) => [
  for (final g in goals)
    if (g.dueDate != null && g.completedAt == null)
      () {
        final balance = convert(bags[g.accountId] ?? MoneyBag(), g.currency);
        final target = g.originalTargetAmount ?? g.targetAmount;
        return DeadlineItem(
          kind: DeadlineKind.goal,
          id: g.id,
          name: g.name,
          due: parseDateKey(g.dueDate!),
          remaining: target - balance,
          currency: g.currency,
        );
      }(),
  for (final v in debts)
    if (v.debt.dueDate != null && !v.isSettled())
      DeadlineItem(
        kind: DeadlineKind.debt,
        id: v.debt.id,
        name: v.debt.person,
        due: parseDateKey(v.debt.dueDate!),
        remaining: v.remaining(),
        currency: v.debt.currency,
        borrowed: v.debt.direction == DebtDirection.borrowed,
      ),
];

/// Giữ lịch nhắc hạn khớp dữ liệu và cài đặt (AC-156): `VigonApp` theo dõi
/// provider này; mọi thay đổi mục tiêu, khoản nợ, khoản trong ví, cài đặt hay
/// ngôn ngữ đều xếp lại toàn bộ lịch.
final deadlineSyncProvider = Provider<void>((ref) {
  final ready = ref.watch(reminderReadyProvider);
  final enabled = ref.watch(deadlineReminderEnabledProvider).value;
  final days = ref.watch(deadlineReminderDaysProvider).value;
  final time = ref.watch(deadlineReminderTimeProvider).value;
  final localeCode = ref.watch(localeCodeProvider);
  final goals = ref.watch(savingsGoalsProvider).value;
  final debts = ref.watch(debtsProvider).value;
  final bags = ref.watch(accountBalanceBagsProvider).value;
  final service = ref.watch(currencyServiceProvider).value;
  ref.watch(todayProvider);
  ref.watch(exactAlarmAllowedProvider); // đổi quyền đúng giờ → đặt lại (D-045)
  if (!ready.hasValue ||
      enabled == null ||
      days == null ||
      time == null ||
      !localeCode.hasValue ||
      goals == null ||
      debts == null ||
      bags == null ||
      service == null) {
    return;
  }
  final l = reminderStrings(localeCode.value);
  final notifier = ref.read(deadlineNotifierProvider);
  final items = enabled
      ? planDeadlineNotifications(
          items: deadlineItems(
            goals: goals,
            bags: bags,
            debts: debts,
            convert: (bag, currency) => bag.convertTo(service, currency) ?? 0,
          ),
          days: days,
          time: time,
          now: ref.read(clockProvider)(),
          l: l,
          locale: localeCode.value ?? 'en',
        )
      : const <DeadlineNotification>[];
  unawaited(
    notifier.replaceAll(
      items,
      title: l.appTitle,
      channelName: l.deadlineChannelName,
      channelDescription: l.deadlineChannelDescription,
    ),
  );
});

/// Lần đầu có mục có hạn: giải thích rồi xin quyền thông báo (AC-155). Chỉ
/// hỏi một lần trên máy; từ chối thì tắt nhắc trước hạn.
Future<void> ensureDeadlinePermission(
  BuildContext context,
  WidgetRef ref, {
  required Future<bool> Function() explain,

  /// Chạy sau khi đã có quyền thông báo — vd mời bật báo đúng giờ (D-045).
  Future<void> Function()? afterGranted,
}) async {
  final settings = ref.read(settingsRepositoryProvider);
  if (await settings.readDeadlinePermissionAsked()) return;
  final enabled = await ref.read(deadlineReminderEnabledProvider.future);
  if (!enabled) return;
  if (!context.mounted) return;
  await settings.setDeadlinePermissionAsked();
  final agreed = await explain();
  if (!agreed) {
    await settings.setDeadlineReminderEnabled(false);
    return;
  }
  final granted = await ref.read(reminderSchedulerProvider).requestPermission();
  if (!granted) {
    await settings.setDeadlineReminderEnabled(false);
    return;
  }
  await afterGranted?.call();
}
