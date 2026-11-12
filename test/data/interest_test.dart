import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/data/interest.dart';

/// AC-172..AC-174: lãi đơn theo ngày trên gốc còn lại, năm 365 ngày, phân số
/// chính xác, làm tròn một lần nửa lên.
void main() {
  DebtInterest loan(
    int principal, {
    required int annual,
    DateTime? start,
    List<RateStep> changes = const [],
    List<PaymentStep> payments = const [],
  }) {
    final s = start ?? DateTime(2026, 11, 1);
    return DebtInterest(
      principal: principal,
      start: s,
      rates: [(from: s, annual: annual), ...changes],
      payments: payments,
    );
  }

  test('AC-172: 10 triệu, 12 %/năm, 30 ngày → 98.630 ₫', () {
    final d = loan(10000000, annual: 1200);
    expect(d.accrued(DateTime(2026, 12, 1)), 98630);
    expect(d.remaining(DateTime(2026, 12, 1)), 10098630);
  });

  test('AC-172: 1 %/tháng cho cùng kết quả; 5 triệu 30 ngày → 49.315 ₫', () {
    expect(annualRateOf(100, InterestPeriod.month), 1200);
    final d = loan(10000000, annual: annualRateOf(100, InterestPeriod.month));
    expect(d.accrued(DateTime(2026, 12, 1)), 98630);
    final five = loan(5000000, annual: annualRateOf(100, InterestPeriod.month));
    expect(five.accrued(DateTime(2026, 12, 1)), 49315);
  });

  test('AC-174: hạn 30/01/2027 (90 ngày) → phải trả khoảng 10.295.890 ₫', () {
    final d = loan(10000000, annual: 1200);
    expect(d.dueEstimate(DateTime(2027, 1, 30)), 10295890);
  });

  test('ngày vay và ngày trước khi bắt đầu: lãi 0', () {
    final d = loan(10000000, annual: 1200);
    expect(d.accrued(DateTime(2026, 11, 1)), 0);
    expect(d.accrued(DateTime(2026, 10, 1)), 0);
    expect(d.accrued(DateTime(2026, 11, 2)), 3288); // 3.287,67
  });

  test('AC-173: trả 1.000.000 ngày 01/12 → lãi 98.630, gốc 901.370; từ '
      '01/12 lãi trên 9.098.630', () {
    final d = loan(10000000, annual: 1200);
    final split = d.split(1000000, DateTime(2026, 12, 1));
    expect(split, (interest: 98630, principal: 901370));
    final after = loan(
      10000000,
      annual: 1200,
      payments: [
        (date: DateTime(2026, 12, 1), principal: 901370, interest: 98630),
      ],
    );
    expect(after.principalLeft, 9098630);
    expect(after.unpaidInterest(DateTime(2026, 12, 1)), 0);
    // 31 ngày tháng 12 trên 9.098.630: 92.731,2… (cộng dồn chính xác với
    // 30 ngày trước rồi mới làm tròn).
    final exact = (10000000 * 1200 * 30 + 9098630 * 1200 * 31) / 3650000;
    expect(after.accrued(DateTime(2027, 1, 1)), (exact + 0.5).floor());
    expect(after.unpaidInterest(DateTime(2027, 1, 1)), 92731);
  });

  test('số trả nhỏ hơn lãi: tất cả là lãi', () {
    final d = loan(10000000, annual: 1200);
    expect(d.split(50000, DateTime(2026, 12, 1)), (
      interest: 50000,
      principal: 0,
    ));
  });

  test('đổi lãi suất giữa chừng: áp từ ngày đổi (gồm)', () {
    final d = loan(
      10000000,
      annual: 1200,
      changes: [(from: DateTime(2026, 11, 11), annual: 2400)],
    );
    // 10 ngày × 12 % + 20 ngày × 24 % = 32.876,7 + 131.506,8 = 164.383,56
    expect(d.accrued(DateTime(2026, 12, 1)), 164384);
  });

  test('ngày bắt đầu tính lãi muộn hơn ngày vay (ân hạn)', () {
    final d = loan(10000000, annual: 1200, start: DateTime(2026, 11, 16));
    // 15 ngày: 49.315,07
    expect(d.accrued(DateTime(2026, 12, 1)), 49315);
  });

  test('năm nhuận vẫn chia 365: 366 ngày của 2028 → 12,0329 %', () {
    final d = loan(10000000, annual: 1200, start: DateTime(2028, 1, 1));
    // 10.000.000 × 12 % × 366 / 365 = 1.203.287,67
    expect(d.accrued(DateTime(2029, 1, 1)), 1203288);
  });

  test('trả hết gốc: lãi ngừng tích; còn lại = lãi chưa trả', () {
    final d = loan(
      10000000,
      annual: 1200,
      payments: [
        (date: DateTime(2026, 12, 1), principal: 10000000, interest: 0),
      ],
    );
    expect(d.principalLeft, 0);
    expect(d.accrued(DateTime(2027, 6, 1)), 98630);
    expect(d.remaining(DateTime(2027, 6, 1)), 98630);
  });

  test('không lãi: còn lại = gốc còn lại', () {
    final d = DebtInterest(
      principal: 500,
      start: DateTime(2026, 1, 1),
      rates: const [],
      payments: [(date: DateTime(2026, 2, 1), principal: 200, interest: 0)],
    );
    expect(d.hasInterest, isFalse);
    expect(d.remaining(DateTime(2027, 1, 1)), 300);
  });
}
