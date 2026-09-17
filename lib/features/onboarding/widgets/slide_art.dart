import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Illustrations for the intro slides.
///
/// Drawn with widgets rather than shipped as images: they have to work on
/// both the light and dark slides, and an exported PNG would bake in one
/// background and one set of colours.

/// A small white card with an icon, a figure and a caption. The chips that
/// float around the meal illustration.
class MacroChip extends StatelessWidget {
  const MacroChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide 1 art: a meal with its macros called out around it.
class MealArt extends StatelessWidget {
  const MealArt({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.dinner_dining_rounded,
              size: 96,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: MacroChip(
              icon: Icons.local_fire_department_rounded,
              value: '320',
              label: 'Calories',
              tint: theme.colorScheme.tertiary,
            ),
          ),
          Positioned(
            top: 40,
            right: 0,
            child: MacroChip(
              icon: Icons.fitness_center_rounded,
              value: '25g',
              label: 'Protein',
              tint: theme.colorScheme.primary,
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            child: MacroChip(
              icon: Icons.eco_rounded,
              value: '40g',
              label: 'Carbs',
              tint: theme.colorScheme.primary,
            ),
          ),
          Positioned(
            bottom: 64,
            right: 8,
            child: MacroChip(
              icon: Icons.water_drop_rounded,
              value: '12g',
              label: 'Fats',
              tint: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 2 art: a week of rising bars under an encouraging badge.
class ProgressArt extends StatelessWidget {
  const ProgressArt({super.key});

  /// Relative bar heights. Rising, but not a straight line — a perfect ramp
  /// looks like a diagram rather than somebody's week.
  static const List<double> _bars = <double>[
    0.30,
    0.42,
    0.38,
    0.58,
    0.66,
    0.82,
    1.00,
  ];

  static const List<String> _days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 260,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Flexible, not fixed: at the largest text scales the
                // badge would otherwise be wider than the card it sits in.
                Flexible(
                  child: Text(
                    "You're Doing Great!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < _bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: _bars[i],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    // The week builds toward today, so the
                                    // most recent bars read strongest.
                                    alpha: 0.45 + 0.55 * _bars[i],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _days[i],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 3 art: the reasons people track, as labelled bubbles.
class GoalsArt extends StatelessWidget {
  const GoalsArt({super.key});

  static const List<(IconData, String)> _items = <(IconData, String)>[
    (Icons.fitness_center_rounded, 'Build Muscle'),
    (Icons.monitor_weight_outlined, 'Lose Weight'),
    (Icons.favorite_rounded, 'Stay Healthy'),
    (Icons.bolt_rounded, 'More Energy'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: <Widget>[
          for (final (IconData icon, String label) in _items)
            _GoalBubble(icon: icon, label: label),
        ],
      ),
    );
  }
}

class _GoalBubble extends StatelessWidget {
  const _GoalBubble({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 112,
      width: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surface,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 34, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
