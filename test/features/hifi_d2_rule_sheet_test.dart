import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/recurring/rule_sheet.dart';
import 'package:vigon/src/ui/settings_rows.dart' show StatusPill;
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/tokens.g.dart';

import '../helpers.dart';

/// SCR-21: bảng sửa chuỗi định kỳ toàn màn (Hi-Fi D2).

const _rule = RecurringRule(
  id: 1,
  type: EntryType.expense,
  amount: 3500000,
  categoryId: 3,
  accountId: 1,
  note: 'Tiền nhà',
  frequency: RecurrenceFrequency.monthly,
  startDate: '2026-10-01',
  lastGeneratedDate: '2026-11-01',
  active: true,
  currency: 'VND',
);

final _home = Category(
  id: 3,
  type: CategoryType.expense,
  name: 'Nhà cửa',
  icon: 'home',
  color: vgCategoryColors[8].toARGB32(),
  sortOrder: 0,
);

const _cash = Account(
  id: 1,
  name: 'Tiền mặt',
  initialBalance: 0,
  sortOrder: 0,
  archived: false,
  currency: 'VND',
);
const _card = Account(
  id: 2,
  name: 'Thẻ',
  initialBalance: 0,
  sortOrder: 1,
  archived: false,
  currency: 'VND',
);

/// Mở bảng bằng nút trên màn trống; [result] nhận giá trị trả về.
Future<void> _open(
  WidgetTester tester, {
  RecurringRule rule = _rule,
  List<Account> accounts = const [_cash, _card],
  Brightness brightness = Brightness.light,
  double textScale = 1,
  void Function(RuleEdit?)? result,
}) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final r = await showRuleSheet(
                  context,
                  rule: rule,
                  categories: [_home],
                  accounts: accounts,
                );
                result?.call(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final (brightness, name) in [
    (Brightness.light, 'sáng'),
    (Brightness.dark, 'tối'),
  ]) {
    testWidgets('đang chạy ($name): ✕, đầu chuỗi chỉ đọc, chip, 2 ô chọn, '
        'Hủy/Lưu ghim đáy', (tester) async {
      await _open(tester, brightness: brightness);
      expect(find.byTooltip('Hủy'), findsOneWidget);
      expect(find.text('Khoản định kỳ'), findsOneWidget);
      expect(find.text('Tiền nhà'), findsWidgets); // tên chuỗi + ô Ghi chú
      expect(find.textContaining('Hằng tháng ·'), findsOneWidget);
      expect(find.byType(StatusPill), findsNothing);
      for (final f in RecurrenceFrequency.values) {
        expect(find.byKey(ValueKey('rule-frequency-${f.name}')), findsOne);
      }
      expect(find.byKey(const Key('rule-category')), findsOneWidget);
      expect(find.byKey(const Key('rule-account')), findsOneWidget);
      // Chip đang chọn có ✓ và nền secondary-container.
      final scheme = Theme.of(tester.element(find.text('open'))).colorScheme;
      final selected = tester.widget<Material>(
        find
            .descendant(
              of: find.byKey(const ValueKey('rule-frequency-monthly')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(selected.color, scheme.secondaryContainer);
      // Hủy / Lưu nằm cùng hàng ở đáy màn.
      final save = tester.getCenter(find.text('Lưu'));
      final cancel = tester.getCenter(find.text('Hủy').last);
      expect(save.dy, closeTo(cancel.dy, 1));
      expect(save.dy, greaterThan(700));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  testWidgets('đổi tần suất thì hiện gợi ý bắt đầu lại (A12); đổi về thì ẩn', (
    tester,
  ) async {
    await _open(tester);
    final hint = find.textContaining('Bắt đầu lại từ lần đến hạn kế tiếp');
    expect(hint, findsNothing);
    await tester.tap(find.byKey(const ValueKey('rule-frequency-weekly')));
    await tester.pump();
    expect(hint, findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing); // dùng Symbols, không Icons
    await tester.tap(find.byKey(const ValueKey('rule-frequency-monthly')));
    await tester.pump();
    expect(hint, findsNothing);
  });

  testWidgets('số tiền ≤ 0 báo lỗi dưới ô, Lưu vẫn bấm được; đúng thì trả kết '
      'quả', (tester) async {
    RuleEdit? got;
    await _open(tester, result: (r) => got = r);
    await tester.enterText(find.byKey(const Key('rule-amount')), '0');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Số tiền phải lớn hơn 0'), findsOneWidget);
    expect(got, isNull);
    await tester.enterText(find.byKey(const Key('rule-amount')), '120000');
    await tester.tap(find.byKey(const ValueKey('rule-frequency-yearly')));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(got?.amount, 120000);
    expect(got?.frequency, RecurrenceFrequency.yearly);
    expect(got?.categoryId, 3);
  });

  testWidgets(
    'đã dừng + chỉ một tài khoản: pill "Đã dừng", không ô Tài khoản',
    (tester) async {
      await _open(
        tester,
        rule: _rule.copyWith(active: false),
        accounts: const [_cash],
      );
      expect(find.byType(StatusPill), findsOneWidget);
      expect(find.byKey(const Key('rule-account')), findsNothing);
    },
  );

  testWidgets('✕ đóng không trả gì', (tester) async {
    var called = false;
    RuleEdit? got;
    await _open(
      tester,
      result: (r) {
        called = true;
        got = r;
      },
    );
    await tester.tap(find.byTooltip('Hủy'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    expect(got, isNull);
  });

  testWidgets('chữ 200%: không tràn, nút đáy xếp dọc, thân cuộn tới ô Tài '
      'khoản', (tester) async {
    await _open(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    final save = tester.getCenter(find.text('Lưu'));
    final cancel = tester.getCenter(find.text('Hủy').last);
    expect(save.dy, greaterThan(cancel.dy));
    await tester.scrollUntilVisible(
      find.byKey(const Key('rule-account')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
}
