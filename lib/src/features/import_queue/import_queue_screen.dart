import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/import_text.dart';
import '../../import/mb/mb_import_service.dart' show mbAutoAccountName;
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/category_avatar.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../entry/entry_time.dart';
import 'import_queue_providers.dart';

/// Màn Hàng đợi (F-32, AC-95..AC-99): mỗi email biên lai không ghép được là
/// một mục chờ chọn danh mục. Mục CHƯA là khoản: không vào tổng, biểu đồ,
/// ngân sách, số dư. Dựng tạm bằng component Hi-Fi hiện có; bản vẽ của Claude
/// Design (phiên điều phối #4) thay sau.
class ImportQueueScreen extends ConsumerWidget {
  const ImportQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(importQueueProvider).value ?? const [];
    final notices = ref.watch(autoAccountNoticesProvider).value ?? const [];
    final empty = items.isEmpty && notices.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.importQueue),
        actions: [
          IconButton(
            icon: const Icon(Symbols.lightbulb_rounded),
            tooltip: l.queueSuggestions,
            onPressed: () => context.push('/import-queue/suggestions'),
          ),
        ],
      ),
      body: empty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.queueEmpty,
                  textAlign: TextAlign.center,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                VgSpace.s6,
              ),
              itemCount: notices.length + items.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: VgSpace.s3),
                child: i < notices.length
                    ? _NoticeCard(accountId: notices[i], allNotices: notices)
                    : _ItemCard(item: items[i - notices.length]),
              ),
            ),
    );
  }
}

/// Thẻ "Đã tạo tài khoản MB Bank …1234 · Gắn vào tài khoản có sẵn" (AC-89).
class _NoticeCard extends ConsumerWidget {
  const _NoticeCard({required this.accountId, required this.allNotices});

  final int accountId;
  final List<int> allNotices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final account = all.where((a) => a.id == accountId).firstOrNull;
    if (account == null) return const SizedBox.shrink();
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(VgRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(VgSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.account_balance_rounded,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: VgSpace.s3),
                Expanded(
                  child: Text(
                    l.queueAutoAccount(accountLabel(l, account)),
                    style: VgType.bodyMd.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, VgSize.tapMin),
                  ),
                  onPressed: () => ref
                      .read(mbImportServiceProvider)
                      .dismissAutoAccountNotice(accountId),
                  child: Text(l.queueDismiss),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, VgSize.tapMin),
                  ),
                  onPressed: () => _attach(context, ref),
                  child: Text(l.queueAttach),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Gắn vào tài khoản có sẵn": chọn một Account không phải Account tự tạo
  /// nào khác (AC-89).
  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final visible = ref.read(accountsProvider).value ?? const <Account>[];
    final candidates = [
      for (final a in visible)
        if (!allNotices.contains(a.id)) a,
    ];
    if (candidates.isEmpty) {
      showMessage(l.queueNoOtherAccount);
      return;
    }
    final picked = await showChoiceSheet<int>(
      context,
      title: l.queueAttachTitle,
      selected: -1,
      options: [
        for (final a in candidates)
          ChoiceOption(
            a.id,
            accountLabel(l, a),
            icon: Symbols.account_balance_wallet_rounded,
          ),
      ],
    );
    if (picked == null) return;
    await ref
        .read(mbImportServiceProvider)
        .attachToExistingAccount(
          autoAccountId: accountId,
          targetAccountId: picked.$1,
        );
  }
}

