import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';

/// Preset windows plus a custom date range.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.rangeDays,
    required this.customRange,
    required this.onPreset,
    required this.onCustom,
  });

  final int rangeDays;
  final DateTimeRange? customRange;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;

  static const List<int> _presets = <int>[7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isCustom = customRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Spelled-out labels plus a fourth chip overflow a phone row, so
        // the presets abbreviate and the custom option is an icon button.
        Row(
          children: <Widget>[
            for (final int preset in _presets) ...<Widget>[
              Expanded(
                child: _RangeChip(
                  label: '${preset}d',
                  selected: !isCustom && preset == rangeDays,
                  onTap: () => onPreset(preset),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            _CalendarButton(selected: isCustom, onTap: onCustom),
          ],
        ),
        if (isCustom) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Icon(
                Icons.event_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${DayKey.pretty(DayKey.of(customRange!.start))}'
                  '  —  '
                  '${DayKey.pretty(DayKey.of(customRange!.end))}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square icon button that opens the date-range picker. Icon-only so the
/// preset chips keep the width they need.
class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Tooltip(
      message: 'Pick a date range',
      child: Material(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Ink(
            height: _size,
            width: _size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
