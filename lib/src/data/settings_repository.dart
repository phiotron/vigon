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

  /// Hạn mức chi mỗi tháng theo đơn vị nhỏ nhất; null là chưa đặt (AC-26).
  Stream<int?> watchBudget() =>
      _watch(budgetKey).map((v) => int.tryParse(v ?? ''));

  Future<int?> readBudget() =>
      _read(budgetKey).then((v) => int.tryParse(v ?? ''));

  Future<void> setBudget(int? amount) => amount == null || amount <= 0
      ? _remove(budgetKey)
      : _write(budgetKey, '$amount');
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
