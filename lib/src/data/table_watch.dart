import 'package:drift/drift.dart';

/// Phát một lần ngay khi nghe, rồi mỗi lần một trong [tables] được ghi.
///
/// Thay cho mẹo `customSelect('SELECT 1', readsFrom: …).watch()`: luồng truy
/// vấn của drift BỎ kết quả trùng lần trước, mà `SELECT 1` lần nào cũng ra
/// cùng một dòng, nên chỉ phát đúng lần đầu — nghe từ lúc mở app (vd nhắc
/// trước hạn) là số dư không bao giờ cập nhật nữa.
Stream<void> watchTables(
  GeneratedDatabase db,
  Iterable<TableInfo<Table, dynamic>> tables,
) async* {
  yield null;
  yield* db.tableUpdates(TableUpdateQuery.onAllTables(tables));
}
