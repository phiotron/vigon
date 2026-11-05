import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database.dart';

/// Đọc, ghi cài đặt trong bảng khóa-giá trị (D-005).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const themeModeKey = 'themeMode';
  static const localeKey = 'locale';
  static const currencyKey = 'currency';
  static const weekStartKey = 'weekStart';
  static const monthStartDayKey = 'monthStartDay';
  static const budgetKey = 'monthlyBudget';
  static const secureWindowKey = 'secureWindow';
  static const widgetShowAmountsKey = 'widgetShowAmounts';
  static const reminderEnabledKey = 'reminderEnabled';
  static const reminderTimeKey = 'reminderTime';

  /// Mã ngẫu nhiên của lần cài đặt, ghi cùng mã PIN (iOS-02). Gắn với lần cài
  /// chứ không với dữ liệu: không xuất ra file sao lưu, khôi phục hay xóa toàn
  /// bộ dữ liệu vẫn giữ (xem `backup.dart`).
  static const pinInstallIdKey = 'pinInstallId';

  Stream<String?> _watch(String key) {
    final query = _db.select(_db.settings)..where((s) => s.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<String?> _read(String key) =>
      (_db.select(_db.settings)..where((s) => s.key.equals(key)))
          .getSingleOrNull()
          .then((row) => row?.value);

  Future<void> _write(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> _remove(String key) =>
      (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();

  /// Giao diện sáng, tối hoặc theo hệ thống (AC-35). Mặc định theo hệ thống.
  Stream<ThemeMode> watchThemeMode() =>
      _watch(themeModeKey)
          .map((v) => ThemeMode.values.asNameMap()[v] ?? ThemeMode.system);

  Future<void> setThemeMode(ThemeMode mode) => _write(themeModeKey, mode.name);

  /// Mã ngôn ngữ đã chọn; null là theo ngôn ngữ máy (AC-36).
  Stream<String?> watchLocaleCode() => _watch(localeKey);

  Future<void> setLocaleCode(String? code) =>
      code == null ? _remove(localeKey) : _write(localeKey, code);

  /// Mã tiền tệ ISO 4217 (AC-21). Lần đầu chưa có thì lấy theo vùng của máy
  /// [deviceLocale] và lưu lại, để đổi ngôn ngữ máy sau này không làm đổi tiền tệ.
  Future<String> ensureCurrency(String deviceLocale) async {
    final saved = await _read(currencyKey);
    if (saved != null) return saved;
    final code = currencyForLocale(deviceLocale);
    await _write(currencyKey, code);
    return code;
  }

  Stream<String> watchCurrency() => _watch(currencyKey).map((v) => v ?? 'VND');

  /// Ngày đầu tuần: DateTime.monday (mặc định) hoặc DateTime.sunday (AC-12).
  Stream<int> watchWeekStart() => _watch(
    weekStartKey,
  ).map((v) => v == '${DateTime.sunday}' ? DateTime.sunday : DateTime.monday);

  Future<void> setWeekStart(int weekday) => _write(weekStartKey, '$weekday');

  /// Ngày bắt đầu tháng, 1 tới 28 (AC-12).
  Stream<int> watchMonthStartDay() =>
      _watch(monthStartDayKey)
          .map((v) => (int.tryParse(v ?? '') ?? 1).clamp(1, 28));

  Future<void> setMonthStartDay(int day) =>
      _write(monthStartDayKey, '${day.clamp(1, 28)}');

  /// Che nội dung ở màn đa nhiệm và chặn chụp màn hình (AC-56). Mặc định tắt.
  Stream<bool> watchSecureWindow() =>
      _watch(secureWindowKey).map((v) => v == '1');

  Future<bool> readSecureWindow() =>
      _read(secureWindowKey).then((v) => v == '1');

  Future<void> setSecureWindow(bool on) =>
      on ? _write(secureWindowKey, '1') : _remove(secureWindowKey);

  /// Cho widget màn hình chính hiện số tiền đã chi tháng này (AC-64).
  /// Mặc định tắt; khi khóa PIN bật thì widget vẫn ẩn số.
  Stream<bool> watchWidgetShowAmounts() =>
      _watch(widgetShowAmountsKey).map((v) => v == '1');

  Future<void> setWidgetShowAmounts(bool on) =>
      on ? _write(widgetShowAmountsKey, '1') : _remove(widgetShowAmountsKey);

  /// Nhắc ghi chép hằng ngày bật hay tắt (AC-61). Mặc định tắt.
  Stream<bool> watchReminderEnabled() =>
      _watch(reminderEnabledKey).map((v) => v == '1');

  Future<bool> readReminderEnabled() =>
      _read(reminderEnabledKey).then((v) => v == '1');

  Future<void> setReminderEnabled(bool on) =>
      on ? _write(reminderEnabledKey, '1') : _remove(reminderEnabledKey);

  /// Giờ nhắc, lưu dạng `HH:mm`. Mặc định 20:00 (AC-61).
  Stream<TimeOfDay> watchReminderTime() =>
      _watch(reminderTimeKey).map(parseReminderTime);

  Future<TimeOfDay> readReminderTime() =>
      _read(reminderTimeKey).then(parseReminderTime);

  Future<void> setReminderTime(TimeOfDay time) => _write(
    reminderTimeKey,
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}',
  );

  /// Hạn mức chi mỗi tháng theo đơn vị nhỏ nhất; null là chưa đặt (AC-26).
  Stream<int?> watchBudget() =>
      _watch(budgetKey).map((v) => int.tryParse(v ?? ''));

  Future<int?> readBudget() =>
      _read(budgetKey).then((v) => int.tryParse(v ?? ''));

  Future<void> setBudget(int? amount) => amount == null || amount <= 0
      ? _remove(budgetKey)
      : _write(budgetKey, '$amount');

  /// Mã cài đặt đi kèm mã PIN; null là cơ sở dữ liệu chưa từng đặt PIN.
  Future<String?> readPinInstallId() => _read(pinInstallIdKey);

  Future<void> setPinInstallId(String id) => _write(pinInstallIdKey, id);
}

/// Giờ nhắc mặc định (AC-61).
const defaultReminderTime = TimeOfDay(hour: 20, minute: 0);

/// Đọc `HH:mm`; thiếu hoặc sai thì dùng [defaultReminderTime].
TimeOfDay parseReminderTime(String? value) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value ?? '');
  if (m == null) return defaultReminderTime;
  final h = int.parse(m[1]!);
  final min = int.parse(m[2]!);
  if (h > 23 || min > 59) return defaultReminderTime;
  return TimeOfDay(hour: h, minute: min);
}

/// Tiền tệ theo vùng trong mã ngôn ngữ máy, ví dụ `vi_VN` → VND.
/// Không có vùng thì: tiếng Việt → VND, còn lại → USD.
String currencyForLocale(String locale) {
  final parts = locale.split(RegExp('[-_]'));
  if (parts.length < 2) return parts.first == 'vi' ? 'VND' : 'USD';
  try {
    return NumberFormat.simpleCurrency(locale: locale).currencyName ?? 'USD';
  } catch (_) {
    return 'USD';
  }
}
