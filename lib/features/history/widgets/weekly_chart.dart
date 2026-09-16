import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../log/models/food_entry.dart';

/// Bar chart of daily protein against the goal line.
///
/// Every day gets its own full-width bar and label. When the range is wider
/// than the card the plot scrolls horizontally while the y-axis stays put,
/// rather than shrinking bars and thinning labels until they collide.
class WeeklyChart extends StatefulWidget {
  const WeeklyChart({
    super.key,
    required this.days,
    required this.totals,
    required this.goal,
  });

  /// Day keys, oldest first.
  final List<String> days;

  /// Totals keyed by day; missing days count as zero.
  final Map<String, DayTotals> totals;

  final double goal;

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  final ScrollController _scroll = ScrollController();

  /// Horizontal room each day occupies once the range overflows the card.
  /// Wide enough for a "18 Aug" label (about 69px) plus breathing space, so
  /// neighbouring labels never touch however long the range is.
  static const double _slotWidth = 78;

  /// A week uses short weekday labels and is meant to fit without scrolling,
  /// so it only needs room for "Wed".
  static const double _weekSlotWidth = 40;

  double get _minSlot =>
      widget.days.length <= 7 ? _weekSlotWidth : _slotWidth;

  static const double _chartHeight = 200;
  /// The y-axis gutter. Sized so a three-digit value at [_axisFontSize]
  /// (about 33px) fits without clipping, plus a small gap before the plot,
  /// and no more: the axis is the least interesting part of the chart.
  static const double _axisWidth = 38;

  /// Slightly smaller than the day labels, so three digits fit the gutter.
  static const double _axisFontSize = 11;
  static const double _barWidth = 18;
  static const double _bottomStrip = 28;

  /// Breathing room at each end of the plot so the first and last day
  /// labels are not cut off by the edge of the scroll view.
  static const double _edgePadding = 12;

  @override
  void initState() {
    super.initState();
    // Open on the most recent day, which is the one worth seeing first.
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
  }

  @override
  void didUpdateWidget(WeeklyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
    }
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _maxY {
    final double highest = widget.days.fold<double>(
      widget.goal,
      (double max, String day) {
        final double value = widget.totals[day]?.protein ?? 0;
        return value > max ? value : max;
      },
    );
    return highest * 1.2;
  }

  /// Weekday names are unambiguous within a week; past that they repeat, so
  /// the day of the month is the useful label.
  String _labelFor(String day) =>
      widget.days.length <= 7 ? DayKey.weekday(day) : DayKey.dayOfMonth(day);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The scroller gets whatever the pinned axis leaves behind.
        final double available = constraints.maxWidth - _axisWidth;
        final double wanted = widget.days.length * _minSlot;
        // Short ranges stretch to fill the card exactly, so they do not
        // scroll; longer ones overflow and become scrollable.
        final double plotWidth = wanted <= available ? available : wanted;

        return SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // A chart with only the y-axis, pinned beside the scroller so
              // the values stay readable however far you scroll.
              SizedBox(
                width: _axisWidth,
                child: BarChart(_axisOnlyData(theme)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  // Half a slot of padding at each end: spaceAround centres
                  // the outermost labels on their bars, which pushes them
                  // past the plot edge and clips them.
                  padding: const EdgeInsets.symmetric(
                    horizontal: _edgePadding,
                  ),
                  child: SizedBox(
                    width: plotWidth - _edgePadding * 2,
                    child: BarChart(_plotData(theme)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  FlGridData _grid(ThemeData theme) => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _maxY / 4,
        getDrawingHorizontalLine: (double value) => FlLine(
          color: theme.colorScheme.outline,
          strokeWidth: 1,
        ),
      );

  /// The pinned gutter: value labels and grid lines, no bars.
  BarChartData _axisOnlyData(ThemeData theme) {
    return BarChartData(
      maxY: _maxY,
      barGroups: const <BarChartGroupData>[],
      barTouchData: BarTouchData(enabled: false),
      gridData: _grid(theme),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        // Reserve the same strip the plot gives its day labels, so the grid
        // lines on both sides sit at the same height.
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: _bottomStrip),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _axisWidth,
            interval: _maxY / 4,
            // Left-aligned, not right: right-alignment pushes a short value
            // like "0" to the far edge of the gutter and leaves a ragged
            // column of empty space beside the shorter numbers.
            getTitlesWidget: (double value, TitleMeta meta) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Fmt.number(value, decimals: 0),
                  maxLines: 1,
                // An explicit style, not a copyWith on labelSmall: the
                // theme's size is what overflows this narrow gutter.
                  style: TextStyle(
                    fontSize: _axisFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The scrolling part: bars, day labels and the goal line.
  BarChartData _plotData(ThemeData theme) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => theme.colorScheme.onSurface,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              '${DayKey.pretty(widget.days[groupIndex])}\n'
              '${Fmt.grams(rod.toY)}',
              TextStyle(
                color: theme.colorScheme.surface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      gridData: _grid(theme),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: _bottomStrip,
            getTitlesWidget: (double value, TitleMeta meta) {
              final int index = value.toInt();
              if (index < 0 || index >= widget.days.length) {
                return const SizedBox.shrink();
              }
              final bool isToday = DayKey.isToday(widget.days[index]);
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _labelFor(widget.days[index]),
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: <HorizontalLine>[
          HorizontalLine(
            y: widget.goal,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            strokeWidth: 1.5,
            dashArray: <int>[6, 4],
          ),
        ],
      ),
      barGroups: <BarChartGroupData>[
        for (int i = 0; i < widget.days.length; i++)
          BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: widget.totals[widget.days[i]]?.protein ?? 0,
                width: _barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                color:
                    (widget.totals[widget.days[i]]?.protein ?? 0) >= widget.goal
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.45),
              ),
            ],
          ),
      ],
    );
  }
}
