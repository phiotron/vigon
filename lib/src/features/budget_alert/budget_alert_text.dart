import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import 'budget_alerts.dart';

/// Tên tháng trong thông báo: tiếng Việt dùng số ("tháng 11"), tiếng Anh dùng
/// tên tháng ("November"). Kỳ có ngày bắt đầu khác 1 (25/10–24/11) gọi theo
/// tháng chứa phần lớn kỳ, tức tháng của ngày cuối khi bắt đầu sau ngày 15.
String budgetAlertMonthLabel(
  AppLocalizations l,
  DateTime monthStart,
  DateTime monthEnd,
) {
  final named = monthStart.day > 15 ? monthEnd : monthStart;
  if (l.localeName == 'vi') return '${named.month}';
  try {
    return DateFormat.MMMM(l.localeName).format(named);
  } catch (_) {
    // Thiếu dữ liệu ngày tháng của ngôn ngữ: dùng tên tiếng Anh cố định.
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][named.month - 1];
  }
}

/// Chữ của thông báo ngân sách (AC-113): CHỈ có phần trăm và tên ngân sách,
/// không bao giờ có số tiền hay ký hiệu tiền tệ, dù PIN bật hay tắt. Tiêu đề là
/// tên app. [categoryName] là tên danh mục khi ngân sách là của danh mục.
BudgetAlertContent budgetAlertContent(
  AppLocalizations l,
  BudgetAlert alert, {
  required DateTime monthStart,
  required DateTime monthEnd,
  String? categoryName,
}) {
  final month = budgetAlertMonthLabel(l, monthStart, monthEnd);
  final body = alert.id == monthlyBudgetId
      ? l.budgetAlertMonthly(month, alert.percent)
      : l.budgetAlertCategory(categoryName ?? '', alert.percent, month);
  return BudgetAlertContent(
    title: l.appTitle,
    body: body,
    channelName: l.budgetAlertChannelName,
    channelDescription: l.budgetAlertChannelDescription,
  );
}
