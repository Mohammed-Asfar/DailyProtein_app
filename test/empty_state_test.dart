import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({String? actionLabel, VoidCallback? onAction}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products yet',
        message: 'Add the foods you eat with their protein content. '
            'Then logging a meal is just picking a product and a quantity.',
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    ),
  );
}

/// Height of a single line of the button's label, measured from a short
/// label that cannot wrap.
Future<double> _singleLineHeight(WidgetTester tester) async {
  await tester.pumpWidget(_harness(actionLabel: 'Add', onAction: () {}));
  await tester.pumpAndSettle();
  return tester.getSize(find.text('Add')).height;
}

void main() {
  testWidgets('shows the action button only when given both label and callback',
      (WidgetTester tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsNothing);

    await tester.pumpWidget(_harness(actionLabel: 'Add product', onAction: () {}));
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('the button label fits on one line at phone width', (
    WidgetTester tester,
  ) async {
    // A typical phone: 738 physical px at 2x = 369 logical px.
    tester.view.physicalSize = const Size(738, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final double oneLine = await _singleLineHeight(tester);

    await tester.pumpWidget(
      _harness(actionLabel: 'Add product', onAction: () {}),
    );
    await tester.pumpAndSettle();

    final Size label = tester.getSize(find.text('Add product'));
    expect(
      label.height,
      lessThanOrEqualTo(oneLine),
      reason: 'the label wrapped onto a second line; shorten it or widen '
          'the button',
    );
  });

  testWidgets('the button stays inside the screen at phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(738, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _harness(actionLabel: 'Add product', onAction: () {}),
    );
    await tester.pumpAndSettle();

    final Rect button = tester.getRect(find.byType(FilledButton));
    final Rect screen = tester.getRect(find.byType(Scaffold));

    expect(button.left, greaterThanOrEqualTo(screen.left));
    expect(button.right, lessThanOrEqualTo(screen.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the button fires its callback', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _harness(actionLabel: 'Add product', onAction: () => taps++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
  });
}
