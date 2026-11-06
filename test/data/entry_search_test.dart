import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_search.dart';
import 'package:vigon/src/data/summary.dart';

Category _cat(int id, String name, CategoryType type) => Category(
  id: id,
  type: type,
  nameKey: null,
  name: name,
  icon: 'more_horiz',
  color: 0xFF000000,
  sortOrder: id,
);

EntryView _row(
  int id,
  EntryType type,
  int amount,
  Category? category, {
  String? note,
}) => EntryView(
  Entry(
    id: id,
    type: type,
    amount: amount,
    categoryId: category?.id,
    accountId: 1,
    toAccountId: type == EntryType.transfer ? 2 : null,
    date: '2026-11-03',
    note: note,
    recurringRuleId: null,
    source: EntrySource.manual,
    createdAt: DateTime(2026),
  ),
  category,
);

/// Giả lập cách hiển thị VND: dấu chấm ngăn nghìn và khoảng trắng + ₫.
String _vnd(int a) {
  final s = a.toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
    out.write(s[i]);
  }
  return '$out ₫';
}

void main() {
  final food = _cat(1, 'Ăn uống', CategoryType.expense);
  final salary = _cat(10, 'Lương', CategoryType.income);
  final rows = [
    _row(1, EntryType.expense, 155000, food, note: 'Cà phê Highlands'),
    _row(2, EntryType.expense, 1550000, food),
    _row(3, EntryType.expense, 20000, food, note: 'Đi grab'),
    _row(4, EntryType.income, 9000000, salary, note: 'Tháng 11'),
    _row(5, EntryType.transfer, 500000, null, note: 'Chuyển ví'),
  ];

  List<int> ids(String q) => [
    for (final r in filterEntries(
      rows,
      q,
      categoryNameOf: (r) => r.category?.name ?? '',
      amountTextOf: _vnd,
    ))
      r.entry.id,
  ];

  test('khớp ghi chú, không phân biệt hoa thường và dấu (AC-48)', () {
    expect(ids('ca phe'), [1]);
    expect(ids('CÀ PHÊ'), [1]);
    expect(ids('highlan'), [1]);
    expect(ids('grab'), [3]);
    expect(ids('di gra'), [3]);
    expect(ids('chuyen vi'), [5]);
  });

  test('khớp tên danh mục, gồm Đ/đ (AC-48)', () {
    expect(ids('an uong'), [1, 2, 3]);
    expect(ids('LUONG'), [4]);
  });

  test('số tiền khớp theo chữ số, bỏ dấu ngăn cách (AC-48)', () {
    expect(ids('155'), [1, 2]);
    expect(ids('155.000'), [1, 2]);
    expect(ids('155000'), [1, 2]);
    expect(ids('1.550.000'), [2]);
    expect(ids('20.000'), [3]);
    expect(ids('9000000'), [4]);
  });

  test('chữ lẫn số chỉ khớp ghi chú, không khớp số tiền', () {
    // Chỉ xét số tiền khi cả chuỗi tìm là số và dấu ngăn cách.
    expect(ids('thang 11'), [4]);
    expect(ids('a155'), isEmpty);
  });

  test('chuỗi rỗng giữ tất cả, không khớp thì rỗng', () {
    expect(ids(''), [1, 2, 3, 4, 5]);
    expect(ids('   '), [1, 2, 3, 4, 5]);
    expect(ids('zzz'), isEmpty);
  });

  test('tổng: chỉ chi, chỉ thu, lẫn cả hai, chuyển tiền không tính', () {
    expect(searchTotal([rows[0], rows[1]]), 1705000);
    expect(searchTotal([rows[3]]), 9000000);
    expect(searchTotal([rows[0], rows[3]]), 9000000 - 155000);
    expect(searchTotal([rows[4]]), 0);
    expect(searchTotal(const []), 0);
  });
}
