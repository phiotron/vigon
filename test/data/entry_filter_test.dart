import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_filter.dart';
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
  Category? category,
  String date, {
  String? time,
}) => EntryView(
  Entry(
    id: id,
    type: type,
    amount: amount,
    categoryId: category?.id,
    accountId: 1,
    toAccountId: type == EntryType.transfer ? 2 : null,
    date: date,
    time: time,
    recurringRuleId: null,
    source: EntrySource.manual,
    createdAt: DateTime(2026),
  ),
  category,
);

void main() {
  final food = _cat(1, 'Ăn uống', CategoryType.expense);
  final bus = _cat(2, 'Đi lại', CategoryType.expense);
  final shop = _cat(3, 'Mua sắm', CategoryType.expense);
  final salary = _cat(10, 'Lương', CategoryType.income);
  final rows = [
    _row(1, EntryType.expense, 50000, food, '2026-11-01'), // đúng đầu dưới
    _row(2, EntryType.expense, 200000, bus, '2026-11-15'), // đúng đầu trên
    _row(3, EntryType.expense, 49999, food, '2026-11-05'), // dưới khoảng tiền
    _row(4, EntryType.expense, 200001, bus, '2026-11-05'), // trên khoảng tiền
    _row(5, EntryType.expense, 100000, shop, '2026-11-05'), // sai danh mục
    _row(6, EntryType.expense, 100000, food, '2026-10-31'), // trước ngày
    _row(7, EntryType.expense, 100000, bus, '2026-11-16'), // sau ngày
    _row(8, EntryType.income, 120000, salary, '2026-11-10'), // sai danh mục
    _row(9, EntryType.transfer, 100000, null, '2026-11-10'),
    _row(10, EntryType.expense, 150000, bus, '2026-11-10'),
  ];

  List<int> ids(EntryFilter f) => [
    for (final r in applyEntryFilter(rows, f)) r.entry.id,
  ];

  test('ví dụ AC-115: 50.000–200.000, Ăn uống + Đi lại, 01–15/11/2026', () {
    final filter = EntryFilter(
      minAmount: 50000,
      maxAmount: 200000,
      categoryIds: {food.id, bus.id},
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 15),
    );
    expect(ids(filter), [1, 2, 10]);
  });

  test('không đặt điều kiện thì giữ nguyên danh sách', () {
    expect(EntryFilter.none.isActive, isFalse);
    expect(identical(applyEntryFilter(rows, EntryFilter.none), rows), isTrue);
  });

  test('bỏ trống một đầu của khoảng số tiền', () {
    expect(
      ids(const EntryFilter(minAmount: 200000)),
      [2, 4],
      reason: 'chỉ "Từ": số tiền ≥ 200.000',
    );
    expect(
      ids(const EntryFilter(maxAmount: 50000)),
      [1, 3],
      reason: 'chỉ "Đến": số tiền ≤ 50.000',
    );
  });

  test('từ = đến chỉ lấy đúng số đó; từ > đến báo không hợp lệ và rỗng', () {
    expect(ids(const EntryFilter(minAmount: 150000, maxAmount: 150000)), [10]);
    const bad = EntryFilter(minAmount: 200000, maxAmount: 50000);
    expect(bad.amountRangeInvalid, isTrue);
    expect(ids(bad), isEmpty);
    expect(const EntryFilter(minAmount: 5).amountRangeInvalid, isFalse);
  });

  test('lọc danh mục: chọn cả chi lẫn thu, loại chuyển tiền', () {
    expect(ids(EntryFilter(categoryIds: {salary.id, shop.id})), [5, 8]);
    // Chuyển tiền (không danh mục) chỉ còn khi không lọc danh mục.
    expect(ids(const EntryFilter(minAmount: 100000, maxAmount: 100000)), [
      5,
      6,
      7,
      9,
    ]);
    expect(
      ids(
        EntryFilter(
          minAmount: 100000,
          maxAmount: 100000,
          categoryIds: {food.id, bus.id, shop.id},
        ),
      ),
      [5, 6, 7],
    );
  });

  test('khoảng ngày tính cả hai đầu', () {
    final f = EntryFilter(from: DateTime(2026, 11, 5), to: DateTime(2026, 11, 5));
    expect(ids(f), [3, 4, 5]);
  });

  test('gỡ từng điều kiện bằng without()', () {
    final filter = EntryFilter(
      minAmount: 1,
      maxAmount: 9,
      categoryIds: {1, 2},
      from: DateTime(2026),
      to: DateTime(2026, 2),
    );
    expect(filter.without(amount: true).hasAmount, isFalse);
    expect(filter.without(amount: true).hasCategories, isTrue);
    expect(filter.without(category: 1).categoryIds, {2});
    expect(filter.without(category: 1).hasAmount, isTrue);
    expect(filter.without(dates: true).hasDates, isFalse);
    expect(
      filter.without(amount: true, category: 1, dates: true).categoryIds,
      {2},
    );
    expect(filter.without(category: 1).without(category: 2).isActive, isTrue);
    expect(
      filter.without(amount: true).without(category: 1).without(category: 2)
          .without(dates: true).isActive,
      isFalse,
    );
  });

  test('dòng tổng: số khoản, chi, thu; chuyển tiền không tính chi/thu', () {
    final totals = FilterTotals.of(rows);
    expect(totals.count, 10);
    expect(totals.income, 120000);
    expect(
      totals.expense,
      50000 + 200000 + 49999 + 200001 + 100000 + 100000 + 100000 + 150000,
    );
    final empty = FilterTotals.of(const []);
    expect((empty.count, empty.expense, empty.income), (0, 0, 0));
  });

  test('mới nhất trước: ngày, rồi giờ muộn trước, không giờ sau cùng', () {
    final list = [
      _row(1, EntryType.expense, 1, food, '2026-11-01'),
      _row(2, EntryType.expense, 1, food, '2026-11-02', time: '08:00'),
      _row(3, EntryType.expense, 1, food, '2026-11-02', time: '20:30'),
      _row(4, EntryType.expense, 1, food, '2026-11-02'),
      _row(5, EntryType.expense, 1, food, '2026-11-02'),
    ]..sort(newestFirst);
    expect([for (final r in list) r.entry.id], [3, 2, 5, 4, 1]);
  });
}
