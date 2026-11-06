import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'format.dart';
import 'tokens.g.dart';

/// Thanh Số dư (`.vg-balance` v2, ChartRing.html, 2.1, SCR-01): nền
/// `surface-container-high`, bo `radius-md`, cao tối thiểu 56. Bên trái "Số
/// dư" và dưới nó [periodTitle] (tên kỳ đang xem, body-sm màu chữ phụ); bên
/// phải số tiền amount-md tự co cho vừa; mũi tên ›. Chạm để xem danh sách
/// khoản (AC-07, AC-08). Trình đọc màn hình đọc "Số dư: X, tên kỳ".
class BalanceBar extends StatelessWidget {
  const BalanceBar({
    super.key,
    required this.amount,
    this.periodTitle,
    required this.onTap,
  });

  /// Số dư đã định dạng.
  final String amount;
  final String? periodTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final semantic = [l.balanceLabel(amount), ?periodTitle].join(', ');
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(VgRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VgSize.tapKey),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s2,
                VgSpace.s2,
              ),
              // Số tiền lấy đúng bề rộng của nó (tối đa 60% hàng, quá thì co
              // chữ); phần còn lại cho "Số dư" + tên kỳ để tên kỳ không bị bẻ
              // giữa chữ ("Novemb/er 2026" khi chia cố định 1:3).
              child: LayoutBuilder(
                builder: (context, box) => isLargeText(context)
                    ? _stacked(l, scheme, muted)
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.balance,
                                  style: VgType.bodyMd.copyWith(color: muted),
                                ),
                                if (periodTitle != null)
                                  Text(
                                    periodTitle!,
                                    style: VgType.bodySm.copyWith(color: muted),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: VgSpace.s2),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: box.maxWidth * 0.6,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                amount,
                                style: VgType.amountMd.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: VgSpace.s2),
                          Icon(Symbols.chevron_right_rounded, color: muted),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Chữ ≥ 130%: "Số dư", tên kỳ rồi số tiền xếp dọc cả bề rộng. Xếp ngang
  /// thì số tiền chiếm tới 60% hàng và cột chữ còn lại hẹp tới mức tên kỳ bị
  /// bẻ giữa chữ ("Thán/g 11", D9 Galaxy A13 cỡ chữ 200% + thu phóng).
  Widget _stacked(AppLocalizations l, ColorScheme scheme, Color muted) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.balance, style: VgType.bodyMd.copyWith(color: muted)),
            if (periodTitle != null)
              Text(periodTitle!, style: VgType.bodySm.copyWith(color: muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                amount,
                style: VgType.amountMd.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: VgSpace.s2),
      Icon(Symbols.chevron_right_rounded, color: muted),
    ],
  );
}
