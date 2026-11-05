import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/entry_search.dart';
import '../../data/period.dart';
import '../../data/summary.dart';
import '../../data/text_fold.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/fields.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';

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

/// Thanh tiêu đề của màn "Các khoản": tên kỳ và nút 🔍 "Tìm"; khi đang tìm
/// (SCR-11) thành ← "Đóng tìm kiếm" + ô tìm viên thuốc [VgSearchField] có nút
/// ✕ "Xóa nội dung tìm" (AC-48).
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
            icon: const Icon(Symbols.search_rounded),
            tooltip: l.search,
            onPressed: () => ref.read(entrySearchProvider.notifier).open(),
          ),
        ],
      );
    }
    return PopScope(
      // Nút Back đóng ô tìm trước, rồi mới thoát màn.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_rounded),
          tooltip: l.searchClose,
          onPressed: _close,
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: VgSpace.s2),
          child: VgSearchField(
            controller: _controller,
            hintText: l.searchHint,
            autofocus: true,
            onChanged: ref.read(entrySearchProvider.notifier).setQuery,
          ),
        ),
      ),
    );
  }
}

/// Kết quả tìm (SCR-11): cặp chip phạm vi "{tên kỳ}" | "Tất cả thời gian"
/// (A21), dòng tổng body-sm chữ phụ (không có khi ô tìm trống, A06), danh
/// sách phẳng các khoản khớp, mới nhất trước — dòng 72 có chữ khớp tô
/// `primary-container` + 600, số tiền có dấu − / + (A07). Không khớp: icon
/// `search_off` + "Không có khoản nào khớp". Chạm dòng để sửa, vuốt trái để
/// xóa có hoàn tác.
class EntrySearchResults extends ConsumerWidget {
  const EntrySearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final search = ref.watch(entrySearchProvider);
    final source = search.allTime
        ? ref.watch(_allTimeEntriesProvider)
        : ref.watch(periodEntriesProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final rows = source.value;
    final query = search.query.trim();

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s4,
          VgSpace.s1,
          VgSpace.s4,
          VgSpace.s2,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: ScopeChips<bool>(
            options: [
              (false, periodTitle(context, ref.watch(periodProvider))),
              (true, l.searchAllTime),
            ],
            selected: search.allTime,
            onChanged: ref.read(entrySearchProvider.notifier).setAllTime,
          ),
        ),
      ),
    ];
    if (rows != null) {
      String categoryName(EntryView r) =>
          r.category == null ? '' : categoryLabel(l, r.category!);
      final matches = [
        ...filterEntries(
          rows,
          query,
          categoryNameOf: categoryName,
          amountTextOf: (a) => money(context, currency, a),
        ),
      ]..sort(_newestFirst);
      if (matches.isEmpty) {
        children.add(
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s8,
                  48,
                  VgSpace.s8,
                  VgSpace.s4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Symbols.search_off_rounded,
                        size: 40,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: VgSpace.s3),
                    Text(
                      l.searchNoMatch,
                      textAlign: TextAlign.center,
                      style: VgType.bodyMd.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        if (query.isNotEmpty) {
          children.add(
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4,
                  VgSpace.s1,
                  VgSpace.s4,
                  VgSpace.s2,
                ),
                child: Text(
                  l.searchTotal(
                    matches.length,
                    money(context, currency, searchTotal(matches)),
                  ),
                  style: VgType.bodySm.copyWith(color: muted),
                ),
              ),
            ),
          );
        }
        children.add(
          Expanded(
            child: ListView.builder(
              // Cuộn danh sách thì ẩn bàn phím (SCR-11 all-time).
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: matches.length,
              itemBuilder: (context, i) {
                final r = matches[i];
                return SearchResultTile(
                  row: r,
                  title: _titleOf(l, r, accounts),
                  categoryName: r.entry.type == EntryType.transfer
                      ? l.transfer
                      : categoryName(r),
                  amount: money(context, currency, r.entry.amount),
                  query: query,
                );
              },
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Mới nhất trước: ngày giảm dần, cùng ngày thì khoản ghi sau đứng trước.
  static int _newestFirst(EntryView a, EntryView b) {
    final byDate = b.entry.date.compareTo(a.entry.date);
    return byDate != 0 ? byDate : b.entry.id.compareTo(a.entry.id);
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

/// Một dòng kết quả tìm (`.vg-row.two`, SCR-11): avatar danh mục 40 (chuyển
/// tiền: ⇄) · ghi chú (hoặc tên danh mục) · "danh mục · ngày" · số tiền có
/// dấu − chi / + thu theo màu (chuyển tiền không dấu, A07); cao tối thiểu 72.
/// Chữ ≥ 130%: chữ xuống dòng, số tiền xuống dưới. Chạm để sửa (AC-13), vuốt
/// trái để xóa có hoàn tác (AC-14).
class SearchResultTile extends ConsumerWidget {
  const SearchResultTile({
    super.key,
    required this.row,
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.query,
  });

  final EntryView row;
  final String title;
  final String categoryName;
  final String amount;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entry = row.entry;
    final large = isLargeText(context);
    final isTransfer = entry.type == EntryType.transfer;
    final (sign, color) = switch (entry.type) {
      EntryType.expense => ('−', expenseColor(context)),
      EntryType.income => ('+', incomeColor(context)),
      EntryType.transfer => ('', scheme.onSurface),
    };
    final mark = TextStyle(
      backgroundColor: scheme.primaryContainer,
      color: scheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );
    // Khoản của hôm nay ghi "Hôm nay" như frame SCR-10/11 (A05, A06).
    final day = parseDateKey(entry.date);
    final date = day == ref.watch(todayProvider)
        ? l.today
        : shortDate(context, day);
    final amountText = Text.rich(
      TextSpan(
        style: VgType.bodyMd.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign),
          ...highlightSpans(amount, amountMatches(amount, query), mark),
        ],
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: VgType.bodyMd.copyWith(color: scheme.onSurface),
            children: highlightSpans(title, textMatches(title, query), mark),
          ),
          maxLines: large ? null : 1,
          overflow: large ? null : TextOverflow.ellipsis,
        ),
        Text.rich(
          TextSpan(
            style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            children: [
              ...highlightSpans(
                categoryName,
                isTransfer ? const [] : textMatches(categoryName, query),
                mark,
              ),
              TextSpan(text: ' · $date'),
            ],
          ),
          maxLines: large ? null : 1,
          overflow: large ? null : TextOverflow.ellipsis,
        ),
        if (large) ...[const SizedBox(height: 2), amountText],
      ],
    );
    final leading = isTransfer
        ? SizedBox.square(
            dimension: 40,
            child: Icon(
              Symbols.swap_horiz_rounded,
              color: scheme.onSurfaceVariant,
            ),
          )
        : row.category == null
        ? const SizedBox.square(dimension: 40)
        : CategoryAvatar(category: row.category!, size: 40);
    return Dismissible(
      key: ValueKey('search-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.vg.swipeDelete,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VgSpace.s6),
        child: Icon(Symbols.delete_rounded, color: context.vg.error),
      ),
      onDismissed: (_) async {
        final repo = ref.read(entryRepositoryProvider);
        final deleted = await repo.delete(entry.id);
        if (deleted != null) {
          showUndoSnackBar(
            message: l.deleted,
            undoLabel: l.undo,
            onUndo: () => repo.restore(deleted),
          );
        }
      },
      child: InkWell(
        onTap: () => context.push(
          isTransfer ? '/transfer/${entry.id}' : '/entry/${entry.id}',
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VgSize.rowTwoLine),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VgSpace.s4,
              vertical: VgSpace.s2,
            ),
            child: Row(
              crossAxisAlignment: large
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: VgSpace.s4),
                Expanded(child: text),
                if (!large) ...[const SizedBox(width: VgSpace.s4), amountText],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chuỗi tìm có phải số tiền không (giống `filterEntries`).
final _amountQuery = RegExp(r"^[\d\s.,'’]+$");
final _digit = RegExp(r'\d');

/// Các khoảng [start, end) trong [source] khớp [query], không phân biệt hoa
/// thường và dấu tiếng Việt (cùng cách gấp chữ với `filterEntries`).
List<(int, int)> textMatches(String source, String query) {
  final q = foldText(query.trim());
  if (q.isEmpty || source.isEmpty) return const [];
  final folded = StringBuffer();
  final starts = <int>[];
  final ends = <int>[];
  var offset = 0;
  for (final rune in source.runes) {
    final ch = String.fromCharCode(rune);
    final f = foldText(ch);
    if (f.isEmpty && ends.isNotEmpty) {
      // Dấu rời (NFD) dính vào chữ đứng trước.
      ends[ends.length - 1] = offset + ch.length;
    }
    for (var k = 0; k < f.length; k++) {
      starts.add(offset);
      ends.add(offset + ch.length);
    }
    folded.write(f);
    offset += ch.length;
  }
  final hay = folded.toString();
  final out = <(int, int)>[];
  var from = 0;
  while (true) {
    final i = hay.indexOf(q, from);
    if (i < 0) break;
    out.add((starts[i], ends[i + q.length - 1]));
    from = i + q.length;
  }
  return out;
}

/// Các khoảng trong [amount] khớp dãy chữ số của [query], vắt qua dấu ngăn
/// cách nghìn (A07): gõ `155` tô "1.55" trong "1.550.000 ₫". Chỉ khi chuỗi
/// tìm là số tiền.
List<(int, int)> amountMatches(String amount, String query) {
  final q = query.trim();
  if (q.isEmpty || !_amountQuery.hasMatch(q)) return const [];
  final digits = q.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return const [];
  final pos = <int>[];
  final buf = StringBuffer();
  for (var i = 0; i < amount.length; i++) {
    if (_digit.hasMatch(amount[i])) {
      pos.add(i);
      buf.write(amount[i]);
    }
  }
  final hay = buf.toString();
  final out = <(int, int)>[];
  var from = 0;
  while (true) {
    final i = hay.indexOf(digits, from);
    if (i < 0) break;
    out.add((pos[i], pos[i + digits.length - 1] + 1));
    from = i + digits.length;
  }
  return out;
}

/// Tách [text] thành các đoạn; đoạn nằm trong [ranges] dùng [mark].
List<TextSpan> highlightSpans(
  String text,
  List<(int, int)> ranges,
  TextStyle mark,
) {
  if (ranges.isEmpty) return [TextSpan(text: text)];
  final spans = <TextSpan>[];
  var at = 0;
  for (final (s, e) in ranges) {
    if (s > at) spans.add(TextSpan(text: text.substring(at, s)));
    spans.add(TextSpan(text: text.substring(s, e), style: mark));
    at = e;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return spans;
}
