// Test thành phần dùng chung theo design-system Hi-Fi v2 (D0, phiên #2):
// sáng/tối, chữ 200%, Semantics, vùng chạm (S-50).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/summary.dart';
import 'package:vigon/src/ui/balance_bar.dart';
import 'package:vigon/src/ui/category_avatar.dart';
import 'package:vigon/src/ui/category_grid.dart';
import 'package:vigon/src/ui/choice_segments.dart';
import 'package:vigon/src/ui/confirm_dialog.dart';
import 'package:vigon/src/ui/dialog.dart';
import 'package:vigon/src/ui/fields.dart';
import 'package:vigon/src/ui/hint.dart';
import 'package:vigon/src/ui/limit_bar.dart';
import 'package:vigon/src/ui/messenger.dart';
import 'package:vigon/src/ui/settings_rows.dart';
import 'package:vigon/src/ui/spending_ring.dart';
import 'package:vigon/src/ui/theme.dart';
import 'package:vigon/src/ui/tokens.g.dart';

import '../helpers.dart';

const _themes = [(Brightness.light, 'sáng'), (Brightness.dark, 'tối')];

/// Dựng [child] trong theme của app, tiếng Việt, màn 360×800, cỡ chữ
/// [textScale]. Dùng messenger chung để thử [showVgSnackBar].
Future<void> pumpUi(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool scroll = false,
}) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(
    MaterialApp(
      scaffoldMessengerKey: rootMessengerKey,
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
      home: Scaffold(
        body: scroll ? SingleChildScrollView(child: child) : child,
      ),
    ),
  );
}

Category _category({int id = 1, String icon = 'restaurant'}) => Category(
  id: id,
  type: CategoryType.expense,
  name: 'Ăn uống',
  icon: icon,
  color: vgCategoryColors[12].toARGB32(),
  sortOrder: 0,
);

const _long =
    'Chưa có quyền gửi thông báo. Hãy bật thông báo cho Ví Gọn trong cài '
    'đặt hệ thống.';

