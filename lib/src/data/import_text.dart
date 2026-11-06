import 'text_fold.dart';

/// Chữ dùng chung cho nhập từ email (2.0): khoá gợi ý theo người thụ hưởng,
/// che số tài khoản, kiểm 4 số cuối. Thuần Dart.

/// Khoá gợi ý theo người thụ hưởng (AC-97): bỏ dấu, viết thường, gộp khoảng
/// trắng, bỏ khoảng trắng đầu/cuối. "CONG TY  ABC" và "Công ty ABC" cùng khoá
/// `cong ty abc`.
String payeeKey(String payee) =>
    foldText(payee).trim().replaceAll(RegExp(r'\s+'), ' ');

final _longDigitRun = RegExp(r'\d{9,}');

/// Che mọi dãy từ 9 chữ số liền trở lên còn "…" + 4 số cuối (AC-88), để số
/// tài khoản đầy đủ không bao giờ vào cơ sở dữ liệu.
String maskLongDigitRuns(String text) => text.replaceAllMapped(
  _longDigitRun,
  (m) => '…${m[0]!.substring(m[0]!.length - 4)}',
);

final _last4 = RegExp(r'^\d{4}$');

/// Ném [ArgumentError] nếu [last4] không đúng 4 chữ số (AC-88: chỉ giữ 4 số
/// cuối, không bao giờ số đầy đủ).
void checkLast4(String last4) {
  if (!_last4.hasMatch(last4)) {
    throw ArgumentError.value(last4, 'last4', 'phải đúng 4 chữ số');
  }
}
