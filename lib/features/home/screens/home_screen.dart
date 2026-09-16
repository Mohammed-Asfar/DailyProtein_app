import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../log/data/log_controller.dart';
import '../../log/models/food_entry.dart';
import '../../log/screens/add_food_sheet.dart';
import '../../log/widgets/entry_tile.dart';
import '../../products/data/product_controller.dart';
import '../../settings/data/settings_controller.dart';
import '../widgets/day_switcher.dart';

/// Today's dashboard: goal ring, stats and the day's entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickDate(BuildContext context, LogController log) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DayKey.parse(log.date),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await log.setDate(DayKey.of(picked));
    }
  }

  Future<void> _deleteEntry(
    BuildContext context,
    LogController log,
    FoodEntry entry,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await log.deleteEntry(entry.id!);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${entry.displayName} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => log.restoreEntry(entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LogController log = context.watch<LogController>();
    final SettingsController settings = context.watch<SettingsController>();
    final ProductController products = context.watch<ProductController>();
    final DayTotals totals = log.totals;
    final String currency = settings.currencySymbol;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await log.load();
            await products.load();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.navBarClearance,
            ),
            children: <Widget>[
              DaySwitcher(
                date: log.date,
                onPrevious: () => log.shiftDay(-1),
                onNext: () => log.shiftDay(1),
                onPickDate: () => _pickDate(context, log),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: ProgressRing(
                  value: totals.protein,
                  goal: settings.proteinGoal,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _StatsRow(totals: totals, settings: settings),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Logged today',
                trailing: totals.entryCount > 0
                    ? '${totals.entryCount} '
                        '${totals.entryCount == 1 ? 'item' : 'items'}'
                    : null,
              ),
              if (log.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (log.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl,
                  ),
                  // No action button here: the nav bar's centre button
                  // already offers this action.
                  child: EmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'Nothing logged yet',
                    message: products.isEmpty
                        ? 'Add your first product, then log what you ate.'
                        : 'Tap Add food below to log what you ate.',
                  ),
                )
              else
                for (final MapEntry<Meal, List<FoodEntry>> group
                    in log.entriesByMeal.entries) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          group.key.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          Fmt.grams(
                            group.value.fold<double>(
                              0,
                              (double sum, FoodEntry e) => sum + e.protein,
                            ),
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final FoodEntry entry in group.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EntryTile(
                        entry: entry,
                        currencySymbol: currency,
                        onDelete: () => _deleteEntry(context, log, entry),
                        onTap: entry.product == null
                            ? null
                            : () => AddFoodSheet.show(
                                  context,
                                  date: log.date,
                                  editing: entry,
                                ),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totals, required this.settings});

  final DayTotals totals;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final String currency = settings.currencySymbol;
    final double? perGram = totals.costPerGram;

    return Row(
      children: <Widget>[
        Expanded(
          child: StatTile(
            label: 'Calories',
            icon: Icons.local_fire_department_outlined,
            useAccent: true,
            value: Fmt.kcal(totals.calories),
            caption: 'of ${Fmt.kcal(settings.calorieGoal)}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(
            label: 'Spent',
            icon: Icons.sell_outlined,
            value: Fmt.money(totals.cost, currency),
            caption: perGram == null
                ? 'no prices set'
                : '${Fmt.perGram(perGram, currency)} protein',
          ),
        ),
      ],
    );
  }
}
