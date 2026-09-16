import 'package:daily_protein/core/theme/app_colors.dart';
import 'package:daily_protein/core/theme/app_theme.dart';
import 'package:daily_protein/features/products/models/category.dart';
import 'package:daily_protein/features/products/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    test('survives a round-trip through the database map', () {
      const Category original = Category(
        id: 3,
        name: 'Proteins',
        icon: 'protein',
        colour: 'chart',
        builtIn: true,
        sortOrder: 4,
      );
      final Category restored = Category.fromMap(original.toMap());

      expect(restored.id, 3);
      expect(restored.name, 'Proteins');
      expect(restored.icon, 'protein');
      expect(restored.colour, 'chart');
      expect(restored.builtIn, isTrue);
      expect(restored.sortOrder, 4);
    });

    test('built_in is stored as an integer, since SQLite has no bool', () {
      expect(
        const Category(name: 'x', icon: 'other', colour: 'leaf').toMap()['built_in'],
        0,
      );
      expect(
        const Category(name: 'x', icon: 'other', colour: 'leaf', builtIn: true)
            .toMap()['built_in'],
        1,
      );
    });

    test('an unknown icon key falls back rather than throwing', () {
      const Category odd =
          Category(name: 'x', icon: 'not-a-real-icon', colour: 'leaf');
      expect(odd.iconData, Icons.category_rounded);
    });

    testWidgets('an unknown colour key falls back rather than throwing', (
      WidgetTester tester,
    ) async {
      late AppIconColors icons;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (BuildContext context) {
              icons = AppIconColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      const Category odd =
          Category(name: 'x', icon: 'other', colour: 'not-a-colour');
      expect(odd.resolveColour(icons), icons.leaf);
    });

    test('offered icon keys map to distinct icons', () {
      // "other" legitimately maps to the same icon used as the fallback,
      // so distinctness is the useful check rather than inequality.
      final Set<int> points = Category.iconKeys
          .map((String k) =>
              Category(name: 'x', icon: k, colour: 'leaf').iconData.codePoint)
          .toSet();
      expect(points.length, Category.iconKeys.length);
    });

    testWidgets('offered colour keys map to distinct colours', (
      WidgetTester tester,
    ) async {
      late AppIconColors icons;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (BuildContext context) {
              icons = AppIconColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final Set<int> colours = Category.colourKeys
          .map((String k) => Category(name: 'x', icon: 'other', colour: k)
              .resolveColour(icons)
              .toARGB32())
          .toSet();
      expect(colours.length, Category.colourKeys.length);
    });
  });

  group('Product with a category and photo', () {
    test('carries both through a round-trip', () {
      final Product original = Product(
        name: 'Paneer',
        measureMode: MeasureMode.per100g,
        unitLabel: '100 g',
        protein: 18,
        categoryId: 4,
        imagePath: '/data/app/product_images/1.jpg',
        createdAt: DateTime(2026, 9, 16),
      );
      final Product restored = Product.fromMap(original.toMap());

      expect(restored.categoryId, 4);
      expect(restored.imagePath, '/data/app/product_images/1.jpg');
      expect(restored.protein, 18);
    });

    test('both are optional and stay null', () {
      final Product plain = Product(
        name: 'Egg',
        measureMode: MeasureMode.perUnit,
        unitLabel: 'piece',
        protein: 6,
        createdAt: DateTime(2026),
      );
      final Product restored = Product.fromMap(plain.toMap());

      expect(restored.categoryId, isNull);
      expect(restored.imagePath, isNull);
    });

    test('copyWith can clear them, not just set them', () {
      final Product withBoth = Product(
        name: 'Paneer',
        measureMode: MeasureMode.per100g,
        unitLabel: '100 g',
        protein: 18,
        categoryId: 4,
        imagePath: '/photo.jpg',
        createdAt: DateTime(2026),
      );

      final Product cleared = withBoth.copyWith(
        categoryId: () => null,
        imagePath: () => null,
      );
      expect(cleared.categoryId, isNull);
      expect(cleared.imagePath, isNull);

      // Omitting them leaves the originals alone.
      final Product untouched = withBoth.copyWith(name: 'Tofu');
      expect(untouched.categoryId, 4);
      expect(untouched.imagePath, '/photo.jpg');
    });
  });
}
