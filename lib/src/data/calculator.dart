import 'dart:math';

/// Ký hiệu phép tính trên bàn phím số của app (AC-03).
const opAdd = '+', opSub = '−', opMul = '×', opDiv = '÷';
const _ops = {opAdd, opSub, opMul, opDiv};

/// Số tiền tối đa một khoản, theo đơn vị nhỏ nhất (VND: 1.000 tỷ đồng). Nhỏ hơn
/// nhiều so với giới hạn số nguyên 64-bit nên cộng hàng nghìn khoản không tràn.
const maxMinorUnits = 1000000000000;

bool isOperator(String s) => _ops.contains(s);

/// Tính biểu thức trên bàn phím, ví dụ `120+35` hoặc `12.5×2`, ra số tiền
/// theo đơn vị nhỏ nhất với [decimalDigits] chữ số thập phân.
/// Nhân chia trước, cộng trừ sau. Trả về null khi biểu thức rỗng hoặc sai
/// (chia cho 0, thiếu số sau phép tính, nhiều dấu chấm) hoặc kết quả vượt [maxMinorUnits].
int? evaluateToMinorUnits(String expression, {required int decimalDigits}) {
  final tokens = _tokenize(expression);
  if (tokens == null || tokens.isEmpty) return null;

  // Gộp nhân chia trước.
  final terms = <double>[];
  final signs = <String>[];
  double? current;
  String? pending;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (i.isEven) {
      final value = double.parse(t);
      if (current == null) {
        current = value;
      } else if (pending == opMul) {
        current *= value;
      } else if (pending == opDiv) {
        if (value == 0) return null;
        current /= value;
      }
    } else if (t == opMul || t == opDiv) {
      pending = t;
    } else {
      terms.add(current!);
      signs.add(t);
      current = null;
      pending = null;
    }
  }
  terms.add(current!);

  var result = terms.first;
  for (var i = 0; i < signs.length; i++) {
    result = signs[i] == opAdd ? result + terms[i + 1] : result - terms[i + 1];
  }
  // Bỏ nhiễu số thực (1.005 × 100 = 100.49999999999999) trước khi làm tròn nửa lên.
  final scaled = double.parse(
    (result * pow(10, decimalDigits)).toStringAsPrecision(15),
  );
  if (scaled.abs() > maxMinorUnits) return null;
  return scaled.round();
}

/// Tách thành [số, phép, số, phép, ..., số]; null nếu sai cú pháp.
List<String>? _tokenize(String expression) {
  final tokens = <String>[];
  final number = StringBuffer();
  for (final ch in expression.split('')) {
    if (isOperator(ch)) {
      if (number.isEmpty) return null;
      tokens
        ..add(number.toString())
        ..add(ch);
      number.clear();
    } else if (ch == '.' ||
        (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57)) {
      if (ch == '.' && number.toString().contains('.')) return null;
      number.write(ch);
    } else {
      return null;
    }
  }
  if (number.isEmpty) return tokens.isEmpty ? <String>[] : null;
  if (number.toString() == '.') return null;
  tokens.add(number.toString());
  return tokens;
}
