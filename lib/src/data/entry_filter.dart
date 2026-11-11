import 'dates.dart';
import 'database.dart';
import 'money_sum.dart';
import 'rate_repository.dart';
import 'summary.dart';

/// Bộ lọc nâng cao của màn "Các khoản" (F-39, AC-115): khoảng số tiền, nhiều
/// danh mục, khoảng ngày. Các điều kiện kết hợp bằng VÀ; điều kiện không đặt
/// thì bỏ qua. Chỉ sống trong phiên chạy, không lưu.
class EntryFilter {
  const EntryFilter({
    this.minAmount,
    this.maxAmount,
    this.categoryIds = const {},
    this.from,
    this.to,
  });

  static const none = EntryFilter();

  /// Số tiền từ / đến theo **Tiền tệ chính** (D-042: số to trên dòng khoản),
  /// đơn vị nhỏ nhất, tính cả hai đầu; null là bỏ trống đầu đó. So với số dẫn
  /// xuất `Entry.amount` (đã quy về Tiền tệ chính).
  final int? minAmount;
  final int? maxAmount;

  /// Id các danh mục (chi và thu) được chọn; rỗng là không lọc theo danh mục.
  final Set<int> categoryIds;

  /// Khoảng ngày, tính cả hai đầu. Luôn đặt cùng nhau (bộ chọn khoảng trả cả
  /// hai); null là không lọc theo ngày.
  final DateTime? from;
  final DateTime? to;

  bool get hasAmount => minAmount != null || maxAmount != null;
  bool get hasCategories => categoryIds.isNotEmpty;
  bool get hasDates => from != null && to != null;
  bool get isActive => hasAmount || hasCategories || hasDates;

  /// "Từ" lớn hơn "Đến": bảng lọc báo lỗi dưới ô và không áp dụng (AC-115).
  bool get amountRangeInvalid =>
      minAmount != null && maxAmount != null && minAmount! > maxAmount!;

  /// Bỏ điều kiện số tiền, danh mục hoặc ngày; phần còn lại giữ nguyên.
  EntryFilter without({
    bool amount = false,
    int? category,
    bool dates = false,
  }) => EntryFilter(
    minAmount: amount ? null : minAmount,
    maxAmount: amount ? null : maxAmount,
    categoryIds: category == null
        ? categoryIds
        : (Set.of(categoryIds)..remove(category)),
    from: dates ? null : from,
    to: dates ? null : to,
  );

  /// Ngày đầu / cuối dạng chữ `YYYY-MM-DD` để so sánh với `Entry.date`.
  String? get fromKey => hasDates ? dateKey(from!) : null;
  String? get toKey => hasDates ? dateKey(to!) : null;

  @override
  bool operator ==(Object other) =>
      other is EntryFilter &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.from == from &&
      other.to == to &&
      other.categoryIds.length == categoryIds.length &&
      other.categoryIds.containsAll(categoryIds);

  @override
  int get hashCode => Object.hash(
    minAmount,
    maxAmount,
    from,
    to,
    Object.hashAllUnordered(categoryIds),
  );
}

/// Giữ các khoản trong [rows] thoả MỌI điều kiện của [filter] (AC-115), giữ
/// nguyên thứ tự. Có lọc danh mục thì chuyển tiền bị loại (chuyển tiền không
/// có danh mục). Bộ lọc không có điều kiện thì trả nguyên [rows]. "Từ" lớn
/// hơn "Đến" thì không khoản nào thoả.
List<EntryView> applyEntryFilter(List<EntryView> rows, EntryFilter filter) {
  if (!filter.isActive) return rows;
  final min = filter.minAmount, max = filter.maxAmount;
  final fromKey = filter.fromKey, toKey = filter.toKey;
  return [
    for (final r in rows)
      if ((min == null || r.entry.amount >= min) &&
          (max == null || r.entry.amount <= max) &&
          (!filter.hasCategories ||
              (r.category != null &&
                  filter.categoryIds.contains(r.category!.id))) &&
          (fromKey == null || r.entry.date.compareTo(fromKey) >= 0) &&
          (toKey == null || r.entry.date.compareTo(toKey) <= 0))
        r,
  ];
}

/// Dòng tổng của kết quả lọc: số khoản, tổng chi, tổng thu (AC-115). Chuyển
/// tiền được đếm vào số khoản nhưng không vào chi hay thu (AC-19).
///
/// Có [service]: cộng số gốc theo từng tiền tệ rồi quy về Tiền tệ chính MỘT
/// lần (D-042, AC-148); khoản thiếu tỷ giá không vào tổng (AC-134). Không có
/// (chưa nạp tỷ giá): cộng số dẫn xuất.
class FilterTotals {
  const FilterTotals(this.count, this.expense, this.income);

  final int count;
  final int expense;
  final int income;

  factory FilterTotals.of(
    Iterable<EntryView> rows, {
    CurrencyService? service,
  }) {
    var count = 0;
    final expense = MoneyBag(), income = MoneyBag();
    for (final r in rows) {
      count++;
      final e = r.entry;
      if (e.type == EntryType.transfer) continue;
      if (service != null && !service.has(e.currency, service.primary)) {
        continue;
      }
      final amount = service == null ? e.amount : entryOriginal(e);
      final currency = service == null ? '' : e.currency;
      (e.type == EntryType.expense ? expense : income).add(currency, amount);
    }
    int total(MoneyBag bag) => service == null
        ? bag.parts.values.fold(0, (a, b) => a + b)
        : bag.convertTo(service, service.primary) ?? 0;
    return FilterTotals(count, total(expense), total(income));
  }
}

/// Mới nhất trước: ngày giảm dần, cùng ngày thì khoản có giờ muộn hơn trước,
/// khoản không giờ sau cùng, rồi khoản ghi sau đứng trước (AC-76).
int newestFirst(EntryView a, EntryView b) {
  final byDate = b.entry.date.compareTo(a.entry.date);
  if (byDate != 0) return byDate;
  final ta = a.entry.time, tb = b.entry.time;
  if (ta != tb) {
    if (ta == null) return 1;
    if (tb == null) return -1;
    final byTime = tb.compareTo(ta);
    if (byTime != 0) return byTime;
  }
  return b.entry.id.compareTo(a.entry.id);
}
