import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/category.dart';
import '../models/product.dart';

/// A product's picture, in order of preference: a photo the user took,
/// then an emoji, then the category icon, then the product's first letter.
///
/// The photo is read from app storage, so a file that has gone missing
/// degrades to the next fallback rather than showing a broken image.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.category,
    this.size = 44,
    this.radius,
  });

  final Product product;
  final Category? category;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppIconColors icons = AppIconColors.of(context);
    final double corner = radius ?? AppSpacing.radiusSm;
    final Color tint =
        category?.resolveColour(icons) ?? theme.colorScheme.primary;

    final String? path = product.imagePath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(corner),
        child: Image.file(
          File(path),
          height: size,
          width: size,
          fit: BoxFit.cover,
          // A file can be removed from under the app between the check and
          // the decode; fall back rather than throwing.
          errorBuilder: (BuildContext _, Object _, StackTrace? _) => _Fallback(
            product: product,
            category: category,
            size: size,
            corner: corner,
            tint: tint,
          ),
        ),
      );
    }

    return _Fallback(
      product: product,
      category: category,
      size: size,
      corner: corner,
      tint: tint,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.product,
    required this.category,
    required this.size,
    required this.corner,
    required this.tint,
  });

  final Product product;
  final Category? category;
  final double size;
  final double corner;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Category? cat = category;
    final String? emoji = product.emoji;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(corner),
      ),
      alignment: Alignment.center,
      child: emoji != null && emoji.isNotEmpty
          ? Text(emoji, style: TextStyle(fontSize: size * 0.52))
          : cat != null
              ? Icon(cat.iconData, size: size * 0.45, color: tint)
              : Text(
                  product.name.isEmpty ? '?' : product.name.characters.first,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    color: tint,
                  ),
                ),
    );
  }
}
