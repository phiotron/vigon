import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency_table.dart';
import '../../ui/fields.dart';
import '../../ui/tokens.g.dart';

/// Nhãn "VND · ₫" của một mã tiền tệ (mã, kèm ký hiệu nếu khác mã).
String currencyCodeLabel(String code) {
  final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
  return symbol == code ? code : '$code · $symbol';
}

/// Chọn tiền tệ (AC-53, SCR-13, §10.1 #15): sheet toàn màn, ✕ = giữ nguyên.
/// Trả về mã đã chọn, hoặc null nếu đóng.
Future<String?> showCurrencyPicker(BuildContext context, String current) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CurrencyPickerSheet(current: current),
    );

class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({super.key, required this.current});

  final String current;

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  final _search = TextEditingController();
  List<CurrencyInfo> _shown = currenciesByCode;
  bool _noteOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _searching => _search.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lang = l.localeName;
    final query = _search.text.trim();
    final current = currencyInfo(widget.current);
    final showPinned = !_searching && current != null;

    // Ô tìm trên nền sheet (`surface-container`) dùng `surface-container-high`
    // như frame; component lấy `surfaceContainer` nên đổi màu qua Theme.
    final search = Theme(
      data: theme.copyWith(
        colorScheme: scheme.copyWith(
          surfaceContainer: scheme.surfaceContainerHigh,
        ),
      ),
      child: VgSearchField(
        controller: _search,
        hintText: l.currencySearchHint,
        searchIcon: true,
        onChanged: (q) => setState(() => _shown = searchCurrencies(q)),
      ),
    );

    Widget note() => Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Symbols.info_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: VgSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.currencyNote,
                  maxLines: _noteOpen ? null : 2,
                  overflow: _noteOpen ? null : TextOverflow.ellipsis,
                  style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
                ),
                Semantics(
                  expanded: _noteOpen,
                  child: TextButton.icon(
                    // `primary` trên nền sheet chỉ 4,34:1 (ngoại lệ CHANGELOG
                    // token: không dùng cho chữ) → `onPrimaryContainer`, vẫn
                    // tông xanh, đạt 4,5:1 cả sáng lẫn tối.
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onPrimaryContainer,
                      padding: EdgeInsets.zero,
                      // Vùng chạm 48 (S-31); `VisualDensity.compact` làm còn 40.
                      minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
                      textStyle: VgType.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    onPressed: () => setState(() => _noteOpen = !_noteOpen),
                    icon: Icon(
                      _noteOpen
                          ? Symbols.expand_less_rounded
                          : Symbols.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(_noteOpen ? l.showLess : l.showMore),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    Widget pinned() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s8,
            VgSpace.s2,
            VgSpace.s8,
            VgSpace.s1,
          ),
          child: Text(
            l.currencyCurrent,
            style: VgType.labelMd.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s4,
            0,
            VgSpace.s4,
            VgSpace.s2,
          ),
          child: Material(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(VgRadius.md),
            clipBehavior: Clip.antiAlias,
            child: CurrencyRow(
              info: current!,
              language: lang,
              selected: true,
              onTap: () => Navigator.pop(context, current.code),
            ),
          ),
        ),
        Divider(height: VgSpace.s2 + 1, color: scheme.outlineVariant),
      ],
    );

    // Dòng 0 là ghi chú, dòng 1 là tiền tệ đang dùng (ẩn khi đang tìm, A09);
    // danh sách dựng lười.
    final head = showPinned ? 2 : 1;
    final list = ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: VgSpace.s6),
      itemCount: head + (_shown.isEmpty ? 1 : _shown.length),
      itemBuilder: (context, i) {
        if (i == 0) return note();
        if (showPinned && i == 1) return pinned();
        if (_shown.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Icon(
                  Symbols.search_off_rounded,
                  size: 40,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: VgSpace.s3),
                Text(l.currencyNoMatch, style: VgType.bodyMd),
              ],
            ),
          );
        }
        final c = _shown[i - head];
        return CurrencyRow(
          info: c,
          language: lang,
          query: query,
          selected: _searching && c.code == widget.current,
          onTap: () => Navigator.pop(context, c.code),
        );
      },
    );

    final height = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(
                  top: VgSpace.s3,
                  bottom: VgSpace.s2,
                ),
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(VgRadius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s1,
                0,
                VgSpace.s2,
                VgSpace.s1,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l.cancel,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Symbols.close_rounded),
                  ),
                  const SizedBox(width: VgSpace.s1),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l.currency, style: VgType.titleMd),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                0,
                VgSpace.s4,
                VgSpace.s3,
              ),
              child: search,
            ),
            Expanded(child: list),
          ],
        ),
      ),
    );
  }
}

/// Một dòng tiền tệ (SCR-13): "{MÃ} · {ký hiệu}" rồi tên tiền tệ là phụ đề
/// (A09), cao tối thiểu 72; đang dùng thì có ✓ `primary` và đọc "đã chọn".
/// Có [query] thì phần khớp được tô `primary-container` đậm 600.
class CurrencyRow extends StatelessWidget {
  const CurrencyRow({
    super.key,
    required this.info,
    required this.language,
    required this.onTap,
    this.query = '',
    this.selected = false,
  });

  final CurrencyInfo info;
  final String language;
  final VoidCallback onTap;
  final String query;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = currencyCodeLabel(info.code);
    final name = info.name(language);
    final digits = const TextStyle(
      fontFamily: vgFontFamily,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VgSize.rowTwoLine),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VgSpace.s4,
                vertical: VgSpace.s2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Highlighted(
                          label,
                          query: query,
                          style: VgType.bodyMd
                              .merge(digits)
                              .copyWith(color: scheme.onSurface),
                        ),
                        _Highlighted(
                          name,
                          query: query,
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: VgSpace.s2),
                    Icon(Symbols.check_rounded, color: scheme.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chữ có tô phần khớp với [query] (không phân biệt hoa thường, dấu). Chỉ tô
/// khi bỏ dấu không đổi độ dài chuỗi (chữ Việt dựng sẵn), để vị trí khớp đúng.
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, {required this.query, required this.style});

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final q = foldForSearch(query);
    final folded = foldForSearch(text);
    final at = q.isEmpty || folded.length != text.length
        ? -1
        : folded.indexOf(q);
    if (at < 0) return Text(text, style: style);
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: text.substring(at, at + q.length),
            style: TextStyle(
              backgroundColor: scheme.primaryContainer,
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: text.substring(at + q.length)),
        ],
      ),
    );
  }
}
