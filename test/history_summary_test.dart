import 'package:daily_protein/features/history/models/history_summary.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:flutter_test/flutter_test.dart';

DayTotals _day(String date, double protein, {double cost = 0}) => DayTotals(
      date: date,
      protein: protein,
      calories: 0,
      cost: cost,
      entryCount: 1,
    );

/// A window of five days, with entries on only three of them.
HistorySummary _summary() {
  const List<String> days = <String>[
    '2026-09-12',
    '2026-09-13',
    '2026-09-14',
    '2026-09-15',
    '2026-09-16',
  ];
  return HistorySummary(
    days: days,
    range: <String, DayTotals>{
      '2026-09-12': _day('2026-09-12', 100, cost: 200),
      '2026-09-14': _day('2026-09-14', 130, cost: 260),
      '2026-09-16': _day('2026-09-16', 70, cost: 140),
    },
    hasAnyHistory: true,
  );
}

void main() {
  group('loggedDays', () {
    test('lists only days inside the range that have entries', () {
      expect(_summary().loggedDays.length, 3);
    });

    test('is newest first', () {
      expect(
        _summary().loggedDays.map((DayTotals d) => d.date).toList(),
        <String>['2026-09-16', '2026-09-14', '2026-09-12'],
      );
    });

    test('excludes days logged outside the selected range', () {
      final HistorySummary summary = HistorySummary(
        days: const <String>['2026-09-15', '2026-09-16'],
        range: <String, DayTotals>{
          '2026-09-16': _day('2026-09-16', 70),
        },
        hasAnyHistory: true,
      );
      // An August day exists in the database but is not in this window, so
      // it must not appear.
      expect(summary.loggedDays.length, 1);
      expect(summary.loggedDays.single.date, '2026-09-16');
    });

    test('an empty range yields an empty list, not an error', () {
      final HistorySummary summary = HistorySummary(
        days: const <String>['2026-09-15', '2026-09-16'],
        range: const <String, DayTotals>{},
        hasAnyHistory: true,
      );
      expect(summary.loggedDays, isEmpty);
    });
  });

  group('derived figures', () {
    test('average counts untracked days as zero', () {
      // 300 g over five days, not over the three that were logged.
      expect(_summary().averageProtein, 60);
    });

    test('totals sum only the days in the window', () {
      expect(_summary().totalProtein, 300);
      expect(_summary().totalCost, 600);
    });

    test('cost per gram divides spend by protein', () {
      expect(_summary().costPerGram, closeTo(2.0, 0.0001));
    });

    test('no spend means no cost per gram', () {
      final HistorySummary summary = HistorySummary(
        days: const <String>['2026-09-16'],
        range: <String, DayTotals>{'2026-09-16': _day('2026-09-16', 70)},
        hasAnyHistory: true,
      );
      expect(summary.costPerGram, isNull);
    });

    test('counts days at or above the goal', () {
      expect(_summary().daysHittingGoal(100), 2);
      expect(_summary().daysHittingGoal(140), 0);
    });

    test('a goal of zero counts nothing rather than everything', () {
      expect(_summary().daysHittingGoal(0), 0);
    });
  });
}
