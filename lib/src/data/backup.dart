import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'balance_guard.dart' show negativeNoticeKey;
import 'database.dart';
import 'import_repositories.dart' show entrySourceForBank;
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
/// widget (AC-64) và công tắc nhắc ghi sổ (AC-61). Hai việc này phải do người
/// dùng bật trên chính máy này (có lời cảnh báo, có xin quyền), nên khi xuất
/// không ghi vào file và khi khôi phục không áp từ file (kể cả file cũ 1.0/1.1
/// còn chứa chúng); khôi phục xong cả hai về tắt. Giờ nhắc vẫn đi theo file.
const deviceOnlySettingKeys = {
  SettingsRepository.widgetShowAmountsKey,
  SettingsRepository.reminderEnabledKey,
  SettingsRepository.mbAutoAccountNoticesKey,
  SettingsRepository.onboardingPendingKey,
  SettingsRepository.deadlineReminderOffKey,
  SettingsRepository.deadlinePermissionAskedKey,
  negativeCheckPendingKey,
  negativeNoticeKey,
};

/// Mã cài đặt đi kèm PIN (iOS-02) gắn với máy, không phải dữ liệu: không xuất,
/// không nhận từ file, và khôi phục hay xóa toàn bộ dữ liệu vẫn giữ.
const _installIdKey = SettingsRepository.pinInstallIdKey;

/// Xuất toàn bộ khoản, danh mục, tài khoản, chuỗi định kỳ, cài đặt ra JSON (AC-28).
/// Mỗi dòng mang cả số tiền chính xác (cột `*Micro`, khóa `budgetMicro`, D-029).
/// File không mã hóa; mã PIN và mã cài đặt không nằm trong file.
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
        if (!deviceOnlySettingKeys.contains(r.key) && r.key != _installIdKey)
          r.toJson(),
    ],
    // Schema 4 (AC-121). Hàng đợi KHÔNG vào file (AC-99); hộp thư không nằm
    // trong cơ sở dữ liệu (AC-79).
    'savingsGoals': [
      for (final r in await db.select(db.savingsGoals).get()) r.toJson(),
    ],
    'debts': [for (final r in await db.select(db.debts).get()) r.toJson()],
    'debtPayments': [
      for (final r in await db.select(db.debtPayments).get()) r.toJson(),
    ],
    'payeeSuggestions': [
      for (final r in await db.select(db.payeeSuggestions).get()) r.toJson(),
    ],
    'seenReferences': [
      for (final r in await db.select(db.seenReferences).get()) r.toJson(),
    ],
    // Schema 8 (AC-176): mốc đổi lãi suất của khoản nợ.
    'debtRateChanges': [
      for (final r in await db.select(db.debtRateChanges).get()) r.toJson(),
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
  List<SavingsGoal> goals,
  List<Debt> debts,
  List<DebtPayment> debtPayments,
  List<PayeeSuggestion> suggestions,
  List<SeenReference> seenReferences,
  List<DebtRateChange> rateChanges,
  int fileSchema,
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
  // File cũ vẫn đọc được: schema 1 không có cột budget của danh mục, schema 1/2
  // không có cột số tiền chính xác `*Micro` và khóa `budgetMicro` (D-029) —
  // thiếu thì null, tức số chính xác bằng đúng số đã làm tròn; schema 1–3 không
  // có bảng/cột của bản 2.0 (AC-77, AC-121) — xem [rows] dưới. File từ bản app
  // mới hơn schema hiện tại thì từ chối.
  final schema = root['schemaVersion'];
  if (schema != null && (schema is! int || schema > currentSchemaVersion)) {
    throw BackupFormatException('schema $schema không hỗ trợ');
  }
  final tables = root['tables'];
  if (tables is! Map<String, dynamic> ||
      root['checksum'] != _checksum(tables)) {
    throw BackupFormatException('mã băm không khớp');
  }

  // File không ghi schemaVersion là bản đầu (schema 1).
  final fileSchema = schema is int ? schema : 1;

  /// Bảng [name]; [since] là schema đầu tiên có bảng đó — file cũ hơn không có
  /// thì coi là rỗng, file từ schema đó trở đi thiếu bảng là hỏng.
  List<T> rows<T>(
    String name,
    T Function(Map<String, dynamic>) fromJson, {
    int since = 1,
    Map<String, dynamic> defaults = const {},
  }) {
    final list = tables[name];
    if (list == null && fileSchema < since) return const [];
    if (list is! List) throw BackupFormatException('thiếu bảng $name');
    try {
      return [
        for (final r in list)
          fromJson({...defaults, ...r as Map<String, dynamic>}),
      ];
    } catch (e) {
      throw BackupFormatException('bảng $name hỏng: $e');
    }
  }

  // File schema ≤ 7: tài khoản chưa có công tắc cho phép âm — tính như nâng
  // cấp sau khi khôi phục (AC-163); lần trả chưa có phần lãi.
  final accounts = rows(
    'accounts',
    Account.fromJson,
    defaults: {'allowNegative': false},
  );
  final categories = rows('categories', Category.fromJson);
  final rules = rows('recurringRules', RecurringRule.fromJson);
  // File schema 1–3: khoản là ghi tay, không giờ, không số tham chiếu (AC-77).
  final entries = rows(
    'entries',
    Entry.fromJson,
    defaults: {'source': EntrySource.manual.name},
  );
  final goals = rows('savingsGoals', SavingsGoal.fromJson, since: 4);
  final debts = rows('debts', Debt.fromJson, since: 4);
  final debtPayments = rows(
    'debtPayments',
    DebtPayment.fromJson,
    since: 4,
    defaults: {'interest': 0},
  );
  final rateChanges = rows(
    'debtRateChanges',
    DebtRateChange.fromJson,
    since: 8,
  );
  final suggestions = rows(
    'payeeSuggestions',
    PayeeSuggestion.fromJson,
    since: 4,
  );
  final seenReferences = rows(
    'seenReferences',
    SeenReference.fromJson,
    since: 4,
  );
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
    goals: goals,
    debts: debts,
    debtPayments: debtPayments,
    suggestions: suggestions,
    seenReferences: seenReferences,
    rateChanges: rateChanges,
    fileSchema: fileSchema,
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
        b.insertAll(db.settings, [
          for (final s in parsed.settings)
            if (s.key != _installIdKey) s,
        ]);
        b.insertAll(db.savingsGoals, parsed.goals);
        b.insertAll(db.debts, parsed.debts);
        b.insertAll(db.debtPayments, parsed.debtPayments);
        // Sau khoản nợ + lần trả: khoản trỏ tới chúng (schema 8, khoá ngoại).
        b.insertAll(db.entries, parsed.entries);
        b.insertAll(db.payeeSuggestions, parsed.suggestions);
        b.insertAll(db.seenReferences, parsed.seenReferences);
        b.insertAll(db.debtRateChanges, parsed.rateChanges);
      });
      if (parsed.fileSchema < 8) {
        // Như nâng cấp lên schema 8: thêm danh mục lãi, bật cho phép âm cho
        // tài khoản đang âm ở lần mở kế tiếp (AC-163, AC-173).
        await addInterestCategories(db);
        await db
            .into(db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion.insert(
                key: negativeCheckPendingKey,
                value: '1',
              ),
            );
      }
      await _reconcileQueue(db);
    });
  } on BackupFormatException {
    rethrow;
  } catch (e) {
    // Ví dụ khóa ngoại sai, số tiền âm: giao dịch đã quay lui.
    throw BackupFormatException('dữ liệu không hợp lệ: $e');
  }
}

