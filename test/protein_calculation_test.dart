import 'package:daily_protein/core/utils/formatters.dart';
import 'package:daily_protein/features/log/models/food_entry.dart';
import 'package:daily_protein/features/products/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required MeasureMode mode,
  required double protein,
  double? calories,
  double? price,
}) {
  return Product(
    id: 1,
    name: 'Test',
    measureMode: mode,
    unitLabel: mode == MeasureMode.perUnit ? 'piece' : '100 g',
    protein: protein,
    calories: calories,
    price: price,
    createdAt: DateTime(2026),
  );
}

void main() {
  group('per-unit products', () {
    final Product egg = _product(
      mode: MeasureMode.perUnit,
      protein: 6,
      calories: 78,
      price: 8,
    );

    test('2 eggs give 12 g protein', () {
      expect(egg.proteinFor(2), 12);
    });

    test('calories and cost scale with the count', () {
      expect(egg.caloriesFor(3), 234);
      expect(egg.costFor(3), 24);
    });

    test('zero quantity gives zero', () {
      expect(egg.proteinFor(0), 0);
    });

    test('cost per gram of protein', () {
      expect(egg.costPerGramProtein, closeTo(1.333, 0.001));
    });
  });

  group('per-100g products', () {
    final Product chicken = _product(
      mode: MeasureMode.per100g,
      protein: 27,
      calories: 165,
      price: 25,
    );

    test('150 g gives 40.5 g protein', () {
      expect(chicken.proteinFor(150), closeTo(40.5, 0.0001));
    });

    test('100 g gives exactly the listed values', () {
      expect(chicken.proteinFor(100), 27);
      expect(chicken.caloriesFor(100), 165);
      expect(chicken.costFor(100), 25);
    });

    test('50 g gives half', () {
      expect(chicken.proteinFor(50), closeTo(13.5, 0.0001));
    });
  });

  group('optional fields', () {
    test('missing calories and price count as zero, not null', () {
      final Product plain = _product(mode: MeasureMode.perUnit, protein: 10);
      expect(plain.caloriesFor(2), 0);
      expect(plain.costFor(2), 0);
      expect(plain.costPerGramProtein, isNull);
    });

    test('a zero-protein product has no cost per gram', () {
      final Product water =
          _product(mode: MeasureMode.perUnit, protein: 0, price: 20);
      expect(water.costPerGramProtein, isNull);
    });
  });

  group('FoodEntry.calculate', () {
    test('snapshots the nutrition at log time', () {
      final Product egg =
          _product(mode: MeasureMode.perUnit, protein: 6, price: 8);
      final FoodEntry entry = FoodEntry.calculate(
        product: egg,
        quantity: 2,
        date: '2026-09-16',
        meal: Meal.breakfast,
      );

      expect(entry.protein, 12);
      expect(entry.cost, 16);
      expect(entry.meal, Meal.breakfast);
      expect(entry.date, '2026-09-16');
    });

    test('quantity label uses the product unit', () {
      final Product egg = _product(mode: MeasureMode.perUnit, protein: 6);
      final Product chicken = _product(mode: MeasureMode.per100g, protein: 27);

      expect(
        FoodEntry.calculate(
          product: egg,
          quantity: 2,
          date: '2026-09-16',
          meal: Meal.snack,
        ).quantityLabel,
        '2 piece',
      );
      expect(
        FoodEntry.calculate(
          product: chicken,
          quantity: 150,
          date: '2026-09-16',
          meal: Meal.lunch,
        ).quantityLabel,
        '150 g',
      );
    });
  });

  group('DayTotals', () {
    test('cost per gram divides spend by protein', () {
      const DayTotals totals = DayTotals(
        date: '2026-09-16',
        protein: 80,
        calories: 1800,
        cost: 200,
        entryCount: 5,
      );
      expect(totals.costPerGram, closeTo(2.5, 0.0001));
    });

    test('no cost means no cost per gram', () {
      const DayTotals totals = DayTotals(
        date: '2026-09-16',
        protein: 80,
        calories: 1800,
        cost: 0,
        entryCount: 5,
      );
      expect(totals.costPerGram, isNull);
    });
  });

  group('serialisation round-trip', () {
    test('a product survives toMap/fromMap', () {
      final Product original = _product(
        mode: MeasureMode.per100g,
        protein: 27,
        calories: 165,
        price: 25,
      );
      final Product restored = Product.fromMap(original.toMap());

      expect(restored.name, original.name);
      expect(restored.measureMode, original.measureMode);
      expect(restored.protein, original.protein);
      expect(restored.calories, original.calories);
      expect(restored.price, original.price);
    });

    test('null calories and price survive the round-trip', () {
      final Product original = _product(mode: MeasureMode.perUnit, protein: 6);
      final Product restored = Product.fromMap(original.toMap());

      expect(restored.calories, isNull);
      expect(restored.price, isNull);
    });
  });

  group('formatting', () {
    test('whole numbers drop the trailing zero', () {
      expect(Fmt.grams(12), '12 g');
      expect(Fmt.grams(12.5), '12.5 g');
      expect(Fmt.number(40.50), '40.5');
    });
  });
}
