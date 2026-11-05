import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency_table.dart';
import '../../ui/tokens.g.dart';

/// Nhãn "VND · ₫" của một mã tiền tệ (mã, kèm ký hiệu nếu khác mã).
String currencyCodeLabel(String code) {
  final symbol = NumberFormat.simpleCurrency(name: code).currencySymbol;
  return symbol == code ? code : '$code · $symbol';
}

/// Hộp thoại chọn tiền tệ, có ô tìm theo mã hoặc tên (AC-53). Trả về mã đã
/// chọn, hoặc null nếu đóng hộp thoại.
Future<String?> showCurrencyPicker(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (context) => CurrencyPickerDialog(current: current),
    );

class CurrencyPickerDialog extends StatefulWidget {
  const CurrencyPickerDialog({super.key, required this.current});

  final String current;

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  final _search = TextEditingController();
  List<CurrencyInfo> _shown = currencyTable;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = l.localeName;
    final height = min(MediaQuery.sizeOf(context).height * 0.8, 600.0);
    return Dialog(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s6,
                VgSpace.s6,
                VgSpace.s6,
                VgSpace.s2,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l.currency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.currencySearchHint,
                  prefixIcon: const Icon(Symbols.search_rounded),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (q) => setState(() => _shown = searchCurrencies(q)),
              ),
            ),
            Expanded(
              // Dòng 0 là ghi chú (cuộn đi được, nhường chỗ cho bàn phím);
              // danh sách dựng lười.
              child: ListView.builder(
                itemCount: _shown.isEmpty ? 2 : _shown.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VgSpace.s6,
                        VgSpace.s3,
                        VgSpace.s6,
                        VgSpace.s2,
                      ),
                      child: Text(
                        l.currencyNote,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  if (_shown.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(VgSpace.s6),
                      child: Text(l.currencyNoMatch),
                    );
                  }
                  final c = _shown[i - 1];
                  final selected = c.code == widget.current;
                  return ListTile(
                    selected: selected,
                    title: Text(currencyCodeLabel(c.code)),
                    subtitle: Text(c.name(lang)),
                    trailing: selected
                        ? const Icon(Symbols.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, c.code),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                VgSpace.s4,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
