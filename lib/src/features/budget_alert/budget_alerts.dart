import 'dart:convert';

import 'budget_status.dart';
import 'budget_alert_settings.dart';

/// Thông báo ngân sách (F-37, AC-112): logic "mốc nào, báo một lần mỗi tháng"
/// tách khỏi plugin thông báo và khỏi giao diện để test được.

/// Mã của ngân sách tháng trong [BudgetAlertInput.id].
const monthlyBudgetId = 'month';

/// Mã của ngân sách danh mục [categoryId].
String categoryBudgetId(int categoryId) => 'cat$categoryId';

/// Một ngân sách đang được theo dõi: hạn mức và đã chi của THÁNG HIỆN TẠI.
class BudgetAlertInput {
  const BudgetAlertInput({
    required this.id,
    required this.limit,
    required this.spent,
    this.categoryId,
  });

  /// [monthlyBudgetId] hoặc [categoryBudgetId].
  final String id;
  final int limit;
  final int spent;

  /// Có khi là ngân sách danh mục (để lấy tên cho nội dung thông báo).
  final int? categoryId;
}

/// Một thông báo cần gửi. Chỉ mang phần trăm của MỐC, không có số tiền.
class BudgetAlert {
  const BudgetAlert({
    required this.id,
    required this.milestone,
    required this.percent,
    this.categoryId,
  });

  final String id;
  final BudgetMilestone milestone;

  /// Mốc hiển thị: ngưỡng (50–95) hoặc 100.
  final int percent;
  final int? categoryId;

  @override
  String toString() => 'BudgetAlert($id, $milestone, $percent%)';
}

/// Trạng thái lưu giữa các lần chạy: tháng đang theo dõi, "chữ ký" của cài đặt
/// (hạn mức + ngưỡng) lúc tính lần trước, và các mốc đã báo.
class BudgetAlertState {
  const BudgetAlertState({
    required this.month,
    required this.signature,
    required this.done,
  });

  /// Khóa của tháng (ngày đầu kỳ, `YYYY-MM-DD`).
  final String month;
  final String signature;

  /// Mốc đã báo hoặc đã được coi là báo rồi, dạng `<mã ngân sách>:t|f`.
  final Set<String> done;

  String toJson() => jsonEncode({
    'month': month,
    'sig': signature,
    'done': done.toList()..sort(),
  });

  static BudgetAlertState? tryParse(String? text) {
    if (text == null) return null;
    try {
      final m = jsonDecode(text) as Map<String, dynamic>;
      return BudgetAlertState(
        month: m['month'] as String,
        signature: m['sig'] as String,
        done: {for (final d in m['done'] as List) d as String},
      );
    } catch (_) {
      return null;
    }
  }
}

String _doneKey(String id, BudgetMilestone m) =>
    '$id:${m == BudgetMilestone.threshold ? 't' : 'f'}';

/// Chữ ký của phần KHÔNG phải khoản ghi: ngưỡng và hạn mức. Đổi hạn mức hay
/// ngưỡng thì mốc nào đang vượt không được báo (đó là đổi cài đặt, không phải
/// một khoản làm vượt).
String budgetAlertSignature(int warnPercent, List<BudgetAlertInput> budgets) {
  final parts = [for (final b in budgets) '${b.id}=${b.limit}']..sort();
  return '$warnPercent|${parts.join(',')}';
}

/// Kết quả một lần tính.
class BudgetAlertPlan {
  const BudgetAlertPlan(this.alerts, this.state);

  /// Thông báo cần gửi lúc này (tối đa một cho mỗi ngân sách).
  final List<BudgetAlert> alerts;

  /// Trạng thái cần lưu.
  final BudgetAlertState state;
}

