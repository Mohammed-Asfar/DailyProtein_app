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

double _contrast(Color a, Color b) {
  final double l1 = _relativeLuminance(a);
  final double l2 = _relativeLuminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// The tint square a row icon is drawn on, composed over the card surface
/// exactly as SettingsRow paints it.
Color _tile(Color icon, Color surface) =>
    Color.alphaBlend(icon.withValues(alpha: 0.16), surface);

void main() {
  for (final MapEntry<String, ThemeData> entry in <String, ThemeData>{
    'dark': AppTheme.dark,
    'light': AppTheme.light,
  }.entries) {
    testWidgets('${entry.key}: every row icon reads on its own tint', (
      WidgetTester tester,
    ) async {
      late AppIconColors icons;
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: Builder(
            builder: (BuildContext context) {
              icons = AppIconColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final Color surface = entry.value.colorScheme.surface;
      final Map<String, Color> palette = <String, Color>{
        'flame': icons.flame,
        'chart': icons.chart,
        'leaf': icons.leaf,
        'violet': icons.violet,
        'amber': icons.amber,
        'cyan': icons.cyan,
        'danger': icons.danger,
      };

      for (final MapEntry<String, Color> icon in palette.entries) {
        expect(
          _contrast(icon.value, _tile(icon.value, surface)),
          greaterThanOrEqualTo(3.0),
          reason: '"${icon.key}" is too faint against its tinted square in '
              '${entry.key} mode',
        );
      }
    });
  }

  test('light mode uses deeper shades than dark mode', () {
    // Sharing one set is what washed the icons out on white.
    expect(AppColors.iconFlameLight, isNot(AppColors.iconFlameDark));
    expect(AppColors.iconLeafLight, isNot(AppColors.iconLeafDark));
    expect(AppColors.iconAmberLight, isNot(AppColors.iconAmberDark));
    expect(AppColors.iconCyanLight, isNot(AppColors.iconCyanDark));
  });
}
