import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'device_backup_exclusion.dart';
import 'seed.dart';

part 'database.g.dart';

/// Phiên bản schema hiện tại; file sao lưu có schemaVersion lớn hơn bị từ chối.
/// 3: thêm cột số tiền chính xác `*Micro` (D-029), khoản cho phép 0.
/// 4: bản 2.0 (AC-121) — giờ, nguồn, số tham chiếu của khoản; liên kết ngân
/// hàng của tài khoản; mục tiêu tiết kiệm, khoản nợ + lần trả, gợi ý theo
/// người thụ hưởng, hàng đợi nhập, số tham chiếu đã gặp.
/// 5: đa tiền tệ (D-037) — tiền tệ của tài khoản, số tiền gốc + tiền tệ của
/// khoản/định kỳ/nợ/mục tiêu/ngân sách, số nhận của chuyển tiền khác tiền tệ.
const currentSchemaVersion = 7;

/// Loại khoản ghi. Chuyển tiền không tính là thu hay chi (AC-19).
enum EntryType { expense, income, transfer }

/// Loại danh mục: chi hoặc thu.
enum CategoryType { expense, income }

/// Chu kỳ của khoản định kỳ (AC-23).
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Nguồn của khoản (Import source, AC-124): ghi tay hoặc email biên lai MB.
/// Lưu bằng tên (`textEnum`) nên thêm nguồn sau này không đổi dữ liệu cũ.
enum EntrySource { manual, emailMb }

/// Ngân hàng gửi email biên lai (D-030: bản đầu chỉ MB Bank). Lưu bằng tên.
enum Bank { mb }

/// Chiều của khoản nợ (AC-104): cho vay = người khác nợ bạn; đi vay = bạn nợ.
enum DebtDirection { lent, borrowed }

/// Số tham chiếu đã được xử lý thế nào (AC-86): ghép vào khoản ghi tay, lưu từ
/// hàng đợi (khoản chi hoặc chuyển tiền), hay bị bỏ qua.
enum ReferenceOutcome { matched, confirmed, skipped }

/// Ràng buộc CHECK cho cột giờ `HH:mm` (AC-74).
Expression<bool> _isHhMm(String column) =>
    CustomExpression<bool>("$column GLOB '[0-2][0-9]:[0-5][0-9]'");

/// Ràng buộc CHECK cho 4 số cuối tài khoản (AC-88: không lưu số đầy đủ).
Expression<bool> _isLast4(String column) =>
    CustomExpression<bool>("$column GLOB '[0-9][0-9][0-9][0-9]'");

/// Liên kết (ngân hàng, 4 số cuối) thuộc tối đa một tài khoản (AC-89, AC-90).
@TableIndex(
  name: 'accounts_bank_link',
  columns: {#bank, #bankLast4},
  unique: true,
)
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

  /// Ngân hàng của tài khoản trích nợ liên kết (AC-89); null là không liên
  /// kết. Có [bank] thì phải có [bankLast4] và ngược lại (repository giữ).
  /// Thêm ở schema 4.
  TextColumn get bank => textEnum<Bank>().nullable()();

  /// 4 số cuối của tài khoản trích nợ — KHÔNG bao giờ lưu số đầy đủ (AC-88).
  /// Thêm ở schema 4.
  TextColumn get bankLast4 => text().nullable().check(_isLast4('bank_last4'))();

  /// Tiền tệ của tài khoản (D-037). Mọi khoản của tài khoản mặc định ghi bằng
  /// tiền tệ này; vẫn có thể đổi tiền tệ hiển thị mà không sửa số gốc. Thêm ở
  /// schema 5.
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();

  /// Số dư ban đầu gốc + tiền tệ (D-037); [initialBalance] là số quy về Tiền
  /// tệ chính. Null ở cột gốc là dữ liệu cũ.
  IntColumn get initialBalanceOriginal => integer().nullable()();
  TextColumn get initialCurrency =>
      text().withLength(min: 3, max: 3).nullable()();
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

  /// Hạn mức gốc theo tiền tệ của danh mục (D-037); null là [budget] đã là số
  /// gốc ở [budgetCurrency]. Thêm ở schema 5.
  IntColumn get budgetOriginal => integer().nullable()();

  /// Tiền tệ của hạn mức danh mục; null là chưa đặt. Thêm ở schema 5.
  TextColumn get budgetCurrency =>
      text().withLength(min: 3, max: 3).nullable()();
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

  /// "Pick days" (F-45): weekdays the series falls on, Mon = bit 0 … Sun =
  /// bit 6; only with weekly. Null = the weekday of [startDate]. Schema 6.
  IntColumn get weekdays => integer().nullable()();

  /// Ngày `YYYY-MM-DD` (D-005).
  TextColumn get startDate => text().withLength(min: 10, max: 10)();
  TextColumn get lastGeneratedDate =>
      text().withLength(min: 10, max: 10).nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Số tiền gốc + tiền tệ của chuỗi (D-037); [amount] là số quy về Tiền tệ
  /// chính. Null ở cột gốc là dữ liệu cũ: [amount] đã là số gốc ở [currency].
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  IntColumn get originalAmount => integer().nullable()();

  /// Chuyển tiền khác tiền tệ: số nhận gốc + tiền tệ đích, và số nhận quy về
  /// Tiền tệ chính (D-037).
  IntColumn get toOriginalAmount => integer().nullable()();
  TextColumn get toCurrency => text().withLength(min: 3, max: 3).nullable()();
  IntColumn get toAmount => integer().nullable()();
}

