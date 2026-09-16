import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'product_image.dart';

/// One row in the product catalogue.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.currencySymbol,
    this.category,
    this.onTap,
    this.trailing,
  });

  final Product product;
  final String currencySymbol;
  final Category? category;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String basis = product.measureMode == MeasureMode.perUnit
        ? 'per ${product.unitLabel}'
        : 'per 100 g';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          ProductImage(product: product, category: category),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    '${Fmt.grams(product.protein)} $basis',
                    if (product.calories != null)
                      Fmt.kcal(product.calories!),
                    if (product.price != null)
                      Fmt.money(product.price!, currencySymbol),
                  ].join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
