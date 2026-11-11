import '../../data/database.dart';
import 'budget_status.dart';

/// Cài đặt của Cảnh báo ngân sách (F-37) trong bảng `settings` (D-005), không
/// đổi schema. Đọc/ghi thẳng bảng khoá–giá trị để không chạm
/// `SettingsRepository` của các tính năng khác.
class BudgetAlertSettings {
  BudgetAlertSettings(this._db);

  final AppDatabase _db;

  /// Ngưỡng "Sắp vượt" (50–95, bước 5; mặc định 80). Đi theo file sao lưu như
  /// giờ nhắc.
  static const thresholdKey = 'budgetAlertThreshold';

  /// Công tắc "Thông báo ngân sách" (mặc định tắt). Theo máy: quyền thông báo
  /// là của máy (`backup.dart` → `deviceOnlySettingKeys`).
  static const enabledKey = 'budgetAlertEnabled';

  /// Mốc đã báo của tháng đang theo dõi (JSON, xem `BudgetAlertState`). Theo
  /// máy: là lịch sử thông báo của máy này.
  static const stateKey = 'budgetAlertState';

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

  Stream<int> watchThreshold() => _watch(
    thresholdKey,
  ).map((v) => normalizeBudgetWarnPercent(v == null ? null : int.tryParse(v)));

  Future<int> readThreshold() => _read(
    thresholdKey,
  ).then((v) => normalizeBudgetWarnPercent(v == null ? null : int.tryParse(v)));

  Future<void> setThreshold(int percent) =>
      _write(thresholdKey, '${normalizeBudgetWarnPercent(percent)}');

  Stream<bool> watchEnabled() => _watch(enabledKey).map((v) => v == '1');

  Future<bool> readEnabled() => _read(enabledKey).then((v) => v == '1');

  Future<void> setEnabled(bool on) =>
      on ? _write(enabledKey, '1') : _remove(enabledKey);

  Future<String?> readState() => _read(stateKey);

  Future<void> writeState(String? json) =>
      json == null ? _remove(stateKey) : _write(stateKey, json);
}