/// Một số tham chiếu chỉ nằm ở một khoản (AC-86, AC-93). NULL (khoản ghi tay
/// chưa ghép) không tính trùng.
@TableIndex(
  name: 'entries_reference',
  columns: {#source, #referenceNumber},
  unique: true,
)
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

  /// Giờ `HH:mm` theo giờ máy (AC-74). Null: khoản có từ trước schema 4 hoặc
  /// sinh từ khoản định kỳ (AC-75); khi ghép coi là 12:00. Thêm ở schema 4.
  TextColumn get time => text().nullable().check(_isHhMm('"time"'))();

  /// Ghi tay hay từ email MB (AC-91, AC-96, AC-124). Thêm ở schema 4; khoản
  /// cũ là ghi tay.
  TextColumn get source =>
      textEnum<EntrySource>().withDefault(Constant(EntrySource.manual.name))();

  /// Số tham chiếu của email biên lai đã ghép/lưu vào khoản (AC-86); null với
  /// khoản ghi tay chưa ghép. Thêm ở schema 4.
  TextColumn get referenceNumber => text().withLength(max: 64).nullable()();

  /// Số tiền gốc + tiền tệ gốc (D-037). [amount] là số quy về Tiền tệ chính;
  /// null ở [originalAmount] là dữ liệu cũ: [amount] đã là số gốc ở [currency].
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  IntColumn get originalAmount => integer().nullable()();

  /// Chuyển tiền khác tiền tệ: số nhận gốc + tiền tệ đích; [toAmount] là số
  /// nhận quy về Tiền tệ chính (D-037).
  IntColumn get toOriginalAmount => integer().nullable()();
  TextColumn get toCurrency => text().withLength(min: 3, max: 3).nullable()();
  IntColumn get toAmount => integer().nullable()();
}

/// Mục tiêu tiết kiệm (Savings goal, AC-100..AC-103): tiến độ là số dư của
/// tài khoản gắn; một tài khoản gắn tối đa một mục tiêu. Thêm ở schema 4.
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Số tiền mục tiêu, đơn vị nhỏ nhất, tối thiểu 1 (kể cả sau quy đổi).
  IntColumn get targetAmount =>
      // ignore: recursive_getters
      integer().check(targetAmount.isBiggerThanValue(0))();

  /// Số chính xác, phần triệu đơn vị chính (D-029); null là đúng bằng
  /// [targetAmount].
  IntColumn get targetAmountMicro => integer().nullable()();

  /// Hạn `YYYY-MM-DD`, tuỳ chọn.
  TextColumn get dueDate => text().withLength(min: 10, max: 10).nullable()();

  /// Tài khoản gắn. Xoá tài khoản bị chặn khi còn mục tiêu (AccountRepository).
  IntColumn get accountId => integer().unique().references(Accounts, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Số mục tiêu gốc + tiền tệ (D-037); [targetAmount] là số quy về Tiền tệ
  /// chính. Null ở cột gốc là dữ liệu cũ.
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  IntColumn get originalTargetAmount => integer().nullable()();

  /// Ngày `YYYY-MM-DD` lần đầu số dư ví ≥ mục tiêu (D-043, AC-153); null là
  /// đang tiết kiệm. "Đã xong" vĩnh viễn: rút tiền sau đó không xoá cột này,
  /// chỉ "Mở lại" mới xoá. Thêm ở schema 7.
  TextColumn get completedAt =>
      text().withLength(min: 10, max: 10).nullable()();
}

