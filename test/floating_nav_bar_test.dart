import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/core/widgets/floating_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const List<NavItem> _items = <NavItem>[
  NavItem(
    icon: Icons.today_outlined,
    selectedIcon: Icons.today_rounded,
    label: 'Today',
  ),
  NavItem(
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    label: 'History',
  ),
  NavItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    label: 'Products',
  ),
  NavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
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
  // Mirrors AppShell: the bar notches, the Scaffold docks the button.
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeMode,
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: const SizedBox.expand(),
        floatingActionButtonLocation: FloatingNavBar.centerLocation,
        floatingActionButton: showCenter
            ? FloatingNavBar.buildCenterButton(
                context,
                onPressed: onCenterPressed ?? () {},
                tooltip: 'Add food',
              )
            : null,
        bottomNavigationBar: FloatingNavBar(
          items: _items,
          currentIndex: currentIndex,
          onSelected: onSelected ?? (_) {},
          hasCenter: showCenter,
        ),
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
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
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

    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(presses, 1);
  });

  testWidgets('selected tab uses the filled icon, others the outline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(currentIndex: 2));

    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
    expect(find.byIcon(Icons.today_outlined), findsOneWidget);
  });

  testWidgets('selected tab is tinted with the primary colour', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(currentIndex: 1));
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.text('History'));
    final ColorScheme scheme = Theme.of(context).colorScheme;

    // The colour is inherited, not set on the Text, so read what actually
    // paints. A style passed to the Text would override it with null and
    // the labels would silently lose their selected/unselected tint.
    Color? painted(String label) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.text(label),
      );
      return paragraph.text.style?.color;
    }

    // Regression guard: the selected item must not blend into its background.
    expect(painted('History'), scheme.primary);
    expect(painted('Today'), scheme.onSurfaceVariant);
    expect(painted('History'), isNot(painted('Today')));
  });

  testWidgets('the centre button sits above the bar contents', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final Rect button = tester.getRect(find.byIcon(Icons.add_rounded));
    final Rect firstLabel = tester.getRect(find.text('Today'));

    // What makes it read as raised: it is higher than the tab labels.
    expect(button.center.dy, lessThan(firstLabel.center.dy));
  });

  testWidgets('the centre button straddles the top edge of the bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final Rect bar = tester.getRect(find.byType(FloatingNavBar));
    final Rect circle = tester.getRect(find.byType(FloatingActionButton));

    // Docked, not floating clear: the circle crosses the bar's top edge so
    // it lands in the notch rather than hovering above an unbroken bar.
    expect(
      circle.top,
      lessThan(bar.top),
      reason: 'the button should rise above the bar',
    );
    expect(
      circle.bottom,
      greaterThan(bar.top),
      reason: 'the button should overlap the bar, not float clear of it',
    );
  });

  group('without a centre button', () {
    testWidgets('the button is not rendered', (WidgetTester tester) async {
      await tester.pumpWidget(_harness(showCenter: false));

      expect(find.byIcon(Icons.add_rounded), findsNothing);
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

    testWidgets('no notch is cut into the bar', (WidgetTester tester) async {
      // The notch is only right when a button fills it. Left behind on a
      // screen with no button it would be a bite out of the bar.
      await tester.pumpWidget(_harness(showCenter: false));
      await tester.pumpAndSettle();

      final FloatingNavBar bar = tester.widget<FloatingNavBar>(
        find.byType(FloatingNavBar),
      );
      expect(bar.hasCenter, isFalse);
    });

    testWidgets('the bar height barely moves', (WidgetTester tester) async {
      // The button is docked by the Scaffold rather than lifted inside the
      // bar, so notching must not meaningfully resize the bar under the
      // content. The package does add a couple of pixels for the notch.
      await tester.pumpWidget(_harness(showCenter: false));
      await tester.pumpAndSettle();
      final double plain = tester.getSize(find.byType(FloatingNavBar)).height;

      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final double notched =
          tester.getSize(find.byType(FloatingNavBar)).height;

      expect((notched - plain).abs(), lessThan(4));
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
