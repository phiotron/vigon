import 'dart:convert';

import 'package:flutter/material.dart';

import 'database.dart';
import 'exchange_rate.dart';

/// Đọc, ghi cài đặt trong bảng khóa-giá trị (D-005).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const themeModeKey = 'themeMode';
  static const localeKey = 'locale';

  /// Tiền tệ cũ của bản một-tiền-tệ; giữ để đọc dữ liệu trước schema 5.
  static const currencyKey = 'currency';

  /// Tiền tệ chính (D-037): chỉ dùng để cộng/hiển thị, không ghi đè số gốc.
  static const primaryCurrencyKey = 'primaryCurrency';
  static const weekStartKey = 'weekStart';
  static const monthStartDayKey = 'monthStartDay';
  static const budgetKey = 'monthlyBudget';

  /// Ngân sách tháng chính xác, phần triệu đơn vị chính (D-029); thiếu là
  /// đúng bằng [budgetKey].
  static const budgetMicroKey = 'budgetMicro';

  /// Ngân sách tháng gốc + tiền tệ (D-037); thiếu là ngân sách cũ đang ở
  /// Tiền tệ chính.
  static const budgetOriginalKey = 'budgetOriginal';
  static const budgetCurrencyKey = 'budgetCurrency';

  /// Tài khoản tự tạo từ email MB còn thẻ "Gắn vào tài khoản có sẵn" (AC-89):
  /// danh sách id cách nhau dấu phẩy. Theo máy, không vào file sao lưu.
  static const mbAutoAccountNoticesKey = 'mbAutoAccountNotices';
  static const secureWindowKey = 'secureWindow';
  static const widgetShowAmountsKey = 'widgetShowAmounts';
  static const reminderEnabledKey = 'reminderEnabled';
  static const reminderTimeKey = 'reminderTime';

  /// Bảng tỉ giá tải được gần nhất (D-025), để mất mạng vẫn điền sẵn tỉ giá.
  static const exchangeRatesKey = 'exchangeRates';

  /// Tỉ giá người dùng tự nhập lần gần nhất: `{from, to, rate, date}`.
  static const exchangeRateManualKey = 'exchangeRateManual';

  /// Ghi đè tỉ giá theo cặp (D-037): `{"USD>VND": "26000", ...}`.
  static const exchangeRateOverridesKey = 'exchangeRateOverrides';

  /// Ngày bảng tỉ giá đã áp dụng lần cuối, để quy đổi lại số dẫn xuất khi bảng
  /// đổi mà không lặp mỗi lần mở app.
  static const ratesAppliedDateKey = 'ratesAppliedDate';

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

  /// Mã ngôn ngữ đã chọn; null là chưa chọn = English (D-036, AC-36).
  Stream<String?> watchLocaleCode() => _watch(localeKey);

  Future<void> setLocaleCode(String? code) =>
      code == null ? _remove(localeKey) : _write(localeKey, code);

  /// Mã Tiền tệ chính ISO 4217 (AC-21, D-037). Lần đầu chưa có thì lưu
  /// [defaultCode] (mặc định USD, D-036: không đoán theo vùng/ngôn ngữ máy).
  Future<String> ensureCurrency({String defaultCode = 'USD'}) async {
    final saved = await _read(primaryCurrencyKey) ?? await _read(currencyKey);
    final code = saved ?? defaultCode;
    await _write(currencyKey, code);
    await _write(primaryCurrencyKey, code);
    return code;
  }

  /// Tiền tệ chính; đọc khóa cũ khi dữ liệu chưa qua migration (D-037).
  Stream<String> watchCurrency() =>
      _watch(primaryCurrencyKey).map((v) => v ?? 'USD');

  Future<String> readPrimaryCurrency() async =>
      await _read(primaryCurrencyKey) ?? await _read(currencyKey) ?? 'USD';

  /// Giữ tên cũ cho các luồng chưa chuyển sang "Tiền tệ chính".
  Future<String> readCurrency() => readPrimaryCurrency();

  /// Ghi Tiền tệ chính. Không quy đổi số tiền (D-037): số gốc giữ nguyên,
  /// `CurrencyService` quy đổi lại các cột dẫn xuất.
  Future<void> setPrimaryCurrency(String code) async {
    await _write(primaryCurrencyKey, code);
  }

  /// Giữ cho dữ liệu/tests cũ; tương đương [setPrimaryCurrency].
  Future<void> setCurrency(String code) async {
    await _write(currencyKey, code);
    await _write(primaryCurrencyKey, code);
  }

  /// Ghi đè tỉ giá "1 [from] = rate [to]" (D-037); lưu cả hai chiều đọc được.
  Future<void> setRateOverride(
    String from,
    String to,
    ExchangeRate rate,
  ) async {
    final all = await readRateOverrides();
    all['$from>$to'] = rate;
    all.remove('$to>$from');
    await _write(
      exchangeRateOverridesKey,
      jsonEncode({for (final e in all.entries) e.key: e.value.toStorage()}),
    );
  }

  /// Bỏ ghi đè của cặp [from]–[to] (cả hai chiều).
  Future<void> clearRateOverride(String from, String to) async {
    final all = await readRateOverrides()
      ..remove('$from>$to')
      ..remove('$to>$from');
    if (all.isEmpty) {
      await _remove(exchangeRateOverridesKey);
    } else {
      await _write(
        exchangeRateOverridesKey,
        jsonEncode({for (final e in all.entries) e.key: e.value.toStorage()}),
      );
    }
  }

  Future<Map<String, ExchangeRate>> readRateOverrides() async {
    final text = await _read(exchangeRateOverridesKey);
    if (text == null) return {};
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          e.key: ?ExchangeRate.fromStorage(e.value as String),
      };
    } catch (_) {
      return {};
    }
  }

  Future<String?> readRatesAppliedDate() => _read(ratesAppliedDateKey);

  Future<void> setRatesAppliedDate(String date) =>
      _write(ratesAppliedDateKey, date);

  /// Bảng tỉ giá đã lưu; null nếu chưa có hoặc hỏng.
  Future<RateTable?> readRateTable() =>
      _read(exchangeRatesKey).then(RateTable.tryFromJson);

  Future<void> setRateTable(RateTable table) =>
      _write(exchangeRatesKey, table.toJson());

  /// Tỉ giá tự nhập gần nhất cho cặp [from]–[to] (cả chiều ngược): trả về
  /// tỉ giá "1 [from] = ? [to]" và ngày nhập; null nếu chưa có.
  Future<({ExchangeRate rate, String date})?> readManualRate(
    String from,
    String to,
  ) async {
    final text = await _read(exchangeRateManualKey);
    if (text == null) return null;
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      final rate = ExchangeRate.fromStorage(m['rate'] as String);
      final date = m['date'] as String;
      if (rate == null) return null;
      if (m['from'] == from && m['to'] == to) return (rate: rate, date: date);
      if (m['from'] == to && m['to'] == from) {
        return (rate: rate.inverse, date: date);
      }
    } catch (_) {}
    return null;
  }

  Future<void> setManualRate(
    String from,
    String to,
    ExchangeRate rate,
    String date,
  ) => _write(
    exchangeRateManualKey,
    jsonEncode({
      'from': from,
      'to': to,
      'rate': rate.toStorage(),
      'date': date,
    }),
  );

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

  /// Nhắc ghi sổ hằng ngày bật hay tắt (AC-61). Mặc định tắt.
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

  /// Ngân sách tháng chính xác (D-029); null là đúng bằng [readBudget].
  Future<int?> readBudgetMicro() =>
      _read(budgetMicroKey).then((v) => int.tryParse(v ?? ''));

  Future<void> setBudgetMicro(int? micro) => micro == null
      ? _remove(budgetMicroKey)
      : _write(budgetMicroKey, '$micro');

  /// Ngân sách tháng gốc + tiền tệ (D-037); null là ngân sách đang ở Tiền tệ
  /// chính.
  Future<int?> readBudgetOriginal() =>
      _read(budgetOriginalKey).then((v) => int.tryParse(v ?? ''));

  Future<void> setBudgetOriginal(int? amount) => amount == null
      ? _remove(budgetOriginalKey)
      : _write(budgetOriginalKey, '$amount');

  Stream<String?> watchBudgetCurrency() => _watch(budgetCurrencyKey);

  Future<String?> readBudgetCurrency() => _read(budgetCurrencyKey);

  Future<void> setBudgetCurrency(String? code) => code == null
      ? _remove(budgetCurrencyKey)
      : _write(budgetCurrencyKey, code);

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