/// Một mục hàng đợi: thông tin email, lưới danh mục chi (có gợi ý), các hành
/// động Lưu / Sửa trước khi lưu / Chuyển sang tài khoản của tôi / Bỏ qua.
class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final ImportQueueItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final categories =
        ref.watch(categoriesProvider(CategoryType.expense)).value ??
        const <Category>[];
    final appCurrency = ref.watch(currencyProvider).value ?? 'VND';
    final suggestions =
        ref.watch(payeeSuggestionsProvider).value ?? const <PayeeSuggestion>[];

    final account = all.where((a) => a.id == item.accountId).firstOrNull;
    final accountName = account != null
        ? accountLabel(l, account)
        : mbAutoAccountName(item.debitLast4);
    final mismatch = item.currency != appCurrency;
    final payee = item.payee;
    final key = payee == null ? '' : payeeKey(payee);
    final suggestion = key.isEmpty
        ? null
        : suggestions.where((s) => s.payeeKey == key).firstOrNull;
    // Gợi ý còn dùng được: danh mục còn tồn tại, hoặc tài khoản đích khác tài
    // khoản trích nợ (AC-97, AC-98).
    final suggestedCategory = suggestion?.categoryId == null
        ? null
        : categories.where((c) => c.id == suggestion!.categoryId).firstOrNull;
    final suggestedAccount =
        mismatch ||
            suggestion?.toAccountId == null ||
            suggestion!.toAccountId == item.accountId
        ? null
        : all.where((a) => a.id == suggestion.toAccountId).firstOrNull;

    final when = _dateTime(context, item);
    final amount = money(context, item.currency, item.amount);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VgRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(VgSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    payee == null || payee.trim().isEmpty
                        ? l.queuePayeeUnknown
                        : payee,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VgType.titleSm.copyWith(color: scheme.onSurface),
                  ),
                ),
                const SizedBox(width: VgSpace.s3),
                Text(
                  amount,
                  style: VgType.titleSm.copyWith(
                    color: expenseColor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (item.transferContent != null &&
                item.transferContent!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: VgSpace.s1),
                child: Text(
                  item.transferContent!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: VgSpace.s1),
            Text(
              '$when · ${l.queueFromAccount(accountName)}',
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (mismatch)
              VgHint(
                l.queueCurrencyNote(item.currency, appCurrency),
                icon: Symbols.warning_rounded,
                padding: const EdgeInsets.only(top: VgSpace.s2),
              ),
            const SizedBox(height: VgSpace.s3),
            _CategoryGrid(
              categories: categories,
              suggestedId: suggestedCategory?.id,
              onPick: (c) => _save(context, ref, c.id, mismatch),
            ),
            const SizedBox(height: VgSpace.s2),
            if (suggestedCategory != null)
              _PrimaryAction(
                suggested: true,
                label: l.queueSaveTo(categoryLabel(l, suggestedCategory)),
                onPressed: () =>
                    _save(context, ref, suggestedCategory.id, mismatch),
              )
            else if (suggestedAccount != null)
              _PrimaryAction(
                suggested: true,
                label: l.queueMoveTo(accountLabel(l, suggestedAccount)),
                onPressed: () => _moveTo(context, ref, suggestedAccount),
              ),
            Wrap(
              spacing: VgSpace.s1,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, VgSize.tapMin),
                  ),
                  onPressed: () => _edit(context, suggestedCategory?.id),
                  child: Text(l.queueEditFirst),
                ),
                // Mục khác tiền tệ không tự chuyển được (không biết số tiền
                // theo tiền tệ của app): chỉ qua "Sửa trước khi lưu" (AC-87).
                if (!mismatch)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, VgSize.tapMin),
                    ),
                    onPressed: () => _chooseMoveTarget(context, ref),
                    child: Text(l.queueMoveToMine),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    minimumSize: const Size(0, VgSize.tapMin),
                  ),
                  onPressed: () => _skip(context, ref),
                  child: Text(l.queueSkip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ngày giờ của email, ví dụ "3 thg 11, 2026 · 12:02".
  String _dateTime(BuildContext context, ImportQueueItem item) {
    final day = shortDate(context, parseDateKey(item.date));
    return '$day · ${formatTimeKey(context, item.time)}';
  }

  /// Lưu vào danh mục (AC-96). Mục khác tiền tệ thì mở Nhập khoản với ô số
  /// tiền trống (AC-87).
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    int categoryId,
    bool mismatch,
  ) async {
    final l = AppLocalizations.of(context);
    if (mismatch) {
      await context.push('/entry/new?queue=${item.id}&category=$categoryId');
      return;
    }
    final cats =
        ref.read(categoriesProvider(CategoryType.expense)).value ?? const [];
    final name = cats.where((c) => c.id == categoryId).firstOrNull;
    final id = await ref
        .read(importQueueActionsProvider)
        .saveToCategory(item, categoryId);
    if (id != null && name != null) {
      showMessage(l.queueSaved(categoryLabel(l, name)));
    }
  }

  Future<void> _edit(BuildContext context, int? categoryId) => context.push(
    '/entry/new?queue=${item.id}'
    '${categoryId == null ? '' : '&category=$categoryId'}',
  );

  /// "Chuyển sang tài khoản của tôi" (AC-98): chọn Account đích khác Account
  /// trích nợ, kể cả Account của mục tiêu tiết kiệm.
  Future<void> _chooseMoveTarget(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final visible = ref.read(accountsProvider).value ?? const <Account>[];
    final candidates = [
      for (final a in visible)
        if (a.id != item.accountId) a,
    ];
    if (candidates.isEmpty) {
      showMessage(l.queueNoOtherAccount);
      return;
    }
    final picked = await showChoiceSheet<int>(
      context,
      title: l.queueMoveToTitle,
      selected: -1,
      options: [
        for (final a in candidates)
          ChoiceOption(
            a.id,
            accountLabel(l, a),
            icon: Symbols.account_balance_wallet_rounded,
          ),
      ],
    );
    if (picked == null) return;
    final target = candidates.firstWhere((a) => a.id == picked.$1);
    if (context.mounted) await _moveTo(context, ref, target);
  }

  Future<void> _moveTo(
    BuildContext context,
    WidgetRef ref,
    Account target,
  ) async {
    final l = AppLocalizations.of(context);
    final id = await ref
        .read(importQueueActionsProvider)
        .saveAsTransfer(item, target.id);
    if (id != null) showMessage(l.queueMoved(accountLabel(l, target)));
  }

  /// "Bỏ qua" sau hộp xác nhận (AC-99).
  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.close_rounded,
      title: l.queueSkipTitle,
      body: l.queueSkipBody,
      action: l.queueSkip,
      style: ConfirmStyle.danger,
    );
    if (!ok) return;
    if (await ref.read(importQueueActionsProvider).skip(item)) {
      showMessage(l.queueSkipped);
    }
  }
}

