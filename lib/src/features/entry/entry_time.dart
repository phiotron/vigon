import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';

/// Giờ của khoản lưu dạng chữ `HH:mm` theo giờ máy (F-27, AC-74).
String timeKey(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Giờ hiện tại của [now] dạng `HH:mm`: giờ mặc định của khoản mới (AC-74).
String nowTimeKey(DateTime now) => timeKey(TimeOfDay.fromDateTime(now));

/// Đọc `HH:mm`; null nếu [key] trống hoặc sai dạng.
TimeOfDay? parseTimeKey(String? key) {
  if (key == null) return null;
  final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final h = int.parse(m[1]!), min = int.parse(m[2]!);
  return h > 23 || min > 59 ? null : TimeOfDay(hour: h, minute: min);
}

/// Giờ hiện cho người dùng, 24 giờ hay 12 giờ theo máy (AC-74).
String formatTimeKey(BuildContext context, String key) {
  final t = parseTimeKey(key);
  if (t == null) return key;
  return MaterialLocalizations.of(context).formatTimeOfDay(
    t,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Chip Giờ ở màn Nhập/Sửa khoản và Chuyển tiền: giờ đã chọn, hoặc "Chưa đặt
/// giờ" khi khoản cũ/định kỳ chưa có giờ (AC-75). Chạm mở bộ chọn giờ hệ thống.
class TimeChip extends StatelessWidget {
  const TimeChip({
    super.key,
    required this.time,
    required this.fallback,
    required this.onChanged,
  });

  /// `HH:mm` hoặc null (chưa đặt giờ).
  final String? time;

  /// Giờ bộ chọn mở ra khi [time] chưa có (giờ lúc này).
  final String fallback;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = time == null
        ? '${l.timeNotSet} · ${l.setTime}'
        : formatTimeKey(context, time!);
    // Chưa có giờ: chip viền nét đứt + icon more_time (mockup v4 SCR-06
    // no-time) thay cho một ô trống.
    return ActionChip(
      avatar: Icon(
        time == null ? Symbols.more_time_rounded : Symbols.schedule_rounded,
        size: 18,
      ),
      side: time == null
          ? BorderSide(color: Theme.of(context).colorScheme.outline)
          : null,
      label: Text(label),
      tooltip: l.entryTime,
      onPressed: () async {
        final picked = await showTimePicker(
          // Kiểu nhập bàn phím lỗi "BoxConstraints non-normalized" khi cỡ chữ
          // hệ thống nhỏ (Galaxy A13 0.8) — giữ mặt đồng hồ như A001 `b0f32fa`.
          initialEntryMode: TimePickerEntryMode.dialOnly,
          context: context,
          initialTime:
              parseTimeKey(time) ??
              parseTimeKey(fallback) ??
              const TimeOfDay(hour: 12, minute: 0),
        );
        if (picked != null) onChanged(timeKey(picked));
      },
    );
  }
}
