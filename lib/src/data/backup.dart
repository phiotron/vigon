import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'database.dart';
import 'seed.dart';
import 'settings_repository.dart';

const backupFormat = 'vigon-backup';
const backupVersion = 1;

/// File sao lưu sai định dạng, sai phiên bản hoặc hỏng (AC-29).
class BackupFormatException implements Exception {
  BackupFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// Mã băm SHA-256 của phần dữ liệu, để phát hiện file bị sửa hoặc hỏng.
String _checksum(Object tables) =>
    sha256.convert(utf8.encode(jsonEncode(tables))).toString();

/// Cài đặt "theo máy", không đi theo file sao lưu: công tắc hiện số tiền trên
/// widget (AC-64) và công tắc nhắc ghi chép (AC-61). Hai việc này phải do người
/// dùng bật trên chính máy này (có lời cảnh báo, có xin quyền), nên khi xuất
/// không ghi vào file và khi khôi phục không áp từ file (kể cả file cũ 1.0/1.1
/// còn chứa chúng); khôi phục xong cả hai về tắt. Giờ nhắc vẫn đi theo file.
const deviceOnlySettingKeys = {
  SettingsRepository.widgetShowAmountsKey,
  SettingsRepository.reminderEnabledKey,
};

/// Xuất toàn bộ khoản, danh mục, tài khoản, chuỗi định kỳ, cài đặt ra JSON (AC-28).
/// File không mã hóa; mã PIN không nằm trong file.
Future<String> exportBackup(AppDatabase db, {required DateTime now}) async {
  final tables = {
    'accounts': [
      for (final r in await db.select(db.accounts).get()) r.toJson(),
    ],
    'categories': [
      for (final r in await db.select(db.categories).get()) r.toJson(),
    ],
    'recurringRules': [
      for (final r in await db.select(db.recurringRules).get()) r.toJson(),
    ],
    'entries': [for (final r in await db.select(db.entries).get()) r.toJson()],
    'settings': [
      for (final r in await db.select(db.settings).get())
        if (!deviceOnlySettingKeys.contains(r.key)) r.toJson(),
    ],
  };
  return const JsonEncoder.withIndent(' ').convert({
    'format': backupFormat,
    'version': backupVersion,
    'schemaVersion': db.schemaVersion,
    'exportedAt': now.toIso8601String(),
    'checksum': _checksum(tables),
    'tables': tables,
  });
}

/// Thay toàn bộ dữ liệu bằng bản sao lưu (AC-29). Kiểm tra định dạng, phiên
/// bản, mã băm và đọc hết dữ liệu TRƯỚC khi xóa; ghi trong một giao dịch nên
/// có lỗi giữa chừng thì dữ liệu hiện có giữ nguyên.
typedef _Parsed = ({
  List<Account> accounts,
  List<Category> categories,
  List<RecurringRule> rules,
  List<Entry> entries,
  List<Setting> settings,
});

/// Đọc và kiểm hết file (định dạng, phiên bản, mã băm, từng dòng) mà KHÔNG đụng
/// cơ sở dữ liệu. Ném [BackupFormatException] nếu có gì sai.
_Parsed _parseBackup(String content) {
  final Map<String, dynamic> root;
  try {
    root = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    throw BackupFormatException('không phải JSON');
  }
  if (root['format'] != backupFormat) {
    throw BackupFormatException('sai định dạng');
  }
  final version = root['version'];
  if (version is! int || version > backupVersion) {
    throw BackupFormatException('phiên bản $version không hỗ trợ');
  }
  // File cũ (schema 1) không có cột budget của danh mục: vẫn đọc được. File từ
  // bản app mới hơn schema hiện tại thì từ chối.
  final schema = root['schemaVersion'];
  if (schema != null && (schema is! int || schema > currentSchemaVersion)) {
    throw BackupFormatException('schema $schema không hỗ trợ');
  }
  final tables = root['tables'];
  if (tables is! Map<String, dynamic> ||
      root['checksum'] != _checksum(tables)) {
    throw BackupFormatException('mã băm không khớp');
  }

  List<T> rows<T>(String name, T Function(Map<String, dynamic>) fromJson) {
    final list = tables[name];
    if (list is! List) throw BackupFormatException('thiếu bảng $name');
    try {
      return [for (final r in list) fromJson(r as Map<String, dynamic>)];
    } catch (e) {
      throw BackupFormatException('bảng $name hỏng: $e');
    }
  }

  final accounts = rows('accounts', Account.fromJson);
  final categories = rows('categories', Category.fromJson);
  final rules = rows('recurringRules', RecurringRule.fromJson);
  final entries = rows('entries', Entry.fromJson);
  // Bỏ cài đặt "theo máy" (file cũ có thể còn chứa): xem [deviceOnlySettingKeys].
  final settings = [
    for (final s in rows('settings', Setting.fromJson))
      if (!deviceOnlySettingKeys.contains(s.key)) s,
  ];
  if (accounts.isEmpty) throw BackupFormatException('không có tài khoản');
  if (accounts.every((a) => a.archived)) {
    throw BackupFormatException('không có tài khoản nào đang hiện');
  }
  return (
    accounts: accounts,
    categories: categories,
    rules: rules,
    entries: entries,
    settings: settings,
  );
}

/// Kiểm file sao lưu mà không ghi gì; dùng để báo file hỏng TRƯỚC khi hỏi xác nhận (AC-29).
void validateBackup(String content) => _parseBackup(content);

Future<void> importBackup(AppDatabase db, String content) async {
  final parsed = _parseBackup(content);
  try {
    await db.transaction(() async {
      await _clearAll(db);
      await db.batch((b) {
        b.insertAll(db.accounts, parsed.accounts);
        b.insertAll(db.categories, parsed.categories);
        b.insertAll(db.recurringRules, parsed.rules);
        b.insertAll(db.entries, parsed.entries);
        b.insertAll(db.settings, parsed.settings);
      });
    });
  } on BackupFormatException {
    rethrow;
  } catch (e) {
    // Ví dụ khóa ngoại sai, số tiền ≤ 0: giao dịch đã quay lui.
    throw BackupFormatException('dữ liệu không hợp lệ: $e');
  }
}

Future<void> _clearAll(AppDatabase db) async {
  await db.delete(db.entries).go();
  await db.delete(db.recurringRules).go();
  await db.delete(db.categories).go();
  await db.delete(db.accounts).go();
  await db.delete(db.settings).go();
}

/// Xóa toàn bộ dữ liệu rồi tạo lại danh mục, tài khoản mặc định như lúc mới cài (AC-42).
Future<void> deleteAllData(AppDatabase db) => db.transaction(() async {
  await _clearAll(db);
  await db.customStatement('DELETE FROM sqlite_sequence');
  await seedDefaults(db);
});

/// Cách ghi file CSV theo ngôn ngữ (AC-52). Tầng dữ liệu không biết
/// `BuildContext`: chuỗi nằm trong `.arb`, nơi gọi truyền vào.
class CsvFormat {
  const CsvFormat({
    required this.delimiter,
    required this.decimalSeparator,
    required this.header,
    required this.expense,
    required this.income,
    required this.transfer,
  });

