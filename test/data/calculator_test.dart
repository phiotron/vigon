import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/calculator.dart';
import 'package:vigon/src/features/entry/keypad.dart';

int? vnd(String e) => evaluateToMinorUnits(e, decimalDigits: 0);
int? usd(String e) => evaluateToMinorUnits(e, decimalDigits: 2);

void main() {
  test('120+35 lưu 155 (AC-03)', () => expect(vnd('120+35'), 155));

  test('nhân chia trước, cộng trừ sau', () {
    expect(vnd('2+3×4'), 14);
    expect(vnd('100−20÷4'), 95);
    expect(vnd('10÷4'), 3); // 2,5 làm tròn
  });

  test('số thập phân với tiền có phần lẻ', () {
    expect(usd('12.5'), 1250);
    expect(usd('0.1+0.2'), 30);
    expect(usd('19.99×3'), 5997);
  });

  test('biểu thức sai trả về null', () {
    expect(vnd(''), isNull);
    expect(vnd('5÷0'), isNull);
    expect(vnd('5+'), isNull);
    expect(vnd('+5'), isNull);
    expect(vnd('1.2.3'), isNull);
    expect(vnd('.'), isNull);
  });

  test('số âm và 0 vẫn tính ra để màn nhập báo lỗi (AC-05)', () {
    expect(vnd('0'), 0);
    expect(vnd('5−8'), -3);
  });

  test('đổi số tiền đã lưu thành chữ để sửa', () {
    expect(minorUnitsToInput(155000, 0), '155000');
    expect(minorUnitsToInput(1250, 2), '12.5');
    expect(minorUnitsToInput(1200, 2), '12');
    expect(minorUnitsToInput(5, 2), '0.05');
  });

  test('phím trên bàn phím (AC-03)', () {
    String k(String e, String key) => applyKeypadKey(e, key, decimalDigits: 0);
    expect(k('12', '3'), '123');
    expect(k('12', keyBackspace), '1');
    expect(k('', keyBackspace), '');
    expect(k('', opAdd), '');
    expect(k('12+', opMul), '12×');
    expect(k('120+35', keyEquals), '155');
    expect(k('5÷0', keyEquals), '5÷0');
  });
}
