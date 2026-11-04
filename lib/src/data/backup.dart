import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'database.dart';
import 'seed.dart';

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
      for (final r in await db.select(db.settings).get()) r.toJson(),
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
  final settings = rows('settings', Setting.fromJson);
  if (accounts.isEmpty) throw BackupFormatException('không có tài khoản');
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

/// Xuất CSV: ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, ghi chú (AC-30).
/// UTF-8 có BOM để Excel đọc đúng chữ tiếng Việt.
String exportCsv({
  required List<Entry> entries,
  required String currency,
  required int decimalDigits,
  required String Function(int? categoryId) categoryName,
  required String Function(int accountId) accountName,
}) {
  String cell(String v) {
    // Chặn Excel coi ghi chú như "=..." là công thức.
    if (v.startsWith(RegExp(r'[=+\-@]'))) v = "'$v";
    return RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  }

  String amount(int minor) => decimalDigits == 0
      ? '$minor'
      : (minor / BigInt.from(10).pow(decimalDigits).toInt()).toStringAsFixed(
          decimalDigits,
        );
  final sorted = [...entries]
    ..sort(
      (a, b) => a.date.compareTo(b.date) != 0
          ? a.date.compareTo(b.date)
          : a.id.compareTo(b.id),
    );
  final lines = [
    'date,type,amount,currency,category,account,to_account,note',
    for (final e in sorted)
      [
        e.date,
        e.type.name,
        amount(e.amount),
        currency,
        cell(e.type == EntryType.transfer ? '' : categoryName(e.categoryId)),
        cell(accountName(e.accountId)),
        cell(e.toAccountId == null ? '' : accountName(e.toAccountId!)),
        cell(e.note ?? ''),
      ].join(','),
  ];
  return '﻿${lines.join('\r\n')}\r\n';
}
