import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'device_backup_exclusion.dart';
import 'seed.dart';

part 'database.g.dart';

/// Phiên bản schema hiện tại; file sao lưu có schemaVersion lớn hơn bị từ chối.
/// 3: thêm cột số tiền chính xác `*Micro` (D-029), khoản cho phép 0.
const currentSchemaVersion = 3;

/// Loại khoản ghi. Chuyển tiền không tính là thu hay chi (AC-19).
enum EntryType { expense, income, transfer }

/// Loại danh mục: chi hoặc thu.
enum CategoryType { expense, income }

/// Chu kỳ của khoản định kỳ (AC-23).
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Khóa dịch cho tài khoản mặc định; null khi người dùng tự đặt tên (D-005).
  TextColumn get nameKey => text().nullable()();
  TextColumn get name => text().withLength(max: 50).nullable()();

  /// Số dư ban đầu, đơn vị nhỏ nhất của tiền tệ; có thể âm (thẻ tín dụng).
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();

  /// Số dư ban đầu chính xác, phần triệu đơn vị chính (D-029); null là đúng
  /// bằng [initialBalance]. Thêm ở schema 3.
  IntColumn get initialBalanceMicro => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<CategoryType>()();
  TextColumn get nameKey => text().nullable()();
  TextColumn get name => text().withLength(max: 50).nullable()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Hạn mức chi mỗi tháng của danh mục chi, đơn vị nhỏ nhất; null là chưa đặt
  /// (AC-54). Thêm ở schema 2.
  IntColumn get budget => integer().nullable().check(
    // ignore: recursive_getters
    budget.isBiggerThanValue(0),
  )();

  /// Hạn mức chính xác, phần triệu đơn vị chính (D-029); null là đúng bằng
  /// [budget]. Thêm ở schema 3.
  IntColumn get budgetMicro => integer().nullable()();
}

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<EntryType>()();

  /// Đơn vị nhỏ nhất, ≥ 0 (0 chỉ có thể do quy đổi tiền tệ, D-029).
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();

  /// Số tiền chính xác, phần triệu đơn vị chính (D-029); null là đúng bằng
  /// [amount]. Thêm ở schema 3.
  IntColumn get amountMicro => integer().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  @ReferenceName('recurringTransfersIn')
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  TextColumn get note => text().withLength(max: 200).nullable()();
  IntColumn get frequency => intEnum<RecurrenceFrequency>()();

  /// Ngày `YYYY-MM-DD` (D-005).
  TextColumn get startDate => text().withLength(min: 10, max: 10)();
  TextColumn get lastGeneratedDate =>
      text().withLength(min: 10, max: 10).nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<EntryType>()();

  /// Đơn vị nhỏ nhất của tiền tệ (D-005). Người dùng gõ phải > 0 (AC-05); 0
  /// chỉ có thể do quy đổi tiền tệ làm tròn một số rất nhỏ (D-029).
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();

  /// Số tiền chính xác, phần triệu đơn vị chính (D-029); null là đúng bằng
  /// [amount]. Thêm ở schema 3.
  IntColumn get amountMicro => integer().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();

  /// Tài khoản nhận, chỉ dùng khi [type] là chuyển tiền.
  @ReferenceName('transfersIn')
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();

  /// Ngày `YYYY-MM-DD` theo giờ địa phương (D-005).
  TextColumn get date => text().withLength(min: 10, max: 10)();
  TextColumn get note => text().withLength(max: 200).nullable()();
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cài đặt dạng khóa-giá trị, nằm cùng cơ sở dữ liệu để sao lưu một file (D-005).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Accounts, Categories, RecurringRules, Entries, Settings],
)
class AppDatabase extends _$AppDatabase {
  /// [afterOpen] chạy (không chờ) sau mỗi lần mở. Khi dùng file mặc định
  /// ([executor] null) nó mặc định loại file khỏi sao lưu iCloud trên iOS.
  AppDatabase([QueryExecutor? executor, Future<void> Function()? afterOpen])
    : _afterOpen =
          afterOpen ??
          (executor == null
              ? const DeviceBackupExclusion().excludeDatabase
              : null),
      super(executor ?? driftDatabase(name: databaseName));

  final Future<void> Function()? _afterOpen;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedDefaults(this);
    },
    onUpgrade: (m, from, to) async {
      // 1 -> 2: hạn mức theo danh mục (AC-54); dữ liệu cũ giữ nguyên, hạn mức null.
      if (from < 2) await m.addColumn(categories, categories.budget);
      // 2 -> 3: số tiền chính xác (D-029). Dựng lại `entries`/`recurring_rules`
      // để nới CHECK amount > 0 thành >= 0; dữ liệu và khóa ngoại giữ nguyên.
      if (from < 3) {
        // `alterTable` tự tắt/bật lại khóa ngoại khi dựng lại bảng.
        await m.addColumn(accounts, accounts.initialBalanceMicro);
        await m.addColumn(categories, categories.budgetMicro);
        await m.alterTable(
          TableMigration(
            recurringRules,
            newColumns: [recurringRules.amountMicro],
          ),
        );
        await m.alterTable(
          TableMigration(entries, newColumns: [entries.amountMicro]),
        );
        final broken = await customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) {
          throw StateError('foreign_key_check after v3 migration: $broken');
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Sau khi mở file mới chắc chắn tồn tại để iOS đặt cờ. Không chờ: lỗi
      // hay chậm ở kênh nền tảng không được làm chậm hay hỏng việc mở app.
      final afterOpen = _afterOpen;
      if (afterOpen != null) unawaited(afterOpen().catchError((_) {}));
    },
  );
}
