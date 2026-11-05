import 'package:flutter/material.dart';

import '../data/money.dart';
import 'tokens.g.dart';

/// Vùng số tiền khi ghi khoản hoặc chuyển tiền (3.2, 3.7, 6.6): biểu thức
/// đang gõ nhỏ, kết quả lớn tự co cho vừa, lỗi ngay dưới số tiền. Là vùng
/// thông báo trực tiếp để trình đọc màn hình đọc số mới (AC-05, AC-39).
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.expression,
    required this.amount,
    required this.color,
    this.error,
  });

  final String expression;

  /// Số tiền đã định dạng, ví dụ "155.000 ₫".
  final String amount;
  final Color color;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s6,
        VgSpace.s2,
        VgSpace.s6,
        VgSpace.s3,
      ),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hiện theo ngôn ngữ ("3.500.000", "12,5" ở vi); biểu thức gốc
            // vẫn dùng "." thập phân để tính.
            Text(
              expression.isEmpty
                  ? ' '
                  : formatExpressionForDisplay(
                      expression,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
              style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: VgType.amountXl.copyWith(color: color),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  error!,
                  textAlign: TextAlign.end,
                  style: VgType.bodySm.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
