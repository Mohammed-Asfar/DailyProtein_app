import 'package:flutter/material.dart';

import '../../../core/models/body_profile.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import 'onboarding_parts.dart';

/// Heading and supporting line shared by every setup step.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.highlight,
    required this.body,
  });

  final String title;
  final String highlight;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OnboardingTitle(
          title: title,
          highlight: highlight,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Step 1: the numbers behind the estimate.
class BodyDetailsStep extends StatelessWidget {
  const BodyDetailsStep({
    super.key,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.onSexChanged,
    required this.onAgeChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
  });

  final BodySex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ValueChanged<BodySex> onSexChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _StepHeader(
          title: "Let's Personalise",
          highlight: 'Your Experience',
          body: 'This helps us give you accurate recommendations.',
        ),
        _FieldLabel('Your Gender'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            for (final BodySex option in BodySex.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == BodySex.values.first ? AppSpacing.md : 0,
                  ),
                  child: _SexTile(
                    option: option,
                    selected: option == sex,
                    onTap: () => onSexChanged(option),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SliderField(
          label: 'Your Age',
          value: '$age years',
          sliderValue: age.toDouble(),
          min: 13,
          max: 90,
          divisions: 77,
          onChanged: (double value) => onAgeChanged(value.round()),
        ),
        _SliderField(
          label: 'Your Height',
          value: '${Fmt.number(heightCm, decimals: 0)} cm',
          sliderValue: heightCm,
          min: 120,
          max: 220,
          divisions: 100,
          onChanged: onHeightChanged,
        ),
        _SliderField(
          label: 'Your Weight',
          value: '${Fmt.number(weightKg, decimals: 0)} kg',
          sliderValue: weightKg,
          min: 30,
          max: 200,
          divisions: 170,
          onChanged: onWeightChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SexTile extends StatelessWidget {
  const _SexTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final BodySex option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                option == BodySex.male ? Icons.male_rounded : Icons.female_rounded,
                size: 20,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                option == BodySex.male ? 'Male' : 'Female',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.sliderValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String value;
  final double sliderValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FieldLabel(label),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Step 2: what the user is aiming for.
class GoalStep extends StatelessWidget {
  const GoalStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FitnessGoal selected;
  final ValueChanged<FitnessGoal> onChanged;

  static const Map<FitnessGoal, IconData> _icons = <FitnessGoal, IconData>{
    FitnessGoal.loseWeight: Icons.monitor_weight_outlined,
    FitnessGoal.maintainWeight: Icons.track_changes_rounded,
    FitnessGoal.buildMuscle: Icons.fitness_center_rounded,
    FitnessGoal.beHealthier: Icons.favorite_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _StepHeader(
          title: "What's",
          highlight: 'Your Goal?',
          body: 'Choose the option that best fits your journey.',
        ),
        for (final FitnessGoal goal in FitnessGoal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _GoalTile(
              goal: goal,
              icon: _icons[goal]!,
              selected: goal == selected,
              onTap: () => onChanged(goal),
            ),
          ),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final FitnessGoal goal;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            // Selection is carried by the border and the tick, not colour
            // alone, so it survives both themes.
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      goal.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Steps 3 and 4: a single number on a slider, with the estimate explained.
class TargetStep extends StatelessWidget {
  const TargetStep({
    super.key,
    required this.title,
    required this.highlight,
    required this.body,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.hint,
    required this.hintIcon,
    required this.onChanged,
    this.suffix = '',
  });

  final String title;
  final String highlight;
  final String body;
  final double value;
  final double min;
  final double max;

  /// Slider granularity, so the number lands on a round figure.
  final double step;

  final String unit;
  final String suffix;
  final String hint;
  final IconData hintIcon;
  final ValueChanged<double> onChanged;

  /// How many scale labels to print under the track.
  static const int ticks = 5;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double clamped = value.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StepHeader(title: title, highlight: highlight, body: body),
        Center(
          child: Text(
            '${Fmt.number(clamped, decimals: 0)}$suffix',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Center(
          child: Text(
            unit,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Slider(
          value: clamped,
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          onChanged: onChanged,
        ),
        // Evenly spaced ticks rather than just the two ends, so the scale
        // is readable and the current value has context either side.
        Row(
          children: <Widget>[
            for (int i = 0; i < ticks; i++)
              Expanded(
                child: Text(
                  Fmt.number(
                    min + (max - min) * i / (ticks - 1),
                    decimals: 0,
                  ),
                  textAlign: i == 0
                      ? TextAlign.start
                      : i == ticks - 1
                          ? TextAlign.end
                          : TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(hintIcon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