/// Khoản nợ (Debt record, AC-104..AC-106): sổ ghi nhớ, không phải khoản,
/// không đụng số dư tài khoản. Thêm ở schema 4.
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get person => text().withLength(min: 1, max: 50)();
  TextColumn get direction => textEnum<DebtDirection>()();

  /// Đơn vị nhỏ nhất; người dùng nhập > 0, quy đổi có thể ra 0 (như khoản).
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();

  /// Số chính xác (D-029); null là đúng bằng [amount].
  IntColumn get amountMicro => integer().nullable()();

  /// Ngày `YYYY-MM-DD`.
  TextColumn get date => text().withLength(min: 10, max: 10)();
  TextColumn get dueDate => text().withLength(min: 10, max: 10).nullable()();
  TextColumn get note => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Số nợ gốc + tiền tệ (D-037); [amount] là số quy về Tiền tệ chính. Null ở
  /// cột gốc là dữ liệu cũ.
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  IntColumn get originalAmount => integer().nullable()();
}

/// Lần trả của khoản nợ (Debt payment, AC-105). Xoá khoản nợ xoá luôn lần trả.
/// Thêm ở schema 4.
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(Debts, #id, onDelete: KeyAction.cascade)();

  /// Đơn vị nhỏ nhất; ≥ 0 như [Debts.amount].
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();
  IntColumn get amountMicro => integer().nullable()();
  TextColumn get date => text().withLength(min: 10, max: 10)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Số trả gốc + tiền tệ (D-037); [amount] là số quy về Tiền tệ chính. Null ở
  /// cột gốc là dữ liệu cũ.
  TextColumn get currency =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  IntColumn get originalAmount => integer().nullable()();
}

/// Gợi ý theo người thụ hưởng (Payee suggestion, AC-97): lựa chọn gần nhất
/// cho cùng khoá — một danh mục, HOẶC chuyển sang tài khoản (AC-98). Thêm ở
/// schema 4.
class PayeeSuggestions extends Table {
  /// Tên người thụ hưởng đã gấp: bỏ dấu, viết thường, gộp khoảng trắng
  /// (`payeeKey()` trong `import_repositories.dart`).
  TextColumn get payeeKey => text().withLength(min: 1, max: 200)();

  /// Tên như trên email lần gần nhất, để hiện ở "Gợi ý đã nhớ".
  TextColumn get payee => text().withLength(min: 1, max: 200)();

  /// Xoá danh mục thì gợi ý chuyển sang danh mục nhận khoản (CategoryRepository).
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  /// Xoá tài khoản thì gợi ý chuyển sang nó mất theo.
  @ReferenceName('payeeTransferSuggestions')
  IntColumn get toAccountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {payeeKey};

  @override
  List<String> get customConstraints => [
    'CHECK ((category_id IS NULL) <> (to_account_id IS NULL))',
  ];
}

