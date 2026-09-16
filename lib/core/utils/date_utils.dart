import 'package:intl/intl.dart';

/// Day keys are `yyyy-MM-dd` strings so they sort lexicographically
/// and survive JSON export unchanged.
class DayKey {
  const DayKey._();

  static final DateFormat _key = DateFormat('yyyy-MM-dd');
  static final DateFormat _pretty = DateFormat('EEE, d MMM');
  static final DateFormat _full = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _short = DateFormat('E');
  static final DateFormat _dayOfMonth = DateFormat('d MMM');
  static final DateFormat _dayNumber = DateFormat('d');

  static String of(DateTime date) => _key.format(date);

  static String get today => of(DateTime.now());

  static DateTime parse(String key) => _key.parse(key);

  static String pretty(String key) => _pretty.format(parse(key));

  static String full(String key) => _full.format(parse(key));

  static String weekday(String key) => _short.format(parse(key));

  /// "4 Sep". Used where weekday names would repeat and stop being useful.
  static String dayOfMonth(String key) => _dayOfMonth.format(parse(key));

  /// Just the day number, "4". For dense axes where "4 Sep" would not fit.
  static String dayNumber(String key) => _dayNumber.format(parse(key));

  static bool isToday(String key) => key == today;

  static String label(String key) {
    if (isToday(key)) return 'Today';
    final String yesterday =
        of(DateTime.now().subtract(const Duration(days: 1)));
    if (key == yesterday) return 'Yesterday';
    return pretty(key);
  }

  /// The last [count] day keys ending with today, oldest first.
  /// Every day key from [from] to [to] inclusive, oldest first.
  static List<String> daysBetween(DateTime from, DateTime to) {
    final DateTime start = DateTime(from.year, from.month, from.day);
    final DateTime end = DateTime(to.year, to.month, to.day);
    final int span = end.difference(start).inDays;
    if (span < 0) return <String>[];
    return List<String>.generate(
      span + 1,
      (int i) => of(start.add(Duration(days: i))),
    );
  }

  static List<String> lastDays(int count) {
    final DateTime now = DateTime.now();
    return List<String>.generate(
      count,
      (int i) => of(now.subtract(Duration(days: count - 1 - i))),
    );
  }
}
