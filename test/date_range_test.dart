import 'package:daily_protein/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daysBetween', () {
    test('includes both endpoints', () {
      final List<String> days = DayKey.daysBetween(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 5),
      );
      expect(days.length, 5);
      expect(days.first, '2026-09-01');
      expect(days.last, '2026-09-05');
    });

    test('a single day is one key, not zero', () {
      final List<String> days = DayKey.daysBetween(
        DateTime(2026, 9, 16),
        DateTime(2026, 9, 16),
      );
      expect(days, <String>['2026-09-16']);
    });

    test('spans month and year boundaries', () {
      final List<String> days = DayKey.daysBetween(
        DateTime(2025, 12, 30),
        DateTime(2026, 1, 2),
      );
      expect(days, <String>[
        '2025-12-30',
        '2025-12-31',
        '2026-01-01',
        '2026-01-02',
      ]);
    });

    test('ignores the time of day', () {
      final List<String> days = DayKey.daysBetween(
        DateTime(2026, 9, 1, 23, 59),
        DateTime(2026, 9, 2, 0, 1),
      );
      expect(days, <String>['2026-09-01', '2026-09-02']);
    });

    test('a reversed range yields nothing rather than throwing', () {
      expect(
        DayKey.daysBetween(DateTime(2026, 9, 5), DateTime(2026, 9, 1)),
        isEmpty,
      );
    });

    test('keys sort lexicographically, which is why they are strings', () {
      final List<String> days = DayKey.daysBetween(
        DateTime(2026, 8, 28),
        DateTime(2026, 9, 3),
      );
      final List<String> sorted = List<String>.from(days)..sort();
      expect(days, sorted);
    });
  });
}
