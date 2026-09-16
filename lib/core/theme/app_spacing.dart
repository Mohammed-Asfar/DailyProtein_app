/// Spacing and radius scale. Single source of truth for layout metrics.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Vertical room a scrollable must leave at its bottom so content clears
  /// the floating nav bar, which overlays the body rather than displacing it.
  /// Sized for the taller variant that carries the raised centre button;
  /// screens without it simply end with a little extra space.
  static const double navBarClearance = 120;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 999;
}
