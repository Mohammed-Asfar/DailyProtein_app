import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/section_header.dart';
import '../data/category_controller.dart';
import '../data/product_controller.dart';
import '../data/starter_foods.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Common foods the user can add to their catalogue in one tap.
///
/// These are suggestions only: adding one copies it into the user's own
/// products, after which the app never reads this list for that food again.
class StarterFoodsSection extends StatelessWidget {
  const StarterFoodsSection({super.key, this.limit = 8});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final ProductController products = context.watch<ProductController>();
    final List<StarterFood> suggestions = StarterFood.notYetAdded(
      products.products.map((Product p) => p.name),
    );
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final List<StarterFood> shown = suggestions.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Popular foods',
          trailing: suggestions.length > limit ? 'See all' : null,
          onTrailingTap: suggestions.length > limit
              ? () => _showAll(context, suggestions)
              : null,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.86,
          ),
          itemCount: shown.length,
          itemBuilder: (BuildContext context, int index) =>
              _StarterCard(food: shown[index]),
        ),
      ],
    );
  }

  /// The full suggestion list, for when more exist than the grid shows.
  void _showAll(BuildContext context, List<StarterFood> foods) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (BuildContext context, ScrollController scroll) {
          return Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Popular foods',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: GridView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: foods.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _StarterCard(food: foods[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.food});

  final StarterFood food;

  Future<void> _add(BuildContext context) async {
    final ProductController products = context.read<ProductController>();
    final CategoryController categories = context.read<CategoryController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    // Matched by name so a renamed or reordered category list cannot leave
    // these pointing at the wrong id.
    final Category? category = categories.categories
        .where((Category c) => c.name == food.categoryName)
        .firstOrNull;

    await products.add(food.toProduct(categoryId: category?.id));
    await categories.refreshCounts();

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text('${food.name} added to your products')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => _add(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Image area, as in the design: the emoji stands in until the
              // user takes a photo of their own.
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    food.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${food.protein.toStringAsFixed(1)} g',
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            food.measureMode == MeasureMode.perUnit
                                ? 'per ${food.unitLabel}'
                                : 'per 100 g',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