/// Mục hàng đợi (Import queue, AC-95..AC-99): email thành công chưa ghép,
/// CHƯA là khoản. Không vào file sao lưu (AC-99, AC-121). Thêm ở schema 4.
@TableIndex(
  name: 'import_queue_reference',
  columns: {#bank, #referenceNumber},
  unique: true,
)
class ImportQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bank => textEnum<Bank>()();
  TextColumn get referenceNumber => text().withLength(min: 1, max: 64)();

  /// 4 số cuối tài khoản trích nợ (AC-88): để tìm lại tài khoản liên kết khi
  /// [accountId] bị xoá hoặc sau khôi phục.
  TextColumn get debitLast4 => text().check(_isLast4('debit_last4'))();

  /// Tài khoản liên kết với tài khoản trích nợ; null khi tài khoản đó bị xoá
  /// hoặc sau khôi phục không tìm lại được — bên nhập phải gắn lại (AC-90).
  IntColumn get accountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Tiền tệ của [amount] (email MB là VND). Khác tiền tệ app → AC-87. Đổi
  /// tiền tệ app chỉ quy đổi mục đang cùng tiền tệ cũ (AC-122).
  TextColumn get currency => text().withLength(min: 3, max: 3)();

  /// Đơn vị nhỏ nhất của [currency].
  // ignore: recursive_getters
  IntColumn get amount => integer().check(amount.isBiggerOrEqualValue(0))();
  IntColumn get amountMicro => integer().nullable()();

  /// Ngày `YYYY-MM-DD` và giờ `HH:mm` của email (AC-84).
  TextColumn get date => text().withLength(min: 10, max: 10)();
  TextColumn get time => text().check(_isHhMm('"time"'))();

  /// Người thụ hưởng; dãy ≥ 9 chữ số đã che (AC-88).
  TextColumn get payee => text().withLength(max: 200).nullable()();

  /// Nội dung chuyển tiền; dãy ≥ 9 chữ số đã che (AC-88).
  TextColumn get transferContent => text().withLength(max: 500).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Số tham chiếu đã gặp (AC-86): đã ghép, đã lưu hay đã bỏ qua thì không nhập
/// lại, kể cả khi khoản bị xoá. Đi theo file sao lưu (AC-121). Mục còn trong
/// hàng đợi KHÔNG ghi ở đây (hàng đợi chặn trùng bằng chỉ mục riêng, và hàng
/// đợi không vào file — ghi ở đây thì khôi phục sang máy khác sẽ mất mục).
/// Thêm ở schema 4.
class SeenReferences extends Table {
  TextColumn get bank => textEnum<Bank>()();
  TextColumn get referenceNumber => text().withLength(min: 1, max: 64)();
  TextColumn get outcome => textEnum<ReferenceOutcome>()();
  DateTimeColumn get seenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {bank, referenceNumber};
}

/// Cài đặt dạng khóa-giá trị, nằm cùng cơ sở dữ liệu để sao lưu một file (D-005).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    RecurringRules,
    Entries,
    Settings,
    SavingsGoals,
    Debts,
    DebtPayments,
    PayeeSuggestions,
    ImportQueueItems,
    SeenReferences,
  ],
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
      // Cài mới → hiện Màn chào (F-44). Chỉ ở đây: nâng cấp từ bản cũ, Xóa
      // toàn bộ dữ liệu hay Khôi phục không hiện lại (D-041).
      await customStatement(
        "INSERT INTO settings (key, value) VALUES ('onboardingPending', '1')",
      );
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
            // Phải liệt kê MỌI cột thêm sau schema 3 (schema 4, 5, 6): drift
            // dựng bảng theo định nghĩa hiện tại, cột không có trong danh sách
            // này sẽ bị SELECT từ bảng cũ và lỗi "no such column".
            newColumns: [
              recurringRules.amountMicro,
              recurringRules.currency,
              recurringRules.originalAmount,
              recurringRules.toOriginalAmount,
              recurringRules.toCurrency,
              recurringRules.toAmount,
              recurringRules.weekdays,
            ],
          ),
        );
        // Dựng lại theo định nghĩa HIỆN TẠI của bảng: các cột schema 4 cũng
        // được tạo luôn ở đây (rỗng/mặc định), nên bước 3 -> 4 bỏ qua chúng.
        await m.alterTable(
          TableMigration(
            entries,
            newColumns: [
              entries.amountMicro,
              entries.time,
              entries.source,
              entries.referenceNumber,
              entries.currency,
              entries.originalAmount,
              entries.toOriginalAmount,
              entries.toCurrency,
              entries.toAmount,
            ],
          ),
        );
        final broken = await customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) {
          throw StateError('foreign_key_check after v3 migration: $broken');
        }
      }
      // 3 -> 4: bản 2.0 (AC-121). Chỉ thêm cột (null hoặc có mặc định) và bảng
      // mới; khoản cũ là ghi tay, không giờ (AC-75). Không dựng lại bảng cũ.
      if (from < 4) {
        await m.addColumn(accounts, accounts.bank);
        await m.addColumn(accounts, accounts.bankLast4);
        if (from == 3) {
          await m.addColumn(entries, entries.time);
          await m.addColumn(entries, entries.source);
          await m.addColumn(entries, entries.referenceNumber);
        }
        await m.create(accountsBankLink);
        await m.create(entriesReference);
        await m.create(savingsGoals);
        await m.create(debts);
        await m.create(debtPayments);
        await m.create(payeeSuggestions);
        await m.create(importQueueItems);
        await m.create(importQueueReference);
        await m.create(seenReferences);
        final broken = await customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) {
          throw StateError('foreign_key_check after v4 migration: $broken');
        }
      }
      // 4 -> 5: đa tiền tệ (D-037). Dữ liệu cũ giữ nguyên số tiền; mọi bản ghi
      // nhận tiền tệ đang dùng của app, Tiền tệ chính = tiền tệ đó. Cột gốc để
      // null nghĩa là số hiện tại đã là số gốc.
      if (from < 5) {
        await m.addColumn(accounts, accounts.currency);
        await m.addColumn(accounts, accounts.initialBalanceOriginal);
        await m.addColumn(accounts, accounts.initialCurrency);
        await m.addColumn(categories, categories.budgetOriginal);
        await m.addColumn(categories, categories.budgetCurrency);
        // Từ schema 3 trở xuống, bước dựng lại bảng ở trên đã tạo sẵn các cột
        // của bảng này theo định nghĩa hiện tại; chỉ thêm khi bảng chưa dựng lại.
        if (from >= 3) {
          await m.addColumn(recurringRules, recurringRules.currency);
          await m.addColumn(recurringRules, recurringRules.originalAmount);
          await m.addColumn(recurringRules, recurringRules.toOriginalAmount);
          await m.addColumn(recurringRules, recurringRules.toCurrency);
          await m.addColumn(recurringRules, recurringRules.toAmount);
          await m.addColumn(entries, entries.currency);
          await m.addColumn(entries, entries.originalAmount);
          await m.addColumn(entries, entries.toOriginalAmount);
          await m.addColumn(entries, entries.toCurrency);
          await m.addColumn(entries, entries.toAmount);
        }
        // savings_goals/debts/debt_payments được tạo ở bước 4 với định nghĩa
        // hiện tại (đã có cột tiền tệ) khi nâng từ schema < 4.
        if (from >= 4) {
          await m.addColumn(savingsGoals, savingsGoals.currency);
          await m.addColumn(savingsGoals, savingsGoals.originalTargetAmount);
          await m.addColumn(debts, debts.currency);
          await m.addColumn(debts, debts.originalAmount);
          await m.addColumn(debtPayments, debtPayments.currency);
          await m.addColumn(debtPayments, debtPayments.originalAmount);
        }

        final legacy = await customSelect(
          "SELECT value FROM settings WHERE key = 'currency'",
        ).getSingleOrNull();
        var oldCurrency = legacy?.read<String>('value') ?? 'USD';
        if (!RegExp(r'^[A-Z]{3}$').hasMatch(oldCurrency)) oldCurrency = 'USD';
        await customStatement(
          "UPDATE accounts SET currency = '$oldCurrency', "
          "initial_currency = '$oldCurrency'",
        );
        await customStatement(
          "UPDATE categories SET budget_currency = '$oldCurrency' "
          'WHERE budget IS NOT NULL',
        );
        await customStatement(
          "UPDATE recurring_rules SET currency = '$oldCurrency'",
        );
        await customStatement("UPDATE entries SET currency = '$oldCurrency'");
        await customStatement(
          "UPDATE savings_goals SET currency = '$oldCurrency'",
        );
        await customStatement("UPDATE debts SET currency = '$oldCurrency'");
        await customStatement(
          "UPDATE debt_payments SET currency = '$oldCurrency'",
        );
        await customStatement(
          "INSERT OR REPLACE INTO settings (key, value) "
          "VALUES ('primaryCurrency', '$oldCurrency')",
        );
        await customStatement(
          "INSERT OR REPLACE INTO settings (key, value) "
          "SELECT 'budgetCurrency', '$oldCurrency' WHERE EXISTS "
          "(SELECT 1 FROM settings WHERE key = 'monthlyBudget')",
        );
        final broken = await customSelect('PRAGMA foreign_key_check').get();
        if (broken.isNotEmpty) {
          throw StateError('foreign_key_check after v5 migration: $broken');
        }
      }
      // 5 -> 6: lặp theo thứ (F-45). Từ schema 3 trở xuống bảng đã được dựng
      // lại ở bước 3 theo định nghĩa hiện tại (đã có cột).
      if (from < 6 && from >= 3) {
        await m.addColumn(recurringRules, recurringRules.weekdays);
      }
      // 6 -> 7: mục tiêu "Đã xong" (D-043). Từ schema 3 trở xuống bảng được
      // tạo ở bước 4 theo định nghĩa hiện tại (đã có cột).
      if (from < 7 && from >= 4) {
        await m.addColumn(savingsGoals, savingsGoals.completedAt);
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