/// Tính thông báo cho tháng [month] (đã tính xong số đã chi của tháng đó).
///
/// - [previous] null (mới bật, hoặc mới xóa dữ liệu) hoặc khác chữ ký (vừa đổi
///   hạn mức/ngưỡng): chỉ ghi nhận các mốc đang vượt là "đã báo", KHÔNG gửi.
/// - Sang tháng mới: bắt đầu lại từ trống, mọi mốc được báo lại một lần.
/// - Cùng tháng: gửi mốc mới chạm mà chưa có trong `done`; mỗi mốc mỗi ngân
///   sách một lần mỗi tháng, giảm rồi tăng lại không báo lại.
/// - Một ngân sách chạm cả hai mốc cùng lúc (khoản lớn nhảy từ dưới ngưỡng lên
///   hết hạn mức) chỉ gửi MỘT thông báo, ở mốc cao nhất; cả hai được ghi là đã báo.
BudgetAlertPlan planBudgetAlerts({
  required BudgetAlertState? previous,
  required String month,
  required int warnPercent,
  required List<BudgetAlertInput> budgets,
}) {
  final pct = normalizeBudgetWarnPercent(warnPercent);
  final signature = budgetAlertSignature(pct, budgets);
  final sameMonth = previous != null && previous.month == month;
  final done = <String>{if (sameMonth) ...previous.done};
  final silent = previous == null || previous.signature != signature;
  final alerts = <BudgetAlert>[];
  for (final b in budgets) {
    final reached = budgetMilestonesReached(
      spent: b.spent,
      limit: b.limit,
      warnPercent: pct,
    );
    final fresh = {
      for (final m in reached)
        if (!done.contains(_doneKey(b.id, m))) m,
    };
    if (fresh.isEmpty) continue;
    done.addAll([for (final m in reached) _doneKey(b.id, m)]);
    if (silent) continue;
    final top = fresh.contains(BudgetMilestone.full)
        ? BudgetMilestone.full
        : BudgetMilestone.threshold;
    alerts.add(
      BudgetAlert(
        id: b.id,
        milestone: top,
        percent: top == BudgetMilestone.full ? 100 : pct,
        categoryId: b.categoryId,
      ),
    );
  }
  return BudgetAlertPlan(
    alerts,
    BudgetAlertState(month: month, signature: signature, done: done),
  );
}

/// Chữ của một thông báo, đã dịch. Chỉ có phần trăm, không bao giờ có số tiền
/// hay ký hiệu tiền tệ (AC-113).
class BudgetAlertContent {
  const BudgetAlertContent({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}

/// Gửi một thông báo ngân sách. Bản thật dùng plugin thông báo của hệ điều
/// hành, test dùng bản giả.
abstract class BudgetNotifier {
  Future<void> show(BudgetAlert alert, BudgetAlertContent content);
}

/// Đường dẫn app mở khi chạm thông báo ngân sách: màn Tổng quan (AC-113).
/// Router chưa có route này (Tổng quan làm song song) thì mở màn chính, xem
/// `BudgetAlertBinder`.
const budgetAlertPayload = '/overview';

/// Nối các bước tính → lưu → gửi thành một hàng đợi tuần tự, để hai lần cập
/// nhật liên tiếp (tổng và danh mục) không đọc/ghi trạng thái chồng nhau.
class BudgetAlertMonitor {
  BudgetAlertMonitor(this._settings, this._notifier);

  final BudgetAlertSettings _settings;
  final BudgetNotifier _notifier;
  Future<void> _tail = Future.value();

  /// Công tắc tắt: xóa trạng thái để lần bật sau bắt đầu từ mốc hiện có.
  Future<void> disable() => _enqueue(() => _settings.writeState(null));

  /// Tính với số liệu mới của tháng [month]; gửi các thông báo mới chạm mốc.
  Future<void> evaluate({
    required String month,
    required int warnPercent,
    required List<BudgetAlertInput> budgets,
    required BudgetAlertContent Function(BudgetAlert alert) contentFor,
  }) => _enqueue(() async {
    final previous = BudgetAlertState.tryParse(await _settings.readState());
    final plan = planBudgetAlerts(
      previous: previous,
      month: month,
      warnPercent: warnPercent,
      budgets: budgets,
    );
    await _settings.writeState(plan.state.toJson());
    for (final alert in plan.alerts) {
      await _notifier.show(alert, contentFor(alert));
    }
  });

  Future<void> _enqueue(Future<void> Function() job) {
    final next = _tail.then((_) => job());
    _tail = next.catchError((_) {});
    return next;
  }
}
