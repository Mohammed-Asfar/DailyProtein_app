/// Number formatting used across the app. Keeps decimal rules in one place.
class Fmt {
  const Fmt._();

  /// Trims a trailing `.0` so 12.0 shows as "12" but 12.5 stays "12.5".
  static String number(double value, {int decimals = 1}) {
    final String text = value.toStringAsFixed(decimals);
    if (!text.contains('.')) return text;
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String grams(double value) => '${number(value)} g';

  static String kcal(double value) => '${number(value, decimals: 0)} kcal';

  static String money(double value, String symbol) =>
      '$symbol${number(value, decimals: 2)}';

  static String perGram(double value, String symbol) =>
      '${money(value, symbol)}/g';
}