/// Nút lớn "Lưu vào (danh mục)" / "Chuyển sang (tài khoản)" của gợi ý; người
/// dùng vẫn phải chạm để xác nhận (AC-96). [suggested] hiện nhãn "Gợi ý".
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
    this.suggested = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool suggested;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suggested)
          Padding(
            padding: const EdgeInsets.only(bottom: VgSpace.s1),
            child: Row(
              children: [
                Icon(
                  Symbols.lightbulb_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: VgSpace.s1),
                Text(
                  l.queueSuggested,
                  style: VgType.labelMd.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, VgSize.tapMin),
          ),
          onPressed: onPressed,
          child: Text(label, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// Lưới danh mục chi của một mục: 4 cột; chạm một danh mục là lưu vào đó
/// (D-018). Ô được gợi ý có vòng chọn và nhãn "Gợi ý".
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.suggestedId,
    required this.onPick,
  });

  final List<Category> categories;
  final int? suggestedId;
  final ValueChanged<Category> onPick;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rows = (categories.length / _columns).ceil();

    Widget cell(Category c) {
      final suggested = c.id == suggestedId;
      final name = categoryLabel(l, c);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Semantics(
            button: true,
            selected: suggested,
            label: suggested ? '$name, ${l.queueSuggested}' : name,
            excludeSemantics: true,
            onTap: () => onPick(c),
            child: InkWell(
              borderRadius: BorderRadius.circular(VgRadius.md),
              onTap: () => onPick(c),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VgSpace.s1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryAvatar(category: c, selected: suggested),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VgType.labelSm.copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : VgSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _columns; i++)
                  Expanded(
                    child: r * _columns + i < categories.length
                        ? cell(categories[r * _columns + i])
                        : const SizedBox(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
