import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/entry_filter.dart';
import '../../data/money.dart';
import '../../data/period.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/fields.dart';
import '../../ui/format.dart';
import '../../ui/tokens.g.dart';
import '../home/range_calendar.dart';
import '../settings/budget_dialog.dart' show currencySymbol;

/// Mở bảng "Lọc" (N-04, AC-115) với [initial]; trả về bộ lọc mới khi bấm Áp
/// dụng hoặc Xoá (bộ lọc rỗng), null khi đóng bảng để giữ nguyên.
Future<EntryFilter?> showEntryFilterSheet(
  BuildContext context,
  EntryFilter initial,
) => showModalBottomSheet<EntryFilter>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => EntryFilterSheet(initial: initial),
);

/// Nội dung bảng lọc: khoảng số tiền (từ/đến), danh mục chi + thu chọn nhiều,
/// khoảng ngày (lịch khoảng của kỳ tùy chọn), nút Xoá / Áp dụng. "Từ" lớn
/// hơn "Đến" thì báo lỗi dưới ô "Đến" và chưa đóng bảng.
class EntryFilterSheet extends ConsumerStatefulWidget {
  const EntryFilterSheet({super.key, required this.initial});

  final EntryFilter initial;

  @override
  ConsumerState<EntryFilterSheet> createState() => _EntryFilterSheetState();
}

class _EntryFilterSheetState extends ConsumerState<EntryFilterSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final Set<int> _categories = {...widget.initial.categoryIds};
  DateTime? _from, _to;
  String? _minError, _maxError;

  @override
  void initState() {
    super.initState();
    _from = widget.initial.from;
    _to = widget.initial.to;
    _min = TextEditingController();
    _max = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chữ đặt sẵn theo ngôn ngữ cần context, nên điền một lần ở đây.
    if (_min.text.isEmpty && _max.text.isEmpty && !_filled) {
      _filled = true;
      final digits = _digits;
      final f = widget.initial;
      if (f.minAmount != null) {
        _min.text = amountInput(context, f.minAmount!, digits);
      }
      if (f.maxAmount != null) {
        _max.text = amountInput(context, f.maxAmount!, digits);
      }
    }
  }

  bool _filled = false;

  String get _currency => ref.read(currencyProvider).value ?? 'USD';
  int get _digits => currencyDecimalDigits(_currency);

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  /// Đọc một ô: rỗng là bỏ trống (hợp lệ), chữ sai là lỗi.
  (int?, bool) _read(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return (null, true);
    final v = parseAmountField(context, text, _digits);
    return (v, v != null && v >= 0);
  }

  void _apply() {
    final l = AppLocalizations.of(context);
    final (min, minOk) = _read(_min);
    final (max, maxOk) = _read(_max);
    String? minError, maxError;
    if (!minOk) minError = l.filterAmountInvalid;
    if (!maxOk) maxError = l.filterAmountInvalid;
    if (minOk && maxOk && min != null && max != null && min > max) {
      maxError = l.filterAmountRangeError;
    }
    if (minError != null || maxError != null) {
      setState(() {
        _minError = minError;
        _maxError = maxError;
      });
      return;
    }
    Navigator.pop(
      context,
      EntryFilter(
        minAmount: min,
        maxAmount: max,
        categoryIds: _categories,
        from: _from,
        to: _to,
      ),
    );
  }

  Future<void> _pickDates() async {
    final now = ref.read(clockProvider)();
    final range = await showRangeCalendar(
      context,
      initialStart: _from,
      initialEnd: _to,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
      today: now,
      weekStart: ref.read(weekStartProvider).value ?? DateTime.monday,
    );
    if (range == null || !mounted) return;
    setState(() {
      _from = range.start;
      _to = range.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final large = isLargeText(context);
    final symbol = currencySymbol(_currency);
    Widget amountField(
      TextEditingController c,
      String label,
      String? error,
      String key,
    ) => TextField(
      key: ValueKey(key),
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
      onChanged: (_) {
        if (_minError != null || _maxError != null) {
          setState(() => _minError = _maxError = null);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: symbol,
        errorText: error,
        errorMaxLines: 3,
      ),
    );

    final fields = [
      amountField(_min, l.filterFrom, _minError, 'filter-min'),
      amountField(_max, l.filterTo, _maxError, 'filter-max'),
    ];

    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(0, VgSpace.s4, 0, VgSpace.s2),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleSmall),
      ),
    );

    Widget group(CategoryType type, String title) {
      final list = ref.watch(categoriesProvider(type)).value ?? const [];
      if (list.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: VgSpace.s1),
            child: Text(
              title,
              style: VgType.bodySm.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ScopeMultiChips<int>(
            options: [for (final c in list) (c.id, categoryLabel(l, c))],
            selected: _categories,
            onChanged: (id) => setState(
              () => _categories.contains(id)
                  ? _categories.remove(id)
                  : _categories.add(id),
            ),
          ),
        ],
      );
    }

    final dateText = _from != null && _to != null
        ? periodTitle(context, Period.custom(_from!, _to!))
        : l.filterAnyDate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(l.filter),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label(l.filterAmountRange),
                  if (large)
                    Column(
                      children: [
                        fields[0],
                        const SizedBox(height: VgSpace.s3),
                        fields[1],
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: VgSpace.s3),
                        Expanded(child: fields[1]),
                      ],
                    ),
                  label(l.filterCategories),
                  group(CategoryType.expense, l.expense),
                  const SizedBox(height: VgSpace.s2),
                  group(CategoryType.income, l.income),
                  label(l.filterDateRange),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('filter-dates'),
                          onPressed: _pickDates,
                          icon: const Icon(Symbols.date_range_rounded),
                          label: Text(dateText),
                        ),
                      ),
                      if (_from != null)
                        IconButton(
                          icon: const Icon(Symbols.close_rounded),
                          tooltip: l.filterRemoveDates,
                          onPressed: () => setState(() {
                            _from = null;
                            _to = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: VgSpace.s4),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s6,
              VgSpace.s2,
              VgSpace.s6,
              VgSpace.s4,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: VgSpace.s2,
              runSpacing: VgSpace.s2,
              children: [
                // Chữ `primary` trên nền bảng chỉ 4,34:1 (AC-40): dùng chữ chính.
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context, EntryFilter.none),
                  child: Text(l.filterClear),
                ),
                FilledButton(onPressed: _apply, child: Text(l.apply)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
