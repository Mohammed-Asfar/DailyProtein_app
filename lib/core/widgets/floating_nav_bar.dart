import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

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

/// Bottom navigation bar, optionally notched around a raised action button.
///
/// Wraps `stylish_bottom_bar` so colours are still resolved from the theme
/// here rather than passed as literals by every caller, keeping the single
/// source of truth for colour intact.
///
/// The raised button is **not** part of this widget. The package notches the
/// bar but does not draw the button, which the Scaffold positions over the
/// notch — see [buildCenterButton] and [centerLocation]. When [hasCenter] is
/// false no notch is cut, so the bar reads as a plain rounded strip.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.hasCenter = false,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Whether to notch the bar for a centre button. The Scaffold must supply
  /// a matching button, or the notch will be an empty bite out of the bar.
  final bool hasCenter;

  /// Diameter of the raised centre button.
  static const double centerSize = 62;

  /// Where the Scaffold places the centre button so it lands in the notch.
  static FloatingActionButtonLocation get centerLocation =>
      FloatingActionButtonLocation.centerDocked;

  /// Builds the raised button that sits in the bar's notch.
  ///
  /// A plain [FloatingActionButton] rather than a hand-rolled circle: it
  /// draws its fill, shadow and ink splash as one anti-aliased shape, where
  /// a decorated Container clipped by a Material put a hard clip edge over a
  /// soft fill and read as a rough edge.
  static Widget buildCenterButton(
    BuildContext context, {
    required VoidCallback onPressed,
    IconData icon = Icons.add_rounded,
    String? tooltip,
  }) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: centerSize,
      width: centerSize,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: 6,
        shape: const CircleBorder(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: Icon(icon, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selected = theme.colorScheme.primary;
    final Color unselected = theme.colorScheme.onSurfaceVariant;

    return StylishBottomBar(
      currentIndex: currentIndex,
      onTap: onSelected,
      backgroundColor: theme.colorScheme.surface,
      elevation: 8,
      hasNotch: hasCenter,
      notchStyle: NotchStyle.circle,
      fabLocation: hasCenter ? StylishBarFabLocation.center : null,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      option: AnimatedBarOptions(
        iconSize: 26,
        barAnimation: BarAnimation.fade,
        iconStyle: IconStyle.Default,
        // The package dims unselected items by default; our own
        // onSurfaceVariant is already the contrast-checked resting colour.
        opacity: 1,
      ),
      items: <BottomBarItem>[
        for (final NavItem item in items)
          BottomBarItem(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            selectedColor: selected,
            unSelectedColor: unselected,
            // The package sets size, weight and the selected/unselected
            // colour via an inherited DefaultTextStyle, so the label carries
            // no style of its own. Setting colour here would override it.
            title: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
