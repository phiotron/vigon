import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/money.dart';

/// Đổi tiền tệ của ô đang nhập giữ nguyên con số đã gõ (lỗi thấy trên máy
/// 2026-11-11: gõ 10 ở VND rồi đổi sang USD thành "0,10 USD").
void main() {
  test('thêm chữ số lẻ: 10 ₫ → 10,00 USD', () {
    expect(rescaleMinorUnits(10, 0, 2), 1000);
    expect(rescaleMinorUnits(-10, 0, 3), -10000);
  });

  test('bớt chữ số lẻ: làm tròn half-up ra xa 0', () {
    expect(rescaleMinorUnits(1000, 2, 0), 10); // 10,00 USD → 10 ₫
    expect(rescaleMinorUnits(1050, 2, 0), 11); // 10,50 → 11
    expect(rescaleMinorUnits(1049, 2, 0), 10);
    expect(rescaleMinorUnits(-1050, 2, 0), -11);
    expect(rescaleMinorUnits(12345, 3, 2), 1235); // KWD → USD
  });

  test('cùng số chữ số lẻ thì giữ nguyên', () {
    expect(rescaleMinorUnits(1234, 2, 2), 1234);
  });
}
