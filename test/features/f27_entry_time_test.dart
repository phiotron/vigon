import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/entry_repository.dart';
import 'package:vigon/src/data/period.dart';
import 'package:vigon/src/features/settings/data_actions.dart';

import '../helpers.dart';
import 'entry_flow_test.dart' show typeKeys;

final _at1435 = DateTime(2026, 11, 3, 14, 35);

void main() {
  group('F-27 · màn Nhập khoản', () {
    testWidgets('khoản mới mặc định giờ lúc mở màn, lưu đúng giờ (AC-74)', (
      tester,
    ) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, clock: () => _at1435);
      await tester.tap(find.byTooltip('Thêm khoản chi'));
      await settle(tester);
      expect(find.text('14:35'), findsOneWidget);
      await typeKeys(tester, '20');
      await tester.tap(find.text('Chọn danh mục'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống'));
      await settle(tester);
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.time, '14:35');
      await disposeApp(tester, db);
    });

    testWidgets('đổi giờ bằng bộ chọn giờ rồi lưu; đổi ngày không đổi giờ', (
      tester,
    ) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, clock: () => _at1435);
      await tester.tap(find.byTooltip('Thêm khoản chi'));
      await settle(tester);
      await tester.tap(find.byTooltip('Giờ'));
      await settle(tester);
      // Bộ chọn giờ hệ thống; chuyển sang chế độ nhập số.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await settle(tester);
      final fields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '07');
      await tester.enterText(fields.at(1), '05');
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(find.text('07:05'), findsOneWidget);
      await typeKeys(tester, '15');
      await tester.tap(find.text('Chọn danh mục'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống'));
      await settle(tester);
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.time, '07:05');
      expect(rows.single.date, '2026-11-03');
      await disposeApp(tester, db);
    });

    testWidgets('máy dùng 12 giờ thì giờ hiện theo 12 giờ, vẫn lưu HH:mm '
        '(AC-74)', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, localeCode: 'en', clock: () => _at1435);
      await tester.tap(find.byTooltip('Add expense'));
      await settle(tester);
      expect(find.text('14:35'), findsNothing);
      expect(find.textContaining('2:35'), findsOneWidget);
      await typeKeys(tester, '20');
      await tester.tap(find.text('Choose category'));
      await settle(tester);
      await tester.tap(find.text('Food'));
      await settle(tester);
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.time, '14:35');
      await disposeApp(tester, db);
    });

    testWidgets('khoản cũ chưa có giờ: màn sửa hiện "Chưa đặt giờ", lưu mà '
        'không đặt thì vẫn không giờ (AC-75)', (tester) async {
      final db = await pumpApp(tester, clock: () => _at1435);
      final id = await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 50000,
        categoryId: 1,
        note: 'phở',
      );
      await tester.tap(find.byTooltip('Các khoản'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống'));
      await settle(tester);
      await tester.tap(find.text('phở'));
      await settle(tester);
      expect(find.text('Chưa đặt giờ · Đặt giờ'), findsOneWidget);
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      final e = await tester.runAsync(() => EntryRepository(db).find(id));
      expect(e!.time, isNull);
      await disposeApp(tester, db);
    });

    testWidgets('sửa khoản có giờ: màn sửa hiện giờ đã lưu và giữ nguyên khi '
        'lưu (AC-74)', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, clock: () => _at1435);
      final id = await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 50000,
        categoryId: 1,
        note: 'cà phê',
        time: '12:02',
      );
      await tester.tap(find.byTooltip('Các khoản'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống'));
      await settle(tester);
      await tester.tap(find.text('cà phê'));
      await settle(tester);
      expect(find.text('12:02'), findsOneWidget);
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      final e = await tester.runAsync(() => EntryRepository(db).find(id));
      expect(e!.time, '12:02');
      await disposeApp(tester, db);
    });

    testWidgets('màn Chuyển tiền có ô Giờ, mặc định giờ lúc mở, lưu cùng '
        'lần chuyển (AC-74)', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, clock: () => _at1435);
      await tester.runAsync(
        () =>
            AccountRepository(db)
                .add(name: 'Thẻ', initialBalance: 0, currency: 'VND'),
      );
      await settle(tester);
      await tester.tap(find.byTooltip('Cài đặt'));
      await settle(tester);
      await tester.tap(find.text('Tài khoản'));
      await settle(tester);
      await tester.tap(find.byTooltip('Chuyển tiền'));
      await settle(tester);
      expect(find.text('14:35'), findsOneWidget);
      await typeKeys(tester, '90');
      await tester.tap(find.text('Lưu'));
      await settle(tester);
      final rows = await tester.runAsync(() => db.select(db.entries).get());
      expect(rows!.single.type, EntryType.transfer);
      expect(rows.single.time, '14:35');
      await disposeApp(tester, db);
    });
  });

  group('F-27 · Các khoản xếp theo giờ (AC-76)', () {
    testWidgets('trong ngày: có giờ trước (mới nhất trước), rồi không giờ '
        '(mới trước); ngày vẫn xếp trước giờ', (tester) async {
      final db = await pumpApp(tester, clock: () => _at1435);
      Future<int> add(String date, String? time, int amount) => insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: amount,
        categoryId: 1,
        date: date,
        time: time,
      );
      final noTimeOld = await add('2026-11-03', null, 1);
      final t0800 = await add('2026-11-03', '08:00', 2);
      final noTimeNew = await add('2026-11-03', null, 3);
      final t1202 = await add('2026-11-03', '12:02', 4);
      final yesterday = await add('2026-11-02', '23:59', 5);
      final period = Period.containing(PeriodType.month, _at1435);
      final rows = await tester.runAsync(
        () => EntryRepository(db).watchEntries(period).first,
      );
      expect(rows!.map((v) => v.entry.id).toList(), [
        t1202,
        t0800,
        noTimeNew,
        noTimeOld,
        yesterday,
      ]);
      await disposeApp(tester, db);
    });

    testWidgets('dòng khoản có giờ hiện giờ cạnh tên tài khoản; khoản không '
        'giờ chỉ hiện ngày', (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final db = await pumpApp(tester, clock: () => _at1435);
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 50000,
        categoryId: 1,
        note: 'cà phê',
        time: '12:02',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 30000,
        categoryId: 1,
        note: 'bánh',
      );
      await insertEntry(
        tester,
        db,
        type: EntryType.expense,
        amount: 20000,
        categoryId: 1,
        note: 'nước',
        time: '18:30',
      );
      await tester.tap(find.byTooltip('Các khoản'));
      await settle(tester);
      await tester.tap(find.text('Ăn uống'));
      await settle(tester);
      expect(find.text('Hôm nay · Tiền mặt · 12:02'), findsOneWidget);
      expect(find.text('Hôm nay · Tiền mặt · 18:30'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget); // "bánh", không giờ
      // Thứ tự từ trên xuống: 18:30, 12:02, rồi khoản không giờ.
      double y(String note) => tester.getTopLeft(find.text(note)).dy;
      expect(y('nước'), lessThan(y('cà phê')));
      expect(y('cà phê'), lessThan(y('bánh')));
      await disposeApp(tester, db);
    });
  });

  group('F-27 · CSV có hai cột Giờ và Nguồn (AC-124)', () {
    Future<String> csvOf(String locale) async {
      final l = await AppLocalizations.delegate.load(Locale(locale));
      final entries = [
        Entry(
          id: 1,
          type: EntryType.expense,
          amount: 50000,
          categoryId: 1,
          accountId: 1,
          date: '2026-11-03',
          time: '12:02',
          note: 'a',
          source: EntrySource.emailMb,
          createdAt: DateTime(2026, 11, 3),
          currency: 'VND',
        ),
        Entry(
          id: 2,
          type: EntryType.expense,
          amount: 10000,
          categoryId: 1,
          accountId: 1,
          date: '2026-11-03',
          note: 'b',
          source: EntrySource.manual,
          createdAt: DateTime(2026, 11, 3),
          currency: 'VND',
        ),
      ];
      return exportCsv(
        entries: entries,
        currency: 'VND',
        decimalDigits: 0,
        format: csvFormatFor(l),
        categoryName: (_) => 'Ăn uống',
        accountName: (_) => 'Tiền mặt',
      );
    }

    test('tiếng Việt', () async {
      final lines = (await csvOf('vi')).split(RegExp(r'\r?\n'));
      expect(lines.first, endsWith('Ghi chú;Giờ;Nguồn'));
      expect(lines[1], endsWith(';a;12:02;Email MB'));
      expect(lines[2], endsWith(';b;;Ghi tay'));
    });

    test('tiếng Anh', () async {
      final lines = (await csvOf('en')).split(RegExp(r'\r?\n'));
      expect(lines.first, endsWith('note,Time,Source'));
      expect(lines[1], endsWith(',a,12:02,MB email'));
      expect(lines[2], endsWith(',b,,Manual'));
    });
  });
}
