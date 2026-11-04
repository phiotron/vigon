import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/entry_search.dart';
import '../../data/period.dart';
import '../../data/summary.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';

/// Trạng thái tìm kiếm trên màn "Các khoản" (F-15).
class EntrySearchState {
  const EntrySearchState({
    this.active = false,
    this.query = '',
    this.allTime = false,
  });

  final bool active;
  final String query;

  /// Tìm trên toàn bộ dữ liệu thay vì kỳ đang xem (AC-49).
  final bool allTime;

  EntrySearchState copyWith({bool? active, String? query, bool? allTime}) =>
      EntrySearchState(
        active: active ?? this.active,
        query: query ?? this.query,
        allTime: allTime ?? this.allTime,
      );
}

class EntrySearchNotifier extends Notifier<EntrySearchState> {
  @override
  EntrySearchState build() => const EntrySearchState();

  void open() => state = state.copyWith(active: true);

  /// Đóng ô tìm và xóa mọi lựa chọn.
  void close() => state = const EntrySearchState();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setAllTime(bool allTime) => state = state.copyWith(allTime: allTime);
}

final entrySearchProvider =
    NotifierProvider.autoDispose<EntrySearchNotifier, EntrySearchState>(
      EntrySearchNotifier.new,
    );

/// Mọi khoản của tài khoản đang lọc, chỉ nạp khi tìm "Tất cả thời gian".
final _allTimeEntriesProvider = StreamProvider.autoDispose<List<EntryView>>(
  (ref) => ref
      .watch(entryRepositoryProvider)
      .watchEntries(
        Period.containing(PeriodType.all, ref.watch(todayProvider)),
        accountId: ref.watch(accountFilterProvider),
      ),
);

/// Thanh tiêu đề của màn "Các khoản": tên kỳ và nút "Tìm"; khi đang tìm thì
/// tiêu đề thành ô nhập có nút đóng (AC-48).
class EntriesAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const EntriesAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<EntriesAppBar> createState() => _EntriesAppBarState();
}

class _EntriesAppBarState extends ConsumerState<EntriesAppBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.clear();
    ref.read(entrySearchProvider.notifier).close();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active = ref.watch(entrySearchProvider.select((s) => s.active));
    if (!active) {
      return AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l.search,
            onPressed: () => ref.read(entrySearchProvider.notifier).open(),
          ),
        ],
      );
    }
    return AppBar(
      title: PopScope(
        // Nút Back đóng ô tìm trước, rồi mới thoát màn.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: ref.read(entrySearchProvider.notifier).setQuery,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l.searchClose,
          onPressed: _close,
        ),
      ],
    );
  }
}

/// Chip "Tất cả thời gian", dòng tổng và danh sách phẳng các khoản khớp (AC-49).
/// [tileBuilder] vẽ một khoản như ở danh sách thường (chạm sửa, vuốt xóa).
class EntrySearchResults extends ConsumerWidget {
  const EntrySearchResults({super.key, required this.tileBuilder});

  final Widget Function(EntryView row, String title, String amount) tileBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final search = ref.watch(entrySearchProvider);
    final source = search.allTime
        ? ref.watch(_allTimeEntriesProvider)
        : ref.watch(periodEntriesProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final accounts = {
      for (final a in ref.watch(accountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final rows = source.value;

    final chip = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilterChip(
          label: Text(l.searchAllTime),
          selected: search.allTime,
          onSelected: ref.read(entrySearchProvider.notifier).setAllTime,
        ),
      ),
    );

    Widget list = const SizedBox.shrink();
    if (rows != null) {
      final matches = filterEntries(
        rows,
        search.query,
        categoryNameOf: (r) =>
            r.category == null ? '' : categoryLabel(l, r.category!),
        amountTextOf: (a) => money(context, currency, a),
      );
      list = matches.isEmpty
          ? Center(child: Text(l.searchNoMatch))
          : ListView.builder(
              // Dòng 0 là dòng tổng; các dòng sau là khoản, dựng lười.
              itemCount: matches.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    title: Text(
                      l.searchTotal(
                        matches.length,
                        money(context, currency, searchTotal(matches)),
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                final r = matches[i - 1];
                return tileBuilder(
                  r,
                  _titleOf(l, r, accounts),
                  money(context, currency, r.entry.amount),
                );
              },
            );
    }
    return Column(
      children: [
        chip,
        Expanded(child: list),
      ],
    );
  }

  static String _titleOf(
    AppLocalizations l,
    EntryView r,
    Map<int, Account> accounts,
  ) {
    if (r.entry.type == EntryType.transfer) {
      final from = accounts[r.entry.accountId];
      final to = accounts[r.entry.toAccountId];
      return l.transferLabel(
        from == null ? '' : accountLabel(l, from),
        to == null ? '' : accountLabel(l, to),
      );
    }
    return r.entry.note ??
        (r.category == null ? '' : categoryLabel(l, r.category!));
  }
}
