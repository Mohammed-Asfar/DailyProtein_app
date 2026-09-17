import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Two-tone heading: plain text, then the brand colour.
///
/// Wraps as one paragraph rather than two stacked lines, so a long title
/// breaks where it fits instead of always at the colour change.
class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({
    super.key,
    required this.title,
    required this.highlight,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final String highlight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? base = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: title.isEmpty ? '' : '$title '),
          TextSpan(
            text: highlight,
            style: base?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
      textAlign: textAlign,
      style: base,
    );
  }
}

/// Page indicator for the intro slides.
///
/// The current page widens into a pill rather than only changing colour, so
/// position is readable without relying on the colour difference alone.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  static const double _size = 8;
  static const double _activeWidth = 22;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            height: _size,
            width: i == index ? _activeWidth : _size,
            decoration: BoxDecoration(
              color: i == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
      ],
    );
  }
}

/// Step progress for the setup half of the flow, where the user is filling
/// things in and wants to know how much is left.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.total,
  });

  /// One-based.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: LinearProgressIndicator(
        value: step / total,
        minHeight: 6,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }
}

/// The wide action button every onboarding screen ends with.
class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label),
            if (icon != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular icon badge used as each slide's illustration.
class OnboardingBadge extends StatelessWidget {
  const OnboardingBadge({super.key, required this.icon, this.size = 132});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