Finder _snackMaterial() => find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  group('thanh thông báo (Feedback.html)', () {
    testWidgets('ngắn: một hàng, nút bên phải, có vạch thời gian; bấm nút '
        'thì đóng và gọi hành động', (tester) async {
      var undo = 0;
      await pumpUi(tester, const SizedBox.expand());
      showUndoSnackBar(
        message: 'Đã xóa',
        undoLabel: 'Hoàn tác',
        onUndo: () => undo++,
      );
      await tester.pumpAndSettle();
      final text = tester.getRect(find.text('Đã xóa'));
      final action = tester.getRect(find.text('Hoàn tác'));
      expect(action.left, greaterThan(text.right));
      expect((action.center.dy - text.center.dy).abs(), lessThan(2));
      expect(find.byKey(const ValueKey('snack-timer')), findsOneWidget);
      expect(tester.getSize(_snackMaterial()).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Hoàn tác')).height,
        greaterThanOrEqualTo(VgSize.tapMin),
      );
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(undo, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('chữ dài thì xếp chồng: nút nằm dưới chữ', (tester) async {
      await pumpUi(tester, const SizedBox.expand());
      showVgSnackBar(
        _long,
        actionLabel: 'Mở cài đặt',
        onAction: () {},
        long: true,
      );
      await tester.pumpAndSettle();
      final text = tester.getRect(find.text(_long));
      final action = tester.getRect(find.text('Mở cài đặt'));
      expect(action.top, greaterThanOrEqualTo(text.bottom));
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.duration, SnackDuration.long);
    });

    testWidgets('chỉ chữ: không có vạch thời gian, 4 giây', (tester) async {
      await pumpUi(tester, const SizedBox.expand());
      showMessage('Đã sao lưu');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('snack-timer')), findsNothing);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).duration,
        SnackDuration.short,
      );
    });

    testWidgets('luôn nằm trên vùng SnackBarClearance (− / +, bàn phím số)', (
      tester,
    ) async {
      await pumpUi(
        tester,
        const Column(
          children: [
            Expanded(child: SizedBox()),
            SnackBarClearance(child: SizedBox(height: 280)),
          ],
        ),
      );
      showUndoSnackBar(message: 'Đã xóa', undoLabel: 'Hoàn tác', onUndo: () {});
      await tester.pumpAndSettle();
      final guard = tester.getRect(find.byType(SnackBarClearance));
      final snack = tester.getRect(_snackMaterial());
      expect(snack.bottom, lessThanOrEqualTo(guard.top));
      expect(guard.top - snack.bottom, lessThan(24));
    });

    for (final (brightness, name) in _themes) {
      testWidgets('chữ 200% không tràn, màu `inverse-surface` ($name)', (
        tester,
      ) async {
        await pumpUi(
          tester,
          const SizedBox.expand(),
          brightness: brightness,
          textScale: 2,
        );
        showVgSnackBar(_long, actionLabel: 'Mở cài đặt', onAction: () {});
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final p = brightness == Brightness.dark ? vgDark : vgLight;
        expect(
          tester.widget<Material>(_snackMaterial()).color,
          p.inverseSurface,
        );
        expect(find.text('Mở cài đặt'), findsOneWidget);
      });
    }
  });

  group('hộp thoại (Dialogs.html)', () {
    Future<Future<bool>> open(
      WidgetTester tester, {
      double textScale = 1,
      Brightness brightness = Brightness.light,
      String body = 'Dữ liệu hiện tại sẽ bị thay thế. Tiếp tục?',
      String? note,
    }) async {
      await pumpUi(
        tester,
        const SizedBox.expand(),
        textScale: textScale,
        brightness: brightness,
      );
      final context = tester.element(find.byType(SizedBox).first);
      final result = showConfirmDialog(
        context,
        title: 'Khôi phục từ bản sao lưu',
        body: body,
        action: 'Xác nhận',
        icon: Symbols.settings_backup_restore_rounded,
        iconTone: VgDialogTone.neutral,
        note: note,
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('loại thường: icon chữ phụ, tiêu đề là header, ghi chú ⓘ', (
      tester,
    ) async {
      final result = await open(
        tester,
        note:
            'Nhắc ghi sổ hằng ngày sẽ tắt. Bạn có thể bật lại trong Cài đặt.',
      );
      final icon = tester.widget<Icon>(
        find.byIcon(Symbols.settings_backup_restore_rounded),
      );
      expect(icon.color, vgLight.inkMuted);
      expect(find.byType(VgHint), findsOneWidget);
      final title = tester.getSemantics(find.text('Khôi phục từ bản sao lưu'));
      expect(title, isSemantics(isHeader: true));
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });

    for (final (brightness, name) in _themes) {
      testWidgets('chữ 200%, thân dài: thân cuộn, nút ghim trong màn, có '
          'vạch ngăn ($name)', (tester) async {
        await open(
          tester,
          textScale: 2,
          brightness: brightness,
          body: List.filled(12, _long).join(' '),
          note: 'Nhắc ghi sổ hằng ngày sẽ tắt.',
        );
        expect(tester.takeException(), isNull);
        final screen = tester.getRect(find.byType(Scaffold));
        for (final label in ['Hủy', 'Xác nhận']) {
          final r = tester.getRect(find.text(label));
          expect(screen.contains(r.center), isTrue, reason: label);
          expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
        }
        expect(
          find.descendant(
            of: find.byType(VgDialog),
            matching: find.byType(Divider),
          ),
          findsOneWidget,
        );
        final body = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(VgDialog),
            matching: find.byType(Scrollable),
          ),
        );
        expect(body.position.maxScrollExtent, greaterThan(0));
        body.position.jumpTo(body.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final hint = tester.getRect(find.byType(VgHint));
        final cancel = tester.getRect(find.text('Hủy'));
        expect(hint.bottom, lessThanOrEqualTo(cancel.top));
        expect(screen.contains(hint.center), isTrue);
      });
    }

    testWidgets('chữ 100%: không có vạch ngăn trên hàng nút', (tester) async {
      await open(tester);
      expect(
        find.descendant(
          of: find.byType(VgDialog),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
    });

    testWidgets('loại form: ô mật khẩu trong thân, nút xóa màu error', (
      tester,
    ) async {
      await pumpUi(tester, const SizedBox.expand());
      final context = tester.element(find.byType(SizedBox).first);
      showDialog<void>(
        context: context,
        builder: (context) => VgDialog(
          title: 'Mật khẩu sao lưu tự động',
          icon: Symbols.backup_rounded,
          tone: VgDialogTone.neutral,
          content: const [
            PasswordField(label: 'Mật khẩu'),
            SizedBox(height: VgSpace.s4),
            PasswordField(label: 'Nhập lại mật khẩu'),
          ],
          actions: [
            VgDialog.cancelButton(context),
            FilledButton(
              style: dangerButtonStyle(context),
              onPressed: () {},
              child: const Text('Bật'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PasswordField), findsNWidgets(2));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('ô nhập (TextFields.html, SearchField.html)', () {
    testWidgets('ô mật khẩu: cao ≥ 56, nút 👁 đọc "Hiện mật khẩu" rồi "Ẩn '
        'mật khẩu", chuyển che/hiện', (tester) async {
      final controller = TextEditingController(text: 'bimat1');
      addTearDown(controller.dispose);
      await pumpUi(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: PasswordField(controller: controller, label: 'Mật khẩu'),
        ),
      );
      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText));
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(56),
      );
      expect(editable().obscureText, isTrue);
      expect(editable().enableSuggestions, isFalse);
      expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
      expect(
        tester.getSize(find.byType(IconButton)),
        const Size.square(VgSize.tapMin),
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(editable().obscureText, isFalse);
      expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
    });

    testWidgets('ô mật khẩu lỗi: viền và chữ màu error', (tester) async {
      await pumpUi(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: PasswordField(
            label: 'Nhập lại mật khẩu',
            errorText: 'Hai mật khẩu không khớp',
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Hai mật khẩu không khớp'));
      final style = text.style ?? const TextStyle();
      final shown = DefaultTextStyle.of(
        tester.element(find.text('Hai mật khẩu không khớp')),
      ).style.merge(style);
      expect(shown.color, vgLight.error);
    });

    testWidgets('ô tìm: viên thuốc ≥ 48 nền surface-container; nút ✕ chỉ hiện '
        'khi có chữ, xóa và giữ con trỏ', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];
      await pumpUi(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: VgSearchField(
            controller: controller,
            hintText: 'Ghi chú, danh mục hoặc số tiền',
            autofocus: true,
            onChanged: changes.add,
          ),
        ),
      );
      final pill = find.descendant(
        of: find.byType(VgSearchField),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(pill.first).height, greaterThanOrEqualTo(48));
      final deco = tester.widget<DecoratedBox>(pill.first).decoration;
      expect((deco as BoxDecoration).color, vgLight.surfaceContainer);
      expect(find.byTooltip('Xóa nội dung tìm'), findsNothing);
      await tester.enterText(find.byType(TextField), 'tiền nhà');
      await tester.pump();
      expect(find.byTooltip('Xóa nội dung tìm'), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa nội dung tìm'));
      await tester.pump();
      expect(controller.text, '');
      expect(changes.last, '');
      expect(find.byTooltip('Xóa nội dung tìm'), findsNothing);
    });

    testWidgets('ô tìm ở chữ 200% không tràn', (tester) async {
      final controller = TextEditingController(text: 'tiền nhà tháng 11');
      addTearDown(controller.dispose);
      await pumpUi(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: VgSearchField(controller: controller, hintText: 'Tìm'),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    for (final (brightness, name) in _themes) {
      testWidgets('chip phạm vi: chọn một, vùng chạm 48, đủ tương phản '
          '($name)', (tester) async {
        var selected = false;
        await pumpUi(
          tester,
          StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: ScopeChips<bool>(
                options: const [
                  (false, 'Tháng 11 năm 2026'),
                  (true, 'Tất cả thời gian'),
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
          brightness: brightness,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(
          tester.getSemantics(find.text('Tháng 11 năm 2026')),
          isSemantics(isSelected: true, hasTapAction: true),
        );
        await tester.tap(find.text('Tất cả thời gian'));
        await tester.pump();
        expect(selected, isTrue);
      });
    }
  });

  group('Cài đặt v2 (SettingsRows.html)', () {
    Widget gallery({
      required bool on,
      required ValueChanged<bool> onChanged,
      VoidCallback? onNav,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsGroupTitle('Bảo mật', first: true),
        SettingsCard(
          children: [
            SettingsSwitchRow(
              icon: Symbols.widgets_rounded,
              title: 'Hiện số tiền trên widget',
              subtitle:
                  'Ai cầm máy cũng nhìn thấy số này trên màn hình chờ. Khi '
                  'đang bật khóa PIN, widget luôn ẩn số.',
              value: on,
              onChanged: onChanged,
              footer: const StatusPill(
                icon: Symbols.lock_rounded,
                label: 'Đã khóa bằng PIN',
              ),
            ),
            SettingsNavRow(
              icon: Symbols.savings_rounded,
              title: 'Ngân sách tháng',
              value: '12.000.000 ₫',
              onTap: onNav ?? () {},
            ),
            SettingsNavRow(
              icon: Symbols.event_repeat_rounded,
              title: 'Khoản định kỳ',
              onTap: () {},
            ),
            SettingsSegmentRow(
              icon: Symbols.view_week_rounded,
              title: 'Ngày đầu tuần',
              segments: ChoiceSegments<int>(
                options: const [(1, 'Thứ Hai'), (7, 'Chủ Nhật')],
                selected: 1,
                onChanged: (_) {},
              ),
            ),
            SettingsNavRow(
              icon: Symbols.delete_forever_rounded,
              title: 'Xóa toàn bộ dữ liệu',
              danger: true,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: SettingsCard.gap),
        const SettingsCard(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsStatusLine(
                    status: SettingsStatus.idle,
                    text: 'Chưa sao lưu lần nào',
                  ),
                  SettingsStatusLine(
                    status: SettingsStatus.ok,
                    text: 'Lần cuối: 25 thg 11, 21:04',
                  ),
                  SettingsStatusLine(
                    status: SettingsStatus.error,
                    text:
                        'Lần thử 26 thg 11, 08:12: Không ghi được vào thư mục. '
                        'Chọn lại thư mục',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    for (final (brightness, name) in _themes) {
      testWidgets('thẻ nhóm surface-container-low, dải lỗi error-container, '
          'đủ tương phản và vùng chạm ($name)', (tester) async {
        await pumpUi(
          tester,
          gallery(on: true, onChanged: (_) {}),
          brightness: brightness,
          scroll: true,
        );
        final p = brightness == Brightness.dark ? vgDark : vgLight;
        final card = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(SettingsCard).first,
                matching: find.byType(Material),
              )
              .first,
        );
        expect(card.color, p.surfaceContainerLow);
        final strip = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.textContaining('Không ghi được'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((strip.decoration as BoxDecoration).color, p.errorContainer);
        final error = tester.widget<Text>(
          find.textContaining('Không ghi được'),
        );
        expect(error.style!.color, p.onErrorContainer);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }

    testWidgets('hàng công tắc: chạm cả hàng để bật/tắt; đọc tên + phụ đề + '
        'trạng thái trong một nút', (tester) async {
      var on = false;
      await pumpUi(
        tester,
        StatefulBuilder(
          builder: (context, setState) =>
              gallery(on: on, onChanged: (v) => setState(() => on = v)),
        ),
        scroll: true,
      );
      final row = find.ancestor(
        of: find.text('Hiện số tiền trên widget'),
        matching: find.byType(InkWell),
      );
      expect(
        tester.getSize(find.byType(SettingsSwitchRow)).height,
        greaterThanOrEqualTo(VgSize.rowTwoLine),
      );
      final node = tester.getSemantics(row.first);
      expect(node.label, contains('Hiện số tiền trên widget'));
      expect(node.label, contains('Ai cầm máy'));
      expect(node, isSemantics(hasToggledState: true, isToggled: false));
      await tester.tap(find.text('Hiện số tiền trên widget'));
      await tester.pump();
      expect(on, isTrue);
    });

    testWidgets('hàng giá trị cao ≥ 72, hàng không phụ đề ≥ 56, hàng xóa không '
        'có mũi tên, chữ màu error', (tester) async {
      await pumpUi(tester, gallery(on: false, onChanged: (_) {}), scroll: true);
      double h(String t) => tester
          .getSize(
            find.ancestor(
              of: find.text(t),
              matching: find.byType(SettingsNavRow),
            ),
          )
          .height;
      expect(h('Ngân sách tháng'), greaterThanOrEqualTo(VgSize.rowTwoLine));
      expect(h('Khoản định kỳ'), greaterThanOrEqualTo(VgSize.tapKey));
      final danger = find.ancestor(
        of: find.text('Xóa toàn bộ dữ liệu'),
        matching: find.byType(SettingsNavRow),
      );
      expect(
        find.descendant(
          of: danger,
          matching: find.byIcon(Symbols.chevron_right_rounded),
        ),
        findsNothing,
      );
      expect(
        tester.widget<Text>(find.text('Xóa toàn bộ dữ liệu')).style!.color,
        vgLight.error,
      );
      expect(
        tester.getSemantics(find.text('Lần cuối: 25 thg 11, 21:04')),
        isSemantics(isLiveRegion: true),
      );
    });

    testWidgets('chữ 200%: không tràn, nút chọn một xếp dọc', (tester) async {
      await pumpUi(
        tester,
        gallery(on: true, onChanged: (_) {}),
        textScale: 2,
        scroll: true,
      );
      expect(tester.takeException(), isNull);
      final monday = tester.getRect(find.text('Thứ Hai'));
      final sunday = tester.getRect(find.text('Chủ Nhật'));
      expect(sunday.top, greaterThan(monday.bottom));
    });

    testWidgets('nút tông nhẹ và nút viền theo token; nhãn bận có vòng quay', (
      tester,
    ) async {
      await pumpUi(
        tester,
        ButtonPair(
          children: [
            FilledButton.tonal(
              onPressed: null,
              child: const BusyButtonLabel(label: 'Đang xử lý', busy: true),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const BusyButtonLabel(
                label: 'Chọn lại thư mục',
                icon: Symbols.folder_open_rounded,
              ),
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Sao lưu ngay'),
            ),
          ],
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final tonal = find.ancestor(
        of: find.text('Sao lưu ngay'),
        matching: find.byType(Material),
      );
      expect(
        tester.widget<Material>(tonal.first).color,
        vgLight.secondaryContainer,
      );
      final outline = find.ancestor(
        of: find.text('Chọn lại thư mục'),
        matching: find.byType(Material),
      );
      final shape = tester.widget<Material>(outline.first).shape!;
      expect((shape as OutlinedBorder).side.color, vgLight.outline);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group('màn chính v2 (ChartRing.html)', () {
    final food = _category();
    final summary = PeriodSummary(
      income: 19500000,
      expense: 15240000,
      expenseByCategory: [CategoryTotal(food, 15240000, 100)],
      incomeByCategory: const [],
    );

    for (final (brightness, name) in _themes) {
      testWidgets('vòng có nhãn "Thu" / "Chi" ở giữa ($name)', (tester) async {
        await pumpUi(
          tester,
          Center(
            child: SizedBox.square(
              dimension: 214,
              child: SpendingRing(summary: summary, currency: 'VND'),
            ),
          ),
          brightness: brightness,
        );
        final p = brightness == Brightness.dark ? vgDark : vgLight;
        for (final label in ['Thu', 'Chi']) {
          expect(
            tester.widget<Text>(find.text(label)).style!.color,
            p.inkMuted,
          );
        }
        final thu = tester.getRect(find.text('Thu'));
        final chi = tester.getRect(find.text('Chi'));
        expect(chi.top, greaterThan(thu.bottom));
      });
    }

    testWidgets('thanh Số dư: tên kỳ dưới "Số dư", đọc cả hai, cao ≥ 56, '
        'chạm được, 200% không tràn', (tester) async {
      var taps = 0;
      for (final scale in [1.0, 2.0]) {
        await pumpUi(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: BalanceBar(
              amount: '4.260.000 ₫',
              periodTitle: 'Tháng 11 năm 2026',
              onTap: () => taps++,
            ),
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        final balance = tester.getRect(find.text('Số dư'));
        final period = tester.getRect(find.text('Tháng 11 năm 2026'));
        expect(period.top, greaterThanOrEqualTo(balance.bottom));
        expect(
          tester.getSize(find.byType(BalanceBar)).height,
          greaterThanOrEqualTo(VgSize.tapKey),
        );
      }
      expect(
        find.bySemanticsLabel('Số dư: 4.260.000 ₫, Tháng 11 năm 2026'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BalanceBar));
      expect(taps, 1);
    });

    testWidgets('ô ⋯ "Danh mục khác": viền nét đứt `outline`, nền `surface`, '
        'đọc tên, vùng chạm 48', (tester) async {
      var taps = 0;
      await pumpUi(
        tester,
        Center(child: MoreCategoriesAvatar(onTap: () => taps++)),
      );
      final paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(MoreCategoriesAvatar),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(paint.foregroundPainter, isA<DashedCirclePainter>());
      expect(
        (paint.foregroundPainter! as DashedCirclePainter).color,
        vgLight.outline,
      );
      await tester.tap(find.bySemanticsLabel('Danh mục khác'));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('icon danh mục 40/48: vòng chọn màu chữ chính, đọc "đã chọn"', (
      tester,
    ) async {
      await pumpUi(
        tester,
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryAvatar(
                category: _category(),
                selected: true,
                semanticLabel: 'Ăn uống',
                onTap: () {},
              ),
              const SizedBox(width: 24),
              CategoryAvatar(
                category: _category(id: 2, icon: 'home'),
                size: 40,
                semanticLabel: 'Nhà cửa',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      final ring = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is SelectedRingPainter,
      );
      expect(ring, findsOneWidget);
      expect(
        (tester.widget<CustomPaint>(ring).foregroundPainter!
                as SelectedRingPainter)
            .color,
        vgLight.ink,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ăn uống')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSize(find.byType(CategoryAvatar).last),
        const Size.square(40),
      );
    });

    testWidgets('thanh hạn mức: vượt thì ⚠ + chữ error đậm + thanh đầy; chưa '
        'vượt không có ⚠', (tester) async {
      await pumpUi(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              LimitBar(text: 'Vượt 240.000 ₫', progress: 1.08, over: true),
              SizedBox(height: 16),
              LimitBar(
                text: 'Tháng này: Đã chi 1.450.000 ₫ / 2.000.000 ₫',
                progress: 0.725,
                over: false,
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Symbols.warning_rounded), findsOneWidget);
      final over = tester.widget<Text>(find.text('Vượt 240.000 ₫'));
      expect(over.style!.color, vgLight.error);
      expect(over.style!.fontWeight, FontWeight.w600);
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.first.value, 1);
      expect(bars.first.color, vgLight.error);
      expect(bars.last.value, closeTo(0.725, 1e-9));
      expect(bars.last.minHeight, 4);
      expect(
        find.bySemanticsLabel('Tháng này: Đã chi 1.450.000 ₫ / 2.000.000 ₫'),
        findsOneWidget,
      );
    });
  });
}
