import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two-step flow the History screen uses: a start date, then an end
/// date, each in an ordinary calendar dialog rather than the full-screen
/// range picker.
Future<DateTimeRange?> _pickRange(
  BuildContext context,
  DateTimeRange initial,
  DateTime now,
) async {
  final DateTime? start = await showDatePicker(
    context: context,
    initialDate: initial.start,
    firstDate: DateTime(2020),
    lastDate: now,
    helpText: 'Start date',
  );
  if (start == null || !context.mounted) return null;

  final DateTime? end = await showDatePicker(
    context: context,
    initialDate: initial.end.isBefore(start) ? start : initial.end,
    firstDate: start,
    lastDate: now,
    helpText: 'End date',
  );
  if (end == null) return null;
  return DateTimeRange(start: start, end: end);
}

final DateTime _now = DateTime(2026, 9, 16);

Widget _harness(void Function(DateTimeRange?) onResult) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (BuildContext context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              onResult(
                await _pickRange(
                  context,
                  DateTimeRange(start: DateTime(2026, 9, 10), end: _now),
                  _now,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void _phoneSized(WidgetTester tester) {
  // A typical phone: 738 physical px at 2x.
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the picker is a dialog, not a full-screen page', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_harness((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Size screen = tester.getSize(find.byType(MaterialApp));
    // The calendar card itself, inside the modal barrier.
    final Size card = tester.getSize(find.byType(AnimatedContainer).first);

    expect(
      card.width,
      lessThan(screen.width),
      reason: 'the picker fills the screen width; it should be a dialog',
    );
    expect(
      card.height,
      lessThan(screen.height),
      reason: 'the picker fills the screen height; it should be a dialog',
    );
  });

  testWidgets('asks for a start date, then an end date', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_harness((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Start date'), findsOneWidget);
    expect(find.text('End date'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('End date'), findsOneWidget);
  });

  testWidgets('returns the chosen span', (WidgetTester tester) async {
    _phoneSized(tester);
    DateTimeRange? result;
    await tester.pumpWidget(_harness((DateTimeRange? r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result?.start, DateTime(2026, 9, 10));
    expect(result?.end, _now);
  });

  testWidgets('cancelling the first step picks nothing', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    DateTimeRange? result;
    bool called = false;
    await tester.pumpWidget(
      _harness((DateTimeRange? r) {
        called = true;
        result = r;
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
    expect(find.text('End date'), findsNothing);
  });

  testWidgets('cancelling the second step leaves the range unchanged', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    DateTimeRange? result;
    await tester.pumpWidget(_harness((DateTimeRange? r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
