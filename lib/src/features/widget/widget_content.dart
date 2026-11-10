import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import 'home_widget_bridge.dart';

/// Dòng trạng thái hiện trên widget màn hình chính (AC-64).
/// [line] null nghĩa là không hiện dòng nào: widget chỉ có hai nút.
///
/// [validUntil] chỉ có khi [line] là số tiền: lúc kỳ tháng của số liệu kết thúc
/// (0 giờ ngày đầu kỳ sau, giờ máy). Phía Android tự bỏ dòng số khi quá hạn này
/// để không bao giờ hiện số của kỳ cũ như của kỳ hiện tại.
class WidgetContent {
  const WidgetContent(this.line, {this.validUntil, this.hero});

  /// Không có dòng nào, và bộ nhớ của widget phải được xóa sạch.
  static const hidden = WidgetContent(null);

  final String? line;
  final DateTime? validUntil;

  /// Số lớn của widget vẽ lại (chỉ khi được hiện số tiền).
  final WidgetHero? hero;

  @override
  bool operator ==(Object other) =>
      other is WidgetContent &&
      other.line == line &&
      other.validUntil == validUntil &&
      other.hero == hero;

  @override
  int get hashCode => Object.hash(line, validUntil, hero);

  @override
  String toString() => 'WidgetContent($line, validUntil: $validUntil)';
}

/// Quy tắc hiện, ẩn số tiền trên widget (AC-64). Hàm thuần để test đủ tổ hợp.
///
/// - Công tắc tắt: không có dòng nào (mặc định).
/// - Công tắc bật, PIN bật: chỉ chữ "Đã khóa bằng PIN"; hai chuỗi số tiền
///   KHÔNG BAO GIỜ được tính hay đưa vào kết quả.
/// - Công tắc bật, PIN tắt: "Tháng này đã chi X", thêm " / Y" nếu có hạn mức.
///
/// [validUntil] là hạn dùng của dòng số tiền (hết kỳ tháng); chỉ đi kèm số tiền.
///
/// Hai chuỗi số tiền là hàm trả về chuỗi để khi không được phép hiện thì không
/// cần (và không được) tính ra chúng.
WidgetContent widgetContent({
  required bool showAmounts,
  required bool pinEnabled,
  required String Function() spentFormatted,
  String Function()? budgetFormatted,
  int? percent,
  String Function()? overFormatted,
  DateTime? validUntil,
  required String language,
}) {
  if (!showAmounts) return WidgetContent.hidden;
  final l = lookupAppLocalizations(Locale(language));
  if (pinEnabled) return WidgetContent(l.widgetLockedByPin);
  final spent = spentFormatted();
  final budget = budgetFormatted?.call();
  // Mockup v4 EXT-01: "Tháng này đã chi" + số lớn; có hạn mức thì thanh +
  // "trên Y · N%", ≥ 80 % thì "Sắp vượt · N%", vượt thì "Vượt X".
  String? caption;
  final warn = budget != null && percent != null && percent >= 80;
  if (budget != null && percent != null) {
    final over = percent > 100 ? overFormatted?.call() : null;
    caption = over != null
        ? l.budgetOver(over)
        : warn
        ? '${l.almostOver} · $percent%'
        : l.widgetOfBudget(budget, '$percent%');
  }
  return WidgetContent(
    budget == null
        ? l.widgetSpentThisMonth(spent)
        : l.widgetSpentOfBudget(spent, budget),
    validUntil: validUntil,
    hero: WidgetHero(
      label: l.widgetSpentLabel,
      amount: spent,
      caption: caption,
      percent: budget == null ? null : percent,
      warn: warn,
    ),
  );
}
