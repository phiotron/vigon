import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/text_fold.dart';

void main() {
  test('bỏ dấu và hạ chữ hoa tiếng Việt (AC-48)', () {
    expect(foldText('Cà phê'), 'ca phe');
    expect(foldText('CÀ PHÊ'), 'ca phe');
    expect(foldText('Ăn uống'), 'an uong');
    expect(foldText('Người thân, Giáo dục'), 'nguoi than, giao duc');
    expect(foldText('Hoàng Quỳnh Ữ ỷ ợ ẫ'), 'hoang quynh u y o a');
  });

  test('đ và Đ thành d', () {
    expect(foldText('Đường đi'), 'duong di');
    expect(foldText('ĐỀN'), 'den');
  });

  test('chữ gõ dạng tổ hợp (dấu rời) cũng được gấp', () {
    // "ê" + dấu sắc, "ơ" + dấu móc rời + dấu nặng.
    expect(foldText('ế'), 'e');
    expect(foldText('ợ'), 'o');
  });

  test('chữ Latin, số và ký tự khác giữ nguyên (chỉ hạ chữ hoa)', () {
    expect(foldText('Grab 155.000 ₫'), 'grab 155.000 ₫');
    expect(foldText(''), '');
  });
}
