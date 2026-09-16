import '../../log/models/food_entry.dart';

/// The numbers behind the History screen for one selected range.
///
/// Pure: given the days in the window and their totals, every figure the
/// screen shows is derived here, so the arithmetic can be tested without a
/// database or a widget tree.
class HistorySummary {
  const HistorySummary({
    required this.days,
    required this.range,
    required this.hasAnyHistory,
  });

  final List<String> days;
  final Map<String, DayTotals> range;

  /// True when the database holds at least one entry, anywhere. Separates
  /// "you have never logged" from "nothing in this range".
  final bool hasAnyHistory;

  /// Days inside the selected range that have entries, newest first. Days
  /// with nothing logged are left out rather than listed as empty rows.
  List<DayTotals> get loggedDays => days.reversed
      .map((String day) => range[day])
      .whereType<DayTotals>()
      .toList();

  /// Average across the whole window, counting untracked days as zero so the
  /// number reflects real intake rather than only the days you remembered.
  double get averageProtein {
    if (days.isEmpty) return 0;
    final double sum = days.fold<double>(
      0,
      (double total, String day) => total + (range[day]?.protein ?? 0),
    );
    return sum / days.length;
  }

  double get totalCost => days.fold<double>(
        0,
        (double total, String day) => total + (range[day]?.cost ?? 0),
      );

  double get totalProtein => days.fold<double>(
        0,
        (double total, String day) => total + (range[day]?.protein ?? 0),
      );

  double? get costPerGram {
    if (totalCost <= 0 || totalProtein <= 0) return null;
    return totalCost / totalProtein;
  }

  int daysHittingGoal(double goal) {
    if (goal <= 0) return 0;
    return days
        .where((String day) => (range[day]?.protein ?? 0) >= goal)
        .length;
  }
}