/// Sau khôi phục, hàng đợi hiện có được giữ (AC-99) nhưng: mục có số tham
/// chiếu đã nằm trong khoản hoặc trong "số tham chiếu đã gặp" của file thì bỏ;
/// mục còn lại gắn lại tài khoản theo liên kết (ngân hàng, 4 số cuối) của dữ
/// liệu vừa khôi phục — không có thì để null cho bên nhập tạo lại (AC-90).
/// (Xoá tài khoản cũ đã làm `accountId` của mục thành null, khoá ngoại SET NULL.)
Future<void> _reconcileQueue(AppDatabase db) async {
  final sourceOfBank = [
    'CASE import_queue_items.bank',
    for (final b in Bank.values)
      "WHEN '${b.name}' THEN '${entrySourceForBank(b).name}'",
    'END',
  ].join(' ');
  await db.customStatement('''
    DELETE FROM import_queue_items WHERE EXISTS (
      SELECT 1 FROM seen_references s
      WHERE s.bank = import_queue_items.bank
        AND s.reference_number = import_queue_items.reference_number)
    OR EXISTS (
      SELECT 1 FROM entries e
      WHERE e.source = $sourceOfBank
        AND e.reference_number = import_queue_items.reference_number)''');
  await db.customStatement('''
    UPDATE import_queue_items SET account_id = (
      SELECT a.id FROM accounts a
      WHERE a.bank = import_queue_items.bank
        AND a.bank_last4 = import_queue_items.debit_last4)''');
}

Future<void> _clearAll(AppDatabase db) async {
  // Bảng con trước bảng cha (khoá ngoại). Hàng đợi KHÔNG xoá ở đây (AC-99).
  await db.delete(db.seenReferences).go();
  await db.delete(db.payeeSuggestions).go();
  await db.delete(db.debtRateChanges).go();
  await db.delete(db.debtPayments).go();
  await db.delete(db.debts).go();
  await db.delete(db.savingsGoals).go();
  await db.delete(db.entries).go();
  await db.delete(db.recurringRules).go();
  await db.delete(db.categories).go();
  await db.delete(db.accounts).go();
  await (db.delete(
    db.settings,
  )..where((s) => s.key.isNotValue(_installIdKey))).go();
}