  /// Chọn dấu ngăn theo ngôn ngữ: tiếng Việt `;` và `,` (Excel vùng Việt đọc
  /// đúng); ngôn ngữ khác `,` và `.`.
  factory CsvFormat.forLanguage(
    String languageCode, {
    required List<String> header,
    required String expense,
    required String income,
    required String transfer,
  }) => CsvFormat(
    delimiter: languageCode == 'vi' ? ';' : ',',
    decimalSeparator: languageCode == 'vi' ? ',' : '.',
    header: header,
    expense: expense,
    income: income,
    transfer: transfer,
  );

  static const english = CsvFormat(
    delimiter: ',',
    decimalSeparator: '.',
    header: [
      'date',
      'type',
      'amount',
      'currency',
      'category',
      'account',
      'to_account',
      'note',
    ],
    expense: 'expense',
    income: 'income',
    transfer: 'transfer',
  );

  final String delimiter;
  final String decimalSeparator;

  /// Tám tiêu đề cột: ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, đến tài khoản, ghi chú.
  final List<String> header;
  final String expense;
  final String income;
  final String transfer;

  String typeName(EntryType type) => switch (type) {
    EntryType.expense => expense,
    EntryType.income => income,
    EntryType.transfer => transfer,
  };
}

/// Xuất CSV: ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, ghi chú (AC-30, AC-52).
/// UTF-8 có BOM để Excel đọc đúng chữ tiếng Việt.
String exportCsv({
  required List<Entry> entries,
  required String currency,
  required int decimalDigits,
  required String Function(int? categoryId) categoryName,
  required String Function(int accountId) accountName,
  CsvFormat format = CsvFormat.english,
}) {
  String cell(String v) {
    // Chặn Excel coi ghi chú như "=..." là công thức.
    if (v.startsWith(RegExp(r'[=+\-@\t\r]'))) v = "'$v";
    // Ngoặc kép khi chứa dấu ngăn cột (cả `,` lẫn `;` cho chắc), ngoặc kép, xuống dòng.
    return RegExp(r'[",;\r\n]').hasMatch(v)
        ? '"${v.replaceAll('"', '""')}"'
        : v;
  }

  // Tính bằng số nguyên, không qua số thực: không sai số làm tròn.
  String amount(int minor) {
    if (decimalDigits == 0) return '$minor';
    final unit = BigInt.from(10).pow(decimalDigits).toInt();
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final frac = (abs % unit).toString().padLeft(decimalDigits, '0');
    return '$sign${abs ~/ unit}${format.decimalSeparator}$frac';
  }

  final sorted = [...entries]
    ..sort(
      (a, b) => a.date.compareTo(b.date) != 0
          ? a.date.compareTo(b.date)
          : a.id.compareTo(b.id),
    );
  final lines = [
    format.header.map(cell).join(format.delimiter),
    for (final e in sorted)
      [
        e.date,
        cell(format.typeName(e.type)),
        amount(e.amount),
        currency,
        cell(e.type == EntryType.transfer ? '' : categoryName(e.categoryId)),
        cell(accountName(e.accountId)),
        cell(e.toAccountId == null ? '' : accountName(e.toAccountId!)),
        cell(e.note ?? ''),
      ].join(format.delimiter),
  ];
  return '﻿${lines.join('\r\n')}\r\n';
}
