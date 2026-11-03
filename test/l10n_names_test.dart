import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/seed.dart';
import 'package:vigon/src/l10n_names.dart';

void main() {
  final keys = [
    'cash',
    ...defaultExpenseCategories.map((c) => c.$1),
    ...defaultIncomeCategories.map((c) => c.$1),
  ];

  for (final locale in AppLocalizations.supportedLocales) {
    test('mọi tên mặc định có bản dịch ${locale.languageCode} (AC-15)', () {
      final l = lookupAppLocalizations(locale);
      for (final key in keys) {
        expect(defaultName(l, key), isNotEmpty, reason: key);
      }
    });
  }

  test('tên tiếng Việt đúng chữ', () {
    final l = lookupAppLocalizations(const Locale('vi'));
    expect(defaultName(l, 'cash'), 'Tiền mặt');
    expect(defaultName(l, 'food'), 'Ăn uống');
  });
}
