import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigon/src/data/account_repository.dart';
import 'package:vigon/src/data/database.dart';

import '../helpers.dart';

/// Chặn lỗi hiển thị với tài khoản đã ẩn do kiểm chứng độc lập tìm ra (B3, B5).
void main() {
  Future<(AppDatabase, int, int)> setup(WidgetTester tester) async {
    final db = memoryDatabase();
    final card = await tester.runAsync(
      () => AccountRepository(db).add(name: 'Thẻ', initialBalance: 0),
    );
    await pumpApp(tester, db: db);
    final transferId = await insertEntry(
      tester,
      db,
      type: EntryType.transfer,
      amount: 50000,
      accountId: 1,
      toAccountId: card,
      note: 'Gửi thẻ',
    );
    await tester.runAsync(() => AccountRepository(db).archive(card!));
    await settle(tester);
    return (db, card!, transferId);
  }

  testWidgets('tìm kiếm hiện đủ tên tài khoản đã ẩn của khoản chuyển tiền', (
    tester,
  ) async {
    final (db, _, _) = await setup(tester);
    await tester.tap(find.byTooltip('Các khoản'));
    await settle(tester);
    await tester.tap(find.byTooltip('Tìm'));
    await settle(tester);
    expect(find.text('Tiền mặt → Thẻ'), findsOneWidget);
    await disposeApp(tester, db);
  });

  testWidgets('mở khoản chuyển tiền cũ vẫn xem và sửa được khi chỉ còn một '
      'tài khoản hiện', (tester) async {
    final (db, _, transferId) = await setup(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push('/transfer/$transferId');
    await settle(tester);
    // Có đủ ô Từ, Đến và bàn phím, không phải màn trống.
    expect(find.text('Từ'), findsOneWidget);
    expect(find.text('Đến'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    await disposeApp(tester, db);
  });
}
