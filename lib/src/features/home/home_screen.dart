import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/period.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/balance_bar.dart';
import '../../ui/category_avatar.dart';
import '../../ui/category_grid.dart';
import '../../ui/format.dart';
import '../../ui/limit_bar.dart';
import '../../ui/main_action_button.dart';
import '../../ui/messenger.dart';
import '../../ui/spending_ring.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import '../settings/budget_dialog.dart';
import 'home_extras.dart';
import 'period_picker.dart';

/// Màn chính: biểu đồ chi theo danh mục, tổng thu chi, số dư (F-02).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final accountFilter = ref.watch(accountFilterProvider);

    return Scaffold(
      appBar: AppBar(
        // Theme đặt titleSpacing 4 cho màn có nút quay lại; màn chính không có
        // nút này nên tự lùi 12 để chữ bắt đầu ở x = 16.
        title: Padding(
          padding: const EdgeInsets.only(left: VgSpace.s3),
          child: Text(l.appTitle),
        ),
        actions: [
          if (accounts.length > 1)
            _AccountFilterMenu(accounts: accounts, selected: accountFilter),
          IconButton(
            icon: const Icon(Symbols.receipt_long_rounded),
            tooltip: l.entries,
            onPressed: () => context.push('/entries'),
          ),
          IconButton(
            icon: const Icon(Symbols.settings_rounded),
            tooltip: l.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _PeriodHeader(),
            if (accountFilter != null) const ActiveAccountChip(),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  ref.read(periodProvider.notifier).shift(v < 0 ? 1 : -1);
                },
                // Chữ ≥ 130% (A04, SCR-01 text-200): vòng giữ cỡ 328, tổng
                // thu/chi ra danh sách dưới vòng, cả vùng giữa đầu kỳ và hàng
                // − / + cuộn được.
                child: isLargeText(context)
                    ? const SingleChildScrollView(
                        child: Column(
                          children: [
                            BudgetBar(),
                            SizedBox(
                              height: _ringBox,
                              child: _ChartWithCategories(showTotals: false),
                            ),
                            _TotalsList(),
                            _BalanceBar(),
                          ],
                        ),
                      )
                    : const Column(
                        children: [
                          BudgetBar(),
                          Expanded(child: _ChartWithCategories()),
                          _BalanceBar(),
                        ],
                      ),
              ),
            ),
            // Thanh thông báo (Hoàn tác…) luôn nằm trên hàng − / + (v2).
            const SnackBarClearance(child: _AddButtons()),
          ],
        ),
      ),
    );
  }
}

/// Khung vòng ở bản vẽ SCR-01 (328 × 328 ở 360 dp).
const _ringBox = 328.0;

/// Đầu kỳ `.vg-period` (2.1): nút kỳ trước, tên kỳ title-md kèm mũi tên xổ
/// xuống (chạm để mở bảng "Xem theo"), nút kỳ sau. Kỳ "Tất cả" không có kỳ
/// trước/sau nên ẩn hai nút (AC-10, AC-11).
class _PeriodHeader extends ConsumerWidget {
  const _PeriodHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final period = ref.watch(periodProvider);
    final notifier = ref.read(periodProvider.notifier);
    final canShift = period.type != PeriodType.all;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VgSize.appbar),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2),
        child: Row(
          mainAxisAlignment: canShift
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            if (canShift)
              IconButton(
                icon: const Icon(Symbols.chevron_left_rounded),
                tooltip: l.previousPeriod,
                onPressed: () => notifier.shift(-1),
              ),
            Flexible(
              child: Semantics(
                button: true,
                hint: l.choosePeriod,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => showPeriodPicker(context, ref),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: VgSize.tapMin),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VgSpace.s3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              periodTitle(context, period),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: VgSpace.s1),
                          const ExcludeSemantics(
                            child: Icon(Symbols.arrow_drop_down_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (canShift)
              IconButton(
                icon: const Icon(Symbols.chevron_right_rounded),
                tooltip: l.nextPeriod,
                onPressed: () => notifier.shift(1),
              ),
          ],
        ),
      ),
    );
  }
}

/// Menu lọc tài khoản từ icon ví (2.6): dòng "Tất cả tài khoản" rồi từng
/// tài khoản, cao 48; dòng đang chọn nền `secondary-container` và dấu ✓.
/// Lựa chọn chỉ sống trong phiên (AC-20).
class _AccountFilterMenu extends ConsumerWidget {
  const _AccountFilterMenu({required this.accounts, required this.selected});

