import 'package:daily_protein/features/products/data/starter_foods.dart';
import 'package:daily_protein/features/products/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('starter catalogue', () {
    test('every entry has usable nutrition', () {
      for (final StarterFood food in StarterFood.all) {
        expect(food.name.trim(), isNotEmpty);
        expect(food.protein, greaterThanOrEqualTo(0), reason: food.name);
        expect(food.calories, greaterThan(0), reason: food.name);
        expect(food.emoji.trim(), isNotEmpty, reason: food.name);
      }
    });

    test('names are unique', () {
      final Set<String> names = StarterFood.all
          .map((StarterFood f) => f.name.toLowerCase())
          .toSet();
      expect(names.length, StarterFood.all.length);
    });

    test('per-unit foods name their unit, weighed ones say 100 g', () {
      for (final StarterFood food in StarterFood.all) {
        if (food.measureMode == MeasureMode.perUnit) {
          expect(food.unitLabel, isNot('100 g'), reason: food.name);
        } else {
          expect(food.unitLabel, '100 g', reason: food.name);
        }
      }
    });

    test('protein figures are plausible, not placeholders', () {
      for (final StarterFood food in StarterFood.all) {
        // Nothing is more than 60% protein by weight.
        if (food.measureMode == MeasureMode.per100g) {
          expect(food.protein, lessThan(60), reason: food.name);
        }
      }
    });

    test('converting to a product carries the figures across', () {
      final StarterFood egg = StarterFood.all.firstWhere(
        (StarterFood f) => f.name == 'Egg',
      );
      final Product product = egg.toProduct(categoryId: 4);

      expect(product.name, 'Egg');
      expect(product.protein, 6.3);
      expect(product.categoryId, 4);
      expect(product.measureMode, MeasureMode.perUnit);
      // The headline promise: two eggs is 12.6 g.
      expect(product.proteinFor(2), closeTo(12.6, 0.0001));
    });

    test('chicken scales per 100 g', () {
      final StarterFood chicken = StarterFood.all.firstWhere(
        (StarterFood f) => f.name == 'Chicken Breast',
      );
      expect(chicken.toProduct().proteinFor(150), closeTo(46.5, 0.0001));
    });
  });

  group('notYetAdded', () {
    test('hides foods already in the catalogue, ignoring case', () {
      final List<StarterFood> left =
          StarterFood.notYetAdded(<String>['egg', 'BANANA']);
      final Set<String> names =
          left.map((StarterFood f) => f.name).toSet();

      expect(names, isNot(contains('Egg')));
      expect(names, isNot(contains('Banana')));
      expect(names, contains('Chicken Breast'));
      expect(left.length, StarterFood.all.length - 2);
    });

    test('an empty catalogue leaves every suggestion', () {
      expect(
        StarterFood.notYetAdded(<String>[]).length,
        StarterFood.all.length,
      );
    });

    test('a fully seeded catalogue leaves none, so the section hides', () {
      final List<String> everything =
          StarterFood.all.map((StarterFood f) => f.name).toList();
      expect(StarterFood.notYetAdded(everything), isEmpty);
    });
  });

  group('emoji', () {
    test('survives the conversion to a product', () {
      for (final StarterFood food in StarterFood.all) {
        expect(
          food.toProduct().emoji,
          food.emoji,
          reason: '${food.name} loses its emoji when added',
        );
      }
    });

    test('survives a database round-trip', () {
      final Product original = StarterFood.all
          .firstWhere((StarterFood f) => f.name == 'Banana')
          .toProduct(categoryId: 1);
      final Product restored = Product.fromMap(original.toMap());

      expect(restored.emoji, '🍌');
      expect(restored.categoryId, 1);
    });

    test('is optional, and stays null when unset', () {
      final Product plain = Product(
        name: 'Custom',
        measureMode: MeasureMode.perUnit,
        unitLabel: 'piece',
        protein: 5,
        createdAt: DateTime(2026),
      );
      expect(Product.fromMap(plain.toMap()).emoji, isNull);
    });

    test('copyWith can clear it as well as set it', () {
      final Product withEmoji = StarterFood.all.first.toProduct();
      expect(withEmoji.copyWith(emoji: () => null).emoji, isNull);
      expect(withEmoji.copyWith(emoji: () => '🥑').emoji, '🥑');
      // Omitting it leaves the original alone.
      expect(withEmoji.copyWith(name: 'x').emoji, withEmoji.emoji);
    });
  });
}
