import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/core/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<NavItem> _items = <NavItem>[
  NavItem(
    icon: Icons.today_outlined,
    selectedIcon: Icons.today,
    label: 'Today',
  ),
  NavItem(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    label: 'History',
  ),
  NavItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Products',
  ),
  NavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

Widget _harness({
  int currentIndex = 0,
  ValueChanged<int>? onSelected,
  VoidCallback? onCenterPressed,
  bool showCenter = true,
  ThemeMode themeMode = ThemeMode.dark,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    home: Scaffold(
      extendBody: true,
      body: const SizedBox.expand(),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        currentIndex: currentIndex,
        onSelected: onSelected ?? (_) {},
        onCenterPressed:
            showCenter ? (onCenterPressed ?? () {}) : null,
      ),
    ),
  );
}

void main() {
  testWidgets('renders every label and the centre button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());

    for (final NavItem item in _items) {
      expect(find.text(item.label), findsOneWidget);
    }
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping a tab reports its index', (WidgetTester tester) async {
    final List<int> taps = <int>[];
    await tester.pumpWidget(_harness(onSelected: taps.add));

    await tester.tap(find.text('History'));
    await tester.tap(find.text('Settings'));

    // Settings is the fourth item, after the centre gap.
    expect(taps, <int>[1, 3]);
  });

  testWidgets('centre button fires its own callback', (
    WidgetTester tester,
  ) async {
    int presses = 0;
    await tester.pumpWidget(_harness(onCenterPressed: () => presses++));

    await tester.tap(find.byIcon(Icons.add));
    expect(presses, 1);
  });

  testWidgets('selected tab uses the filled icon, others the outline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(currentIndex: 2));

    expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.byIcon(Icons.today_outlined), findsOneWidget);
  });

  testWidgets('selected tab is tinted with the primary colour', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(currentIndex: 1));

    final BuildContext context = tester.element(find.text('History'));
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Text selected = tester.widget<Text>(find.text('History'));
    final Text unselected = tester.widget<Text>(find.text('Today'));

    // Regression guard: the selected item must not blend into its background.
    expect(selected.style?.color, scheme.primary);
    expect(unselected.style?.color, scheme.onSurfaceVariant);
    expect(selected.style?.color, isNot(unselected.style?.color));
  });

  testWidgets('the centre button clears the top of the bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());

    final Rect button = tester.getRect(find.byIcon(Icons.add));
    final Rect firstLabel = tester.getRect(find.text('Today'));

    // The button should sit higher than the tab labels, which is what makes
    // it read as elevated out of the pill.
    expect(button.center.dy, lessThan(firstLabel.center.dy));
  });

  testWidgets('the centre button overlaps the pill rather than floating', (
    WidgetTester tester,
  ) async {
    // Without a button the bar is exactly the pill, which gives us its
    // height without reaching into the widget's private constants.
    await tester.pumpWidget(_harness(showCenter: false));
    final double pillHeight =
        tester.getSize(find.byType(FloatingNavBar)).height;

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final Rect bar = tester.getRect(find.byType(FloatingNavBar));
    // The circle, not the icon inside it.
    final Rect circle = tester.getRect(
      find
          .ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(Container),
          )
          .last,
    );

    // The pill occupies the lower part of the bar; the button must straddle
    // its top edge, not sit entirely above it.
    final double pillTop = bar.bottom - pillHeight;
    expect(
      circle.top,
      lessThan(pillTop),
      reason: 'the button should rise above the pill',
    );
    expect(
      circle.bottom,
      greaterThan(pillTop),
      reason: 'the button should overlap the pill, not float clear of it',
    );
  });

  group('without a centre button', () {
    testWidgets('the button is not rendered', (WidgetTester tester) async {
      await tester.pumpWidget(_harness(showCenter: false));

      expect(find.byIcon(Icons.add), findsNothing);
      for (final NavItem item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('tabs still map to the right indices', (
      WidgetTester tester,
    ) async {
      final List<int> taps = <int>[];
      await tester.pumpWidget(
        _harness(showCenter: false, onSelected: taps.add),
      );

      await tester.tap(find.text('Today'));
      await tester.tap(find.text('Settings'));

      expect(taps, <int>[0, 3]);
    });

    testWidgets('tabs spread wider without the centre gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(showCenter: false));
      final double withoutGap =
          tester.getRect(find.text('Settings')).center.dx;

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final double withGap = tester.getRect(find.text('Settings')).center.dx;

      // Removing the gap pulls the trailing tabs back toward the centre.
      expect(withoutGap, lessThan(withGap));
    });

    testWidgets('the bar is shorter without a button to lift', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(showCenter: false));
      final double plain = tester.getSize(find.byType(FloatingNavBar)).height;

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final double lifted = tester.getSize(find.byType(FloatingNavBar)).height;

      expect(plain, lessThan(lifted));
    });
  });

  testWidgets('no label overflows at a narrow width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in light theme too', (WidgetTester tester) async {
    await tester.pumpWidget(_harness(themeMode: ThemeMode.light));

    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
