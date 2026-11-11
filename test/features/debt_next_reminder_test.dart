// Chip "Nhắc ngày …" ở Khoản nợ khớp lịch thông báo thật (D-044, D-045):
// mốc N ngày trước mà giờ nhắc đã qua thì chuyển sang mốc ngày hạn.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/features/debts/debts_screen.dart';

void main() {
  final due = DateTime(2026, 11, 18);
  const nine = TimeOfDay(hour: 9, minute: 0);

  test('trước giờ nhắc của mốc N ngày trước: còn mốc đó', () {
    expect(
      nextDeadlineReminder(due, 7, DateTime(2026, 11, 11, 8, 59), nine),
      DateTime(2026, 11, 11),
    );
  });

  test('đã qua giờ nhắc của mốc N ngày trước: mốc ngày hạn', () {
    expect(
      nextDeadlineReminder(due, 7, DateTime(2026, 11, 11, 9, 32), nine),
      due,
    );
  });

  test('cả hai mốc đã nổ: không còn chip', () {
    expect(
      nextDeadlineReminder(due, 7, DateTime(2026, 11, 18, 9, 0), nine),
      isNull,
    );
  });

  test('không có hạn: không có chip', () {
    expect(
      nextDeadlineReminder(null, 7, DateTime(2026, 11, 11), nine),
      isNull,
    );
  });
}