  final List<Account> accounts;
  final int? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = selected == null
        ? null
        : accounts.where((a) => a.id == selected).firstOrNull;
    return PopupMenuButton<int>(
      icon: const Icon(Symbols.account_balance_wallet_rounded),
      tooltip: current == null
          ? l.account
          : '${l.account}: ${accountLabel(l, current)}',
      position: PopupMenuPosition.under,
      // Menu rộng 224, mép phải thẳng với mép phải nút ví, ngay dưới thanh
      // tiêu đề (bản vẽ 2.6).
      constraints: const BoxConstraints.tightFor(width: 224),
      offset: const Offset(-(224 - VgSize.tapMin) + VgSpace.s1, -VgSpace.s1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
      ),
      onSelected: (id) =>
          ref.read(accountFilterProvider.notifier).select(id == -1 ? null : id),
      itemBuilder: (context) => [
        _item(
          context,
          value: -1,
          icon: Symbols.select_all_rounded,
          label: l.allAccounts,
          on: current == null,
        ),
        for (final a in accounts)
          _item(
            context,
            value: a.id,
            // Dữ liệu tài khoản không có icon riêng.
            icon: Symbols.account_balance_wallet_rounded,
            label: accountLabel(l, a),
            on: current?.id == a.id,
          ),
      ],
    );
  }

  PopupMenuItem<int> _item(
    BuildContext context, {
    required int value,
    required IconData icon,
    required String label,
    required bool on,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fg = on ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return PopupMenuItem(
      value: value,
      height: VgSize.tapMin,
      padding: EdgeInsets.zero,
      child: Semantics(
        selected: on,
        child: Ink(
          color: on ? scheme.secondaryContainer : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VgSize.tapMin),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: VgSpace.s3),
                  Expanded(
                    child: Text(
                      label,
                      style: VgType.bodyMd.copyWith(
                        color: on
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (on) ...[
                    const SizedBox(width: VgSpace.s2),
                    Icon(Symbols.check_rounded, size: 20, color: fg),
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

/// Biểu đồ tròn ở giữa, icon danh mục chi xếp quanh (AC-06, AC-09). Kích
/// thước theo bản vẽ 2.1 trong khung 328 (lớn nhất): icon 48 trên vòng bán kính 140,
/// vòng chi tiêu từ 77 tới 107; khung nhỏ hơn thì co theo tỉ lệ.
class _ChartWithCategories extends ConsumerWidget {
  const _ChartWithCategories({this.showTotals = true});

  /// false khi tổng thu/chi nằm ở danh sách dưới vòng (A04).
  final bool showTotals;

  static const _iconSize = 48.0;

  /// Mỗi ô trên vòng icon chiếm 51,5 dọc theo vòng: vòng bán kính 140 (360 dp
  /// và 393 pt) xếp đúng 17 ô — 16 danh mục + ⋯ (A01, SCR-01).
  static const _slotArc = 51.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final categories =
        ref.watch(categoriesProvider(CategoryType.expense)).value ??
        const <Category>[];
    final totals = {
      for (final t in summary.expenseByCategory) t.category.id: t,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        // Icon phải nằm trọn trong khung: bán kính vòng icon tối đa 140, khung
        // nhỏ (cỡ chữ lớn, màn thấp) thì co cả vòng icon lẫn biểu đồ.
        final ring = max(0.0, min(140.0, side / 2 - _iconSize / 2));
        final scale = ring / 140;
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );
        final fit = max(1, (2 * pi * ring / _slotArc).floor());
        // Không đủ chỗ: dành ô cuối cho "Danh mục khác" (AC-51).
        final overflow = categories.length > fit;
        final shown = categories.take(overflow ? fit - 1 : fit).toList();
        final slots = shown.length + (overflow ? 1 : 0);

        Widget onRing(int i, Widget child) => Positioned(
          left:
              center.dx +
              ring * cos(-pi / 2 + 2 * pi * i / slots) -
              _iconSize / 2,
          top:
              center.dy +
              ring * sin(-pi / 2 + 2 * pi * i / slots) -
              _iconSize / 2,
          child: child,
        );

        String label(Category c) {
          final name = categoryLabel(l, c);
          final t = totals[c.id];
          return t == null
              ? l.categoryNoEntries(name)
              : l.categoryAmount(
                  name,
                  money(context, currency, t.total),
                  percent(context, t.percent),
                );
        }

        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.fromCircle(center: center, radius: 107 * scale),
              child: summary.isEmpty
                  ? _EmptyRing(scale: scale, showHint: showTotals)
                  : Semantics(
                      label: l.chartSummary(
                        summary.expenseByCategory
                            .map((t) => label(t.category))
                            .join('; '),
                      ),
                      excludeSemantics: true,
                      child: SpendingRing(
                        summary: summary,
                        scale: scale,
                        currency: currency,
                        showTotals: showTotals,
                      ),
                    ),
            ),
            for (var i = 0; i < shown.length; i++)
              onRing(
                i,
                Tooltip(
                  message: categoryLabel(l, shown[i]),
                  child: CategoryAvatar(
                    category: shown[i],
                    semanticLabel: '${l.addExpense}: ${label(shown[i])}',
                    onTap: () => context.push(
                      '/entry/new?type=expense&category=${shown[i].id}',
                    ),
                  ),
                ),
              ),
            if (overflow)
              onRing(
                shown.length,
                MoreCategoriesAvatar(
                  size: _iconSize,
                  onTap: () async {
                    // SCR-07: lưới đủ mọi danh mục chi; chọn một → màn ghi
                    // khoản chi đã chọn sẵn danh mục đó (chưa lưu vì chưa có
                    // số tiền).
                    final id = await showMoreCategoriesSheet(context);
                    if (id != null && context.mounted) {
                      context.push('/entry/new?type=expense&category=$id');
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Thanh Số dư của kỳ (2.1): chạm để xem danh sách khoản (AC-07, AC-08).
class _BalanceBar extends ConsumerWidget {
  const _BalanceBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s3),
      child: BalanceBar(
        amount: money(context, currency, summary.balance),
        // Tên kỳ dưới "Số dư": đây là số dư của kỳ, không phải số dư tài
        // khoản (§10.1 #2).
        periodTitle: periodTitle(context, ref.watch(periodProvider)),
        onTap: () => context.push('/entries'),
      ),
    );
  }
}

/// Vòng khi kỳ chưa có khoản nào (2.3, §10.1 #16): vạch vòng nhạt cùng cỡ
/// vòng chi tiêu để các icon danh mục quanh nó vẫn "có chỗ", giữa vòng là lời
/// nhắc "Bấm − để ghi khoản chi đầu tiên" và mũi tên chỉ xuống hàng − / +.
/// Chữ ≥ 130% thì lời nhắc ra danh sách dưới vòng ([showHint] = false).
class _EmptyRing extends StatelessWidget {
  const _EmptyRing({required this.scale, required this.showHint});

  final double scale;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _RingTrackPainter(
        color: scheme.surfaceContainerHigh,
        thickness: 30 * scale,
      ),
      child: !showHint
          ? const SizedBox.expand()
          : Center(
              child: SizedBox.square(
                dimension: 2 * 77 * scale - VgSpace.s4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 2 * 77 * scale - VgSpace.s4,
                    child: _EmptyHint(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Lời nhắc kỳ trống + mũi tên chỉ xuống hàng − / +.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.emptyPeriod,
          textAlign: TextAlign.center,
          style: VgType.bodyMd.copyWith(color: color),
        ),
        const SizedBox(height: VgSpace.s1),
        ExcludeSemantics(
          child: Icon(Symbols.south_rounded, size: 20, color: color),
        ),
      ],
    );
  }
}

class _RingTrackPainter extends CustomPainter {
  const _RingTrackPainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final r = min(size.width, size.height) / 2 - thickness / 2;
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingTrackPainter old) =>
      old.color != color || old.thickness != thickness;
}

/// Tổng thu / chi dưới vòng khi chữ ≥ 130% (`.vg-totals`, A04): mỗi dòng
/// nhãn body-md chữ phụ bên trái, số tiền amount-md màu thu/chi bên phải;
/// không vừa một dòng thì số tiền xuống dòng. Kỳ trống thì là lời nhắc.
class _TotalsList extends ConsumerWidget {
  const _TotalsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(periodSummaryProvider);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (summary.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s4,
          VgSpace.s2,
          VgSpace.s4,
          VgSpace.s3,
        ),
        child: _EmptyHint(color: muted),
      );
    }
    Widget row(String label, int amount, Color color) => MergeSemantics(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: VgSpace.s2,
        children: [
          Text(label, style: VgType.bodyMd.copyWith(color: muted)),
          Text(
            money(context, currency, amount),
            style: VgType.amountMd.copyWith(color: color),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(l.income, summary.income, incomeColor(context)),
          const SizedBox(height: VgSpace.s1),
          row(l.expense, summary.expense, expenseColor(context)),
        ],
      ),
    );
  }
}

/// Hai nút lớn "− Chi" và "+ Thu" ở vùng ngón cái (AC-01, AC-37). Chữ ≥ 130%
/// (A04): dấu − / + là icon 32 (không phóng theo chữ), chữ xuống dòng dưới
/// icon, nút cao tối thiểu 96.
class _AddButtons extends StatelessWidget {
  const _AddButtons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final large = isLargeText(context);
    Widget button({
      required String glyph,
      required IconData icon,
      required String label,
      required String semanticLabel,
      required Color background,
      required Color foreground,
      required VoidCallback onPressed,
    }) => large
        ? _TallAddButton(
            icon: icon,
            label: label,
            semanticLabel: semanticLabel,
            background: background,
            foreground: foreground,
            onPressed: onPressed,
          )
        : MainActionButton(
            glyph: glyph,
            label: label,
            semanticLabel: semanticLabel,
            background: background,
            foreground: foreground,
            onPressed: onPressed,
          );
    // IntrinsicHeight + stretch: hai nút luôn cao bằng nhau khi chữ một bên
    // xuống dòng.
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, 0, VgSpace.s4, VgSpace.s3),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: button(
                glyph: '−',
                icon: Symbols.remove_rounded,
                label: l.expense,
                semanticLabel: l.addExpense,
                background: context.vg.expense,
                foreground: context.vg.onExpense,
                onPressed: () => context.push('/entry/new?type=expense'),
              ),
            ),
            const SizedBox(width: VgSpace.s3),
            Expanded(
              child: button(
                glyph: '+',
                icon: Symbols.add_rounded,
                label: l.income,
                semanticLabel: l.addIncome,
                background: context.vg.income,
                foreground: context.vg.onIncome,
                onPressed: () => context.push('/entry/new?type=income'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút − / + khi chữ lớn (A04, SCR-01 text-200). Dựng riêng vì
/// [MainActionButton] (lib/src/ui) chỉ có bố cục một hàng — ghi notes D1 để
/// gom về component chung.
class _TallAddButton extends StatelessWidget {
  const _TallAddButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: semanticLabel,
    excludeFromSemantics: true,
    child: Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: FilledButton(
        style:
            bigButtonStyle(
              background: background,
              foreground: foreground,
              height: 96,
            ).copyWith(
              // Không lề ngang như `.vg-mainbtn` (SCR-01 text-200): lề 8 làm
              // "Expenses" 200% bẻ giữa chữ ở máy 360 dp.
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: VgSpace.s2),
              ),
            ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: foreground),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

/// Thanh ngân sách tháng (`.vg-budget`, 2.1/2.2): đã chi / hạn mức; vượt thì
/// ⚠ + chữ đỏ đậm + thanh đầy màu lỗi, không chỉ dựa vào màu (AC-27). Vẽ
/// bằng [LimitBar] dày 8. Chạm để đặt lại hạn mức. Tính theo tháng của kỳ
/// đang xem; kỳ năm/tất cả/tùy chọn thì ẩn (D-028).
class BudgetBar extends ConsumerWidget {
  const BudgetBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(budgetProvider).value;
    if (limit == null) return const SizedBox.shrink();
    final spentValue = ref.watch(viewedBudgetSpentProvider);
    // Kỳ không ứng với một tháng: ẩn. Đang tải lần đầu: coi như 0 như trước.
    if (spentValue.hasValue && spentValue.value == null) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final spent = spentValue.value ?? 0;
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final over = spent > limit;
    final text = over
        ? '${l.budget}: ${l.budgetOver(money(context, currency, spent - limit))}'
        : '${l.budget}: ${l.budgetProgress(money(context, currency, spent), money(context, currency, limit))}';
    return InkWell(
      onTap: () => showBudgetDialog(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s4,
          VgSpace.s1,
          VgSpace.s4,
          VgSpace.s3,
        ),
        child: LimitBar(
          text: text,
          progress: spent / limit,
          over: over,
          thickness: 8,
        ),
      ),
    );
  }
}
