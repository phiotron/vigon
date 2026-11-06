/// Giờ sao lưu tự động hằng ngày theo giờ máy (F-24, D-026).
///
/// Mỗi ngày có một **mốc** lúc [hour]:[minute] theo múi giờ hiện tại của máy.
/// Quy tắc "tối đa một lần mỗi ngày" tính theo mốc: mỗi mốc được xử lý nhiều
/// nhất một lần (sao lưu, thử mà lỗi, hoặc xét thấy dữ liệu không đổi). Một lần
/// xử lý lúc `t` phủ mọi mốc tới `t`, nên lỡ mấy ngày liền cũng chỉ bù một lần.
class BackupTime {
  const BackupTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Giờ điền sẵn khi bật (D-026).
  static const defaultTime = BackupTime(21, 0);

  final int hour;
  final int minute;

  /// Dạng lưu trong SecretStore: `HH:MM`.
  String encode() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Đọc dạng `HH:MM`; sai dạng hay ngoài khoảng thì null.
  static BackupTime? parse(String? text) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text ?? '');
    if (m == null) return null;
    final h = int.parse(m[1]!);
    final min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return BackupTime(h, min);
  }

  @override
  bool operator ==(Object other) =>
      other is BackupTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => encode();
}

/// Dựng một thời điểm theo giờ địa phương. Mặc định là [DateTime.new] (giờ máy);
/// test truyền hàm dựng `TZDateTime` của một múi giờ để kiểm đổi múi giờ, DST.
typedef LocalDateTimeBuilder = DateTime Function(
  int year,
  int month,
  int day,
  int hour,
  int minute,
);

DateTime _local(int y, int mo, int d, int h, int mi) =>
    DateTime(y, mo, d, h, mi);

/// Mốc của ngày chứa [day] (theo giờ địa phương của [day]). Giờ không tồn tại
/// vì chuyển giờ mùa hè được thư viện đẩy tới sau khoảng nhảy.
DateTime slotOn(
  DateTime day,
  BackupTime time, {
  LocalDateTimeBuilder at = _local,
}) => at(day.year, day.month, day.day, time.hour, time.minute);

/// Mốc kế tiếp, sau hẳn [now] (hôm nay nếu chưa tới giờ, không thì ngày mai).
DateTime nextSlot(
  DateTime now,
  BackupTime time, {
  LocalDateTimeBuilder at = _local,
}) {
  final today = slotOn(now, time, at: at);
  if (today.isAfter(now)) return today;
  return at(now.year, now.month, now.day + 1, time.hour, time.minute);
}

/// Mốc gần nhất đã tới (không sau [now]): hôm nay nếu đã qua giờ, không thì
/// hôm qua.
DateTime lastSlot(
  DateTime now,
  BackupTime time, {
  LocalDateTimeBuilder at = _local,
}) {
  final today = slotOn(now, time, at: at);
  if (!today.isAfter(now)) return today;
  return at(now.year, now.month, now.day - 1, time.hour, time.minute);
}

/// Có phải chạy (hoặc bù) sao lưu bây giờ không: mốc gần nhất chưa được xử lý.
/// [handledAt] là lần xử lý gần nhất (thử sao lưu, hoặc xét thấy dữ liệu không
/// đổi); null nghĩa là chưa từng xử lý.
bool isBackupDue({
  required DateTime now,
  required BackupTime time,
  DateTime? handledAt,
  LocalDateTimeBuilder at = _local,
}) {
  if (handledAt == null) return true;
  return handledAt.isBefore(lastSlot(now, time, at: at));
}

/// Mốc kế tiếp là hôm nay hay ngày mai (cho dòng "Lần tới: ..."); so ngày lịch
/// theo giờ địa phương của [now].
bool isToday(DateTime now, DateTime slot) =>
    slot.year == now.year && slot.month == now.month && slot.day == now.day;
