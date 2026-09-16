import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// Animated circular gauge showing progress toward the daily goal.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.goal,
    this.size = 190,
    this.strokeWidth = 14,
    this.unit = 'g',
  });

  final double value;
  final double goal;
  final double size;
  final double strokeWidth;
  final String unit;

  double get _progress => goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

  bool get _goalReached => goal > 0 && value >= goal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double remaining = math.max(0, goal - value);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _progress),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, _) {
        return SizedBox(
          height: size,
          width: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: animated,
              strokeWidth: strokeWidth,
              // A primary-tinted track, so the unfilled ring still reads as
              // part of the app rather than plain grey.
              trackColor: theme.colorScheme.primary.withValues(alpha: 0.18),
              // The accent fills the ring as you make progress: it is the
              // one warm mark on the screen and draws the eye to the number.
              progressColor: theme.colorScheme.tertiary,
              // Past the goal a second primary arc rides inside the accent.
              overflowColor: theme.colorScheme.primary,
              overflow: goal > 0 ? math.max(0, (value / goal) - 1) : 0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    Fmt.number(value),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of ${Fmt.number(goal)} $unit',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      // The arc carries the accent, so the pill stays on the
                      // primary and does not compete with it.
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      _goalReached
                          ? 'Goal reached'
                          : '${Fmt.number(remaining)} $unit left',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    required this.overflowColor,
    required this.overflow,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Color overflowColor;

  /// Fraction past the goal, drawn as a second lighter arc.
  final double overflow;

  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      // Solid rather than a gradient: a short arc drawn from a faded stop
      // reads as washed out at exactly the values where it matters most.
      final Paint arc = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _start, 2 * math.pi * progress, false, arc);
    }

    if (overflow > 0) {
      final Paint extra = Paint()
        ..color = overflowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.45
        ..strokeCap = StrokeCap.round;
      final Rect inner = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth * 0.85,
      );
      canvas.drawArc(
        inner,
        _start,
        2 * math.pi * overflow.clamp(0.0, 1.0),
        false,
        extra,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.overflow != overflow ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
