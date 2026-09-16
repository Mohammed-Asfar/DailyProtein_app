import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/features/history/widgets/range_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _selector({
  int rangeDays = 7,
  DateTimeRange? customRange,
  ValueChanged<int>? onPreset,
  VoidCallback? onCustom,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RangeSelector(
          rangeDays: rangeDays,
          customRange: customRange,
          onPreset: onPreset ?? (_) {},
          onCustom: onCustom ?? () {},
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

/// True when the label was ellipsised, i.e. it did not fit its chip.
bool _isTruncated(WidgetTester tester, String label) {
  final RenderParagraph paragraph =
      tester.renderObject(find.text(label)) as RenderParagraph;
  return paragraph.didExceedMaxLines;
}

void main() {
  testWidgets('preset labels are not ellipsised at phone width', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_selector());
    await tester.pumpAndSettle();

    for (final String label in <String>['7d', '14d', '30d']) {
      expect(find.text(label), findsOneWidget);
      expect(
        _isTruncated(tester, label),
        isFalse,
        reason: '"$label" is ellipsised; the row is too narrow for it',
      );
    }
  });

  testWidgets('labels still fit on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_selector());
    await tester.pumpAndSettle();

    for (final String label in <String>['7d', '14d', '30d']) {
      expect(_isTruncated(tester, label), isFalse, reason: '"$label" clipped');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a preset reports its length', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    final List<int> picked = <int>[];
    await tester.pumpWidget(_selector(onPreset: picked.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('30d'));
    await tester.tap(find.text('14d'));
    expect(picked, <int>[30, 14]);
  });

  testWidgets('a calendar button opens the date range picker', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    int taps = 0;
    await tester.pumpWidget(_selector(onCustom: () => taps++));
    await tester.pumpAndSettle();

    final Finder calendar = find.byIcon(Icons.calendar_month_outlined);
    expect(calendar, findsOneWidget);
    await tester.tap(calendar);
    expect(taps, 1);
  });

  testWidgets('everything fits one row without overflowing', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_selector());
    await tester.pumpAndSettle();

    final Rect calendar =
        tester.getRect(find.byIcon(Icons.calendar_month_outlined));
    final Rect firstChip = tester.getRect(find.text('7d'));
    // The calendar sits beside the presets, not below them.
    expect(calendar.center.dy, closeTo(firstChip.center.dy, 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chosen range is named and spelled out underneath', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(
      _selector(
        customRange: DateTimeRange(
          start: DateTime(2026, 9, 3),
          end: DateTime(2026, 9, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3 Sep'), findsOneWidget);
    expect(find.textContaining('16 Sep'), findsOneWidget);
  });
}
