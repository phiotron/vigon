/// Trạng thái ngân sách (F-37, AC-111): hàm thuần, dùng chung cho ngân sách
/// tháng và ngân sách danh mục, và cho cả logic thông báo (AC-112).
library;

/// Ngưỡng "Sắp vượt" mặc định, nhỏ nhất, lớn nhất và bước (phần trăm, AC-111).
const defaultBudgetWarnPercent = 80;
const minBudgetWarnPercent = 50;
const maxBudgetWarnPercent = 95;
const budgetWarnPercentStep = 5;

/// Các ngưỡng chọn được: 50, 55, … 95.
final budgetWarnPercentChoices = [
  for (
    var p = minBudgetWarnPercent;
    p <= maxBudgetWarnPercent;
    p += budgetWarnPercentStep
  )
    p,
];

/// Đưa một giá trị bất kỳ về ngưỡng hợp lệ: kẹp trong 50–95 rồi làm tròn về
/// bội của 5; null hoặc sai thì dùng mặc định 80.
int normalizeBudgetWarnPercent(int? value) {
  if (value == null) return defaultBudgetWarnPercent;
  final clamped = value.clamp(minBudgetWarnPercent, maxBudgetWarnPercent);
  final steps = ((clamped - minBudgetWarnPercent) / budgetWarnPercentStep)
      .round();
  return minBudgetWarnPercent + steps * budgetWarnPercentStep;
}

/// Ba trạng thái của một ngân sách trong tháng.
enum BudgetState {
  /// Chưa chạm ngưỡng.
  normal,

  /// Đã chi ≥ ngưỡng × hạn mức và ≤ hạn mức.
  almostOver,

  /// Đã chi > hạn mức.
  over,
}

/// Trạng thái của ngân sách có hạn mức [limit] khi đã chi [spent] (cùng đơn vị
/// nhỏ nhất), ngưỡng "Sắp vượt" [warnPercent]. Tính bằng số nguyên, không dùng
/// số thực, nên đúng ở mọi biên: hạn mức 5.000.000, ngưỡng 80% → 3.999.999
/// bình thường, 4.000.000 và 5.000.000 sắp vượt, 5.000.001 vượt. Hạn mức ≤ 0
/// (chưa đặt) luôn là [BudgetState.normal].
BudgetState budgetStateOf({
  required int spent,
  required int limit,
  int warnPercent = defaultBudgetWarnPercent,
}) {
  if (limit <= 0) return BudgetState.normal;
  if (spent > limit) return BudgetState.over;
  if (spent * 100 >= normalizeBudgetWarnPercent(warnPercent) * limit) {
    return BudgetState.almostOver;
  }
  return BudgetState.normal;
}

/// Phần trăm đã dùng, làm tròn XUỐNG (hiện "Đã dùng 82%"; không bao giờ hiện
/// 100% khi còn dưới hạn mức). Hạn mức ≤ 0 trả 0.
int budgetUsedPercent({required int spent, required int limit}) {
  if (limit <= 0 || spent <= 0) return 0;
  return spent * 100 ~/ limit;
}

/// Mốc thông báo của một ngân sách (AC-112).
enum BudgetMilestone {
  /// Chạm ngưỡng "Sắp vượt".
  threshold,

  /// Đã dùng hết hạn mức (100%): đã chi ≥ hạn mức.
  full,
}

/// Các mốc mà [spent] đã chạm với hạn mức [limit] và ngưỡng [warnPercent].
/// Mốc 100% tính khi đã chi ≥ hạn mức ("đã dùng 100%"), nên đúng hạn mức vẫn
/// báo một lần dù trạng thái lúc đó còn là "Sắp vượt".
Set<BudgetMilestone> budgetMilestonesReached({
  required int spent,
  required int limit,
  int warnPercent = defaultBudgetWarnPercent,
}) {
  if (limit <= 0) return const {};
  final pct = normalizeBudgetWarnPercent(warnPercent);
  return {
    if (spent * 100 >= pct * limit) BudgetMilestone.threshold,
    if (spent >= limit) BudgetMilestone.full,
  };
}
