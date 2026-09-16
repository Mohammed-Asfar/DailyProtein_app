import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../log/data/entry_repository.dart';
import '../../log/data/log_controller.dart';
import '../../log/models/food_entry.dart';
import '../../products/data/product_controller.dart';
import '../../products/models/product.dart';
import '../../settings/data/settings_controller.dart';
import '../models/history_summary.dart';
import '../widgets/range_selector.dart';
import '../widgets/weekly_chart.dart';

/// Past days, the weekly chart, averages and value-for-money insights.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onOpenDay});

  /// Called when a past day is tapped, so the shell can switch to Home.
  final ValueChanged<String>? onOpenDay;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final EntryRepository _repository = EntryRepository();

  /// Preset window in days. Ignored while [_customRange] is set.
  int _rangeDays = 7;

  /// A user-picked span, which overrides the preset when present.
  DateTimeRange? _customRange;

  late Future<HistorySummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// The days the chart and stats cover, oldest first.
  List<String> get _days {
    final DateTimeRange? custom = _customRange;
    if (custom != null) {
      return DayKey.daysBetween(custom.start, custom.end);
    }
    return DayKey.lastDays(_rangeDays);
  }

  /// How many days the current selection spans, for the "over N days"
  /// captions and the goal-hit tally.
  int get _dayCount => _days.length;

  Future<HistorySummary> _load() async {
    final List<String> days = _days;
    final Map<String, DayTotals> range =
        await _repository.totalsForRange(days.first, days.last);
    // Whether anything has ever been logged, which decides between the
    // empty state and an empty range.
    final bool hasAnyHistory = (await _repository.allDays()).isNotEmpty;
    return HistorySummary(
      days: days,
      range: range,
      hasAnyHistory: hasAnyHistory,
    );
  }

  void _reload() => setState(() => _future = _load());

  void _setRange(int days) {
    setState(() {
      _rangeDays = days;
      _customRange = null;
      _future = _load();
    });
  }

  Future<void> _pickCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(Duration(days: _rangeDays - 1)),
            end: now,
          ),
      helpText: 'Select a date range',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _future = _load();
    });
  }

  /// Label for the current selection, used in the captions.
  String get _rangeCaption =>
      _customRange == null ? 'over $_dayCount days' : 'in this range';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsController settings = context.watch<SettingsController>();
    final ProductController products = context.watch<ProductController>();

    // Rebuild when the log changes so new entries show up here immediately.
    context.watch<LogController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: FutureBuilder<HistorySummary>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<HistorySummary> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final HistorySummary data = snapshot.data!;

          if (!data.hasAnyHistory) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No history yet',
              message: 'Log a few days of food and your trends will show up '
                  'here.',
            );
          }

          final double average = data.averageProtein;
          final int hitDays = data.daysHittingGoal(settings.proteinGoal);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.navBarClearance,
            ),
            children: <Widget>[
              RangeSelector(
                rangeDays: _rangeDays,
                customRange: _customRange,
                onPreset: _setRange,
                onCustom: _pickCustomRange,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Protein per day',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Dashed line is your ${Fmt.grams(settings.proteinGoal)} '
                      'goal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    WeeklyChart(
                      days: data.days,
                      totals: data.range,
                      goal: settings.proteinGoal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      label: 'Daily average',
                      icon: Icons.show_chart,
                      value: Fmt.grams(average),
                      caption: _rangeCaption,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatTile(
                      label: 'Goal hit',
                      icon: Icons.emoji_events_outlined,
                      useAccent: true,
                      value: '$hitDays / $_dayCount',
                      caption: 'days on target',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      label: 'Total spent',
                      icon: Icons.account_balance_wallet_outlined,
                      value: Fmt.money(
                        data.totalCost,
                        settings.currencySymbol,
                      ),
                      caption: _rangeCaption,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatTile(
                      label: 'Cost per gram',
                      icon: Icons.calculate_outlined,
                      value: data.costPerGram == null
                          ? '--'
                          : Fmt.perGram(
                              data.costPerGram!,
                              settings.currencySymbol,
                            ),
                      caption: 'of protein',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _BestValueSection(products: products, settings: settings),
              SectionHeader(
                title: 'Logged days',
                trailing: data.loggedDays.isEmpty
                    ? null
                    : '${data.loggedDays.length} of $_dayCount',
              ),
              if (data.loggedDays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'Nothing logged in this range',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                for (final DayTotals day in data.loggedDays)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _DayRow(
                      day: day,
                      goal: settings.proteinGoal,
                      currency: settings.currencySymbol,
                      onTap: () => widget.onOpenDay?.call(day.date),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _BestValueSection extends StatelessWidget {
  const _BestValueSection({required this.products, required this.settings});

  final ProductController products;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Product> cheapest = products.cheapestSources();
    if (cheapest.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Best value protein'),
        AppCard(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < cheapest.length; i++) ...<Widget>[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(height: 1),
                  ),
                Row(
                  children: <Widget>[
                    Container(
                      height: 26,
                      width: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        cheapest[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      Fmt.perGram(
                        cheapest[i].costPerGramProtein!,
                        settings.currencySymbol,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.goal,
    required this.currency,
    required this.onTap,
  });

  final DayTotals day;
  final double goal;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hitGoal = goal > 0 && day.protein >= goal;
    final double progress =
        goal <= 0 ? 0 : (day.protein / goal).clamp(0.0, 1.0);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DayKey.label(day.date),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (hitGoal)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              Text(
                Fmt.grams(day.protein),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            <String>[
              '${day.entryCount} ${day.entryCount == 1 ? 'item' : 'items'}',
              if (day.calories > 0) Fmt.kcal(day.calories),
              if (day.cost > 0) Fmt.money(day.cost, currency),
            ].join('  •  '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
