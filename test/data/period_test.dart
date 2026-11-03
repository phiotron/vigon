import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/src/data/period.dart';

void main() {
  final tue = DateTime(2026, 11, 3, 15, 30); // Thứ Ba

  group('kỳ chứa một ngày (AC-10)', () {
    test('ngày', () {
      final p = Period.containing(PeriodType.day, tue);
      expect((p.fromKey, p.toKey), ('2026-11-03', '2026-11-03'));
    });

    test('tuần bắt đầu Thứ Hai và Chủ Nhật (AC-12)', () {
      final mon = Period.containing(PeriodType.week, tue);
      expect((mon.fromKey, mon.toKey), ('2026-11-02', '2026-11-08'));
      final sun = Period.containing(
        PeriodType.week,
        tue,
        weekStart: DateTime.sunday,
      );
      expect((sun.fromKey, sun.toKey), ('2026-11-01', '2026-11-07'));
    });

    test('tháng bắt đầu ngày 1 và ngày 25 (AC-12)', () {
      final m = Period.containing(PeriodType.month, tue);
      expect((m.fromKey, m.toKey), ('2026-11-01', '2026-11-30'));
      final pay = Period.containing(PeriodType.month, tue, monthStartDay: 25);
      expect((pay.fromKey, pay.toKey), ('2026-10-25', '2026-11-24'));
    });

    test('năm và tất cả', () {
      final y = Period.containing(PeriodType.year, tue);
      expect((y.fromKey, y.toKey), ('2026-01-01', '2026-12-31'));
      final all = Period.containing(PeriodType.all, tue);
      expect(all.contains('1999-05-05'), isTrue);
      expect(all.contains('2090-01-01'), isTrue);
    });

    test('khoảng tùy chọn đổi chỗ khi chọn ngược', () {
      final c = Period.custom(DateTime(2026, 11, 10), DateTime(2026, 11, 1));
      expect((c.fromKey, c.toKey), ('2026-11-01', '2026-11-10'));
    });
  });

  group('chuyển kỳ trước, kỳ sau (AC-11)', () {
    test('tháng qua cuối năm', () {
      final dec = Period.containing(PeriodType.month, DateTime(2026, 12, 15));
      final jan = dec.shift(1);
      expect((jan.fromKey, jan.toKey), ('2027-01-01', '2027-01-31'));
      expect(jan.shift(-1), dec);
    });

    test('tháng ngắn: tháng 2 năm nhuận', () {
      final feb = Period.containing(PeriodType.month, DateTime(2028, 2, 10));
      expect(feb.toKey, '2028-02-29');
      expect(feb.shift(1).toKey, '2028-03-31');
    });

    test('tuần, ngày, năm', () {
      final w = Period.containing(PeriodType.week, tue).shift(-1);
      expect((w.fromKey, w.toKey), ('2026-10-26', '2026-11-01'));
      expect(
        Period.containing(PeriodType.day, tue).shift(1).fromKey,
        '2026-11-04',
      );
      expect(
        Period.containing(PeriodType.year, tue).shift(-1).fromKey,
        '2025-01-01',
      );
    });

    test('khoảng tùy chọn dịch đúng độ dài', () {
      final c = Period.custom(DateTime(2026, 11, 1), DateTime(2026, 11, 10));
      final next = c.shift(1);
      expect((next.fromKey, next.toKey), ('2026-11-11', '2026-11-20'));
    });

    test('tháng bắt đầu ngày 25 dịch giữ ngày 25', () {
      final p = Period.containing(PeriodType.month, tue, monthStartDay: 25);
      final next = p.shift(1);
      expect((next.fromKey, next.toKey), ('2026-11-25', '2026-12-24'));
    });
  });
}
