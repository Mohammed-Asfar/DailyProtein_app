import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/core/utils/date_utils.dart';
import 'package:daily_protein/features/history/widgets/weekly_chart.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _chart(List<String> days) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: WeeklyChart(
          days: days,
          totals: <String, DayTotals>{
            days.last: DayTotals(
              date: days.last,
              protein: 12,
              calories: 0,
              cost: 0,
              entryCount: 1,
            ),
          },
          goal: 120,
        ),
      ),
    ),
  );
}

/// Painted bounds of one label. The widget's box is padded and wider than
/// the glyphs, so measuring the box would hide real collisions.
({String text, double left, double right}) _glyphBounds(
  WidgetTester tester,
  Text widget,
) {
  final Rect box = tester.getRect(find.byWidget(widget));
  final TextPainter painter = TextPainter(
    text: TextSpan(text: widget.data, style: widget.style),
    textDirection: TextDirection.ltr,
  )..layout();
  return (
    text: widget.data!,
    left: box.center.dx - painter.width / 2,
    right: box.center.dx + painter.width / 2,
  );
}

/// The day labels under the scrolling plot, left to right. The y-axis lives
/// in its own pinned chart, so it is excluded by searching only inside the
/// scroll view.
List<({String text, double left, double right})> _dayLabels(
  WidgetTester tester,
) {
  final Finder texts = find.descendant(
    of: find.byType(SingleChildScrollView),
    matching: find.byType(Text),
  );
  final List<({String text, double left, double right})> labels =
      <({String text, double left, double right})>[];
  for (final Element element in texts.evaluate()) {
    final Text widget = element.widget as Text;
    if (widget.data == null) continue;
    labels.add(_glyphBounds(tester, widget));
  }
  labels.sort((a, b) => a.left.compareTo(b.left));
  return labels;
}

void _phoneSized(WidgetTester tester) {
  // A typical phone: 738 physical px at 2x.
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  for (final int range in <int>[7, 14, 30]) {
    testWidgets('$range-day labels do not touch', (WidgetTester tester) async {
      _phoneSized(tester);
      await tester.pumpWidget(_chart(DayKey.lastDays(range)));
      await tester.pumpAndSettle();

      final List<({String text, double left, double right})> labels =
          _dayLabels(tester);
      expect(labels.length, greaterThan(1));

      for (int i = 1; i < labels.length; i++) {
        expect(
          labels[i].left - labels[i - 1].right,
          greaterThan(0),
          reason: '"${labels[i - 1].text}" and "${labels[i].text}" overlap at '
              '$range days, which is what smears the axis',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every day gets its own label, none are dropped', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    // 14 days spans two weeks, so day numbers are unique across the range.
    final List<String> days = DayKey.lastDays(14);
    await tester.pumpWidget(_chart(days));
    await tester.pumpAndSettle();

    // Scrolling reveals the rest, but all of them are laid out.
    expect(_dayLabels(tester).length, days.length);
  });

  testWidgets('a long range scrolls rather than squeezing', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_chart(DayKey.lastDays(30)));
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      scrollable.position.maxScrollExtent,
      greaterThan(0),
      reason: '30 days should not be crammed into one screen width',
    );
  });

  testWidgets('a week fits without scrolling', (WidgetTester tester) async {
    _phoneSized(tester);
    await tester.pumpWidget(_chart(DayKey.lastDays(7)));
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, 0);
  });

  testWidgets('opens scrolled to the most recent day', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_chart(DayKey.lastDays(30)));
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      scrollable.position.pixels,
      scrollable.position.maxScrollExtent,
      reason: 'the latest day is the one worth seeing first',
    );
  });

  testWidgets('the first and last day labels are not cut off', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    await tester.pumpWidget(_chart(DayKey.lastDays(7)));
    await tester.pumpAndSettle();

    final Rect scroller = tester.getRect(find.byType(SingleChildScrollView));
    final List<({String text, double left, double right})> labels =
        _dayLabels(tester);

    expect(
      labels.first.left,
      greaterThanOrEqualTo(scroller.left),
      reason: '"${labels.first.text}" runs off the left edge',
    );
    expect(
      labels.last.right,
      lessThanOrEqualTo(scroller.right),
      reason: '"${labels.last.text}" runs off the right edge',
    );
  });

  testWidgets('y-axis values are not clipped by the gutter', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    final List<String> days = DayKey.lastDays(7);
    // A high total pushes the axis to three-digit values, the widest case.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: WeeklyChart(
              days: days,
              goal: 120,
              totals: <String, DayTotals>{
                days.last: DayTotals(
                  date: days.last,
                  protein: 240,
                  calories: 0,
                  cost: 0,
                  entryCount: 1,
                ),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool sawThreeDigits = false;
    for (final Element element in find.byType(Text).evaluate()) {
      final Text widget = element.widget as Text;
      if (widget.data == null || double.tryParse(widget.data!) == null) {
        continue;
      }
      if (widget.data!.length >= 3) sawThreeDigits = true;

      final Rect box = tester.getRect(find.byWidget(widget));
      final TextPainter painter = TextPainter(
        text: TextSpan(text: widget.data, style: widget.style),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(box.width),
        reason: '"${widget.data}" is clipped by the y-axis gutter',
      );
    }
    expect(sawThreeDigits, isTrue, reason: 'the widest case was not covered');
  });

  testWidgets('y-axis values start flush, whatever their length', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);
    final List<String> days = DayKey.lastDays(7);
    // A high total gives a mix of one, two and three digit axis values.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: WeeklyChart(
              days: days,
              goal: 120,
              totals: <String, DayTotals>{
                days.last: DayTotals(
                  date: days.last,
                  protein: 140,
                  calories: 0,
                  cost: 0,
                  entryCount: 1,
                ),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect chart = tester.getRect(find.byType(WeeklyChart));
    final List<double> starts = <double>[];
    for (final Element element in find.byType(Text).evaluate()) {
      final Text widget = element.widget as Text;
      if (widget.data == null || double.tryParse(widget.data!) == null) {
        continue;
      }
      starts.add(tester.getRect(find.byWidget(widget)).left - chart.left);
    }
    expect(starts.length, greaterThan(2));

    // Right-aligning them indents the short values and leaves a ragged
    // column of dead space; left-aligned, every value starts together.
    for (final double start in starts) {
      expect(
        start,
        lessThan(4),
        reason: 'an axis value is indented from the chart edge',
      );
    }
  });

  testWidgets('a week shows weekday names, longer ranges show dates', (
    WidgetTester tester,
  ) async {
    _phoneSized(tester);

    await tester.pumpWidget(_chart(DayKey.lastDays(7)));
    await tester.pumpAndSettle();
    expect(find.text(DayKey.weekday(DayKey.today)), findsOneWidget);

    await tester.pumpWidget(_chart(DayKey.lastDays(30)));
    await tester.pumpAndSettle();
    expect(find.text(DayKey.dayOfMonth(DayKey.today)), findsOneWidget);
  });
}
