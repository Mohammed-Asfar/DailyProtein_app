import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// One destination in the [FloatingNavBar].
class NavItem {
  const NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating pill navigation bar, optionally with an elevated action button
/// raised out of its middle.
///
/// When [onCenterPressed] is null the button is omitted and the tabs spread
/// evenly across the full width, so the action can be offered only on the
/// screens where it means something.
///
/// With the button present, items are split evenly either side of it, so an
/// even number of them is expected.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.onCenterPressed,
    this.centerIcon = Icons.add_rounded,
    this.centerTooltip,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Null hides the centre button entirely.
  final VoidCallback? onCenterPressed;

  final IconData centerIcon;
  final String? centerTooltip;

  /// Diameter of the raised centre button.
  static const double _centerSize = 62;

  /// Height of the pill itself, excluding the part of the button above it.
  static const double _barHeight = 72;

  /// How much of the button sits above the top edge of the pill. A little
  /// under half its height, so it overlaps the pill rather than floating
  /// clear of it.
  static const double _centerLift = 24;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final VoidCallback? centerAction = onCenterPressed;
    final bool hasCenter = centerAction != null;
    final int half = items.length ~/ 2;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      // With a button the stack is taller than the pill so the lifted button
      // is not clipped; without one the pill is all there is.
      child: SizedBox(
        height: hasCenter ? _barHeight + _centerLift : _barHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            _Pill(
              height: _barHeight,
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < half; i++)
                    Expanded(child: _buildTab(context, i)),
                  // Gap the centre button sits in. Without a button the tabs
                  // close up and spread across the full width instead.
                  if (hasCenter)
                    const SizedBox(width: _centerSize + AppSpacing.lg),
                  for (int i = half; i < items.length; i++)
                    Expanded(child: _buildTab(context, i)),
                ],
              ),
            ),
            if (hasCenter)
              Positioned(
                bottom: _barHeight - _centerSize + _centerLift,
                child: _CenterButton(
                  icon: centerIcon,
                  tooltip: centerTooltip,
                  size: _centerSize,
                  onPressed: centerAction,
                  color: theme.colorScheme.primary,
                  iconColor: theme.colorScheme.onPrimary,
                  ringColor: theme.scaffoldBackgroundColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    return _NavTab(
      item: items[index],
      selected: index == currentIndex,
      onTap: () => onSelected(index),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.onPressed,
    required this.color,
    required this.iconColor,
    required this.ringColor,
  });

  final IconData icon;
  final String? tooltip;
  final double size;
  final VoidCallback onPressed;
  final Color color;
  final Color iconColor;

  /// Drawn behind the button so it reads as cut out of the pill.
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    final Widget button = Container(
      height: size + 8,
      width: size + 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: Center(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Icon(icon, size: 30, color: iconColor),
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
