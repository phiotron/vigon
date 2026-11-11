import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/account_repository.dart';

import '../helpers.dart';

/// D-037 + bố cục A001: Cài đặt gom Tiền tệ chính + Tỷ giá, màn Tỷ giá có
/// cặp đang dùng dạng "1 USD → … VND" và sheet ghi đè có công tắc tự động.
void main() {
  testWidgets('Cài đặt gom tiền tệ, màn Tỷ giá và sheet ghi đè', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    // Thêm tài khoản USD để có cặp đang dùng (mặc định mọi thứ là VND).
    await tester.runAsync(
      () => AccountRepository(db).add(name: 'Tài khoản USD', currency: 'USD'),
    );
    await settle(tester);

    // Cài đặt: hai hàng tiền tệ nằm cùng nhóm, hàng Tỷ giá có tóm tắt.
    await tester.tap(find.byTooltip('Cài đặt'));
    await settle(tester);
    // Nhóm Kế hoạch dài thêm hai hàng F-37: cuộn tới từng dòng của nhóm.
    for (final text in ['Tiền tệ & kỳ', 'Tiền tệ chính', 'Tỷ giá']) {
      await tester.scrollUntilVisible(
        find.text(text),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await settle(tester);
      expect(find.text(text), findsOneWidget);
    }

    // Màn Tỷ giá.
    await tester.ensureVisible(find.text('Tỷ giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tỷ giá'));
    await settle(tester);

    expect(find.textContaining('Số dư và tổng quy về VND'), findsOneWidget);
    expect(find.textContaining('1 USD', findRichText: true), findsOneWidget);
    expect(find.text('Cập nhật ngay'), findsOneWidget);

    // Sheet ghi đè: công tắc tự động + nút Xong.
    await tester.tap(find.textContaining('1 USD', findRichText: true));
    await settle(tester);
    expect(find.text('Dùng tỷ giá tự động'), findsOneWidget);
    expect(find.text('Xong'), findsOneWidget);

    // Tắt tự động: hiện ô tỷ giá và nút lưu.
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Tỷ giá của bạn · 1 USD ='), findsOneWidget);
    expect(find.text('Lưu tỷ giá này'), findsOneWidget);
  });
}
