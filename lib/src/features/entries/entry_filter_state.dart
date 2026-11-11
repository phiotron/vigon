import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/entry_filter.dart';

/// Bộ lọc nâng cao đang áp dụng ở màn "Các khoản" (F-39). Chỉ nằm trong bộ
/// nhớ: tắt app là mất (AC-115), không ghi vào cài đặt hay sao lưu.
class EntryFilterNotifier extends Notifier<EntryFilter> {
  @override
  EntryFilter build() => EntryFilter.none;

  void set(EntryFilter filter) => state = filter;

  void clear() => state = EntryFilter.none;

  /// Gỡ một chip: số tiền, một danh mục, hoặc khoảng ngày.
  void remove({bool amount = false, int? category, bool dates = false}) =>
      state = state.without(amount: amount, category: category, dates: dates);
}

final entryFilterProvider = NotifierProvider<EntryFilterNotifier, EntryFilter>(
  EntryFilterNotifier.new,
);
