import 'package:drift/drift.dart';

import 'database.dart';
import 'period.dart';
import 'summary.dart';

/// Đọc, ghi khoản thu chi và chuyển tiền.
class EntryRepository {
  EntryRepository(this._db);

  final AppDatabase _db;

  /// Các khoản trong [period], mới nhất trước; lọc theo tài khoản nếu có (AC-20).
  Stream<List<EntryView>> watchEntries(Period period, {int? accountId}) {
    final e = _db.entries;
    final c = _db.categories;
    final query = _db.select(e).join([
      leftOuterJoin(c, c.id.equalsExp(e.categoryId)),
    ])..where(e.date.isBetweenValues(period.fromKey, period.toKey));
    if (accountId != null) {
      query.where(
        e.accountId.equals(accountId) | e.toAccountId.equals(accountId),
      );
    }
    query.orderBy([OrderingTerm.desc(e.date), OrderingTerm.desc(e.id)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows) EntryView(r.readTable(e), r.readTableOrNull(c)),
      ],
    );
  }

  Future<Entry?> find(int id) => (_db.select(
    _db.entries,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> add(EntriesCompanion entry) =>
      _db.into(_db.entries).insert(entry);

  /// Chuyển tiền giữa hai tài khoản; không tính là thu hay chi (AC-19).
  Future<int> addTransfer({
    required int fromAccountId,
    required int toAccountId,
    required int amount,
    required String date,
    String? note,
  }) {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Hai tài khoản phải khác nhau');
    }
    return add(
      EntriesCompanion.insert(
        type: EntryType.transfer,
        amount: amount,
        accountId: fromAccountId,
        toAccountId: Value(toAccountId),
        date: date,
        note: Value(note),
      ),
    );
  }

  Future<void> update(Entry entry) => _db.update(_db.entries).replace(entry);

  /// Xóa và trả về bản ghi đã xóa để hoàn tác (AC-14).
  Future<Entry?> delete(int id) => _db.transaction(() async {
    final entry = await find(id);
    if (entry != null) {
      await (_db.delete(_db.entries)..where((e) => e.id.equals(id))).go();
    }
    return entry;
  });

  /// Ghi lại đúng bản ghi đã xóa, giữ nguyên id (AC-14).
  Future<void> restore(Entry entry) => _db.into(_db.entries).insert(entry);

  /// Khoản đang gắn số tham chiếu [reference] của nguồn [source] (AC-86).
  Future<Entry?> findByReference(EntrySource source, String reference) =>
      (_db.select(_db.entries)..where(
            (e) =>
                e.source.equalsValue(source) &
                e.referenceNumber.equals(reference),
          ))
          .getSingleOrNull();

  /// Ghép (AC-91): gắn nguồn [source] và số tham chiếu vào khoản [id], mọi dữ
  /// liệu khác giữ nguyên. [source] không được là ghi tay.
  Future<void> attachReference(int id, EntrySource source, String reference) {
    if (source == EntrySource.manual) {
      throw ArgumentError.value(source, 'source', 'không phải nguồn email');
    }
    return (_db.update(_db.entries)..where((e) => e.id.equals(id))).write(
      EntriesCompanion(
        source: Value(source),
        referenceNumber: Value(reference),
      ),
    );
  }

  /// Bỏ ghép (Hoàn tác, AC-94): khoản về ghi tay, không số tham chiếu.
  Future<void> detachReference(int id) =>
      (_db.update(_db.entries)..where((e) => e.id.equals(id))).write(
        const EntriesCompanion(
          source: Value(EntrySource.manual),
          referenceNumber: Value(null),
        ),
      );
}
