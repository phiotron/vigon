import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/backup_crypto.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/settings_repository.dart';

import '../helpers.dart';

/// Khôi phục không được mang theo công tắc "theo máy" (AC-61, AC-63, AC-64):
/// hiện số tiền trên widget và nhắc ghi chép chỉ do người dùng bật trên máy này.

/// Thay bảng settings của file rồi tính lại mã băm: một file "hợp lệ" như bản
/// 1.0/1.1 đã xuất kèm hai công tắc.
String withSettings(String json, Map<String, String> settings) {
  final root = jsonDecode(json) as Map<String, dynamic>;
  final tables = root['tables'] as Map<String, dynamic>;
  tables['settings'] = [
    for (final e in settings.entries) {'key': e.key, 'value': e.value},
  ];
  root['checksum'] = sha256.convert(utf8.encode(jsonEncode(tables))).toString();
  return jsonEncode(root);
}

Future<Map<String, String>> settingsOf(AppDatabase db) async => {
  for (final s in await db.select(db.settings).get()) s.key: s.value,
};

const _hostile = {
  SettingsRepository.widgetShowAmountsKey: '1',
  SettingsRepository.reminderEnabledKey: '1',
  SettingsRepository.reminderTimeKey: '07:30',
  SettingsRepository.budgetKey: '5000000',
};

void main() {
  final now = DateTime(2026, 11, 3, 10, 30);

  test('xuat sao luu khong ghi hai cong tac theo may, van ghi cai dat khac '
      '(AC-61, AC-64)', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final s = SettingsRepository(db);
    await s.setWidgetShowAmounts(true);
    await s.setReminderEnabled(true);
    await s.setReminderTime(const TimeOfDay(hour: 6, minute: 5));
    await s.setBudget(1000);
    final json = await exportBackup(db, now: now);
    final tables = (jsonDecode(json) as Map)['tables'] as Map;
    final keys = [for (final r in tables['settings'] as List) r['key']];
    expect(keys, isNot(contains(SettingsRepository.widgetShowAmountsKey)));
    expect(keys, isNot(contains(SettingsRepository.reminderEnabledKey)));
    expect(
      keys,
      containsAll([
        SettingsRepository.reminderTimeKey,
        SettingsRepository.budgetKey,
      ]),
    );
    validateBackup(json); // mã băm khớp với bảng đã lọc
  });

  test('khoi phuc file cu chua hai cong tac bat: khong ap, ca hai ve tat; '
      'gio nhac va cai dat khac van theo file', () async {
    final src = memoryDatabase();
    addTearDown(src.close);
    await SettingsRepository(src).ensureCurrency('vi_VN');
    final file = withSettings(await exportBackup(src, now: now), _hostile);

    final db = memoryDatabase();
    addTearDown(db.close);
    // Máy này đang có sẵn công tắc bật: khôi phục thay hết dữ liệu nên về tắt.
    await SettingsRepository(db).setWidgetShowAmounts(true);
    await SettingsRepository(db).setReminderEnabled(true);
    validateBackup(file); // file cũ vẫn hợp lệ
    await importBackup(db, file);
    final after = await settingsOf(db);
    expect(after.containsKey(SettingsRepository.widgetShowAmountsKey), isFalse);
    expect(after.containsKey(SettingsRepository.reminderEnabledKey), isFalse);
    expect(after[SettingsRepository.reminderTimeKey], '07:30');
    expect(after[SettingsRepository.budgetKey], '5000000');
    final repo = SettingsRepository(db);
    expect(await repo.readReminderEnabled(), isFalse);
    expect(await repo.watchWidgetShowAmounts().first, isFalse);
  });

  test(
    'duong khoi phuc ma hoa: giai ma roi nhap, hai cong tac van ve tat',
    () async {
      final src = memoryDatabase();
      addTearDown(src.close);
      final plain = withSettings(await exportBackup(src, now: now), _hostile);
      final envelope = await encryptBackup(
        plain,
        'mat-khau-1',
        iterations: 1000,
      );
      final opened = await decryptBackup(envelope, 'mat-khau-1');
      final db = memoryDatabase();
      addTearDown(db.close);
      validateBackup(opened);
      await importBackup(db, opened);
      final after = await settingsOf(db);
      expect(
        after.containsKey(SettingsRepository.widgetShowAmountsKey),
        isFalse,
      );
      expect(after.containsKey(SettingsRepository.reminderEnabledKey), isFalse);
    },
  );
}
