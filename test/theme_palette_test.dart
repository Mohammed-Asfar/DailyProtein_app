import 'dart:math' as math;

import 'package:daily_protein/core/theme/app_colors.dart';
import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _relativeLuminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double l1 = _relativeLuminance(a);
  final double l2 = _relativeLuminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('palette matches the design spec', () {
    test('dark theme', () {
      final ColorScheme s = AppTheme.dark.colorScheme;
      expect(s.primary, AppColors.darkPrimary);
      expect(s.tertiary, AppColors.darkAccent);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(s.surface, AppColors.darkSurface);
      expect(s.onSurface, AppColors.darkText);
    });

    test('light theme', () {
      final ColorScheme s = AppTheme.light.colorScheme;
      expect(s.primary, AppColors.lightPrimary);
      expect(s.tertiary, AppColors.lightAccent);
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(s.surface, AppColors.lightSurface);
      expect(s.onSurface, AppColors.lightText);
    });
  });

  group('contrast', () {
    for (final MapEntry<String, ThemeData> entry in <String, ThemeData>{
      'dark': AppTheme.dark,
      'light': AppTheme.light,
    }.entries) {
      final ColorScheme s = entry.value.colorScheme;

      test('${entry.key}: body text on surface clears 4.5:1', () {
        expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: secondary text on surface clears 4.5:1', () {
        expect(
          _contrast(s.onSurfaceVariant, s.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: text on a filled button clears 4.5:1', () {
        expect(_contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: primary as a UI mark clears 3:1', () {
        // Icons, rings and selected labels are components, not body text.
        expect(_contrast(s.primary, s.surface), greaterThanOrEqualTo(3.0));
        expect(
          _contrast(s.primary, entry.value.scaffoldBackgroundColor),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('${entry.key}: text on an accent fill clears 4.5:1', () {
        expect(_contrast(s.onTertiary, s.tertiary), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: accent text on its tinted container clears 4.5:1',
          () {
        // tertiaryContainer is translucent, so compose it over the surface
        // the way it actually paints.
        final Color pill =
            Color.alphaBlend(s.tertiaryContainer, s.surface);
        expect(
          _contrast(s.onTertiaryContainer, pill),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: accent text reads on a primary-tinted panel', () {
        // The add-food sheet shows the calorie figure on this panel.
        final Color panel = Color.alphaBlend(
          s.primary.withValues(alpha: 0.10),
          s.surface,
        );
        expect(
          _contrast(s.onTertiaryContainer, panel),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
