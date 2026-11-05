import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import 'accounts_screen.dart' show accountIcon, showAccountEditor;

/// Vùng quản lý trong bảng sửa tài khoản (SCR-18, AC-44..AC-47), ngăn với các ô
/// bằng một vạch để nút hủy hoại không nằm cạnh Lưu:
/// - tài khoản đang ẩn: "Hiện lại" thay "Ẩn tài khoản";
/// - chưa dùng: Ẩn (viền) + Xóa (chữ đỏ) → hộp xác nhận;
/// - đã dùng: chỉ Ẩn + gợi ý ⓘ vì sao không xóa được;
/// - tài khoản hiện cuối cùng (A11): không nút nào, chỉ gợi ý.
/// Xong thao tác thì đóng bảng.
class AccountRemoveSection extends ConsumerWidget {
  const AccountRemoveSection({super.key, required this.account});

  final Account account;

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    await ref.read(accountRepositoryProvider).archive(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _unarchive(BuildContext context, WidgetRef ref) async {
    await ref.read(accountRepositoryProvider).unarchive(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // SCR-18 delete: icon `error`, chỉ tiêu đề (tài khoản chưa có khoản nên
    // không mất gì khác), nút Xóa nền `error`.
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => VgDialog(
            title: l.deleteAccountConfirm(accountLabel(l, account)),
            icon: Symbols.delete_rounded,
            actions: [
              VgDialog.cancelButton(
                context,
                onPressed: () => Navigator.pop(context, false),
              ),
              FilledButton(
                style: dangerButtonStyle(context),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !context.mounted) return;
    await ref.read(accountRepositoryProvider).delete(account.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final visible = ref.watch(accountsProvider).value ?? const <Account>[];
    final inUse = ref.watch(accountInUseProvider(account.id)).value;
    // Tài khoản đang ẩn thì hiện lại / xóa không làm giảm số tài khoản hiện.
    final lastVisible = !account.archived && visible.length <= 1;
    final buttonSize = const Size(VgSize.tapMin, VgSize.tapMin);
    return Padding(
      padding: const EdgeInsets.fromLTRB(VgSpace.s4, VgSpace.s4, VgSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: VgSpace.s4),
          if (lastVisible)
            VgHint(l.accountLastOneHint)
          else ...[
            // Xếp dọc, căn đầu dòng như `.vg-mgmt` (SCR-18): nút Xóa không
            // nằm cạnh nút Ẩn. Vùng chạm 48 của mỗi nút đã tạo khe nhìn thấy 8.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (account.archived)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    icon: const Icon(Symbols.visibility_rounded, size: 18),
                    label: Text(l.unarchiveAccount),
                    onPressed: () => _unarchive(context, ref),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    icon: const Icon(Symbols.visibility_off_rounded, size: 18),
                    label: Text(l.archiveAccount),
                    onPressed: () => _archive(context, ref),
                  ),
                // Đã dùng: nút Xóa không hiện (không chỉ tắt), AC-45.
                if (inUse == false)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      minimumSize: buttonSize,
                    ),
                    icon: const Icon(Symbols.delete_rounded, size: 18),
                    label: Text(l.deleteAccount),
                    onPressed: () => _delete(context, ref),
                  ),
              ],
            ),
            if (inUse == true)
              Padding(
                padding: const EdgeInsets.only(top: VgSpace.s3),
                child: VgHint(l.accountInUseHint),
              ),
          ],
        ],
      ),
    );
  }
}

/// Mục "Tài khoản đã ẩn (n)" cuối màn Tài khoản (SCR-17, A10): tiêu đề là nút
/// 56 dp có trạng thái thu/mở (mặc định thu, AC-47), mở/thu 200 ms. Hàng ẩn
/// chữ phụ, có nút "Hiện lại"; chạm hàng mở bảng sửa tài khoản. Không vẽ gì khi
/// chưa có tài khoản nào bị ẩn.
class ArchivedAccountsSection extends ConsumerStatefulWidget {
  const ArchivedAccountsSection({super.key});

  @override
  ConsumerState<ArchivedAccountsSection> createState() =>
      _ArchivedAccountsSectionState();
}

class _ArchivedAccountsSectionState
    extends ConsumerState<ArchivedAccountsSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final archived =
        ref.watch(archivedAccountsProvider).value ?? const <Account>[];
    if (archived.isEmpty) return const SizedBox.shrink();
    final balances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final muted = scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 9, thickness: 1, color: scheme.outlineVariant),
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: VgSize.tapKey),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VgSpace.s4,
                  vertical: VgSpace.s2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Icon(Symbols.visibility_off_rounded, color: muted),
                    ),
                    const SizedBox(width: VgSpace.s4),
                    Expanded(
                      child: Text(
                        l.archivedAccountsCount(archived.length),
                        style: VgType.titleSm.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    Icon(
                      _open
                          ? Symbols.expand_less_rounded
                          : Symbols.expand_more_rounded,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: VgMotion.reduced(context) ? Duration.zero : VgMotion.medium,
          curve: VgMotion.standard,
          alignment: Alignment.topCenter,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final a in archived)
                      _HiddenAccountRow(
                        account: a,
                        balance: money(
                          context,
                          currency,
                          balances[a.id] ?? a.initialBalance,
                        ),
                      ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Hàng tài khoản ẩn (`.vg-row.two`): cao tối thiểu 72, tên màu chữ phụ một
/// dòng, số dư dưới tên, nút chữ "Hiện lại" có icon 👁.
class _HiddenAccountRow extends ConsumerWidget {
  const _HiddenAccountRow({required this.account, required this.balance});

  final Account account;
  final String balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final name = accountLabel(l, account);
    return InkWell(
      onTap: () => showAccountEditor(context, account: account),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VgSize.rowTwoLine),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VgSpace.s4,
            vertical: VgSpace.s2,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(accountIcon(account), color: muted),
              ),
              const SizedBox(width: VgSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VgType.bodyMd.copyWith(color: muted),
                    ),
                    Text(
                      balance,
                      style: VgType.bodySm.copyWith(
                        color: muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                // "Hiện lại: Thẻ cũ" để TalkBack biết hiện tài khoản nào.
                label: '${l.unarchiveAccount}: $name',
                button: true,
                excludeSemantics: true,
                onTap: () =>
                    ref.read(accountRepositoryProvider).unarchive(account.id),
                child: TextButton.icon(
                  icon: const Icon(Symbols.visibility_rounded, size: 18),
                  label: Text(l.unarchiveAccount),
                  onPressed: () =>
                      ref.read(accountRepositoryProvider).unarchive(account.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
