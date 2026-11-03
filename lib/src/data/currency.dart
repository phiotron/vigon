import 'dart:math';

import 'database.dart';
import 'money.dart';
import 'settings_repository.dart';

/// Tiền tệ chọn được trong Cài đặt (mã ISO 4217, AC-21).
const supportedCurrencies = [
  'VND', 'USD', 'EUR', 'GBP', 'JPY', 'KRW', 'CNY', 'TWD', 'HKD', 'SGD', //
  'THB', 'MYR', 'IDR', 'PHP', 'INR', 'AUD', 'NZD', 'CAD', 'CHF', 'SEK', //
  'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'TRY', 'BRL', 'MXN', 'ZAR', 'AED', //
  'SAR',
];

/// Đổi tiền tệ của app. Không quy đổi tỉ giá: số hiển thị giữ nguyên, chỉ đổi
/// ký hiệu (AC-21). Khi số chữ số thập phân khác nhau (VND 0, USD 2) thì nhân
/// hoặc chia số đã lưu để giữ đúng con số người dùng nhìn thấy (D-005).
Future<void> changeCurrency(AppDatabase db, String newCode) =>
    db.transaction(() async {
      final settings = SettingsRepository(db);
      final oldCode = await settings.watchCurrency().first;
      final shift =
          currencyDecimalDigits(newCode) - currencyDecimalDigits(oldCode);
      if (shift != 0) {
        final factor = pow(10, shift.abs()).toInt();
        // Chia thì làm tròn, và giữ tối thiểu 1 để không vi phạm ràng buộc số tiền > 0.
        final scaledPositive = shift > 0
            ? 'amount * $factor'
            : 'MAX(1, CAST(ROUND(amount * 1.0 / $factor) AS INTEGER))';
        final scaledAny = shift > 0
            ? 'initial_balance * $factor'
            : 'CAST(ROUND(initial_balance * 1.0 / $factor) AS INTEGER)';
        await db.customUpdate(
          'UPDATE entries SET amount = $scaledPositive',
          updates: {db.entries},
        );
        await db.customUpdate(
          'UPDATE recurring_rules SET amount = $scaledPositive',
          updates: {db.recurringRules},
        );
        await db.customUpdate(
          'UPDATE accounts SET initial_balance = $scaledAny',
          updates: {db.accounts},
        );
        final budget = await settings.readBudget();
        if (budget != null) {
          await settings.setBudget(
            shift > 0 ? budget * factor : max(1, (budget / factor).round()),
          );
        }
      }
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(
              key: SettingsRepository.currencyKey,
              value: newCode,
            ),
          );
    });