/// Việc dọn NGOÀI cơ sở dữ liệu khi "Xóa toàn bộ dữ liệu" (AC-123), ví dụ xoá
/// hộp thư + mật khẩu ứng dụng khỏi Keystore/Keychain, tắt kiểm thư nền, tắt
/// sinh trắc. Chạy sau khi phần cơ sở dữ liệu đã xoá xong.
typedef DeleteAllDataHook = Future<void> Function();

/// Xóa toàn bộ dữ liệu rồi tạo lại danh mục, tài khoản mặc định như lúc mới cài
/// (AC-42). Bản 2.0 xoá thêm mục tiêu, khoản nợ + lần trả, gợi ý, hàng đợi, số
/// tham chiếu đã gặp (AC-123) trong cùng giao dịch. Sau đó chạy lần lượt mọi
/// [hooks] (kể cả khi một hook lỗi, rồi ném lại lỗi đầu tiên) — phần ngoài cơ
/// sở dữ liệu do nơi gọi truyền vào (tầng dữ liệu không biết Keystore hay lịch
/// chạy nền).
Future<void> deleteAllData(
  AppDatabase db, {
  Iterable<DeleteAllDataHook> hooks = const [],
}) async {
  await db.transaction(() async {
    await db.delete(db.importQueueItems).go();
    await _clearAll(db);
    await db.customStatement('DELETE FROM sqlite_sequence');
    await seedDefaults(db);
  });
  Object? firstError;
  StackTrace? firstStack;
  for (final hook in hooks) {
    try {
      await hook();
    } catch (e, s) {
      firstError ??= e;
      firstStack ??= s;
    }
  }
  if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
}

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
    this.debt = 'debt',
    this.timeHeader = 'time',
    this.sourceHeader = 'source',
    this.manualSource = 'manual',
    this.emailMbSource = 'email_mb',
  });

  /// Chọn dấu ngăn theo ngôn ngữ: tiếng Việt `;` và `,` (Excel vùng Việt đọc
  /// đúng); ngôn ngữ khác `,` và `.`.
  factory CsvFormat.forLanguage(
    String languageCode, {
    required List<String> header,
    required String expense,
    required String income,
    required String transfer,
    String debt = 'debt',
    String timeHeader = 'time',
    String sourceHeader = 'source',
    String manualSource = 'manual',
    String emailMbSource = 'email_mb',
  }) => CsvFormat(
    delimiter: languageCode == 'vi' ? ';' : ',',
    decimalSeparator: languageCode == 'vi' ? ',' : '.',
    header: header,
    expense: expense,
    income: income,
    transfer: transfer,
    debt: debt,
    timeHeader: timeHeader,
    sourceHeader: sourceHeader,
    manualSource: manualSource,
    emailMbSource: emailMbSource,
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

  /// Chữ của loại Debt movement (D-049): "Khoản nợ" / "Debt".
  final String debt;

  /// Hai cột thêm ở CUỐI (AC-124) để giữ thứ tự tám cột cũ: Giờ và Nguồn.
  final String timeHeader;
  final String sourceHeader;

  /// Chữ của cột Nguồn: "Ghi tay" / "Email MB".
  final String manualSource;
  final String emailMbSource;

  String sourceName(EntrySource source) => switch (source) {
    EntrySource.manual => manualSource,
    EntrySource.emailMb => emailMbSource,
  };

  String typeName(EntryType type) => switch (type) {
    EntryType.expense => expense,
    EntryType.income => income,
    EntryType.transfer => transfer,
    EntryType.debt => debt,
  };
}

/// Xuất CSV: ngày, loại, số tiền, tiền tệ, danh mục, tài khoản, đến tài khoản,
/// ghi chú (AC-30, AC-52), rồi giờ (trống nếu khoản không giờ) và nguồn (AC-124).
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
    [
      ...format.header,
      format.timeHeader,
      format.sourceHeader,
    ].map(cell).join(format.delimiter),
    for (final e in sorted)
      [
        e.date,
        cell(format.typeName(e.type)),
        amount(e.amount),
        currency,
        cell(
          e.type == EntryType.transfer || e.type == EntryType.debt
              ? ''
              : categoryName(e.categoryId),
        ),
        cell(accountName(e.accountId)),
        cell(e.toAccountId == null ? '' : accountName(e.toAccountId!)),
        cell(e.note ?? ''),
        e.time ?? '',
        cell(format.sourceName(e.source)),
      ].join(format.delimiter),
  ];
  return '﻿${lines.join('\r\n')}\r\n';
}
