/// Which illustration a slide shows. An enum rather than a widget so the
/// slide list stays a plain const.
enum SlideArtKind { meal, progress, goals }

/// One explanatory slide in the welcome flow.
class OnboardingPage {
  const OnboardingPage({
    required this.art,
    required this.title,
    required this.highlight,
    required this.body,
    required this.dark,
  });

  final SlideArtKind art;

  /// First half of the heading, in the default text colour.
  final String title;

  /// Second half, painted in the brand colour. Split rather than marked up
  /// inline so the copy stays plain strings.
  final String highlight;

  /// One or two sentences. Longer than that and it stops being read.
  final String body;

  /// Whether this slide forces the dark theme. Alternating light and dark
  /// gives the carousel rhythm, so a slide looks the same whichever theme
  /// the phone is in.
  final bool dark;
}
