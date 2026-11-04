import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency_table.dart';

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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                l.currency,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l.currencySearchHint,
                  prefixIcon: const Icon(Icons.search),
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
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Text(l.currencyNote),
                    );
                  }
                  if (_shown.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.currencyNoMatch),
                    );
                  }
                  final c = _shown[i - 1];
                  final selected = c.code == widget.current;
                  return ListTile(
                    selected: selected,
                    title: Text(currencyCodeLabel(c.code)),
                    subtitle: Text(c.name(lang)),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, c.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
